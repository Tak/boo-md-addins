namespace Boo.Ide

import System

import Boo.Lang.Compiler.Ast

class MethodInvocationFinder(DepthFirstVisitor):
	_node as MethodInvocationExpression
	_name as string
	_file as string
	_line as int
	
	def constructor(name as string, file as string, line as int):
		_name = name
		_file = file
		_line = line
		
	def FindIn(root as Node):
		VisitAllowingCancellation(root)
		return _node
		
	override def LeaveMethodInvocationExpression(expression as MethodInvocationExpression):
		if (expression.LexicalInfo is null or expression.Target is null or expression.Target.Entity is null):
			return
		if not (expression.LexicalInfo.FileName.Equals(_file, StringComparison.OrdinalIgnoreCase) and \
		   expression.Target.Entity.Name == _name and \
		   expression.LexicalInfo.Line == _line):
			return
		Found(expression)
			
	protected def Found(node as MethodInvocationExpression):
		_node = node
		Cancel()
