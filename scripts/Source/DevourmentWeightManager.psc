ScriptName DevourmentWeightManager Extends Quest
{
AUTHOR: Gaz
PURPOSE: WeightMorphs-esque Slider Manager for both Player and NPCs.
CREDIT: WeightMorphs and Ousnius, for providing the basis for this idea and implementation.
}
import Logging


Actor Property PlayerRef Auto
DevourmentManager Property Manager auto
String[] Property MorphStrings auto
{ This Array as well as the other Morph and Root arrays is divided up between Female, Male and Creature. }
Float[] Property MorphsHigh auto
Float[] Property MorphsLow auto
float[] property RootLow auto
float[] property RootHigh auto
Form[] Property HighValueFood Auto
Form[] Property NoValueFood Auto
Keyword Property ActorTypeCreature Auto

Bool Property PlayerEnabled = false Auto Hidden
Bool Property CompanionsEnabled = false Auto Hidden
Bool Property ActorsEnabled = false Auto Hidden
Bool Property FemalesEnabled = false Auto Hidden
Bool Property MalesEnabled = false Auto Hidden
Bool Property CreaturesEnabled = false Auto Hidden
Bool Property LinearChanges = false Auto Hidden
Bool Property SkeletonScaling = false Auto Hidden
Float Property WeightLoss = 0.05 auto Hidden
Float Property WeightRate = 4.0 auto Hidden
Float Property MaximumWeight = 2.0 Auto Hidden
Float Property MinimumWeight = -1.0 Auto Hidden
Float Property VoreBaseGain = 0.05 Auto Hidden
Float Property IngredientBaseGain = 0.04 Auto Hidden
Float Property PotionBaseGain = 0.02 Auto Hidden
Float Property FoodBaseGain = 0.10 Auto Hidden
Float Property HighValueMultiplier = 2.0 Auto Hidden

String property rootNode = "NPC Root [Root]" autoReadOnly

String PREFIX = "DevourmentWeightManager"

Event OnInit()
	SyncSettings()
EndEvent

Event OnPlayerLoadGame()
	SyncSettings()
EndEvent

Function SyncSettings(bool resetActorWeights = false)
{ Intended to be called whenever MCM settings change. Optionally, resets weights. }
	If PlayerEnabled || CompanionsEnabled || ActorsEnabled
        EventRegistration(True)
    EndIf
	If resetActorWeights
		ResetActorWeights()
	EndIf
EndFunction

Function EventRegistration(Bool Register)
    If Register
		ConsoleUtil.PrintMessage("WeightManagement started.")
        RegisterForModEvent("Devourment_OnDeadDigestion", "DeadDigest")
        RegisterForModEvent("Devourment_onDeadReforming", "DeadReform")
        RegisterForModEvent("Devourment_onConsumeItem", "ItemConsume")

		if PlayerEnabled
			RegisterForSingleUpdateGameTime(WeightRate)
			RegisterForSleep()
			RegisterForModEvent("HookAnimationEnd", "SexlabAnimationEnd")
		endIf
    Else 
        UnRegisterForModEvent("Devourment_OnDeadDigestion")
        UnRegisterForModEvent("Devourment_onDeadReforming")
        UnRegisterForModEvent("Devourment_onConsumeItem")
		UnregisterForUpdate()
		UnregisterForUpdateGameTime()
		UnregisterForSleep()
    EndIf
EndFunction

Event OnUpdate()
	if PlayerEnabled
		ChangeActorWeight(PlayerRef, -WeightLoss)
	endIf

	if CompanionsEnabled && !ActorsEnabled
		Actor[] nearby = LibFire.FindNearbyFollowers(2048.0)
		int index = nearby.length
		while index
			index -= 1
			ChangeActorWeight(nearby[index], -WeightLoss)
		endWhile
	elseif ActorsEnabled
		Actor[] nearby = LibFire.FindNearbyActors(PlayerRef, 2048.0)
		int index = nearby.length
		while index
			index -= 1
			if nearby[index].HasKeywordString("ActorTypeNPC")
				ChangeActorWeight(nearby[index], -WeightLoss)
			endIf
		endWhile
	endIf

	If PlayerEnabled || CompanionsEnabled || ActorsEnabled
		RegisterForSingleUpdate(WeightRate * 3600.0)
	endIf
