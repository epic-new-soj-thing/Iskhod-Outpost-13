// For personal player fluff items. Expect to see a lot of `ckey_whitelist = list("meow")`
// Please keep the `path = ` defines in here as well
// And put the icons in `icons/fluff/fluff_icons.dmi` or a file within the `icons/fluff` directory (computers need their own DMI files).
// And always label both the /datum/gear and /obj/item with `// ckey - character name` (or just `// ckey`)
// IT IS UP TO THE PLAYERS TO KEEP THEIR SHIT WORKING, NOT DEVELOPERS THAT CHANGE THINGS. (Other than compile errors, cuz, y'know, you'll have to figure that out.)
// Prefer using /obj/item/fluff_conversion_kit where possible over spawning an item

/obj/item/fluff_conversion_kit
	name = "Conversion Kit"
	icon = 'icons/obj/device.dmi'
	icon_state = "modkit"

	// ckeys are always lowercase
	var/list/ckey_whitelist = list()

	// Typed like this to hint at what typepath it should contain
	// as well as used to avoid a recast in examine()
	var/obj/target_type = null

	// Multiple options: Spawning a new item
	var/path_change = null

	// Or modifying the existing items vars
	var/name_change = null
	var/icon_change = null
	var/icon_state_change = null
	var/vars_change = list()

/obj/item/fluff_conversion_kit/examine(user, distance)
	..()
	to_chat(user, SPAN_NOTICE("This is able to convert '[initial(target_type.name)]'."))

/obj/item/fluff_conversion_kit/afterattack(atom/target, mob/user, proximity_flag, params)
	if(!proximity_flag)
		return
	if(!istype(user))
		return
	if(user.incapacitated())
		return
	if(!user.IsAdvancedToolUser())
		return

	if(!target_type)
		CRASH("Fluff conversion kit [name] doesn't specify a target type!")

	if(!istype(target, target_type))
		to_chat(user, "[src] does not support '[target]'.")
		return

	user.visible_message("[user] starts to apply [src] to [target]...", "You start to apply [src] to [target]...")
	if(!do_after(user, 2 SECONDS, target))
		to_chat(user, "You need to stay still to apply [src].")
		return


	var/old_name = target.name
	var/old_type = target.type
	var/obj/final_item = convert(target)
	user.visible_message("[user] uses [src] to transform '[old_name]' into '[final_item]'.", "You apply [src] to transform '[old_name]' into '[final_item]'.")
	// Put down a note that this happened
	final_item.investigate_log("was converted from [old_name] ([old_type]) into a fluff item by [user.ckey] using [name] ([type]).", "fluff")
	if(!(user.ckey in ckey_whitelist))
		// And an extra log if it was used suspiciously
		log_admin("[key_name(user)] used the fluff item modkit '[name]' that is only supposed to be used by ckeys '[jointext(ckey_whitelist, ", ")]'.")
	qdel(src)

/obj/item/fluff_conversion_kit/proc/convert(atom/target)
	if(path_change)
		var/obj/item/new_item = new path_change(target.loc)
		qdel(target)
		return new_item

	if(name_change)
		target.name = name_change

	if(icon_change)
		target.icon = icon_change

	if(icon_state_change)
		target.icon_state = icon_state_change

	if(length(vars_change))
		for(var/key in vars_change)
			target.vars["[key]"] = vars_change[key]

	target.update_icon()
	return target

/datum/gear/fluff
	category = /datum/gear/fluff
	sort_category = "Fluff Items"
	cost = 0

/datum/gear/fluff/New()
	. = ..()
	// no gear tweaks, they won't be carried through correctly because of modkits
	gear_tweaks = list()

/datum/gear/fluff/spawn_item(location, metadata)
	. = ..()
	var/obj/item/fluff_conversion_kit/kit = .
	if(istype(kit))
		kit.ckey_whitelist = ckey_whitelist


