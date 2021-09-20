ScriptName TIF__EscapePrey extends TopicInfo hidden


FavorDialogueScript property Generic = None auto
bool property intimidate = false auto
bool property persuade = false auto
bool property bribe = false auto
bool property oralEscape = true auto


function Fragment_0(ObjectReference akSpeakerRef)
	escape(akSpeakerRef as Actor)
endFunction


function Fragment_1(ObjectReference akSpeakerRef)
	escape(akSpeakerRef as Actor)
endFunction


Function escape(Actor target)
	if Generic
		if persuade
			Generic.Persuade(target)
		elseif bribe
			Generic.Bribe(target)
		elseif intimidate
			Generic.Intimidate(target)
		endif
	endif

	DevourmentManager manager = DevourmentManager.instance()
	Form[] stomach = Manager.GetStomachArray(target)
	
	if !stomach || !stomach.length || !stomach[0]
		return
	endIf
	
	int preyIndex = stomach.length
	while preyIndex
		preyIndex -= 1
		Actor prey = stomach[preyIndex] as Actor
		if prey && Manager.AreFriends(Manager.playerRef, prey)
			manager.ForceEscape(prey)
			return
		endIf
	endWhile
EndFunction
