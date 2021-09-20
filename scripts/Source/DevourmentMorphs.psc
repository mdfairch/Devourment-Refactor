ScriptName DevourmentMorphs extends ReferenceAlias


DevourmentManager property Manager auto
Actor property PlayerRef auto
bool property UseDualBreastMode = true auto


String property BodyMorphsFile_Player = "data\\skse\\plugins\\devourment\\bodyMorphs_player.json" autoreadonly
String property BodyMorphsFile_Female = "data\\skse\\plugins\\devourment\\bodyMorphs_female.json" autoreadonly
String property BodyMorphsFile_Male = "data\\skse\\plugins\\devourment\\bodyMorphs_male.json" autoreadonly
String property BodyMorphsFile_Creature = "data\\skse\\plugins\\devourment\\bodyMorphs_creature.json" autoreadonly
String property BodyMorphsFile_Template = "data\\skse\\plugins\\devourment\\bodyMorphs_template.json" autoreadonly
String property BodyMorphsFile_Specific = "data\\skse\\plugins\\devourment\\bodyMorphs_" autoreadonly


;=======================
; REGULAR MODE SETTINGS
;=======================


bool property UseMorphVore = true auto
bool property UseStruggleSliders = true auto
bool property UseLocationalMorphs = true auto
bool property UseEliminationLocus = true auto
int property EquippableBellyType = 1 auto
float property StruggleAmplitude = 1.0 auto
float property MorphSpeed = 0.07 auto
float property ScalingThreshold = 0.001 auto
float[] property Locus_Scales auto
float[] property Locus_Maxes auto
String[] property Locus_Sliders auto


Event OnInit()
	OnPlayerLoadGame()
EndEvent


Event OnPlayerLoadGame()
	if !JContainers.fileExistsAtPath(BodyMorphsFile_Template)
		Write(BodyMorphsFile_Template)
	endIf
EndEvent


Function LoadSettingsFrom(int data)
	UseMorphVore = 			JMap.getInt(data, "UseMorphVore", 			UseMorphVore as int) as bool
	UseLocationalMorphs = 	JMap.getInt(data, "UseLocationalMorphs", 	UseLocationalMorphs as int) as bool
	useStruggleSliders = 	JMap.getInt(data, "UseStruggleSliders", 	UseStruggleSliders as int) as bool
	UseEliminationLocus = 	JMap.getInt(data, "UseEliminationLocus", 	UseEliminationLocus as int) as bool
	UseDualBreastMode = 	JMap.getInt(data, "UseDualBreastMode", 		UseDualBreastMode as int) as bool
	EquippableBellyType = 	JMap.getInt(data, "EquippableBellyType", 	EquippableBellyType)
	MorphSpeed = 			JMap.getFlt(data, "MorphSpeed", 			MorphSpeed)
	StruggleAmplitude = 	JMap.getFlt(data, "StruggleAmplitude", 		StruggleAmplitude)
	Locus_Scales = 			JArray.asFloatArray(JMap.getObj(data, "Locus_Scales"))
	Locus_Maxes = 			JArray.asFloatArray(JMap.getObj(data, "Locus_Maxes"))
	Locus_Sliders = 		JArray.asStringArray(JMap.getObj(data, "Locus_Sliders"))
EndFunction


Function SaveSettingsTo(int data)
	JMap.setInt(data, "UseMorphVore", 			UseMorphVore as int)
	JMap.setInt(data, "UseLocationalMorphs", 	UseLocationalMorphs as int)
	JMap.setInt(data, "UseStruggleSliders", 	UseStruggleSliders as int)
	JMap.setInt(data, "UseEliminationLocus", 	UseEliminationLocus as int)
	JMap.setInt(data, "UseDualBreastMode", 		UseDualBreastMode as int)
	JMap.setInt(data, "EquippableBellyType", 	EquippableBellyType)
	JMap.setFlt(data, "MorphSpeed", 			MorphSpeed)
	JMap.setFlt(data, "StruggleAmplitude", 		StruggleAmplitude)
	JMap.setObj(data, "Locus_Scales", 			JArray.ObjectWithFloats(Locus_Scales))
	JMap.setObj(data, "Locus_Maxes", 			JArray.ObjectWithFloats(Locus_Maxes))
	JMap.setObj(data, "Locus_Sliders", 			JArray.ObjectWithStrings(Locus_Sliders))
