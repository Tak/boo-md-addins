namespace UnityScript.MonoDevelop.ProjectModel

import MonoDevelop.Projects.Dom
import MonoDevelop.Projects.Dom.Parser

import Boo.MonoDevelop.Util
import UnityScript.MonoDevelop

class UnityScriptParser(AbstractParser):
	
	public static final MimeType = "text/x-unityscript"
	
	def constructor():
		super("UnityScript", MimeType)
		
	override def CanParse(fileName as string):
		return IsUnityScriptFile(fileName)
		
	override def Parse(dom as ProjectDom, fileName as string, content as string):
		result = ParseUnityScript(fileName, content)
		
		document = ParsedDocument(fileName)
		document.CompilationUnit = CompilationUnit(fileName)
		if(null == dom): return document
		
		try:
			index = ProjectIndexFactory.ForProject(dom.Project)
			assert index is not null
			module = index.Update(fileName, content)
			result.CompileUnit.Accept(DomConversionVisitor(document.CompilationUnit))
		except e:
			LogError e
		
		return document
		
def ParseUnityScript(fileName as string, content as string):
	compiler = UnityScript.UnityScriptCompiler()
	compiler.Parameters.ScriptMainMethod = "Awake"
	compiler.Parameters.ScriptBaseType = object
	compiler.Parameters.Pipeline = UnityScript.UnityScriptCompiler.Pipelines.Parse()
	compiler.Parameters.Input.Add(Boo.Lang.Compiler.IO.StringInput(fileName, content))
	return compiler.Run()
	