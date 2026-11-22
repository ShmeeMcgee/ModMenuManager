// ============================================================================
//  SHMEES MENU v1.0  -  World at War Multiplayer
//  by Shmees  |  youtube.com/@Shmees14  |  github.com/ShmeeMcgee
//
//  Loaded by CoD Xe's raw GSC loader. Installed with Mod Menu Manager.
//  Open: Aim + Knife   Scroll: Aim / Shoot   Select: Use (X)   Back: Knife
//  For offline play, private matches and system link only.
// ============================================================================

init()
{
	if(isDefined(level.sm_started))
		return;
	level.sm_started = true;
	level.sm_version = "1.0";
	level.sm_game = "World at War";
	level.sm_everyone = false;
	level.sm_maxLines = 11;
	precacheShader("white");
	setDvar("loc_warnings", "0");
	setDvar("loc_warningsAsErrors", "0");
	level thread sm_onConnect();
}

sm_onConnect()
{
	for(;;)
	{
		level waittill("connected", player);
		player thread sm_onPlayer();
	}
}

sm_onPlayer()
{
	self endon("disconnect");
	self.sm_open = false;
	self.sm_on = [];
	self.sm_theme = (0.61, 0.88, 0.24);
	self.sm_access = false;
	if(self sm_isHost())
		self.sm_access = true;
	self.sm_welcomed = false;
	self thread sm_monitor();
	for(;;)
	{
		self waittill("spawned_player");
		if(self sm_hasAccess() && !self.sm_welcomed)
		{
			self.sm_welcomed = true;
			self iPrintlnBold("^2Shmees Menu^7 loaded");
			self iPrintln("Aim + Knife to open the menu");
		}
	}
}

// ---------------------------------------------------------------- engine ----

sm_hasAccess()
{
	if(isDefined(self.sm_access) && self.sm_access)
		return true;
	if(isDefined(level.sm_everyone) && level.sm_everyone)
		return true;
	return false;
}

sm_isHost()
{
	if(self getEntityNumber() == 0)
		return true;
	return false;
}

sm_monitor()
{
	self endon("disconnect");
	self notify("sm_monitor_stop");
	self endon("sm_monitor_stop");
	for(;;)
	{
		if(!self.sm_open)
		{
			if(self sm_hasAccess() && isAlive(self) && !self sm_gameOver() && self adsButtonPressed() && self meleeButtonPressed())
			{
				self sm_openMenu("main");
				while(self adsButtonPressed() || self meleeButtonPressed())
					wait 0.05;
			}
		}
		else
		{
			if(!isAlive(self) || self sm_gameOver())
			{
				self sm_closeMenu();
			}
			else if(self adsButtonPressed())
			{
				self sm_scroll(-1);
				wait 0.12;
			}
			else if(self attackButtonPressed())
			{
				self sm_scroll(1);
				wait 0.12;
			}
			else if(self useButtonPressed())
			{
				self sm_select();
				wait 0.25;
			}
			else if(self meleeButtonPressed())
			{
				self sm_back();
				wait 0.25;
			}
		}
		wait 0.05;
	}
}

sm_gameOver()
{
	if(isDefined(level.gameEnded) && level.gameEnded)
		return true;
	return false;
}

sm_openMenu(id)
{
	self.sm_open = true;
	self freezeControls(true);
	self sm_drawBase();
	self.sm_stackIds = [];
	self.sm_stackCur = [];
	self sm_goto(id, 0);
}

sm_closeMenu()
{
	self.sm_open = false;
	self freezeControls(false);
	self sm_destroyHud();
}

sm_goto(id, cursor)
{
	self.sm_menuId = id;
	self.sm_cursor = cursor;
	self.sm_first = 0;
	self sm_build(id);
	self sm_render();
}

sm_enter(id)
{
	n = self.sm_stackIds.size;
	self.sm_stackIds[n] = self.sm_menuId;
	self.sm_stackCur[n] = self.sm_cursor;
	self sm_goto(id, 0);
}

sm_back()
{
	n = self.sm_stackIds.size;
	if(n == 0)
	{
		self sm_closeMenu();
		return;
	}
	id = self.sm_stackIds[n - 1];
	cur = self.sm_stackCur[n - 1];
	self.sm_stackIds[n - 1] = undefined;
	self.sm_stackCur[n - 1] = undefined;
	self sm_goto(id, cur);
}

