namespace UnityScript.MonoDevelop.Completion

import UnityScript

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Steps
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.IO
import Boo.Lang.Compiler.TypeSystem

class ResolveMonoBehaviourType(Boo.MonoDevelop.Util.Completion.ResolveMonoBehaviourType):
       override def Run():
               super()
               (Parameters as UnityScriptCompilerParameters).ScriptBaseType = type or object
