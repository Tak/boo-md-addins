namespace UnityScript.Ide

import Boo.Ide
import Boo.Lang.Compiler
import UnityScript

static class UnityScriptProjectIndexFactory:
	
	def CreateUnityScriptProjectIndex() as ProjectIndex:
		
		scriptMainMethod = "Main"
		
		pipeline = UnityScriptCompiler.Pipelines.AdjustBooPipeline(Boo.Lang.Compiler.Pipelines.ResolveExpressions())
		pipeline.InsertAfter(UnityScript.Steps.Parse, ResolveMonoBehaviourType())
		pipeline.Remove(UnityScript.Steps.ApplySemantics)
		pipeline.BreakOnErrors = false
		
		compiler = BooCompiler(UnityScriptCompilerParameters(ScriptMainMethod: scriptMainMethod, Pipeline: pipeline))
		
		parser = BooCompiler(UnityScriptCompilerParameters(ScriptMainMethod: scriptMainMethod))
		parser.Parameters.Pipeline = UnityScriptCompiler.Pipelines.Parse()
		parser.Parameters.Pipeline.InsertAfter(UnityScript.Steps.Parse, ResolveMonoBehaviourType())
		parser.Parameters.Pipeline.BreakOnErrors = false
		
		return ProjectIndex(compiler, parser)

