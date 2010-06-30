namespace Boo.MonoDevelop.Util

import MonoDevelop.Projects
import Boo.Ide
	
static class ProjectIndexFactory:
	
	def ForProject(project as DotNetProject):
		
		if project is null:
			return ProjectIndex()
			
		languageBinding as IBooIdeLanguageBinding = project.LanguageBinding
		return languageBinding.ProjectIndexFor(project)
			
def LogError(x):
	System.Console.Error.WriteLine(x)
	