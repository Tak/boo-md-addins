namespace Boo.Ide

import Boo.Lang.Parser
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast

import System.IO

class ProjectIndex:
	
	_compiler = BooCompiler()
	_modules = List of Module()
	_referencedProjects = List of ProjectIndex()
		
	def constructor():
		_compiler.Parameters.Pipeline = Pipelines.Compile(BreakOnErrors: false)
	
	def ProposalsFor(code as string):
		
		unit = CompileUnitIncludingAllModulesAndReferencedProjects()
		module = ParseModule(unit, code)
		
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
		
	def AddReference(project as ProjectIndex):
		_referencedProjects.Add(project)
		
	def AddReference(assembly as System.Reflection.Assembly):
		_compiler.Parameters.References.Add(assembly)
		
	def Update(fileName as string, contents as string):
		module = ParseModule(CompileUnit(), fileName, contents)
		existing = _modules.IndexOf({ m as Module | m.LexicalInfo.FileName == fileName })
		if existing < 0:
			_modules.Add(module)
		else:
			_modules[existing] = module
		return module
		
	private def CompileUnitIncludingAllModulesAndReferencedProjects():
		unit = CompileUnit()
		unit.Modules.ExtendWithClones(_modules)
		for project in _referencedProjects:
			unit.Modules.ExtendWithClones(project._modules)
		return unit
		
	private def ParseModule(unit as CompileUnit, code as string):
		return ParseModule(unit, "code", code)
		
	private def ParseModule(unit as CompileUnit, fileName as string, contents as string):
		return BooParser.ParseModule(4, unit, fileName, StringReader(contents), { error | print error })
				
def DumpErrors(errors as CompilerErrorCollection):
	for error in errors:
		print error