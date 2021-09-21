Scriptname DevourmentMCM extends MCM_ConfigBase Conditional
{
AUTHOR: Gaz and MarkDF
PURPOSE: Manages the mod configuration menu for Devourment. 
Stores all Vore Perks as properties, so is useful for other scripts needing access.
CREDIT: Additional guidance acquired by pestering Parapets on his Discord.
}

;/
************************* WARNING NOTICE ************************

This script is a hybrid. It uses both legacy SKI MCM functions
as well as new MCM Helper functions. If you want to compile it
you need to download MCM Helpers' SDK and then overwrite 
SKI_ConfigBase with the old SkyUI version.

******************************************************************
/;

import DevourmentUtil
import Logging

; Plugin-defined Properties.
Actor Property PlayerRef Auto
DevourmentPlayerAlias Property PlayerAlias Auto
DevourmentManager Property Manager Auto
DevourmentMorphs Property Morphs Auto
DevourmentSkullHandler Property SkullHandler Auto
DevourmentWeightManager Property WeightManager Auto
GlobalVariable Property VoreDialog Auto
float[] property LocusChances auto
float[] property LocusCumulative auto
String[] property StatRaces auto
Perk[] Property DigestItems_arr Auto
Perk[] Property IronStomach_arr Auto
Perk[] Property Resilience_arr auto
Perk[] Property Slippery_arr auto
Perk[] Property StrongAcid_arr auto
Perk[] Property Struggle_arr auto
Perk[] Property Voracious_arr auto
Perk Property Comfy Auto
Perk Property ConstrictingGrip Auto
Perk Property ConsumeEssence Auto
Perk Property CounterVore auto
Perk Property Cordyceps Auto
Perk Property Delicious Auto
Perk Property DigestionDaedric Auto
Perk Property DigestionDwemer Auto
Perk Property DigestionUndead Auto
Perk Property NourishmentBody Auto
Perk Property NourishmentMana Auto
Perk Property PartingGift Auto
Perk Property Phylactery auto
Perk Property RaiseDead Auto
Perk Property SilentDefecate Auto
Perk Property SilentSwallow Auto
Perk Property SoulFood Auto
Perk Property StickTheLanding Auto
Perk Property StrongBack Auto
Perk Property VoreMagic1 auto
Perk Property VoreMagic2 auto
Spell Property QuickSettings auto
Spell Property Power_Regurgitate auto
Spell Property Power_Defecate auto
Spell Property Power_DigestItems auto
Spell Property Power_EatThis auto


; Script-defined Properties.
int property VERSION = 118 auto Hidden
bool property EnableHungryBones = true auto Hidden
bool property EnableCordyceps = true auto Hidden 
bool property LooseItemVore = true auto Hidden
bool property AutoRebirth = true auto Hidden
bool property AltPerkMenus = false auto Hidden
bool property SLAccidents = false auto Hidden
bool property DontAddPowers = false auto conditional Hidden
bool property UnrestrictedItemVore = false auto Hidden
bool property GentleGas = false auto Hidden
bool property CounterVoreEnabled = true auto Hidden
bool property DigestToInventory = false auto Hidden
String property ExportFilename = "data\\skse\\plugins\\devourment\\db_export.json" autoreadonly Hidden
String property SettingsFileName = "data\\skse\\plugins\\devourment\\settings.json" autoreadonly Hidden
String property PredPerkFile = "data\\skse\\plugins\\devourment\\PredPerkData.json" autoreadonly Hidden
String property PreyPerkFile = "data\\skse\\plugins\\devourment\\PreyPerkData.json" autoreadonly Hidden

; Properties required for MCM pages.
Actor Property target Auto Hidden
String Property targetName Auto Hidden
Bool Property isAutoPred Auto Hidden

; Variables.
string[] equipList

bool resetBellies = false
bool vomitActivated = false
bool flushActivated = false

int predSkillInfo
int preySkillInfo

String PREFIX = "DevourmentManager"
int Property difficulty = 2 Auto

int bellyPreset = 1

int optionsMap

int function GetVersion()
	return 118
endFunction

event OnConfigInit()
	Pages = new string[10]
	Pages[0] = "$DVT_Page_StatsSkills"
	Pages[1] = "$DVT_Page_General"
	Pages[2] = "$DVT_Page_VisualSoundMisc"
	Pages[3] = "$DVT_Page_LocusMorphs"
	Pages[4] = "$DVT_Page_WeightSettings"
	Pages[5] = "$DVT_Page_WeightManagerFemale"
	Pages[6] = "$DVT_Page_WeightManagerMale"
	;Pages[?] = "$DVT_Page_WeightManagerCreature"	;TODO. When you enable this, make sure the page is in MCM Config.JSON also.
	Pages[7] = "$DVT_Page_Debugging"
	Pages[8] = "$DVT_Page_Dependancies"

	equipList = new string[3]
	equipList[0] = "$DVT_EquipNone"
	equipList[1] = "$DVT_EquipMacross"
	equipList[2] = "$DVT_EquipSkeptic"
endEvent

Event OnVersionUpdate(int newVersion)
	Upgrade(CurrentVersion, newVersion)
EndEvent

Function Upgrade(int oldVersion, int newVersion)
{ Version 118 is a clean break, so upgrades all start from there. }
	if oldVersion < newVersion
		VERSION = newVersion
		PlayerAlias.Upgrade(oldVersion, newVersion)
		Manager.Upgrade(oldVersion, newVersion)
		DevourmentSkullHandler.instance().Upgrade(oldVersion, newVersion)
		DevourmentReformationQuest.instance().Upgrade(oldVersion, newVersion)
		DevourmentNewDova.instance().Upgrade(oldVersion, newVersion)
		RecalculateLocusCumulative()
	endif
endFunction

Function RecalculateLocusCumulative()
	LocusCumulative = Utility.CreateFloatArray(LocusChances.length)
	
	if Manager.VEGAN_MODE
		LocusChances[5] = 0.0
	endIf

	float sum = 0
	int locus = LocusChances.length

	while locus
		locus -= 1
		sum += LocusChances[locus]
		LocusCumulative[locus] = sum
	endWhile
EndFunction

Function AddPredContents(UIListMenu menu, int parentEntry, Actor pred)
	Form[] stomach = Manager.getStomachArray(pred) as Form[]
	if Manager.EmptyStomach(stomach)
		menu.AddEntryItem("(Nothing)", parentEntry)
	else
		int stomachIndex = 0
		while stomachIndex < stomach.length
			ObjectReference stomachItem = stomach[stomachIndex] as ObjectReference
			stomachIndex += 1

			int ENTRY_CONTENTS = menu.AddEntryItem(Namer(stomachItem, true), parentEntry, entryHasChildren = true)

			if stomachItem as Actor
				AddPreyDetails(menu, ENTRY_CONTENTS, stomachItem as Actor)
			else
				AddBolusContents(menu, ENTRY_CONTENTS, stomachItem)
			endIf
		endWhile
	endIf
EndFunction

String Function GetLocusName(int locus)
	if locus == 0
		return "Swallow"
	elseif locus == 1
		return "Anal"
	elseif locus == 2
		return "Unbirth"
	elseif locus == 3
		return "Breast (left)"
	elseif locus == 4
		return "Breast (right)"
	elseif locus == 5
		if Manager.VEGAN_MODE
			return "DISABLED"
		else
			return "Cock"
		endIf
	elseif locus < 0
		return "Random"
	else
		return "Unknown " + locus
	endIf
EndFunction

Function AddBolusContents(UIListMenu menu, int parentEntry, ObjectReference bolus)
	Form[] bolusContents = bolus.GetContainerForms()
	if bolusContents.length > 0
		String description = Namer(bolusContents[0], !Manager.DEBUGGING)
	
		int bolusIndex = 0
		while bolusIndex < bolusContents.length
			Form item = bolusContents[bolusIndex]
			int count = bolus.GetItemCount(item)
			menu.AddEntryItem(NameWithCount(bolusContents[bolusIndex], count), parentEntry)
			bolusIndex += 1
		endWhile
	else
		menu.AddEntryItem("(EMPTY)", parentEntry)
	endIf
EndFunction

Function AddPreyDetails(UIListMenu menu, int parentEntry, Actor prey)
	menu.AddEntryItem("Name: " + Namer(prey, !Manager.DEBUGGING), parentEntry)
	menu.AddEntryItem("Level: " + prey.GetLevel(), parentEntry)
	menu.AddEntryItem("Pred skill: " + Manager.GetPredSkill(prey) as int, parentEntry)
	menu.AddEntryItem("Prey skill: " + Manager.GetPreySkill(prey) as int, parentEntry)
	
	int preyData = Manager.GetPreyData(prey)
	menu.AddEntryItem("Locus: " + GetLocusName(Manager.GetLocus(preyData)), parentEntry)

	if Manager.IsReforming(preyData)
		menu.AddEntryItem("Reforming: " + Manager.GetDigestionPercent(preyData) as int + "%", parentEntry)
	elseif Manager.IsDigesting(preyData)
		menu.AddEntryItem("Digesting: " + Manager.GetDigestionProgress(preyData) as int + "%", parentEntry)
	elseif Manager.IsDigested(preyData)
		menu.AddEntryItem("DIGESTED", parentEntry)
	elseif Manager.IsEndo(preyData)
		menu.AddEntryItem("Health: " + prey.GetActorValue("Health") as int + " / " + prey.GetBaseActorValue("Health") as int + " (" + prey.GetActorValuePercentage("Health") + "%)", parentEntry)
		menu.AddEntryItem("Non-lethal", parentEntry)
	elseif Manager.IsVore(preyData)
		menu.AddEntryItem("Health: " + prey.GetActorValue("Health") as int + " / " + prey.GetBaseActorValue("Health") as int + " (" + prey.GetActorValuePercentage("Health") + "%)", parentEntry)
		menu.AddEntryItem("Acid DPS: " + Manager.GetDPS(preyData) , parentEntry)
	endIf
EndFunction

String Function NameWithCount(Form item, int count)
	if count == 1
		return Namer(item, !Manager.DEBUGGING)
	else
		return Namer(item, !Manager.DEBUGGING) + " (" + count + ")"
	endIf
endFunction

String Function ToggleString(String name, bool toggle)
	if toggle
		return name + ": [X]"
	else
		return name + ": [ ]"
	endIf
EndFunction

bool Function ShowPerkSubMenu(bool pred, actor subject = None)

	If !Subject
		Subject = GetTarget()
	EndIf

	if !subject.GetActorBase().IsUnique() 
		Debug.MessageBox(Namer(subject, true) + " is not a unique actor and cannot gain perks.")
		return false
	endIf

	int perkMap
	float skill
	
	if pred
		perkMap = JValue.readFromFile(PredPerkFile)
		skill = Manager.GetPredSkill(subject)
	else
		perkMap = JValue.readFromFile(PreyPerkFile)
		skill = Manager.GetPreySkill(subject)
	endIf
	
	if !AssertExists(PREFIX, "ShowPerkSubMenu", "perkMap", perkMap)
		return false
	endIf
	
	JValue.retain(perkMap, PREFIX)
	UIListMenu menu = UIExtensions.GetMenu("UIListMenu") as UIListMenu

	bool exit = false
	while !exit
		Int perkPoints = Manager.GetPerkPoints(subject)
		Perk[] perkList = new Perk[50]
		int perkIndex = 0

		menu.ResetMenu()
		String[] names = JArray.asStringArray(JArray.Sort(JMap.allKeys(perkMap)))
		int[] entries = Utility.createIntArray(names.length)

		int index = 0
		
		while index < names.length
			String name = names[index]
			int perkEntry = JMap.GetObj(perkMap, name)
			if AssertExists(PREFIX, "ShowPerkSubMenu", name, perkEntry)
				
				float requiredSkill = JMap.GetFlt(perkEntry, "Skill")
				Perk requiredPerk = JMap.GetForm(perkEntry, "Req") as Perk
				Perk thePerk = JMap.GetForm(perkEntry, "Perk") as Perk
				String description = JMap.GetStr(perkEntry, "Description")
				
				if skill >= requiredSkill && thePerk != none && !subject.HasPerk(thePerk) && (requiredPerk == none || subject.HasPerk(requiredPerk))
					perkList[perkIndex] = thePerk
					int ENTRY_PERK = menu.AddEntryItem(name, entryHasChildren = true)
					if description != ""
						menu.AddEntryItem(description, ENTRY_PERK)
					endIf
					if requiredSkill > 0.0
						menu.AddEntryItem("Require Skill: " + requiredSkill, ENTRY_PERK)
					endIf
					if perkPoints > 0
						entries[perkIndex] = menu.AddEntryItem("Add Perk", ENTRY_PERK)
					elseif Manager.DEBUGGING
						entries[perkIndex] = menu.AddEntryItem("Add Perk (DEBUGGING)", ENTRY_PERK)
					endIf
					perkIndex += 1
				endIf
			endIf
			
			index += 1
		endWhile
		
		int ENTRY_EXIT = menu.AddEntryItem("Exit")
		menu.OpenMenu()
		int result = menu.GetResultInt()
		int entryIndex = entries.find(result)

		if result < 0 || result == ENTRY_EXIT 
			exit = true
		elseif entryIndex >= 0 && perkList[entryIndex]
			if subject == PlayerRef
				subject.addPerk(perkList[entryIndex])
			else
				PO3_SKSEFunctions.AddBasePerk(subject, perkList[entryIndex])
			endIf

			if perkPoints > 0
				perkPoints = Manager.DecrementPerkPoints(subject)
			endIf

			if perkPoints <= 0 && !Manager.DEBUGGING
				exit = true
			endIf
		endIf
	endWhile
	
	JValue.release(perkMap)
	return true