EndEvent 

Event OnUpdateGameTime()
	if PlayerEnabled
		ChangeActorWeight(PlayerRef, -WeightLoss)
	endIf

	if CompanionsEnabled || ActorsEnabled
		Actor[] nearby

		if CompanionsEnabled && !ActorsEnabled
			nearby = LibFire.FindNearbyFollowers(4096.0)
		else
			nearby = LibFire.FindNearbyActors(PlayerRef, 4096.0)
		endIf

		int index = nearby.length
		while index
			index -= 1
			Actor who = nearby[index]
			if !who.IsDead() && who.IsEnabled() && who.HasKeywordString("ActorTypeNPC")
				ChangeActorWeight(who, -WeightLoss)
			endIf
		endWhile
	endif

	If PlayerEnabled || CompanionsEnabled || ActorsEnabled
		RegisterForSingleUpdateGameTime(WeightRate)
	endIf
EndEvent 

Event OnSleepStart(float afSleepStartTime, float afDesiredSleepEndTime)
	ChangeActorWeight(PlayerRef, -afDesiredSleepEndTime / (WeightRate * 24.0))
EndEvent

Event SexlabAnimationEnd(int tid, bool HasPlayer)
	if HasPlayer
		ChangeActorWeight(PlayerRef, -WeightLoss)
	endIf
EndEvent

Event DeadDigest(Form f1, Form f2, float remaining)
	; This prevents gaining weight from prey that are reformed or fully digested.
	if remaining >= 100.0 || remaining <= 0.0
		return
	endIf

    Actor pred = f1 as Actor
    Actor prey = f2 as Actor
    
	If pred && prey && !isValidConsumer(pred)
        return
    endIf

    ;This will fire every tick of digestion so set it low and gradual.
    ;It would be much less computationally heavy to just wait until Digestion is over
    ;and *then* do this, but people want fidelity, to see the WG in action as they digest things.
	float currentWeight = ChangeActorWeight(pred, VoreBaseGain / Manager.DigestionTime)
EndEvent

Event DeadReform(Form f1, Form f2, float remaining)
	; This prevents gaining weight from prey that are reformed or fully digested.
	if remaining >= 100.0 || remaining <= 0.0
		return
	endIf

    Actor pred = f1 as Actor
    Actor prey = f2 as Actor
    
	If pred && prey && !isValidConsumer(pred)
        return
    endIf

	float currentWeight = ChangeActorWeight(pred, -VoreBaseGain / Manager.DigestionTime)
EndEvent

Event ItemConsume(Form consumer, Form itemBase, int count)
{ Event that fires when Devourment Actors consume something via Object Vore / Feeding. Also called for Player Equip events. }

    ; Putting this here is a bit ugly but might be worth it in the future.
    If NoValueFood.Find(itemBase) >= 0
		ConsoleUtil.PrintMessage(Namer(itemBase) + " has no food value.")
        Return
    endIf
    
    Actor pred = consumer as Actor
	If !isValidConsumer(pred)
		Log1(PREFIX, "ItemConsume", "INVALID CONSUMER")
        return
    endIf

	float baseWeight = itemBase.GetWeight()

    If FoodBaseGain > 0.0 && itemBase.HasKeywordString("VendorItemFood")
        If HighValueFood.Find(itemBase) >= 0
			ConsoleUtil.PrintMessage(Namer(itemBase) + ": high value food.")
            ChangeActorWeight(pred, FoodBaseGain * baseWeight * HighValueMultiplier)
        else
			ConsoleUtil.PrintMessage(Namer(itemBase) + ": regular food.")
            ChangeActorWeight(pred, FoodBaseGain * baseWeight)
        EndIf
		Manager.RegisterFakeDigestion(pred, baseWeight * count * 2.0)

    ElseIf PotionBaseGain > 0.0 && itemBase.HasKeywordString("VendorItemPotion")
        ChangeActorWeight(pred, PotionBaseGain)
		Manager.RegisterFakeDigestion(pred, baseWeight * count)
        
    ElseIf IngredientBaseGain > 0.0 && itemBase as Ingredient
        ChangeActorWeight(pred, IngredientBaseGain * baseWeight)
		Manager.RegisterFakeDigestion(pred, baseWeight * count)
    EndIf
