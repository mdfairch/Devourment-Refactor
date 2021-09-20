scriptName DevourmentBellyScaling extends ActiveMagicEffect
{
}
import Logging
import DevourmentUtil


DevourmentManager property Manager auto
DevourmentMorphs property Morphs auto
Actor property PlayerRef auto
Armor[] property Fullnesses auto
FormList property FullnessTypes_All auto
String[] property StruggleSliders auto


String PREFIX = "DevourmentBellyScaling"
bool DEBUGGING
bool isFemale
Actor target

int DATA = 0
int OUTPUT_BODY = 0
int OUTPUT_BUMPS = 0
String PROTOTYPE = "{ \"currentScale\" : 0.0, \"targetScale\" : 0.0, \"currentScales\" : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0], \"targetScales\" : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0], \"oddity\" : 0.9, \"amplitude\" : 0.5, \"minDuration\" : 15.0, \"maxDuration\" : 30.0, \"bumps\" : [{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}], \"output_scale\" : 0.0, \"output_body\" : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0], \"output_bumps\" : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0] }"


bool UseMorphVore = true
bool UseStruggleSliders = true
bool UseLocationalMorphs = true
int EquippableBellyType = 1
float UpdateTime = 0.05
float playerStruggle = 0.0
bool PlayerStruggleBumps


String[] Sliders
bool[] isNode


event OnEffectStart(Actor akTarget, Actor akCaster)
	{ Event received when this effect is first started (OnInit may not have been run yet!) }
	if !akTarget
		assertNotNone(PREFIX, "OnEffectStart", "akTarget", akTarget)
		return
	endif

	target = akTarget
	isFemale = Manager.IsFemale(target)
	PlayerStruggleBumps = Manager.whoStruggles > 0

	DEBUGGING = Manager.DEBUGGING
	
	DATA = JValue.retain(JValue.objectFromPrototype(PROTOTYPE), PREFIX)
	OUTPUT_BODY = JMap.GetObj(DATA, "output_body")
	OUTPUT_BUMPS = JMap.GetObj(DATA, "output_bumps")

	int SETTINGS = Morphs.GetSettings(target)
	JMap.addPairs(DATA, SETTINGS, false)
	JMap.SetForm(DATA, "target", target)

	Sliders = JArray.asStringArray(JMap.GetObj(SETTINGS, "Locus_Sliders"))
	IsNode = Utility.CreateBoolArray(Sliders.length)

	int sliderIndex = Sliders.length
	while sliderIndex
		sliderIndex -= 1
		String slider = Sliders[sliderIndex]
		if target.HasNode(slider) || StringUtil.find(slider, "NPC ") >= 0
			IsNode[sliderIndex] = true
		else
			IsNode[sliderIndex] = false
		endIf
	endWhile

	if Manager.PERFORMANCE
		UseStruggleSliders = false
		JMap.setFlt(DATA, "MorphSpeed", 1.0)
		JMap.setInt(DATA, "UseStruggleSliders", 0)
		UpdateTime = 1.0
	else
		UseStruggleSliders = JMap.GetInt(SETTINGS, "UseStruggleSliders", Morphs.UseStruggleSliders as int) as bool
	endIf

	EquippableBellyType = JMap.GetInt(SETTINGS, "EquippableBellyType", Morphs.EquippableBellyType)
	
	if EquippableBellyType >= 0 && EquippableBellyType < Fullnesses.length
		Armor belly = Fullnesses[EquippableBellyType]
		target.equipItem(belly, false, true)

		if !belly.HasKeywordString("SexlabNoStrip")
			Keyword NoStrip = Keyword.GetKeyword("SexlabNoStrip")
			if NoStrip
				PO3_SKSEFunctions.AddKeywordToForm(belly, NoStrip)
			endIf
		endIf
	else
		target.removeItem(FullnessTypes_All, 99, true)
	endIf

	if Sliders.length < 1 || IsNode.length < 1 || !JValue.IsExists(DATA)
		AssertExists(PREFIX, "OnEffectStart", "DATA", DATA)
		AssertExists(PREFIX, "OnEffectStart", "OUTPUT_BODY", OUTPUT_BODY)
		AssertExists(PREFIX, "OnEffectStart", "OUTPUT_BUMPS", OUTPUT_BUMPS)
		return
	endIf

	if PlayerStruggleBumps
		RegisterForModEvent("Devourment_PlayerStruggle", "OnPlayerStruggle")
		RegisterForModEvent("Devourment_onLiveDigestion", "onLiveDigestion")
		RegisterForModEvent("Devourment_onPreyDeath", "onPreyDeath")
		RegisterForModEvent("Devourment_onEscape", "onEscape")
	else
		playerStruggle = -1.0
	endIf
	
	RegisterForSingleUpdate(0.0)
