ScriptName DevourmentDigestItems extends ActiveMagicEffect
import Logging


;-- Properties --------------------------------------
DevourmentManager property Manager auto


String PREFIX = "DevourmentDigestItems"
Perk property TummyBank auto
Perk property Selective auto
MiscObject property Gold auto
Keyword[] property MaterialKeywords auto
Form[] property BreakdownItems auto
float ValueRatioLimit = 10.0
bool tummyBanking = false


Event OnEffectStart(Actor akTarget, Actor akCaster)
	Form[] stomach = Manager.GetStomachArray(akCaster)
	if Manager.EmptyStomach(stomach)
		return
	endIf

	tummyBanking = akCaster.HasPerk(TummyBank)
	ValueRatioLimit += (akCaster.GetLevel() as float) / 5.0
	
	if akCaster.HasPerk(Selective)
		SelectItems(akCaster, stomach)
	else
		DigestItems(akCaster, stomach)
	endIf
	
	if akCaster == Manager.playerRef
		Manager.PlayerAlias.CheckClearEliminate()
	endIf
EndEvent


bool Function SelectItems(Actor caster, Form[] stomach)
	UIListMenu menu = UIExtensions.GetMenu("UIListMenu") as UIListMenu

	int entryMap = JValue.Retain(JIntMap.Object(), PREFIX)
	bool exit = false
	while !exit
		menu.ResetMenu()
		int ENTRY_EXIT = menu.AddEntryItem("Exit")

		int stomachIndex = stomach.length
		while stomachIndex
			stomachIndex -= 1
			
			if stomach[stomachIndex] as DevourmentBolus
				DevourmentBolus bolus = stomach[stomachIndex] as DevourmentBolus
				Form[] bolusContents = bolus.GetContainerForms()
				bool keepBolus = false
				
				int bolusIndex = bolusContents.length
				while bolusIndex
					bolusIndex -= 1
					Form item = bolusContents[bolusIndex]
					int count = bolus.GetItemCount(item)
					
					if Manager.IsStrippable(item) && GetValueRatio(item) <= ValueRatioLimit && item != Gold

						int ENTRY = menu.AddEntryItem(Namer(item, true) + "(" + count + ")")
						int entryDescriptor = JMap.object()
						JMap.setForm(entryDescriptor, "bolus", bolus)
						JMap.setForm(entryDescriptor, "item", item)
						JMap.setInt(entryDescriptor, "count", count)
						JIntMap.setObj(entryMap, ENTRY, entryDescriptor)
					else
						Log2(PREFIX, "OnEffectStart", "Indigestible: not strippable.", Namer(item))
					endIf
				endWhile
			endIf
		endWhile

		menu.OpenMenu()
		int result = menu.GetResultInt()
		int entryDescriptor = JIntMap.GetObj(entryMap, result)
		
		if result < 0 || result == ENTRY_EXIT
			exit = true

		elseif JValue.isExists(entryDescriptor)
			DevourmentBolus bolus = JMap.getForm(entryDescriptor, "bolus") as DevourmentBolus
			Form item = JMap.getForm(entryDescriptor, "item")
			int count = JMap.getInt(entryDescriptor, "count", 1)
			Debug.MessageBox(Namer(bolus) + " / " + Namer(item) + " / " + count)

			bool digested = DigestItem(caster, bolus, item, count)

		endIf
	endWhile

	entryMap = JValue.Release(entryMap)
EndFunction


bool Function DigestItems(Actor caster, Form[] stomach)
	int stomachIndex = stomach.length
	while stomachIndex
		stomachIndex -= 1
		
		if stomach[stomachIndex] as DevourmentBolus
			DevourmentBolus bolus = stomach[stomachIndex] as DevourmentBolus
			Form[] bolusContents = bolus.GetContainerForms()
			bool allDigested = true
			
			int bolusIndex = bolusContents.length
			while bolusIndex
				bolusIndex -= 1
				Form item = bolusContents[bolusIndex]
				int count = bolus.GetItemCount(item)
				
				if Manager.IsStrippable(item)
					bool digested = DigestItem(caster, bolus, item, count)
					allDigested = allDigested && digested
				else
					Log2(PREFIX, "OnEffectStart", "Indigestible: not strippable.", Namer(item))
				endIf
			endWhile

			Manager.UpdateBolusData(caster, bolus)
			if allDigested
				bolus.SetName("Dissolved Items")
			endIf
		endIf
	endWhile

	return true
