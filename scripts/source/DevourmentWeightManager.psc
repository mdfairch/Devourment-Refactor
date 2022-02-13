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
Float[] Property MorphsHigh auto
Float[] Property MorphsLow auto
Form[] Property HighValueFood Auto
Form[] Property NoValueFood Auto
Keyword Property ActorTypeCreature Auto

Bool Property PlayerEnabled = false Auto Hidden
Bool Property CompanionsEnabled = false Auto Hidden
Bool Property ActorsEnabled = false Auto Hidden
Bool Property FemalesEnabled = false Auto Hidden
Bool Property MalesEnabled = false Auto Hidden
Bool Property CreaturesEnabled = false Auto Hidden
Bool Property SkeletonScaling = false Auto Hidden
Bool Property LinearChanges = false Auto Hidden
Float Property WeightLoss = 0.05 auto Hidden
Float Property WeightRate = 4.0 auto Hidden
Float Property MaximumWeight = 2.0 Auto Hidden
Float Property MinimumWeight = -1.0 Auto Hidden
Float Property VoreBaseGain = 0.05 Auto Hidden
Float Property IngredientBaseGain = 0.04 Auto Hidden
Float Property PotionBaseGain = 0.02 Auto Hidden
Float Property FoodBaseGain = 0.10 Auto Hidden
Float Property HighValueMultiplier = 2.0 Auto Hidden
Float Property DoPreview = 0.0 Auto hidden
Float Property fSkeletonLow = 1.0 Auto Hidden
Float Property fSkeletonHigh = 1.0 Auto Hidden
Float Property mSkeletonLow = 1.0 Auto Hidden
Float Property mSkeletonHigh = 1.0 Auto Hidden
Float Property cSkeletonLow = 1.0 Auto Hidden
Float Property cSkeletonHigh = 1.0 Auto Hidden

String property rootNode = "NPC Root [Root]" autoReadOnly

String PREFIX = "DevourmentWeightManager"


Event OnInit()
	EventRegistration()
	
	Utility.Wait(10.0)
	RunPatchups()
EndEvent


Event OnPlayerLoadGame()
	EventRegistration()
EndEvent


Function EventRegistration()
    If PlayerEnabled || CompanionsEnabled || ActorsEnabled
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
		ChangeActorWeight(PlayerRef, -WeightLoss, source="time passing")
	endIf

	if CompanionsEnabled && !ActorsEnabled
		Actor[] nearby = LibFire.FindNearbyFollowers(2048.0)
		int index = nearby.length
		while index
			index -= 1
			ChangeActorWeight(nearby[index], -WeightLoss, source="time passing")
		endWhile
	elseif ActorsEnabled
		Actor[] nearby = LibFire.FindNearbyActors(PlayerRef, 2048.0)
		int index = nearby.length
		while index
			index -= 1
			if nearby[index].HasKeywordString("ActorTypeNPC")
				ChangeActorWeight(nearby[index], -WeightLoss, source="time passing")
			endIf
		endWhile
	endIf

	If PlayerEnabled || CompanionsEnabled || ActorsEnabled
		RegisterForSingleUpdate(WeightRate * 3600.0)
	endIf
EndEvent 


Event OnUpdateGameTime()
	if PlayerEnabled
		ChangeActorWeight(PlayerRef, -WeightLoss, source="time passing")
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
				ChangeActorWeight(who, -WeightLoss, source="time passing")
			endIf
		endWhile
	endif

	If PlayerEnabled || CompanionsEnabled || ActorsEnabled
		RegisterForSingleUpdateGameTime(WeightRate)
	endIf
EndEvent 


Event OnSleepStart(float afSleepStartTime, float afDesiredSleepEndTime)
	ChangeActorWeight(PlayerRef, -(afDesiredSleepEndTime - afSleepStartTime) / (WeightRate * 24.0), source="sleep")
EndEvent