EndFunction


int Function GetSettings(Actor target)
	int settings = JMap.Object()
	int expertData = Read(target)

	JMap.setInt(settings, "UseMorphVore", 			JMap.getInt(expertData, "UseMorphVore", 		UseMorphVore as int))
	JMap.setInt(settings, "UseLocationalMorphs", 	JMap.getInt(expertData, "UseLocationalMorphs", 	UseLocationalMorphs as int))
	JMap.setInt(settings, "UseStruggleSliders", 	JMap.getInt(expertData, "UseStruggleSliders", 	UseStruggleSliders as int))
	JMap.setInt(settings, "UseEliminationLocus", 	JMap.getInt(expertData, "UseEliminationLocus", 	UseEliminationLocus as int))
	JMap.setInt(settings, "EquippableBellyType", 	JMap.getInt(expertData, "EquippableBellyType", 	EquippableBellyType))
	JMap.setFlt(settings, "StruggleAmplitude", 		JMap.getFlt(expertData, "StruggleAmplitude", 	StruggleAmplitude))
	JMap.setFlt(settings, "MorphSpeed", 			JMap.getFlt(expertData, "MorphSpeed", 			MorphSpeed))
	JMap.setFlt(settings, "ScalingThreshold", 		JMap.getFlt(expertData, "ScalingThreshold", 	ScalingThreshold))
	JMap.setObj(settings, "Locus_Scales",			JMap.getObj(expertData, "Locus_Scales",			JArray.objectWithFloats(Locus_Scales)))
	JMap.setObj(settings, "Locus_Maxes",			JMap.getObj(expertData, "Locus_Maxes",			JArray.objectWithFloats(Locus_Maxes)))
	JMap.setObj(settings, "Locus_Sliders",			JMap.getObj(expertData, "Locus_Sliders",		JArray.objectWithStrings(Locus_Sliders)))
	return settings
EndFunction


int Function Read(Actor target)
	if target == playerRef
		return JValue.readFromFile(BodyMorphsFile_Player)
	elseif target.HasKeywordString("ActorTypeNPC")
		if Manager.IsMale(target)
			return JValue.readFromFile(BodyMorphsFile_Male)
		else
			return JValue.readFromFile(BodyMorphsFile_Female)
		endIf
	else
		String filename = BodyMorphsFile_Specific + MiscUtil.GetActorRaceEditorID(target) + ".json"
		if JContainers.fileExistsAtPath(filename)
			return JValue.readFromFile(filename)
		else
			return JValue.readFromFile(BodyMorphsFile_Creature)
		endIf
	endIf
EndFunction


Function Write(String filename)
	int data = JMap.object()

	JMap.setInt(data, "UseMorphVore", 			UseMorphVore as int)
	JMap.setInt(data, "UseLocationalMorphs", 	UseLocationalMorphs as int)
	JMap.setInt(data, "UseStruggleSliders", 	UseStruggleSliders as int)
	JMap.setInt(data, "UseEliminationLocus", 	UseEliminationLocus as int)
	JMap.setInt(data, "EquippableBellyType", 	EquippableBellyType)
	JMap.setFlt(data, "StruggleAmplitude", 		StruggleAmplitude)
	JMap.setFlt(data, "MorphSpeed", 			MorphSpeed)
	JMap.setFlt(data, "ScalingThreshold", 		ScalingThreshold)
	JMap.setObj(data, "Locus_Sliders", 			JArray.objectWithStrings(Locus_Sliders))
	JMap.setObj(data, "Locus_Scales", 			JArray.objectWithFloats(Locus_Scales))
	JMap.setObj(data, "Locus_Maxes", 			JArray.objectWithFloats(Locus_Maxes))
	JValue.writeToFile(data, filename)
EndFunction

