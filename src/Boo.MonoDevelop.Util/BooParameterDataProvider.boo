namespace Boo.MonoDevelop.Util

import MonoDevelop.Ide.CodeCompletion

class BooParameterDataProvider(IParameterDataProvider):
	OverloadCount:
		get: return 1

	def GetCurrentParameterIndex(context as CodeCompletionContext):
		return -1

	def GetMethodMarkup(overloadIndex as int, parameterMarkup as (string), currentParameterIndex as int):
		return string.Empty
		
	def GetParameterMarkup(overloadIndex as int, parameterIndex as int):
		return string.Empty
		
	def GetParameterCount(overloadIndex as int):
		return 0
		