/**********************************/
/*                                */
/*    PLAYER STUFF BEYOND HERE    */
/*                                */
/**********************************/

// Tigercat2000
/datum/gear/fluff/larkens_laptop
	ckey_whitelist = list("tigercat2000")
	display_name = "Larkens Laptop Conversion Kit"
	path = /obj/item/fluff_conversion_kit/larkens_laptop

// Tigercat2000
/obj/item/fluff_conversion_kit/larkens_laptop
	name = "Larkens Laptop Conversion Kit"
	target_type = /obj/item/modular_computer/laptop

	name_change = "Larkens-Branded Laptop"
	icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "shadowlaptop-closed"
	vars_change = list(
		"icon_state_unpowered" = "shadowlaptop",
		"overlay_icon" = 'icons/obj/modular_laptop.dmi'
	)

// TheEternalFlame
/datum/gear/fluff/tef_frayed_duster
	ckey_whitelist = list("theeternalflame")
	display_name = "Frayed Military Duster Conversion Kit"
	path = /obj/item/fluff_conversion_kit/tef_frayed_duster

// TheEternalFlame
/obj/item/fluff_conversion_kit/tef_frayed_duster
	name = "Frayed Military Duster Conversion Kit"
	target_type = /obj/item/clothing/suit/storage/toggle/leather

	name_change = "Frayed Military Duster"
	icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "ghostechoe"
	vars_change = list(
		"desc" = "A military duster that's seen more combat than it probably should have, riddled with holes, tears and a healthy amount of dried blood. It likely should have been thrown away a long time ago, instead recently a peace symbol was drawn over it's back. The state of the duster and the symbol on it's back left it at odds with itself.",
		"icon_override" = 'icons/fluff/clothing_mob.dmi',
		"item_state" = "ghostechoe"
	)

// SLRaptor
/datum/gear/fluff/slr_patterned_serape
	ckey_whitelist = list("slraptor")
	display_name = "Patterned Serape Conversion Kit"
	path = /obj/item/fluff_conversion_kit/slr_patterned_serape

// SLRaptor
/obj/item/fluff_conversion_kit/slr_patterned_serape
	name = "Patterned Serape Conversion Kit"
	target_type = /obj/item/clothing/suit/storage/vest/scav
	name_change = "Worn Serape"
	icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "serape"
	vars_change = list(
		"desc" = "A red and white serape. This shawl is well faded and well worn from years of heavy outdoor use, the pattern and colors are splotched with new patches hastily sewn with discolored thread",
		"icon_override" = 'icons/fluff/clothing_mob.dmi',
		"item_state" = "serape"
	)

// guidesa/SSGT_BR
/datum/gear/fluff/guidesa_sheath
	ckey_whitelist = list("ssgtbr")
	display_name = "Runed Sheath Conversion Kit"
	path = /obj/item/fluff_conversion_kit/guidesa_sheath

// guidesa/SSGT_BR
/obj/item/fluff_conversion_kit/guidesa_sheath
	name = "Runed Sheath Conversion Kit"
	target_type = /obj/item/storage/sheath/non_church/general

	name_change = "Runed Sheath"
	icon_change = 'icons/fluff/fluff_items.dmi'
	vars_change = list(
		"desc" = "An old adorned sheath meant to hold a variety of weapons and swords. It looks elegant.",
		"icon_override" = 'icons/fluff/clothing_mob.dmi',
		"base_icon_state" = "runed_sheath",
		"base_item_state" = "runed_sheath"
	)

// Chef_Doggo
/datum/gear/fluff/chef_doggo_telescopic_baton
	ckey_whitelist = list("chefdoggo")
	display_name = "Gold Leaf Telescopic Baton Kit"
	path = /obj/item/fluff_conversion_kit/chef_doggo_telescopic_baton

