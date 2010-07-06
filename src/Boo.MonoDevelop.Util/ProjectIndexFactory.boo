namespace Boo.MonoDevelop.Util

import MonoDevelop.Projects
import Boo.Ide
import UnityScript.Ide
	
static class ProjectIndexFactory:
	
	def ForProject(project as DotNetProject):
		
		if project is null:
			return ProjectIndex()
		if not (project isa IBooIdeLanguageBinding):
			return MixedProjectIndex(project, ProjectIndex(), UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex())
			
		languageBinding as IBooIdeLanguageBinding = project.LanguageBinding
		return languageBinding.ProjectIndexFor(project)
			
def LogError(x):
	System.Console.Error.WriteLine(x)
	