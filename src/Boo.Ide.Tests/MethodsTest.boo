namespace Boo.Ide.Tests

import NUnit.Framework

import Boo.Ide

[TestFixture]
class MethodsTest:
	[Test]
	def FirstTest():
		index = ProjectIndex()
		code = ReIndent("""
class Foo:
	def blah():
		foo = System.Collections.Generic.List of string()
		foo.CopyTo()
""")
		methods = index.MethodsFor("foo.boo", code, "CopyTo", 5)
		Assert.AreEqual(3, methods.Count) # List<>.CopyTo has 3 overloads
