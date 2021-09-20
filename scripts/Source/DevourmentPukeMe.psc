Scriptname DevourmentPukeMe extends ActiveMagicEffect  


Event OnEffectStart(Actor akTarget, Actor akCaster)
	DevourmentManager.instance().ForceEscape(akCaster)
EndEvent
