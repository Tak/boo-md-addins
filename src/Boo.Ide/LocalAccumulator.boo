namespace Boo.Ide

import System
import System.Collections.Generic
import Boo.Lang.Compiler.Ast

class LocalAccumulator(DepthFirstVisitor):
	_filename as string
	_line as int
	_enabled as Stack of bool
	_results as System.Collections.Generic.List of string
	
	def constructor(filename as string, line as int):
		_filename = filename
		_line = line
		
	[lock]
	def FindIn(root as Node):
		_results = System.Collections.Generic.List of string()
		_enabled = Stack of bool()
		Visit(root)
		return _results
		
	override def LeaveMethod(method as Method):
		if (null != method.LexicalInfo and method.LexicalInfo.FullPath.Equals(_filename, StringComparison.OrdinalIgnoreCase) and \
		    method.LexicalInfo.Line <= _line and method.EndSourceLocation.Line >= _line):
		    for local in method.Locals:
		    	_results.Add(local.Name)
		    for param in method.Parameters:
		    	_results.Add(param.Name)
		
