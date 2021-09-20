scriptName DevourmentPuddle extends Actor
import Logging
import DevourmentUtil


String PREFIX = "DevourmentPuddle"
String puddleMorph
float puddleProgress
float puddleIncrement
float puddleSmoothness
ObjectReference anchor = none


Event onInit()
	int r = Utility.RandomInt(1,3)
	if r == 1
		puddleMorph = "Splash1"
	elseif r == 2
		puddleMorph = "Splash2"
	else
		puddleMorph = "Splash3"
	endif
	
	puddleProgress = 0.0
	puddleSmoothness = 0.94
	
	if anchor
		SetPosition(anchor.GetPositionX(), anchor.GetPositionY(), anchor.GetPositionZ())
	endIf

	self.Kill()
	self.Enable(false)
	self.EnableAI(false)
	self.SetAngle(0.0, 0.0, Utility.RandomFloat(0.0, 360.0))
	
	RegisterForSingleUpdate(0.01)
EndEvent


Function Initialize(ObjectReference loc)
	anchor = loc
	SetPosition(anchor.GetPositionX(), anchor.GetPositionY(), anchor.GetPositionZ())
EndFunction


Event OnUpdate()
	if puddleProgress < 0.99
		puddleProgress = puddleProgress * puddleSmoothness + (1.0 - puddleSmoothness)
		
		NiOverride.SetBodyMorph(self, puddleMorph, PREFIX, puddleProgress)
		NiOverride.UpdateModelWeight(self)
		RegisterForSingleUpdate(0.01)
	endIf
EndEvent
