Scriptname DevourmentForceSwallow extends ActiveMagicEffect  
import Logging


String property PREFIX = "DevourmentForceSwallow" autoreadonly


Event OnEffectStart(Actor akTarget, Actor akCaster)
	if !assertNotNone(PREFIX, "OnEffectStart", "akTarget", akTarget) \
	|| !assertNotNone(PREFIX, "OnEffectStart", "akCaster", akCaster)
		return
	endIf

	; Send an event to any other instances of this MagicEffect that are running.
	; If the caster is recasting this, the first instance will catch the event.
	int handle = ModEvent.create("DevourmentForceSwallow_Recast")
	ModEvent.pushForm(handle, akTarget)
	ModEvent.pushForm(handle, akCaster)
	ModEvent.Send(handle)
	
	; Register for subsequent recasts.
	RegisterForModEvent("DevourmentForceSwallow_Recast", "onRecast")
EndEvent


Event onRecast(Form f1, Form f2)
	if !(f1 && f2 && f1 as Actor && f2 as Actor)
		assertNotNone(PREFIX, "onRecast", "f1", f1)
		assertNotNone(PREFIX, "onRecast", "f2", f2)
		assertAs(PREFIX, "onRecast", f1, f1 as Actor)
		assertAs(PREFIX, "onRecast", f2, f2 as Actor)
		return
	endIf
	
	Actor pred = self.getTargetActor()
	Actor prey = f1 as Actor
	Actor eventCaster = f2 as Actor
	Actor selfCaster = self.getCasterActor()
	
	if pred != prey && eventCaster == selfCaster
		DevourmentManager.instance().ForceSwallow(pred, prey, false)
	endIf
EndEvent
