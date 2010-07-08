namespace Boo.Ide

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem

class ProjectIndex:
	
	_compiler as BooCompiler
	_parser as BooCompiler
	
	_modules = List of Module()
	_referencedProjects = List of ProjectIndex()
	_implicitNamespaces = []
		
	def constructor():
		_compiler = BooCompiler()
		_compiler.Parameters.Pipeline = Pipelines.ResolveExpressions(BreakOnErrors: false)
		
		_parser = BooCompiler()
		_parser.Parameters.Pipeline = Pipelines.Parse()
		_implicitNamespaces = ["Boo.Lang", "Boo.Lang.Builtins"]
	
	def constructor(compiler as BooCompiler, parser as BooCompiler, implicitNamespaces as List):
		_compiler = compiler
		_parser = parser
		_implicitNamespaces = implicitNamespaces
	
	[lock]
	virtual def ProposalsFor(fileName as string, code as string):
		
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
		
	[lock]
	virtual def MethodsFor(fileName as string, code as string, methodName as string, methodLine as int):
		unit = CompileUnitIncludingAllModulesAndReferencedProjectsExcluding(fileName)
		module = ParseModule(unit, fileName, code)
		
		context = _compiler.Run(unit)
		DumpErrors(context.Errors)
		methods = System.Collections.Generic.List of MethodDescriptor()
		
		Environments.With(context) do:
			expression = MethodInvocationFinder(methodName, fileName, methodLine).FindIn(module)
			if expression is null:
				print "No method found for ${methodName}: (${fileName}:${methodLine})"
				return
			if (expression.Target.Entity isa Ambiguous):
				# Multiple overloads
				for i in (expression.Target.Entity as Ambiguous).Entities:
					methods.Add (MethodDescriptor(i))
			else:
				# May have failed resolution - try one more time
				entity = Services.NameResolutionService().ResolveMethod((expression.Target.Entity as IMethod).DeclaringType, methodName)
				if (entity isa Ambiguous):
					# Multiple overloads
					for i in (expression.Target.Entity as Ambiguous).Entities:
						methods.Add (MethodDescriptor(i))
				else:
					# No overloads
					methods.Add(MethodDescriptor(entity))
		return methods
		
	[lock]
	virtual def LocalsAt(fileName as string, code as string, line as int):
		unit = CompileUnitIncludingAllModulesAndReferencedProjectsExcluding(fileName)
		module = ParseModule(unit, fileName, code)
		
		context = _compiler.Run(unit)
		DumpErrors(context.Errors)
		locals = System.Collections.Generic.List of string()
		
		Environments.With(context) do:
			locals = LocalAccumulator(fileName, line).FindIn(module)
		return locals
		
		
	virtual def ImportsFor(fileName as string, code as string):
		module = Update(fileName, code)
		imports = List of string(i.Namespace for i in module.Imports)
		for ns in _implicitNamespaces:
			imports.Add(ns)
		return imports
		
	[lock]
	virtual def AddReference(project as ProjectIndex):
		_referencedProjects.Add(project)
		
	[lock]
	virtual def AddReference(assembly as System.Reflection.Assembly):
		_compiler.Parameters.References.Add(assembly)
		
	[lock]
	virtual def AddReference(reference as string):
		_compiler.Parameters.LoadAssembly(reference, false)
		
	virtual def Update(fileName as string, contents as string):
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