Event SexlabAnimationEnd(int tid, bool HasPlayer)
	if HasPlayer
		ChangeActorWeight(PlayerRef, -WeightLoss, source="orgasm")
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
	ChangeActorWeight(pred, VoreBaseGain / Manager.DigestionTime, source="digesting prey")
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

	float currentWeight = ChangeActorWeight(pred, -VoreBaseGain / Manager.DigestionTime, source="reforming prey")
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

	float baseWeight = itemBase.GetWeight() * count
	
    If FoodBaseGain > 0.0 && itemBase.HasKeywordString("VendorItemFood")
        If HighValueFood.Find(itemBase) >= 0
            ChangeActorWeight(pred, FoodBaseGain * baseWeight * HighValueMultiplier, source="rich food: " + Namer(itemBase, true))
        else
            ChangeActorWeight(pred, FoodBaseGain * baseWeight, source="food: " + Namer(itemBase, true))
        EndIf
		Manager.RegisterFakeDigestion(pred, baseWeight * 2.0)

    ElseIf PotionBaseGain > 0.0 && itemBase.HasKeywordString("VendorItemPotion")
        ChangeActorWeight(pred, PotionBaseGain, source="potion: " + Namer(itemBase, true))
		Manager.RegisterFakeDigestion(pred, baseWeight)
        
    ElseIf IngredientBaseGain > 0.0 && itemBase as Ingredient
        ChangeActorWeight(pred, IngredientBaseGain * baseWeight, source="ingredient: " + Namer(itemBase, true))
		Manager.RegisterFakeDigestion(pred, baseWeight)
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
			ConsoleUtil.PrintMessage("Added No-Value food: " + Namer(type))
		endIf
	EndEvent
endState


state LearnHighValue
	Event OnObjectEquipped(Form type, ObjectReference ref)
		if type as Potion || type as Ingredient
			addHighValueFood(type)
			ConsoleUtil.PrintMessage("Added High-Value food: " + Namer(type))
		endIf
	EndEvent
endState


Function ResetActorWeight(Actor target)
	if target
		bool isFemale = Manager.IsFemale(target)
		bool keepWeight = target == PlayerRef || (CompanionsEnabled && LibFire.ActorIsFollower(target))

		NIOverride.RemoveNodeTransformScale(target, false, isFemale, rootNode, PREFIX)
		NIOverride.UpdateNodeTransform(target, false, isFemale, rootNode)

		if NiOverride.HasBodyMorphKey(target, PREFIX)
			NiOverride.ClearBodyMorphKeys(target, PREFIX)
			NiOverride.ClearBodyMorphKeys(target, PREFIX)
		endIf

		if keepWeight
			ChangeActorWeight(target, 0.0, source="reset")
		else
			StorageUtil.UnSetFloatValue(target, "DevourmentActorWeight")
		endIf
	endIf
EndFunction


Function ResetActorWeights()
	Utility.Wait(0.1)
	NiOverride.ForEachMorphedReference("ResetActorWeight", Manager)
EndFunction


float Function GetCurrentActorWeight(Actor target)
	return StorageUtil.GetFloatValue(target, "DevourmentActorWeight", 0.0)
EndFunction


float Function GetCurrentActorWeightPercent(Actor target)
	if isValidConsumer(target)
		return 0.3333 + 2.0*(GetCurrentActorWeight(target) - MinimumWeight) / (MaximumWeight - MinimumWeight)
	else
		return 1.0
	endIf
EndFunction


