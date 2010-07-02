namespace Boo.MonoDevelop.Completion

import System.Linq
import System.Collections.Generic

import MonoDevelop.Ide.CodeCompletion
import Boo.Ide

class BooParameterDataProvider(IParameterDataProvider):
	_methods as List of MethodDescriptor
	
	def constructor(methods as List of MethodDescriptor):
		_methods = methods
		
	OverloadCount:
		get: return _methods.Count

	def GetCurrentParameterIndex(context as CodeCompletionContext):
		return -1

	def GetMethodMarkup(overloadIndex as int, parameterMarkup as (string), currentParameterIndex as int):
		method = _methods[overloadIndex]
		formatString = "${method.Name}({0}) as ${method.ReturnType}"
		return System.Security.SecurityElement.Escape(string.Format(formatString, string.Join(',',parameterMarkup)))
		
	def GetParameterMarkup(overloadIndex as int, parameterIndex as int):
		return Enumerable.ElementAt(_methods[overloadIndex].Arguments, parameterIndex)
		
	def GetParameterCount(overloadIndex as int):
		return Enumerable.Count(_methods[overloadIndex].Arguments)
		
