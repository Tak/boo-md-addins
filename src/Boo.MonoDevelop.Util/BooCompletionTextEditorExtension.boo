namespace Boo.MonoDevelop.Util.Completion

import System
import System.Text.RegularExpressions

import Boo.Lang.PatternMatching
import Boo.Lang.Compiler.TypeSystem

import MonoDevelop.Projects
import MonoDevelop.Projects.Dom.Parser 
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
		
	abstract SelfReference as string:
		get: pass
		
	virtual def ProjectIndexFor(project as DotNetProject):
		return ProjectIndexFactory.ForProject(project)
		
	override def ExtendsEditor(doc as MonoDevelop.Ide.Gui.Document, editor as IEditableTextBuffer):
		return ShouldEnableCompletionFor(doc.Name)
				
	def ImportCompletionDataFor(nameSpace as string, filterMatches as MonoDevelop.Projects.Dom.MemberType*):
		result = CompletionDataList()
		
		seen = {}
		for member in _dom.GetNamespaceContents(nameSpace, true, true):
			if (member.Name in seen or \
			    (null != filterMatches and not member.MemberType in filterMatches)):
				continue
			seen.Add(member.Name, member)
			result.Add(member.Name, member.StockIcon)
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
			return ImportCompletionDataFor(nameSpace, filterMatches)
		return null
		
	def CompleteMembers(context as CodeCompletionContext):
		text = string.Format ("{0}{1} {2}", Document.TextEditor.GetText (0, context.TriggerOffset),
		                                    Boo.Ide.CursorLocation,
		                                    Document.TextEditor.GetText (context.TriggerOffset, Document.TextEditor.TextLength))
		# print text
		return CompleteMembersUsing(context, text)
		
	def CompleteMembersUsing(context as CodeCompletionContext, text as string):
		result = CompletionDataList()
		for proposal in _index.ProposalsFor(Document.FileName, text):
			member = proposal.Entity
			result.Add(member.Name, IconForEntity(member))
		return result
		
	def CompleteVisible(context as CodeCompletionContext):
		completions = CompletionDataList()
		text = string.Format ("{0}{1}.{2} {3}", Document.TextEditor.GetText (0, context.TriggerOffset-1),
		                                    SelfReference, Boo.Ide.CursorLocation,
		                                    Document.TextEditor.GetText (context.TriggerOffset, Document.TextEditor.TextLength))
		
		# Add members
		if (null != (tmp = CompleteMembersUsing(context, text))):
			completions.AddRange(tmp)
			
		# Add globally visible
		completions.AddRange(ImportCompletionDataFor(string.Empty, null))
		
		# TODO: Add locals
		
		return completions
		
	def GetLineText(line as int):
		return Document.TextEditor.GetLineText(line)
		
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
				

		
