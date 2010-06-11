namespace UnityScript.MonoDevelop.Completion

import UnityScript

import System

import Boo.MonoDevelop.Util.Completion

class UnityScriptTypeResolver(CompletionTypeResolver):
	
	private _compiler as UnityScriptCompiler
		
	override def Initialize():
		_compiler = UnityScriptCompiler()
		pipeline = UnityScriptCompiler.Pipelines.AdjustBooPipeline(Boo.Lang.Compiler.Pipelines.Compile())
		pipeline.InsertAfter(UnityScript.Steps.Parse, ResolveMonoBehaviourType())
		pipeline.BreakOnErrors = false
	
		_compiler.Parameters.ScriptMainMethod = "Awake"
		_compiler.Parameters.Pipeline = pipeline
		imports = _compiler.Parameters.Imports
		imports.Add("UnityEngine")
		imports.Add("System.Collections")
	
	override Parameters:
		private get: return _compiler.Parameters
		
	override def Run():
		return _compiler.Run()
	
