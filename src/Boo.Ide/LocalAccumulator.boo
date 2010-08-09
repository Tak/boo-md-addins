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
		_filename = System.IO.Path.GetFullPath(filename)
		_line = line
		
	[lock]
	def FindIn(root as Node):
		_results = System.Collections.Generic.List of string()
		_enabled = Stack of bool()
		Visit(root)
		return _results
		
	override def LeaveMethod(method as Method):
		AddMethodParams(method)
		
	override def LeaveConstructor(method as Constructor):
		AddMethodParams(method)
		    	
	private def AddMethodParams(method as Method):
		if method.LexicalInfo is null: return
		if not method.LexicalInfo.FullPath.Equals(_filename, StringComparison.OrdinalIgnoreCase): return
		if _line < method.LexicalInfo.Line or _line > method.EndSourceLocation.Line: return
		
		for local in method.Locals:
			_results.Add(local.Name)
		for param in method.Parameters:
			_results.Add(param.Name)
		    	
