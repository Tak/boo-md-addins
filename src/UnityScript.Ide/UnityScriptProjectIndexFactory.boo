namespace UnityScript.Ide

import Boo.Ide
import Boo.Lang.Compiler
import UnityScript

static class UnityScriptProjectIndexFactory:
	
	final ScriptMainMethod = "Main"
	
	def CreateUnityScriptProjectIndex() as ProjectIndex:
		return ProjectIndex(CreateCompiler(), CreateParser(), [])
		
	private def CreateCompiler():
		pipeline = UnityScriptCompiler.Pipelines.AdjustBooPipeline(Boo.Lang.Compiler.Pipelines.ResolveExpressions())
		pipeline.InsertAfter(UnityScript.Steps.Parse, ResolveMonoBehaviourType())
		pipeline.Remove(UnityScript.Steps.ApplySemantics)
		pipeline.BreakOnErrors = false
		return BooCompiler(UnityScriptCompilerParameters(ScriptMainMethod: ScriptMainMethod, Pipeline: pipeline))
		
	private def CreateParser():
		parameters = UnityScriptCompilerParameters(ScriptMainMethod: ScriptMainMethod)
		parameters.Imports = ["UnityEngine", "UnityEditor", "System.Collections"]
		
		parser = BooCompiler(parameters)
		parser.Parameters.Pipeline = UnityScriptCompiler.Pipelines.Parse()
		parser.Parameters.Pipeline.InsertAfter(UnityScript.Steps.Parse, ResolveMonoBehaviourType())
		parser.Parameters.Pipeline.BreakOnErrors = false
		return parser

