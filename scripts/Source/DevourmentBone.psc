scriptName DevourmentBone extends ObjectReference


;-- Properties --------------------------------------
ObjectReference property MainRemains auto


;-- Functions ---------------------------------------


function OnActivate(ObjectReference akActionRef)
	MainRemains.Activate(akActionRef, false)
endFunction
