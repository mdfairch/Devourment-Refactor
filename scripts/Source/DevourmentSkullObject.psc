ScriptName DevourmentSkullObject extends ObjectReference
import Logging


Actor property PlayerRef auto
Keyword property DevourmentSkull auto
DevourmentManager property Manager auto


String PREFIX = "DevourmentSkullObject"


bool Function IsInitialized()
	return self.GetLinkedRef(DevourmentSkull) != None
EndFunction


Actor Function GetRevivee()
	Actor revivee = self.GetLinkedRef(DevourmentSkull) as Actor
	if revivee == none
		revivee = StorageUtil.GetFormValue(self, "DevourmentRevivee") as Actor
	endIf
	return revivee
EndFunction


Function InitializeFor(Actor thePrey)
	Log1(PREFIX, "InitializeFor", Namer(thePrey))
	SetDisplayName(Namer(thePrey, true) + "'s Skull")
	PO3_SKSEFunctions.SetLinkedRef(self, thePrey, DevourmentSkull)
	StorageUtil.SetFormValue(self, "DevourmentRevivee", thePrey)
EndFunction


Event OnInit()
	Log0(PREFIX, "OnInit")
EndEvent


Event OnLoad()
	Log0(PREFIX, "OnLoad")
EndEvent


Event OnUnload()
	Log0(PREFIX, "OnUnload")
EndEvent


Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
	PO3_SKSEFunctions.SetLinkedRef(self, (storageutil.GetFormValue(self as Form, "DevourmentRevivee", none) as actor), DevourmentSkull)
endEvent