EndEvent

Event OnObjectEquipped(Form type, ObjectReference ref)
	if PlayerEnabled
		if type as Potion || type as Ingredient
			ItemConsume(PlayerRef, type, 1)
		endIf
	endIf
EndEvent

auto state DefaultState
endState

Function LearnValue(int Type)
	if Type == 0
		GoToState("LearnHighValue")
	else
		GoToState("LearnNoValue")
	endif
EndFunction

state LearnNoValue
	Event OnObjectEquipped(Form type, ObjectReference ref)
		if type as Potion || type as Ingredient
			addNoValueFood(type)
		endIf
	EndEvent
endState

state LearnHighValue
	Event OnObjectEquipped(Form type, ObjectReference ref)
		if type as Potion || type as Ingredient
			addHighValueFood(type)
		endIf
	EndEvent
endState

Function ResetActorWeight(Actor target)
	Log1(PREFIX, "ResetActorWeight", Namer(target))
	if target
		bool isFemale = Manager.IsFemale(target)
		NIOverride.RemoveNodeTransformScale(target, false, isFemale, rootNode, PREFIX)
		NIOverride.UpdateNodeTransform(target, false, isFemale, rootNode)

		if NiOverride.HasBodyMorphKey(target, PREFIX)
			StorageUtil.UnSetFloatValue(target, "DevourmentActorWeight")
			NiOverride.ClearBodyMorphKeys(target, PREFIX)
			NiOverride.ClearBodyMorphKeys(target, PREFIX)
		endIf
	endIf
EndFunction

Function ResetActorWeights()
	NiOverride.ForEachMorphedReference("ResetActorWeight", Manager)
EndFunction

float Function GetCurrentActorWeight(Actor target)
	return StorageUtil.GetFloatValue(target, "DevourmentActorWeight", 0.0)
EndFunction