EndFunction

Function ToggleVorish(bool Toggle)
	Manager.ToggleVorish(target, Toggle)	;Ugly. TODO, make into bool function confirming success.
	isAutoPred = Manager.IsVorish(target)	
EndFunction

Function Vomit()
	if !vomitActivated
		Manager.vomit(target)
		vomitActivated = true
		ForcePageReset()
	endif
EndFunction

Function SettingsContext(bool save)
	if save
		If Manager.saveSettings(SettingsFileName)
			;Parent.ShowMessage("Saved settings to '" + SettingsFileName + "'.", false)
			Debug.MessageBox("Saved settings to '" + SettingsFileName + "'.")
		Else
			;Parent.ShowMessage("Couldn't write to '" + SettingsFileName + "'.", false)
			Debug.MessageBox("Couldn't write to '" + SettingsFileName + "'.")
		EndIf
	else
		If Manager.loadSettings(SettingsFileName)
			;Parent.ShowMessage("Loaded settings from '" + SettingsFileName + "'.", false)
			Debug.MessageBox("Loaded settings from '" + SettingsFileName + "'.")
		Else
			;Parent.ShowMessage("Couldn't read from '" + SettingsFileName + "'.", false)
			Debug.MessageBox("Couldn't read from '" + SettingsFileName + "'.")
		EndIf
	endif
	ForcePageReset()
EndFunction

Function ExportDatabase()
	Manager.ExportDatabase(ExportFilename)
	;Parent.ShowMessage("JContainers database exported to '" + ExportFilename + "'.", false)
	Debug.MessageBox("JContainers database exported to '" + ExportFilename + "'.")
	ForcePageReset()
EndFunction

Function MaxSkills()
	Manager.GivePredXP(target, 10000.0)
	Manager.GivePreyXP(target, 10000.0)
	ForcePageReset()
EndFunction

Function MaxPerks()
	Manager.IncreaseVoreLevel(target, 100)
	ForcePageReset()
EndFunction

Function FlushVomitQueue()
	if !flushActivated
		Manager.VOMIT_CLEAR()
		flushActivated = true
		ForcePageReset()
	endIf
EndFunction

Function resetPrey()
	Manager.resetPrey(target)
	ForcePageReset()
EndFunction

Function ResetVisuals()
	Manager.UnassignAllPreyMeters()
	Manager.RestoreAllPreyMeters()
	Manager.ResetBellies()
	;Parent.ShowMessage("Ran the visuals reset procedure.", false)
	Debug.MessageBox("Ran the visuals reset procedure.")
	ForcePageReset()
EndFunction

Function ResetDevourment()
	Manager.ResetDevourment()
	;Parent.ShowMessage("Ran the reset Devourment procedure.", false)
	Debug.MessageBox("Ran the reset Devourment procedure.")
	ForcePageReset()
EndFunction

Function setDifficultyPreset(int preset)
	difficulty = preset
	
	if difficulty == 0
		Manager.acidDamageModifier = 0.1
		Manager.PredExperienceRate = 0.2
		Manager.PreyExperienceRate = 0.1
		Manager.struggleDamage = 0.1
		Manager.struggleDifficulty = 10.0
		Manager.NPCBonus = 0.1
		Manager.endoAnyone = true
		Manager.killPlayer = false
		Manager.VoreTimeout = false
		Manager.swallowHeal = true
		Manager.whoStruggles = 0
		Manager.DigestionTime = 60.0
	elseif difficulty == 1
		Manager.acidDamageModifier = 0.5
		Manager.PredExperienceRate = 0.5
		Manager.PreyExperienceRate = 0.1
		Manager.struggleDamage = 0.5
		Manager.struggleDifficulty = 10.0
		Manager.NPCBonus = 0.5
		Manager.endoAnyone = true
		Manager.killPlayer = false
		Manager.VoreTimeout = false
		Manager.swallowHeal = true
		Manager.whoStruggles = 1
		Manager.DigestionTime = 120.0
	elseif difficulty == 2
		Manager.acidDamageModifier = 1.0
		Manager.PredExperienceRate = 1.0
		Manager.PreyExperienceRate = 2.0
		Manager.struggleDamage = 1.0
		Manager.struggleDifficulty = 10.0
		Manager.NPCBonus = 1.0
		Manager.endoAnyone = false
		Manager.killPlayer = true
		Manager.VoreTimeout = true
		Manager.swallowHeal = true
		Manager.whoStruggles = 2
		Manager.DigestionTime = 180.0
	elseif difficulty == 3
		Manager.acidDamageModifier = 2.0
		Manager.PredExperienceRate = 2.0
		Manager.PreyExperienceRate = 4.0
		Manager.struggleDamage = 2.0
		Manager.struggleDifficulty = 10.0
		Manager.NPCBonus = 2.0
		Manager.endoAnyone = false
		Manager.killPlayer = true
		Manager.VoreTimeout = true
		Manager.swallowHeal = false
		Manager.whoStruggles = 2
		Manager.DigestionTime = 300.0
	elseif difficulty == 4
		Manager.acidDamageModifier = 5.0
		Manager.PredExperienceRate = 5.0
		Manager.PreyExperienceRate = 10.0
		Manager.struggleDamage = 5.0
		Manager.struggleDifficulty = 10.0
		Manager.NPCBonus = 5.0
		Manager.endoAnyone = false
		Manager.killPlayer = true
		Manager.VoreTimeout = true
		Manager.swallowHeal = false
		Manager.whoStruggles = 2
		Manager.DigestionTime = 600.0
	elseif difficulty == 6
		Manager.acidDamageModifier = 20.0
		Manager.PredExperienceRate = 0.0
		Manager.PreyExperienceRate = 0.0
		Manager.struggleDamage = 2.0
		Manager.struggleDifficulty = 10.0
		Manager.NPCBonus = 5.0
		Manager.endoAnyone = false
		Manager.killPlayer = true
		Manager.killNPCs = true
		Manager.killEssential = true
		Manager.VoreTimeout = true
		Manager.swallowHeal = true
		Manager.whoStruggles = 2
		Manager.endoAnyone = true
		Manager.multiPrey = Manager.MULTI_UNLIMITED
		Manager.DigestionTime = 10.0
	endIf
	Manager.AdjustPreyData()

EndFunction

int function checkDifficultyPreset() 
	if Manager.acidDamageModifier == 0.1 \
		&& Manager.struggleDamage == 0.1 \
		&& Manager.struggleDifficulty == 10.0 \
		&& Manager.NPCBonus == 0.1 \
		&& Manager.endoAnyone == true \
		&& Manager.killPlayer == false \
		&& Manager.VoreTimeout == false \
		&& Manager.swallowHeal == true \
		&& Manager.whoStruggles == 0
		return 0
	elseif Manager.acidDamageModifier == 0.5 \
		&& Manager.struggleDamage == 0.5 \
		&& Manager.struggleDifficulty == 10.0 \
		&& Manager.NPCBonus == 0.5 \
		&& Manager.endoAnyone == true \
		&& Manager.killPlayer == false \
		&& Manager.VoreTimeout == false \
		&& Manager.swallowHeal == true \
		&& Manager.whoStruggles == 1
		return 1
	elseif Manager.acidDamageModifier == 1.0 \
		&& Manager.struggleDamage == 1.0 \
		&& Manager.struggleDifficulty == 10.0 \
		&& Manager.NPCBonus == 1.0 \
		&& Manager.endoAnyone == false \
		&& Manager.killPlayer == true \
		&& Manager.VoreTimeout == true \
		&& Manager.swallowHeal == true \
		&& Manager.whoStruggles == 2
		return 2
	elseif Manager.acidDamageModifier == 2.0 \
		&& Manager.struggleDamage == 2.0 \
		&& Manager.struggleDifficulty == 10.0 \
		&& Manager.NPCBonus == 2.0 \
		&& Manager.endoAnyone == false \
		&& Manager.killPlayer == true \
		&& Manager.VoreTimeout == true \
		&& Manager.swallowHeal == false \
		&& Manager.whoStruggles == 2
		return 3
	elseif Manager.acidDamageModifier == 5.0 \
		&& Manager.struggleDamage == 5.0 \
		&& Manager.struggleDifficulty == 10.0 \
		&& Manager.NPCBonus == 5.0 \
		&& Manager.endoAnyone == false \
		&& Manager.killPlayer == true \
		&& Manager.VoreTimeout == true \
		&& Manager.swallowHeal == false \
		&& Manager.whoStruggles == 2
		return 4
	else
		return 5
	endIf
endFunction

event onConfigOpen()
	vomitActivated = false
	flushActivated = false
	resetBellies = false
endEvent


Int PerkMenuQueue = 0


event OnConfigClose()
	RecalculateLocusCumulative()

	if resetBellies
		resetBellies = false
		Manager.ResetBellies()
	endIf

	If PerkMenuQueue == 1
		if AltPerkMenus
			ShowPerkSubMenu(true)
		else
			Manager.Devourment_ShowPredPerks.SetValue(1.0)
		endIf
	ElseIf PerkMenuQueue == 2
		if AltPerkMenus
			ShowPerkSubMenu(false)
		else
			Manager.Devourment_ShowPreyPerks.SetValue(1.0)
		endIf
	EndIf
	PerkMenuQueue = 0
endEvent


string Function GetCustomControl(int keyCode)
	if keyCode == PlayerAlias.DIALOGUE_KEY
		return "Dialog"
	elseif keyCode == PlayerAlias.COMPEL_KEY
		return "Compel"
	elseif keyCode == PlayerAlias.QUICK_KEY
		return "Settings"
	elseif keyCode == PlayerAlias.VORE_KEY
		return "Vore"
	elseif keyCode == PlayerAlias.ENDO_KEY
		return "Endo"
	elseif keyCode == PlayerAlias.COMB_KEY
		return "Swallow"
	elseif keyCode == PlayerAlias.FORGET_KEY
		return "Forget"
	else
		return ""
	endIf
endFunction


Actor Function GetTarget()
	target = Game.GetCurrentCrosshairRef() as Actor
	if target
		return target
	endIf

	return PlayerRef
EndFunction


