ScriptName DevourmentSurvivalNeeds extends ReferenceAlias
import Logging


float property RNDFoodPerTick = -0.2 auto
float property INeedFoodPerTick = 0.2 auto
float property ccSurvFoodPerTick = 32.0 auto
float property SunHelmFoodPerTick = 0.25 auto
int property MiniNeedsTicksPerFood = 20 auto
Form property MiniNeedsProxyFood auto

String PREFIX = "DevourmentSurvivalNeeds"
Quest RNDQuest = None
Quest INeedQuest = None
Quest CCSurvHungerQuest = None
Quest SunHelmQuest = None
Alias MiniNeedPlayer = None
int MiniNeedTicks = 0
float scale = 1.0


Event OnInit()
	RegisterForSingleUpdate(5.0)
EndEvent


Event OnPlayerLoadGame()
	RegisterForSingleUpdate(5.0)
EndEvent


Event onUpdate()
	Registrations()
EndEvent


Event OnDeadDigestion(Form pred, Form prey, float remaining)
	if pred != self.GetReference()
		return
	endif

	if RNDQuest
		GlobalVariable hunger = (RNDQuest as RND_SkyUIMCMScript).RND_HungerPoints
		float newValue = hunger.mod(scale * RNDFoodPerTick)
		if newValue < 0.0
			 hunger.setValue(0.0)
		endif
	endif

	if INeedQuest
		(iNeedQuest as _SNQuestScript).ModHunger(scale * INeedFoodPerTick)
	endif
	
	if ccSurvHungerQuest && PO3_SKSEFunctions.IsSurvivalModeActive()
		(ccSurvHungerQuest as Survival_NeedHunger).DecreaseHungerBuffered(scale * ccSurvFoodPerTick)
	endif

	if MiniNeedPlayer
		if MiniNeedTicks == 0
			(MiniNeedPlayer as mndMiniNeedsPlayerScript).setEat(MiniNeedsProxyFood)
		endIf
		
		MiniNeedTicks += 1
		MiniNeedTicks %= MiniNeedsTicksPerFood
	endif
	
	if SunHelmQuest
		(SunHelmQuest as _SunHelmMain).Hunger.DecreaseHungerLevel(scale * SunHelmFoodPerTick)
	endIf
EndEvent


Function Registrations()
	scale = 360.0 / DevourmentManager.instance().DigestionTime
	
	RNDQuest = Quest.GetQuest("RNDConfigQuest")
	iNeedQuest = Quest.GetQuest("_SNQuest")
	ccSurvHungerQuest = Quest.GetQuest("Survival_NeedHungerQuest")
	SunHelmQuest = Quest.GetQuest("_SHMainQuest")
	
	Quest MiniNeedQuest = Quest.GetQuest("mndMiniNeeds")
	if MiniNeedQuest
		MiniNeedPlayer = MiniNeedQuest.GetAliasByName("playerRef")
	else
		MiniNeedPlayer = None
	endif

	if MiniNeedPlayer || iNeedQuest || RNDQuest || ccSurvHungerQuest || SunHelmQuest
		Log1(PREFIX, "Registrations", "*Survival mods registered*\n" + \
			"MiniNeedPlayer: " + MiniNeedPlayer + "\n" + \
			"iNeedQuest: " + iNeedQuest + "\n" + \
			"RNDQuest: " + RNDQuest + "\n" + \
			"ccSurvivalModeHungerQuest: " + ccSurvHungerQuest + "\n" + \
			"SunHelmQuest: " + SunHelmQuest + "\n" + \
			"")
			
		RegisterForModEvent("Devourment_OnDeadDigestion", "OnDeadDigestion")
	endIf
EndFunction


float Function GetPlayerHunger()
	Actor PlayerRef = Self.GetReference() as Actor
	
	if SunHelmQuest
		_SHHungerSystem hunger = (SunHelmQuest as _SunHelmMain).Hunger
		if hunger.CurrentHungerStage < 0
			return 0.0
		else 
			return ((hunger.CurrentHungerStage - 1) as float) / 4.0
		endIf
	else
		return 1.0
	endIf
EndFunction
