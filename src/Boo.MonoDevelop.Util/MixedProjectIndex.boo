namespace Boo.MonoDevelop.Util

import System
import System.IO

import Boo.Ide
import MonoDevelop.Core
import MonoDevelop.Projects

class MixedProjectIndex(ProjectIndex):
	_booIndex as ProjectIndex
	_usIndex as ProjectIndex
	_project as DotNetProject

	def constructor(project as DotNetProject, booIndex as ProjectIndex, usIndex as ProjectIndex):
		_project = project
		_booIndex = booIndex
		_usIndex = usIndex
		
		# Populate files and references from project
		for reference in _project.References:
			_booIndex.AddReference(reference.Reference)
			_usIndex.AddReference(reference.Reference)
			
		usFiles = List of string()
		booFiles = List of string()
		for file in _project.Files:
			extension = Path.GetExtension(file.FilePath.FullPath).ToLower()
			if(".js" == extension):
				usFiles.Add(file.FilePath.FullPath)
			elif(".boo" == extension):
				booFiles.Add(file.FilePath.FullPath)
				
		_usIndex.Initialize(usFiles)
		_booIndex.Initialize(booFiles)
		
		# Register for update events
		_project.FileAddedToProject += OnFileUpdated
		_project.FileChangedInProject += OnFileUpdated
		_project.FileRenamedInProject += OnFileRenamed
		# TODO: (how) do we handle file removal?
		
		_booIndex.AddReference(_usIndex)
		_usIndex.AddReference(_booIndex)
	
	override def ProposalsFor(filename as string, code as string):
		return IndexForSourceFile(filename).ProposalsFor(filename, code)
		
	override def MethodsFor(filename as string, code as string, methodName as string, methodLine as int):
		return IndexForSourceFile(filename).MethodsFor(filename, code, methodName, methodLine)
		
	override def ImportsFor(filename as string, code as string):
		return IndexForSourceFile(filename).ImportsFor(filename, code)
		
	override def AddReference(project as ProjectIndex):
		_usIndex.AddReference(project)
		_booIndex.AddReference(project)
		
	override def AddReference(reference as System.Reflection.Assembly):
		_usIndex.AddReference(reference)
		_booIndex.AddReference(reference)
		
	def Update(filename as string):
		try:
			extension = Path.GetExtension(filename).ToLower()
			if (".boo" == extension or ".js" == extension):
				Update(filename, File.ReadAllText(filename))
		except e:
			LoggingService.LogError("Error updating index for ${filename}", e)
		
	override def Update(filename as string, contents as string):
		return IndexForSourceFile(filename).Update(filename, contents)
		
	override def LocalsAt(filename as string, code as string, line as int):
		return IndexForSourceFile(filename).LocalsAt(filename, code, line)
		
	def IndexForSourceFile(filename as string):
		if filename.EndsWith(".js", StringComparison.OrdinalIgnoreCase): return _usIndex
		return _booIndex
		
	def OnFileUpdated(sender, args as ProjectFileEventArgs):
		Update(args.ProjectFile.Name)
		
	def OnFileRenamed(sender, args as ProjectFileRenamedEventArgs):
		Update(args.NewName.FullPath)
	