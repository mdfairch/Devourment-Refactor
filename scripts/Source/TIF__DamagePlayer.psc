scriptName TIF__DamagePlayer extends TopicInfo hidden


float property damage = 0.0 auto


function Fragment_0(ObjectReference akSpeakerRef)
	doDamage(Game.getPlayer())
endFunction


function Fragment_1(ObjectReference akSpeakerRef)
	doDamage(Game.getPlayer())
endFunction


Function doDamage(Actor target)
	if damage > 0.0
		float health = target.getActorValue("health")
		if damage < health
			target.damageActorValue("health", health - damage)
		endIf
	endIf
EndFunction