event OnPageReset(string page)
	parent.OnPageReset(page)
	optionsMap = JValue.ReleaseAndRetain(optionsMap, JIntMap.Object(), PREFIX)
	target = GetTarget()	;We use this so often we should just refresh it whenever.
	targetName = Namer(target, true)

	if Pages.find(page) < 0
		LoadCustomContent("Devourment\Title.dds", 0, 126)
	else
		UnloadCustomContent()
	endIf

	If page == Pages[0]
		int perkPoints = Manager.GetPerkPoints(target)
		int predSkill = Manager.GetPredSkill(target) as int
		int preySkill = Manager.GetPreySkill(target) as int
		int numVictims = Manager.getNumVictims(target)
		int swallowSkill = Manager.getSwallowSkill(target) as int
		int acidDamage = Manager.getAcidDamage(target, Manager.fakePlayer) as int
		int MaxTime = Manager.getHoldingTime(target) as int
		int StruggleDamage = Manager.getStruggleDamage(target, Manager.fakePlayer) as int
		int acidresistance = (Manager.getAcidResistance(target) * 100) as int
		int swallowResistance = Manager.getSwallowResistance(target) as int
		int dtime = Manager.GetDigestionTime(target, none) as int
		int endoes = Manager.GetTimesSwallowed(target, true)
		int vores = Manager.GetTimesSwallowed(target, false)

		setCursorFillMode(TOP_TO_BOTTOM)
		addHeaderOption("Devourment v" + (Version / 100) + "." + (Version % 100))
		addTextOption("Viewing: ", targetName)
		predSkillInfo = addTextOption("Devourment pred skill: ", predSkill)
		preySkillInfo = addTextOption("Devourment prey skill: ", preySkill)
		addTextOption("Devourment level: ", Manager.GetVoreLevel(target))
		addTextOption("Devourment perk points: ", perkPoints)
		addToggleOptionSt("PredPerksState", "$DVT_ShowPredPerks", false)
		addToggleOptionSt("PreyPerksState", "$DVT_ShowPreyPerks", false)
		
		if Manager.MicroMode
			addTextOptionSt("CapacityInfoState",  "Devourment Capacity:   ", Manager.GetCapacity(target))
		endIf
		
		if WeightManager.PlayerEnabled
			addTextOption("Devourment Weight: ", WeightManager.GetWeightApprox(target))
		endIf

		addEmptyOption()
		addTextOption("Swallow skill: ", swallowSkill)
		addTextOption("Swallow resistance: ", swallowResistance)
		addTextOption("Acid damage: ", acidDamage + " hp/sec")
		addTextOption("Struggling damage: ", StruggleDamage + " hp")
		addTextOption("Maximum holding time: ", maxTime + " sec")
		addTextOption("Digestion duration: ", dtime + " sec")
		addTextOption("Acid resistance: ", acidresistance + "%")
		setCursorPosition(1)

		addHeaderOption("Total times swallowed: " + (endoes + vores))
		addTextOption("Endo", endoes)
		addTextOption("Vore", vores)
		
		addHeaderOption("Total victims digested: " + numVictims)
		addTextOption("Women", Manager.GetVictimType(target, "women"))
		addTextOption("Men", Manager.GetVictimType(target, "men"))
		addTextOption("Corpses", Manager.GetVictimType(target, "corpses"))

		DevourmentNewDova newDova = DevourmentNewDova.instance()
		if NewDova.prevDov > 0
			addTextOption("Previous Dovahkiins: ", NewDova.prevDov)
			addTextOption("Last Dovahkiin", NewDova.previousName)
		endif

		addEmptyOption()
		addTextOption("RACE ", " DIGESTED")
		
		int index = 0 
		while index < StatRaces.Length
			String raceName = StatRaces[index]
			addTextOption(raceName + " digested: ", Manager.GetVictimType(target, raceName))
			index += 1
		endWhile

		addTextOption("Others digested: ", Manager.GetVictimType(target, "other"))

	ElseIf page == Pages[1]

		setCursorFillMode(TOP_TO_BOTTOM)
		setCursorPosition(1)
		addHeaderOption("$DVT_Header_Shortcuts")
		AddKeyMapOptionST("VoreKeyState", "$DVT_VoreKey", PlayerAlias.VORE_KEY)
		AddKeyMapOptionST("EndoKeyState", "$DVT_EndoKey", PlayerAlias.ENDO_KEY)
		AddKeyMapOptionST("CombKeyState", "$DVT_CombKey", PlayerAlias.COMB_KEY)
		AddKeyMapOptionST("DialogueKeyState", "$DVT_DialogueKey", PlayerAlias.DIALOGUE_KEY)
		AddKeyMapOptionST("QuickSettingsKeyState", "$DVT_DevourmentKey", PlayerAlias.QUICK_KEY)
		AddKeyMapOptionST("compelVoreKeyState", "$DVT_CompelVoreKey", PlayerAlias.COMPEL_KEY)
		AddKeyMapOptionST("ForgetKeyState", "$DVT_ForgetKey", PlayerAlias.FORGET_KEY)

		addHeaderOption("$DVT_Header_Skulls")
		addToggleOptionSt("SkullsSeparateState", "$DVT_SkullsSeparate", SkullHandler.SkullsSeparate)
		addToggleOptionSt("SkullsForEveryoneState", "$DVT_SkullsEveryone", SkullHandler.SkullsForEveryone)
		addToggleOptionSt("SkullsForUniqueState", "$DVT_SkullsUnique", SkullHandler.SkullsForUnique || SkullHandler.SkullsForEveryone)
		addToggleOptionSt("SkullsForEssentialState", "$DVT_SkullsEssential", SkullHandler.SkullsForEssential || SkullHandler.SkullsForEveryone)
		addToggleOptionSt("SkullsForUnleveledState", "$DVT_SkullsUnleveled", SkullHandler.SkullsForUnleveled || SkullHandler.SkullsForEveryone)
		addToggleOptionSt("SkullsForDragonsState", "$DVT_SkullsDragons", SkullHandler.SkullsForDragons)

	ElseIf page == Pages[3]

		setCursorPosition(0)
		addMenuOptionSt("equipBellyState", "$DVT_EquipableBelly", equipList[Morphs.EquippableBellyType])
		addToggleOptionSt("UseLocusMorphsState", "$DVT_LocusMorphs", Morphs.UseLocationalMorphs)
		addSliderOptionSt("MorphSpeedState", "$DVT_MorphSpeed", Morphs.MorphSpeed, "{2}x")
		addToggleOptionSt("EliminationLocusState", "$DVT_UseEliminationLocus", Morphs.UseEliminationLocus)
		addToggleOptionSt("struggleSlidersState", "$DVT_StruggleSliders", Morphs.useStruggleSliders)

		if Morphs.UseStruggleSliders
			addSliderOptionSt("BumpAmplitudeState", "$DVT_BumpAmplitude", Morphs.struggleAmplitude, "{2}x")
		else
			addSliderOptionSt("BumpAmplitudeState", "$DVT_BumpAmplitude", Morphs.struggleAmplitude, "{2}x", OPTION_FLAG_DISABLED)
		endIf
		
		if !Morphs.UseLocationalMorphs
			setCursorPosition(1)
			addInputOptionSt("Slider_Locus0State", "$DVT_LocusSlider", Morphs.Locus_Sliders[0])
			addSliderOptionSt("Scaling_Locus0State", "$DVT_LocusScale", Morphs.Locus_Scales[0], "{2}")
			addEmptyOption()
			addSliderOptionSt("Scaling_Locus0_MaxState", "$DVT_LocusMaximum", Morphs.Locus_Maxes[0], "{2}")
	
		else
			AddHeaderOption("Locus 0 - Stomach")
			addInputOptionSt("Slider_Locus0State", "$DVT_LocusSlider", Morphs.Locus_Sliders[0])
			addSliderOptionSt("Scaling_Locus0State", "$DVT_LocusScale", Morphs.Locus_Scales[0], "{2}")
			addSliderOptionSt("Scaling_Locus0_MaxState", "$DVT_LocusMaximum", Morphs.Locus_Maxes[0], "{2}")
			addSliderOptionSt("Chance_Locus0", "$DVT_LocusChance", LocusChances[0], "{2}")

			AddHeaderOption("Locus 1 - Buttocks")
			addInputOptionSt("Slider_Locus1State", "$DVT_LocusSlider", Morphs.Locus_Sliders[1])
			addSliderOptionSt("Scaling_Locus1State", "$DVT_LocusScale", Morphs.Locus_Scales[1], "{2}")
			addSliderOptionSt("Scaling_Locus1_MaxState", "$DVT_LocusMaximum", Morphs.Locus_Maxes[1], "{2}")
			addSliderOptionSt("Chance_Locus1", "$DVT_LocusChance", LocusChances[1], "{2}")

			AddHeaderOption("Locus 2 - Uterus")
			addInputOptionSt("Slider_Locus2State", "$DVT_LocusSlider", Morphs.Locus_Sliders[2], OPTION_FLAG_DISABLED)
			addSliderOptionSt("Scaling_Locus2State", "$DVT_LocusScale", Morphs.Locus_Scales[2], "{2}", OPTION_FLAG_DISABLED)
			addSliderOptionSt("Scaling_Locus2_MaxState", "$DVT_LocusMaximum", Morphs.Locus_Maxes[2], "{2}", OPTION_FLAG_DISABLED)
			addSliderOptionSt("Chance_Locus2", "$DVT_LocusChance", LocusChances[2], "{2}")

			setCursorPosition(1)

			addToggleOptionSt("DualBreastModeState", "$DVT_UseDualBreastMode", Morphs.UseDualBreastMode)

			if Morphs.UseDualBreastMode
				AddHeaderOption("Locus 3 - Breasts (left)")
			else
				AddHeaderOption("Locus 3 - Breasts")
			endIf
			addInputOptionSt("Slider_Locus3State", "$DVT_LocusSlider", Morphs.Locus_Sliders[3])
			addSliderOptionSt("Scaling_Locus3State", "$DVT_LocusScale", Morphs.Locus_Scales[3], "{2}")
			addSliderOptionSt("Scaling_Locus3_MaxState", "$DVT_LocusMaximum", Morphs.Locus_Maxes[3], "{2}")
			addSliderOptionSt("Chance_Locus3", "$DVT_LocusChance", LocusChances[3], "{2}")

			if Morphs.UseDualBreastMode
				AddHeaderOption("Locus 4 - Breasts (right)")
				addInputOptionSt("Slider_Locus4State", "$DVT_LocusSlider", Morphs.Locus_Sliders[4])
				addSliderOptionSt("Scaling_Locus4State", "$DVT_LocusScale", Morphs.Locus_Scales[4], "{2}")
				addSliderOptionSt("Scaling_Locus4_MaxState", "$DVT_LocusMaximum", Morphs.Locus_Maxes[4], "{2}")
				addSliderOptionSt("Chance_Locus4", "$DVT_LocusChance", LocusChances[4], "{2}")
			endIf

			if !Manager.VEGAN_MODE
				AddHeaderOption("Locus 5 - Scrotum")
				addInputOptionSt("Slider_Locus5State", "$DVT_LocusSlider", Morphs.Locus_Sliders[5])
				addSliderOptionSt("Scaling_Locus5State", "$DVT_LocusScale", Morphs.Locus_Scales[5], "{2}")
				addSliderOptionSt("Scaling_Locus5_MaxState", "$DVT_LocusMaximum", Morphs.Locus_Maxes[5], "{2}")
				addSliderOptionSt("Chance_Locus5", "$DVT_LocusChance", LocusChances[5], "{2}")
			endIf
		endIf
	ElseIf page == Pages[5]	;Female Weight

		SetCursorFillMode(LEFT_TO_RIGHT)
		If WeightManager.SkeletonScaling
			addSliderOptionSt("WeightFemaleRootLowState", "$DVT_RootLow", WeightManager.RootLow[0], "{2}")
			addSliderOptionSt("WeightFemaleRootHighState", "$DVT_RootHigh", WeightManager.RootHigh[0], "{2}")
		EndIf
		addInputOptionSt("WeightAddFemaleMorphState", "Add Female Morph", "")
		AddEmptyOption()

		String[] MorphStrings = WeightManager.MorphStrings
		float[] MultLow = WeightManager.MorphsLow
		float[] MultHigh = WeightManager.MorphsHigh

		;int cutoff = MorphStrings.length / 2 - 2
		

		int index = 0
		while index < 32 && MorphStrings[index] != ""
		;Female morphs span elements 0 through 31.
			;if index == cutoff
			;	setCursorPosition(1)
			;	AddHeaderOption("Morphs")
			;endIf

			int[] quad = new int[4]
			quad[0] = index
			quad[1] = AddInputOption("Morph", MorphStrings[index])
			AddEmptyOption()
			quad[2] = AddInputOption("Low", MultLow[index])
			quad[3] = AddInputOption("High", MultHigh[index])
			

			int oQuad = JArray.objectWithInts(quad)
			JIntMap.SetObj(optionsMap, quad[1], oQuad)
			JIntMap.SetObj(optionsMap, quad[2], oQuad)
			JIntMap.SetObj(optionsMap, quad[3], oQuad)

			index += 1
		endWhile
	ElseIf page == Pages[6]	;Male Weight

		SetCursorFillMode(LEFT_TO_RIGHT)
		If WeightManager.SkeletonScaling
			addSliderOptionSt("WeightMaleRootLowState", "$DVT_RootLow", WeightManager.RootLow[0], "{2}")
			addSliderOptionSt("WeightMaleRootHighState", "$DVT_RootHigh", WeightManager.RootHigh[0], "{2}")
		EndIf
		addInputOptionSt("WeightAddMaleMorphState", "Add Male Morph", "")
		AddEmptyOption()

		String[] MorphStrings = WeightManager.MorphStrings
		float[] MultLow = WeightManager.MorphsLow
		float[] MultHigh = WeightManager.MorphsHigh

		;int cutoff = MorphStrings.length / 2 - 2
		
		int index = 32
		while index < 64 && MorphStrings[index] != ""
		;Male morphs span elements 32 through 63.
			;if index == cutoff
			;	setCursorPosition(1)
			;	AddHeaderOption("Morphs")
			;endIf

			int[] quad = new int[4]
			quad[0] = index
			quad[1] = AddInputOption("Morph", MorphStrings[index])
			AddEmptyOption()
			quad[2] = AddInputOption("Low", MultLow[index])
			quad[3] = AddInputOption("High", MultHigh[index])

			int oQuad = JArray.objectWithInts(quad)
			JIntMap.SetObj(optionsMap, quad[1], oQuad)
			JIntMap.SetObj(optionsMap, quad[2], oQuad)
			JIntMap.SetObj(optionsMap, quad[3], oQuad)

			index += 1
		endWhile
	;/ To be uncommented once more creature WG sliders are done. TODO
	ElseIf page == Pages[7]	;Creature Weight

		SetCursorFillMode(LEFT_TO_RIGHT)
		If WeightManager.SkeletonScaling
			addSliderOptionSt("WeightCreatureRootLowState", "$DVT_RootLow", WeightManager.RootLow[0], "{2}")
			addSliderOptionSt("WeightCreatureRootHighState", "$DVT_RootHigh", WeightManager.RootHigh[0], "{2}")
		EndIf
		addInputOptionSt("WeightAddCreatureMorphState", "Add Creature Morph", "")
		AddEmptyOption()

		String[] MorphStrings = WeightManager.MorphStrings
		float[] MultLow = WeightManager.MorphsLow
		float[] MultHigh = WeightManager.MorphsHigh

		;int cutoff = MorphStrings.length / 2 - 2
		
		int index = 64
		while index < 96 && MorphStrings[index] != ""
		;Creature morphs span elements 64 through 95.
			;if index == cutoff
			;	setCursorPosition(1)
			;	AddHeaderOption("Morphs")
			;endIf

			int[] quad = new int[4]
			quad[0] = index
			quad[1] = AddInputOption("Morph", MorphStrings[index])
			AddEmptyOption()
			quad[2] = AddInputOption("Low", MultLow[index])
			quad[3] = AddInputOption("High", MultHigh[index])

			int oQuad = JArray.objectWithInts(quad)
			JIntMap.SetObj(optionsMap, quad[1], oQuad)
			JIntMap.SetObj(optionsMap, quad[2], oQuad)
			JIntMap.SetObj(optionsMap, quad[3], oQuad)

			index += 1
		endWhile
	/;
	ElseIf page == Pages[8]

		if SKSE.GetVersion()
			addTextOption("SKSE", SKSE.GetVersion() + "." + SKSE.GetVersionMinor())
		else
			addTextOption("SKSE", "MISSING")
		endIf
		
		if MiscUtil.FileExists("Data/DLLPlugins/NetScriptFramework.Runtime.dll") && MiscUtil.FileExists("Data/NetScriptFramework/NetScriptFramework.log.txt")
			String NetscriptLog = MiscUtil.ReadFromFile("Data/NetScriptFramework/NetScriptFramework.log.txt")
			AddLogVersion("NetScriptFramework", NetscriptLog, " Initializing framework version %d+", "%d+")
			AddLogCheck("CustomSkillFramework", NetscriptLog, "CustomSkills.dll")
		else
			addTextOption("NetScriptFramework", "MISSING")
			addTextOption("CustomSkillFramework", "MISSING")
		endIf

		AddSKSEDetails("SSEEngineFixes", "EngineFixes plugin", "EngineFixes plugin")
		AddSKSEDetails("JContainers", "JContainers", "JContainers64", JContainers.FeatureVersion(), JContainers.APIVersion())
		AddSKSEDetails("PapyrusUtil", "papyrusutil plugin", "papyrusutil", PapyrusUtil.GetVersion(), PapyrusUtil.GetScriptVersion())
		AddSKSEDetails("ConsoleUtil", "console plugin", "ConsoleUtilSSE", ConsoleUtil.GetVersion())
		AddSKSEDetails("PO3 Papyrus Extender", "PapyrusExtender", "powerofthree's Papyrus Extender")
		AddSKSEDetails("NIOverride", "NIOverride", "skee", NIOverride.GetScriptVersion())
		AddQuestDetails("RaceMenu", "RaceMenu", RaceMenuBase.GetScriptVersionRelease())
		AddQuestDetails("XPMSE", "XPMSEMCM", XPMSELib.GetXPMSELibVersion() as String)
	EndIf

