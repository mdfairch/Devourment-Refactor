Scriptname DevourmentConditionalVore extends ActiveMagicEffect
import DevourmentUtil
import Logging


DevourmentManager property Manager auto
Actor property playerRef auto
Keyword property keywordCreature auto
Spell property CorpseSpell auto
Spell property VoreSpell auto
Spell property EndoSpell auto
Faction property Follower auto
float property SwallowRange = 180.0 autoReadOnly


String PREFIX = "DevourmentConditionalVore"


Event OnEffectStart(Actor akTarget, Actor akCaster)
	ObjectReference grabbed = Game.GetPlayerGrabbedRef()
	if grabbed && !(grabbed as Actor)
		Manager.PlayVoreAnimation_Item(akCaster, grabbed, 0, true)
		Manager.DigestItem(akCaster, grabbed, 1, none)
		return
	endIf
	
	ObjectReference crosshairRef = Game.GetCurrentCrosshairRef()
	if crossHairRef == none || !(crosshairRef as Actor) || crosshairRef == akCaster
		return
	endIf
	
	Actor pred = akCaster
	Actor prey = crosshairRef as Actor
	
	if pred.getDistance(prey) > SwallowRange
		return
	endIf
	
	if pred.isSneaking() || Input.IsKeyPressed(Input.GetMappedKey("Sneak")) || pred.hasKeyword(keywordCreature)
		VoreSpell.cast(pred, prey)
	
	elseif areFriends(pred, prey)
		EndoSpell.cast(pred, prey)
		
	elseif areEnemies(pred, prey) || prey.hasKeyword(keywordCreature)
		VoreSpell.cast(pred, prey)

	elseif prey.isInCombat() 
		Actor target = prey.getCombatTarget()
		if target == none || areFriends(pred, target) || !areEnemies(pred, target)
			VoreSpell.cast(pred, prey)
		else
			EndoSpell.cast(pred, prey)
		endIf
	
	else
		EndoSpell.cast(pred, prey)
	endIf
EndEvent


bool Function areFriends(Actor pred, Actor prey)
	if pred == playerRef
		 return prey.getRelationshipRank(pred) > 0 \
		 	|| prey.isPlayerTeammate() \
			|| prey.isInFaction(Follower)
	else
		return prey.getRelationshipRank(pred) > 0
	endif
EndFunction


bool Function areEnemies(Actor pred, Actor prey)
	return pred.isHostileToActor(prey) || prey.isHostileToActor(pred)
EndFunction
