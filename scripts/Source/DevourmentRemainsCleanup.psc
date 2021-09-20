scriptName DevourmentRemainsCleanup extends ObjectReference
import Logging


ObjectReference property DungGathererChest auto


float property UpdateInterval = 24.0 auto
GlobalVariable property CleanupMultiplier auto


Event OnInit()
	self.RegisterForSingleUpdateGameTime(UpdateInterval)
EndEvent


Event OnLoad()
	self.RegisterForSingleUpdateGameTime(UpdateInterval)
endEvent


Event OnUnload()
	;self.removeAllItems(DungGathererChest, false, true)
EndEvent


auto State Full
	Event OnUpdateGameTime()
		self.removeAllItems(DungGathererChest, false, true)
		self.RegisterForSingleUpdateGameTime(CleanupMultiplier.GetValue() * UpdateInterval)
		GotoState("Emptied")
	endEvent
endState


State Emptied
	Event OnUpdateGameTime()
		self.removeAllItems(DungGathererChest, false, true)
		Utility.wait(5.0)
		self.disable(false)
		self.delete()
	endEvent
endState
