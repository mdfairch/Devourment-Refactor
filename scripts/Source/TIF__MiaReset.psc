ScriptName TIF__MiaReset extends TopicInfo hidden


function Fragment_0(ObjectReference akSpeakerRef)
	Faction StrangerFaction = Game.GetFormFromFile(0xD00, "Devourment.esp") as Faction
	(akSpeakerRef as Actor).SetFactionRank(StrangerFaction, 0)
	(akSpeakerRef as Actor).RemoveFromFaction(StrangerFaction)
endFunction


function Fragment_1(ObjectReference akSpeakerRef)
	Faction StrangerFaction = Game.GetFormFromFile(0xD00, "Devourment.esp") as Faction
	(akSpeakerRef as Actor).SetFactionRank(StrangerFaction, 0)
	(akSpeakerRef as Actor).RemoveFromFaction(StrangerFaction)
endFunction
