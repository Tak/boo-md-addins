namespace Boo.MonoDevelop.Completion

import System

import MonoDevelop.Projects
import MonoDevelop.Ide.Gui.Content
import MonoDevelop.Ide.CodeCompletion

import Boo.Lang.Compiler.IO
import Boo.Lang.PatternMatching

import Boo.MonoDevelop.Util.Completion

class BooEditorCompletion(BooCompletionTextEditorExtension):
	
	override def Initialize():
		_resolver = CompletionTypeResolver()
		super()

	override def InitializeProject():
		super()
		
		if _project is null:
			return
				
		# Add other project files
		for file as ProjectFile in [projectFile for projectFile in _project.Files if \
		    Boo.MonoDevelop.ProjectModel.BooLanguageBinding.IsBooFile(projectFile.FilePath) and not \
		    projectFile.FilePath.FullPath.ToString().Equals(Document.FileName.FullPath.ToString(), StringComparison.OrdinalIgnoreCase)]:
			_resolver.Input.Add(FileInput(file.FilePath.FullPath))
		
		
	override def ExtendsEditor(doc as MonoDevelop.Ide.Gui.Document, editor as IEditableTextBuffer):
		return Boo.MonoDevelop.ProjectModel.BooLanguageBinding.IsBooFile(doc.Name)
		
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
				
	