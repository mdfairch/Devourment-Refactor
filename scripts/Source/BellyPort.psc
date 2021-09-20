scriptName Bellyport extends ActiveMagicEffect


DevourmentManager property Manager auto
Explosion property visual auto
Spell property predSpell auto
Message property StomachCapacity auto


function OnEffectStart(Actor akTarget, Actor akCaster)
	if Manager.isFull(akCaster)
		if akCaster == Game.GetPlayer()
			StomachCapacity.show()
		endif
		self.dispel()		
	elseif akTarget.getLevel() > 25
		self.dispel()
	else
		akTarget.placeatme(visual, 1, false, false)
		Manager.registerDigestion(akCaster, akTarget, false, 1)
		;predSpell.Cast(akTarget, akCaster)
	endIf
endFunction
