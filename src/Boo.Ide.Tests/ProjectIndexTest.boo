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
		
		m = Module()
		parser = BooCompiler()
		parser.Parameters.Pipeline = CompilerPipeline()
		parser.Parameters.Pipeline.Add(ActionStep({ my(CompileUnit).Modules.Add(m) }))
		
		compiled = false
		compiler = BooCompiler()
		compiler.Parameters.Pipeline = CompilerPipeline()
		compiler.Parameters.Pipeline.Add(ActionStep({ compiled = true }))
		
		index = ProjectIndex(compiler, parser)
		assert index.Update("code.js", "") is m
		
		assert not compiled
		assert index.ProposalsFor("code.js", "") is not null
		assert compiled
		
	class ActionStep(AbstractCompilerStep):
		
		_action as System.Action
		
		def constructor(action as System.Action):
			_action = action
			
		override def Run():
			_action()
		
		
		
		

		