float Function ChangeActorWeight(Actor target, float afChange, String source = "", float preview = 0.0)
	{ All-purpose function for losing and gaining Weight. }

	;Initialise required function variables.
	float fOldWeight = StorageUtil.GetFloatValue(target, "DevourmentActorWeight", 0.0)
	int endPoint = 32
	int iSlider = 0
	float fTargetWeight = fOldWeight
	float skeletonLow = 1.0
	float skeletonHigh = 1.0
	bool isFemale = Manager.IsFemale(target)
	;Log3(PREFIX, "ChangeActorWeight", Namer(target), CurrentWeight, afChange)

	If target == PlayerRef && !PlayerEnabled
		Return fOldWeight
	EndIf
	
	If !target.HasKeyword(ActorTypeCreature)
		If isFemale
			If !FemalesEnabled && target != PlayerRef
				Return fOldWeight
			EndIf
			skeletonLow = fSkeletonLow
			skeletonHigh = fSkeletonHigh
		Else
			If !MalesEnabled && target != PlayerRef
				Return fOldWeight
			EndIf
			iSlider = 32
			endPoint = 64
			skeletonLow = mSkeletonLow
			skeletonHigh = mSkeletonHigh
		EndIf
	Else
		If !CreaturesEnabled && target != PlayerRef
			Return fOldWeight
		EndIf
		iSlider = 64
		endPoint = 96
		skeletonLow = cSkeletonLow
		skeletonHigh = cSkeletonHigh
	EndIf

	if afChange != 0.0	;REGULAR FUNCTIONALITY
		If LinearChanges
			fTargetWeight += afChange * linearize(fOldWeight, MaximumWeight)
		else
			fTargetWeight += afChange
		EndIf

		if fTargetWeight < MinimumWeight	; Clamp values.
			fTargetWeight = MinimumWeight
		elseif fTargetWeight > MaximumWeight
			fTargetWeight = MaximumWeight
		endIf

		StorageUtil.SetFloatValue(target, "DevourmentActorWeight", fTargetWeight) ; Save our Weight on the actor.

		if target == PlayerRef && Manager.Notifications
			if source != ""
				ConsoleUtil.PrintMessage(Namer(target, true) + "'s weight to changed by " + afChange + " to " + fTargetWeight + " because of " + source + ".")
			else
				ConsoleUtil.PrintMessage(Namer(target, true) + "'s weight to changed by " + afChange + " to " + fTargetWeight + ".")
			endIf
		endIf

	elseif preview != 0.0	; PREVIEWING
		ConsoleUtil.PrintMessage("Previewing " + Namer(target, true) + " at weight " + preview + ".")
		fTargetWeight = preview
	endIf

	Utility.Wait(0.001) ; A hacky fix but should prevent us from changing bodies while menus or console is up.

	if SkeletonScaling
		if fTargetWeight < 0.0
			NIOverride.AddNodeTransformScale(target, false, isFemale, rootNode, PREFIX, 1.0 - fTargetWeight * skeletonLow)
			NIOverride.UpdateNodeTransform(target, false, isFemale, rootNode)
		else
			NIOverride.AddNodeTransformScale(target, false, isFemale, rootNode, PREFIX, 1.0 + fTargetWeight * skeletonHigh)
			NIOverride.UpdateNodeTransform(target, false, isFemale, rootNode)
		endIf
	endIf

	if fTargetWeight < 0.0	; Targets need to be inverted for the sliders to end up at correct values if target is below 0.0 weight.
		While iSlider < endPoint && MorphStrings[iSlider] != ""
			NiOverride.SetBodyMorph(target, MorphStrings[iSlider], PREFIX, -fTargetWeight * MorphsLow[iSlider])
			iSlider += 1
		EndWhile
	else
		While iSlider < endPoint && MorphStrings[iSlider] != ""
			NiOverride.SetBodyMorph(target, MorphStrings[iSlider], PREFIX, fTargetWeight * MorphsHigh[iSlider])
			iSlider += 1
		EndWhile
	endIf
	NiOverride.UpdateModelWeight(target) ; Update the model.

	return fTargetWeight
EndFunction


float Function linearize(float oldWeight, float maximumWeight) global
	float ratio = oldWeight / maximumWeight

	If ratio < 0.0
		ratio += 1.0
		If ratio > 0.7
			ratio = 0.7
		EndIf
		return ratio
	Else
		ratio -= 1.0
		If ratio > -0.3
			ratio = -0.3
		EndIf
		return -ratio
	EndIf
endFunction


bool Function isValidConsumer(Actor consumer)
	if consumer == PlayerRef
		return PlayerEnabled
	elseif LibFire.ActorIsFollower(consumer)
		if CompanionsEnabled
			int sex = consumer.GetLeveledActorBase().GetSex()
			return (MalesEnabled && sex == 0) || (FemalesEnabled && sex != 0)
		else
			return false
		endIf
	elseif consumer.GetActorBase().IsUnique()
		;Some actors like Town Guards are recycled so we have to ensure NPCs are unique or morphs may carry over.
		if ActorsEnabled
			int sex = consumer.GetLeveledActorBase().GetSex()
			return (MalesEnabled && sex == 0) || (FemalesEnabled && sex != 0)
		else 
			return false
		endIf
	Else
		Return False
	endIf
EndFunction


