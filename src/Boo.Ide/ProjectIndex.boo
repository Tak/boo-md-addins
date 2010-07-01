namespace Boo.Ide

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

class ProjectIndex:
	
	_compiler as BooCompiler
	_parser as BooCompiler
	
	_modules = List of Module()
	_referencedProjects = List of ProjectIndex()
		
	def constructor():
		_compiler = BooCompiler()
		_compiler.Parameters.Pipeline = Pipelines.ResolveExpressions(BreakOnErrors: false)
		
		_parser = BooCompiler()
		_parser.Parameters.Pipeline = Pipelines.Parse()
	
	def constructor(compiler as BooCompiler, parser as BooCompiler):
		_compiler = compiler
		_parser = parser
	
	[lock]
	def ProposalsFor(fileName as string, code as string):
		
		unit = CompileUnitIncludingAllModulesAndReferencedProjectsExcluding(fileName)
		module = ParseModule(unit, fileName, code)
		
		context = _compiler.Run(unit)
		DumpErrors(context.Errors)
		
		result = List of CompletionProposal()
		Environments.With(context) do:
			expression = CursorLocationFinder().FindIn(module)
			if expression is null:
				print "expression is null"
				return
			for proposal in CompletionProposer.ForExpression(expression):
				result.Add(proposal)
		return result.ToArray()
		
	def ImportsFor(fileName as string, code as string):
		module = Update(fileName, code)
		return (i.Namespace for i in module.Imports)
		
	[lock]
	def AddReference(project as ProjectIndex):
		_referencedProjects.Add(project)
		
	[lock]
	def AddReference(assembly as System.Reflection.Assembly):
		_compiler.Parameters.References.Add(assembly)
		
	def Update(fileName as string, contents as string):
		module = ParseModule(CompileUnit(), fileName, contents)
		
		lock self:
			existing = _modules.IndexOf({ m as Module | m.LexicalInfo.FileName == fileName })
			if existing < 0:
				_modules.Add(module)
			else:
				_modules[existing] = module
			return module
		
	private def CompileUnitIncludingAllModulesAndReferencedProjectsExcluding(fileName as string):
		unit = CompileUnit()
		for module in _modules:
			continue if module.LexicalInfo.FileName == fileName
			unit.Modules.Add(module.Clone())
		for project in _referencedProjects:
			unit.Modules.ExtendWithClones(project._modules)
		return unit
		
	private def ParseModule(unit as CompileUnit, fileName as string, contents as string):
		try:
			_parser.Parameters.Input.Add(IO.StringInput(fileName, contents))
			result = _parser.Run(unit)
			//DumpErrors result.Errors
			return result.CompileUnit.Modules[-1]
		except x:
			print x
			return Module(LexicalInfo(fileName, 1, 1))
		ensure:
			_parser.Parameters.Input.Clear()
				
def DumpErrors(errors as CompilerErrorCollection):
	for error in errors:
		print error.ToString(true)