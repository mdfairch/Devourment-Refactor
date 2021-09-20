Scriptname DevourmentEffect_Weasel extends ActiveMagicEffect
import Logging


DevourmentManager property Manager auto
Actor property PlayerRef auto
Explosion property AbsorbExplosion auto


String PREFIX = "DevourmentEffect_Weasel"
String HEADNODE = "NPC Head [Head]"
Actor target = none
Actor caster = none
bool isFemale
float scale = 1.0
float endScale = 3.0
float delta = 0.075
float interval = 0.10


Event OnEffectStart(Actor akTarget, Actor akCaster)
	if !assertNotNone(PREFIX, "OnEffectStart", "akTarget", akTarget)
		Dispel()
		return 
	endIf

	target = akTarget
	caster = akCaster

	if target == PlayerRef
		Game.ForceThirdPerson()
	elseif caster == PlayerRef
		target.SendAssaultAlarm()
	endIf

	isFemale = Manager.IsFemale(target)
	caster.pushActorAway(target, 0.5)
	RegisterForSingleUpdate(1.0)
EndEvent


Event OnUpdate()
	scale += delta * Utility.RandomFloat()
	NIOverride.AddNodeTransformScale(target, false, isFemale, HEADNODE, PREFIX, scale)
	NIOverride.UpdateNodeTransform(target, false, isFemale, HEADNODE)

	if target == PlayerRef && scale > 2.5 && Utility.RandomInt() < 10
		Game.ShakeCamera(target, 0.5, 0.5)
		Game.ShakeController(0.5, 0.2, 0.2)
	endIf

	if scale > endscale
		Dispel()
	else
		RegisterForSingleUpdate(interval)
	endIf
EndEvent


Event OnEffectFinish(Actor akTarget, Actor akCaster)
	NIOverride.AddNodeTransformScale(target, false, isFemale, HEADNODE, PREFIX, 0.01)
	NIOverride.UpdateNodeTransform(target, false, isFemale, HEADNODE)

	ObjectReference expl = akTarget.PlaceAtme(AbsorbExplosion)
	expl.MoveTo(akTarget, 0.0, 0.0, 100.0)

	if target == PlayerRef
		Game.ShakeCamera(target, 1.0, 1.0)
		Game.ShakeController(1.0, 0.5, 2.0)
		Utility.wait(1.5)
	endIf

	ActorBase preyBase = target.GetActorBase()
	bool wasProtected = preyBase.isProtected()
	bool wasEssential = preyBase.isEssential()
	preyBase.SetInvulnerable(false)

	if wasProtected
		preyBase.setProtected(false)
	endIf
	if wasEssential
		preyBase.setEssential(false)
	endIf

	target.Kill(caster)
	
	if wasProtected
		preyBase.setProtected(true)
	endIf
	if wasEssential
		preyBase.setEssential(true)
	endIf
EndEvent