// Chef_Doggo
/obj/item/fluff_conversion_kit/chef_doggo_telescopic_baton
	name = "Patterned Serape Conversion Kit"
	target_type = /obj/item/melee/telebaton
	name_change = "Gilded Telebaton"
	icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "rat_telebaton"
	vars_change = list(
		"desc" = "A relatively standard telebaton with gold leafing on the tip and on parts of the metal creating a striped look, the handle is dyed a golden yellow.",
		"icon_override" = 'icons/fluff/fluff_items.dmi',
		"item_state" = "rat_telebaton_0",
		"baton_base" = "rat_telebaton"
	)

// drfarson
/datum/gear/fluff/drfarson_katana_saya
	ckey_whitelist = list("drfarson")
	display_name = "Embroidered Occult Saya"
	path = /obj/item/clothing/accessory/holster/saber/rapiersci/occult

// drfarson
/obj/item/clothing/accessory/holster/saber/rapiersci/occult
	name = "embroidered occult saya"
	desc = "A sleek hardened ebony material covers the entire saya in multifaceted shapes, the runes on it seem to shift and change as you look at them, probing your mind."
	icon_state = "rapiersci_holster"
	overlay_state = "rapiersci"
	slot = "utility"
	can_hold = list(/obj/item/tool/sword/saber/deconstuctive_rapier, /obj/item/tool/sword/katana/nano, /obj/item/tool/hydrogen_sword, /obj/item/tool/knife/ritual/blade)
	price_tag = 15000
	sound_in = 'sound/effects/sheathin.ogg'
	sound_out = 'sound/effects/sheathout.ogg'

// drfarson
/datum/gear/fluff/drfarson_medal
	ckey_whitelist = list("drfarson")
	display_name = "High Council Medal of Honor"
	path = /obj/item/clothing/accessory/medal/gold/honor


// floofster
/datum/gear/fluff/floof_cloak
	ckey_whitelist = list("floofster")
	display_name = "Outsider's Cloak"
	path = /obj/item/clothing/accessory/cape/outsider
	cost = 0

// MicroMinty
/datum/gear/fluff/microminty_labcoat
	ckey_whitelist = list("microminty")
	display_name = "Extra-Membranous Tailored Labcoat"
	path = /obj/item/clothing/suit/hooded/fluff/microminty_membranousmembrane
	cost = 0
// MicroMinty
/obj/item/clothing/suit/hooded/fluff/microminty_membranousmembrane
	name = "Extra-Membranous Tailored Labcoat"
	icon = 'icons/fluff/clothing_mob.dmi'
	icon_state = "membranousmembrane"
	item_state = "membranousmembrane"
	desc = "An even longer labcoat with buttons on the side. It has a gigantically larger collar than the standard lab coat, to help protect your face from your and everyone elses' mistakes. This one has a metal rivet near the mouth. It is also stained near the edges of the sleeves with remnants of various toxic compounds. Yummy!"
	hoodtype = /obj/item/clothing/head/fluff/microminty_membranousmembrane_hood
	blood_overlay_type = "coat"
	body_parts_covered = UPPER_TORSO|ARMS|LOWER_TORSO|LEGS
	armor_list = list(
		melee = 0,
		bullet = 0,
		bomb = 0,
		bio = 50,
		rad = 0
	)
/obj/item/clothing/head/fluff/microminty_membranousmembrane_hood
	name = "Extra-Membranous Coat Collar"
	icon = 'icons/fluff/clothing_mob.dmi'
	icon_state = "membranoushood"
	item_state = "membranoushood"
	desc = "The collar of a very long labcoat."

