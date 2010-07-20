namespace Boo.MonoDevelop.Util.Completion

import System
import MonoDevelop.Ide.CodeCompletion

class BooCompletionDataList(CompletionDataList,IMutableCompletionDataList):
	event Changed as EventHandler
	event Changing as EventHandler
	
	_isChanging as bool
	
	public IsChanging as bool:
		get: return _isChanging
		set: 
			oldIsChanging = _isChanging
			_isChanging = value
			if (value and not oldIsChanging):
				OnChanging(self, null)
			elif (oldIsChanging and not value):
				OnChanged(self, null)
			
	def constructor():
		super()
		IsChanging = true
		
	def Dispose():
		pass
		
	new def Add(item as CompletionData):
		(self as CompletionDataList).Add(item)
		
	new def AddRange(items as CompletionData*):
		(self as CompletionDataList).AddRange(items)
		
	protected virtual def OnChanging(sender, args as EventArgs):
		if(null != Changing):
			Changing(sender, args)

	protected virtual def OnChanged(sender, args as EventArgs):
		if(null != Changed):
			Changed(sender, args)
		