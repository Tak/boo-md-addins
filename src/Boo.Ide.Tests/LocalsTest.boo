namespace Boo.Ide.Tests

import NUnit.Framework
import Boo.Ide

[TestFixture]
class LocalsTest:
	[Test]
	def ReturnsNoLocals():
		code = ReIndent("""
class Foo:
	baz = 4.2
	def Bar():
		cursorgoeshere
		
	def Blah()
		blah = 12
""")
		index = ProjectIndex()
		index.Update("/foo.boo", code)
		locals = index.LocalsAt("/foo.boo", code, 5)
		Assert.IsEmpty(locals)
		
	[Test]
	def ReturnsCorrectLocals():
		code = ReIndent("""
class Foo:
	def Bar():
		baz = 4.2
		cursorgoeshere
		
	def Blah()
		blah = 12
""")
		index = ProjectIndex()
		index.Update("/foo.boo", code)
		locals = index.LocalsAt("/foo.boo", code, 5)
		Assert.Contains("baz", locals)
		Assert.IsFalse(locals.Contains("blah"))
		
	[Test]
	def ReturnsMethodParams():
		code = ReIndent("""
class Foo:
	def Bar(baz as int):
		foo = 4.2
		cursorgoeshere
		
	def Blah(blah as int)
		blah = 12
""")
		index = ProjectIndex()
		index.Update("/foo.boo", code)
		locals = index.LocalsAt("/foo.boo", code, 5)
		Assert.Contains("baz", locals)
		Assert.IsFalse(locals.Contains("blah"))
		
	[Test]
	def ReturnsConstructorParams():
		code = ReIndent("""
class Foo:
	def constructor(baz as int):
		baz = 4.2
		cursorgoeshere
		
	def Blah(blah as int)
		blah = 12
""")
		index = ProjectIndex()
		index.Update("/foo.boo", code)
		locals = index.LocalsAt("/foo.boo", code, 5)
		Assert.Contains("baz", locals)
		Assert.IsFalse(locals.Contains("blah"))
		
		