// msrandylicious
// theres a lot here so uh...
// CONVERSION KITS
/obj/item/fluff_conversion_kit/sts_pinkifier
	name = "Crashouts STS Auto Converter"
	target_type = /obj/item/gun/projectile/automatic/sts/rifle/blackshield
	name_change = "\"STS PINK\" Blackshield rifle"
	icon_change = 'icons/obj/guns/projectile/sts_pink.dmi'
	icon_state_change = "stspara"
	vars_change = list(
		"desc" = "A lightweight, pinkified modified variant of the STS-30 that takes 7.5mm rounds, shedding wartime wood for modern plastic polymer and some pink tape. \
	The lightweight polymer, skeletal stock and shortened barrel make this weapon much lighter than the standard STS with modified receivers and gas block for better recoil control. \
	Two stamps are pressed into the side of the receiver: A 'M&C' logo and a blackshield logo.",
		"icon_override" = 'icons/obj/guns/projectile/sts_pink.dmi',
		"item_state" = "stspara",
		//"sawn" = '/obj/item/gun/projectile/automatic/sts/rifle/blackshield'
	)
/obj/item/fluff_conversion_kit/uniform_pinkifier
	name = "Crashouts Fatigue Dye"
	target_type = /obj/item/clothing/under/rank/ranger/fatigues
	name_change = "pink dyed ranger field fatigues"
	//icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "pinkcombat"
	vars_change = list(
		"desc" = "An alternative utility uniform of the Iskhod Rangers, designed for field operations where mobility is key. This one has been dyed pink against department dress code.",
		//"icon_override" = 'icons/fluff/fluff_items.dmi',
		"item_state" = "pinkcombat"
	)
/obj/item/fluff_conversion_kit/armour_pinkifier
	name = "Crashouts Armour Paint"
	target_type = /obj/item/clothing/suit/armor/vest/ironhammer/full
	name_change = "pink tactical unit armor"
	//icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "pinkarmor_ih_fullbody_alt"
	vars_change = list(
		"desc" = "An armored vest painted in Pretty Pink. This one has shoulderpads and kneepads included to protect all parts of the body.",
		//"icon_override" = 'icons/fluff/fluff_items.dmi',
		"item_state" = "pinkarmor_ih_fullbody_alt"
	)
/obj/item/fluff_conversion_kit/wintercoat_pinkifier
	name = "Crashouts Wintercoat Dye"
	target_type = /obj/item/clothing/suit/armor/vest/ironhammer_wintercoat
	name_change = "pink armored winter coat"
	//icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "coatsecurity_long_pink"
	vars_change = list(
		"desc" = "An armored winter coat with vest that protects against some damage. This one has been dyed pink against department dress code. Not designed for serious operations. You're pretty sure the coat is just thick enough to keep warm, and that's all. Handy on a planet like Iskandor.",
		//"icon_override" = 'icons/fluff/fluff_items.dmi',
		"item_state" = "coatsecurity_long_pink"
	)
/obj/item/fluff_conversion_kit/s10_pinkifier
	name = "Crashouts GasMask Paint"
	target_type = /obj/item/clothing/mask/gas/blackshield_gasmask
	name_change = "C-10 Gas Mask"
	//icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "s10_pink"
	vars_change = list(
		"desc" = "A modern reproduction of an ancient but effective gas mask design from centuries ago on earth. While its primitive design is virtually unchanged, the air is still pure.",
		//"icon_override" = 'icons/fluff/fluff_items.dmi',
		"item_state" = "s10_pink"
	)
/obj/item/fluff_conversion_kit/ushanka_pinkifier
	name = "Crashouts Ushanka Dye"
	target_type = /obj/item/clothing/head/ushanka/security
	name_change = "pink security ushanka"
	//icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "pinkflushankadown"
	vars_change = list(
		"desc" = "A warm, fur cap. The flaps are currently secured downwards for maximum warmth. This one has been dyed pink against department dress code.",
		//"icon_override" = 'icons/fluff/fluff_items.dmi',
		"item_state" = "pinkflushankadown"
	)
