Scriptname RaceMenuMimic extends ActiveMagicEffect
{
Taken from the RaceMenuMimic plugin from RaceMenu.
https://www.nexusmods.com/skyrim/mods/29624/
}
import Logging


Event OnEffectStart(Actor akTarget, Actor akCaster)
	mimic(akCaster, akTarget)
EndEvent 


Function mimic(Actor dest, Actor source) global
	Quest rcQuest = Quest.getQuest("RaceMenu")
	if rcQuest == None
		return
	endIf
	
	RaceMenu rcMenu = rcQuest as RaceMenu
	ActorBase destBase = dest.GetLeveledActorBase()
	ActorBase sourceBase = source.GetLeveledActorBase()
	
	if destBase.getSex() != sourceBase.getSex()
		if dest == Game.GetPlayer()
			ConsoleUtil.ExecuteCommand("player.sexchange")
		else
			ConsoleUtil.ExecuteCommand(destBase.GetFormID() + ".sexchange")
		endIf
	endif

	if dest.getRace() != source.getRace()
		dest.setRace(source.getRace())
	endIf

	If rcMenu && destBase && sourceBase
		int totalPresets = rcMenu.MAX_PRESETS
		int i = 0
		While i < totalPresets
			int preset = sourceBase.GetFacePreset(i)
			destBase.SetFacePreset(preset, i)
			i += 1
		EndWhile

		int totalMorphs = rcMenu.MAX_MORPHS
		i = 0
		While i < totalMorphs
			float morph = sourceBase.GetFaceMorph(i)
			destBase.SetFaceMorph(morph, i)
			i += 1
		EndWhile

		HeadPart eyes = None
		HeadPart hair = None
		HeadPart facialHair = None
		HeadPart scar = None
		HeadPart brows = None

		int totalHeadParts = sourceBase.GetNumHeadParts()
		i = 0
		While i < totalHeadParts
			HeadPart current = sourceBase.GetNthHeadPart(i)
			dest.ChangeHeadPart(current)
			i += 1
		EndWhile

		ColorForm hairColor = sourceBase.GetHairColor()
		destBase.SetHairColor(hairColor)
		rcMenu.SaveHair()

		TextureSet faceTXST = sourceBase.getFaceTextureSet()
		destBase.SetFaceTextureSet(faceTXST)
		
		destBase.SetVoiceType(sourceBase.GetVoiceType())
		destBase.SetSkin(sourceBase.GetSkin())
		destBase.SetSkinFar(sourceBase.GetSkinFar())
		
		float destWeight = destBase.getWeight()
		float sourceWeight = sourceBase.getWeight()
		dest.setWeight(sourceWeight)
		dest.updateWeight(sourceWeight / 100.0 - destWeight / 100.0)
		
		if SKSE.GetPluginVersion("PapyrusExtender") >= 0
			PO3_SKSEFunctions.SetHairColor(dest, PO3_SKSEFunctions.GetHairColor(source))
			PO3_SKSEFunctions.SetSkinColor(dest, PO3_SKSEFunctions.GetSkinColor(source))
		
			If eyes
				TextureSet txst = PO3_SKSEFunctions.GetHeadPartTextureSet(source, 2)
				if txst
					PO3_SKSEFunctions.SetHeadPartTextureSet(dest, txst, 2)
				endIf
			Endif

			If hair
				TextureSet txst = PO3_SKSEFunctions.GetHeadPartTextureSet(source, 3)
				if txst
					PO3_SKSEFunctions.SetHeadPartTextureSet(dest, txst, 3)
				endIf
			Endif

			If facialHair
				TextureSet txst = PO3_SKSEFunctions.GetHeadPartTextureSet(source, 4)
				if txst
					PO3_SKSEFunctions.SetHeadPartTextureSet(dest, txst, 4)
				endIf
			Endif

			If scar
				TextureSet txst = PO3_SKSEFunctions.GetHeadPartTextureSet(source, 5)
				if txst
					PO3_SKSEFunctions.SetHeadPartTextureSet(dest, txst, 5)
				endIf
			Endif

			If brows
				TextureSet txst = PO3_SKSEFunctions.GetHeadPartTextureSet(source, 6)
				if txst
					PO3_SKSEFunctions.SetHeadPartTextureSet(dest, txst, 6)
				endIf
			Endif
		endIf
		
		PO3_SKSEFunctions.ResetActor3D(dest, "PO3_TINT")
		dest.RegenerateHead()
		dest.QueueNiNodeUpdate()
	Endif
	
EndFunction
