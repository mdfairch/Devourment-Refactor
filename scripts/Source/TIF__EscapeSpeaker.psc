ScriptName TIF__EscapeSpeaker extends DialogueVore hidden


bool property oralEscape = true auto


function Fragment_0(ObjectReference akSpeakerRef)
	Escape(Game.GetPlayer(), Resolve(akSpeakerRef), oralEscape)
endFunction


function Fragment_1(ObjectReference akSpeakerRef)
	Escape(Game.GetPlayer(), Resolve(akSpeakerRef), oralEscape)
endFunction
