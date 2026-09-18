// superior_animal and definition moved to superior_defines.dm
/mob/living/carbon/superior/New()
	..()
	blood_color = bloodcolor
	flesh_color = fleshcolor
	if(!icon_living)
		icon_living = icon_state
	if(!icon_dead)
		icon_dead = "[icon_state]_dead"

	objectsInView = new

	full_reload_message  = "[reload_message]"
	reload_message = "[name] [full_reload_message]"

	remove_verb(src, /mob/verb/observe)
	pixel_x = RAND_DECIMAL(-randpixel, randpixel)
	pixel_y = RAND_DECIMAL(-randpixel, randpixel)

	GLOB.superior_animal_list += src

	for(var/language as anything in known_languages)
		add_language(language)

/mob/living/carbon/superior/get_blood_data()
	var/data = ..()
	data["species"] = type // Unique for each mob path
	data["blood_group"] = "superior_animal" // Prevent matching with human groups
	data["blood_DNA"] = md5("[type]")
	data["blood_type"] = "A+" // Doesn't matter, species and group won't match, but provide fallback
	return data

/mob/living/carbon/superior/Initialize(var/mapload)
	if (get_stat_modifier && allowed_stat_modifiers)
		var/list/mods_to_remove = list()
		for (var/key as anything in allowed_stat_modifiers)
			var/datum/stat_modifier/mod = key
			var/tags = initial(mod.stattags)
			if (tags & (NOTHING_STATTAG | DEFENSE_STATTAG))
				continue
			if (!(tags & MELEE_STATTAG) && !ranged)
				mods_to_remove += mod
				continue
			if (!(tags & RANGED_STATTAG) && ranged)
				mods_to_remove += mod
				continue
		if(mods_to_remove.len)
			allowed_stat_modifiers -= mods_to_remove

	.=..()
	if (mapload && can_burrow)
		find_or_create_burrow(get_turf(src))
		if (prob(extra_burrow_chance))
			create_burrow(get_turf(src))

	if(move_and_attack)
		RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(movement_tech))

	RegisterSignal(src, COMSIG_ATTACKED, PROC_REF(react_to_attack))

/mob/living/carbon/superior/Destroy()
	GLOB.superior_animal_list -= src
	target_mob = null

	LAZYCLEARLIST(objectsInView)
	LAZYCLEARLIST(friends)

	UnregisterSignal(src, COMSIG_ATTACKED)
	lastarea = null
	known_languages = null
	. = ..()

/mob/living/carbon/superior/u_equip(obj/item/W as obj)
	return

/mob/living/carbon/superior/proc/visible_emote(message)
	if(islist(message))
		message = safepick(message)
	if(message)
		visible_message("<span class='name'>[src]</span> [message]")

/mob/living/carbon/superior/update_icons()
	. = ..()
	if (stat == DEAD)
		icon_state = icon_dead
	else if ((stat == UNCONSCIOUS) || resting || lying)
		if (icon_rest)
			icon_state = icon_rest
		else if (icon_living)
			icon_state = icon_living
		add_new_transformation(/datum/transform_type/prone)
	else
		remove_transformation(PRONE_TRANSFORM)
		if (icon_living)
			icon_state = icon_living

/mob/living/carbon/superior/regenerate_icons()
	. = ..()
	update_icons()

/mob/living/carbon/superior/updateicon()
	. = ..()

/mob/living/carbon/superior/examine(mob/user)
	..()
	if (is_dead(src))
		to_chat(user, SPAN_DANGER("It is completely motionless, likely dead."))
		return

	if(!maxHealth)
		return

	var/health_ratio = health / maxHealth
	if (health_ratio < 0.10)
		to_chat(user, SPAN_DANGER("It looks like they are on their last legs!"))
	else if (health_ratio < 0.20)
		to_chat(user, SPAN_DANGER("It's grievously wounded!"))
	else if (health_ratio < 0.30)
		to_chat(user, SPAN_DANGER("It's badly wounded!"))
	else if (health_ratio < 0.40)
		to_chat(user, SPAN_WARNING("Its wounds are mounting."))
	else if (health_ratio < 0.50)
		to_chat(user, SPAN_WARNING("It looks half dead."))
	else if (health_ratio < 0.60)
		to_chat(user, SPAN_WARNING("It looks like its been beaten up quite badly."))
	else if (health_ratio < 0.70)
		to_chat(user, SPAN_WARNING("It has accrued some lasting injuries."))
	else if (health_ratio < 0.80)
		to_chat(user, SPAN_WARNING("It has had minor damage done to it."))
	else if (health_ratio < 1.0)
		to_chat(user, SPAN_WARNING("It has a few cuts and bruses."))

