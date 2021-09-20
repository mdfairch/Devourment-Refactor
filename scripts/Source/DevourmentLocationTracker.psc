scriptName DevourmentLocationTracker extends ActiveMagicEffect
{
	Every 2 seconds the target is moved to a position 2800 units away from their pred.
	The effect only runs outside of dialog and when the target is in a loaded cell.
}
import Logging


bool DEBUGGING = false

Actor property PlayerRef auto
Cell property StomachCell auto
DevourmentManager Property Manager auto
DevourmentDialog property DialogQuest auto
String PREFIX = "DevourmentLocationTracker"
float property UpdateInterval = 2.0 autoreadonly


bool translationSystem = true
bool dead = false
Cell OwnedCell = none
Actor subject
ActorBase OwnedCellOwner1 = none
Faction OwnedCellOwner2 = none


float distanceMove = 250.0
float distanceTooClose = 200.0
float distanceTooFar = 600.0


event OnEffectStart(Actor target, Actor caster)
{ Event received when this effect is first started (OnInit may not have been run yet!) }
	subject = target

	if DEBUGGING
		Log1(PREFIX, "OnEffectStart", Namer(subject))
	endIf

	;MoveSubject(apex)
	RegisterForSingleUpdate(0.05)

	if subject.IsSneaking()
		Debug.SendAnimationEvent(subject, "SneakStop")
	endIf
endEvent


event OnEffectFinish(Actor target, Actor caster)
	{ Event received when this effect ends. }
	if DEBUGGING
		Log0(PREFIX, "OnEffectFinish")
	endIf
	
	subject.stopTranslation()
	ResetCellOwners()
EndEvent


Event OnCombatStateChanged(Actor newTarget, int aeCombatState)
	if DEBUGGING
		Log1(PREFIX, "OnCombatStateChanged", "Stopping combat.")
		ConsoleUtil.PrintMessage("Stopping Combat")
	endIf

	subject.stopCombatAlarm()
	subject.stopCombat()
endEvent 


Event OnCellAttach()
	if subject == PlayerRef && PlayerRef.IsTrespassing()
		if DEBUGGING
			Log1(PREFIX, "OnCellAttach", "Preventing Trespass alarm from going off.")
			ConsoleUtil.PrintMessage("Preventing Trespass alarm from going off.")
		endIf
		StoreCellOwners()
	endIf
EndEvent


Event OnCellDetach()
	if subject == PlayerRef
		ResetCellOwners()
	endIf
EndEvent 


Event onUpdate()
{ Called repeatedly whenever the prey is in a loaded cell and not in dialogue. }

	if dead
		return
	endIf
	
	Actor apex = Manager.FindApex(subject)
	float distance = subject.GetDistance(apex)
	Cell apexCell = apex.getParentCell()
	Cell subjectCell = subject.getParentCell()

	if Game.GetDialogueTarget() != none || DialogQuest.Activated
		if DEBUGGING
			Log1(PREFIX, "OnUpdate", "In dialogue -- skipping player relocation.")
		endIf

	else
		if Manager.DEBUGGING
			Log4(PREFIX, "OnUpdate", Namer(apex), Namer(apexCell), Namer(subjectCell), distance)
		endIf

		if apexCell != subjectCell && (apexCell.IsInterior() || subjectCell.IsInterior())	
			if DEBUGGING
				Log1(PREFIX, "onUpdate", "Relocating Player to Pred's cell.")
			endIf
			ConsoleUtil.PrintMessage("Relocating Player to Pred's location.")
			MoveSubject(apex, cellChange = true)

		elseif distance > distanceTooFar || distance < distanceTooClose
			if DEBUGGING
				Log1(PREFIX, "onUpdate", "Relocating Player to an appropriate distance.")
			endIf
			MoveSubject(apex)
		endIf
	endIf
	
	RegisterForSingleUpdate(UpdateInterval)
endEvent


Event OnDeath(Actor akKiller)
	{ Event that is triggered when this actor finishes dying. }
	Log1(PREFIX, "OnDeath", "Player died!")
	dead = true
EndEvent


Event OnDying(Actor akKiller)
	{ Event that is triggered when this actor begins to die. }
	Log1(PREFIX, "OnDying", "Player dying!")
EndEvent


Function StoreCellOwners()
	ResetCellOwners()
	
	OwnedCell = PlayerRef.GetParentCell()
	if OwnedCell
		OwnedCellOwner1 = OwnedCell.GetActorOwner()
		OwnedCellOwner2 = OwnedCell.GetFactionOwner()
		Log3(PREFIX, "StoreCellOwners", Namer(OwnedCell), Namer(OwnedCellOwner1), Namer(OwnedCellOwner2))
	endIf
EndFunction


Function ResetCellOwners()
	if OwnedCell
		Log3(PREFIX, "ResetCellOwners", Namer(OwnedCell), Namer(OwnedCellOwner1), Namer(OwnedCellOwner2))
		OwnedCell.SetActorOwner(OwnedCellOwner1)
		OwnedCell.SetFactionOwner(OwnedCellOwner2)
		OwnedCell = none
		OwnedCellOwner1 = none
		OwnedCellOwner2 = none
	endIf
EndFunction


Function MoveSubject(ObjectReference center, bool cellChange = false)
	if translationSystem && !cellChange
		float px = center.GetPositionX() - distanceMove
		float py = center.GetPositionY() - distanceMove
		float pz = center.GetPositionZ()
		subject.stopTranslation()
		subject.SetPosition(px, py, pz)
		subject.TranslateTo(px, py, pz + 20.0, 0.0, 0.0, 0.0, 0.01)
	else
		subject.moveTo(center, -distanceMove, -distanceMove)
	endIf
EndFunction
