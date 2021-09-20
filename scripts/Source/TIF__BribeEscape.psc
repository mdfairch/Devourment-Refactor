scriptName TIF__BribeEscape extends TopicInfo hidden


bool property oralEscape = false autoReadOnly


function Fragment_0(ObjectReference akSpeakerRef)
	int goldAmount = Game.getPlayer().GetGoldAmount()
	Form gold = Game.GetForm(0x0000000F)
	Game.getPlayer().removeItem(gold, goldAmount, false, akSpeakerRef)

	DevourmentManager.instance().forceEscape(Game.getPlayer())
endFunction
