ScriptName TIF__LethalDisablePlayer extends DialogueVore hidden


function Fragment_0(ObjectReference akSpeakerRef)
	LethalDisable(Resolve(akSpeakerRef), Game.GetPlayer())
endFunction


function Fragment_1(ObjectReference akSpeakerRef)
	LethalDisable(Resolve(akSpeakerRef), Game.GetPlayer())
endFunction
