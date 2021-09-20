Scriptname DevourmentMegaDigest extends ActiveMagicEffect  
import DevourmentUtil


DevourmentManager Property Manager auto
Perk[] Property StrongAcid auto


Event OnEffectStart(Actor akTarget, Actor akCaster)
	Manager.playBurp_async(akCaster, true)
	actor pred = akCaster
	Form[] stomach = Manager.GetStomachArray(pred)
	int stomachIndex = stomach.length
	
	While stomachIndex
		stomachIndex -= 1
		ObjectReference content = stomach[stomachIndex] as ObjectReference
		int PreyData = manager.GetPreyData(content)
		Actor contentActor = content as actor

		if Manager.isAlive(PreyData)
			float Damage = contentActor.getActorValue("Health") - 1
			Damage *= Manager.GetPerkMultiplier(pred, Manager.Menu.StrongAcid_arr, 0.0, 0.333)
			Manager.Gurgle.play(pred)
			contentActor.DamageActorValue("Health", Damage)
			manager.switchlethal(contentActor, true)
		endif
	endWhile
EndEvent