/mob/living/carbon/superior/proc/target_outside_of_view_range(var/atom/target, distance = get_dist(src, target), target_mode = target_out_of_sight_mode)
	var/tiles_out_of_viewrange = (distance - viewRange)
	if (tiles_out_of_viewrange <= 0)
		return FALSE

	var/list/possible_locations
	switch (target_mode)
		if (ALWAYS_SEE)
			return target

		if (GUESS_LOCATION_WITH_AURA)
			possible_locations = RANGE_TURFS(tiles_out_of_viewrange, target)

		if (GUESS_LOCATION_WITH_LINE, GUESS_LOCATION_WITH_END_OF_LINE)
			var/turf/viewrange_edge = get_turf_at_edge_of_viewRange(target)
			possible_locations = get_turfs_in_line_toward_target(viewrange_edge, target, out_of_viewrange_line_distance_mult)

			if (target_mode == GUESS_LOCATION_WITH_END_OF_LINE)
				if (out_of_sight_turf_LOS_check && possible_locations)
					for (var/i = possible_locations.len, i > 0, i--)
						var/atom/possible_location = possible_locations[i]
						if (can_see(possible_location, target, get_dist(possible_location, target)))
							return possible_location
				return possible_locations ? possible_locations[possible_locations.len] : null

	if (!possible_locations)
		return null

	var/list/filtered_locations = list()
	for (var/turf/possible_location as anything in possible_locations)
		if (possible_location.density)
			continue
		if (out_of_sight_turf_LOS_check && !(can_see(possible_location, target, get_dist(possible_location, target))))
			continue

		var/has_dense_content = FALSE
		for (var/atom/movable/entity in possible_location)
			if (entity.density)
				has_dense_content = TRUE
				break
		if (has_dense_content)
			continue

		filtered_locations += possible_location

	return safepick(filtered_locations)

/mob/living/carbon/superior/proc/cheap_incapacitation_check()
	return stunned > 0 || weakened > 0 || resting || pinned.len > 0 || stat || paralysis || sleeping || (status_flags & FAKEDEATH) || buckled() > 0

/mob/living/carbon/superior/proc/adjustFiringOffset(var/value)
	current_firing_offset += value
	return TRUE

/mob/living/carbon/superior/proc/resetFiringOffset()
	current_firing_offset = initial_firing_offset
	return TRUE

/mob/living/carbon/superior/proc/handle_ai()
	if(weakened || ckey || AI_inactive)
		return

	objectsInView = null

	if (!check_AI_act())
		return

	var/atom/targetted_mob = target_mob?.resolve()
	if (!targetted_mob || !targetted_mob.check_if_alive(TRUE))
		loseTarget()
		targetted_mob = null

	switch(stance)
		if(HOSTILE_STANCE_IDLE)
			if (!busy)
				stop_automated_movement = FALSE
			if (!targetted_mob)
				target_mob = WEAKREF(findTarget())
				targetted_mob = target_mob?.resolve()
			if (targetted_mob)
				stance = HOSTILE_STANCE_ATTACK
				handle_hostile_stance(targetted_mob)

		if(HOSTILE_STANCE_ATTACK)
			handle_hostile_stance(targetted_mob)

		if(HOSTILE_STANCE_ATTACKING)
			if (delayed <= 0)
				delayed = delayed_initial
				handle_attacking_stance(targetted_mob)
			else
				delayed--

	//random movement
	if(wander && !stop_automated_movement && !anchored && isturf(loc) && !resting && !buckled && canmove)
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

