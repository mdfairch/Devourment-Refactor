ScriptName DevourmentTurnLethal extends ActiveMagicEffect


DevourmentManager property Manager auto


event OnEffectStart(Actor target, Actor caster)
    Manager.SwitchLethalAll(target,true)
endEvent