float Function ChangeActorWeight(Actor target, float afChange, float afPreview = 0.0)
	{ All-purpose function for losing and gaining Weight. }

	;Initialise required function variables.
	float fOldWeight = StorageUtil.GetFloatValue(target, "DevourmentActorWeight", 0.0)
	int morphsEnd = 32
	int iSlider = 0
	Int iRoot = 0
	Float fTargetWeight = fOldWeight
	bool isFemale = Manager.IsFemale(target)
	;Log3(PREFIX, "ChangeActorWeight", Namer(target), CurrentWeight, afChange)

	If !target.HasKeyword(ActorTypeCreature)
		If isFemale
			If !FemalesEnabled
				Return fOldWeight
			EndIf
		Else
			If !MalesEnabled
				Return fOldWeight
			EndIf
			iRoot = 1
			iSlider = 32
			morphsEnd = 64
		EndIf
	Else
		If !CreaturesEnabled
			Return fOldWeight
		EndIf
		iRoot = 2
		iSlider = 64
		morphsEnd = 96
	EndIf

	if afChange != 0.0	;REGULAR FUNCTIONALITY
		If LinearChanges	; There's gotta be a nicer way to write this but fuck if I know.
			Float fRatio = fOldWeight / MaximumWeight	;May be insufficient in case of people with weird setups.
			If fRatio < 0.0
				fRatio += 1.0
				If fRatio > 0.7
					fRatio = 0.7
				EndIf
				afChange *= fRatio
			Else
				fRatio -= 1.0
				If fRatio > -0.3
					fRatio = -0.3
				EndIf
				afChange *= -fRatio
			EndIf
		EndIf
		fTargetWeight += afChange
		if fTargetWeight < MinimumWeight	; Clamp values.
			fTargetWeight = MinimumWeight
		elseif fTargetWeight > MaximumWeight
			fTargetWeight = MaximumWeight
		endIf
		StorageUtil.SetFloatValue(target, "DevourmentActorWeight", fTargetWeight) ; Save our Weight on the actor.
		ConsoleUtil.PrintMessage(Namer(target, true) + "'s weight to changed by " + afChange + " to " + fTargetWeight + ". Close console to see changes.")
	elseif afPreview != 0.0	; PREVIEWING
		ConsoleUtil.PrintMessage("Previewing " + Namer(target, true) + " at weight " + afPreview + " when console closes.")
		fTargetWeight = afPreview
	endIf

	Utility.Wait(0.001) ; A hacky fix but should prevent us from changing bodies while menus or console is up.

	if SkeletonScaling && RootLow[iRoot] != RootHigh[iRoot]
		if fTargetWeight < 0.0
			NIOverride.AddNodeTransformScale(target, false, isFemale, rootNode, PREFIX, 1.0 - fTargetWeight * RootLow[iRoot])
		else
			NIOverride.AddNodeTransformScale(target, false, isFemale, rootNode, PREFIX, 1.0 + fTargetWeight * RootHigh[iRoot])
		endIf
		NIOverride.UpdateNodeTransform(target, false, isFemale, rootNode)
	endIf

	if fTargetWeight < 0.0	; Targets need to be inverted for the sliders to end up at correct values if target is below 0.0 weight.
		While iSlider < morphsEnd ;&& MorphStrings[iSlider] != ""	;I'm curious if MorphStrings[iSlider] != "" could cause edge-case bugs if user deletes old morphs behind new morphs.
			NiOverride.SetBodyMorph(target, MorphStrings[iSlider], PREFIX, -fTargetWeight * MorphsLow[iSlider])
			iSlider += 1
		EndWhile
	else
		While iSlider < morphsEnd ;&& MorphStrings[iSlider] != ""
			NiOverride.SetBodyMorph(target, MorphStrings[iSlider], PREFIX, fTargetWeight * MorphsHigh[iSlider])
			iSlider += 1
		EndWhile
	endIf
	NiOverride.UpdateModelWeight(target) ; Update the model.

	return fTargetWeight
EndFunction


bool Function isValidConsumer(Actor consumer)
	if consumer == PlayerRef
		return PlayerEnabled
	elseif LibFire.ActorIsFollower(consumer)
		return CompanionsEnabled
	elseif consumer.GetActorBase().IsUnique()
	;Some actors like Town Guards are recycled so we have to ensure NPCs are unique or morphs may carry over.
		return ActorsEnabled
	Else
		Return False
	endIf
EndFunction


bool Function addHighValueFood(Form food)
	Log1(PREFIX, "addHighValueFood", Namer(food))
	DevourmentUtil.ArrayAddFormEx(HighValueFood, food)
	SyncSettings()
	GotoState("DefaultState")
	ConsoleUtil.PrintMessage("Added High-Value food: " + Namer(food))
	LogForms(PREFIX, "addHighValueFood", "HighValueFood", HighValueFood)
	return true
endFunction


bool Function addNoValueFood(Form food)
	Log1(PREFIX, "addNoValueFood", Namer(food))
	DevourmentUtil.ArrayAddFormEx(NoValueFood, food)
	SyncSettings()
	GotoState("DefaultState")
	ConsoleUtil.PrintMessage("Added No-Value food: " + Namer(food))
	LogForms(PREFIX, "addNoValueFood", "NoValueFood", HighValueFood)
	return true