EndFunction


bool Function DigestItem(Actor caster, DevourmentBolus bolus, Form item, int count)
	{ Returns the digested flag -- true if the item was destroyed or replaced. }

	Keyword[] ItemKeywords = item.GetKeywords()
	Keyword match = FirstMatchingKeyword(ItemKeywords, MaterialKeywords)
	int materialIndex = MaterialKeywords.find(match)
	
	ObjectReference destination
	if Manager.Menu.DigestToInventory
		destination = caster
	else
		destination = bolus
	endIf

	if Manager.DEBUGGING
		Log3(PREFIX, "DigestItem", Namer(item), materialIndex, match)
	endIf

	if match && materialIndex >= 0
		bolus.RemoveItem(item, count, true)
		AddBreakdownItem(bolus, item, count, BreakdownItems[materialIndex], destination)
		Log2(PREFIX, "DigestItem", "Broken down", Namer(item))
		return true
	
	elseif GetValueRatio(item) > ValueRatioLimit || item == Gold
		Log2(PREFIX, "DigestItem", "Too valuable", Namer(item))
		return false
		
	elseif tummyBanking && item != Gold
		bolus.RemoveItem(item, count, true)
		int goldValue = item.GetGoldValue()
		int totalGold = 1 + count * goldValue / 2

		destination.AddItem(Gold, goldValue, true)
		Log5(PREFIX, "DigestItem", "Banked", goldValue, count, totalGold, Namer(item))
		return true
		
	elseif BreakdownItems.find(item) >= 0
		Log2(PREFIX, "DigestItem", "Already broken down", Namer(item))
		return false
	
	else
		bolus.RemoveItem(item, count, true)
		Log2(PREFIX, "DigestItem", "Destroyed", Namer(item))
		return true
	endIf
EndFunction


float Function GetValueRatio(Form item)
	float itemValue = item.GetGoldValue()
	float itemWeight = item.GetWeight()
	
	if itemWeight > 0.01
		return itemValue / itemWeight
	else
		return itemValue
	endIf
EndFunction


Function AddBreakdownItem(DevourmentBolus bolus, Form item, int count, Form breakdownItem, ObjectReference destination)
	float itemWeight = item.GetWeight()
	float breakdownWeight = breakdownItem.GetWeight()
	float itemValue = item.GetGoldValue() as float
	float breakdownValue = breakdownItem.GetGoldValue() as float
	
	; If the value or weight is extremely low, just provide COUNT of the breakdown item.
	if breakdownWeight < 0.01 || itemWeight < 0.01 || breakdownValue < 0.5 || itemValue < 0.5
		bolus.AddItem(breakdownItem, count, true)

	else
		int breakdownCount = (0.33 * count * min(itemWeight / breakdownWeight, itemValue / breakdownValue)) as int

		; If the count is less than 1, return 1 of the breakdown item.
		if breakdownCount < 1
			destination.AddItem(breakdownItem, 1, true)

		; If the count is greater than 25, return 25 of the breakdown item.
		elseif breakdownCount > 25
			destination.AddItem(breakdownItem, 25, true)

		else
			destination.AddItem(breakdownItem, breakdownCount, true)
		endIf
	endIf
EndFunction


Keyword Function FirstMatchingKeyword(Keyword[] list1, Keyword[] list2)
	int len = list1.length
	if len > list2.length
		return FirstMatchingKeyword(list2, list1)
	endIf
	
	while len
		len -= 1
		Keyword k = list1[len]
		if list2.find(k) >= 0
			return k
		endIf
	endWhile
	
	return none
EndFunction


float Function min(float a, float b)
	if a<b
		return a
	else
		return b
	endIf
endFunction