sm_scroll(dir)
{
	total = self.sm_labels.size;
	if(total == 0)
		return;
	self.sm_cursor = self.sm_cursor + dir;
	if(self.sm_cursor < 0)
		self.sm_cursor = total - 1;
	if(self.sm_cursor > total - 1)
		self.sm_cursor = 0;
	self sm_render();
}

sm_select()
{
	i = self.sm_cursor;
	if(i >= self.sm_labels.size)
		return;
	kind = self.sm_kind[i];
	if(kind == "menu")
	{
		self sm_enter(self.sm_a1[i]);
		return;
	}
	if(kind == "player")
	{
		self.sm_target = self.sm_a1[i];
		self sm_enter("player");
		return;
	}
	self thread [[ self.sm_funcs[i] ]](self.sm_a1[i], self.sm_a2[i]);
	wait 0.1;
	if(self.sm_open)
	{
		if(isDefined(self.sm_rebuild) && self.sm_rebuild)
		{
			self.sm_rebuild = false;
			cur = self.sm_cursor;
			self sm_build(self.sm_menuId);
			self.sm_cursor = cur;
		}
		self sm_render();
	}
}

sm_start(title)
{
	self.sm_title = title;
	self.sm_labels = [];
	self.sm_kind = [];
	self.sm_funcs = [];
	self.sm_a1 = [];
	self.sm_a2 = [];
	self.sm_keys = [];
}

sm_add(label, func, a1, a2, key)
{
	i = self.sm_labels.size;
	self.sm_labels[i] = label;
	self.sm_kind[i] = "func";
	self.sm_funcs[i] = func;
	self.sm_a1[i] = a1;
	self.sm_a2[i] = a2;
	self.sm_keys[i] = key;
}

sm_addMenu(label, id)
{
	i = self.sm_labels.size;
	self.sm_labels[i] = label;
	self.sm_kind[i] = "menu";
	self.sm_a1[i] = id;
}

sm_addPlayer(label, player)
{
	i = self.sm_labels.size;
	self.sm_labels[i] = label;
	self.sm_kind[i] = "player";
	self.sm_a1[i] = player;
}

sm_nothing(a1, a2)
{
}

sm_isOn(key)
{
	if(isDefined(self.sm_on[key]) && self.sm_on[key])
		return true;
	return false;
}

sm_flip(key)
{
	if(self sm_isOn(key))
	{
		self.sm_on[key] = false;
		return false;
	}
	self.sm_on[key] = true;
	return true;
}

sm_say(name, state)
{
	if(state)
		self iPrintln(name + " ^2ON");
	else
		self iPrintln(name + " ^1OFF");
}

// ------------------------------------------------------------------- HUD ----

sm_text(x, y, scale, sort)
{
	h = newClientHudElem(self);
	h.horzAlign = "center";
	h.vertAlign = "middle";
	h.alignX = "left";
	h.alignY = "middle";
	h.x = x;
	h.y = y;
	h.font = "objective";
	h.fontScale = scale;
	h.color = (1, 1, 1);
	h.alpha = 1;
	h.sort = sort;
	h.foreground = true;
	h.hideWhenInMenu = true;
	h.archived = false;
	return h;
}

sm_box(x, y, w, ht, color, alpha, sort)
{
	e = newClientHudElem(self);
	e.horzAlign = "center";
	e.vertAlign = "middle";
	e.alignX = "left";
	e.alignY = "top";
	e.x = x;
	e.y = y;
	e.color = color;
	e.alpha = alpha;
	e.sort = sort;
	e.foreground = true;
	e.hideWhenInMenu = true;
	e.archived = false;
	e setShader("white", w, ht);
	return e;
}

sm_drawBase()
{
	self sm_destroyHud();
	self.sm_hBg = self sm_box(120, -165, 240, 335, (0, 0, 0), 0.75, 1);
	self.sm_hAccent = self sm_box(120, -165, 240, 4, self.sm_theme, 1, 2);
	self.sm_hBar = self sm_box(120, -115, 240, 22, self.sm_theme, 0.6, 2);
	self.sm_hTitle = self sm_text(132, -140, 1.8, 4);
	self.sm_hLines = [];
	for(i = 0; i < level.sm_maxLines; i++)
		self.sm_hLines[i] = self sm_text(134, -104 + (i * 22), 1.4, 4);
	self.sm_hFoot = self sm_text(132, 152, 1.4, 4);
	self.sm_hFoot.color = (0.75, 0.75, 0.75);
	self.sm_hFoot setText("Aim/Shoot Scroll   X Select   Knife Back");
}

