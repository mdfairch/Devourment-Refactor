ScriptName TIF__MiaOverride extends TopicInfo hidden


int property Override = -1 auto
bool property NoEscape = false auto
bool property Consented = false auto


function Fragment_0(ObjectReference akSpeakerRef)
	Override(akSpeakerRef as Actor)
endFunction


function Fragment_1(ObjectReference akSpeakerRef)
	Override(akSpeakerRef as Actor)
endFunction


Function override(Actor target)
	DevourmentManager manager = DevourmentManager.instance()

	if Override >= 0
		Faction StrangerFaction = Game.GetFormFromFile(0xD00, "Devourment.esp") as Faction
		target.SetFactionRank(StrangerFaction, Override)
	endIf

	if consented
		manager.VoreConsent(target)
	endIf
	
	if NoEscape
		manager.DisableEscape(target)
	endIf
endFunction
