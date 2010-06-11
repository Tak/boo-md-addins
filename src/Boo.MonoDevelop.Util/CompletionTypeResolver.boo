namespace Boo.MonoDevelop.Util.Completion

import System

import Boo.Lang.Environments
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Steps
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.IO
import Boo.Lang.Compiler.TypeSystem

class CompletionTypeResolver:

	private _compiler as BooCompiler
	
	def constructor():
		Initialize()
		
	virtual def Initialize():
		_compiler = BooCompiler()
		pipeline = Pipelines.Compile()
		pipeline.InsertAfter(Boo.Lang.Parser.BooParsingStep, ResolveMonoBehaviourType())
		pipeline.BreakOnErrors = false
		
		# _compiler.Parameters.ScriptMainMethod = "Awake"
		_compiler.Parameters.Pipeline = pipeline
		# imports = _compiler.Parameters.Imports
		# imports.Add("UnityEngine")
		# imports.Add("System.Collections")
	
	Input:
		get: return Parameters.Input
	
	References:
		get: return Parameters.References
	
	virtual Parameters:
		private get: return _compiler.Parameters
	
	def AddReference(reference as string):
		References.Add(Parameters.LoadAssembly(reference, true))
	
	def ResolveAnd(action as Action of IType):
		context = Run()
		DumpErrors(context.Errors)
		
		Environments.With(context) do:
			finder = CompletionFinder()
			type = finder.FindCompletionTypeFor(context.CompileUnit)
			if type is null:
				print "Null type!"
				return
			print type
			action(type)
	
	virtual def Run():
		return _compiler.Run()
			
	protected def DumpErrors(errors as CompilerErrorCollection):
		for error in errors:
			print error
		