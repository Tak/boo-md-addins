namespace Boo.MonoDevelop.Completion

import System
import Boo.Lang.PatternMatching

import MonoDevelop.Projects.Dom
import MonoDevelop.Ide.CodeCompletion

import Boo.MonoDevelop.Util.Completion

class BooEditorCompletion(BooCompletionTextEditorExtension):
	
	# Match "blah as [...]" pattern
	static AS_PATTERN = /\bas\s+(?<namespace>[\w\d]+(\.[\w\d]+)*)?\.?/
	
	# Match "Blah[of ...]" pattern
	static OF_PATTERN = /\bof\s+(?<namespace>[\w\d]+(\.[\w\d]+)*)?\.?/
	
	# Patterns that result in us doing a type completion
	static TYPE_PATTERNS = [OF_PATTERN, AS_PATTERN]
	
	# Patterns that result in us doing a namespace completion
	static NAMESPACE_PATTERNS = [IMPORTS_PATTERN]
	
	override def Initialize():
		super()

	override def HandleCodeCompletion(context as CodeCompletionContext, completionChar as char):
#		print "HandleCodeCompletion(${context.ToString()}, ${completionChar.ToString()})"
		
		match completionChar.ToString():
			case " ":
				if (null != (completions = CompleteNamespacePatterns(context))):
					return completions
				return CompleteTypePatterns(context)
			case ".":
				if (null != (completions = CompleteNamespacePatterns(context))):
					return completions
				elif (null != (completions = CompleteTypePatterns(context))):
					return completions
				return CompleteMembers(context)
			otherwise:
				return null
		return null
				
	def CompleteNamespacePatterns(context as CodeCompletionContext):
		completions as CompletionDataList = null
		types = List[of MemberType]()
		types.Add(MemberType.Namespace)
		
		for pattern in NAMESPACE_PATTERNS:
			return completions if (null != (completions = CompleteNamespacesForPattern(context, pattern,
			                                              "namespace", types)))
		return null
		
	def CompleteTypePatterns(context as CodeCompletionContext):
		completions as CompletionDataList = null
		types = List[of MemberType]()
		types.Add(MemberType.Namespace)
		types.Add(MemberType.Type)
		
		for pattern in TYPE_PATTERNS:
			return completions if (null != (completions = CompleteNamespacesForPattern(context, pattern,
			                                              "namespace", types)))
		return null
			
	override def ShouldEnableCompletionFor(fileName as string):
		return Boo.MonoDevelop.ProjectModel.BooLanguageBinding.IsBooFile(fileName)
	
	override SelfReference:
		get: return "self"