endEvent

event OnOptionInputOpen(int oid)
	{Used exclusively for dynamic lists.}

	parent.OnOptionInputOpen(oid)
	if !AssertTrue(PREFIX, "OnOptionInputOpen", "JIntMap.HasKey(optionsMap, oid)", JIntMap.HasKey(optionsMap, oid))
		return
	endIf

	String[] MorphStrings = WeightManager.MorphStrings
	float[] MultLow = WeightManager.MorphsLow
	float[] MultHigh = WeightManager.MorphsHigh

	; Get the quad.
	int oq = JIntMap.GetObj(optionsMap, oid)
	if !AssertExists(PREFIX, "OnOptionInputOpen", "oq", oq)
		return
	endIf

	int[] quad = JArray.asIntArray(oq)
	int index = quad[0]
	String morph = MorphStrings[index]

	if oid == quad[1]
		SetInputDialogStartText(MorphStrings[index])
	elseif oid == quad[2]
		SetInputDialogStartText(MultLow[index])
	elseif oid == quad[3]
		SetInputDialogStartText(MultHigh[index])
	endIf
endEvent

event OnOptionInputAccept(int oid, string a_input)

	parent.OnOptionInputAccept(oid, a_input)
	if !AssertTrue(PREFIX, "OnOptionInputAccept", "JIntMap.hasKey(optionsMap, oid)", JIntMap.hasKey(optionsMap, oid))
		return
	endIf

	String[] MorphStrings = WeightManager.MorphStrings
	float[] MultLow = WeightManager.MorphsLow
	float[] MultHigh = WeightManager.MorphsHigh

	; Get the quad.
	int oq = JIntMap.GetObj(optionsMap, oid)
	if !AssertExists(PREFIX, "OnOptionInputAccept", "oq", oq)
		return
	endIf

	int[] quad = JArray.asIntArray(oq)
	int index = quad[0]
	String morph = MorphStrings[index]

	if oid == quad[1]
		if a_input == ""
			WeightManager.RemoveMorph(index)
			ForcePageReset()
		else
			MorphStrings[index] = a_input
			SetInputOptionValue(oid, a_input)
		endIf

	elseif oid == quad[2]
		float val = a_input as float
		MultLow[index] = val
		SetInputOptionValue(oid, val)
	
	elseif oid == quad[3]
		float val = a_input as float
		MultHigh[index] = val
		SetInputOptionValue(oid, val)
	endIf
	WeightManager.SyncSettings(true)
endEvent

Event OnPageSelect(string a_page)
    optionsMap = JValue.ReleaseAndRetain(optionsMap, JIntMap.Object(), PREFIX)

	if difficulty < 5
		difficulty = checkDifficultyPreset()
	endIf

	If a_page == Pages[8]
		isAutoPred = Manager.IsVorish(target)
	EndIf
EndEvent