bool Function addHighValueFood(Form food)
	int index = HighValueFood.find(food)
	if index >= 0 && index < HighValueFood.Length
        return true
    endIf

    index = HighValueFood.find(none)
    if index < 0 
        HighValueFood = Utility.ResizeFormArray(HighValueFood, 1+(3*HighValueFood.length/2), none)
		index = HighValueFood.find(none)
		if index < 0 
			return false
		endIf
    endIf

    HighValueFood[index] = food
	Log1(PREFIX, "addHighValueFood", Namer(food))
	GotoState("DefaultState")
	return true
endFunction


bool Function addNoValueFood(Form food)
	int index = NoValueFood.find(food)
	if index >= 0 && index < NoValueFood.Length
        return true
    endIf

    index = NoValueFood.find(none)
    if index < 0 
        NoValueFood = Utility.ResizeFormArray(NoValueFood, 1+(3*NoValueFood.length/2), none)
		index = NoValueFood.find(none)
		if index < 0 
			return false
		endIf
    endIf

    NoValueFood[index] = food
	Log1(PREFIX, "addNoValueFood", Namer(food))
	GotoState("DefaultState")
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

	return true
EndFunction


bool Function removeMorph(int iSliderIndex)
    MorphStrings[iSliderIndex] = ""
	MorphsHigh[iSliderIndex] = 0.0
	MorphsLow[iSliderIndex] = 0.0

	if iSliderIndex < 32
		CompactifyMorphs(0, 32)
	elseif iSliderIndex < 64
		CompactifyMorphs(32, 32)
	else
		CompactifyMorphs(64, 32)
	endIf

    return true
EndFunction


Function CompactifyMorphs(int first, int count)
	int firstBlank = MorphStrings.find("", first)
	int endPoint = first + count
	int i = firstBlank + 1
	
	while i < endPoint
		if MorphStrings[i] != ""
			MorphStrings[firstBlank] = MorphStrings[i]
			MorphsHigh[firstBlank] = MorphsHigh[i]
			MorphsLow[firstBlank] = MorphsLow[i]
			MorphStrings[i] = ""
			MorphsHigh[i] = 0.0
			MorphsLow[i] = 0.0
			firstBlank += 1
		endIf
		i += 1
	endWhile
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


