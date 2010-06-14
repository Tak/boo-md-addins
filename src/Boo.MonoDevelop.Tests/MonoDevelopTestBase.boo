namespace Boo.MonoDevelop.Tests

import System
import System.IO
import NUnit.Framework
import MonoDevelop
import MonoDevelop.Projects.Dom.Parser
import MonoDevelop.Ide
import Gtk from "gtk-sharp" as Gtk

class MonoDevelopTestBase:

	static firstRun = true
	
	[TestFixtureSetUp]
	virtual def SetUp():
		if firstRun:
			rootDir = PathCombine(TmpDir, "config")
			try:
				firstRun = false
				InternalSetup(rootDir)
			except:
				// if we encounter an error, try to re create the configuration directory
				// (This takes much time, therfore it's only done when initialization fails)
				try:
					if Directory.Exists(rootDir):
						Directory.Delete(rootDir, true)
					InternalSetup(rootDir)
				except x:
					print "failed to initialize MD:", x
					
	static def InternalSetup(rootDir as string):
		print rootDir
		Environment.SetEnvironmentVariable("MONO_ADDINS_REGISTRY", rootDir)
		Environment.SetEnvironmentVariable("XDG_CONFIG_HOME", rootDir)
		Core.Runtime.Initialize(true)
		Gtk.Application.Init()
		ProjectDomService.TrackFileChanges = true
		DesktopService.Initialize()
		MonoDevelop.Projects.Services.ProjectService.DefaultTargetFramework = Core.Runtime.SystemAssemblyService.GetTargetFramework("2.0")
		
	[TestFixtureTearDown]
	virtual def TearDown():
		pass
