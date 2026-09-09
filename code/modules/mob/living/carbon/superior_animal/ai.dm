//NOTE: Don't use this proc for finding specific mobs or a very certain object;
//utilize GLOBs instead of view()/mob/living/carbon/superior/proc/getObjectsInView()
/mob/living/carbon/superior/proc/getObjectsInView()
	objectsInView = objectsInView || view(src, viewRange)
	return objectsInView

//Use this for all mobs per zlevel, get_dist() checked
/mob/living/carbon/superior/proc/getPotentialTargets()
	var/turf/T = get_turf(src)
	if(!T)
		return //We're contained inside something, a locker perhaps.
	return hearers(src, viewRange)

/mob/living/carbon/superior/proc/findTarget(prioritizeCurrent = FALSE)
	if (prioritizeCurrent && target_mob && prob(retarget_chance))
		return //if we already have a target_mob and we want to not untarget, lets just return

	var/turf/our_turf = get_turf(src)
	if (!our_turf)
		return

	var/list/filteredTargets = list()

	// 1. Process living mobs using highly optimized hearer lists
	for(var/mob/living/target_m in hearers(viewRange, src))
		if(!(target_m.faction == faction && !attack_same) && isValidAttackTarget(target_m))
			if(target_m.target_dummy && prioritize_dummies) //Target me over anyone else
				return target_m
			filteredTargets += target_m

	// 2. Scan machinery using a single type-filtered view call
	for(var/obj/machinery/M in view(viewRange, src))
		if(istype(M, /obj/machinery/tesla_turret) || istype(M, /obj/machinery/porta_turret) || istype(M, /obj/machinery/power/os_turret))
			if(isValidAttackTarget(M))
				filteredTargets += M

	// 3. Scan mechas from the global registry
	for(var/obj/mecha/M in GLOB.mechas_list)
		if(M.z == z && get_dist(src, M) <= viewRange)
			if(isValidAttackTarget(M))
				filteredTargets += M

	var/atom/filteredTarget = safepick(getTargets(filteredTargets, src))

	if (filteredTarget && filteredTarget != target_mob)
		doTargetMessage()

	if (filteredTarget)
		target_location = WEAKREF(get_turf(filteredTarget))

	return filteredTarget

/// Returns a list of objects, using a method dependant on the prioritization_type var of the mob.
/mob/living/carbon/superior/proc/getTargets(list/L, sourceLocation)
	if (L.len == 1)
		return L.Copy()

	switch(prioritization_type)
		if (RANDOM)
			return L
		if (CLOSEST)
			return getClosestObjects(L, sourceLocation, viewRange)
		if (FURTHEST)
			return getFurthestObjects(L, sourceLocation, viewRange)

/mob/living/carbon/superior/proc/attemptAttackOnTarget()
	var/atom/targetted_mob = (target_mob?.resolve())

	if(weakened || isnull(targetted_mob) || !Adjacent(targetted_mob))
		return

	return UnarmedAttack(targetted_mob, 1)

/mob/living/carbon/superior/proc/prepareAttackOnTarget()
	var/atom/targetted_mob = (target_mob?.resolve())

	if(weakened || isnull(targetted_mob))
		return

	stop_automated_movement = 1

	if (!isValidAttackTarget(targetted_mob))
		loseTarget()
		return

	if ((get_dist(src, targetted_mob) >= viewRange) || (z != targetted_mob.z && !istype(targetted_mob, /obj/mecha)))
		loseTarget()
		return

	if (check_if_alive())
		if (prepareAttackPrecursor(MELEE_TYPE, FALSE, FALSE, targetted_mob))
			addtimer(CALLBACK(src, PROC_REF(attemptAttackOnTarget)), delay_for_melee)

/mob/living/carbon/superior/proc/loseTarget(stop_pursuit = TRUE, simply_losetarget = FALSE)
	if (stop_pursuit)
		stop_automated_movement = 0
		if (move_packet)
			var/datum/move_loop/our_loop = move_packet.existing_loops[SSmovement]
			if (our_loop && our_loop.priority < MOVEMENT_PATHMODE_PRIORITY)
				SSmove_manager.stop_looping(src)
	if (!simply_losetarget)
		fire_delay = fire_delay_initial
		melee_delay = melee_delay_initial
		patience = patience_initial
		retarget_timer = retarget_timer_initial
		stance = HOSTILE_STANCE_IDLE
		delayed = delayed_initial
	lost_sight = FALSE
	target_mob = null
	target_location = null