sm_destroyHud()
{
	if(isDefined(self.sm_hBg))
		self.sm_hBg destroy();
	if(isDefined(self.sm_hAccent))
		self.sm_hAccent destroy();
	if(isDefined(self.sm_hBar))
		self.sm_hBar destroy();
	if(isDefined(self.sm_hTitle))
		self.sm_hTitle destroy();
	if(isDefined(self.sm_hFoot))
		self.sm_hFoot destroy();
	if(isDefined(self.sm_hLines))
	{
		for(i = 0; i < self.sm_hLines.size; i++)
		{
			if(isDefined(self.sm_hLines[i]))
				self.sm_hLines[i] destroy();
		}
	}
	self.sm_hBg = undefined;
	self.sm_hAccent = undefined;
	self.sm_hBar = undefined;
	self.sm_hTitle = undefined;
	self.sm_hFoot = undefined;
	self.sm_hLines = undefined;
}

sm_render()
{
	if(!isDefined(self.sm_hLines))
		return;
	total = self.sm_labels.size;
	if(self.sm_cursor > total - 1)
		self.sm_cursor = total - 1;
	if(self.sm_cursor < 0)
		self.sm_cursor = 0;
	if(self.sm_cursor < self.sm_first)
		self.sm_first = self.sm_cursor;
	if(self.sm_cursor > self.sm_first + level.sm_maxLines - 1)
		self.sm_first = self.sm_cursor - level.sm_maxLines + 1;
	self.sm_hTitle setText(self.sm_title);
	for(i = 0; i < level.sm_maxLines; i++)
	{
		idx = self.sm_first + i;
		if(idx < total)
		{
			label = self.sm_labels[idx];
			if(isDefined(self.sm_keys[idx]))
			{
				if(self sm_isOn(self.sm_keys[idx]))
					label = label + "  ^2ON";
				else
					label = label + "  ^1OFF";
			}
			if(self.sm_kind[idx] == "menu" || self.sm_kind[idx] == "player")
				label = label + "  >";
			self.sm_hLines[i] setText(label);
			self.sm_hLines[i].alpha = 1;
		}
		else
		{
			self.sm_hLines[i].alpha = 0;
		}
	}
	if(total == 0)
		self.sm_hBar.alpha = 0;
	else
		self.sm_hBar.alpha = 0.6;
	self.sm_hBar.y = -115 + ((self.sm_cursor - self.sm_first) * 22);
}

sm_setTheme(color, name)
{
	self.sm_theme = color;
	if(isDefined(self.sm_hAccent))
		self.sm_hAccent.color = color;
	if(isDefined(self.sm_hBar))
		self.sm_hBar.color = color;
	self iPrintln("Theme: " + name);
}

sm_about(a1, a2)
{
	self iPrintlnBold("^2Shmees Menu^7 v" + level.sm_version);
	self iPrintln("Made by Shmees - youtube.com/@Shmees14");
	self iPrintln("Free at github.com/ShmeeMcgee");
}

sm_god(a1, a2)
{
	on = self sm_flip("god");
	self sm_say("God Mode", on);
	if(on)
	{
		self thread sm_godLoop();
	}
	else
	{
		self notify("sm_god_off");
		self.maxhealth = 100;
		if(self.health > 100)
			self.health = 100;
	}
}

sm_godLoop()
{
	self endon("disconnect");
	self endon("sm_god_off");
	for(;;)
	{
		if(self.health < 900000)
		{
			self.maxhealth = 999999;
			self.health = 999999;
		}
		wait 0.05;
	}
}

sm_ufo(a1, a2)
{
	on = self sm_flip("ufo");
	self sm_say("UFO Mode", on);
	self.ufo = on;
}

sm_ammo(a1, a2)
{
	on = self sm_flip("ammo");
	self sm_say("Infinite Ammo", on);
	if(on)
		self thread sm_ammoLoop();
	else
		self notify("sm_ammo_off");
}

