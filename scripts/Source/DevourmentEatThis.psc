Scriptname DevourmentEatThis extends ActiveMagicEffect
import Logging


Actor property PlayerRef auto
DevourmentManager property Manager auto
Container property BolusContainer auto


String PREFIX = "DevourmentEatThis"
DevourmentBolus bolus = none
Actor pred = none


Event OnEffectStart(Actor akTarget, Actor akCaster)
	if !assertNotNone(PREFIX, "OnEffectStart", "akTarget", akTarget)
		Dispel()
		return 
	endIf
	
	pred = akTarget
	bolus = Manager.FakePlayer.placeAtMe(BolusContainer) as DevourmentBolus
	bolus.Initialize(Namer(PlayerRef, true) + "'s stash", PlayerRef, pred)
	RegisterForMenu("GiftMenu")
	pred.ShowGiftMenu(true, none, true, false)
EndEvent


Event OnEffectFinish(Actor akTarget, Actor akCaster)
EndEvent


Event OnMenuClose(string menuName)
	if bolus.GetNumItems() > 0
		Manager.RegisterDigestion(pred, bolus, false, 0)
		Manager.PlayVoreAnimation_Item(pred, bolus, 0, true)
	else
		bolus.delete()
	endIf
	
	UnregisterForAllMenus()
	Dispel()
EndEvent


Function OnItemAdded(Form baseItem, int itemCount, ObjectReference itemReference, ObjectReference source)
	if source == PlayerRef
		if itemReference
			pred.RemoveItem(itemReference, itemCount, false, bolus)
			Manager.PlayVoreAnimation_Item(pred, itemReference, 0, true)
		else
			pred.RemoveItem(baseItem, itemCount, false, bolus)
		endIf
	endIf
EndFunction