Function RunPatchups()
	Debug.Notification("Scanning main plugins.")
	addNoValueFood(Game.GetFormFromFile(0x034CDF, "Skyrim.esm"))
	addNoValueFood(Game.GetFormFromFile(0x074A19, "Skyrim.esm"))

	addHighValueFood(Game.GetFormFromFile(0x064b30, "Skyrim.esm"))
	addHighValueFood(Game.GetFormFromFile(0x03AD72, "Skyrim.esm"))
	addHighValueFood(Game.GetFormFromFile(0x10394D, "Skyrim.esm"))
	addHighValueFood(Game.GetFormFromFile(0x0669A4, "Skyrim.esm"))
	addHighValueFood(Game.GetFormFromFile(0x0722BB, "Skyrim.esm"))
	addHighValueFood(Game.GetFormFromFile(0x00353C, "Hearthfires.esm"))

	if Game.IsPluginInstalled("RealisticNeedsAndDiseases.esp")
		Debug.Notification("Scanning 'RealisticNeedsAndDiseases.esp'")
		addNoValueFood(Game.GetFormFromFile(0x0053EC, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0053EE, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0053F0, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x00FB99, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x00FB9B, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x00FBA0, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0053E5, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0053E7, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0053E9, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x00FBA3, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x00FBA5, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x00FBA7, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x05B2BC, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x05B2BE, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x05B2C0, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047FAE, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047FB0, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047FB6, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0B6DF3, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0B6DF0, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0B6DEE, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x005968, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x046497, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047F98, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047F9A, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047F96, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047F94, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047F8B, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047F89, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047F88, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x0449AB, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x069FBE, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047FA7, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047FA5, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047FA4, "RealisticNeedsAndDiseases.esp"))
		addNoValueFood(Game.GetFormFromFile(0x047FA2, "RealisticNeedsAndDiseases.esp"))

		addHighValueFood(Game.GetFormFromFile(0x012C49, "RealisticNeedsAndDiseases.esp"))
	endIf

	if Game.IsPluginInstalled("Skyrim Immersive Creatures Special Edition.esp")
		Debug.Notification("Scanning 'Skyrim Immersive Creatures Special Edition.esp'")
		addHighValueFood(Game.GetFormFromFile(0x00F5EA, "Skyrim Immersive Creatures Special Edition.esp"))
	endIf
		
	if Game.IsPluginInstalled("SunhelmSurvival.esp")
		Debug.Notification("Scanning 'SunhelmSurvival.esp'")
		addNoValueFood(Game.GetFormFromFile(0x265BE3, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x265BE7, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x326258, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x070897, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x07AA96, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x326252, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4DE9AE, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4DE9AF, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4DE9B0, "SunhelmSurvival.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4EDCC1, "SunhelmSurvival.esp"))
	endIf

	if Game.IsPluginInstalled("Minineeds.esp")
		Debug.Notification("Scanning 'Minineeds.esp'")
		addNoValueFood(Game.GetFormFromFile(0x003192, "Minineeds.esp"))
		addNoValueFood(Game.GetFormFromFile(0x003194, "Minineeds.esp"))
	endIf

	if Game.IsPluginInstalled("INeed.esp")
		Debug.Notification("Scanning 'INeed.esp'")
		addNoValueFood(Game.GetFormFromFile(0x00437F, "INeed.esp"))
		addNoValueFood(Game.GetFormFromFile(0x00437D, "INeed.esp"))
		addNoValueFood(Game.GetFormFromFile(0x004376, "INeed.esp"))
		addNoValueFood(Game.GetFormFromFile(0x03B2C5, "INeed.esp"))
		addNoValueFood(Game.GetFormFromFile(0x03B2C8, "INeed.esp"))
		addNoValueFood(Game.GetFormFromFile(0x03B2CC, "INeed.esp"))
	endIf

	if Game.IsPluginInstalled("Hunterborn.esp")
		Debug.Notification("Scanning 'Hunterborn.esp'")
		addNoValueFood(Game.GetFormFromFile(0x28CCFA, "Hunterborn.esp"))

		addHighValueFood(Game.GetFormFromFile(0x1C2257, "Hunterborn.esp"))
	endIf
		
	if Game.IsPluginInstalled("Complete Alchemy & Cooking Overhaul.esp")
		Debug.Notification("Scanning 'Complete Alchemy & Cooking Overhaul.esp'")
		addNoValueFood(Game.GetFormFromFile(0xCCA111, "Update.esm"))
		addNoValueFood(Game.GetFormFromFile(0x4E3D21, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4E3D23, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4E3D25, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4E3D27, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4E3D29, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4E3D2B, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4E3D2D, "Complete Alchemy & Cooking Overhaul.esp"))		
		addNoValueFood(Game.GetFormFromFile(0x4B633B, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x50750A, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x50750B, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x50750D, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5DC3C2, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4FD2B7, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5DC3C0, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4FD2BA, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x46A34E, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x73499B, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D2185, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D2186, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D21A0, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D21A2, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D21A4, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D21A6, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D21A8, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D21AA, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D2188, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D2192, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D2194, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D2196, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D2198, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D219A, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D219C, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D219E, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5E14C8, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x4FD2BC, "Complete Alchemy & Cooking Overhaul.esp"))
		addNoValueFood(Game.GetFormFromFile(0x5D72AF, "Complete Alchemy & Cooking Overhaul.esp"))

		addHighValueFood(Game.GetFormFromFile(0xCCA124, "Update.esm"))
		addHighValueFood(Game.GetFormFromFile(0xCCA143, "Update.esm"))
		addHighValueFood(Game.GetFormFromFile(0xCCA144, "Update.esm"))
		addHighValueFood(Game.GetFormFromFile(0xCCA120, "Update.esm"))
		
		addHighValueFood(Game.GetFormFromFile(0x9E0567, "Complete Alchemy & Cooking Overhaul.esp"))
		addHighValueFood(Game.GetFormFromFile(0x9E056A, "Complete Alchemy & Cooking Overhaul.esp"))
		addHighValueFood(Game.GetFormFromFile(0x9E056C, "Complete Alchemy & Cooking Overhaul.esp"))
		addHighValueFood(Game.GetFormFromFile(0x9E056E, "Complete Alchemy & Cooking Overhaul.esp"))
	endIf

	if Game.IsPluginInstalled("MilkModNEW.esp")
		Debug.Notification("Scanning 'MilkModNEW.esp'")
		addNoValueFood(Game.GetFormFromFile(0x076D1D, "MilkModNEW.esp"))
		addNoValueFood(Game.GetFormFromFile(0x05311B, "MilkModNEW.esp"))
		addNoValueFood(Game.GetFormFromFile(0x05820F, "MilkModNEW.esp"))
	endIf

	Debug.MessageBox("Patchup Complete")
EndFunction


Function LoadSettings(int data)
	PlayerEnabled =			JMap.GetInt(data, "PlayerEnabled", PlayerEnabled as int) as bool
	CompanionsEnabled =		JMap.GetInt(data, "CompanionsEnabled", CompanionsEnabled as int) as bool
	ActorsEnabled =			JMap.GetInt(data, "ActorsEnabled", ActorsEnabled as int) as bool
	FemalesEnabled =		JMap.GetInt(data, "FemalesEnabled", FemalesEnabled as int) as bool
	MalesEnabled =			JMap.GetInt(data, "MalesEnabled", MalesEnabled as int) as bool
	CreaturesEnabled =		JMap.GetInt(data, "CreaturesEnabled", CreaturesEnabled as int) as bool
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
	fSkeletonLow = 			JMap.GetFlt(data, "fSkeletonLow", fSkeletonLow)
	fSkeletonHigh = 		JMap.GetFlt(data, "fSkeletonHigh", fSkeletonHigh)
	mSkeletonLow = 			JMap.GetFlt(data, "mSkeletonLow", mSkeletonLow)
	mSkeletonHigh = 		JMap.GetFlt(data, "mSkeletonHigh", mSkeletonHigh)
	cSkeletonLow = 			JMap.GetFlt(data, "cSkeletonLow", cSkeletonLow)
	cSkeletonHigh = 		JMap.GetFlt(data, "cSkeletonHigh", cSkeletonHigh)
	
	int tempData

	MorphStrings = JArray.asStringArray(JMap.getObj(data, "MorphStrings", JArray.ObjectWithStrings(MorphStrings)))
	MorphsHigh = JArray.asFloatArray(JMap.getObj(data, "MorphsHigh", JArray.ObjectWithFloats(MorphsHigh)))
	MorphsLow = JArray.asFloatArray(JMap.getObj(data, "MorphsLow", JArray.ObjectWithFloats(MorphsLow)))
	HighValueFood = JArray.asFormArray(JMap.getObj(data, "HighValueFood", JArray.ObjectWithForms(HighValueFood)))
	NoValueFood = JArray.asFormArray(JMap.getObj(data, "NoValueFood", JArray.ObjectWithForms(NoValueFood)))

    if MorphStrings.length < 96 || MorphsHigh.length < 96 || MorphsLow.length < 96
        MorphStrings = Utility.ResizeStringArray(MorphStrings, 96)
        MorphsHigh = Utility.ResizeFloatArray(MorphsHigh, 96)
        MorphsLow = Utility.ResizeFloatArray(MorphsLow, 96)
    endIf
EndFunction


Function SaveSettings(int data)
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
	JMap.SetObj(data, "MorphStrings", 			JArray.objectWithStrings(MorphStrings))
	JMap.SetObj(data, "MorphsHigh", 			JArray.objectWithFloats(MorphsHigh))
	JMap.SetObj(data, "MorphsLow", 				JArray.objectWithFloats(MorphsLow))
	JMap.SetObj(data, "HighValueFood", 			JArray.objectWithForms(HighValueFood))
	JMap.SetObj(data, "NoValueFood", 			JArray.objectWithForms(NoValueFood))
	JMap.SetFlt(data, "fSkeletonLow", 			fSkeletonLow)
	JMap.SetFlt(data, "fSkeletonHigh", 			fSkeletonHigh)
	JMap.SetFlt(data, "mSkeletonLow", 			mSkeletonLow)
	JMap.SetFlt(data, "mSkeletonHigh", 			mSkeletonHigh)
	JMap.SetFlt(data, "cSkeletonLow", 			cSkeletonLow)
	JMap.SetFlt(data, "cSkeletonHigh", 			cSkeletonHigh)
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
