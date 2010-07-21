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
	_contexts = System.Collections.Generic.Dictionary[of string,CompilerContext]()
		
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
		result = List of CompletionProposal()
		if(not _contexts.ContainsKey(fileName)):
			return result.ToArray()
			
		context = _contexts[fileName]
		originalModule = GetModuleForFileFromContext(context, fileName)
		context.CompileUnit.Modules.Remove(originalModule)
		module = ParseModule(context.CompileUnit, fileName, code)
		
		context = _compiler.Run(context.CompileUnit)
		
		Environments.With(context) do:
			expression = CursorLocationFinder().FindIn(module)
			if expression is null:
				return result.ToArray()
			for proposal in CompletionProposer.ForExpression(expression):
				result.Add(proposal)
		context.CompileUnit.Modules.Replace(module, originalModule)
		return result.ToArray()
		
	def GetModuleForFileFromContext(context as CompilerContext, fileName as string):
		index = -1
		for i in range(0, context.CompileUnit.Modules.Count):
			if(context.CompileUnit.Modules[i].LexicalInfo.FileName == fileName):
				index = i
				break
		if(0 <= index): return context.CompileUnit.Modules[index]
		else: return null
		
	def GetModuleForFile(fileName as string):
		index = _modules.IndexOf({ m as Module | m.LexicalInfo.FileName == fileName })
		if(0 <= index): return _modules[index]
		else: return null
		
		
		
	[lock]
	virtual def MethodsFor(fileName as string, code as string, methodName as string, methodLine as int):
		methods = System.Collections.Generic.List of MethodDescriptor()
		if(not _contexts.ContainsKey(fileName)): return methods
		
		context = _contexts[fileName]
		originalModule = GetModuleForFileFromContext(context, fileName)
		context.CompileUnit.Modules.Remove(originalModule)
		module = ParseModule(context.CompileUnit, fileName, code)
		
		context = _compiler.Run(context.CompileUnit)
		
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
		context.CompileUnit.Modules.Replace(module, originalModule)
		return methods
		
	[lock]
	virtual def LocalsAt(fileName as string, code as string, line as int):
		locals = System.Collections.Generic.List of string()
		
		if(not _contexts.ContainsKey(fileName)): return locals
		Environments.With(_contexts[fileName]) do:
			for module in _contexts[fileName].CompileUnit.Modules:
				locals.AddRange(LocalAccumulator(fileName, line).FindIn(module))
		return locals
		
		
	[lock]
	virtual def ImportsFor(fileName as string, code as string):
		module = ParseModule(CompileUnit(), fileName, code)
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
		unit as CompileUnit
		
		if(_contexts.ContainsKey(fileName)):
			unit = _contexts[fileName].CompileUnit
			oldModule = GetModuleForFileFromContext(_contexts[fileName], fileName)
			if(null != oldModule): unit.Modules.Remove(oldModule)
		else:
			unit = CompileUnitIncludingAllModulesAndReferencedProjectsExcluding(fileName)
			
		# module = ParseModule(CompileUnit(), fileName, contents)
		module = ParseModule(unit, fileName, contents).Clone() as Module
		_contexts[fileName] = _compiler.Run(unit)
		
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