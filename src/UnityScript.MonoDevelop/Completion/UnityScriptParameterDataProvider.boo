namespace UnityScript.MonoDevelop.Completion

import System.Linq
import System.Collections.Generic

import MonoDevelop.Ide.Gui
import MonoDevelop.Ide.CodeCompletion
import Boo.Ide

class UnityScriptParameterDataProvider(IParameterDataProvider):
	_methods as List of MethodDescriptor
	_document as Document
	
	def constructor(document as Document, methods as List of MethodDescriptor):
		_methods = methods
		_document = document
		
	OverloadCount:
		get: return _methods.Count

	def GetCurrentParameterIndex(context as CodeCompletionContext):
		line = _document.TextEditor.GetLineText(context.TriggerLine)
		offset = _document.TextEditor.CursorColumn-2
		if(0 <= offset and offset < line.Length):
			stack = 0
			for i in range(offset, -1, -1):
				current = line[i:i+1]
				if (')' == current): --stack
				elif('(' == current): ++stack
			if (1 == stack):
				return /,/.Split(line[0:offset+1]).Length
		return -1


	def GetMethodMarkup(overloadIndex as int, parameterMarkup as (string), currentParameterIndex as int):
		method = _methods[overloadIndex]
		methodName = System.Security.SecurityElement.Escape(method.Name)
		methodReturnType = System.Security.SecurityElement.Escape(method.ReturnType)
		return "${methodName}(${string.Join(',',parameterMarkup)}): ${methodReturnType}"
		
	def GetParameterMarkup(overloadIndex as int, parameterIndex as int):
		return Enumerable.ElementAt(_methods[overloadIndex].Arguments, parameterIndex)
		
	def GetParameterCount(overloadIndex as int):
		return Enumerable.Count(_methods[overloadIndex].Arguments)
		
