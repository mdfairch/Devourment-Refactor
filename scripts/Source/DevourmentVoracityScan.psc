scriptName DevourmentVoracityScan extends ActiveMagicEffect


DevourmentManager property Manager auto
Message property MainMenu auto


function OnEffectStart(actor akTarget, actor akCaster)
	Actor pred = akTarget
	
	float numVictims = Manager.getNumVictims(akTarget)
	float swallowBonus = Manager.getSwallowSkill(akTarget)
	float swallowResistance = Manager.getSwallowResistance(akTarget)
	float damage = Manager.getAcidDamage(akTarget, Manager.FakePlayer)
	float holdingTime = Manager.getHoldingTime(akTarget)
	float acidResistance = Manager.getAcidResistance(akTarget)
	
	MainMenu.show(numVictims, swallowBonus, swallowResistance, Damage, holdingTime, acidResistance)
endFunction