bool Function ConflictCheck(String reference, String conflictControl, String conflictName)
{Taken from Nether's Follower Framework. }
	if !conflictControl || reference == conflictName
		return true
	endIf

	string myMsg

	if conflictName
		myMsg = "This key is already mapped to \"" + conflictControl + "\" (" + conflictName + ")\n\nContinue?"
	else
		myMsg = "This key is already mapped to \"" + conflictControl + "\"\n\nContinue?"
	endif

	return ShowMessage(myMsg, true)
endFunction

state PredPerksState
	event OnDefaultST()
		PerkMenuQueue = 0
		setToggleOptionValueST(false)
		SetToggleOptionValueST(false, false, "PreyPerksState")
	endEvent

	event OnSelectST()
		if PerkMenuQueue != 1
			PerkMenuQueue = 1
			setToggleOptionValueST(true)
			SetToggleOptionValueST(false, false, "PreyPerksState")
		else
			PerkMenuQueue = 0
			setToggleOptionValueST(false)
		endIf
	endEvent

	event OnHighlightST()
		SetInfoText("If selected, then the Predator perk tree will be displayed once the MCM is closed.")
	endEvent
endstate

state PreyPerksState
	event OnDefaultST()
		PerkMenuQueue = 0
		setToggleOptionValueST(false)
		SetToggleOptionValueST(false, false, "PredPerksState")
	endEvent

	event OnSelectST()
		if PerkMenuQueue != 2
			PerkMenuQueue = 2
			setToggleOptionValueST(true)
			SetToggleOptionValueST(false, false, "PredPerksState")
		else
			PerkMenuQueue = 0
			setToggleOptionValueST(false)
		endIf
	endEvent

	event OnHighlightST()
		SetInfoText("If selected, then the Prey perk tree will be displayed once the MCM is closed.")
	endEvent
endstate

state QuickSettingsKeyState
	event OnKeyMapChangeST(int newKeyCode, string conflictControl, string conflictName)
		if ConflictCheck("Settings", conflictControl, conflictName)
			PlayerAlias.UnRegisterForKey(PlayerAlias.QUICK_KEY)
			
			if newKeyCode > 1
				PlayerAlias.QUICK_KEY = newKeyCode
				SetKeyMapOptionValueST(PlayerAlias.QUICK_KEY)
				PlayerAlias.RegisterForKey(PlayerAlias.QUICK_KEY)
				playerRef.RemoveSpell(QuickSettings)
			else
				PlayerAlias.QUICK_KEY = 0
				SetKeyMapOptionValueST(PlayerAlias.QUICK_KEY)
				playerRef.AddSpell(QuickSettings)
			endIf
		endIf
	endEvent

	event OnDefaultST()
		PlayerAlias.UnRegisterForKey(PlayerAlias.QUICK_KEY)
		PlayerAlias.QUICK_KEY = 0
		SetKeyMapOptionValueST(0)
		playerRef.RemoveSpell(QuickSettings)
	endEvent

	event OnHighlightST()
		SetInfoText("Sets the quick-settings key.")
	endEvent
endState

state compelVoreKeyState
	event OnKeyMapChangeST(int newKeyCode, string conflictControl, string conflictName)
		if ConflictCheck("Compel", conflictControl, conflictName)
			PlayerAlias.UnRegisterForKey(PlayerAlias.COMPEL_KEY)
			PlayerAlias.COMPEL_KEY = newKeyCode
			SetKeyMapOptionValueST(PlayerAlias.COMPEL_KEY)

			if Manager.DEBUGGING && PlayerAlias.COMPEL_KEY > 1
				PlayerAlias.RegisterForKey(PlayerAlias.COMPEL_KEY)
			endIf
		endIf
	endEvent

	event OnDefaultST()
		PlayerAlias.UnRegisterForKey(PlayerAlias.COMPEL_KEY)
		PlayerAlias.COMPEL_KEY = 43
		SetKeyMapOptionValueST(PlayerAlias.COMPEL_KEY)
		
		if Manager.DEBUGGING
			PlayerAlias.RegisterForKey(PlayerAlias.COMPEL_KEY)
		endIf
	endEvent

	event OnHighlightST()
		SetInfoText("Sets the Compel Vore key. Forces actors to vore or endo each others. Only works in Debugging mode.")
	endEvent
endState

state ForgetKeyState
	event OnKeyMapChangeST(int newKeyCode, string conflictControl, string conflictName)
		if ConflictCheck("Forget", conflictControl, conflictName)
			PlayerAlias.UnRegisterForKey(PlayerAlias.FORGET_KEY)
			PlayerAlias.FORGET_KEY = newKeyCode
			SetKeyMapOptionValueST(PlayerAlias.FORGET_KEY)

			if Manager.DEBUGGING && PlayerAlias.FORGET_KEY > 1
				PlayerAlias.RegisterForKey(PlayerAlias.FORGET_KEY)
			endIf
		endIf
	endEvent

	event OnDefaultST()
		PlayerAlias.UnRegisterForKey(PlayerAlias.FORGET_KEY)
		PlayerAlias.FORGET_KEY = 0
		SetKeyMapOptionValueST(PlayerAlias.FORGET_KEY)
		
		if Manager.DEBUGGING
			PlayerAlias.RegisterForKey(PlayerAlias.FORGET_KEY)
		endIf
	endEvent

	event OnHighlightST()
		SetInfoText("Sets the Forget Spells key. The player will lose any spells or powers that are equipped. Only works in Debugging mode.")
	endEvent
endState

state VoreKeyState
	event OnKeyMapChangeST(int newKeyCode, string conflictControl, string conflictName)
		if ConflictCheck("Vore", conflictControl, conflictName)
			PlayerAlias.UnregisterForKey(PlayerAlias.VORE_KEY)
			
			if newKeyCode > 1
				PlayerAlias.VORE_KEY = newKeyCode
				SetKeyMapOptionValueST(PlayerAlias.VORE_KEY)
				PlayerAlias.RegisterForKey(PlayerAlias.VORE_KEY)
			else
				PlayerAlias.VORE_KEY = 0
				SetKeyMapOptionValueST(PlayerAlias.VORE_KEY)
			endIf
		endIf
	endEvent

	event OnDefaultST()
		PlayerAlias.UnregisterForKey(PlayerAlias.VORE_KEY)
		PlayerAlias.VORE_KEY = 0
		SetKeyMapOptionValueST(PlayerAlias.VORE_KEY)
	endEvent

	event OnHighlightST()
		SetInfoText("Sets the vore key.")
	endEvent
endState

state EndoKeyState
	event OnKeyMapChangeST(int newKeyCode, string conflictControl, string conflictName)
		if ConflictCheck("Endo", conflictControl, conflictName)
			PlayerAlias.UnregisterForKey(PlayerAlias.ENDO_KEY)
			
			if newKeyCode > 1
				PlayerAlias.ENDO_KEY = newKeyCode
				SetKeyMapOptionValueST(PlayerAlias.ENDO_KEY)
				PlayerAlias.RegisterForKey(PlayerAlias.ENDO_KEY)
			else
				PlayerAlias.ENDO_KEY = 0
				SetKeyMapOptionValueST(PlayerAlias.ENDO_KEY)
			endIf
		endIf
	endEvent

	event OnDefaultST()
		PlayerAlias.UnregisterForKey(PlayerAlias.ENDO_KEY)
		PlayerAlias.ENDO_KEY = 34
		SetKeyMapOptionValueST(PlayerAlias.ENDO_KEY)
	endEvent

	event OnHighlightST()
		SetInfoText("Sets the endo key.")
	endEvent
endState

state CombKeyState
	event OnKeyMapChangeST(int newKeyCode, string conflictControl, string conflictName)
		if ConflictCheck("Swallow", conflictControl, conflictName)
			PlayerAlias.UnregisterForKey(PlayerAlias.COMB_KEY)
			
			if newKeyCode > 1
				PlayerAlias.COMB_KEY = newKeyCode
				SetKeyMapOptionValueST(PlayerAlias.COMB_KEY)
				PlayerAlias.RegisterForKey(PlayerAlias.COMB_KEY)
			else
				PlayerAlias.COMB_KEY = 0
				SetKeyMapOptionValueST(PlayerAlias.COMB_KEY)
			endIf
		endIf
	endEvent

	event OnDefaultST()
		PlayerAlias.UnregisterForKey(PlayerAlias.COMB_KEY)
		PlayerAlias.COMB_KEY = 0
		SetKeyMapOptionValueST(PlayerAlias.COMB_KEY)
	endEvent

	event OnHighlightST()
		SetInfoText("Sets the contextual swallow key. Devourment will try to decide based on context whether to use vore or endo. This power usually doesn't work correctly on very large creatures because of range and targetting issues.")
	endEvent
endState

state dialogueKeyState
	event OnKeyMapChangeST(int newKeyCode, string conflictControl, string conflictName)
		if ConflictCheck("Dialogue", conflictControl, conflictName)
			PlayerAlias.UnregisterForKey(PlayerAlias.DIALOGUE_KEY)
			
			if newKeyCode > 1
				PlayerAlias.DIALOGUE_KEY = newKeyCode
				SetKeyMapOptionValueST(PlayerAlias.DIALOGUE_KEY)
				PlayerAlias.RegisterForKey(PlayerAlias.DIALOGUE_KEY)
			else
				PlayerAlias.DIALOGUE_KEY = 0
				SetKeyMapOptionValueST(PlayerAlias.DIALOGUE_KEY)
			endIf
		endIf
	endEvent

	event OnDefaultST()
		PlayerAlias.UnregisterForKey(PlayerAlias.DIALOGUE_KEY)
		PlayerAlias.DIALOGUE_KEY = 34
		SetKeyMapOptionValueST(PlayerAlias.DIALOGUE_KEY)
		PlayerAlias.RegisterForKey(PlayerAlias.DIALOGUE_KEY)
	endEvent

	event OnHighlightST()
		SetInfoText("Sets the vore dialog key.")
	endEvent
endState

state SkullsForDragonsState
	event OnDefaultST()
		SkullHandler.SkullsForDragons = true
		setToggleOptionValueST(SkullHandler.SkullsForDragons)
	endEvent
	event OnSelectST()
		SkullHandler.SkullsForDragons = !SkullHandler.SkullsForDragons
		SkullHandler.SkullsForEveryone = SkullHandler.SkullsForEveryone && SkullHandler.SkullsForDragons
		setToggleOptionValueST(SkullHandler.SkullsForDragons)
		setToggleOptionValueST(SkullHandler.SkullsForEveryone, false, "SkullsForEveryoneState")
	endEvent
	event OnHighlightST()
		SetInfoText("Collect the skulls of dragons after digesting them. Careful, they're heavy.")
	endEvent
endstate

state SkullsForUniqueState
	event OnDefaultST()
		SkullHandler.SkullsForUnique = true
		setToggleOptionValueST(SkullHandler.SkullsForUnique)
	endEvent
	event OnSelectST()
		SkullHandler.SkullsForUnique = !SkullHandler.SkullsForUnique
		SkullHandler.SkullsForEveryone = SkullHandler.SkullsForEveryone && SkullHandler.SkullsForUnique
		setToggleOptionValueST(SkullHandler.SkullsForUnique)
		setToggleOptionValueST(SkullHandler.SkullsForEveryone, false, "SkullsForEveryoneState")
	endEvent
	event OnHighlightST()
		SetInfoText("Collect the skulls of unique NPCs after digesting them.\nUseful for resurrecting them if you need them for quest purposes.")
	endEvent
endstate

state SkullsForEssentialState
	event OnDefaultST()
		SkullHandler.SkullsForEssential = true
		setToggleOptionValueST(SkullHandler.SkullsForEssential)
	endEvent
	event OnSelectST()
		SkullHandler.SkullsForEssential = !SkullHandler.SkullsForEssential
		SkullHandler.SkullsForEveryone = SkullHandler.SkullsForEveryone && SkullHandler.SkullsForEssential
		setToggleOptionValueST(SkullHandler.SkullsForEssential)
		setToggleOptionValueST(SkullHandler.SkullsForEveryone, false, "SkullsForEveryoneState")
	endEvent
	event OnHighlightST()
		SetInfoText("Collect the skulls of essential, protected, and invulnerable NPCs after digesting them.\nUseful for resurrecting them if you need them for quest purposes.")
	endEvent
endstate

state SkullsForUnleveledState
	event OnDefaultST()
		SkullHandler.SkullsForUnleveled = true
		setToggleOptionValueST(SkullHandler.SkullsForUnleveled)
	endEvent
	event OnSelectST()
		SkullHandler.SkullsForUnleveled = !SkullHandler.SkullsForUnleveled
		SkullHandler.SkullsForEveryone = SkullHandler.SkullsForEveryone && SkullHandler.SkullsForUnleveled
		setToggleOptionValueST(SkullHandler.SkullsForUnleveled)
		setToggleOptionValueST(SkullHandler.SkullsForEveryone, false, "SkullsForEveryoneState")
	endEvent
	event OnHighlightST()
		SetInfoText("Collect the skulls of Unleveled Actors.")
	endEvent
endstate

state SkullsForEveryoneState
	event OnDefaultST()
		SkullHandler.SkullsForEveryone = false
		setToggleOptionValueST(SkullHandler.SkullsForEveryone)
	endEvent
	event OnSelectST()
		SkullHandler.SkullsForEveryone = !SkullHandler.SkullsForEveryone
		SkullHandler.SkullsForUnique = SkullHandler.SkullsForUnique || SkullHandler.SkullsForEveryone
		SkullHandler.SkullsForEssential = SkullHandler.SkullsForEssential || SkullHandler.SkullsForEveryone
		SkullHandler.SkullsForUnleveled = SkullHandler.SkullsForUnleveled || SkullHandler.SkullsForEveryone
		SkullHandler.SkullsForDragons = SkullHandler.SkullsForDragons || SkullHandler.SkullsForEveryone
		setToggleOptionValueST(SkullHandler.SkullsForEveryone)
		setToggleOptionValueST(SkullHandler.SkullsForUnique, false, "SkullsForUniqueState")
		setToggleOptionValueST(SkullHandler.SkullsForEssential, false, "SkullsForEssentialState")
		setToggleOptionValueST(SkullHandler.SkullsForUnleveled, false, "SkullsForUnleveledState")
		setToggleOptionValueST(SkullHandler.SkullsForDragons, false, "SkullsForDragonsState")
	endEvent
	event OnHighlightST()
		SetInfoText("Collect the skulls of ALL NPCs after digesting them.\nNot recommend. The skulls can accumulate extremely quickly.")
	endEvent
endstate

state SkullsSeparateState
	event OnDefaultST()
		SkullHandler.SkullsSeparate = false
		setToggleOptionValueST(SkullHandler.SkullsSeparate)
	endEvent
	event OnSelectST()
		SkullHandler.SkullsSeparate = !SkullHandler.SkullsSeparate
		setToggleOptionValueST(SkullHandler.SkullsSeparate)
	endEvent
	event OnHighlightST()
		SetInfoText("If enabled, skulls will be digested separately from the rest of the prey's body. This can cause problems if you find a way to re-swallow the skull before the rest of the body finishes digesting! It's fun though. Sooo fun.")
	endEvent
endstate

state WeightFemaleRootLowState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(WeightManager.RootLow[0])
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(0.1, WeightManager.RootHigh[0])
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		WeightManager.RootLow[0] = a_value
		WeightManager.SyncSettings(false)
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		WeightManager.RootLow[0] = 1.0
		SetSliderOptionValueST(1.0, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("$DVT_Help_FemaleRootLow")
	endEvent
endState

state WeightFemaleRootHighState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(WeightManager.RootHigh[0])
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(WeightManager.RootLow[0], 5.0)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		WeightManager.RootHigh[0] = a_value
		WeightManager.SyncSettings(false)
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		WeightManager.RootHigh[0] = 1.0
		SetSliderOptionValueST(1.0, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("$DVT_Help_FemaleRootHigh")
	endEvent
endState

state WeightMaleRootLowState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(WeightManager.RootLow[1])
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(0.1, WeightManager.RootHigh[1])
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		WeightManager.RootLow[1] = a_value
		WeightManager.SyncSettings(false)
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		WeightManager.RootLow[1] = 1.0
		SetSliderOptionValueST(1.0, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("$DVT_Help_MaleRootLow")
	endEvent
endState

state WeightMaleRootHighState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(WeightManager.RootHigh[1])
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(WeightManager.RootLow[1], 5.0)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		WeightManager.RootHigh[1] = a_value
		WeightManager.SyncSettings(false)
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		WeightManager.RootHigh[1] = 1.0
		SetSliderOptionValueST(1.0, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("$DVT_Help_MaleRootHigh")
	endEvent
endState

;/ To be uncommented once more creature WG sliders are done. TODO
state WeightCreatureRootLowState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(WeightManager.RootLow[2])
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(0.1, WeightManager.RootHigh[2])
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		WeightManager.RootLow[2] = a_value
		WeightManager.SyncSettings(false)
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		WeightManager.RootLow[2] = 1.0
		SetSliderOptionValueST(1.0, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("$DVT_Help_CreatureRootLow")
	endEvent
endState

state WeightCreatureRootHighState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(WeightManager.RootHigh[2])
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(WeightManager.RootLow[2], 5.0)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		WeightManager.RootHigh[2] = a_value
		WeightManager.SyncSettings(false)
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		WeightManager.RootHigh[2] = 1.0
		SetSliderOptionValueST(1.0, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("$DVT_Help_CreatureRootHigh")
	endEvent
endState
/;

state WeightAddFemaleMorphState
	event OnInputOpenST()
		SetInputDialogStartText("")
	endEvent

	event OnInputAcceptST(string a_input)
		WeightManager.AddMorph(a_input, 0.0, 0.0, 0)
		ForcePageReset()
	endEvent

	event OnHighlightST()
		SetInfoText("Add a female weight morph.")
	endEvent
endState

state WeightAddMaleMorphState
	event OnInputOpenST()
		SetInputDialogStartText("")
	endEvent

	event OnInputAcceptST(string a_input)
		WeightManager.AddMorph(a_input, 0.0, 0.0, 1)
		ForcePageReset()
	endEvent

	event OnHighlightST()
		SetInfoText("Add a male weight morph.")
	endEvent
endState

;/ To be uncommented once more creature WG sliders are done. TODO
state WeightAddCreatureMorphState
	event OnInputOpenST()
		SetInputDialogStartText("")
	endEvent

	event OnInputAcceptST(string a_input)
		WeightManager.AddMorph(a_input, 0.0, 0.0, 2)
		ForcePageReset()
	endEvent

	event OnHighlightST()
		SetInfoText("Add a creature weight morph.")
	endEvent
endState
/;

state Scaling_Locus0State
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Morphs.Locus_Scales[0])
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(0.0, 10.0)
		SetSliderDialogInterval(0.05)
	endEvent

	event OnSliderAcceptST(float a_value)
		Morphs.Locus_Scales[0] = a_value
		SetSliderOptionValueST(a_value, "{2}")
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.Locus_Scales[0] = 1.0
		SetSliderOptionValueST(1.0, "{2}")
		resetBellies = true
	endEvent

	event OnHighlightST()
		SetInfoText("Scaling size for Locus 0 (which is the stomach by default).")
	endEvent
endState

state Scaling_Locus1State
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Morphs.Locus_Scales[1])
		SetSliderDialogDefaultValue(5.0)
		SetSliderDialogRange(0.0, 20.0)
		SetSliderDialogInterval(0.1)
	endEvent

	event OnSliderAcceptST(float a_value)
		Morphs.Locus_Scales[1] = a_value
		SetSliderOptionValueST(a_value, "{2}")
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.Locus_Scales[1] = 5.0
		SetSliderOptionValueST(5.0, "{2}")
		resetBellies = true
	endEvent

	event OnHighlightST()
		SetInfoText("Scaling size for Locus 1 (which is the buttocks by default).")
	endEvent
endState

state Scaling_Locus3State
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Morphs.Locus_Scales[3])
		SetSliderDialogDefaultValue(2.0)
		SetSliderDialogRange(0.0, 10.0)
		SetSliderDialogInterval(0.05)
	endEvent

	event OnSliderAcceptST(float a_value)
		Morphs.Locus_Scales[3] = a_value
		SetSliderOptionValueST(a_value, "{2}")
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.Locus_Scales[3] = 2.0
		SetSliderOptionValueST(2.0, "{2}")
		resetBellies = true
	endEvent

	event OnHighlightST()
		if Morphs.UseDualBreastMode
			SetInfoText("Scaling size for Locus 3 (which is the left breast by default).")
		else
			SetInfoText("Scaling size for Locus 3 (which is the breasts by default).")
		endIf
	endEvent
endState

state Scaling_Locus4State
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Morphs.Locus_Scales[4])
		SetSliderDialogDefaultValue(2.0)
		SetSliderDialogRange(0.0, 10.0)
		SetSliderDialogInterval(0.05)
	endEvent

	event OnSliderAcceptST(float a_value)
		Morphs.Locus_Scales[4] = a_value
		SetSliderOptionValueST(a_value, "{2}")
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.Locus_Scales[4] = 2.0
		SetSliderOptionValueST(2.0, "{2}")
		resetBellies = true
	endEvent

	event OnHighlightST()
		SetInfoText("Scaling size for Locus 4 (which is the right breast by default).")
	endEvent
endState

state Scaling_Locus5State
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Morphs.Locus_Scales[5])
		SetSliderDialogDefaultValue(4.0)
		SetSliderDialogRange(0.0, 20.0)
		SetSliderDialogInterval(0.1)
	endEvent

	event OnSliderAcceptST(float a_value)
		Morphs.Locus_Scales[5] = a_value
		SetSliderOptionValueST(a_value, "{2}")
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.Locus_Scales[5] = 4.0
		SetSliderOptionValueST(4.0, "{2}")
		resetBellies = true
	endEvent

	event OnHighlightST()
		SetInfoText("Scaling size for Locus 5 (which is the scrotum by default).")
	endEvent
endState

state Scaling_Locus0_MaxState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Morphs.Locus_Maxes[0])
		SetSliderDialogDefaultValue(5.0)
		SetSliderDialogRange(0.0, 50.0)
		SetSliderDialogInterval(0.1)
	endEvent

	event OnSliderAcceptST(float a_value)
		Morphs.Locus_Maxes[0] = a_value
		SetSliderOptionValueST(a_value, "{2}")
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.Locus_Maxes[0] = 5.0
		SetSliderOptionValueST(5.0, "{2}")
		resetBellies = true
	endEvent

	event OnHighlightST()
		SetInfoText("Maximum scaling size for Locus 0 (which is the stomach by default).")
	endEvent
endState

state Scaling_Locus1_MaxState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Morphs.Locus_Maxes[1])
		SetSliderDialogDefaultValue(25.0)
		SetSliderDialogRange(0.0, 250.0)
		SetSliderDialogInterval(0.5)
	endEvent

	event OnSliderAcceptST(float a_value)
		Morphs.Locus_Maxes[1] = a_value
		SetSliderOptionValueST(a_value, "{2}")
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.Locus_Maxes[1] = 25.0
		SetSliderOptionValueST(25.0, "{2}")
		resetBellies = true
	endEvent

	event OnHighlightST()
		SetInfoText("Maximum scaling size for Locus 1 (which is the buttocks by default).")
	endEvent
