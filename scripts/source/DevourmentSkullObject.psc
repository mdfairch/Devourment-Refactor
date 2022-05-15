ScriptName DevourmentSkullObject extends ObjectReference
import Logging


;Actor property PlayerRef auto
;Keyword property DevourmentSkull auto
;DevourmentManager property Manager auto

Actor Prey
; PERSISTENCE NOTES: "When any variable in a currently loaded script points at a reference, that reference is temporarily persistent. 
; It will stay persistent until no variables are pointing at it any more, at which point it will unload. (This assumes no other game system is keeping the object alive) 
; This means that you should try not to have variables holding on to objects any longer then you need them. You can clear variables by assigning "None" to them." 
; https://www.creationkit.com/index.php?title=Persistence_(Papyrus)#Variables
;
; We used to use LinkedRef and StorageUtil as solutions for keeping Prey persistent and stored in Skull objects. We did this because this would
; allow us to keep Actors persistent without increasing save script data / papyrus heap size, instead offloading to the SKSE co-save. Unfortunately both these methods were not always reliable.
; So for now, we're just going to use a known safe method, an Actor Var, even though it adds a bit of weight to the save.


String PREFIX = "DevourmentSkullObject"


bool Function IsInitialized()
	return Prey != None ;self.GetLinkedRef(DevourmentSkull) != None
EndFunction


Actor Function GetRevivee()
	;Actor revivee = self.GetLinkedRef(DevourmentSkull) as Actor
	;if !revivee
	;	revivee = Prey
	;endIf
	;if revivee == none
	;	revivee = StorageUtil.GetFormValue(self, "DevourmentRevivee") as Actor
	;endIf
	return Prey ;revivee
EndFunction


Function InitializeFor(Actor thePrey)
	;Log1(PREFIX, "InitializeFor", Namer(thePrey))
	SetDisplayName(Namer(thePrey, true) + "'s Skull")
	;PO3_SKSEFunctions.SetLinkedRef(self, thePrey, DevourmentSkull)
	;StorageUtil.SetFormValue(self, "DevourmentRevivee", thePrey)
	Prey = thePrey
EndFunction


;Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
	;PO3_SKSEFunctions.SetLinkedRef(self, Prey, DevourmentSkull)
;endEvent
