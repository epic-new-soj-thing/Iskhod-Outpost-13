/mob/living/carbon/superior/attack_ui(slot_id)
	return

/mob/living/carbon/superior/UnarmedAttack(var/atom/A, var/proximity)
	if(!..() || weakened)
		return

	var/damage = rand(melee_damage_lower, melee_damage_upper)

	if(moved)
		damage *= move_attack_mult

	// Flattened type-checking for faster execution during combat clicks
	if(ishuman(A))
		var/mob/living/carbon/human/target_human = A
		if(target_human.check_shields(damage, null, src, null, attacktext))
			return FALSE

	. = A.attack_generic(user = src, damage = damage, attack_message = attacktext, damagetype = melee_damage_type, attack_flag = attacking_armor_type, sharp = melee_sharp, edge = melee_sharp)

	if(.)
		if(fancy_attack_overlay)
			var/obj/effect/effect/melee/mob_melee_animation/RS = new(get_turf(A), fancy_colour = fancy_attack_shading)
			RS.dir = dir
			if(randomize_attack_effect_location)
				RS.pixel_x = rand(-6, 6)
				RS.pixel_y = rand(-6, 8)
			flick(fancy_attack_overlay, RS)
			QDEL_IN(RS, 2 SECONDS)

		if (attack_sound && loc && prob(attack_sound_chance))
			playsound(loc, attack_sound, attack_sound_volume, TRUE)

/mob/living/carbon/superior/verb/break_around()
	set name = "Attack Surroundings"
	set desc = "Lash out on your surroundings | Forcefully attack your surroundings."
	set category = "Mob verbs"

	if(!check_if_alive() || weakened || resting)
		return

	src.destroySurroundings()

/mob/living/carbon/superior/RangedAttack()
	if(!check_if_alive() || weakened)
		return

	var/atom/targetted_mob = target_mob?.resolve()
	if(!ranged || !targetted_mob)
		return

	// Clean type-separation fixes the bug where megafauna pathfound twice and bypassed cooldown flow
	if(istype(src, /mob/living/simple/hostile/megafauna))
		var/mob/living/simple/hostile/megafauna/megafauna = src
		sleep(rand(megafauna.megafauna_min_cooldown, megafauna.megafauna_max_cooldown))

		var/should_pathfind = FALSE
		if(istype(src, /mob/living/simple/hostile/megafauna/one_star))
			if(prob(rand(15, 25)))
				should_pathfind = TRUE
		else if(prob(45))
			should_pathfind = TRUE

		if(should_pathfind)
			stance = HOSTILE_STANCE_ATTACKING
			set_glide_size(DELAY2GLIDESIZE(move_to_delay))
			if (stat != DEAD)
				SSmove_manager.move_to(src, targetted_mob, 1, move_to_delay)
		else
			OpenFire(targetted_mob)
	else
		if(get_dist(src, targetted_mob) <= 6)
			OpenFire(targetted_mob)
		else
			set_glide_size(DELAY2GLIDESIZE(move_to_delay))
			if (stat != DEAD)
				SSmove_manager.move_to(src, targetted_mob, 1, move_to_delay)

/mob/living/carbon/superior/proc/OpenFire(var/atom/firing_target, var/obj/item/projectile/trace_arg)
	if(!check_if_alive() || weakened)
		return

	// Validating target integrity early prevents wasted ammunition or unnecessary timer scheduling
	if(!firing_target || QDELETED(firing_target) || firing_target.z != src.z)
		loseTarget()
		return

	if (!firing_target.check_if_alive(TRUE))
		loseTarget()
		return

	var/atom/target = firing_target

	if(rapid)
		for(var/shotsfired = 0, shotsfired < rapid_fire_shooting_amount, shotsfired++)
			addtimer(CALLBACK(src, PROC_REF(Shoot), target, loc, src, 0, trace_arg), (delay_for_rapid_range * shotsfired))
			handle_ammo_check()
	else
		Shoot(target, loc, src, trace = trace_arg)
		handle_ammo_check()

/mob/living/carbon/superior/proc/handle_ammo_check()
	if(!limited_ammo)
		return

	rounds_left -= rounds_per_fire
	if(rounds_left <= 0)
		if(mags_left >= 1)
			mob_reload()
		else
			ranged = FALSE
			rapid = FALSE

