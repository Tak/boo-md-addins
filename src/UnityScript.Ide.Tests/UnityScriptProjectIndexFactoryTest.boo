namespace UnityScript.Ide.Tests

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