endFunction


bool Function addMorph(String name, float multHigh, float multLow, int iType)
	
	Int iMorphStart = 0
	Int iMorphEnd = 32
	
	;We divide our Morph arrays up by Female, Male and Creature. 
	;These iTypes correspond to these "segments", 0 female, 1 male, 2 creature.
	If iType == 1
		iMorphStart = 32
		iMorphEnd = 64
	ElseIf iType == 2
		iMorphStart = 64
		iMorphEnd = 96
	EndIf

	if MorphStrings.find(name, iMorphStart) < iMorphEnd \
	&& MorphStrings.find(name, iMorphStart) >= iMorphStart
		;This slider string is already in our segment, reject it.
        return false
    endIf

    int index = MorphStrings.find("", iMorphStart)
	If index < iMorphStart || index >= iMorphEnd
		;There are no free elements available in this segment.
		return false
	EndIf

    MorphStrings[index] = name
    MorphsHigh[index] = multHigh
    MorphsLow[index] = multLow

	SyncSettings(true)
	return true
EndFunction


bool Function removeMorph(int iSliderIndex)
    MorphStrings[iSliderIndex] = ""
	SyncSettings(true)
    return true
EndFunction


int Function GetWeightApprox(Actor target)
	float diff = MaximumWeight - MinimumWeight
	float baseWeight = StorageUtil.GetFloatValue(target, "DevourmentActorWeight", 0.0)
	float weight = 100.0 + (baseWeight - MinimumWeight) * 150.0 / diff
	return weight as int
EndFunction


float Function GetLossPerDay()
	return 24.0 * WeightLoss / WeightRate
EndFunction


float Function GetGainPerHumanoid()
	return 2.0 * VoreBaseGain
EndFunction


float Function GetGainPer100Food()
	return 100.0 * FoodBaseGain
EndFunction


Function LoadSettingsFrom(int data)
	PlayerEnabled =			JMap.GetInt(data, "PlayerEnabled", PlayerEnabled as int) as bool
	CompanionsEnabled =		JMap.GetInt(data, "CompanionsEnabled", CompanionsEnabled as int) as bool
	ActorsEnabled =			JMap.GetInt(data, "ActorsEnabled", ActorsEnabled as int) as bool
	FemalesEnabled =		JMap.GetInt(data, "FemalesEnabled", ActorsEnabled as int) as bool
	MalesEnabled =			JMap.GetInt(data, "MalesEnabled", ActorsEnabled as int) as bool
	CreaturesEnabled =		JMap.GetInt(data, "CreaturesEnabled", ActorsEnabled as int) as bool
	LinearChanges =			JMap.GetInt(data, "LinearChanges", LinearChanges as int) as bool
	WeightLoss =			JMap.GetFlt(data, "WeightLoss", WeightLoss)
	WeightRate =			JMap.GetFlt(data, "WeightRate", WeightRate)
	MaximumWeight =			JMap.GetFlt(data, "MaximumWeight", MaximumWeight)
	MinimumWeight =			JMap.GetFlt(data, "MinimumWeight", MinimumWeight)
	VoreBaseGain =			JMap.GetFlt(data, "VoreBaseGain", VoreBaseGain)
	IngredientBaseGain =	JMap.GetFlt(data, "IngredientBaseGain", IngredientBaseGain)
	PotionBaseGain =		JMap.GetFlt(data, "PotionBaseGain", PotionBaseGain)
	FoodBaseGain =			JMap.GetFlt(data, "FoodBaseGain", FoodBaseGain)
	HighValueMultiplier = 	JMap.GetFlt(data, "HighValueMultiplier", HighValueMultiplier)

	RootLow = 				JArray.asFloatArray(JMap.getObj(data, "RootLow", JArray.ObjectWithFloats(RootLow)))
	RootHigh = 				JArray.asFloatArray(JMap.getObj(data, "RootHigh", JArray.ObjectWithFloats(RootHigh)))
	MorphStrings = 			JArray.asStringArray(JMap.getObj(data, "MorphStrings", JArray.ObjectWithStrings(MorphStrings)))
	MorphsHigh = 			JArray.asFloatArray(JMap.getObj(data, "MorphsHigh", JArray.ObjectWithFloats(MorphsHigh)))
	MorphsLow = 			JArray.asFloatArray(JMap.getObj(data, "MorphsLow", JArray.ObjectWithFloats(MorphsLow)))
	HighValueFood = 		JArray.asFormArray(JMap.getObj(data, "HighValueFood", JArray.ObjectWithForms(HighValueFood)))
	NoValueFood = 			JArray.asFormArray(JMap.getObj(data, "NoValueFood", JArray.ObjectWithForms(NoValueFood)))

	if MorphStrings == none 
		MorphStrings = new String[96]
		MorphsHigh = new float[96]
		MorphsLow = new float[96]

    elseif MorphStrings.length < 96
        Utility.ResizeStringArray(MorphStrings, 96)
        Utility.ResizeFloatArray(MorphsHigh, 96)
        Utility.ResizeFloatArray(MorphsLow, 96)
    endIf
