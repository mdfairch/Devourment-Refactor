scriptName DevourmentEffect_WeightChange extends ActiveMagicEffect
import Logging


DevourmentManager property Manager auto
DevourmentWeightManager property WeightManager auto
Explosion property AbsorbExplosion auto
bool property Gain auto
String PREFIX = "DevourmentEffect_WeightChange"

event OnEffectStart(Actor akTarget, Actor akCaster)
{ Event received when this effect is first started (OnInit may not have been run yet!) }
	if !akTarget
		assertNotNone(PREFIX, "OnEffectStart", "akTarget", akTarget)
		return
	endif

	float magnitude = GetMagnitude()
	float increment = magnitude / 10.0
	int count = 10

	if Gain
		if WeightManager.GetCurrentActorWeight(akTarget) < WeightManager.MaximumWeight
			akTarget.PlaceAtme(AbsorbExplosion)

			while count && WeightManager.GetCurrentActorWeight(akTarget) < WeightManager.MaximumWeight
				count -= 1
				WeightManager.ChangeActorWeight(akTarget, increment)
				Utility.wait(0.1)
			endWhile
		endIf
	else
		if WeightManager.GetCurrentActorWeight(akTarget) > WeightManager.MinimumWeight
			akTarget.PlaceAtme(AbsorbExplosion)

			while count && WeightManager.GetCurrentActorWeight(akTarget) > WeightManager.MinimumWeight
				count -= 1
				WeightManager.ChangeActorWeight(akTarget, -increment)
				Utility.wait(0.1)
			endWhile
		endIf
	endIf

	Log3(PREFIX, "OnEffectStart", magnitude, gain, Namer(akTarget))
EndEvent