namespace Boo.Ide.Tests

import NUnit.Framework

import Boo.Ide

[TestFixture]
class MethodsTest:
	[Test]
	def ReturnsCorrectNumberOfOverloads():
		index = ProjectIndex()
		code = ReIndent("""
class Foo:
	def blah():
		foo = System.Collections.Generic.List of string()
		foo.CopyTo()
""")
		methods = index.MethodsFor("foo.boo", code, "CopyTo", 5)
		Assert.AreEqual(3, methods.Count) # List<>.CopyTo has 3 overloads

	[Test]
	def ReturnsNoMethodsWhenInvalid():
		index = ProjectIndex()
		code = ReIndent("""
class Foo:
	def blah():
		foo = string.Empty
		foo.ThisMethodDoesNotAndNeverWillExist()
""")
		methods = index.MethodsFor("foo.boo", code, "ThisMethodDoesNotAndNeverWillExist", 5)
		Assert.AreEqual(0, methods.Count)
		