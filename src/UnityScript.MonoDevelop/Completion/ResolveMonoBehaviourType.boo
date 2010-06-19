namespace UnityScript.MonoDevelop.Completion

import UnityScript

class ResolveMonoBehaviourType(Boo.MonoDevelop.Util.Completion.ResolveMonoBehaviourType):
	override def Run():
		(Parameters as UnityScriptCompilerParameters).ScriptBaseType = type or object
