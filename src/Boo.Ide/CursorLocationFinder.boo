namespace Boo.Ide

import Boo.Lang.Compiler.Ast
import Boo.Adt

let CursorLocation = "__cursor_location__"

class CursorLocationFinder(DepthFirstVisitor):
	
	_node as Expression
		
	def FindIn(root as Node):
		VisitAllowingCancellation(root)
		return _node
			
	override def LeaveMemberReferenceExpression(node as MemberReferenceExpression):
		if node.Name != CursorLocation:
			return
		Found(node)
			
	protected def Found(node):
		_node = node
		Cancel()
		
