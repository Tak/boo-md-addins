namespace Boo.Ide

import System

import Boo.Lang.Compiler.TypeSystem

class MethodDescriptor:
	_name as string
	_arguments as string*
	_returnType as string
	
	Name:
		get: return _name
	Arguments:
		get: return _arguments
	ReturnType:
		get: return _returnType
		
	def constructor(method as IMethod):
		_name = method.Name
		arguments = System.Collections.Generic.List of string()
		for param in method.GetParameters():
			arguments.Add("${param.Name} as ${param.Type}")
		_arguments = arguments
		_returnType = "${method.ReturnType}"
