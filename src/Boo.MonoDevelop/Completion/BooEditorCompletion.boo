namespace Boo.MonoDevelop.Completion

import System

import Boo.MonoDevelop.Util.Completion

class BooEditorCompletion(BooCompletionTextEditorExtension):
	
	override def ShouldEnableCompletionFor(fileName as string):
		return Boo.MonoDevelop.ProjectModel.BooLanguageBinding.IsBooFile(fileName)
