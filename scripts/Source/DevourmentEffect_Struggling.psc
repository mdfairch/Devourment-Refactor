ScriptName DevourmentEffect_Struggling extends ActiveMagicEffect
import Logging


DevourmentManager property Manager auto
Actor property PlayerRef auto
Perk property ConstrictingGrip auto
CommonMeterInterfaceHandler property PlayerStruggleMeter auto


String PREFIX = "DevourmentEffect_Struggling"
bool DEBUGGING
Actor pred
int preyData
bool constricted
float cameraShake
float struggleDifficulty 
float struggleDamage
float struggleProgress
String playerName 


Event OnEffectStart(Actor target, Actor caster)
	DEBUGGING = Manager.DEBUGGING
	preyData = Manager.GetPreyData(PlayerRef)
	playerName = Namer(PlayerRef, true)
	struggleProgress = 0.0

	pred = Manager.GetPred(preyData)
	constricted = pred.hasPerk(ConstrictingGrip)
	cameraShake = Manager.cameraShake
	struggleDifficulty = Manager.struggleDifficulty
	struggleDamage = Manager.GetStruggleDamage(pred, PlayerRef)
	
	if DEBUGGING
		!assertNotNone(PREFIX, "Struggle", "pred", pred)
		!assertExists(PREFIX, "Struggle", "preyData", preyData)
		Log3(PREFIX, "OnEffectStart", Namer(pred), constricted, struggleDamage)
	endIf
	
	RegisterForModEvent("Devourment_PlayerStruggle", "OnPlayerStruggle")
EndEvent


Event OnEffectFinish(Actor target, Actor caster)
	PlayerStruggleMeter.RemoveMeter()
EndEvent


Event OnPlayerLoadGame()
	RegisterForModEvent("Devourment_PlayerStruggle", "OnPlayerStruggle")
EndEvent


Event OnPlayerStruggle(bool successful, float times)
{ Resolves struggle attempts. }
	if DEBUGGING
		Log3(PREFIX, "Struggle", successful, times, struggleProgress)
	endIf

	; Chance in the struggle bar.
	float increment = struggleDifficulty * times
	float damage = struggleDamage * times

	if constricted
		increment *= 0.2
	else
		Manager.GivePredXP_async(pred, damage / 5.0)
	endIf
	
	if successful
		struggleProgress += increment
		if struggleProgress > 100.0
			struggleProgress = 100.0
		endIf
		Manager.GivePreyXP_async(PlayerRef, damage / 5.0)
	else
		struggleProgress -= increment
		if struggleProgress < 0.0
			struggleProgress = 0.0
		endIf
	endIf

	; Struggle damage dealt to pred.
	Manager.playGurgle(pred, 10.0 * times)

	if cameraShake > 0.0 && Utility.RandomFloat() < times
		Game.ShakeCamera(pred, cameraShake)
	endIf

	; Vomit the prey if they've filled the strugglebar.
	if struggleProgress >= 100.0
		Manager.CheckAndSetPartingGift(pred, PlayerRef)
		Manager.UpdateStruggleMeter(PlayerRef, 100.0)
		Manager.ForceEscape(PlayerRef)
	else
		UpdateStruggleMeter(struggleProgress)
	endIf

	if !successful
		return
	endIf
	
	; Apply damage and show notifications.
	if constricted
		if DEBUGGING
			ConsoleUtil.PrintMessage(PlayerName + " struggled " + struggleProgress as int + " percent free.")
		endIf
	else
		pred.DamageActorValue("Health", damage)
		if DEBUGGING
			ConsoleUtil.PrintMessage(PlayerName + " struggled " + struggleProgress as int + " percent free, causing " + damage + " damage.")
		endIf
	endIf
EndEvent


Function updateStruggleMeter(float struggle)
	PlayerStruggleMeter.AttributeValue.setValue(struggle)
	PlayerStruggleMeter.UpdateMeter(true)
endFunction	
