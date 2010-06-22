namespace Boo.MonoDevelop.ProjectModel

import System
import System.IO

import MonoDevelop.Projects.Dom
import MonoDevelop.Projects.Dom.Parser

import Boo.Lang.Compiler as BLC

import Boo.MonoDevelop.Util

class BooParser(AbstractParser):
	
	_compiler = BLC.BooCompiler()
	
	def constructor():
		super("Boo", BooMimeType)
		pipeline = BLC.CompilerPipeline()
		pipeline.Add(BLC.Steps.InitializeTypeSystemServices())
		pipeline.Add(BLC.Steps.IntroduceModuleClasses())
		_compiler.Parameters.Pipeline = pipeline
		
	override def CanParse(fileName as string):
		return Path.GetExtension(fileName).ToLower() == ".boo"
		
	override def Parse(dom as ProjectDom, fileName as string, content as string):
		
		document = ParsedDocument(fileName)
		document.CompilationUnit = CompilationUnit(fileName)
		
		try:
			index = ProjectIndexFactory.ForProject(dom.Project)
			assert index is not null
			module = index.Update(fileName, content)
			IntroduceModuleClasses(module).Accept(DomConversionVisitor(document.CompilationUnit))
		except e:
			LogError e
		
		return document
		
	override def CreateResolver(dom as ProjectDom, editor, fileName as string):
		doc = cast(MonoDevelop.Ide.Gui.Document, editor)
		return BooResolver(dom, doc.CompilationUnit, fileName)
		
	private def IntroduceModuleClasses(module as BLC.Ast.Module):
		return _compiler.Run(BLC.Ast.CompileUnit(module)).CompileUnit
		