/mob/living/carbon/superior/proc/mob_reload()
	mags_left--
	rounds_left = initial(rounds_left)
	visible_message(reload_message)
	if(mag_drop)
		new mag_type(get_turf(src))

/mob/living/carbon/superior/proc/Shoot(var/target, var/start, var/user, var/bullet = 0, var/obj/item/projectile/trace)
	if(weakened || target == start || is_dead(src))
		return

	var/obj/item/projectile/A = new projectiletype(loc)
	if(!A)
		return

	var/def_zone = pickweight(zone_hit_rates)
	var/datum/penetration_holder/trace_penetration = (trace && !QDELETED(trace)) ? trace.penetration_holder : null
	var/do_we_shoot = TRUE
	var/obj/item/projectile/new_trace = check_trajectory_raytrace(target, src, projectiletype)

	spawn(0)
		if (new_trace)
			if (new_trace.impact_atom)
				var/list/possible_targets = list()
				if (trace_penetration && trace_penetration.force_penetration_on.len)
					possible_targets = trace_penetration.force_penetration_on.Copy()
				possible_targets += new_trace.impact_atom

				for (var/atom/entry in possible_targets)
					var/mob/possible_target = null
					if (istype(entry, /obj/mecha))
						var/obj/mecha/mechtarget = entry
						possible_target = mechtarget.occupant
					else if (ismob(entry))
						possible_target = entry

					if (possible_target)
						if (possible_target == target)
							continue
						if (!(prob(do_friendly_fire_chance)) && !friendly_to_colony && (((!attack_same && (possible_target.faction == faction)) || (possible_target in friends))))
							do_we_shoot = FALSE
							break

		// Merged identical conditional blocks into one execution chain
		if (do_we_shoot)
			if (trace_penetration && trace_penetration.force_penetration_on?.len)
				var/datum/penetration_holder/penetrator = A.penetration_holder
				for (var/atom/penetrated in trace_penetration.force_penetration_on)
					penetrator.force_penetration_on += penetrated

			var/offset_temp = right_before_firing()
			A.original_firer = src
			if(friendly_to_colony)
				A.friendly_to_colony = TRUE
			A.predetermed = def_zone
			A.launch(target, def_zone, firer_arg = src, angle_offset = offset_temp)
			right_after_firing()
			SEND_SIGNAL(src, COMSIG_SUPERIOR_FIRED_PROJECTILE, A)
			visible_message(SPAN_DANGER("<b>[src]</b> [fire_verb] at [target]!"))
			if(casingtype)
				new casingtype(get_turf(src))
			playsound(src, projectilesound, projectilevolume, TRUE)
		else
			QDEL_NULL(A)

		// Added QDELETED safety guards to protect multi-threaded rapid-fire trace cleanup loops
		if (trace && !QDELETED(trace))
			if (trace.penetration_holder && !QDELETED(trace.penetration_holder))
				qdel(trace.penetration_holder)
				trace.penetration_holder = null
			QDEL_NULL(trace)

		if (new_trace && !QDELETED(new_trace))
			if (new_trace.penetration_holder && !QDELETED(new_trace.penetration_holder))
				qdel(new_trace.penetration_holder)
				new_trace.penetration_holder = null
			QDEL_NULL(new_trace)

/mob/living/carbon/superior/proc/right_before_firing(offset_positive = current_firing_offset, round_offset = FALSE)
	if (round_offset)
		offset_positive = round(offset_positive)

	offset_positive = abs(offset_positive)
	if (!offset_positive)
		return 0

	// Dropped macro operations for optimized internal engine sign-inversion mathematics
	return rand(-offset_positive, offset_positive)

/mob/living/carbon/superior/proc/right_after_firing()
	return FALSE

/mob/living/carbon/superior/MiddleClickOn(mob/targetDD as mob)
	if(!check_if_alive() || weakened)
		return

	if(ranged_middlemouse_cooldown >= world.time)
		to_chat(src, "Your gun isn't ready to fire!")
		return

	if(ranged)
		src.OpenFire(targetDD)
