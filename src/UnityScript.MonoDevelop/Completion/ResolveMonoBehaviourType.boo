namespace UnityScript.MonoDevelop.Completion

import UnityScript

class ResolveMonoBehaviourType(Boo.MonoDevelop.Util.Completion.ResolveMonoBehaviourType):
       override def Run():
               super()
               (Parameters as UnityScriptCompilerParameters).ScriptBaseType = type or object
