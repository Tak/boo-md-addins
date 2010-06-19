namespace Boo.Ide.Tests

import NUnit.Framework

import Boo.Ide

[TestFixture]
class DotCompletionTest:
	
	[Test]
	def ProposalsForTypeInferredLocalVariable():
		
		code = ReIndent("""
			import System
			
			class Foo:
				def Bar():
					pass
					
			f = Foo()
			f.$CursorLocation
		""")
		
		proposals = ProjectIndex().ProposalsFor(code)
		
		expected = ("Bar",) + SystemObjectMemberNames()
		AssertProposalNames(expected, proposals)
		
	[Test]
	def ProposalsForTypeInSeparateModule():
		
		subject = ProjectIndex()
		subject.Update("Foo.boo", ReIndent("""
			class Foo:
				def Bar():
					pass
		"""))
		
		proposals = subject.ProposalsFor("Foo().$CursorLocation")
		expected = ("Bar",) + SystemObjectMemberNames()
		AssertProposalNames(expected, proposals)
		
	[Test]
	def ProposalsForTypeInReferencedAssembly():
		
		subject = ProjectIndex()
		subject.AddReference(typeof(Foo).Assembly)
		
		fooTypeName = typeof(Foo).FullName.Replace('+', '.')
		
		proposals = subject.ProposalsFor("$fooTypeName().$CursorLocation")
		
		expected = ("Bar",) + SystemObjectMemberNames()
		AssertProposalNames(expected, proposals)
		
	class Foo:
		def Bar():
			pass
		
	[Test]
	def ProposalsForTypeInReferencedProject():
		
		reference = ProjectIndex()
		reference.Update("Foo.boo", ReIndent("""
			class Foo:
				def Bar():
					pass
		"""))
		
		subject = ProjectIndex()
		subject.AddReference(reference)
		
		proposals = subject.ProposalsFor("Foo().$CursorLocation")
		expected = ("Bar",) + SystemObjectMemberNames()
		AssertProposalNames(expected, proposals)
		
	[Test]
	def ProposalsForSubClassDontIncludeInaccessibleMembersFromSuper():
		
		code = """
			class Super:
				def Foo():
					pass
				private def Bar(): 
					pass
					
			class Sub(Super):
				def constructor():
					self.$CursorLocation # can't access Bar from here
		"""
		
		proposals = ProjectIndex().ProposalsFor(ReIndent(code))
		expected = ("Foo",) + SystemObjectMemberNames()
		AssertProposalNames(expected, proposals)
		
def AssertProposalNames(expected as (string), actual as (CompletionProposal)):
	Assert.AreEqual(expected, array(proposal.Entity.Name for proposal in actual))
	
def SystemObjectMemberNames():
	return "Equals", "GetHashCode", "GetType", "ToString"
		
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
	
def NonEmptyLines(s as string):
	lines = s.Replace("\r\n", "\n").Split(char('\n'))
	return array(line for line in lines if len(line.Trim()))