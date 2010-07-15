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
		proposals = index.ProposalsFor("code.js", "class Foo { function Bar() {} }; new Foo().$CursorLocation")
		
		expected = ("Bar",) + SystemObjectMemberNames()
		AssertProposalNames(expected, proposals)
		
	[Test]
	def UpdateModuleReturnsCodeWithUnityScriptSemantics():
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		module = index.Update("Code.js", "function foo() {}")
		expected = ReIndent("""
		partial class Code(object):
			public virtual def foo():
				pass
			public virtual def Main():
				pass
		""")
		Assert.AreEqual(NonEmptyLines(expected), NonEmptyLines(module.ToCodeString()))
		
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
		proposals = index.ProposalsFor("code.js", code)
		for proposal in proposals:
			if(proposal.Entity.Name == "CreateXmlDeclaration"): return
		Assert.Fail("CreateXmlDeclaration not found in XmlDocument")
		
	[Test]
	def ProposalsForThis():
		index = UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
		code = ReIndent("""
class Foo
{
	function foo() {
		this.$CursorLocation
	}
}
""")
		proposals = index.ProposalsFor("code.js", code)
		expected = ("foo",) + SystemObjectMemberNames()
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
		proposals = index.ProposalsFor("code.js", code)
		expected = ("foo",) + SystemObjectMemberNames()
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
		proposals = index.ProposalsFor("code.js", code)
		CollectionAssert.IsNotEmpty(proposals)
		
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
	