/mob/living/carbon/superior/proc/handle_hostile_stance(var/atom/targetted_mob)
	var/already_destroying_surroundings = FALSE
	var/calculated_walk = (comfy_range - comfy_distance)
	var/can_see = TRUE

	if(destroy_surroundings)
		destroySurroundings()
		already_destroying_surroundings = TRUE

	var/mob/living/targetted_mob_real = isliving(targetted_mob) ? targetted_mob : null

	if (!(can_see_check(targetted_mob, targetted_mob_real)))
		can_see = FALSE
		lost_sight = TRUE

	var/atom/targetted = can_see ? targetted_mob : target_location?.resolve()

	if(ranged)
		stop_automated_movement = TRUE
		stance = HOSTILE_STANCE_ATTACKING
		set_glide_size(DELAY2GLIDESIZE(move_to_delay))
		if (stat != DEAD)
			SSmove_manager.move_to(src, targetted_mob, calculated_walk, move_to_delay)

		if (delayed > 0)
			if (retarget_rush_timer <= world.time)
				visible_message(SPAN_WARNING("[src] [target_telegraph] <font color = 'green'>[targetted]</font>!"), target = targetted, message_target = always_telegraph_to_target)
				delayed--
				return
			else
				visible_message(SPAN_WARNING("[src] [rush_target_telegraph] <font color = 'green'>[targetted]</font>!"), target = targetted, message_target = always_telegraph_to_target)
	else
		stop_automated_movement = TRUE
		stance = HOSTILE_STANCE_ATTACKING
		set_glide_size(DELAY2GLIDESIZE(move_to_delay))
		if (stat != DEAD)
			SSmove_manager.move_to(src, targetted_mob, 1, move_to_delay)

	handle_attacking_stance(targetted_mob, already_destroying_surroundings, can_see, TRUE)

/mob/living/carbon/superior/proc/handle_attacking_stance(var/atom/targetted_mob, var/already_destroying_surroundings = FALSE, can_see = TRUE, ran_see_check = FALSE)
	var/calculated_walk = (comfy_range - comfy_distance)
	var/fire_through_lost_sight = FALSE
	var/mob/living/targetted_mob_real = null
	var/obj/item/projectile/trace

	retarget_rush_timer += (world.time + retarget_rush_timer_increment)
	if(destroy_surroundings && !already_destroying_surroundings)
		destroySurroundings()

	if (!isburrow(targetted_mob))
		if (ismob(targetted_mob))
			targetted_mob_real = targetted_mob
		else if (ismecha(targetted_mob))
			var/obj/mecha/targetted_mecha = targetted_mob
			if (targetted_mecha.occupant && ismob(targetted_mecha.occupant))
				targetted_mob_real = targetted_mecha.occupant

		if (!ran_see_check)
			can_see = can_see_check(targetted_mob, targetted_mob_real)

		if (can_see)
			lost_sight = FALSE
			target_location = WEAKREF(get_turf(targetted_mob))

		var/atom/target_location_resolved = target_location?.resolve()

		if (retarget)
			var/retarget_prioritize = retarget_prioritize_current
			if (retarget_timer <= 0)
				if (!can_see)
					retarget_prioritize = FALSE
				var/target_mob_cache = target_mob
				target_mob = WEAKREF(findTarget(retarget_prioritize))
				retarget_timer = retarget_timer_initial
				if (!target_mob)
					target_mob = target_mob_cache
				else if (target_mob != target_mob_cache)
					lost_sight = FALSE
				targetted_mob = target_mob?.resolve()
			else
				retarget_timer--

		if (!can_see)
			if (patience <= 0)
				loseTarget()
				patience = patience_initial
				return
			else
				lost_sight = TRUE
				patience--

				if (wander_if_lost_sight)
					var/moving_to = pick(cardinal)
					set_dir(moving_to)
					step_glide(src, moving_to, DELAY2GLIDESIZE(0.5 SECONDS))
			if (fire_through_walls)
				fire_through_lost_sight = TRUE
		else
			lost_sight = FALSE

		if (projectiletype && advance && (can_see || advance_if_cant_see))
			if (ranged)
				trace = check_trajectory_raytrace(targetted_mob, src, projectiletype)
				spawn(0)
				handle_trace_impact(trace, delete_trace = FALSE)

		var/atom/targetted = lost_sight ? target_location_resolved : targetted_mob
		if (!targetted_mob || !targetted_mob.check_if_alive(TRUE))
			loseTarget()
			return

		if (stat == DEAD)
			return

		if(!ranged)
			prepareAttackOnTarget()
			if (stat != DEAD)
				SSmove_manager.move_to(src, targetted, 1, move_to_delay)
		else
			var/distance = get_dist(src, targetted)
			if (stat == DEAD)
				return

			var/shoot = TRUE
			if (targetted == target_location_resolved)
				if (distance > viewRange)
					var/turf/viewrange_edge = get_turf_at_edge_of_viewRange(targetted)
					if (viewrange_edge?.opacity || !can_see_check(viewrange_edge))
						if (!fire_through_walls)
							shoot = FALSE
				else if (!fire_through_walls)
					shoot = FALSE
			else if (targetted == targetted_mob && !can_see && !fire_through_lost_sight)
				shoot = FALSE

			if (shoot && prepareAttackPrecursor(RANGED_TYPE, TRUE, TRUE, targetted))
				if(!QDELETED(src))
					addtimer(CALLBACK(src, PROC_REF(OpenFire), targetted, trace), delay_for_range)

			if (advancement_timer <= world.time)
				if (stat != DEAD)
					SSmove_manager.move_to(src, targetted, calculated_walk, move_to_delay)
				set_glide_size(DELAY2GLIDESIZE(move_to_delay))
	else
		prepareAttackOnTarget()
		if (stat != DEAD)
			SSmove_manager.move_to(src, targetted_mob, 1, move_to_delay)

