ScriptName DevourmentReformationQuest extends Quest
{ 
To add a reformation host (for the default scenario) use this code:
DevourmentReformationQuest.instance().AddReformationHost(host)


To submit a scene, register for the Devourment_Reformation event -- this event will be sent whenever the player's corpse is defecated (if they have the Phylactery perk).

Function RegisterForEvents()
	RegisterForModEvent("Devourment_Reformation", "OnReformation")
EndFunction


Event OnReformation(DevourmentReformationQuest reformQuest)
	;;; Check if you want your quest to run under the current conditions.
	if bEverythingIsGood
		reformQuest.RegisterQuest(Quest myReformationQuest)
	endIf
EndEvent


If more than one quest is registered, one will be picked at random.
It will be initiated by calling myReformationQuest.Start().


To start reforming the player inside of Pred, call
DevourmentManager.RegisterReformation(pred, playerRef, locus)

}
import Logging


DevourmentManager property Manager auto
Actor property PlayerRef auto
FormList property PhylacteryList auto


String PREFIX = "DevourmentReformationQuest"
Quest[] reformationQuests = none
;Actor[] ReformationHosts
;float[] ReformationHosts_TimeOut


Event onInit()
	RegisterForAnimationEvent(PlayerRef, "SoundPlay.NPCHorseDismount")
	;ReformationHosts = new Actor[20]
	;ReformationHosts_TimeOut = new float[20]
EndEvent


Event OnAnimationEvent(ObjectReference akSource, string asEventName)
	If akSource == PlayerRef
		If asEventName == "SoundPlay.NPCHorseDismount"
			Actor horse = Game.GetPlayersLastRiddenHorse()
			if horse
				AddReformationHost(horse)
			endIf		
		endIf
	endIf
EndEvent


Function Upgrade(int oldVersion, int newVersion)
{ Version 105 is a clean break, so upgrades all start from there. }
	Log2(PREFIX, "Upgrade", oldVersion, newVersion)
EndFunction
	
	
bool Function StartReformation()
{ Precondition: the player has been digested and defecated. }
	Log0(PREFIX, "StartReformation")
	reformationQuests = new Quest[20]
	SendReformationEvent()
	RegisterForSingleUpdate(10.0)
	Debug.Notification("I wonder who will find you?")
	return true
EndFunction


Event OnUpdate()
	Log0(PREFIX, "OnUpdate")
	
	int indexOfNone = reformationQuests.find(none)
	if indexOfNone == 0
		DefaultReformation()
	else
		int indexOfQuest = Utility.RandomInt(0, indexOfNone - 1)
		Quest selectedQuest = reformationQuests[indexOfQuest]
		selectedQuest.start()
	endIf
EndEvent


Function DefaultReformation()
	Log0(PREFIX, "DefaultReformation")
	game.FadeOutGame(true,true, 0.0, 1.0)
	
	Actor reviver = GetReformationHost()
	if reviver == none || reviver.IsDead() || reviver.IsDisabled()
		Manager.KillPlayer_ForReal()
		return
	endIf
	
	if Manager.IsPrey(reviver)
		Manager.ForceEscape(reviver)
	endIf

	Manager.RegisterReformation(reviver, PlayerRef, 0)
	game.FadeOutGame(false,true, 4.0, 1.0)
EndFunction


Function SendReformationEvent()
	Log0(PREFIX, "SendReformationEvent")
	
	int handle = ModEvent.create("Devourment_Reformation")
	ModEvent.PushForm(handle, self)
	ModEvent.send(handle)
EndFunction


Function RegisterQuest(Quest myReformationQuest)
	Log1(PREFIX, "RegisterQuest", myReformationQuest)

	int indexOfNone = reformationQuests.find(none)
	if indexOfNone < reformationQuests.length
		reformationQuests[indexOfNone] = myReformationQuest
	endIf
EndFunction


Actor Function GetReformationHost()
	Form[] ReformationHosts = PhylacteryList.ToArray()
	int hostIndex = ReformationHosts.length

	while hostIndex
		hostIndex -= 1
		Actor host = ReformationHosts[hostIndex] as Actor

		; Clear any hosts that are dead, disabled, or unfriendly.
		if host
			if host.IsDead() || host.IsDisabled() || !Manager.AreFriends(PlayerRef, host)
				Log2(PREFIX, "GetReformationHost", "Purging dead/disabled/hostile host.", Namer(host))
				PhylacteryList.RemoveAddedForm(host)
			endIf
		endIf
	endWhile

	if PhylacteryList.GetSize() == 0
		return none
	endIf

	hostIndex = Utility.RandomInt(0, PhylacteryList.GetSize() - 1)
	Actor host = PhylacteryList.GetAt(hostIndex) as Actor

	assertNotNone(PREFIX, "GetReformationHost", "host", host)
	assertFalse(PREFIX, "GetReformationHost", "host.IsDead()", host.IsDead())
	assertFalse(PREFIX, "GetReformationHost", "host.IsDisabled()", host.IsDisabled())
	assertTrue(PREFIX, "GetReformationHost", "Manager.AreFriends(PlayerRef, host)", Manager.AreFriends(PlayerRef, host))
	return host
EndFunction


bool Function AddReformationHost(Actor host)
	if !host
		AssertNotNone(PREFIX, "AddReformationHost", "host", host)
		return false
	endIf

	Log1(PREFIX, "AddReformationHost", Namer(host))
	PhylacteryList.AddForm(host)
	return true
endFunction


DevourmentReformationQuest Function instance() global
	{ Returns the DevourmentReformationQuest instance, for situations in which a property isn't helpful (like global functions). }
	return Quest.GetQuest("DevourmentReformationQuest") as DevourmentReformationQuest
EndFunction
