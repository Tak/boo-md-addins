namespace UnityScript.Ide.Tests

import NUnit.Framework
import UnityScript.Ide

[TestFixture]
class LocalsTest:
	[Test]
	def ReturnsNoLocals():
		code = ReIndent("""
class Foo{
	var baz = 4.2;
	function Bar(){
		cursorgoeshere
	}
		
	function Blah(){
		var blah = 12;
	}
}
""")
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		index.Update("/foo.js", code)
		locals = index.LocalsAt("/foo.js", code, 5)
		Assert.IsEmpty(locals)
		
	[Test]
	def ReturnsCorrectLocals():
		code = ReIndent("""
class Foo{
	function Bar(){
		baz = 4.2;
		cursorgoeshere
	}
		
	function Blah(){
		blah = 12;
	}
}
""")
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		index.Update("/foo.js", code)
		locals = index.LocalsAt("/foo.js", code, 5)
		Assert.Contains("baz", locals)
		Assert.IsFalse(locals.Contains("blah"))
		
	[Test]
	def ReturnsMethodParams():
		code = ReIndent("""
class Foo{
	function Bar(baz: int){
		baz = 4.2;
		cursorgoeshere
	}
		
	function Blah(blah: int){
		blah = 12;
	}
}
""")
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		index.Update("/foo.js", code)
		locals = index.LocalsAt("/foo.js", code, 5)
		Assert.Contains("baz", locals)
		Assert.IsFalse(locals.Contains("blah"))
		
	[Test]
	def ReturnsConstructorParams():
		code = ReIndent("""
class Foo{
	function Foo(baz: int){
		baz = 4.2;
		cursorgoeshere
	}
		
	function Blah(blah: int){
		blah = 12;
	}
}
""")
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		index.Update("/foo.js", code)
		locals = index.LocalsAt("/foo.js", code, 5)
		Assert.Contains("baz", locals)
		Assert.IsFalse(locals.Contains("blah"))
		
		