/mob/living/carbon/superior/proc/get_turf_at_edge_of_viewRange(var/atom/target, view_range = viewRange)
	var/turf/viewrange_edge = get_turf(src)
	if (!target)
		return null
	for (var/i = 0, i < view_range, i++)
		viewrange_edge = get_step_towards(viewrange_edge, target)
	return viewrange_edge

/mob/living/carbon/superior/proc/can_see_check(var/atom/targetted_mob, var/mob/living/targetted_mob_real, can_see = FALSE, use_hearers = FALSE)
	if (!see_through_walls)
		var/distance = min(get_dist(src, targetted_mob), viewRange)
		if ((targetted_mob_real && targetted_mob_real.client && ismob(targetted_mob)) || use_hearers)
			if (targetted_mob in hearers(distance, src))
				can_see = TRUE
		else if (can_see(src, targetted_mob, distance))
			can_see = TRUE
	else if (see_past_viewRange || (targetted_mob in range(viewRange, src)))
		can_see = TRUE

	return can_see

/atom/proc/check_if_alive(var/critcheck = FALSE)
	if (critcheck)
		if (ishuman(src))
			var/mob/living/carbon/human/H = src
			if(H.health > HEALTH_THRESHOLD_CRIT)
				return TRUE
			if(!H.resting && stat == CONSCIOUS)
				return TRUE
			return FALSE
	return health > 0

/mob/living/carbon/superior/handle_status_effects()
	paralysis = max(paralysis - 3, 0)
	if (stunned)
		stunned = max(stunned - 3, 0)
		if(!stunned)
			update_icons()
	if(weakened)
		weakened = max(weakened - 3, 0)
		if(!weakened)
			update_icons()

/mob/living/carbon/superior/handle_regular_status_updates()
	health = maxHealth - oxyloss - toxloss - fireloss - bruteloss - cloneloss - halloss
	if(health <= death_threshold && stat != DEAD)
		death()
		blinded = TRUE
		silent = FALSE
		return TRUE
	return FALSE

/mob/living/carbon/superior/handle_chemicals_in_body()
	if(reagents)
		chem_effects.Cut()
		if(touching)
			touching.metabolize()
		if(bloodstr)
			bloodstr.metabolize()

/mob/living/carbon/superior/Life()
	ticks_processed++
	handle_regular_hud_updates()
	if(!reagent_immune)
		handle_chemicals_in_body()

	if(!(ticks_processed % 3))
		if (!AI_inactive)
			handle_status_effects()
			update_lying_buckled_and_verb_status()
		if(!never_stimulate_air && stat != DEAD)
			sa_handle_breath()
		if(on_fire)
			handle_fire()
		handle_regular_status_updates()
		ticks_processed = 0

	if (!weakened && !AI_inactive)
		handle_ai()
		if(speak_chance && prob(speak_chance))
			visible_emote(emote_see)

		if (following)
			if (!target_mob && stat != DEAD)
				SSmove_manager.move_to(src, following, follow_distance, move_to_delay)
			else if (!target_mob && last_followed)
				SSmove_manager.stop_looping(src)
				last_followed = null

	if(life_cycles_before_sleep)
		life_cycles_before_sleep--
		return TRUE
	if(!(AI_inactive && life_cycles_before_sleep))
		AI_inactive = TRUE

	if(life_cycles_before_scan)
		life_cycles_before_scan--
		return FALSE
	if(check_surrounding_area(viewRange))
		activate_ai()
		life_cycles_before_scan = initial(life_cycles_before_scan) / 6
		return TRUE
	life_cycles_before_scan = initial(life_cycles_before_scan)
	return FALSE

