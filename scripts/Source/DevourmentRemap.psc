Scriptname DevourmentRemap extends Quest
import Logging


FormList property RemapFrom auto
FormList property RemapTo auto
String property RaceRemaps = "..\\devourment\\raceRemaps.json" autoreadonly
String PREFIX = "DevourmentRemap"


Race Function RemapRace(Race from)
	int index = RemapFrom.Find(from)
	if index >= 0
		return RemapTo.GetAt(index) as Race
	else
		return from
	endIf
EndFunction


String Function RemapRaceName(Actor target)
	String raceName = RemapRace(target.GetLeveledActorBase().getRace()).getName()
	String remapName = JLua.evalLuaStr("return '...'..string.lower(args.name)", JLua.SetStr("name", raceName))
	String statName = JSonUtil.GetStringValue(RaceRemaps, remapName, raceName)
	Log4(PREFIX, "RemapRace", Namer(target), raceName, remapName, statName)
	return statName
EndFunction


