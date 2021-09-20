scriptName TIF__SwallowBounty extends TopicInfo hidden


bool property endo = false autoreadonly


function Fragment_0(ObjectReference akSpeakerRef)
	Actor speaker = akSpeakerRef as Actor
	speaker.GetCrimeFaction().SetCrimeGold(0)
	speaker.GetCrimeFaction().SetCrimeGoldViolent(0)
	
	DevourmentManager manager = DevourmentManager.instance()
	manager.playerRef.stopCombatAlarm()

	GetOwningQuest().SetStage(3)
	manager.ForceSwallow(speaker, manager.playerRef, endo)
endFunction