/mob/living/carbon/superior/proc/prepareAttackPrecursor(attack_type, telegraph = TRUE, cast_beam = TRUE, var/atom/movable/targetted)
	if (!check_if_alive())
		return FALSE

	var/time_to_expire
	var/attack_telegraph
	switch(attack_type)
		if (MELEE_TYPE)
			time_to_expire = delay_for_melee
			attack_telegraph = melee_telegraph

			if (melee_delay <= 0)
				melee_delay = melee_delay_initial
			else
				melee_delay--
				if (telegraph)
					visible_message(SPAN_WARNING("\the [src] [melee_charge_telegraph] \the <font color = 'orange'>[targetted]</font>!"), target = targetted, message_target = always_telegraph_to_target)
				return FALSE

		if (RANGED_TYPE, RANGED_RAPID_TYPE)
			time_to_expire = delay_for_range
			attack_telegraph = range_telegraph

			if (fire_delay <= 0)
				fire_delay = fire_delay_initial
			else
				fire_delay--
				if (telegraph)
					visible_message(SPAN_WARNING("\the [src] [range_charge_telegraph] \the <font color = 'orange'>[targetted]</font>!"), target = targetted, message_target = always_telegraph_to_target)
				return FALSE

	if (cast_beam)
		Beam(targetted, icon_state = "1-full", time=(time_to_expire/10), maxdistance=(get_dist(src, targetted) + 10), alpha_arg=telegraph_beam_alpha, color_arg = telegraph_beam_color)
	if (telegraph)
		visible_message(SPAN_WARNING("\the [src] [attack_telegraph] \the <font color = 'blue'>[targetted]</font>!"), target = targetted, message_target = always_telegraph_to_target)

	return TRUE

/mob/living/carbon/superior/proc/doTargetMessage()
	return

/mob/living/carbon/superior/proc/handle_trace_impact(var/obj/item/projectile/trace, var/delete_trace = TRUE)
	if (stat == DEAD)
		return FALSE

	var/targetted_mob = target_mob?.resolve()
	var/boolean = TRUE
	var/datum/penetration_holder/holder = trace.penetration_holder

	if ((trace.impact_atom && (trace.impact_atom == targetted_mob)) || (holder && holder.force_penetration_on && (targetted_mob in holder.force_penetration_on)))
		boolean = FALSE

	if (delete_trace)
		qdel(trace.penetration_holder)
		trace.penetration_holder = null
		QDEL_NULL(trace)
	if (boolean)
		advance_towards(targetted_mob)
	return boolean

/mob/living/carbon/superior/proc/advance_towards(var/atom/target)
	var/calculated_walk = (comfy_range - comfy_distance)
	var/distance = get_dist(src, target)
	if (distance <= calculated_walk)
		advance_steps = distance - advancement
		if (advance_steps <= 0)
			advance_steps = 1
		if (stat != DEAD)
			SSmove_manager.move_to(src, target, advance_steps, move_to_delay)
		advancement_timer = (world.time += advancement_increment)

/mob/living/carbon/superior/CanPass(atom/mover)
	if(istype(mover, /obj/item/projectile))
		return stat ? TRUE : FALSE
	. = ..()

/mob/living/carbon/superior/UnarmedAttack(atom/A, proximity)
	. = ..()
	if(!. || poison_per_bite <= 0 || !isliving(A))
		return

	var/mob/living/L = A
	if(L.reagents)
		var/zone_armor = L.getarmor(targeted_organ, ARMOR_MELEE)
		var/poison_injected = zone_armor ? poison_per_bite * (1 - 0.01 * zone_armor) : poison_per_bite
		L.reagents.add_reagent(poison_type, poison_injected)