endState

state Scaling_Locus3_MaxState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Morphs.Locus_Maxes[3])
		SetSliderDialogDefaultValue(10.0)
		SetSliderDialogRange(0.0, 100.0)
		SetSliderDialogInterval(0.2)
	endEvent

	event OnSliderAcceptST(float a_value)
		Morphs.Locus_Maxes[3] = a_value
		SetSliderOptionValueST(a_value, "{2}")
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.Locus_Maxes[3] = 10.0
		SetSliderOptionValueST(10.0, "{2}")
		resetBellies = true
	endEvent

	event OnHighlightST()
		if Morphs.UseDualBreastMode
			SetInfoText("Maximum scaling size for Locus 3 (which is the left breast by default).")
		else
			SetInfoText("Maximum scaling size for Locus 3 (which is the breasts by default).")
		endIf
	endEvent
endState

state Scaling_Locus4_MaxState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Morphs.Locus_Maxes[4])
		SetSliderDialogDefaultValue(10.0)
		SetSliderDialogRange(0.0, 100.0)
		SetSliderDialogInterval(0.2)
	endEvent

	event OnSliderAcceptST(float a_value)
		Morphs.Locus_Maxes[4] = a_value
		SetSliderOptionValueST(a_value, "{2}")
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.Locus_Maxes[4] = 10.0
		SetSliderOptionValueST(10.0, "{2}")
		resetBellies = true
	endEvent

	event OnHighlightST()
		SetInfoText("Maximum scaling size for Locus 4 (which is the right breast by default).")
	endEvent
endState

state Scaling_Locus5_MaxState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Morphs.Locus_Maxes[5])
		SetSliderDialogDefaultValue(20.0)
		SetSliderDialogRange(0.0, 250.0)
		SetSliderDialogInterval(0.5)
	endEvent

	event OnSliderAcceptST(float a_value)
		Morphs.Locus_Maxes[5] = a_value
		SetSliderOptionValueST(a_value, "{2}")
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.Locus_Maxes[5] = 20.0
		SetSliderOptionValueST(20.0, "{2}")
		resetBellies = true
	endEvent

	event OnHighlightST()
		SetInfoText("Maximum scaling size for Locus 5 (which is the scrotum by default).")
	endEvent
endState

state DualBreastModeState
	event OnSelectST()
		Morphs.UseDualBreastMode = !Morphs.UseDualBreastMode
		setToggleOptionValueST(Morphs.UseDualBreastMode)
		ForcePageReset()
		resetBellies = true
	endEvent
	event OnDefaultST()
		Morphs.UseDualBreastMode = true
		setToggleOptionValueST(Morphs.UseDualBreastMode)
		ForcePageReset()
		resetBellies = true
	endEvent
	event OnHighlightST()
		SetInfoText("In Dual-Breast mode, the breasts are treated as separate locuses.")
	endEvent
endstate

state Slider_Locus0State
	event OnInputOpenST()
		SetInputDialogStartText(Morphs.Locus_Sliders[0])
	endEvent

	event OnInputAcceptST(string a_input)
		Morphs.Locus_Sliders[0] = a_input
		SetInputOptionValueST(Morphs.Locus_Sliders[0])
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.Locus_Sliders[0] = "Vore Prey Belly"
		SetInputOptionValueST(Morphs.Locus_Sliders[0])
		resetBellies = true
	endEvent

	event OnHighlightST()
		SetInfoText("Slider/Node for Locus 0 (which is the belly by default). Recommendations:\n" + \
		"'Vore Prey Belly' is a slider present in the MorphVore bodies and the equippable bellies.\n" + \
		"'PregnancyBelly' is a slider in CBBE, 3BA, and BHUNP; it's supported by many armors and outfits.")
	endEvent
endState

state Slider_Locus1State
	event OnInputOpenST()
		SetInputDialogStartText(Morphs.Locus_Sliders[1])
	endEvent

	event OnInputAcceptST(string a_input)
		Morphs.Locus_Sliders[1] = a_input
		SetInputOptionValueST(Morphs.Locus_Sliders[1])
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.Locus_Sliders[1] = "ChubbyButt"
		SetInputOptionValueST(Morphs.Locus_Sliders[1])
		resetBellies = true
	endEvent

	event OnHighlightST()
		SetInfoText("Slider/Node for Locus 1 (which is the buttocks by default).\n" + \
		"Recommended: 'ChubbyButt' is a slider in CBBE, 3BA, and BHUNP; it's supported by many armors and outfits.")
	endEvent
endState

