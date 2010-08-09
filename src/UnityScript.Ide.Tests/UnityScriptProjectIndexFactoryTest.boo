namespace UnityScript.Ide.Tests

import System.IO
import System.Reflection

import NUnit.Framework
import UnityScript.Ide

import Boo.Ide
import Boo.Ide.Tests

[TestFixture]
class UnityScriptProjectIndexFactoryTest:
	
	[Test]
	def ProposalsForUnityScriptCode():
		
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		index.Update("code.js", "class Foo { function Bar() {} }; new Foo().$CursorLocation")
		proposals = index.ProposalsFor("code.js", "class Foo { function Bar() {} }; new Foo().$CursorLocation")
		
		expected = ("Bar",) + SystemObjectMemberNames()
		AssertProposalNames(expected, proposals)
		
	[Test]
	def UpdateModuleReturnsCodeWithUnityScriptSemantics():
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		module = index.Update("Code.js", "function foo() {}")
		expected = [|
			import UnityEngine
			import UnityEditor
			import System.Collections
			
			partial public class Code(Object):
				public virtual def foo() as void:
					pass
				public virtual def Main() as void:
					pass
				public def constructor():
					super()
		|]
		Assert.AreEqual(expected.ToCodeString(), module.ToCodeString())
		
	[Test]
	def ProposalsForExternalReferences():
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		index.AddReference(Assembly.Load("System.Xml"))
		code = ReIndent("""
import System.Xml;

class Foo
{
	static function foo() {
		new XmlDocument().$CursorLocation
	}
}
""")
		index.Update("code.js", code)
		proposals = index.ProposalsFor("code.js", code)
		for proposal in proposals:
			if(proposal.Entity.Name == "CreateXmlDeclaration"): return
		Assert.Fail("CreateXmlDeclaration not found in XmlDocument")
		
	[Test]
	def ProposalsForThis():
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		code = ReIndent("""
	function foo() {
		this.$CursorLocation
	}
""")
		index.Update("code.js", code)
		proposals = index.ProposalsFor("code.js", code)
		expected = ("foo",) + MonoBehaviourMemberNames()
		AssertProposalNames(expected, proposals)
		
	[Test]
	def ProposalsForSibling():
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		siblingCode = ReIndent("""
class Foo
{
	function foo() {
	}
}
""")
		code = ReIndent("""
class Bar
{
	function bar() {
		new Foo().$CursorLocation
	}
}
""")
		siblingFile = Path.GetTempFileName()
		File.WriteAllText(siblingFile, siblingCode)
		index.Update(siblingFile, siblingCode)
		index.Update("code.js", code)
		proposals = index.ProposalsFor("code.js", code)
		expected = ("foo",) + SystemObjectMemberNames()
		AssertProposalNames(expected, proposals)
		
	[Test]
	def StaticProposalsForSibling():
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		siblingCode = ReIndent("""
class Foo
{
	static function foo() {
	}
}
""")
		code = ReIndent("""
class Bar
{
	function bar() {
		Foo.$CursorLocation
	}
}
""")
		siblingFile = Path.GetTempFileName()
		File.WriteAllText(siblingFile, siblingCode)
		index.Update(siblingFile, siblingCode)
		index.Update("code.js", code)
		proposals = index.ProposalsFor("code.js", code)
		expected = ("foo","Equals","ReferenceEquals")
		AssertProposalNames(expected, proposals)
		
	[Test]
	def ProposalsForSiblingProject():
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		siblingIndex = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		siblingCode = ReIndent("""
class Foo
{
	function foo() {
	}
}
""")
		code = ReIndent("""
class Bar
{
	function bar() {
		new Foo().$CursorLocation
	}
}
""")
		siblingFile = Path.GetTempFileName()
		File.WriteAllText(siblingFile, siblingCode)
		siblingIndex.Update(siblingFile, siblingCode)
		index.AddReference(siblingIndex)
		index.Update("code.js", code)
		proposals = index.ProposalsFor("code.js", code)
		expected = ("foo",) + SystemObjectMemberNames()
		AssertProposalNames(expected, proposals)
		
	[Test]
	def ProposalsForMembersOfImplicitlyImportedTypes():
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		code = ReIndent("""
class Foo
{
	function foo() {
		ArrayList.$CursorLocation
	}
}
""")
		index.Update("code.js", code)
		proposals = index.ProposalsFor("code.js", code)
		expected = ["Adapter","Synchronized","ReadOnly","FixedSize","Repeat","Equals","ReferenceEquals"].ToArray(typeof(string))
		AssertProposalNames(expected, proposals)
		
	[Test]
	def ProposalsForTypeReferenceIncludeOnlyStaticMethods():
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		code = ReIndent("""
			class Foo {
				static function NewInstance(): Foo { return null; }
				function Bar(){}
			}
			Foo.$CursorLocation
		""")
		index.Update("code.js", code)
		proposals = index.ProposalsFor("code.js", code)
		expected = ("NewInstance", "Equals", "ReferenceEquals")
		AssertProposalNames(expected, proposals)
		
def ReIndent(code as string):	
	lines = NonEmptyLines(code)

	firstLine = lines[0]
	indentation = /(\s*)/.Match(firstLine).Groups[0].Value
	return code if len(indentation) == 0

	buffer = System.Text.StringBuilder()
	for line in lines:
		if not line.StartsWith(indentation):
			return code // let the parser complain about it
		buffer.AppendLine(line[len(indentation):])
	return buffer.ToString()
	