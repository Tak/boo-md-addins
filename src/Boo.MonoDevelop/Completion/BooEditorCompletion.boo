namespace Boo.MonoDevelop.Completion

import System
import System.Collections.Generic

import MonoDevelop.Projects
import MonoDevelop.Projects.Dom.Parser 
import MonoDevelop.Ide.Gui
import MonoDevelop.Ide.Gui.Content
import MonoDevelop.Ide.CodeCompletion

import Boo.Lang.Compiler.IO
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.PatternMatching

class BooEditorCompletion(CompletionTextEditorExtension):
	
	_dom as ProjectDom
	_resolver as BooCompletionTypeResolver
	_project as DotNetProject
	
	override def Initialize():
		super()
		_dom = ProjectDomService.GetProjectDom(Document.Project) or ProjectDomService.GetFileDom(Document.FileName)
		_resolver = BooCompletionTypeResolver()
		_project = Document.Project as DotNetProject
		InitializeProjectReferences()
		
	def InitializeProjectReferences():
		if _project is null:
			return
				
		for reference in _project.References:
			if ReferenceType.Project != reference.ReferenceType:
				_resolver.AddReference(reference.Reference)
		
		
	override def ExtendsEditor(doc as MonoDevelop.Ide.Gui.Document, editor as IEditableTextBuffer):
		return System.IO.Path.GetExtension(doc.Name) == ".boo"
		
	override def HandleCodeCompletion(context as CodeCompletionContext, completionChar as char):
#		print "HandleCodeCompletion(${context.ToString()}, ${completionChar.ToString()})"
		
		match completionChar.ToString():
			case ' ':
				lineText = GetLineText(context.TriggerLine)
				if not lineText.StartsWith("import "):
					return null
					
				return ImportCompletionDataFor('')
				
			case '.':
				lineText = GetLineText(context.TriggerLine)
				lineLength = lineText.Length
				lineText = lineText.TrimStart()
				trimmedLength = lineLength - lineText.Length
				if lineText.StartsWith("import "):
					nameSpace = lineText[len("import "):context.TriggerLineOffset-(2+trimmedLength)].Trim()
					return ImportCompletionDataFor(nameSpace)
					
				result = null as CompletionDataList
				text = string.Format ("{0}{1} {2}", Document.TextEditor.GetText (0, context.TriggerOffset),
				                                    CompletionFinder.CompletionToken,
				                                    Document.TextEditor.GetText (context.TriggerOffset, Document.TextEditor.TextLength))
				print text
				_resolver.Input.Clear()
				_resolver.Input.Add(StringInput("completion text", text))
				
				result = CompletionDataList()
					
				_resolver.ResolveAnd() do (type as IType):
					print type
					resultHash = Dictionary[of string,string]()
					for member in type.GetMembers():
						print member
						resultHash[SanitizeMemberName(type,member)] = GetIconForMember(member)
					for pair in resultHash:
						unless string.IsNullOrEmpty(pair.Key) or (4 < pair.Key.Length and /^[gs]et_/.Matches(pair.Key) and resultHash.ContainsKey(pair.Key[4:])):
							result.Add(pair.Key, pair.Value)
       
				return result
				
			otherwise:
				return null
				
	def ImportCompletionDataFor(nameSpace as string):
#		print "ImportCompletionDataFor(${nameSpace})"
		
		result = CompletionDataList()
		
		seen = {}
		for member in _dom.GetNamespaceContents(nameSpace, true, true):
			if member.Name in seen: continue
			seen.Add(member.Name, member)
			result.Add(member.Name, member.StockIcon)
		return result
				
	def GetLineText(line as int):
		return Document.TextEditor.GetLineText(line)
		
	def GetIconForMember(member as IEntity):
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
				
	def SanitizeMemberName(type as IType,member as IEntity) as string:
		name = member.Name
		if (0 <= (lastDot = name.LastIndexOf('.'))):
			name = name[lastDot+1:]
		if ("constructor" == name):
			name = type.Name
		if (name.StartsWith("internal_", StringComparison.OrdinalIgnoreCase)):
			name = string.Empty
		return name
		
	