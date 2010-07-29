namespace Boo.MonoDevelop.Util

import MonoDevelop.Projects
import Boo.Ide
import UnityScript.Ide
	
static class ProjectIndexFactory:
	indices = System.Collections.Generic.Dictionary[of DotNetProject,ProjectIndex]()
	
	def ForProject(project as DotNetProject):
		if project is null:
			return ProjectIndex()
		if indices.ContainsKey(project):
			return indices[project]
		if not (project isa IBooIdeLanguageBinding):
			indices[project] = MixedProjectIndex(project, ProjectIndex(), UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex())
		else:
			languageBinding as IBooIdeLanguageBinding = project.LanguageBinding
			indices[project] = languageBinding.ProjectIndexFor(project)
		return indices[project]
			
def LogError(x):
	System.Console.Error.WriteLine(x)
	