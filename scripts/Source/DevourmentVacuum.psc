ScriptName DevourmentVacuum extends ActiveMagicEffect
{
DOESN'T WORK PROPERLY
* Haven't found a good balance for the havok force that can actually MOVE heavy objects while not launching light objects halfway across the screen.
* Some items don't update their positions correctly; I don't have any idea how to actually fix that. Ground objects seem to be unreliable.
}
import Logging


DevourmentManager property Manager auto
EffectShader Property SwallowShader Auto
Sound Property SwallowSound Auto


String PREFIX = "DevourmentVacuum"
Actor caster
float radius1 = 100.0
float radius2 = 200.0
float force = 20.0

ObjectReference[] items23
ObjectReference[] items26
ObjectReference[] items27
ObjectReference[] items30
ObjectReference[] items32
ObjectReference[] items41
ObjectReference[] items42
ObjectReference[] items46
ObjectReference[] items48
ObjectReference[] items52


Event OnEffectStart(Actor akTarget, Actor akCaster)
	caster = akCaster
	
	if !caster
		assertNotNone(PREFIX, "OnEffectStart", "caster", caster)
		return
	endif
	
	radius2 = 50.0 * Manager.GetPredSkill(caster)
	radius1 = radius2 / 2.0
	
	items23 = PO3_SKSEFunctions.FindAllReferencesOfFormType(caster, 23, radius2)
	items26 = PO3_SKSEFunctions.FindAllReferencesOfFormType(caster, 26, radius2)
	items27 = PO3_SKSEFunctions.FindAllReferencesOfFormType(caster, 27, radius2)
	items30 = PO3_SKSEFunctions.FindAllReferencesOfFormType(caster, 30, radius2)
	items32 = PO3_SKSEFunctions.FindAllReferencesOfFormType(caster, 32, radius2)
	items41 = PO3_SKSEFunctions.FindAllReferencesOfFormType(caster, 41, radius2)
	items42 = PO3_SKSEFunctions.FindAllReferencesOfFormType(caster, 42, radius2)
	items46 = PO3_SKSEFunctions.FindAllReferencesOfFormType(caster, 46, radius2)
	items48 = PO3_SKSEFunctions.FindAllReferencesOfFormType(caster, 48, radius2)
	items52 = PO3_SKSEFunctions.FindAllReferencesOfFormType(caster, 52, radius2)

	Manager.RegisterBlock(PREFIX, caster)
	RegisterForModEvent("DevourmentVacuumDigest", "OnDigest")
	RegisterForSingleUpdate(0.0)
EndEvent


Event OnUpdate()
	Log0(PREFIX, "OnUpdate")

	Suction(items23)
	Suction(items26)
	Suction(items27)
	Suction(items30)
	Suction(items32)
	Suction(items41)
	Suction(items42)
	Suction(items46)
	Suction(items48)
	Suction(items52)
	
	RegisterForSingleUpdate(0.1)
EndEvent


Event OnEffectFinish(Actor akTarget, Actor akCaster)
	Log2(PREFIX, "OnEffectFinish", Namer(akTarget), Namer(akCaster))
	
	StopSuction(items23)
	StopSuction(items26)
	StopSuction(items27)
	StopSuction(items30)
	StopSuction(items32)
	StopSuction(items41)
	StopSuction(items42)
	StopSuction(items46)
	StopSuction(items48)
	StopSuction(items52)

	Manager.UnregisterBlock(PREFIX, caster)
EndEvent


Function Suction(ObjectReference[] items)
	float casterX = caster.getPositionX()
	float casterY = caster.getPositionY()

	int itemIndex = items.length
	while itemIndex
		itemIndex -= 1
		ObjectReference item = items[itemIndex]
		if item
			float distance = item.GetDistance(caster)
			
			if distance > radius2 || !item.Is3DLoaded()
				items[itemIndex] = none
				
			elseif distance < 100.0
				int handle = ModEvent.create("DevourmentVacuumDigest")
				ModEvent.PushForm(handle, item)
				ModEvent.Send(handle)
				items[itemIndex] = none
			
			else
				float dx = casterX - item.GetPositionX()
				float dy = casterY - item.GetPositionY()
				float dz = (Math.abs(dx) + Math.abs(dy)) / 2.0
				item.ApplyHavokImpulse(dx, dy, dz, force)
			endIf
		endIf
	endWhile
endFunction


Function StopSuction(ObjectReference[] items)
	float casterX = caster.getPositionX()
	float casterY = caster.getPositionY()
	
	int itemIndex = items.length
	while itemIndex
		itemIndex -= 1
		ObjectReference item = items[itemIndex]
		
		float dx = item.GetPositionX() - casterX
		float dy = item.GetPositionY() - casterY
		item.ApplyHavokImpulse(dx, dy, (dx+dy)/2.0, force)
	endWhile
endFunction


Event OnDigest(Form f)
	ObjectReference item = f as ObjectReference
	SwallowSound.play(caster)
	item.Disable(true)
	Manager.DigestItem(caster, item, 1, none, 1)
	item.enable()
EndEvent