sm_ammoLoop()
{
	self endon("disconnect");
	self endon("sm_ammo_off");
	for(;;)
	{
		w = self getCurrentWeapon();
		if(isDefined(w) && w != "none")
		{
			self giveMaxAmmo(w);
			self setWeaponAmmoClip(w, 999);
		}
		wait 0.1;
	}
}

sm_speed(a1, a2)
{
	on = self sm_flip("speed");
	self sm_say("Super Speed", on);
	if(on)
	{
		self thread sm_speedLoop();
	}
	else
	{
		self notify("sm_speed_off");
		self setMoveSpeedScale(1);
	}
}

sm_speedLoop()
{
	self endon("disconnect");
	self endon("sm_speed_off");
	for(;;)
	{
		self setMoveSpeedScale(2.2);
		wait 0.25;
	}
}

sm_aimPoint()
{
	start = self.origin + (0, 0, 60);
	dir = anglesToForward(self getPlayerAngles());
	tr = bulletTrace(start, start + (dir * 100000), true, self);
	return tr["position"];
}

sm_teleportAim(a1, a2)
{
	self setOrigin(self sm_aimPoint());
	self iPrintln("Teleported");
}

sm_savePos(a1, a2)
{
	self.sm_savedPos = self.origin;
	self.sm_savedAng = self getPlayerAngles();
	self iPrintln("Position ^2saved");
}

sm_loadPos(a1, a2)
{
	if(!isDefined(self.sm_savedPos))
	{
		self iPrintln("Save a position first");
		return;
	}
	self setOrigin(self.sm_savedPos);
	self setPlayerAngles(self.sm_savedAng);
	self iPrintln("Position ^2loaded");
}

sm_give(w, a2)
{
	self giveWeapon(w);
	self giveMaxAmmo(w);
	self switchToWeapon(w);
	self iPrintln("Gave ^2" + w);
}

sm_maxAmmo(a1, a2)
{
	w = self getCurrentWeapon();
	if(isDefined(w) && w != "none")
		self giveMaxAmmo(w);
	self iPrintln("Max ammo");
}

sm_takeWeapon(a1, a2)
{
	w = self getCurrentWeapon();
	if(isDefined(w) && w != "none")
		self takeWeapon(w);
}

sm_perk(p, name)
{
	self setPerk(p);
	self iPrintln("Gave ^2" + name);
}

// ------------------------------------------------------------- MP mods ----

sm_thirdPerson(a1, a2)
{
	on = self sm_flip("third");
	self sm_say("Third Person", on);
	if(on)
		self setClientDvar("cg_thirdPerson", "1");
	else
		self setClientDvar("cg_thirdPerson", "0");
}

sm_invisible(a1, a2)
{
	on = self sm_flip("invis");
	self sm_say("Invisible", on);
	if(on)
		self hide();
	else
		self show();
}

sm_exBullets(a1, a2)
{
	on = self sm_flip("exb");
	self sm_say("Explosive Bullets", on);
	if(on)
		self thread sm_exLoop();
	else
		self notify("sm_exb_off");
}

sm_exLoop()
{
	self endon("disconnect");
	self endon("sm_exb_off");
	for(;;)
	{
		self waittill("weapon_fired");
		pos = self sm_aimPoint();
		RadiusDamage(pos, 220, 200, 40, self);
		earthquake(0.35, 0.4, pos, 500);
	}
}

sm_quake(a1, a2)
{
	earthquake(0.6, 2, self.origin, 1000);
}

sm_suicide(a1, a2)
{
	if(self.sm_open)
		self sm_closeMenu();
	self suicide();
}

sm_dropWeapon(a1, a2)
{
	w = self getCurrentWeapon();
	if(isDefined(w) && w != "none")
		self dropItem(w);
}

sm_allPerks(list, a2)
{
	for(i = 0; i < list.size; i++)
		self setPerk(list[i]);
	self iPrintln("All perks ^2given");
}

// ------------------------------------------------------------ lobby mods ----

