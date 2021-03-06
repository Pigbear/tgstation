//CLOCKCULT PROOF OF CONCEPT
/datum/antagonist/clockcult
	var/datum/action/innate/hierophant/hierophant_network = new()

/datum/antagonist/clockcult/silent
	silent = TRUE

/datum/antagonist/clockcult/Destroy()
	qdel(hierophant_network)
	return ..()

/datum/antagonist/clockcult/on_gain()
	if(!owner)
		return
	var/mob/living/current = owner.current
	if(!istype(current))
		return
	if(jobban_isbanned(current, ROLE_SERVANT_OF_RATVAR))
		addtimer(CALLBACK(SSticker.mode, /datum/game_mode.proc/replace_jobbaned_player, current, ROLE_SERVANT_OF_RATVAR, ROLE_SERVANT_OF_RATVAR), 0)
	owner.current.log_message("<font color=#BE8700>Has been converted to the cult of Ratvar!</font>", INDIVIDUAL_ATTACK_LOG)
	if(issilicon(current))
		var/mob/living/silicon/S = owner
		if(iscyborg(S) && !silent)
			to_chat(S, "<span class='boldwarning'>You have been desynced from your master AI.</span>")
			to_chat(S, "<span class='boldwarning'>In addition, your onboard camera is no longer active and you have gained additional equipment, including a limited clockwork slab.</span>")
		if(isAI(S))
			to_chat(S, "<span class='boldwarning'>You are able to use your cameras to listen in on conversations.</span>")
		to_chat(S, "<span class='heavy_brass'>You can communicate with other servants by using the Hierophant Network action button in the upper left.</span>")
	else if(isbrain(current) || isclockmob(current))
		to_chat(current, "<span class='nezbere'>You can communicate with other servants by using the Hierophant Network action button in the upper left.</span>")
	..()
	SSticker.mode.update_servant_icons_added(owner)
	if(istype(SSticker.mode, /datum/game_mode/clockwork_cult))
		var/datum/game_mode/clockwork_cult/C = SSticker.mode
		C.present_tasks(owner) //Memorize the objectives

/datum/antagonist/clockcult/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	if(istype(mob_override))
		current = mob_override
	GLOB.all_clockwork_mobs += current
	current.faction |= "ratvar"
	current.grant_language(/datum/language/ratvar)
	current.update_action_buttons_icon() //because a few clockcult things are action buttons and we may be wearing/holding them for whatever reason, we need to update buttons
	if(issilicon(current))
		var/mob/living/silicon/S = current
		if(iscyborg(S))
			var/mob/living/silicon/robot/R = S
			R.UnlinkSelf()
			R.module.rebuild_modules()
		else if(isAI(S))
			var/mob/living/silicon/ai/A = S
			A.requires_power = POWER_REQ_CLOCKCULT
			if(!A.lacks_power())
				A.ai_restore_power()
			if(A.eyeobj)
				A.eyeobj.relay_speech = TRUE
			for(var/mob/living/silicon/robot/R in A.connected_robots)
				if(R.connected_ai == A)
					R.visible_message("<span class='heavy_brass'>[R]'s eyes glow a blazing yellow!</span>", \
					"<span class='heavy_brass'>Assist your new companions in their righteous efforts. Your goal is theirs, and theirs yours. You serve the Clockwork Justiciar above all else. Perform his every \
					whim without hesitation.</span>")
					to_chat(R, "<span class='boldwarning'>Your onboard camera is no longer active and you have gained additional equipment, including a limited clockwork slab.</span>")
					add_servant_of_ratvar(R, TRUE)
		S.laws = new/datum/ai_laws/ratvar
		S.laws.associate(S)
		S.update_icons()
		S.show_laws()
		hierophant_network.Grant(S)
		hierophant_network.title = "Silicon"
		hierophant_network.span_for_name = "nezbere"
		hierophant_network.span_for_message = "brass"
	else if(isbrain(current))
		hierophant_network.Grant(current)
		hierophant_network.title = "Vessel"
		hierophant_network.span_for_name = "nezbere"
		hierophant_network.span_for_message = "alloy"
	else if(isclockmob(current))
		hierophant_network.Grant(current)
		hierophant_network.title = "Construct"
		hierophant_network.span_for_name = "nezbere"
		hierophant_network.span_for_message = "brass"
	current.throw_alert("clockinfo", /obj/screen/alert/clockwork/infodump)
	if(!GLOB.clockwork_gateway_activated)
		current.throw_alert("scripturereq", /obj/screen/alert/clockwork/scripture_reqs)
	update_slab_info()


/datum/antagonist/clockcult/remove_innate_effects(mob/living/mob_override)
	var/mob/living/current = owner.current
	if(istype(mob_override))
		current = mob_override
	GLOB.all_clockwork_mobs -= current
	current.faction -= "ratvar"
	current.remove_language(/datum/language/ratvar)
	current.clear_alert("clockinfo")
	current.clear_alert("scripturereq")
	for(var/datum/action/innate/function_call/F in owner.current.actions) //Removes any bound Ratvarian spears
		qdel(F)
	if(issilicon(current))
		var/mob/living/silicon/S = current
		if(isAI(S))
			var/mob/living/silicon/ai/A = S
			A.requires_power = initial(A.requires_power)
		S.make_laws()
		S.update_icons()
		S.show_laws()
	var/mob/living/temp_owner = current
	..()
	if(iscyborg(temp_owner))
		var/mob/living/silicon/robot/R = temp_owner
		R.module.rebuild_modules()
	if(temp_owner)
		temp_owner.update_action_buttons_icon() //because a few clockcult things are action buttons and we may be wearing/holding them, we need to update buttons
	update_slab_info()

/datum/antagonist/clockcult/on_removal()
	. = ..()
	SSticker.mode.update_servant_icons_removed(owner)
	if(!silent)
		owner.current.visible_message("<span class='big'>[owner] seems to have remembered their true allegiance!</span>", \
		"<span class='userdanger'>A cold, cold darkness flows through your mind, extinguishing the Justiciar's light and all of your memories as his servant.</span>")
	owner.current.log_message("<font color=#BE8700>Has renounced the cult of Ratvar!</font>", INDIVIDUAL_ATTACK_LOG)
	if(iscyborg(owner.current))
		to_chat(owner.current, "<span class='warning'>Despite your freedom from Ratvar's influence, you are still irreparably damaged and no longer possess certain functions such as AI linking.</span>")