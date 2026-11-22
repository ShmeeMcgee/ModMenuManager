// ============================================================================
//  SHMEES MENU v1.0  -  World at War Zombies
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
	players = getEntArray("player", "classname");
	for(i = 0; i < players.size; i++)
		players[i] thread sm_onPlayer();
}

sm_onConnect()
{
	for(;;)
	{
		level waittill("connecting", player);
		player thread sm_onPlayer();
	}
}

sm_onPlayer()
{
	self endon("disconnect");
	if(isDefined(self.sm_ready))
		return;
	self.sm_ready = true;
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
			self iPrintlnBold("^2Shmees Zombies Menu^7 loaded");
			self iPrintln("Aim + Knife to open the menu");
		}
	}
}

sm_isZombies()
{
	if(isDefined(level.zombiemode) && level.zombiemode)
		return true;
	if(isSubStr(getDvar("mapname"), "zombie"))
		return true;
	return false;
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
	h.font = "default";
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
	self.god = on;
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

// -------------------------------------------------------- zombies mods ----

sm_ignoreMe(a1, a2)
{
	on = self sm_flip("ignore");
	self sm_say("Zombies Ignore Me", on);
	self.ignoreme = on;
}

sm_points(amount, a2)
{
	self.score = self.score + amount;
	self iPrintln("^2+" + amount + "^7 points (counter updates on your next kill)");
}

sm_zmGive(w, a2)
{
	self giveWeapon(w);
	self giveMaxAmmo(w);
	self switchToWeapon(w);
	self iPrintln("Gave ^2" + w);
}

sm_pap(a1, a2)
{
	w = self getCurrentWeapon();
	if(!isDefined(level.zombie_weapons) || !isDefined(level.zombie_weapons[w]))
	{
		self iPrintln("Can't Pack-a-Punch this weapon");
		return;
	}
	up = level.zombie_weapons[w].upgrade_name;
	if(!isDefined(up))
	{
		self iPrintln("This weapon has no Pack-a-Punch version here");
		return;
	}
	self takeWeapon(w);
	self giveWeapon(up);
	self giveMaxAmmo(up);
	self switchToWeapon(up);
	self iPrintln("Pack-a-Punched ^2" + w);
}

sm_zmPerk(p, name)
{
	self setPerk(p);
	if(p == "specialty_armorvest" && !self sm_isOn("god"))
	{
		self.maxhealth = 250;
		self.health = 250;
	}
	self iPrintln("Gave ^2" + name);
}

sm_zmAllPerks(list, names)
{
	for(i = 0; i < list.size; i++)
		self setPerk(list[i]);
	if(!self sm_isOn("god"))
	{
		self.maxhealth = 250;
		self.health = 250;
	}
	self iPrintln("All perks ^2given");
}

sm_killZombies(a1, a2)
{
	ai = getAiArray("axis");
	for(i = 0; i < ai.size; i++)
	{
		if(isDefined(ai[i]) && isAlive(ai[i]))
			ai[i] doDamage(ai[i].health + 666, ai[i].origin, self);
	}
	self iPrintln("Killed ^2" + ai.size + "^7 zombies");
}

sm_skipRound(extra, a2)
{
	if(isDefined(extra) && extra > 0 && isDefined(level.round_number))
		level.round_number = level.round_number + extra;
	level.zombie_total = 0;
	self sm_killZombies();
	self iPrintln("Round skipped");
}

sm_openDoors(a1, a2)
{
	saved = self.score;
	self.score = 9999999;
	names = [];
	names[0] = "zombie_door";
	names[1] = "zombie_debris";
	names[2] = "zombie_airlock_buy";
	count = 0;
	for(n = 0; n < names.size; n++)
	{
		ents = getEntArray(names[n], "targetname");
		for(i = 0; i < ents.size; i++)
		{
			ents[i] notify("trigger", self, true);
			count++;
		}
	}
	wait 1.5;
	self.score = saved;
	self iPrintln("Opened ^2" + count + "^7 doors and debris");
}

sm_power(a1, a2)
{
	names = [];
	names[0] = "use_power_switch";
	names[1] = "use_master_switch";
	names[2] = "use_elec_switch";
	found = false;
	for(n = 0; n < names.size; n++)
	{
		ents = getEntArray(names[n], "targetname");
		for(i = 0; i < ents.size; i++)
		{
			ents[i] notify("trigger", self);
			found = true;
		}
	}
	if(found)
		self iPrintln("Power ^2on");
	else
		self iPrintln("This map has no power switch");
}

sm_ignoreAll(a1, a2)
{
	on = self sm_flip("ignoreall");
	players = getEntArray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		players[i].ignoreme = on;
		players[i].sm_on["ignore"] = on;
	}
	self sm_say("Zombies Ignore Everyone", on);
}

