ScriptName DevourmentBellyport extends ActiveMagicEffect
import Logging


Actor property PlayerRef auto
DevourmentManager property Manager auto
Explosion property Graphics auto
Message property Message_Full auto


String PREFIX = "Devourment_Bellyport"


Event OnEffectStart(Actor prey, Actor pred)
	;Log3(PREFIX, "OnEffectStart", prey.GetLevel(), aggression, magnitude)
	
	if !(pred && pred)
		assertNotNone(PREFIX, "OnEffectStart", "pred", pred)
		assertNotNone(PREFIX, "OnEffectStart", "prey", prey)
		return
	endif
	
	if prey.isChild() || pred.isChild() 
		dispel()
		return
	elseif prey.GetLevel() > pred.GetLevel() || (pred != playerRef && Manager.IsFull(pred))
		return
	elseif pred == PlayerRef && !Manager.DEBUGGING && !Manager.HasRoomForPrey(pred, prey)
		Manager.HelpAgnosticMessage(Message_Full, "DVT_FULL", 3.0, 0.1)
		Manager.PlayerFullnessMeter.ForceMeterDisplay(true)
		return
	endIf
	
	prey.placeatme(Graphics, 1, false, false)
	Manager.RegisterDigestion(pred, prey, false, 0)
EndEvent
