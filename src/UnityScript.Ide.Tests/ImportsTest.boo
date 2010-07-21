namespace UnityScript.Ide.Tests

import System.Linq
import NUnit.Framework

import UnityScript.Ide

[TestFixture]
class ImportsTest:
	[Test]
	def ReturnsEmptyListForScriptWithNoImports():
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		code = ReIndent("""
class Foo{}
""")
		index.Update("blah.js", code)
		imports = index.ImportsFor("blah.js", code)
		Assert.IsNotNull(imports)
		Assert.AreEqual(3, Enumerable.Count(imports))

	[Test]
	def ReturnsNonEmptyListForScriptWithImports():
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		code = ReIndent("""
import System;
import System.Collections.Generic;
		
class Foo{}
""")
		index.Update("blah.js", code)
		imports = index.ImportsFor("blah.js", code)
		Assert.IsNotNull(imports)
		Assert.AreEqual(5, Enumerable.Count(imports))