/mob/living/carbon/superior/proc/isValidAttackTarget(atom/O)
	if (isliving(O))
		var/mob/living/L = O
		if(L.stat != CONSCIOUS)
			return FALSE
		//If we are standing well below crit, then it is still a threat
		if(L.health <= (ishuman(L) ? HEALTH_THRESHOLD_CRIT : 0) && resting)
			return FALSE
		if((L.friendly_to_colony && friendly_to_colony) || L.mob_size == MOB_MINISCULE)
			return FALSE
		return TRUE

	if (istype(O, /obj/mecha))
		if (can_see(src, O, get_dist(src, O))) //can we even see it?
			var/obj/mecha/M = O
			return isValidAttackTarget(M.occupant)

	if (istype(O, /obj/machinery/tesla_turret))
		var/obj/machinery/tesla_turret/TT = O
		if(TT.stat & (BROKEN | NOPOWER))
			return FALSE
		if(TT.colony_allied_turret == friendly_to_colony) // Simplified true/true and false/false flags
			return FALSE
		return TRUE

	if (istype(O, /obj/machinery/power/os_turret))
		var/obj/machinery/power/os_turret/OST = O
		if(OST.faction_iff == faction)
			return FALSE
		if(OST.stat & (BROKEN | NOPOWER))
			return FALSE
		if(!OST.should_target_players && friendly_to_colony)
			return FALSE
		return TRUE

	if (istype(O, /obj/machinery/porta_turret))
		var/obj/machinery/porta_turret/PO = O
		if(PO.faction_iff == faction)
			return FALSE
		if(PO.stat & (BROKEN | NOPOWER))
			return FALSE
		if(PO.colony_allied_turret == friendly_to_colony)
			return FALSE
		return TRUE

	return FALSE

/mob/living/carbon/superior/proc/destroySurroundings()
	if (!prob(break_stuff_probability))
		return

	// Scan loc contents in a single pass while respecting original priorities
	var/obj/machinery/door/window/found_windoor
	for (var/obj/obstacle in loc)
		if (istype(obstacle, /obj/structure/window))
			obstacle.attack_generic(src, rand(melee_damage_lower, melee_damage_upper), pick(attacktext))
			return
		if (!found_windoor && istype(obstacle, /obj/machinery/door/window))
			found_windoor = obstacle
	if (found_windoor)
		found_windoor.attack_generic(src, rand(melee_damage_lower, melee_damage_upper), pick(attacktext))
		return

	// Directional sweeping utilizing cached turf structures and dynamic prioritization weights
	for (var/dir in cardinal)
		var/turf/T = get_step(src, dir)
		if (!T)
			continue

		var/obj/best_obstacle
		var/best_priority = 99

		for (var/obj/obstacle in T)
			if (istype(obstacle, /obj/structure/window))
				var/obj/structure/window/W = obstacle
				if (W.is_full_window() || W.dir == reverse_dir[dir])
					best_obstacle = W
					best_priority = 1
					break // Absolute top priority found, exit object loop early

			else if (istype(obstacle, /obj/machinery/door/window))
				var/obj/machinery/door/window/W = obstacle
				if (W.dir == reverse_dir[dir] && best_priority > 2)
					best_obstacle = W
					best_priority = 2

			else if (istype(obstacle, /obj/structure/closet))
				var/obj/structure/closet/C = obstacle
				if ((C.opened == FALSE || C.density == TRUE) && best_priority > 3)
					best_obstacle = C
					best_priority = 3

			else if (istype(obstacle, /obj/structure/table))
				var/obj/structure/table/Tab = obstacle
				if (Tab.density == TRUE && best_priority > 4)
					best_obstacle = Tab
					best_priority = 4

			else if (istype(obstacle, /obj/structure/low_wall))
				var/obj/structure/low_wall/LW = obstacle
				if (LW.density == TRUE && best_priority > 5)
					best_obstacle = LW
					best_priority = 5

			else if (istype(obstacle, /obj/structure/girder))
				var/obj/structure/girder/G = obstacle
				if (G.density == TRUE && best_priority > 6)
					best_obstacle = G
					best_priority = 6

			else if (istype(obstacle, /obj/structure/railing))
				var/obj/structure/railing/R = obstacle
				if (R.density == TRUE && best_priority > 7)
					best_obstacle = R
					best_priority = 7

			else if (istype(obstacle, /obj/mecha))
				var/obj/mecha/M = obstacle
				if (M.density == TRUE && best_priority > 8)
					best_obstacle = M
					best_priority = 8

			else if (istype(obstacle, /obj/structure/barricade))
				var/obj/structure/barricade/B = obstacle
				if (B.density == TRUE && best_priority > 9)
					best_obstacle = B
					best_priority = 9

			else if (istype(obstacle, /obj/machinery/deployable))
				var/obj/machinery/deployable/D = obstacle
				if (D.density == TRUE && best_priority > 10)
					best_obstacle = D
					best_priority = 10

			else if (istype(obstacle, /obj/structure/grille))
				var/obj/structure/grille/G = obstacle
				if (G.density == TRUE && best_priority > 11)
					best_obstacle = G
					best_priority = 11

			else if (istype(obstacle, /obj/machinery/door))
				var/obj/machinery/door/D = obstacle
				if (D.density == TRUE && best_priority > 12)
					best_obstacle = D
					best_priority = 12

			else if (istype(obstacle, /obj/structure/plasticflaps))
				var/obj/structure/plasticflaps/P = obstacle
				if (P.density == TRUE && best_priority > 13)
					best_obstacle = P
					best_priority = 13

			else if (istype(obstacle, /obj/structure/shield_deployed) && best_priority > 14)
				best_obstacle = obstacle
				best_priority = 14

			else if (istype(obstacle, /obj/machinery/tesla_turret))
				var/obj/machinery/tesla_turret/TT = obstacle
				if (TT.density == TRUE && best_priority > 15)
					best_obstacle = TT
					best_priority = 15

		if (best_obstacle)
			var/damage = rand(melee_damage_lower, melee_damage_upper)
			if (best_priority == 5)
				damage *= 3 // Multiplier for low walls
			else if (best_priority == 6)
				damage *= 2 // Multiplier for girders

			best_obstacle.attack_generic(src, damage, pick(attacktext))
			return

