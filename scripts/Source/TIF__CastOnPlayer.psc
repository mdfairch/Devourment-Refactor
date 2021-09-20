ScriptName TIF__CastOnPlayer extends TopicInfo hidden


Spell property SpellToCast = none auto
Spell property CasterSpellToAdd = none auto
Spell property TargetSpellToAdd = none auto


Function Fragment_0(ObjectReference akSpeakerRef)
	castNow(Game.getPlayer(), akSpeakerRef as Actor)
endFunction


Function Fragment_1(ObjectReference akSpeakerRef)
	castNow(Game.getPlayer(), akSpeakerRef as Actor)
endFunction


Function castNow(Actor target, Actor caster)
	if SpellToCast != none
		SpellToCast.Cast(target, caster)
	endIf
	
	if TargetSpellToAdd != none
		target.addSpell(TargetSpellToAdd)
	endif
	
	if CasterSpellToAdd != none
		caster.addSpell(CasterSpellToAdd)
	endif
EndFunction
