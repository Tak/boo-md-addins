namespace Boo.MonoDevelop.Util.Completion

import System
import MonoDevelop.Ide.Gui
import MonoDevelop.Ide.CodeCompletion

class BooCompletionDataList(CompletionDataList,IMutableCompletionDataList):
	event Changed as EventHandler
	event Changing as EventHandler
	
	_isChanging as bool
	
	public IsChanging as bool:
		get: return _isChanging
		set: 
			_isChanging = value
			if (value):
				OnChanging(self, null)
			else: OnChanged(self, null)
		
	def Dispose():
		pass
		
	virtual def AddRange (items):
		for item in items: Add(item)
		
	virtual def OnChanging(sender, args as EventArgs):
		if(null != Changing):
			Changing(sender, args)

	virtual def OnChanged(sender, args as EventArgs):
		if(null != Changed):
			Changed(sender, args)
		