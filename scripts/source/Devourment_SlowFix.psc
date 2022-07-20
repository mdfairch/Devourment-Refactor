Scriptname Devourment_slowfix extends activemagiceffect  
{ Taken from Devious Devices Expansion. }


DevourmentMCM property Menu auto


Event OnEffectStart(Actor akTarget, Actor akCaster)
;This pings skyrim to make it notice player's speed has changed!
	;if !Menu.FoundBugFixesSSE ;Commented out until AE builds are more mature.
		akTarget.DamageAv("CarryWeight", 0.02)
		akTarget.RestoreAv("CarryWeight", 0.02)
	;endIf
EndEvent


Event OnEffectFinish(Actor akTarget, Actor akCaster)
;This pings skyrim to make it notice player's speed has changed!
	;if !Menu.FoundBugFixesSSE
		akTarget.DamageAv("CarryWeight", 0.02)
		akTarget.RestoreAv("CarryWeight", 0.02)
	;endIf
EndEvent