EndFunction


Function SaveSettingsTo(int data)
	JMap.SetInt(data, "PlayerEnabled", 			PlayerEnabled as int) as bool
	JMap.SetInt(data, "CompanionsEnabled", 		CompanionsEnabled as int) as bool
	JMap.SetInt(data, "ActorsEnabled", 			ActorsEnabled as int) as bool
	JMap.SetInt(data, "FemalesEnabled", 		FemalesEnabled as int) as bool
	JMap.SetInt(data, "MalesEnabled", 			MalesEnabled as int) as bool
	JMap.SetInt(data, "CreaturesEnabled", 		CreaturesEnabled as int) as bool
	JMap.SetInt(data, "LinearChanges", 			LinearChanges as int) as bool
	JMap.SetFlt(data, "WeightLoss", 			WeightLoss)
	JMap.SetFlt(data, "WeightRate", 			WeightRate)
	JMap.SetFlt(data, "MaximumWeight", 			MaximumWeight)
	JMap.SetFlt(data, "MinimumWeight", 			MinimumWeight)
	JMap.SetFlt(data, "VoreBaseGain", 			VoreBaseGain)
	JMap.SetFlt(data, "IngredientBaseGain", 	IngredientBaseGain)
	JMap.SetFlt(data, "PotionBaseGain", 		PotionBaseGain)
	JMap.SetFlt(data, "FoodBaseGain", 			FoodBaseGain)
	JMap.SetFlt(data, "HighValueMultiplier", 	HighValueMultiplier)
	JMap.SetObj(data, "RootLow", 				JArray.objectWithFloats(RootLow))
	JMap.SetObj(data, "RootHigh", 				JArray.objectWithFloats(RootHigh))
	JMap.SetObj(data, "MorphStrings", 			JArray.objectWithStrings(MorphStrings))
	JMap.SetObj(data, "MorphsHigh", 			JArray.objectWithFloats(MorphsHigh))
	JMap.SetObj(data, "MorphsLow", 				JArray.objectWithFloats(MorphsLow))
	JMap.SetObj(data, "HighValueFood", 			JArray.objectWithForms(HighValueFood))
	JMap.SetObj(data, "NoValueFood", 			JArray.objectWithForms(NoValueFood))
EndFunction


Function Upgrade(int oldVersion, int newVersion)
	Log2(PREFIX, "Upgrade", oldVersion, newVersion)
	
	if oldVersion > 0 && oldVersion != newVersion
		ResetActorWeights()
	endIf
EndFunction
	
	
DevourmentWeightManager Function instance() global
	Quest.GetQuest("DevourmentWeightManager") as DevourmentWeightManager
EndFunction
