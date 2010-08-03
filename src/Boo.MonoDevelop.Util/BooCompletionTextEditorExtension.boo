namespace Boo.MonoDevelop.Util.Completion

import System
import System.Threading
import System.Text.RegularExpressions

import Boo.Lang.PatternMatching
import Boo.Lang.Compiler.TypeSystem

import MonoDevelop.Projects
import MonoDevelop.Projects.Dom.Parser 
import MonoDevelop.Ide
import MonoDevelop.Ide.Gui
import MonoDevelop.Ide.Gui.Content
import MonoDevelop.Ide.CodeCompletion

import Boo.Ide
import Boo.MonoDevelop.Util

class BooCompletionTextEditorExtension(CompletionTextEditorExtension):
	
	_dom as ProjectDom
	_project as DotNetProject
	_index as ProjectIndex
	
	# Match imports statement and capture namespace
	static IMPORTS_PATTERN = /^\s*import\s+(?<namespace>[\w\d]+(\.[\w\d]+)*)?\.?\s*/
	
	override def Initialize():
		super()
		_dom = ProjectDomService.GetProjectDom(Document.Project) or ProjectDomService.GetFileDom(Document.FileName)
		_project = Document.Project as DotNetProject
		_index = ProjectIndexFor(_project)
		
	abstract def ShouldEnableCompletionFor(fileName as string) as bool:
		pass
		
	abstract def GetParameterDataProviderFor(methods as MethodDescriptor*) as IParameterDataProvider:
		pass
		
	abstract SelfReference as string:
		get: pass
		
	abstract EndStatement as string:
		get: pass
		
	abstract Keywords:
		get: pass
		
	abstract Primitives:
		get: pass
		
	virtual def ProjectIndexFor(project as DotNetProject):
		return ProjectIndexFactory.ForProject(project)
		
	override def ExtendsEditor(doc as MonoDevelop.Ide.Gui.Document, editor as IEditableTextBuffer):
		return ShouldEnableCompletionFor(doc.Name)
		
	override def HandleParameterCompletion(context as CodeCompletionContext, completionChar as char):
		if("(" != completionChar.ToString()):
			return null
			
		methodName = GetToken(context)
		code = "${Editor.GetText(0, context.TriggerOffset)})\n${Editor.GetText(context.TriggerOffset+1, Editor.TextLength)}"
		line = context.TriggerLine
		filename = Document.FileName
		
		methods = System.Collections.Generic.List of MethodDescriptor()
		try:
			methods = _index.MethodsFor(filename, code, methodName, line)
		except e:
			MonoDevelop.Core.LoggingService.LogError("Error getting methods", e)
		return GetParameterDataProviderFor(methods)
		
	override def CodeCompletionCommand(context as CodeCompletionContext):
		pos = context.TriggerOffset
		list = HandleCodeCompletion(context, Editor.GetText(pos-1, pos)[0])
		if list is null:
			list = CompleteVisible(context)
		return list
		
	def GetToken(context as CodeCompletionContext):
		line = GetLineText(context.TriggerLine)
		offset = context.TriggerLineOffset
		if(3 > offset or line.Length+1 < offset):
			return line.Trim()
			
		i = 0
		tokenStart = false
		for i in range(offset-3, -1, -1):
			if not char.IsWhiteSpace(line[i]):
				tokenStart = true
			if tokenStart and not (char.IsLetterOrDigit(line[i]) or '_' == line[i]):
				break
		if (0 == i and (char.IsLetterOrDigit(line[i]) or '_' == line[i])):
			start = 0
		else: start = i+1
		
		for i in range(offset-2, line.Length):
			if not (char.IsLetterOrDigit(line[i]) or '_' == line[i]):
				break
		end = i
		if (start < end):
			return line[start:end].Trim()
		return string.Empty
				
	def ImportCompletionDataFor(nameSpace as string, filterMatches as MonoDevelop.Projects.Dom.MemberType*, result as BooCompletionDataList):
		if(null == result):
			result = BooCompletionDataList()
		namespaces = List of string()
		namespaces.Add(nameSpace)
		
		if(string.IsNullOrEmpty(nameSpace)):
			text = Document.TextEditor.Text
			filename = Document.FileName
			
			work = def():
				for ns in _index.ImportsFor(filename, text):
					namespaces.AddUnique(ns)
				if (0 == namespaces.Count):
					callback = def():
						result.IsChanging = false
				else:
					callback = def():
						result.IsChanging = true
						seen = {}
						for ns in namespaces:
							for member in _dom.GetNamespaceContents(ns, true, true):
								if (member.Name in seen or \
								    (null != filterMatches and not member.MemberType in filterMatches)):
									continue
								seen.Add(member.Name, member)
								result.Add(CompletionData(member.Name, member.StockIcon))
						result.IsChanging = false
				DispatchService.GuiDispatch(callback)
			ThreadPool.QueueUserWorkItem(work)
		return result
		
	virtual def CompleteNamespace(context as CodeCompletionContext):
		return CompleteNamespacesForPattern(context, IMPORTS_PATTERN, "namespace", \
		        [MonoDevelop.Projects.Dom.MemberType.Namespace])
		
	virtual def CompleteNamespacesForPattern(context as CodeCompletionContext, pattern as Regex, \
		                                     capture as string, filterMatches as MonoDevelop.Projects.Dom.MemberType*):
		lineText = GetLineText(context.TriggerLine)
		matches = pattern.Match (lineText)
		
		if (null != matches and matches.Success and \
		    context.TriggerLineOffset > matches.Groups[capture].Index + matches.Groups[capture].Length):
			nameSpace = matches.Groups[capture].Value
			return ImportCompletionDataFor(nameSpace, filterMatches, null)
		return null
		
	def CompleteMembers(context as CodeCompletionContext):
		text = string.Format ("{0}{1} {2}", Document.TextEditor.GetText (0, context.TriggerOffset),
		                                    Boo.Ide.CursorLocation,
		                                    Document.TextEditor.GetText (context.TriggerOffset, Document.TextEditor.TextLength))
		# print text
		return CompleteMembersUsing(context, text, null)
		
	def CompleteMembersUsing(context as CodeCompletionContext, text as string, result as BooCompletionDataList):
		if(null == result): result = BooCompletionDataList()
		work = def():
			proposals =  _index.ProposalsFor(Document.FileName, text)
			if (0 == proposals.Length):
				callback = def():
					result.IsChanging = false
			else:
				callback = def():
					result.IsChanging = true
					for proposal in proposals:
						member = proposal.Entity
						result.Add(CompletionData(member.Name, IconForEntity(member), proposal.Description))
					result.IsChanging = false
			DispatchService.GuiDispatch(callback)
		ThreadPool.QueueUserWorkItem(work)
		return result
		
	def CompleteVisible(context as CodeCompletionContext):
		completions = BooCompletionDataList()
		completions.AddRange(CompletionData(k, Stock.Literal) for k in Keywords)
		completions.AddRange(CompletionData(p, Stock.Literal) for p in Primitives)
		text = string.Format ("{0}{1}.{2}{3} {4}", Document.TextEditor.GetText (0, context.TriggerOffset-1),
		                                    SelfReference, Boo.Ide.CursorLocation, EndStatement,
		                                    Document.TextEditor.GetText (context.TriggerOffset+1, Document.TextEditor.TextLength))
		
		# Add members
		CompleteMembersUsing(context, text, completions)
			
		# Add globally visible
		ImportCompletionDataFor(string.Empty, null, completions)
		work = def():
			locals = _index.LocalsAt(Document.FileName.FullPath, text, context.TriggerLine-1)
			if (0 == locals.Count):
				callback = def():
					completions.IsChanging = false
			else:
				callback = def():
					completions.IsChanging = true
					for local in locals:
						completions.Add(CompletionData(local, Stock.Field))
					completions.IsChanging = false
			DispatchService.GuiDispatch(callback)
		ThreadPool.QueueUserWorkItem (work)
		
		return completions
		
	def GetLineText(line as int):
		return Document.TextEditor.GetLineText(line)
		
	def StartsIdentifier(line as string, offset as int):
		startsIdentifier = false
		completionChar = line[offset]
		
		if(CanStartIdentifier(completionChar)):
			if(0 < offset and line.Length > offset):
				prevChar = line[offset-1]
				startsIdentifier = not (CanStartIdentifier(prevChar) or "."[0] == prevChar) # There's got to be a better way to do this
				
		return startsIdentifier
		
	def CanStartIdentifier(c as char):
		return char.IsLetter(c) or "_"[0] == c
		
	virtual def IsInsideComment(line as string, offset as int):
		tag = MonoDevelop.Projects.LanguageBindingService.GetBindingPerFileName(Document.FileName).SingleLineCommentTag
		index = line.IndexOf(tag)
		return 0 <= index and offset >= index
		
def IconForEntity(member as IEntity) as MonoDevelop.Core.IconId:
	match member.EntityType:
		case EntityType.BuiltinFunction:
			return Stock.Method
		case EntityType.Constructor:
			return Stock.Method
		case EntityType.Method:
			return Stock.Method
		case EntityType.Local:
			return Stock.Field
		case EntityType.Field:
			return Stock.Field
		case EntityType.Property:
			return Stock.Property
		case EntityType.Event:
			return Stock.Event
		case EntityType.Type:
			type as IType = member
			if type.IsEnum: return Stock.Enum
			if type.IsInterface: return Stock.Interface
			if type.IsValueType: return Stock.Struct
			return Stock.Class
		case EntityType.Namespace:
			return Stock.NameSpace
		case EntityType.Ambiguous:
			ambiguous as Ambiguous = member
			return IconForEntity(ambiguous.Entities[0])
		otherwise:
			return Stock.Literal
