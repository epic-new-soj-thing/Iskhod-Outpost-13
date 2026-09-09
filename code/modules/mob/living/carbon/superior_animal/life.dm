/mob/living/carbon/superior/proc/check_AI_act()
	if ((stat != CONSCIOUS) || !canmove || resting || lying || stasis || client || grabbed_by_friend)
		stance = HOSTILE_STANCE_IDLE
		target_mob = null
		lost_sight = FALSE
		target_location = null
		SSmove_manager.stop_looping(src)
		return

	return TRUE

/*

/mob/living/carbon/superior/Life()
	. = ..()

	moved = FALSE

	objectsInView = null

	if(client || AI_inactive)
		return

	if (!check_AI_act())
		return

	var/has_looked_for_target = FALSE
	var/atom/found_target_this_tick = null
	var/target_dist = 0
	var/computed_glide_size = DELAY2GLIDESIZE(move_to_delay)

	if(stance == HOSTILE_STANCE_IDLE)
		if (!busy)
			stop_automated_movement = 0
		found_target_this_tick = findTarget()
		has_looked_for_target = TRUE
		target_mob = found_target_this_tick
		if (found_target_this_tick)
			stance = HOSTILE_STANCE_ATTACK
			target_dist = get_dist(src, found_target_this_tick)
	else if (target_mob)
		target_dist = get_dist(src, target_mob)

	if(stance == HOSTILE_STANCE_ATTACK)
		if(destroy_surroundings)
			destroySurroundings()
		if(!ranged)
			stop_automated_movement = 1
			stance = HOSTILE_STANCE_ATTACKING
			set_glide_size(computed_glide_size)
			walk_to(src, target_mob, 1, move_to_delay)
			moved = 1
		else // ranged
			stop_automated_movement = 1
			if(target_dist <= comfy_range)
				stance = HOSTILE_STANCE_ATTACKING
				return
			else
				set_glide_size(computed_glide_size)
				walk_to(src, target_mob, 4, move_to_delay)
			stance = HOSTILE_STANCE_ATTACKING

	if(stance == HOSTILE_STANCE_ATTACKING)
		if(destroy_surroundings)
			destroySurroundings()
		if(!ranged)
			prepareAttackOnTarget()
		else // ranged
			if(target_dist <= 6)
				OpenFire(target_mob)
			else
				set_glide_size(computed_glide_size)
				walk_to(src, target_mob, 4, move_to_delay)
				OpenFire(target_mob)

	//random movement
	if(wander && !stop_automated_movement && !anchored && isturf(src.loc) && !resting && !buckled && canmove)
		turns_since_move++
		if(turns_since_move >= turns_per_move)
			if(!(stop_automated_movement_when_pulled && pulledby))
				var/moving_to = pick(cardinal)
				set_dir(moving_to)
				step_glide(src, moving_to, DELAY2GLIDESIZE(0.5 SECONDS))
				turns_since_move = 0

	//Speaking
	if(speak_chance && prob(speak_chance))
		visible_emote(emote_see)

	var/atom/final_target_check = (has_looked_for_target ? found_target_this_tick : findTarget())

	if(following && !final_target_check) [cite: 3]
		walk_to(src, following, follow_distance, move_to_delay) [cite: 3]

	if(!following && !final_target_check) [cite: 4]
		walk_to(src, 0) [cite: 4]

*/

/mob/living/carbon/superior/handle_chemicals_in_body()
	if(reagent_immune)
		return FALSE
	if(reagents)
		chem_effects.Cut()

		//If a mob dosnt have one of these then something is wrong with that mob!
		touching.metabolize()
		ingested.metabolize()
		bloodstr.metabolize()

		metabolism_effects.process()

	if(status_flags & GODMODE)
		return FALSE

	if(stat != DEAD)
		return FALSE

	var/turf/T = loc
	if(light_dam && isturf(T))
		var/light_amount = round((T.get_lumcount() * 10) - 5)

		if(light_amount > light_dam)
			take_overall_damage(1,1)
		else
			heal_overall_damage(1,1)

	// nutrition decrease
	if(hunger_factor && nutrition > 0)
		nutrition = max(0, nutrition - hunger_factor)

	updatehealth()
