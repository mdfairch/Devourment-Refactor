Scriptname DevourmentSound extends ActiveMagicEffect
{Playes a looping sound for magic effects.}


Sound property MySoundLoop auto
int soundInstance 


Event OnEffectStart(Actor Target, Actor Caster)
	; Sound on
	if target
		soundInstance = MySoundLoop.play(Target) 
	elseif Caster
		soundInstance = MySoundLoop.play(Caster) 
	endIf
EndEvent


Event OnEffectFinish(Actor Target, Actor Caster)
	;Stop  sound
	Sound.StopInstance(soundInstance)
EndEvent