endEvent


Event onPreyDeath(Form pred, Form prey)
{ Checks if the principal struggler has died. If so, the principal struggler field is cleared. }
	if pred == target && prey == playerRef
		playerStruggle = 0.0
	endIf
EndEvent


Event onEscape(Form pred, Form prey, bool oral)
{ Checks if the principal struggler has escaped. If so, the principal struggler field is cleared. }
	if pred == target && prey == playerRef
		playerStruggle = 0.0
	endIf
EndEvent


Event OnCombatStateChanged(Actor newTarget, int aeCombatState)
	if aeCombatState > 1
		JMap.SetInt(DATA, "squench", 1)
	else
		JMap.removeKey(DATA, "squench")
	endIf
EndEvent


Event onLiveDigestion(Form pred, Form prey, float damage, float percent)
{ Updates the bumpAmplitude field for the principal struggler. }
	if pred == target && prey == playerRef
		playerStruggle *= 0.5
	endIf
EndEvent


Event OnPlayerStruggle(bool successful, float times)
	Log3(PREFIX, "OnPlayerStruggle", successful, times, playerStruggle)
	if Manager.GetPredFor(PlayerRef) == target
		playerStruggle = 1.0
	endIf
EndEvent


Event OnUpdate()

	float totalScale = JLua.evalLuaFlt("dvt.BumpSliders(args, " + playerStruggle + ")", DATA, 0, 0.0)
	float[] outputBody = JArray.asFloatArray(OUTPUT_BODY)
	float[] outputBumps = JArray.asFloatArray(OUTPUT_BUMPS)

	if DEBUGGING 
		;Log1(PREFIX, "OnUpdate" LuaS("DATA", DATA))
	endIf
	
	bool updateWeights = false

	if UseMorphVore
		if !UseLocationalMorphs
			if totalScale >= 0.0
				if IsNode[0]
					NIOverride.AddNodeTransformScale(target, false, isFemale, Sliders[0], PREFIX, 1.0 + totalScale)
					NIOverride.UpdateNodeTransform(target, false, isFemale, Sliders[0])
				else
					NIOverride.SetBodyMorph(target, Sliders[0], PREFIX, totalScale)
					updateWeights = true
				endIf
			endIf
		else
			int sliderIndex = Sliders.length
			while sliderIndex
				sliderIndex -= 1
				float scale = outputBody[sliderIndex]
				if scale >= 0.0
					if IsNode[sliderIndex]
						NIOverride.AddNodeTransformScale(target, false, isFemale, Sliders[sliderIndex], PREFIX, 1.0 + scale)
						NIOverride.UpdateNodeTransform(target, false, isFemale, Sliders[sliderIndex])
					else
						NIOverride.SetBodyMorph(target, Sliders[sliderIndex], PREFIX, scale)
						updateWeights = true
					endIf
				endIf
			endWhile
		endIf
	endIf
	
	if UseStruggleSliders
		int sliderIndex = StruggleSliders.length
		while sliderIndex
			sliderIndex -= 1
			float scale = outputBumps[sliderIndex]
			if scale >= 0.0
				NIOverride.SetBodyMorph(target, StruggleSliders[sliderIndex], PREFIX, scale)
				updateWeights = true
			endIf
		endWhile
	endIf
	
	if updateWeights
		NiOverride.UpdateModelWeight(target)
		RegisterForSingleUpdate(UpdateTime)
	else
		RegisterForSingleUpdate(1.0)
	endIf
EndEvent


Event OnEffectFinish(Actor akTarget, Actor akCaster)
	Log1(PREFIX, "OnEffectFinish", Namer(target))

	DATA = JValue.release(DATA)
	NIOverride.ClearBodyMorphKeys(target, PREFIX)

	if UseMorphVore
		int sliderIndex = Sliders.length
		while sliderIndex
			sliderIndex -= 1
			if IsNode[sliderIndex]
				NIOverride.RemoveNodeTransformScale(target, false, isFemale, Sliders[sliderIndex], PREFIX)
				NIOverride.UpdateNodeTransform(target, false, isFemale, Sliders[sliderIndex])
			endIf
		endWhile
	endIf
	
	NiOverride.UpdateModelWeight(target)
	target.RemoveItem(FullnessTypes_All, 99, true)
endEvent