/obj/item/fluff_conversion_kit/helmet_pinkifier
	name = "Crashouts Helmet Paint"
	target_type = /obj/item/clothing/head/helmet/marshal_full
	name_change = "pink armoured helmet"
	//icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "pinkironhammer_full"
	vars_change = list(
		"desc" = "A full helmet with a built in glow visor. While a weak light its better than nothing and the full cover design makes it ideal for general protection. This one has been painted pink and had cat ears glued on despite department dress code and property violations.",
		//"icon_override" = 'icons/fluff/fluff_items.dmi',
		"item_state" = "pinkironhammer_full"
	)
/obj/item/fluff_conversion_kit/baton_pinkifier
	name = "Crashouts Baton Cover"
	target_type = /obj/item/tool/baton
	name_change = "pink stun baton"
	//icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "pinkstunbaton"
	vars_change = list(
		"desc" = "A pink zap stick for beating the shit out of people.",
		//"icon_override" = 'icons/fluff/fluff_items.dmi',
		"item_state" = "pinkstunbaton"
	)

/obj/item/fluff_conversion_kit/advanced_cuffs_pinkifier
	name = "Crashouts Gauntlet Paint"
	target_type = /obj/item/handcuffs/advanced
	name_change = "pink heavy handcuffs"
	//icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "pinkhandcuff_advanced"
	vars_change = list(
		"desc" = "Use this to keep prisoners in line. This gauntlet verson is much harder to break out as well as able to wrap around a RIG's gauntlet. For added disrespect, these ones have been painted pink.",
		//"icon_override" = 'icons/fluff/fluff_items.dmi',
		"item_state" = "pinkhandcuff_advanced"
	)
/obj/item/fluff_conversion_kit/regular_cuffs_pinkifier
	name = "Crashouts Basic Cuffs Paint"
	target_type = /obj/item/handcuffs
	name_change = "pink handcuffs"
	//icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "pinkhandcuff"
	vars_change = list(
		"desc" = "Use this to keep prisoners in line. For added disrespect, these ones have been painted pink.",
		//"icon_override" = 'icons/fluff/fluff_items.dmi',
		"item_state" = "pinkhandcuff"
	)
/obj/item/fluff_conversion_kit/flashlight_pinkifier
	name = "Crashouts Flashlight Paint"
	target_type = /obj/item/device/lighting/toggleable/flashlight/seclite
	name_change = "pink flashlight"
	//icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "pinkseclite"
	vars_change = list(
		"desc" = "A hand-held security flashlight. This one has been painted pink for an added psychological blinding effect.",
		//"icon_override" = 'icons/fluff/fluff_items.dmi',
		"item_state" = "pinkseclite"
	)
/obj/item/fluff_conversion_kit/hud_pinkifier
	name = "Crashouts SecHUD Paint"
	target_type = /obj/item/clothing/glasses/sechud/tactical
	name_change = "tactically pink HUD"
	//icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "pinkswatgoggles"
	vars_change = list(
		"desc" = "Improved Flash-resistant goggles with inbuilt combat and security information. This one has been painted pink against department dress code.",
		//"icon_override" = 'icons/fluff/fluff_items.dmi',
		"item_state" = "pinkswatgoggles"
	)
/obj/item/fluff_conversion_kit/pistol_pinkifier
	name = "Crashouts Pistol Paint"
	target_type = /obj/item/gun/projectile/colt/ten
	name_change = "\"Pink Elite\" magnum pistol"
	//icon_change = 'icons/fluff/fluff_items.dmi'
	icon_state_change = "pinkdark_delta"
	vars_change = list(
		"desc" = "A classy high-powered automatic commissioned by Blackshield and based on the M1911 series handguns, with significant reinforcements produced by Scarborough Arms. Uses .40 Auto-Mag. This one has been painted pink by its owner for added lethality.",
		//"icon_override" = 'icons/fluff/fluff_items.dmi',
		"item_state" = "colt"
	)
// msrandylicious
// LOADOUT OBJECTS
/datum/gear/fluff/crashouts_sts
	ckey_whitelist = list("msrandylicious")
	display_name = "Crashouts STS Auto Converter (no charlie needed)"
	path = /obj/item/fluff_conversion_kit/sts_pinkifier
