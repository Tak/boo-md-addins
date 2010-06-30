namespace UnityScript.MonoDevelop.Completion

import System
import System.Collections.Generic

import UnityScript
import UnityScript.MonoDevelop
import UnityScript.MonoDevelop.ProjectModel

import MonoDevelop.Core
import MonoDevelop.Ide.CodeCompletion

import Boo.Lang.Compiler
import Boo.Lang.Compiler.IO
import Boo.Lang.PatternMatching

import Boo.MonoDevelop.Util.Completion

class UnityScriptEditorCompletion(BooCompletionTextEditorExtension):

	# Match "blah = new [...]" pattern
	static NEW_PATTERN = /\bnew\s+(?<namespace>[\w\d]+(\.[\w\d]+)*)?\.?/
	
	# Match "var blah: [...]" pattern
	static COLON_PATTERN = /\w\s*:\s*(?<namespace>[\w\d]+(\.[\w\d]+)*)?\.?/
	
	# Patterns that result in us doing a type/namespace completion
	static TYPE_PATTERNS = [IMPORTS_PATTERN, NEW_PATTERN, COLON_PATTERN]
	
	override def Initialize():
		InstallUnityScriptSyntaxModeIfNeeded()
		super()
		
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
	
	override def HandleCodeCompletion(context as CodeCompletionContext, completionChar as char):
#		print "HandleCodeCompletion(${context.ToString()}, ${completionChar.ToString()})"
		
		match completionChar.ToString():
			case ' ' or ':':
				for pattern in TYPE_PATTERNS:
					return completions if (null != (completions = CompleteNamespacesForPattern(context, pattern, "namespace")))
			case '.':
				for pattern in TYPE_PATTERNS:
					return completions if (null != (completions = CompleteNamespacesForPattern(context, pattern, "namespace")))
				return CompleteMembers(context)
			otherwise:
				return null
		return null
			
	override def ShouldEnableCompletionFor(fileName as string):
		return IsUnityScriptFile(fileName)
