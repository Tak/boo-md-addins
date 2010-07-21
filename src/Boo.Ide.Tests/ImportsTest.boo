namespace Boo.Ide.Tests

import System.Linq
import NUnit.Framework

import Boo.Ide

[TestFixture]
class ImportsTest:
	[Test]
	def ReturnsEmptyListForScriptWithNoImports():
		index = ProjectIndex()
		code = ReIndent("""
class Foo:
	pass
""")
		index.Update("blah.boo", code)
		imports = index.ImportsFor("blah.boo", code)
		Assert.IsNotNull(imports)
		Assert.AreEqual(2, Enumerable.Count(imports))

	[Test]
	def ReturnsNonEmptyListForScriptWithImports():
		index = ProjectIndex()
		code = ReIndent("""
import System
import System.Collections.Generic
		
class Foo:
	pass
""")
		index.Update("blah.boo", code)
		imports = index.ImportsFor("blah.boo", code)
		Assert.IsNotNull(imports)
		Assert.AreEqual(4, Enumerable.Count(imports))