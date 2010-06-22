namespace Boo.MonoDevelop.Util

import Boo.Ide
import MonoDevelop.Projects
import Boo.Lang.Compiler.Util
import System.Linq.Enumerable

interface IBooIdeLanguageBinding:	
	def ProjectIndexFor(project as DotNetProject) as ProjectIndex
	
class BooIdeLanguageBinding(IBooIdeLanguageBinding):
	
	_projectIndexFor = MemoizedFunction[of DotNetProject, ProjectIndex](NewProjectIndexFor)
	
	def constructor():
		LogError "$(GetType())()"
	
	[lock]
	def ProjectIndexFor(project as DotNetProject):
		return _projectIndexFor.Invoke(project)
		
	protected virtual def NewProjectIndexFor(project as DotNetProject):
		LogError "NewProjectIndexFor($project)"
		index = ProjectIndex()
		AddReferencesTo(index, project)
		return index
		
	protected def AddReferencesTo(index as ProjectIndex, project as DotNetProject):
		for reference in project.References:
			AddReferenceTo(index, reference)
		
	protected def AddReferenceTo(index as ProjectIndex, reference as ProjectReference):		
		if ReferenceType.Project == reference.ReferenceType:
			projectName = reference.Reference
			project = ProjectIndexFor(projectName)
			if project is not null:
				index.AddReference(project) 
			else:
				LogError "Project '$projectName' not found!"
		else:
			for file in reference.GetReferencedFileNames(Workspace.ActiveConfiguration):
				assembly = LoadAssembly(file)
				index.AddReference(assembly) if assembly is not null
				
	protected def ProjectIndexFor(projectName as string) as ProjectIndex:
		return ProjectIndexFor(Workspace.GetAllProjects().FirstOrDefault({ p as Project | p.Name == projectName }))
				
	Workspace:
		get: return MonoDevelop.Ide.IdeApp.Workspace
				
	def LoadAssembly(file as string):
		try:
			return System.Reflection.Assembly.LoadFrom(file)
		except x:
			LogError x
			return null

		

