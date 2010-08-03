namespace UnityScript.MonoDevelop.Completion

import System
import System.Collections.Generic

import MonoDevelop.Core
import MonoDevelop.Projects.Dom
import MonoDevelop.Ide.Gui
import MonoDevelop.Ide.CodeCompletion

import Boo.Lang.PatternMatching

import Boo.Ide
import Boo.MonoDevelop.Util.Completion

class UnityScriptEditorCompletion(BooCompletionTextEditorExtension):

	# Match "blah = new [...]" pattern
	static NEW_PATTERN = /\bnew\s+(?<namespace>[\w\d]+(\.[\w\d]+)*)?\.?/
	
	# Match "var blah: [...]" pattern
	static COLON_PATTERN = /\w\s*:\s*(?<namespace>[\w\d]+(\.[\w\d]+)*)?\.?/
	
	# Patterns that result in us doing a type completion
	static TYPE_PATTERNS = [NEW_PATTERN, COLON_PATTERN]
	
	# Patterns that result in us doing a namespace completion
	static NAMESPACE_PATTERNS = [IMPORTS_PATTERN]
	
	# Delimiters that indicate a literal
	static LITERAL_DELIMITERS = ['"']
	
	# Scraped from UnityScript.g
	private static KEYWORDS = [
		"as",
		"break",
		"catch",
		"class",
		"continue",
		"else",
		"enum",
		"extends",
		"false",
		"final",
		"finally",
		"for",
		"function",
		"get",
		"if",
		"import",
		"implements",
		"in",
		"interface",
		"instanceof",
		"new",
		"null",
		"return",
		"public",
		"protected",
		"internal",
		"override",
		"partial",
		"pragma",
		"private",
		"set",
		"static",
		"super",
		"this",
		"throw",
		"true",
		"try",
		"typeof",
		"var",
		"virtual",
		"while",
		"yield",  
		"switch",
		"case",
		"default"
	]
	
	# Scraped from Types.cs
	private static PRIMITIVES = [        
		"byte",
		"sbyte",
		"short",
		"ushort",
		"int",
		"uint",
		"long",
		"ulong",
		"float",
		"double",
		"decimal",
		"void",
		"string",
		"object"
	]
	
	override Keywords:
		get: return KEYWORDS
		
	override Primitives:
		get: return PRIMITIVES
	
	override def Initialize():
		InstallUnityScriptSyntaxModeIfNeeded()
		super()
		
	def InstallUnityScriptSyntaxModeIfNeeded():
		view = Document.GetContent[of MonoDevelop.SourceEditor.SourceEditorView]()
		return if view is null
		
		mimeType = UnityScript.MonoDevelop.ProjectModel.UnityScriptParser.MimeType
		return if view.Document.SyntaxMode.MimeType == mimeType
		
		mode = Mono.TextEditor.Highlighting.SyntaxModeService.GetSyntaxMode(mimeType)
		if mode is not null:
			view.Document.SyntaxMode = mode
		else:
			LoggingService.LogWarning(GetType() + " could not get SyntaxMode for mimetype '" + mimeType + "'.")
	
	override def HandleCodeCompletion(context as CodeCompletionContext, completionChar as char):
		triggerWordLength = 0
		HandleCodeCompletion(context, completionChar, triggerWordLength)
	
	override def HandleCodeCompletion(context as CodeCompletionContext, completionChar as char, ref triggerWordLength as int):
		# print "HandleCodeCompletion(${context.ToString()}, '${completionChar.ToString()}')"
		line = GetLineText(context.TriggerLine)

		if (IsInsideComment(line, context.TriggerLineOffset-2) or \
		    IsInsideLiteral(line, context.TriggerLineOffset-2)):
			return null
		
		match completionChar.ToString():
			case " ":
				if (null != (completions = CompleteNamespacePatterns(context))):
					return completions
				return CompleteTypePatterns(context)
			case ":":
				return CompleteTypePatterns(context)
			case ".":
				if (null != (completions = CompleteNamespacePatterns(context))):
					return completions
				elif (null != (completions = CompleteTypePatterns(context))):
					return completions
				return CompleteMembers(context)
			otherwise:
				if(CanStartIdentifier(completionChar)):
					if(StartsIdentifier(line, context.TriggerLineOffset-2)):
						# Necessary for completion window to take first identifier character into account
						--context.TriggerOffset 
						triggerWordLength = 1
						return CompleteVisible(context)
					else:
						offset = context.TriggerLineOffset-3
						if(0 <= offset and line.Length > offset and "."[0] == line[offset]):
							--context.TriggerOffset
							triggerWordLength = 1
							return CompleteMembers(context)
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
			
			if (null != (completions = CompleteNamespacesForPattern(context, pattern, "namespace", types))):
				completions.AddRange(CompletionData(p, Stock.Literal) for p in Primitives)
				return completions
		return null
			
	override def ShouldEnableCompletionFor(fileName as string):
		return UnityScript.MonoDevelop.IsUnityScriptFile(fileName)
		
	def IsInsideLiteral(line as string, offset as int):
		fragment = line[0:offset+1]
		for delimiter in LITERAL_DELIMITERS:
			list = List[of string]()
			list.Add(delimiter)
			if(0 == fragment.Split(list.ToArray(), StringSplitOptions.None).Length%2):
				return true
		return false
	
	override SelfReference:
		get: return "this"
		
	override EndStatement:
		get: return ";"
	
	override def GetParameterDataProviderFor(methods as MethodDescriptor*):
		return UnityScriptParameterDataProvider(Document, methods)
