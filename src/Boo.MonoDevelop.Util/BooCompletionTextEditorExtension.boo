namespace Boo.MonoDevelop.Util.Completion

import System
import System.Collections.Generic

import Boo.Lang.PatternMatching
import Boo.Lang.Compiler.IO
import Boo.Lang.Compiler.TypeSystem

import MonoDevelop.Projects
import MonoDevelop.Projects.Dom.Parser 
import MonoDevelop.Ide.Gui
import MonoDevelop.Ide.Gui.Content
import MonoDevelop.Ide.CodeCompletion

class BooCompletionTextEditorExtension(CompletionTextEditorExtension):
	
	_dom as ProjectDom
	_resolver as CompletionTypeResolver
	_project as DotNetProject
	
	# Match imports statement and capture namespace
	static IMPORTS_PATTERN = /^\s*import\s+(?<namespace>[\w\d]+(\.[\w\d]+)*)?\.?\s*/
	
	override def Initialize():
		super()
		_dom = ProjectDomService.GetProjectDom(Document.Project) or ProjectDomService.GetFileDom(Document.FileName)
		_project = Document.Project as DotNetProject
		InitializeProject()
		
	virtual def InitializeProject():
		if _project is null:
			return
				
		# Add references
		for reference in _project.References:
			if ReferenceType.Project != reference.ReferenceType:
				_resolver.AddReference(reference.Reference)
				
	virtual def ImportCompletionDataFor(nameSpace as string):
		result = CompletionDataList()
		
		seen = {}
		for member in _dom.GetNamespaceContents(nameSpace, true, true):
			if member.Name in seen: continue
			seen.Add(member.Name, member)
			result.Add(member.Name, member.StockIcon)
		return result
		
	virtual def GetIconForMember(member as IEntity):
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
			otherwise:
				return Stock.Literal
				
	virtual def SanitizeMemberName(type as IType,memberName as string) as string:
		name = memberName
		if (0 <= (lastDot = name.LastIndexOf('.'))):
			name = name[lastDot+1:]
		if ("constructor" == name or "ctor" == name):
			name = type.Name
		if (name.StartsWith("internal_", StringComparison.OrdinalIgnoreCase) or name.StartsWith("op_", StringComparison.Ordinal)):
			name = string.Empty
		return name
		
	virtual def CompleteNamespace(context as CodeCompletionContext):
		lineText = GetLineText(context.TriggerLine)
		matches = IMPORTS_PATTERN.Match (lineText)
		if (null != matches and matches.Success and context.TriggerLineOffset > lineText.IndexOf ("imports")+6):
			nameSpace = matches.Groups["namespace"].Value
			return ImportCompletionDataFor(nameSpace)
		return null
		
	virtual def CompleteMembers(context as CodeCompletionContext):
		text = string.Format ("{0}{1} {2}", Document.TextEditor.GetText (0, context.TriggerOffset),
		                                    CompletionFinder.CompletionToken,
		                                    Document.TextEditor.GetText (context.TriggerOffset, Document.TextEditor.TextLength))
		# print text
		_resolver.Input.Clear()
		_resolver.Input.Add(StringInput("completion text", text))
		
		result = CompletionDataList()
		resultHash = Dictionary[of string,string]()
		
		_resolver.ResolveAnd() do (type as IType):
			# print type
			domType = _dom.GetType(type.FullName)
			if (null != domType):
				for member in domType.Members:
					resultHash[SanitizeMemberName(type,member.Name)] = member.StockIcon
			else:
				for member in type.GetMembers():
					# print member
					resultHash[SanitizeMemberName(type,member.Name)] = GetIconForMember(member)
			
			for pair in resultHash:
				valid = not string.IsNullOrEmpty(pair.Key)
				for prefix as string in ["get_","set_","add_","remove_"]:
					if (pair.Key.StartsWith(prefix, StringComparison.Ordinal) and \
					    resultHash.ContainsKey(pair.Key[prefix.Length:])):
						valid = false
				if (valid):
					result.Add(pair.Key, pair.Value)

		return result
		
	def GetLineText(line as int):
		return Document.TextEditor.GetLineText(line)
		
