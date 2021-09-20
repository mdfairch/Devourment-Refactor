Scriptname EWM_DVT extends EWM_HandleModBase
import Logging


Actor property playerRef auto
DevourmentManager property Manager auto
DevourmentMCM property MCM auto
Spell[] property Spells auto
String PREFIX = "EWM_DVT"


Spell Function GetFunctionSpell(int index)
{
This can be used if the function is supposed to replace a spell
In this case, the spell will be hidden from the magic menu if user check "Hide Spells" in EWM's MCM.
The HasSpells property have to be set to true in this script's properties for this feature to be taken into account.
}
	if !assertIndex(PREFIX, "GetFunctionSpell", "Spells", index, Spells.length)
		return none
	endIf

	return Spells[index]
EndFunction


Bool Function GetFunctionCondition(Int index)
{
This can be used if some functions have conditions to be available.
In the following example, _DemoEWM_Fct2 is only available if the player is a male, while _DemoEWM_Fct1 have no conditions.
}
	return true
EndFunction


Event OnHandlerInit()
EndEvent


Function castOnTarget(Spell spl)
	ObjectReference target = Game.GetCurrentCrosshairRef()
	if target && target as Actor && Game.IsFightingControlsEnabled()
		spl.cast(playerRef, target)
	endIf
EndFunction


Function castOnSelf(Spell spl)
	if Game.IsFightingControlsEnabled()
		spl.cast(playerRef, playerRef)
	endIf
EndFunction


Event On_EWMDVTVoreSwallow()
	castOnTarget(Spells[0])
EndEvent


Event On_EWMDVTEndoSwallow()
	castOnTarget(Spells[1])
EndEvent


Event On_EWMDVTComboSwallow()
	castOnTarget(Spells[2])
EndEvent


Event On_EWMDVTVomit()
	;castOnTarget(Spells[3])
	Manager.vomit(playerRef)
EndEvent


Event On_EWMDVTPoop()
	;castOnTarget(Spells[4])
	Manager.poop(playerRef)
EndEvent


Event On_EWMDVTQuick()
	;castOnTarget(Spells[5])
	MCM.DisplayQuickSettings()
EndEvent


Event On_EWMDVTBurp()
	Manager.PlayBurp_async(PlayerRef, true)
EndEvent


Event On_EWMDVTFart()
	Manager.PlayBurp_async(PlayerRef, false)
EndEvent
