namespace Boo.MonoDevelop.Completion

import System
import Boo.Lang.PatternMatching

import MonoDevelop.Ide.CodeCompletion

import Boo.MonoDevelop.Util.Completion

class BooEditorCompletion(BooCompletionTextEditorExtension):
	
	# Match "blah as [...]" pattern
	static AS_PATTERN = /\bas\s+(?<namespace>[\w\d]+(\.[\w\d]+)*)?\.?/
	
	# Patterns that result in us doing a type/namespace completion
	static TYPE_PATTERNS = [IMPORTS_PATTERN, AS_PATTERN]
	
	override def Initialize():
		super()

	override def HandleCodeCompletion(context as CodeCompletionContext, completionChar as char):
#		print "HandleCodeCompletion(${context.ToString()}, ${completionChar.ToString()})"
		
		match completionChar.ToString():
			case ' ':
				for pattern in TYPE_PATTERNS:
					completions = CompleteNamespacesForPattern(context, pattern, "namespace")
					return completions if (null != completions)
			case '.':
				for pattern in TYPE_PATTERNS:
					completions = CompleteNamespacesForPattern(context, pattern, "namespace")
					return completions if (null != completions)
				return CompleteMembers(context)
			otherwise:
				return null
		return null
				
	override def ShouldEnableCompletionFor(fileName as string):
		return Boo.MonoDevelop.ProjectModel.BooLanguageBinding.IsBooFile(fileName)
