scriptName DevourmentMacromancySU extends ActiveMagicEffect
{
This version of Macromancy uses a storageutil value to store the new size. Useful for abrupt size changes that slowly wear off (or vice versa).
Set the new size beforehand using DevourmentMacromancySU.SetSize(target, size)
}
import Logging
import DevourmentUtil


DevourmentManager property Manager auto
Actor property PlayerRef auto
float property Speed = 0.08 auto
Keyword property DevourmentSize auto
;Quest property CCQ auto


String PREFIX = "DevourmentMacromancy"
String rootNode = "NPC Root [Root]"
float Smoothness
float Unsmoothness
float currentScale
float targetScale
float MacromancyScaling
bool isFemale
Actor target


Function SetSize(Actor subject, float size) global
	StorageUtil.SetFloatValue(subject, "DevourmentMacromancy", size)
EndFunction


event OnEffectStart(Actor akTarget, Actor akCaster)
{
Event received when this effect is first started (OnInit may not have been run yet!)
}
	if !akTarget
		assertNotNone(PREFIX, "OnEffectStart", "akTarget", akTarget)
		return
	endif

	MacromancyScaling = Manager.MacromancyScaling
	Unsmoothness = Speed
	Smoothness = 1.0 - Unsmoothness
	
	target = akTarget
	currentScale = StorageUtil.PluckFloatValue(target, "DevourmentMacromancy", 0.5)
	if currentScale < 1.0
		currentScale /= MacromancyScaling
	else
		currentScale *= MacromancyScaling
	endIf

	if currentScale < 0.01
		currentScale = 0.01
	endIf

	targetScale = 1.0
	isFemale = Manager.IsFemale(target)
	Manager.UncacheVoreWeight(akTarget)
	NIOverride.AddNodeTransformScale(target, false, isFemale, rootNode, PREFIX, currentScale)
	NiOverride.UpdateNodeTransform(target, false, isFemale, rootNode)
	RegisterForSingleUpdate(0.0)
endEvent


Event OnUpdate()
	float diff = targetScale - currentScale
	
	if diff < -0.01 || diff > 0.01
		currentScale = Smoothness * currentScale + Unsmoothness * targetScale
		NIOverride.AddNodeTransformScale(target, false, isFemale, rootNode, PREFIX, currentScale)
		NiOverride.UpdateNodeTransform(target, false, isFemale, rootNode)

		RegisterForSingleUpdate(0.050)
		
	elseif !target.HasMagicEffectWithKeyword(DevourmentSize)
		Dispel()
	else
		RegisterForSingleUpdate(1.0)
	endIf
	
EndEvent


Event OnEffectFinish(Actor akTarget, Actor akCaster)
{
Event received when this effect is finished (effect may already be deleted, calling
functions on this effect will fail)
}
	NIOverride.RemoveNodeTransformScale(target, false, isFemale, rootNode, PREFIX)
	NiOverride.UpdateNodeTransform(target, false, isFemale, rootNode)
endEvent

