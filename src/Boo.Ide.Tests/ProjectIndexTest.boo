namespace Boo.Ide.Tests

import Boo.Lang.Environments

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.Steps

import NUnit.Framework

import Boo.Ide

[TestFixture]
class ProjectIndexTest:
	
	[Test]
	def CustomParserAndProposalCompiler():
		
		m = Module(LexicalInfo("code.js"))
		parser = BooCompiler()
		parser.Parameters.Pipeline = CompilerPipeline() { ActionStep({ my(CompileUnit).Modules.Add(m) }) }
		
		compiled = false
		compiler = BooCompiler()
		compiler.Parameters.Pipeline = CompilerPipeline() { ActionStep({ compiled = true }) }
		
		index = ProjectIndex(compiler, parser, ["UnityEngine"])
		Assert.AreSame(m, index.Update("code.js", ""))
		
		assert index.ProposalsFor("code.js", "") is not null
		assert compiled

