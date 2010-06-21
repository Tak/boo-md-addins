namespace Boo.MonoDevelop.Tests

import MonoDevelop.Projects.Dom
import NUnit.Framework
import Boo.MonoDevelop.ProjectModel

[TestFixture]
class BooResolverTest(MonoDevelopTestBase):

	[Test]
	def CursorAtClassHeaderResolvesToClass():
		code = """namespace BooResolverTest
class Foo:
	def Bar():
		pass
"""

		project = CreateSingleFileProject("BooResolverTest", code)
		dom = GetProjectDom(project)
		type = dom.GetType("BooResolverTest.Foo")
		assert type is not null
		
		result = BooResolver(dom, type.CompilationUnit, "Foo.boo").Resolve(
						ExpressionResult("class Foo:\n"),
						DomLocation(2, 8)) as MemberResolveResult
						
		assert result is not null
		Assert.AreEqual(type.FullName, result.ResolvedMember.FullName)
		
		
		
		