/datum/gear/fluff/crashouts_sts_conversion_kit
	ckey_whitelist = list("msrandylicious")
	display_name = "Crashouts STS DIY kit (ask charlie for help)"
	path = /obj/item/stock_parts/blackshield/pink_sts_kit
/datum/gear/fluff/crashouts_uniform
	ckey_whitelist = list("msrandylicious")
	display_name = "Crashouts Fatigue Dye"
	path = /obj/item/fluff_conversion_kit/uniform_pinkifier
/datum/gear/fluff/crashouts_armour
	ckey_whitelist = list("msrandylicious")
	display_name = "Crashouts Armour Paint"
	path = /obj/item/fluff_conversion_kit/armour_pinkifier
/datum/gear/fluff/crashouts_wintercoat
	ckey_whitelist = list("msrandylicious")
	display_name = "Crashouts Wintercoat Dye"
	path = /obj/item/fluff_conversion_kit/wintercoat_pinkifier
/datum/gear/fluff/crashouts_gasmask
	ckey_whitelist = list("msrandylicious")
	display_name = "Crashouts GasMask Paint"
	path = /obj/item/fluff_conversion_kit/s10_pinkifier
/datum/gear/fluff/crashouts_ushanka
	ckey_whitelist = list("msrandylicious")
	display_name = "Crashouts Ushanka Dye"
	path = /obj/item/fluff_conversion_kit/ushanka_pinkifier
/datum/gear/fluff/crashouts_helmet
	ckey_whitelist = list("msrandylicious")
	display_name = "Crashouts Helmet Paint"
	path = /obj/item/fluff_conversion_kit/helmet_pinkifier
/datum/gear/fluff/crashouts_baton
	ckey_whitelist = list("msrandylicious")
	display_name = "Crashouts Baton Cover"
	path = /obj/item/fluff_conversion_kit/baton_pinkifier
/datum/gear/fluff/crashouts_basic_cuffs
	ckey_whitelist = list("msrandylicious")
	display_name = "Crashouts Basic Handcuffs paint"
	path = /obj/item/fluff_conversion_kit/regular_cuffs_pinkifier
/datum/gear/fluff/crashouts_advanced_cuffs
	ckey_whitelist = list("msrandylicious")
	display_name = "Crashouts Advanced Handcuffs paint"
	path = /obj/item/fluff_conversion_kit/advanced_cuffs_pinkifier
/datum/gear/fluff/crashouts_flashlight
	ckey_whitelist = list("msrandylicious")
	display_name = "Crashouts Flashlight Paint"
	path = /obj/item/fluff_conversion_kit/flashlight_pinkifier
/datum/gear/fluff/crashouts_sechud
	ckey_whitelist = list("msrandylicious")
	display_name = "Crashouts SecHUD Paint"
	path = /obj/item/fluff_conversion_kit/hud_pinkifier
/datum/gear/fluff/crashouts_pistol
	ckey_whitelist = list("msrandylicious")
	display_name = "Crashouts Pistol Paint"
	path = /obj/item/fluff_conversion_kit/pistol_pinkifier
/datum/gear/fluff/crashouts_pendant
	ckey_whitelist = list("msrandylicious")
	display_name = "Crashouts Ruby-Gold Pendant"
	path = /obj/item/clothing/accessory/necklace/rubypendant
// this one also for CKey = "mushyp"
/datum/gear/fluff/crashouts_bandana
	ckey_whitelist = list("msrandylicious", "mushyp")
	display_name = "Crashouts Gang Bandana"
	path = /obj/item/clothing/mask/bandana/purple/crashout

// mushyp
/datum/gear/fluff/Avon_S10
	ckey_whitelist = list("mushyp")
	display_name = "Avon S10 Gas Mask"
	path = /obj/item/clothing/mask/gas/avon_s10_purple