state Slider_Locus3State
	event OnInputOpenST()
		SetInputDialogStartText(Morphs.Locus_Sliders[3])
	endEvent

	event OnInputAcceptST(string a_input)
		Morphs.Locus_Sliders[3] = a_input
		SetInputOptionValueST(Morphs.Locus_Sliders[3])
		resetBellies = true
	endEvent

	event OnDefaultST()
		if Morphs.UseDualBreastMode
			Morphs.Locus_Sliders[3] = "BVoreL"
		else
			Morphs.Locus_Sliders[3] = "BreastsNewSH"
		endIf
		SetInputOptionValueST(Morphs.Locus_Sliders[3])
		resetBellies = true
	endEvent

	event OnHighlightST()
		if Morphs.UseDualBreastMode
			SetInfoText(\
			"Slider/Node for Locus 3 (which is the left breast by default). Recommendations:\n" + \
			"'BVoreL' is the left breast vore slider from the MorphVore 3BAv2 body.\n" + \
			"'NPC L Breast' is the left breast node from the XPMSE skeleton. It works with almost everything.")
		else
			SetInfoText("Slider/Node for Locus 3 (which is the breasts by default).\n" + \
			"Recommended: 'BreastsNewSH' is a slider in CBBE, 3BA, and BHUNP; it's supported by many armors and outfits.")
		endIf
	endEvent
endState

state Slider_Locus4State
	event OnInputOpenST()
		SetInputDialogStartText(Morphs.Locus_Sliders[4])
	endEvent

	event OnInputAcceptST(string a_input)
		Morphs.Locus_Sliders[4] = a_input
		SetInputOptionValueST(Morphs.Locus_Sliders[4])
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.Locus_Sliders[4] = "BVoreR"
		SetInputOptionValueST(Morphs.Locus_Sliders[4])
		resetBellies = true
	endEvent

	event OnHighlightST()
		if Morphs.UseDualBreastMode
			SetInfoText(\
			"Slider/Node for Locus 4 (which is the right breast by default). Recommendations:\n" + \
			"'BVoreR' is the right breast vore slider from the MorphVore 3BAv2 body.\n" + \
			"'NPC R Breast' is the right breast node from the XPMSE skeleton. It works with almost everything.")
		else
		endIf
	endEvent
endState

state Slider_Locus5State
	event OnInputOpenST()
		SetInputDialogStartText(Morphs.Locus_Sliders[5])
	endEvent

	event OnInputAcceptST(string a_input)
		Morphs.Locus_Sliders[5] = a_input
		SetInputOptionValueST(Morphs.Locus_Sliders[5])
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.Locus_Sliders[5] = "CVore"
		SetInputOptionValueST(Morphs.Locus_Sliders[5])
		resetBellies = true
	endEvent

	event OnHighlightST()
		SetInfoText("Slider/Node for Locus 5 (which is the scrotum by default). Recommendations:\n" + \
		"'CVore' is the cockvore slider from the MorphVore male bodies.\n" + \
		"'NPC GenitalsScrotum [GenScrot]' is the scrotum node from the XPMSE skeleton. It works with almost everything.")
	endEvent
endState

