namespace Boo.Ide.Tests

import NUnit.Framework

import Boo.Ide
import Boo.Lang.Compiler.MetaProgramming

[TestFixture]
class DotCompletionTest:
	
	[Test]
	def ProposalsForTypeInferredLocalVariable():
		
		code = """
			class Foo:
				def Bar():
					pass
					
			f = Foo()
			f.$CursorLocation
		"""
		
		proposals = ProposalsFor(code)
		
		expected = ("Bar",) + SystemObjectMemberNames()
		AssertProposalNames(expected, proposals)
		
	[Test]
	def ProposalsForTypeReferenceIncludeOnlyStaticMethods():
		code = """
			class Foo:
				static def NewInstance() as Foo:
					pass
				def Bar():
					pass
			Foo.$CursorLocation
		"""
		proposals = ProposalsFor(code)
		expected = ("NewInstance", "Equals", "ReferenceEquals")
		AssertProposalNames(expected, proposals)
		
	[Test]
	def ProposalsForNamespace():
		
		code = [|
			namespace MyLib
			class Foo:
				pass
		|]
		index = ProjectIndex()
		index.AddReference(compile(code))
		index.Update("code.boo", "MyLib.$CursorLocation")
		
		proposals = index.ProposalsFor("code.boo", "MyLib.$CursorLocation")
		AssertProposalNames(("Foo",), proposals)
		
	[Test]
	def ProposalsForInterfacesIncludeSuperInterfaceMembers():
		index = ProjectIndex()
		index.AddReference(typeof(ISub).Assembly)
		
		code = ReIndent("""
		v as $(typeof(ISub).BooTypeName())
		v.$CursorLocation
		""")
		index.Update("code.boo", code)
		proposals = index.ProposalsFor("code.boo", code)
		expected = ("SubMethod", "SuperMethod") + SystemObjectMemberNames()
		AssertProposalNames(expected, proposals)
		
	interface ISuper:
		def SuperMethod()
		
	interface ISub(ISuper):
		def SubMethod()
		
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
		
		proposals = ProposalsFor(code)
		expected = ("Foo",) + SystemObjectMemberNames()
		AssertProposalNames(expected, proposals)
		
	[Test]
	def ProposalsForOverloadedMethodsAppearOnlyOnceAsAnAmbiguousEntity():
		code = """
			class Super:
				virtual def Foo():
					pass
					
			class Sub(Super):
				override def Foo():
					pass
				
				def Foo(value as int):
					pass
					
			Sub().$CursorLocation
		"""
		proposals = ProposalsFor(code)
		expected = ("Foo",) + SystemObjectMemberNames()
		AssertProposalNames(expected, proposals)
		
	[Test]
	def ProposalsDontIncludeSpeciallyNamedMethods():
		index = ProjectIndex()
		index.AddReference(typeof(TypeWithSpecialMembers).Assembly)
		index.Update("code.boo", "$(typeof(TypeWithSpecialMembers).BooTypeName())().$CursorLocation")
		
		proposals = index.ProposalsFor("code.boo", "$(typeof(TypeWithSpecialMembers).BooTypeName())().$CursorLocation")
		expected = ("Name", "NameChanged") + SystemObjectMemberNames()
		AssertProposalNames(expected, proposals)
		
	class TypeWithSpecialMembers:
		Name:
			get: return ""
		event NameChanged as System.EventHandler
		
	[Test]
	def ProposalsForTypeInSeparateModule():
		
		subject = ProjectIndex()
		subject.Update("Foo.boo", ReIndent("""
			class Foo:
				def Bar():
					pass
		"""))
		
		expected = ("Bar",) + SystemObjectMemberNames()			
		for i in range(2):
			subject.Update("code.boo", "Foo().$CursorLocation")
			proposals = subject.ProposalsFor("code.boo", "Foo().$CursorLocation")
			AssertProposalNames(expected, proposals)
		
	[Test]
	def ProposalsForTypeInReferencedAssembly():
		
		subject = ProjectIndex()
		subject.AddReference(typeof(Foo).Assembly)
		
		subject.Update("code.boo", "$(typeof(Foo).BooTypeName())().$CursorLocation")
		proposals = subject.ProposalsFor("code.boo", "$(typeof(Foo).BooTypeName())().$CursorLocation")
		
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
		
		subject.Update("code.boo", "Foo().$CursorLocation")
		proposals = subject.ProposalsFor("code.boo", "Foo().$CursorLocation")
		expected = ("Bar",) + SystemObjectMemberNames()
		AssertProposalNames(expected, proposals)
		
[Extension] def BooTypeName(this as System.Type):
	return this.FullName.Replace('+', '.')
		
def ProposalsFor(code as string):
	index = ProjectIndex()
	index.Update("code.boo", ReIndent(code))
	return index.ProposalsFor("code.boo", ReIndent(code))
		
def AssertProposalNames(expected as (string), actual as (CompletionProposal)):
	if (expected is null or actual is null):
		Assert.AreEqual (expected, actual)
	else:
		Assert.AreEqual(expected.Length, actual.Length)
		for proposal in actual:
			Assert.Contains(proposal.Entity.Name, expected)
	
def SystemObjectMemberNames():
	return "Equals", "GetHashCode", "GetType", "ToString"
	
def MonoBehaviourMemberNames():
	return ("Main",) + SystemObjectMemberNames()
		
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