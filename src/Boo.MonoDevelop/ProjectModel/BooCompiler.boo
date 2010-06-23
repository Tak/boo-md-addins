namespace Boo.MonoDevelop.ProjectModel

import MonoDevelop.Core
import MonoDevelop.Projects

import System.IO

import Boo.Lang.PatternMatching

class BooCompiler:
	
	_config as DotNetProjectConfiguration
	_selector as ConfigurationSelector
	_projectItems as ProjectItemCollection
	_compilationParameters as BooCompilationParameters
	_projectParameters as BooProjectParameters
	_monitor as IProgressMonitor
	
	def constructor(
		config as DotNetProjectConfiguration,
		selector as ConfigurationSelector,
		projectItems as ProjectItemCollection,
		progressMonitor as IProgressMonitor):
		
		_config = config
		_selector = selector
		_projectItems = projectItems
		_compilationParameters = config.CompilationParameters or BooCompilationParameters()
		_projectParameters = config.ProjectParameters or BooProjectParameters()
		_monitor = progressMonitor
		
	def Run() as BuildResult:
		responseFileName = Path.GetTempFileName()
		try:
			WriteOptionsToResponseFile(responseFileName)
			compilerOutput = ExecuteProcess(BoocPath(), "@${responseFileName}")
			buildResult = ParseBuildResult(compilerOutput)
			unless buildResult.Failed:
				CopyRequiredReferences()
			return buildResult
		ensure:
			FileService.DeleteFile(responseFileName)
			
	private def CopyRequiredReferences():
		outputDir = Path.GetDirectoryName(_config.CompiledOutputName)
		for reference in ProjectReferences():
			continue unless IsBooPackageReference(reference)
			for file in reference.GetReferencedFileNames(_selector):
				CopyReferencedFileTo(file, outputDir)
				
	def IsBooPackageReference(reference as ProjectReference):
		return reference.ReferenceType == ReferenceType.Gac and reference.Package.Name == "boo"
				
	def CopyReferencedFileTo(file as string, outputDir as string):
		if CopyNewerFileToDirectory(file, outputDir):
			print("Copied '${file}' to '${outputDir}'.")
			
	private def BoocPath():
		return BooAssemblyPath("booc.exe")
		
	private def BooAssemblyPath(fileName as string):
		return PathCombine(AssemblyPath(), "boo", fileName)
		
	private def AssemblyPath():
		return Path.GetDirectoryName(GetType().Assembly.ManifestModule.FullyQualifiedName)
			
	private def WriteOptionsToResponseFile(responseFileName as string):
		options = StringWriter()
		
		options.WriteLine("-t:${OutputType()}")
		options.WriteLine("-out:${_config.CompiledOutputName}")
		
		options.WriteLine("-debug" + ("+" if _config.DebugMode else "-"))
		
		if _compilationParameters.Ducky: options.WriteLine("-ducky") 
		
		projectFiles = item as ProjectFile for item in _projectItems if item isa ProjectFile 
		for file in projectFiles:
			continue if file.Subtype == Subtype.Directory
			
			match file.BuildAction:
				case BuildAction.Compile:
					options.WriteLine("\"${file.Name}\"")
				case BuildAction.EmbeddedResource:
					options.WriteLine("-embedres:${file.FilePath},${file.ResourceId}")
				otherwise:
					print "Unrecognized build action for file", file, "-", file.BuildAction
				
		for reference in ProjectReferences():
			for fileName in reference.GetReferencedFileNames(_selector):
				options.WriteLine("-reference:${fileName}")
		
		optionsString = options.ToString()
		print optionsString
		File.WriteAllText(responseFileName, optionsString)
		
	private def ProjectReferences():
		for item in _projectItems:
			reference = item as ProjectReference
			yield reference unless reference is null
		
	private def OutputType():
		return _config.CompileTarget.ToString().ToLower()
		
	private def ExecuteProcess(executable as string, commandLine as string):
		startInfo = System.Diagnostics.ProcessStartInfo(executable, commandLine,
						UseShellExecute: false,
						RedirectStandardOutput: true,
						RedirectStandardError: true)
		
		using process = Runtime.SystemAssemblyService.CurrentRuntime.ExecuteAssembly(startInfo, _config.TargetFramework):
			return process.StandardOutput.ReadToEnd() + System.Environment.NewLine + process.StandardError.ReadToEnd()
			
	private def ParseBuildResult(stdout as string):
		
		result = BuildResult()
		for line in StringReader(stdout):
			match line:
				case @/^(?<fileName>.+)\((?<lineNumber>\d+),(?<column>\d+)\):\s+(?<code>.+?):\s+(?<message>.+)$/:
					result.Append(BuildError(
								FileName: fileName[0].Value,
								Line: int.Parse(lineNumber[0].Value),
								Column: int.Parse(column[0].Value),
								IsWarning: code[0].Value.StartsWith("BCW"),
								ErrorNumber: code[0].Value,
								ErrorText: message[0].Value))
					
				case @/^(?<code>.+):\s+(?<message>.+)$/:
					result.Append(
						BuildError(
								ErrorNumber: code[0].Value,
								ErrorText: message[0].Value))
					
				otherwise:
					if len(line) > 0: print "Unrecognized compiler output:", line
		
		return result
