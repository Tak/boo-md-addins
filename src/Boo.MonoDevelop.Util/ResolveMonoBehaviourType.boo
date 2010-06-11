namespace Boo.MonoDevelop.Util.Completion

import Boo.Lang.Compiler.Steps

class ResolveMonoBehaviourType(AbstractCompilerStep):
       type as object
              
       override def Run():
               type = FindReferencedType("UnityEngine.MonoBehaviour")
               # (Parameters as CompilerParameters).ScriptBaseType = type or object

       def FindReferencedType(typeName as string):
               for reference in Parameters.References:
                       assemblyRef = reference as Boo.Lang.Compiler.TypeSystem.Reflection.IAssemblyReference
                       if assemblyRef is null:
                               continue
                       type = assemblyRef.Assembly.GetType(typeName)
                       if type is not null:
                               return type