sm_dvarToggle(key, a2)
{
	on = self sm_flip(key);
	if(key == "ljump")
	{
		if(on)
		{
			setDvar("jump_height", "999");
			setDvar("bg_fallDamageMinHeight", "9998");
			setDvar("bg_fallDamageMaxHeight", "9999");
		}
		else
		{
			setDvar("jump_height", "39");
			setDvar("bg_fallDamageMinHeight", "128");
			setDvar("bg_fallDamageMaxHeight", "300");
		}
		iPrintln("Super Jump " + sm_onOff(on));
	}
	else if(key == "lgrav")
	{
		if(on)
			setDvar("g_gravity", "150");
		else
			setDvar("g_gravity", "800");
		iPrintln("Low Gravity " + sm_onOff(on));
	}
	else if(key == "lspeed")
	{
		if(on)
			setDvar("g_speed", "400");
		else
			setDvar("g_speed", "190");
		iPrintln("Super Speed (everyone) " + sm_onOff(on));
	}
	else if(key == "lslow")
	{
		if(on)
			setDvar("timescale", "0.5");
		else
			setDvar("timescale", "1");
		iPrintln("Slow Motion " + sm_onOff(on));
	}
}

sm_onOff(on)
{
	if(on)
		return "^2ON";
	return "^1OFF";
}

sm_everyone(a1, a2)
{
	on = self sm_flip("everyone");
	level.sm_everyone = on;
	if(on)
		iPrintln("^2Shmees Menu^7 is open to everyone - Aim + Knife");
	else
		iPrintln("^2Shmees Menu^7 is host only again");
}

sm_unlimited(a1, a2)
{
	gt = getDvar("g_gametype");
	setDvar("scr_" + gt + "_timelimit", "0");
	setDvar("scr_" + gt + "_scorelimit", "0");
	self iPrintln("No time or score limit after a Fast Restart");
}

sm_restart(a1, a2)
{
	map_restart(false);
}

sm_vision(name, a2)
{
	if(name == "map")
		name = getDvar("mapname");
	VisionSetNaked(name, 1);
}

// --------------------------------------------------------- player actions ----

sm_targetOk()
{
	if(!isDefined(self.sm_target) || !isPlayer(self.sm_target))
	{
		self iPrintln("That player has left");
		return false;
	}
	return true;
}

sm_pAccess(a1, a2)
{
	if(!self sm_targetOk())
		return;
	t = self.sm_target;
	if(isDefined(t.sm_access) && t.sm_access)
	{
		if(t == self)
		{
			self iPrintln("You can't take the host's menu");
			return;
		}
		t.sm_access = false;
		if(t.sm_open)
			t sm_closeMenu();
		self iPrintln("Menu taken from " + t.name);
	}
	else
	{
		t.sm_access = true;
		t iPrintlnBold("You got ^2Shmees Menu^7 - Aim + Knife");
		self iPrintln("Menu given to " + t.name);
	}
}

sm_pBring(a1, a2)
{
	if(self sm_targetOk())
		self.sm_target setOrigin(self.origin);
}

sm_pGoto(a1, a2)
{
	if(self sm_targetOk())
		self setOrigin(self.sm_target.origin);
}

sm_pFreeze(a1, a2)
{
	if(!self sm_targetOk())
		return;
	t = self.sm_target;
	if(isDefined(t.sm_frozen) && t.sm_frozen)
	{
		t.sm_frozen = false;
		t freezeControls(false);
		self iPrintln(t.name + " ^2unfrozen");
	}
	else
	{
		t.sm_frozen = true;
		t freezeControls(true);
		self iPrintln(t.name + " ^1frozen");
	}
}

sm_pKill(a1, a2)
{
	if(self sm_targetOk())
		self.sm_target suicide();
}

sm_pKick(a1, a2)
{
	if(!self sm_targetOk())
		return;
	if(self.sm_target == self)
	{
		self iPrintln("You can't kick yourself");
		return;
	}
	kick(self.sm_target getEntityNumber());
	self sm_back();
}

// ---------------------------------------------------------------- menus ----

