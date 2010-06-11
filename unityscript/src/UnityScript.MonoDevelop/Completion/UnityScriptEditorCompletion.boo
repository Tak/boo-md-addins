namespace UnityScript.MonoDevelop.Completion

import System
import System.Collections.Generic

import UnityScript
import UnityScript.MonoDevelop
import UnityScript.MonoDevelop.ProjectModel

import MonoDevelop.Core
import MonoDevelop.Projects
import MonoDevelop.Projects.Dom.Parser 
import MonoDevelop.Ide.Gui
import MonoDevelop.Ide.Gui.Content
import MonoDevelop.Ide.CodeCompletion

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Steps
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.IO
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.PatternMatching

import Boo.MonoDevelop.Util.Completion;

class UnityScriptEditorCompletion(BooCompletionTextEditorExtension):
	
	override def Initialize():
		InstallUnityScriptSyntaxModeIfNeeded()
		_resolver = UnityScriptTypeResolver()
		super()
		
	override def InitializeProject():
		super()
		
		if _project is null:
			return
				
		# Add other project files
		for file as ProjectFile in [projectFile for projectFile in _project.Files if \
		    IsUnityScriptFile(projectFile.FilePath) and not \
		    projectFile.FilePath.FullPath.ToString().Equals(Document.FileName.FullPath.ToString(), StringComparison.OrdinalIgnoreCase)]:
			_resolver.Input.Add(FileInput(file.FilePath.FullPath))

		
	def InstallUnityScriptSyntaxModeIfNeeded():
		view = Document.GetContent[of MonoDevelop.SourceEditor.SourceEditorView]()
		return if view is null
		
		mimeType = UnityScriptParser.MimeType
		return if view.Document.SyntaxMode.MimeType == mimeType
		
		mode = Mono.TextEditor.Highlighting.SyntaxModeService.GetSyntaxMode(mimeType)
		if mode is not null:
			view.Document.SyntaxMode = mode
		else:
			LoggingService.LogWarning(GetType() + " could not get SyntaxMode for mimetype '" + mimeType + "'.")
	
	override def ExtendsEditor(doc as MonoDevelop.Ide.Gui.Document, editor as IEditableTextBuffer):
		return IsUnityScriptFile(doc.Name)
		
	override def HandleCodeCompletion(context as CodeCompletionContext, completionChar as char):
#		print "HandleCodeCompletion(${context.ToString()}, ${completionChar.ToString()})"
		
		match completionChar.ToString():
			case ' ':
				return CompleteNamespace(context)
				
			case '.':
				result = CompleteNamespace(context)
				if(null == result):
					return CompleteMembers(context)
				else:
					return result
			otherwise:
				return null
				