/mob/living/carbon/superior/hear_say(var/message, var/verb = "says", var/datum/language/language = null, var/alt_name = "", var/italics = 0, var/mob/living/speaker = null, var/sound/speech_sound, var/sound_vol, speech_volume)
	..()
	if(obey_check(speaker) && findtext(message, name))
		if(!following && !anchored && findtext(message, "Follow"))
			following = speaker
			last_followed = speaker
			visible_emote("[follow_message]")
		else if(following && findtext(message, "Stop"))
			following = null
			visible_emote("[stop_message]")

// Check if we obey the person talking.
/mob/living/carbon/superior/proc/obey_check(var/mob/living/speaker = null)
	return (!obey_friends || (speaker in friends))

//Putting this here due to no idea where it would fit other than here
/mob/living/carbon/superior/verb/toggle_AI()
	set name = "Toggle AI"
	set desc = "Toggles on/off the mobs AI."
	set category = "Mob verbs"

	if (AI_inactive)
		activate_ai()
		to_chat(src, SPAN_NOTICE("You toggle the mobs default AI to ON."))
	else
		AI_inactive = TRUE
		to_chat(src, SPAN_NOTICE("You toggle the mobs default AI to OFF."))

/**
 * Signal handler. Called whenever a superior mob is attacked.
 * On base, will target the mob that attacked them if they don't currently have a target.
 **/
/mob/living/carbon/superior/proc/react_to_attack(var/mob/living/carbon/superior/source = src, var/obj/item/attacked_with, var/atom/attacker, params)
	SIGNAL_HANDLER

	if (attacked_with && isprojectile(attacked_with))
		var/obj/item/projectile/Proj = attacked_with
		if (Proj.testing)
			return FALSE

	if (!react_to_attack || !attacker || target_mob)
		return FALSE

	if (isValidAttackTarget(attacker))
		var/atom/new_target = attacker
		var/atom/new_target_location = get_turf(attacker)
		var/distance = get_dist(src, attacker)

		if (distance > viewRange)
			new_target_location = target_outside_of_view_range(attacker, distance)

		target_mob = WEAKREF(new_target)
		target_location = WEAKREF(new_target_location)
		lost_sight = TRUE

		if (retaliation_type && (retaliation_type & APPROACH_ATTACKER) && stat != DEAD)
			INVOKE_ASYNC(SSmove_manager, /datum/controller/subsystem/move_manager/proc/move_to, src, target_location, (comfy_range - comfy_distance), move_to_delay)

/mob/living/carbon/superior/proc/movement_tech()
	moved = TRUE