sm_maxAmmoAll(a1, a2)
{
	players = getEntArray("player", "classname");
	for(i = 0; i < players.size; i++)
		players[i] sm_maxAmmo();
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
		t iPrintlnBold("You got ^2Shmees Zombies Menu^7 - Aim + Knife");
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

sm_pPoints(a1, a2)
{
	if(!self sm_targetOk())
		return;
	self.sm_target.score = self.sm_target.score + 10000;
	self iPrintln("Gave 10,000 points to " + self.sm_target.name);
}

sm_pGod(a1, a2)
{
	if(self sm_targetOk())
		self.sm_target sm_god();
}

sm_everyone(a1, a2)
{
	on = self sm_flip("everyone");
	level.sm_everyone = on;
	if(on)
		iPrintln("^2Shmees Zombies Menu^7 is open to everyone - Aim + Knife");
	else
		iPrintln("^2Shmees Zombies Menu^7 is host only again");
}

sm_closeFromMenu(a1, a2)
{
	self sm_closeMenu();
}

// ---------------------------------------------------------------- menus ----

sm_build(id)
{
	switch(id)
	{
		case "main":
			self sm_start("Shmees Zombies");
			self sm_addMenu("Main Mods", "mods");
			if(self sm_isZombies())
			{
				self sm_addMenu("Points", "points");
				self sm_addMenu("Weapons", "weapons");
				self sm_addMenu("Perks", "perks");
				if(self sm_isHost())
					self sm_addMenu("Zombies & Rounds", "rounds");
			}
			if(self sm_isHost())
				self sm_addMenu("Players", "players");
			self sm_addMenu("Settings", "settings");
			break;
		case "mods":
			self sm_start("Main Mods");
			self sm_add("God Mode", ::sm_god, undefined, undefined, "god");
			self sm_add("Infinite Ammo", ::sm_ammo, undefined, undefined, "ammo");
			self sm_add("UFO Mode", ::sm_ufo, undefined, undefined, "ufo");
			self sm_add("Super Speed", ::sm_speed, undefined, undefined, "speed");
			self sm_add("Zombies Ignore Me", ::sm_ignoreMe, undefined, undefined, "ignore");
			self sm_add("Teleport to Crosshair", ::sm_teleportAim);
			self sm_add("Save Position", ::sm_savePos);
			self sm_add("Load Position", ::sm_loadPos);
			break;
		case "points":
			self sm_start("Points");
			self sm_add("+1,000", ::sm_points, 1000);
			self sm_add("+10,000", ::sm_points, 10000);
			self sm_add("+100,000", ::sm_points, 100000);
			self sm_add("+500,000", ::sm_points, 500000);
			break;
		case "weapons":
			self sm_start("Weapons");
			self sm_addMenu("Give a Weapon", "zmweapons");
			self sm_add("Pack-a-Punch Current Weapon", ::sm_pap);
			self sm_add("Max Ammo", ::sm_maxAmmo);
			self sm_add("Take Current Weapon", ::sm_takeWeapon);
			break;
		case "zmweapons":
			self sm_start("Give a Weapon");
			if(isDefined(level.zombie_weapons))
			{
				keys = getArrayKeys(level.zombie_weapons);
				for(i = 0; i < keys.size && i < 60; i++)
					self sm_add(keys[i], ::sm_zmGive, keys[i]);
			}
			if(self.sm_labels.size == 0)
				self sm_add("(no weapons on this map)", ::sm_nothing);
			break;
		case "perks":
			self sm_start("Perks");
			list = [];
			list[0] = "specialty_armorvest";
			list[1] = "specialty_quickrevive";
			list[2] = "specialty_fastreload";
			list[3] = "specialty_rof";
			self sm_add("Give All Perks", ::sm_zmAllPerks, list);
			self sm_add("Juggernog", ::sm_zmPerk, "specialty_armorvest", "Juggernog");
			self sm_add("Quick Revive", ::sm_zmPerk, "specialty_quickrevive", "Quick Revive");
			self sm_add("Speed Cola", ::sm_zmPerk, "specialty_fastreload", "Speed Cola");
			self sm_add("Double Tap", ::sm_zmPerk, "specialty_rof", "Double Tap");
			break;
		case "rounds":
			self sm_start("Zombies & Rounds");
			self sm_add("Menu for Everyone", ::sm_everyone, undefined, undefined, "everyone");
			self sm_add("Kill All Zombies", ::sm_killZombies);
			self sm_add("Skip Round", ::sm_skipRound, 0);
			self sm_add("Jump 5 Rounds", ::sm_skipRound, 4);
			self sm_add("Jump 10 Rounds", ::sm_skipRound, 9);
			self sm_add("Zombies Ignore Everyone", ::sm_ignoreAll, undefined, undefined, "ignoreall");
			self sm_add("Open All Doors", ::sm_openDoors);
			self sm_add("Turn On Power", ::sm_power);
			self sm_add("Max Ammo for Everyone", ::sm_maxAmmoAll);
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
			self sm_add("Give 10,000 Points", ::sm_pPoints);
			self sm_add("Toggle God Mode", ::sm_pGod);
			self sm_add("Teleport to Me", ::sm_pBring);
			self sm_add("Teleport to Them", ::sm_pGoto);
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
			self sm_start("Shmees Zombies");
			self sm_add("(empty)", ::sm_nothing);
			break;
	}
}