sm_build(id)
{
	switch(id)
	{
		case "main":
			self sm_start("Shmees Menu");
			self sm_addMenu("Main Mods", "mods");
			self sm_addMenu("Weapons", "weapons");
			self sm_addMenu("Perks", "perks");
			self sm_addMenu("Fun", "fun");
			if(self sm_isHost())
			{
				self sm_addMenu("Lobby", "lobby");
				self sm_addMenu("Players", "players");
			}
			self sm_addMenu("Settings", "settings");
			break;
		case "mods":
			self sm_start("Main Mods");
			self sm_add("God Mode", ::sm_god, undefined, undefined, "god");
			self sm_add("Infinite Ammo", ::sm_ammo, undefined, undefined, "ammo");
			self sm_add("UFO Mode", ::sm_ufo, undefined, undefined, "ufo");
			self sm_add("Super Speed", ::sm_speed, undefined, undefined, "speed");
			self sm_add("Third Person", ::sm_thirdPerson, undefined, undefined, "third");
			self sm_add("Invisible", ::sm_invisible, undefined, undefined, "invis");
			self sm_add("Teleport to Crosshair", ::sm_teleportAim);
			self sm_add("Save Position", ::sm_savePos);
			self sm_add("Load Position", ::sm_loadPos);
			self sm_add("Suicide", ::sm_suicide);
			break;
		case "weapons":
			self sm_start("Weapons");
			self sm_addMenu("SMGs", "wcat0");
			self sm_addMenu("Rifles", "wcat1");
			self sm_addMenu("Snipers", "wcat2");
			self sm_addMenu("MGs & Shotguns", "wcat3");
			self sm_addMenu("Pistols & Launchers", "wcat4");
			self sm_add("Max Ammo", ::sm_maxAmmo);
			self sm_add("Take Current Weapon", ::sm_takeWeapon);
			self sm_add("Drop Current Weapon", ::sm_dropWeapon);
			break;
		case "wcat0":
			self sm_start("SMGs");
			self sm_add("thompson_mp", ::sm_give, "thompson_mp");
			self sm_add("mp40_mp", ::sm_give, "mp40_mp");
			self sm_add("ppsh_mp", ::sm_give, "ppsh_mp");
			self sm_add("type100smg_mp", ::sm_give, "type100smg_mp");
			break;
		case "wcat1":
			self sm_start("Rifles");
			self sm_add("stg44_mp", ::sm_give, "stg44_mp");
			self sm_add("m1garand_mp", ::sm_give, "m1garand_mp");
			self sm_add("svt40_mp", ::sm_give, "svt40_mp");
			self sm_add("gewehr43_mp", ::sm_give, "gewehr43_mp");
			self sm_add("m1carbine_mp", ::sm_give, "m1carbine_mp");
			break;
		case "wcat2":
			self sm_start("Snipers");
			self sm_add("kar98k_scoped_mp", ::sm_give, "kar98k_scoped_mp");
			self sm_add("mosinrifle_scoped_mp", ::sm_give, "mosinrifle_scoped_mp");
			self sm_add("springfield_scoped_mp", ::sm_give, "springfield_scoped_mp");
			self sm_add("ptrs41_mp", ::sm_give, "ptrs41_mp");
			break;
		case "wcat3":
			self sm_start("MGs & Shotguns");
			self sm_add("fg42_mp", ::sm_give, "fg42_mp");
			self sm_add("bar_mp", ::sm_give, "bar_mp");
			self sm_add("mg42_mp", ::sm_give, "mg42_mp");
			self sm_add("dp28_mp", ::sm_give, "dp28_mp");
			self sm_add("shotgun_mp", ::sm_give, "shotgun_mp");
			self sm_add("doublebarreledshotgun_mp", ::sm_give, "doublebarreledshotgun_mp");
			break;
		case "wcat4":
			self sm_start("Pistols & Launchers");
			self sm_add("colt_mp", ::sm_give, "colt_mp");
			self sm_add("walther_mp", ::sm_give, "walther_mp");
			self sm_add("357magnum_mp", ::sm_give, "357magnum_mp");
			self sm_add("nambu_mp", ::sm_give, "nambu_mp");
			self sm_add("tokarev_mp", ::sm_give, "tokarev_mp");
			self sm_add("bazooka_mp", ::sm_give, "bazooka_mp");
			break;
		case "perks":
			self sm_start("Perks");
			list = [];
			list[0] = "specialty_bulletdamage";
			list[1] = "specialty_armorvest";
			list[2] = "specialty_fastreload";
			list[3] = "specialty_rof";
			list[4] = "specialty_bulletpenetration";
			list[5] = "specialty_longersprint";
			list[6] = "specialty_bulletaccuracy";
			list[7] = "specialty_quieter";
			list[8] = "specialty_holdbreath";
			list[9] = "specialty_gpsjammer";
			list[10] = "specialty_flakjacket";
			list[11] = "specialty_pistoldeath";
			self sm_add("Give All Perks", ::sm_allPerks, list);
			self sm_add("Stopping Power", ::sm_perk, "specialty_bulletdamage", "Stopping Power");
			self sm_add("Juggernaut", ::sm_perk, "specialty_armorvest", "Juggernaut");
			self sm_add("Sleight of Hand", ::sm_perk, "specialty_fastreload", "Sleight of Hand");
			self sm_add("Double Tap", ::sm_perk, "specialty_rof", "Double Tap");
			self sm_add("Deep Impact", ::sm_perk, "specialty_bulletpenetration", "Deep Impact");
			self sm_add("Extreme Conditioning", ::sm_perk, "specialty_longersprint", "Extreme Conditioning");
			self sm_add("Steady Aim", ::sm_perk, "specialty_bulletaccuracy", "Steady Aim");
			self sm_add("Dead Silence", ::sm_perk, "specialty_quieter", "Dead Silence");
			self sm_add("Iron Lungs", ::sm_perk, "specialty_holdbreath", "Iron Lungs");
			self sm_add("Camouflage", ::sm_perk, "specialty_gpsjammer", "Camouflage");
			self sm_add("Flak Jacket", ::sm_perk, "specialty_flakjacket", "Flak Jacket");
			self sm_add("Second Chance", ::sm_perk, "specialty_pistoldeath", "Second Chance");
			break;
		case "fun":
			self sm_start("Fun");
			self sm_add("Explosive Bullets", ::sm_exBullets, undefined, undefined, "exb");
			self sm_add("Earthquake", ::sm_quake);
			break;
		case "lobby":
			self sm_start("Lobby");
			self sm_add("Menu for Everyone", ::sm_everyone, undefined, undefined, "everyone");
			self sm_add("Super Jump", ::sm_dvarToggle, "ljump", undefined, "ljump");
			self sm_add("Low Gravity", ::sm_dvarToggle, "lgrav", undefined, "lgrav");
			self sm_add("Super Speed (Everyone)", ::sm_dvarToggle, "lspeed", undefined, "lspeed");
			self sm_add("Slow Motion", ::sm_dvarToggle, "lslow", undefined, "lslow");
			self sm_addMenu("Visions", "visions");
			self sm_add("No Time or Score Limit", ::sm_unlimited);
			self sm_add("Fast Restart", ::sm_restart);
			break;
		case "visions":
			self sm_start("Visions");
			self sm_add("Normal", ::sm_vision, "map");
			self sm_add("Black and White", ::sm_vision, "cheat_bw");
			self sm_add("Night", ::sm_vision, "cheat_chaplinnight");
			break;
		case "players":
			self sm_start("Players");
			players = getEntArray("player", "classname");
			for(i = 0; i < players.size; i++)
				self sm_addPlayer(players[i].name, players[i]);
			break;
		case "player":
			name = "Player";
			if(isDefined(self.sm_target) && isPlayer(self.sm_target))
				name = self.sm_target.name;
			self sm_start(name);
			self sm_add("Give / Take Menu", ::sm_pAccess);
			self sm_add("Teleport to Me", ::sm_pBring);
			self sm_add("Teleport to Them", ::sm_pGoto);
			self sm_add("Freeze / Unfreeze", ::sm_pFreeze);
			self sm_add("Kill", ::sm_pKill);
			self sm_add("Kick", ::sm_pKick);
			break;
		case "settings":
			self sm_start("Settings");
			self sm_addMenu("Menu Color", "themes");
			self sm_add("About", ::sm_about);
			self sm_add("Close Menu", ::sm_closeFromMenu);
			break;
		case "themes":
			self sm_start("Menu Color");
			self sm_add("Shmees Green", ::sm_setTheme, (0.61, 0.88, 0.24), "Shmees Green");
			self sm_add("Red", ::sm_setTheme, (0.9, 0.2, 0.2), "Red");
			self sm_add("Blue", ::sm_setTheme, (0.2, 0.55, 1), "Blue");
			self sm_add("Purple", ::sm_setTheme, (0.6, 0.3, 0.95), "Purple");
			self sm_add("Gold", ::sm_setTheme, (1, 0.78, 0.2), "Gold");
			self sm_add("White", ::sm_setTheme, (0.9, 0.9, 0.9), "White");
			break;
		default:
			self sm_start("Shmees Menu");
			self sm_add("(empty)", ::sm_nothing);
			break;
	}
}

sm_closeFromMenu(a1, a2)
{
	self sm_closeMenu();
}