state Chance_Locus0
	Event OnSliderOpenST()
		SetSliderDialogStartValue(LocusChances[0])
		SetSliderDialogDefaultValue(0.5)
		SetSliderDialogRange(0.0, 100.0)
		SetSliderDialogInterval(0.02)
	endEvent

	event OnSliderAcceptST(float a_value)
		LocusChances[0] = a_value
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		LocusChances[0] = 0.5
		SetSliderOptionValueST(0.5, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("Probability that NPCs will ingest to locus 0 (oral-vore by default)")
	endEvent
endState

state Chance_Locus1
	Event OnSliderOpenST()
		SetSliderDialogStartValue(LocusChances[1])
		SetSliderDialogDefaultValue(0.1)
		SetSliderDialogRange(0.0, 100.0)
		SetSliderDialogInterval(0.02)
	endEvent

	event OnSliderAcceptST(float a_value)
		LocusChances[1] = a_value
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		LocusChances[1] = 0.1
		SetSliderOptionValueST(0.1, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("Probability that NPCs will ingest to locus 1 (anal-vore by default)")
	endEvent
endState

state Chance_Locus2
	Event OnSliderOpenST()
		SetSliderDialogStartValue(LocusChances[2])
		SetSliderDialogDefaultValue(0.1)
		SetSliderDialogRange(0.0, 100.0)
		SetSliderDialogInterval(0.02)
	endEvent

	event OnSliderAcceptST(float a_value)
		LocusChances[2] = a_value
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		LocusChances[2] = 0.1
		SetSliderOptionValueST(0.1, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("Probability that NPCs will ingest to locus 2 (unbirth by default)")
	endEvent
endState

state Chance_Locus3
	Event OnSliderOpenST()
		SetSliderDialogStartValue(LocusChances[3])
		SetSliderDialogDefaultValue(0.1)
		SetSliderDialogRange(0.0, 100.0)
		SetSliderDialogInterval(0.02)
	endEvent

	event OnSliderAcceptST(float a_value)
		LocusChances[3] = a_value
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		LocusChances[3] = 0.1
		SetSliderOptionValueST(0.1, "{2}")
	endEvent

	event OnHighlightST()
		if Morphs.UseDualBreastMode
			SetInfoText("Probability that NPCs will ingest to locus 3 (left breast-vore by default)")
		else
			SetInfoText("Probability that NPCs will ingest to locus 3 (breast-vore by default)")
		endIf
	endEvent
endState

state Chance_Locus4
	Event OnSliderOpenST()
		SetSliderDialogStartValue(LocusChances[4])
		SetSliderDialogDefaultValue(0.1)
		SetSliderDialogRange(0.0, 100.0)
		SetSliderDialogInterval(0.02)
	endEvent

	event OnSliderAcceptST(float a_value)
		LocusChances[4] = a_value
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		LocusChances[4] = 0.1
		SetSliderOptionValueST(0.1, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("Probability that NPCs will ingest to locus 4 (right breast-vore by default)")
	endEvent
endState

state Chance_Locus5
	Event OnSliderOpenST()
		SetSliderDialogStartValue(LocusChances[5])
		SetSliderDialogDefaultValue(0.1)
		SetSliderDialogRange(0.0, 100.0)
		SetSliderDialogInterval(0.02)
	endEvent

	event OnSliderAcceptST(float a_value)
		LocusChances[5] = a_value
		SetSliderOptionValueST(a_value, "{2}")
	endEvent

	event OnDefaultST()
		LocusChances[5] = 0.1
		SetSliderOptionValueST(0.1, "{2}")
	endEvent

	event OnHighlightST()
		SetInfoText("Probability that NPCs will ingest to locus 5 (cock-vore by default)")
	endEvent
endState

state BumpAmplitudeState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Morphs.struggleAmplitude)
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(0.05, 5.0)
		SetSliderDialogInterval(0.05)
	endEvent

	event OnSliderAcceptST(float a_value)
		Morphs.struggleAmplitude = a_value
		SetSliderOptionValueST(Morphs.struggleAmplitude, "{2}x")
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.struggleAmplitude = 1.0
		SetSliderOptionValueST(Morphs.struggleAmplitude, "{2}x")
		resetBellies = true
	endEvent

	event OnHighlightST()
		SetInfoText("Scaling factor for the struggle bump sliders.")
	endEvent
endState

state EliminationLocusState
	event OnDefaultST()
		Morphs.UseEliminationLocus = true
		resetBellies = true
		setToggleOptionValueST(Morphs.UseEliminationLocus)
	endEvent
	event OnSelectST()
		Morphs.UseEliminationLocus = !Morphs.UseEliminationLocus
		resetBellies = true
		setToggleOptionValueST(Morphs.UseEliminationLocus)
	endEvent
	event OnHighlightST()
		SetInfoText("As digestion proceeds and the stomach shrinks, the butt will be inflated proportionally.")
	endEvent
endstate

state struggleSlidersState
	event OnDefaultST()
		Morphs.useStruggleSliders = false
		resetBellies = true
		ForcePageReset()
		setToggleOptionValueST(Morphs.useStruggleSliders)
	endEvent
	event OnSelectST()
		Morphs.useStruggleSliders = !Morphs.useStruggleSliders
		resetBellies = true
		ForcePageReset()
		setToggleOptionValueST(Morphs.useStruggleSliders)
	endEvent
	event OnHighlightST()
		SetInfoText("Use the struggle sliders built into some MorphVore bodies and some equippable bellies. More Script-intensive but better looking and probably more stable.\nThe Gat, Vegan, and KongPow bellies don't support this but they have built-in struggle animations. The SkepticMech and Gaz Bellies support them, as well as the Gaz MorphVore body.")
	endEvent
endstate

state MorphSpeedState
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Morphs.MorphSpeed)
		SetSliderDialogDefaultValue(0.08)
		SetSliderDialogRange(0.01, 0.5)
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(float a_value)
		Morphs.MorphSpeed = a_value
		resetBellies = true
		SetSliderOptionValueST(Morphs.MorphSpeed, "{2}x")
	endEvent

	event OnDefaultST()
		Morphs.MorphSpeed = 1.0
		resetBellies = true
		SetSliderOptionValueST(Morphs.MorphSpeed, "{2}x")
	endEvent

	event OnHighlightST()
		SetInfoText("Scaling rate for belly size and struggle bumps. Setting this too low will impact performance, but setting it too high will increase the choppiness of size changes.")
	endEvent
endState

state equipBellyState
	event OnMenuOpenST()
		SetMenuDialogStartIndex(Morphs.EquippableBellyType)
		SetMenuDialogDefaultIndex(1)
		SetMenuDialogOptions(EquipList)
	endEvent

	event OnMenuAcceptST(int index)
		Morphs.EquippableBellyType = index
		SetMenuOptionValueST(EquipList[index])
		resetBellies = true
	endEvent

	event OnDefaultST()
		Morphs.EquippableBellyType = 1
		SetMenuOptionValueST(EquipList[Morphs.EquippableBellyType])
		resetBellies = true
	endEvent

	event OnHighlightST()
		if Morphs.EquippableBellyType == 1
			SetInfoText("Equip the Macross morphvore belly with struggle sliders.\nCopies the body skin texture and generally looks excellent with any CBBE or 3BA body.")
		elseif Morphs.EquippableBellyType == 2
			SetInfoText("Equip the SkepticMech morphvore belly with struggle sliders.\nUses Xomod texturing and is relatively compatible with CBBE, 3BA, UNP, UUNP, and BHUNP.")
		else
			SetInfoText("Don't use any equipable belly.")
		endIf
	endEvent
endstate

state UseLocusMorphsState
	event OnDefaultST()
		Morphs.UseLocationalMorphs = false
		resetBellies = true
		ForcePageReset()
	endEvent
	event OnSelectST()
		Morphs.UseLocationalMorphs = !Morphs.UseLocationalMorphs
		resetBellies = true
		ForcePageReset()
	endEvent
	event OnHighlightST()
		SetInfoText("Use locational morphs (breasts, stomach, etc). The results are heavily dependent on the body you use and can be unpredictable. ")
	endEvent
endstate

Function AddLogVersion(String label, String log, String linePattern, String subPattern)
	int data = JLua.setStr("log", log, JLua.SetStr("p1", linePattern, JLua.SetStr("p2", subPattern)))
	String result = JLua.evalLuaStr("return args.log:match(args.p1):match(args.p2)", data)
	
	if result != "" 
		addTextOption(label, result)
	else
		addTextOption(label, "MISSING")
	endIf
EndFunction

Function AddLogCheck(String label, String log, String linePattern)
	int data = JLua.setStr("log", log, JLua.SetStr("p1", linePattern))
	String result = JLua.evalLuaStr("return args.log:match(args.p1)", data)
	
	if result != "" 
		addTextOption(label, "Found")
	else
		addTextOption(label, "MISSING")
	endIf
EndFunction

Function AddQuestDetails(String label, String name, String v1)
	if Quest.getQuest(name)
		addTextOption(label, v1)
	else
		addTextOption(label, "MISSING")
	endIf
EndFunction

Function AddSKSEDetails(String label, String pluginLE, String pluginSE, String v1 = "", String v2 = "")
	int skseVersion = 0
	
	if SKSE.GetPluginVersion(pluginSE) >= 0
		skseVersion = SKSE.GetPluginVersion(pluginSE)
	elseif SKSE.GetPluginVersion(pluginLE) >= 0
		skseVersion = SKSE.GetPluginVersion(pluginLE)
	else
		addTextOption(label, "MISSING")
		return
	endIf
	
	if v1 != "" && v2 != ""
		addTextOption(label, skseVersion + " (" + v1 + ", " + v2 + ")")
	elseif v1 != ""
		addTextOption(label, skseVersion + " (" + v1 + ")")
	else
		addTextOption(label, skseVersion)
	endIf
EndFunction

Function DisplayQuickSettings()
	UIListMenu menu = UIExtensions.GetMenu("UIListMenu") as UIListMenu
	Actor subject = PlayerRef
	Actor target2 = Game.GetCurrentConsoleRef() as Actor
	Actor target3 = Game.GetCurrentCrosshairRef() as Actor

	String playerName = Namer(playerRef, true)
	String target2Name = Namer(target2, true)
	String target3Name = Namer(target3, true)
	
	menu.ResetMenu()

	int ENTRY_SUBJECT
	int ENTRY_T1 = -1
	int ENTRY_T2 = -1
	int ENTRY_T3 = -1

	if (target2 && target2 != playerRef) || (target3 && target3 != playerRef)
		ENTRY_SUBJECT = menu.AddEntryItem("Subject: " + playerName, entryHasChildren = true)
		ENTRY_T1 = menu.AddEntryItem(playerName, ENTRY_SUBJECT)
		
		if target2 && target2 != playerRef
			ENTRY_T2 = menu.AddEntryItem(target2Name, ENTRY_SUBJECT)
		endIf

		if target3 && target3 != playerRef && target3 != target2
			ENTRY_T3 = menu.AddEntryItem(target3Name, ENTRY_SUBJECT)
		endIf
	else
		ENTRY_SUBJECT = menu.AddEntryItem("Subject: " + playerName)
	endIf

	int ENTRY_BELLY1 = menu.AddEntryItem("View " + playerName + "'s contents", entryHasChildren = true)
	AddPredContents(menu, ENTRY_BELLY1, playerRef)

	if target2 != None && target2 != PlayerRef
		int ENTRY_BELLY2 = menu.AddEntryItem("View " + target2Name + "'s contents", entryHasChildren = true)
		AddPredContents(menu, ENTRY_BELLY2, target2)
	endIf

	if target3 != None && target3 != PlayerRef && target3 != target2
		int ENTRY_BELLY3 = menu.AddEntryItem("View " + target3Name + "'s contents", entryHasChildren = true)
		AddPredContents(menu, ENTRY_BELLY3, target3)
	endIf

	int ENTRY_LOCUS = menu.AddEntryItem("Default Locus: " + GetLocusName(PlayerAlias.DefaultLocus), entryHasChildren = true)
	int ENTRY_LOCI_RANDOM = menu.AddEntryItem(GetLocusName(-1), ENTRY_LOCUS)

	int[] ENTRY_LOCI = Utility.CreateIntArray(6)
	int locusIndex = 0
	while locusIndex < ENTRY_LOCI.length
		ENTRY_LOCI[locusIndex] = menu.AddEntryItem(GetLocusName(locusIndex), ENTRY_LOCUS)
		locusIndex += 1
	endWhile

	int ENTRY_PERKS = menu.AddEntryItem("Perks (" + Manager.GetPerkPoints(subject) + " perk points)", entryHasChildren = true)
	int ENTRY_PERK_PRED = menu.AddEntryItem("Pred Perks", ENTRY_PERKS)
	int ENTRY_PERK_PREY = menu.AddEntryItem("Prey Perks", ENTRY_PERKS)

	int ENTRY_TOGGLES = menu.AddEntryItem("Toggles")
	int ENTRY_LOOSE = menu.AddEntryItem(ToggleString("Loose item vore", LooseItemVore), ENTRY_TOGGLES)
	int ENTRY_REBIRTH = menu.AddEntryItem(ToggleString("Automatic rebirth", AutoRebirth), ENTRY_TOGGLES)
	int ENTRY_CROUCH = menu.AddEntryItem(ToggleString("Crouch Scat", Manager.CrouchScat), ENTRY_TOGGLES)
	int ENTRY_ESCAPE = menu.AddEntryItem(ToggleString("Anal Escape", Manager.AnalEscape), ENTRY_TOGGLES)
	int ENTRY_GENTLE = menu.AddEntryItem(ToggleString("Gentle Gas", GentleGas), ENTRY_TOGGLES)
	
	int ENTRY_TOINV = -100
	if PlayerRef.HasPerk(DigestItems_arr[2])
		ENTRY_TOINV = menu.AddEntryItem(ToggleString("Digest to Inventory", DigestToInventory), ENTRY_TOGGLES)
	endIf

	int ENTRY_HUNGRYBONES = -100
	if PlayerRef.HasPerk(RaiseDead)
		ENTRY_HUNGRYBONES = menu.AddEntryItem(ToggleString("Hungry Bones", EnableHungryBones), ENTRY_TOGGLES)
	endIf
	
	int ENTRY_CORDYCEPS = -100
	if PlayerRef.HasPerk(Cordyceps)
		ENTRY_CORDYCEPS = menu.AddEntryItem(ToggleString("Cordyceps", EnableCordyceps), ENTRY_TOGGLES)
	endIf
	
	int ENTRY_SLACCIDENTS = -100
	if DevourmentSexlab.instance().SLA != none
		ENTRY_SLACCIDENTS = menu.AddEntryItem(ToggleString("SLAccidents", SLAccidents), ENTRY_TOGGLES)
	endIf

	int ENTRY_COUNTER = -100
	if PlayerRef.HasPerk(CounterVore)
		ENTRY_COUNTER = menu.AddEntryItem(ToggleString("Counter-Vore", CounterVoreEnabled), ENTRY_TOGGLES)
	endIf

	int ENTRY_TEST1 = -100
	int ENTRY_TEST2 = -100
	if Manager.DEBUGGING
		ENTRY_TEST1 = menu.AddEntryItem("Overlay Test")
		ENTRY_TEST2 = menu.AddEntryItem("Name Test")
	endIf

	int ENTRY_FORTIS = -100
	if subject.HasPerk(DigestItems_arr[2])
		ENTRY_FORTIS = menu.AddEntryItem("Digest Items")
	endIf

	int ENTRY_VOMIT = menu.AddEntryItem("Regurgitate")
	int ENTRY_POOP = menu.AddEntryItem("Defecate")
	int ENTRY_INVENTORY_EAT = menu.AddEntryItem("Inventory Vore")

	int ENTRY_SLEEP = -100
	if Manager.IsPrey(playerRef) && playerRef.HasPerk(Comfy) && Manager.RelativelySafe(playerRef)
		ENTRY_SLEEP = menu.AddEntryItem("Vore Sleep")
	endIf
	
	int ENTRY_EXIT = menu.AddEntryItem("Exit")
	
	bool exit = false
	while !exit
		menu.OpenMenu()
		int result = menu.GetResultInt()
		
		if result == ENTRY_EXIT || result < 0
			exit = true
	
		elseif result == ENTRY_T1
			subject = PlayerRef
			menu.SetPropertyIndexString("entryName", ENTRY_SUBJECT, "Subject: " + playerName)

		elseif result == ENTRY_T2
			subject = target2
			menu.SetPropertyIndexString("entryName", ENTRY_SUBJECT, "Subject: " + target2Name)

		elseif result == ENTRY_T3
			subject = target3
			menu.SetPropertyIndexString("entryName", ENTRY_SUBJECT, "Subject: " + target3Name)
		
		elseif result == ENTRY_LOCI_RANDOM
			PlayerAlias.DefaultLocus = -1
			menu.SetPropertyIndexString("entryName", ENTRY_LOCUS, "Default Locus: " + GetLocusName(PlayerAlias.DefaultLocus))

		elseif ENTRY_LOCI.find(result) >= 0
			PlayerAlias.DefaultLocus = ENTRY_LOCI.find(result)
			menu.SetPropertyIndexString("entryName", ENTRY_LOCUS, "Default Locus: " + GetLocusName(PlayerAlias.DefaultLocus))

		elseif result == ENTRY_LOOSE
			LooseItemVore = !LooseItemVore
			menu.SetPropertyIndexString("entryName", ENTRY_LOOSE, ToggleString("Loose item vore", LooseItemVore))
	
		elseif result == ENTRY_REBIRTH
			AutoRebirth = !AutoRebirth
			menu.SetPropertyIndexString("entryName", ENTRY_REBIRTH, ToggleString("Automatic rebirth", AutoRebirth))

		elseif result == ENTRY_CROUCH
			Manager.CrouchScat = !Manager.CrouchScat
			menu.SetPropertyIndexString("entryName", ENTRY_CROUCH, ToggleString("Crouch Scat", Manager.CrouchScat))

		elseif result == ENTRY_ESCAPE
			Manager.AnalEscape = !Manager.AnalEscape
			menu.SetPropertyIndexString("entryName", ENTRY_ESCAPE, ToggleString("Anal Escape", Manager.AnalEscape))

		elseif result == ENTRY_GENTLE
			GentleGas = !GentleGas
			menu.SetPropertyIndexString("entryName", ENTRY_GENTLE, ToggleString("Gentle Gas", GentleGas))

		elseif result == ENTRY_TOINV
			DigestToInventory = !DigestToInventory
			menu.SetPropertyIndexString("entryName", ENTRY_TOINV, ToggleString("Digest To Inventory", DigestToInventory))

		elseif result == ENTRY_HUNGRYBONES
			EnableHungryBones = !EnableHungryBones
			menu.SetPropertyIndexString("entryName", ENTRY_HUNGRYBONES, ToggleString("Hungry Bones", EnableHungryBones))

		elseif result == ENTRY_SLACCIDENTS
			SLAccidents = !SLAccidents
			menu.SetPropertyIndexString("entryName", ENTRY_SLACCIDENTS, ToggleString("SLAccidents", SLAccidents))

		elseif result == ENTRY_COUNTER
			CounterVoreEnabled = !CounterVoreEnabled
			menu.SetPropertyIndexString("entryName", ENTRY_COUNTER, ToggleString("Counter-Vore", CounterVoreEnabled))

		elseif result == ENTRY_CORDYCEPS
			EnableCordyceps = !EnableCordyceps
			menu.SetPropertyIndexString("entryName", ENTRY_CORDYCEPS, ToggleString("Cordyceps", EnableCordyceps))

		elseif result == ENTRY_PERK_PRED
			if AltPerkMenus || subject != playerRef
				ShowPerkSubMenu(true, subject)
			else
				Manager.Devourment_ShowPredPerks.SetValue(1.0)
			endIf
			exit = true

		elseif result == ENTRY_PERK_PREY
			if AltPerkMenus || subject != playerRef
				ShowPerkSubMenu(false, subject)
			else
				Manager.Devourment_ShowPreyPerks.SetValue(1.0)
			endIf
			exit = true

		elseif result == ENTRY_VOMIT
			if LibFire.ActorIsFollower(subject)
				Power_Regurgitate.cast(subject, subject)
			else
				Power_Regurgitate.cast(PlayerRef, PlayerRef)
			endIf
			exit = true

		elseif result == ENTRY_FORTIS
			if LibFire.ActorIsFollower(subject)
				Power_DigestItems.cast(subject, subject)
			else
				Power_DigestItems.cast(PlayerRef, PlayerRef)
			endIf
			exit = true

		elseif result == ENTRY_POOP
			if LibFire.ActorIsFollower(subject)
				Power_Defecate.cast(subject, subject)
			else
				Power_Defecate.cast(PlayerRef, PlayerRef)
			endIf
			exit = true

		elseif result == ENTRY_INVENTORY_EAT
			Actor fakePlayer = Manager.FakePlayer
			fakePlayer.MoveTo(PlayerRef)
			fakePlayer.SetAlpha(0.0, false)
			Power_EatThis.cast(playerRef, fakePlayer)
			exit = true

		elseif result == ENTRY_SLEEP
			PlayerAlias.VoreSleep()
			exit = true

		elseif result == ENTRY_TEST1 
			PlayerAlias.ClearFaceOverlays(PlayerRef)
			exit = true

		elseif result == ENTRY_TEST2
			String name1 = subject.GetLeveledActorBase().GetName()
			String name2 = subject.GetActorBase().GetName()
			String name3 = subject.GetDisplayName()
			Debug.MessageBox("Levelled = '" + name1 + "', unlevelled = '" + name2 + "', display = '" + name3 + "'")
			exit = true

		endIf
	endWhile
EndFunction


DevourmentMCM Function instance() global
	{ Returns the DevourmentMCM instance, for situations in which a property isn't helpful (like global functions). }
	return Quest.GetQuest("DevourmentMCM") as DevourmentMCM
EndFunction
	