#!/usr/bin/env python3
"""
Generates the Shmees Menu GSC packages for CoD Xe (r351 layout).

  Multiplayer menus : CoD4, World at War, Modern Warfare 2, Black Ops
  Zombies menus     : World at War (Nazi Zombies), Black Ops (Zombies)

Output: out/<GAME>/files/_codxe/...   (ready to zip as a Mod Menu Manager package)
"""
import json
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), "ShmeesMenu")
VERSION = "1.0"

# ----------------------------------------------------------------------------
# Per-game data
# ----------------------------------------------------------------------------

GAMES = {
    "COD4": {
        "name": "Call of Duty 4",
        "engine": "iw3",
        "host": "entity",
        "ufo": "link",
        "weapons": [
            ("Assault Rifles", ["m16_mp", "ak47_mp", "m4_mp", "g3_mp", "g36c_mp", "m14_mp", "mp44_mp"]),
            ("SMGs", ["mp5_mp", "skorpion_mp", "uzi_mp", "ak74u_mp", "p90_mp"]),
            ("LMGs & Shotguns", ["saw_mp", "rpd_mp", "m60e4_mp", "winchester1200_mp", "m1014_mp"]),
            ("Snipers", ["m40a3_mp", "barrett_mp", "remington700_mp", "m21_mp", "dragunov_mp"]),
            ("Pistols & Launchers", ["beretta_mp", "colt45_mp", "usp_mp", "deserteagle_mp", "deserteaglegold_mp", "rpg_mp"]),
        ],
        "perks": [
            ("Stopping Power", "specialty_bulletdamage"), ("Juggernaut", "specialty_armorvest"),
            ("Sleight of Hand", "specialty_fastreload"), ("Double Tap", "specialty_rof"),
            ("Deep Impact", "specialty_bulletpenetration"), ("Extreme Conditioning", "specialty_longersprint"),
            ("Steady Aim", "specialty_bulletaccuracy"), ("Dead Silence", "specialty_quieter"),
            ("Iron Lungs", "specialty_holdbreath"), ("UAV Jammer", "specialty_gpsjammer"),
            ("Sonic Boom", "specialty_explosivedamage"),
        ],
        "killstreaks": [],
        "hook": "clientids",
    },
    "WAW": {
        "name": "World at War",
        "engine": "t4",
        "host": "entity",
        "ufo": "codxe",
        "weapons": [
            ("SMGs", ["thompson_mp", "mp40_mp", "ppsh_mp", "type100smg_mp"]),
            ("Rifles", ["stg44_mp", "m1garand_mp", "svt40_mp", "gewehr43_mp", "m1carbine_mp"]),
            ("Snipers", ["kar98k_scoped_mp", "mosinrifle_scoped_mp", "springfield_scoped_mp", "ptrs41_mp"]),
            ("MGs & Shotguns", ["fg42_mp", "bar_mp", "mg42_mp", "dp28_mp", "shotgun_mp", "doublebarreledshotgun_mp"]),
            ("Pistols & Launchers", ["colt_mp", "walther_mp", "357magnum_mp", "nambu_mp", "tokarev_mp", "bazooka_mp"]),
        ],
        "perks": [
            ("Stopping Power", "specialty_bulletdamage"), ("Juggernaut", "specialty_armorvest"),
            ("Sleight of Hand", "specialty_fastreload"), ("Double Tap", "specialty_rof"),
            ("Deep Impact", "specialty_bulletpenetration"), ("Extreme Conditioning", "specialty_longersprint"),
            ("Steady Aim", "specialty_bulletaccuracy"), ("Dead Silence", "specialty_quieter"),
            ("Iron Lungs", "specialty_holdbreath"), ("Camouflage", "specialty_gpsjammer"),
            ("Flak Jacket", "specialty_flakjacket"), ("Second Chance", "specialty_pistoldeath"),
        ],
        "killstreaks": [],
        "hook": "clientids",
        "zombies": {
            "hook": "music",
            "god": "codxe",
            "ufo": "codxe",
            "perks": [
                ("Juggernog", "specialty_armorvest"), ("Quick Revive", "specialty_quickrevive"),
                ("Speed Cola", "specialty_fastreload"), ("Double Tap", "specialty_rof"),
            ],
        },
    },
    "MW2": {
        "name": "Modern Warfare 2",
        "engine": "iw4",
        "host": "ishost",
        "ufo": "link",
        "weapons": [
            ("Assault Rifles", ["m4_mp", "famas_mp", "scar_mp", "tavor_mp", "fal_mp", "m16_mp", "masada_mp", "fn2000_mp", "ak47_mp"]),
            ("SMGs & LMGs", ["mp5k_mp", "ump45_mp", "kriss_mp", "p90_mp", "uzi_mp", "rpd_mp", "sa80_mp", "mg4_mp", "m240_mp", "aug_mp"]),
            ("Snipers", ["cheytac_mp", "barrett_mp", "wa2000_mp", "m21_mp"]),
            ("Shotguns", ["spas12_mp", "aa12_mp", "striker_mp", "ranger_mp", "m1014_mp", "model1887_mp"]),
            ("Pistols", ["pp2000_mp", "glock_mp", "beretta393_mp", "tmp_mp", "usp_mp", "coltanaconda_mp", "beretta_mp", "deserteagle_mp", "deserteaglegold_mp"]),
            ("Launchers & Special", ["at4_mp", "rpg_mp", "javelin_mp", "stinger_mp", "m79_mp", "defaultweapon_mp"]),
        ],
        "perks": [
            ("Marathon", "specialty_marathon"), ("Sleight of Hand", "specialty_fastreload"),
            ("Scavenger", "specialty_scavenger"), ("Bling", "specialty_bling"),
            ("Stopping Power", "specialty_bulletdamage"), ("Lightweight", "specialty_lightweight"),
            ("Hardline", "specialty_hardline"), ("Cold-Blooded", "specialty_coldblooded"),
            ("Danger Close", "specialty_explosivedamage"), ("Commando", "specialty_extendedmelee"),
            ("Steady Aim", "specialty_bulletaccuracy"), ("Scrambler", "specialty_localjammer"),
            ("Ninja", "specialty_heartbreaker"), ("SitRep", "specialty_detectexplosive"),
            ("Last Stand", "specialty_pistoldeath"),
        ],
        "killstreaks": [
            ("UAV", "uav"), ("Counter-UAV", "counter_uav"), ("Care Package", "airdrop"),
            ("Sentry Gun", "sentry"), ("Predator Missile", "predator_missile"),
            ("Precision Airstrike", "precision_airstrike"), ("Harrier Strike", "harrier_airstrike"),
            ("Attack Helicopter", "helicopter"), ("Emergency Airdrop", "airdrop_mega"),
            ("Pave Low", "helicopter_flares"), ("Stealth Bomber", "stealth_airstrike"),
            ("Chopper Gunner", "helicopter_minigun"), ("AC-130", "ac130"), ("EMP", "emp"), ("Tactical Nuke", "nuke"),
        ],
        "hook": "deathicons",
    },
    "BO1": {
        "name": "Black Ops",
        "engine": "t5",
        "host": "ishost",
        "ufo": "link",
        "weapons": [
            ("Assault Rifles", ["m16_mp", "enfield_mp", "m14_mp", "famas_mp", "galil_mp", "aug_mp", "fnfal_mp", "ak47_mp", "commando_mp", "g11_mp"]),
            ("SMGs", ["mp5k_mp", "skorpion_mp", "mac11_mp", "ak74u_mp", "uzi_mp", "pm63_mp", "mpl_mp", "spectre_mp", "kiparis_mp"]),
            ("LMGs & Shotguns", ["hk21_mp", "rpk_mp", "m60_mp", "stoner63_mp", "olympia_mp", "stakeout_mp", "spas_mp", "hs10_mp"]),
            ("Snipers", ["dragunov_mp", "wa2000_mp", "l96a1_mp", "psg1_mp"]),
            ("Pistols & Launchers", ["asp_mp", "m1911_mp", "makarov_mp", "python_mp", "cz75_mp", "m72_law_mp", "rpg_mp", "strela_mp", "china_lake_mp"]),
            ("Specials", ["crossbow_explosive_mp", "knife_ballistic_mp", "minigun_mp", "m202_flash_mp"]),
        ],
        "perks": [],
        "killstreaks": [],
        "hook": "clientids",
        "zombies": {
            "hook": "ffotd",
            "god": "health",
            "ufo": "link",
            "perks": [
                ("Juggernog", "specialty_armorvest"), ("Quick Revive", "specialty_quickrevive"),
                ("Speed Cola", "specialty_fastreload"), ("Double Tap", "specialty_rof"),
                ("Stamin-Up", "specialty_longersprint"), ("PhD Flopper", "specialty_flakjacket"),
                ("Deadshot Daiquiri", "specialty_deadshot"), ("Mule Kick", "specialty_additionalprimaryweapon"),
            ],
        },
    },
}

THEMES = [
    ("Shmees Green", "(0.61, 0.88, 0.24)"),
    ("Red", "(0.9, 0.2, 0.2)"),
    ("Blue", "(0.2, 0.55, 1)"),
    ("Purple", "(0.6, 0.3, 0.95)"),
    ("Gold", "(1, 0.78, 0.2)"),
    ("White", "(0.9, 0.9, 0.9)"),
]

HEADER = """// ============================================================================
//  SHMEES MENU v{ver}  -  {title}
//  by Shmees  |  youtube.com/@Shmees14  |  github.com/ShmeeMcgee
//
//  Loaded by CoD Xe's raw GSC loader. Installed with Mod Menu Manager.
//  Open: Aim + Knife   Scroll: Aim / Shoot   Select: Use (X)   Back: Knife
//  For offline play, private matches and system link only.
// ============================================================================
"""


def q(s):
    """GSC string literal."""
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


# ----------------------------------------------------------------------------
# Shared menu engine (MP and Zombies)
# ----------------------------------------------------------------------------

def engine(mode, font, footer, host_check):
    """The parts both menus share: HUD, controls, navigation."""
    return f"""
// ---------------------------------------------------------------- engine ----

sm_hasAccess()
{{
	if(isDefined(self.sm_access) && self.sm_access)
		return true;
	if(isDefined(level.sm_everyone) && level.sm_everyone)
		return true;
	return false;
}}

sm_isHost()
{{
{host_check}
}}

sm_monitor()
{{
	self endon("disconnect");
	self notify("sm_monitor_stop");
	self endon("sm_monitor_stop");
	for(;;)
	{{
		if(!self.sm_open)
		{{
			if(self sm_hasAccess() && isAlive(self) && !self sm_gameOver() && self adsButtonPressed() && self meleeButtonPressed())
			{{
				self sm_openMenu("main");
				while(self adsButtonPressed() || self meleeButtonPressed())
					wait 0.05;
			}}
		}}
		else
		{{
			if(!isAlive(self) || self sm_gameOver())
			{{
				self sm_closeMenu();
			}}
			else if(self adsButtonPressed())
			{{
				self sm_scroll(-1);
				wait 0.12;
			}}
			else if(self attackButtonPressed())
			{{
				self sm_scroll(1);
				wait 0.12;
			}}
			else if(self useButtonPressed())
			{{
				self sm_select();
				wait 0.25;
			}}
			else if(self meleeButtonPressed())
			{{
				self sm_back();
				wait 0.25;
			}}
		}}
		wait 0.05;
	}}
}}

sm_gameOver()
{{
	if(isDefined(level.gameEnded) && level.gameEnded)
		return true;
	return false;
}}

sm_openMenu(id)
{{
	self.sm_open = true;
	self freezeControls(true);
	self sm_drawBase();
	self.sm_stackIds = [];
	self.sm_stackCur = [];
	self sm_goto(id, 0);
}}

sm_closeMenu()
{{
	self.sm_open = false;
	self freezeControls(false);
	self sm_destroyHud();
}}

sm_goto(id, cursor)
{{
	self.sm_menuId = id;
	self.sm_cursor = cursor;
	self.sm_first = 0;
	self sm_build(id);
	self sm_render();
}}

sm_enter(id)
{{
	n = self.sm_stackIds.size;
	self.sm_stackIds[n] = self.sm_menuId;
	self.sm_stackCur[n] = self.sm_cursor;
	self sm_goto(id, 0);
}}

sm_back()
{{
	n = self.sm_stackIds.size;
	if(n == 0)
	{{
		self sm_closeMenu();
		return;
	}}
	id = self.sm_stackIds[n - 1];
	cur = self.sm_stackCur[n - 1];
	self.sm_stackIds[n - 1] = undefined;
	self.sm_stackCur[n - 1] = undefined;
	self sm_goto(id, cur);
}}

sm_scroll(dir)
{{
	total = self.sm_labels.size;
	if(total == 0)
		return;
	self.sm_cursor = self.sm_cursor + dir;
	if(self.sm_cursor < 0)
		self.sm_cursor = total - 1;
	if(self.sm_cursor > total - 1)
		self.sm_cursor = 0;
	self sm_render();
}}

sm_select()
{{
	i = self.sm_cursor;
	if(i >= self.sm_labels.size)
		return;
	kind = self.sm_kind[i];
	if(kind == "menu")
	{{
		self sm_enter(self.sm_a1[i]);
		return;
	}}
	if(kind == "player")
	{{
		self.sm_target = self.sm_a1[i];
		self sm_enter("player");
		return;
	}}
	self thread [[ self.sm_funcs[i] ]](self.sm_a1[i], self.sm_a2[i]);
	wait 0.1;
	if(self.sm_open)
	{{
		if(isDefined(self.sm_rebuild) && self.sm_rebuild)
		{{
			self.sm_rebuild = false;
			cur = self.sm_cursor;
			self sm_build(self.sm_menuId);
			self.sm_cursor = cur;
		}}
		self sm_render();
	}}
}}

sm_start(title)
{{
	self.sm_title = title;
	self.sm_labels = [];
	self.sm_kind = [];
	self.sm_funcs = [];
	self.sm_a1 = [];
	self.sm_a2 = [];
	self.sm_keys = [];
}}

sm_add(label, func, a1, a2, key)
{{
	i = self.sm_labels.size;
	self.sm_labels[i] = label;
	self.sm_kind[i] = "func";
	self.sm_funcs[i] = func;
	self.sm_a1[i] = a1;
	self.sm_a2[i] = a2;
	self.sm_keys[i] = key;
}}

sm_addMenu(label, id)
{{
	i = self.sm_labels.size;
	self.sm_labels[i] = label;
	self.sm_kind[i] = "menu";
	self.sm_a1[i] = id;
}}

sm_addPlayer(label, player)
{{
	i = self.sm_labels.size;
	self.sm_labels[i] = label;
	self.sm_kind[i] = "player";
	self.sm_a1[i] = player;
}}

sm_nothing(a1, a2)
{{
}}

sm_isOn(key)
{{
	if(isDefined(self.sm_on[key]) && self.sm_on[key])
		return true;
	return false;
}}

sm_flip(key)
{{
	if(self sm_isOn(key))
	{{
		self.sm_on[key] = false;
		return false;
	}}
	self.sm_on[key] = true;
	return true;
}}

sm_say(name, state)
{{
	if(state)
		self iPrintln(name + " ^2ON");
	else
		self iPrintln(name + " ^1OFF");
}}

// ------------------------------------------------------------------- HUD ----

sm_text(x, y, scale, sort)
{{
	h = newClientHudElem(self);
	h.horzAlign = "center";
	h.vertAlign = "middle";
	h.alignX = "left";
	h.alignY = "middle";
	h.x = x;
	h.y = y;
	h.font = "{font}";
	h.fontScale = scale;
	h.color = (1, 1, 1);
	h.alpha = 1;
	h.sort = sort;
	h.foreground = true;
	h.hideWhenInMenu = true;
	h.archived = false;
	return h;
}}

sm_box(x, y, w, ht, color, alpha, sort)
{{
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
}}

sm_drawBase()
{{
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
	self.sm_hFoot setText({q(footer)});
}}

sm_destroyHud()
{{
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
	{{
		for(i = 0; i < self.sm_hLines.size; i++)
		{{
			if(isDefined(self.sm_hLines[i]))
				self.sm_hLines[i] destroy();
		}}
	}}
	self.sm_hBg = undefined;
	self.sm_hAccent = undefined;
	self.sm_hBar = undefined;
	self.sm_hTitle = undefined;
	self.sm_hFoot = undefined;
	self.sm_hLines = undefined;
}}

sm_render()
{{
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
	{{
		idx = self.sm_first + i;
		if(idx < total)
		{{
			label = self.sm_labels[idx];
			if(isDefined(self.sm_keys[idx]))
			{{
				if(self sm_isOn(self.sm_keys[idx]))
					label = label + "  ^2ON";
				else
					label = label + "  ^1OFF";
			}}
			if(self.sm_kind[idx] == "menu" || self.sm_kind[idx] == "player")
				label = label + "  >";
			self.sm_hLines[i] setText(label);
			self.sm_hLines[i].alpha = 1;
		}}
		else
		{{
			self.sm_hLines[i].alpha = 0;
		}}
	}}
	if(total == 0)
		self.sm_hBar.alpha = 0;
	else
		self.sm_hBar.alpha = 0.6;
	self.sm_hBar.y = -115 + ((self.sm_cursor - self.sm_first) * 22);
}}

sm_setTheme(color, name)
{{
	self.sm_theme = color;
	if(isDefined(self.sm_hAccent))
		self.sm_hAccent.color = color;
	if(isDefined(self.sm_hBar))
		self.sm_hBar.color = color;
	self iPrintln("Theme: " + name);
}}

sm_about(a1, a2)
{{
	self iPrintlnBold("^2Shmees Menu^7 v" + level.sm_version);
	self iPrintln("Made by Shmees - youtube.com/@Shmees14");
	self iPrintln("Free at github.com/ShmeeMcgee");
}}
"""


# ----------------------------------------------------------------------------
# Shared player mods (work in MP and Zombies)
# ----------------------------------------------------------------------------

def common_mods(god_style, ufo_style):
    if god_style == "codxe":
        god = """
sm_god(a1, a2)
{
	on = self sm_flip("god");
	self sm_say("God Mode", on);
	self.god = on;
}
"""
    else:
        god = """
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
"""
    if ufo_style == "codxe":
        ufo = """
sm_ufo(a1, a2)
{
	on = self sm_flip("ufo");
	self sm_say("UFO Mode", on);
	self.ufo = on;
}
"""
    else:
        ufo = """
sm_ufo(a1, a2)
{
	on = self sm_flip("ufo");
	if(on)
	{
		self iPrintln("UFO Mode ^2ON^7 - hold Frag (RB) to fly");
		self thread sm_ufoLoop();
	}
	else
	{
		self notify("sm_ufo_off");
		self iPrintln("UFO Mode ^1OFF");
	}
}

sm_ufoLoop()
{
	self endon("disconnect");
	org = spawn("script_origin", self.origin);
	self linkTo(org);
	self thread sm_ufoCleanup(org);
	self thread sm_ufoWatchDeath();
	self endon("sm_ufo_off");
	for(;;)
	{
		if(!self.sm_open && self fragButtonPressed())
		{
			dir = anglesToForward(self getPlayerAngles());
			org moveTo(org.origin + (dir * 45), 0.05);
		}
		wait 0.05;
	}
}

sm_ufoWatchDeath()
{
	self endon("disconnect");
	self endon("sm_ufo_stop");
	self waittill("death");
	self notify("sm_ufo_off");
}

sm_ufoCleanup(org)
{
	self endon("disconnect");
	self waittill("sm_ufo_off");
	self unlink();
	org delete();
	self.sm_on["ufo"] = false;
	self notify("sm_ufo_stop");
}
"""
    rest = """
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
"""
    return god + ufo + rest


# ----------------------------------------------------------------------------
# Multiplayer menu
# ----------------------------------------------------------------------------

def mp_script(key, g):
    host = ("\treturn self isHost();" if g["host"] == "ishost"
            else "\tif(self getEntityNumber() == 0)\n\t\treturn true;\n\treturn false;")
    footer = "Aim/Shoot Scroll   X Select   Knife Back"
    s = HEADER.format(ver=VERSION, title=g["name"] + " Multiplayer")
    s += f"""
init()
{{
	if(isDefined(level.sm_started))
		return;
	level.sm_started = true;
	level.sm_version = {q(VERSION)};
	level.sm_game = {q(g["name"])};
	level.sm_everyone = false;
	level.sm_maxLines = 11;
	precacheShader("white");
	setDvar("loc_warnings", "0");
	setDvar("loc_warningsAsErrors", "0");
	level thread sm_onConnect();
}}

sm_onConnect()
{{
	for(;;)
	{{
		level waittill("connected", player);
		player thread sm_onPlayer();
	}}
}}

sm_onPlayer()
{{
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
	{{
		self waittill("spawned_player");
		if(self sm_hasAccess() && !self.sm_welcomed)
		{{
			self.sm_welcomed = true;
			self iPrintlnBold("^2Shmees Menu^7 loaded");
			self iPrintln("Aim + Knife to open the menu");
		}}
	}}
}}
"""
    s += engine("mp", "objective", footer, host)
    s += common_mods(g.get("god", "health"), g["ufo"])
    s += mp_mods(key, g)
    s += mp_build(key, g)
    return s


def mp_mods(key, g):
    s = """
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
"""
    if g["killstreaks"]:
        s += """
sm_streak(name, label)
{
	self maps\\mp\\killstreaks\\_killstreaks::giveKillstreak(name, false);
	self iPrintln("Gave ^2" + label + "^7 - use it from the D-pad");
}
"""
    return s


def mp_build(key, g):
    L = []
    a = L.append
    a("\n// ---------------------------------------------------------------- menus ----\n")
    a("sm_build(id)\n{\n\tswitch(id)\n\t{")
    # main
    a('\t\tcase "main":')
    a(f'\t\t\tself sm_start("Shmees Menu");')
    a('\t\t\tself sm_addMenu("Main Mods", "mods");')
    a('\t\t\tself sm_addMenu("Weapons", "weapons");')
    if g["perks"]:
        a('\t\t\tself sm_addMenu("Perks", "perks");')
    if g["killstreaks"]:
        a('\t\t\tself sm_addMenu("Killstreaks", "streaks");')
    a('\t\t\tself sm_addMenu("Fun", "fun");')
    a('\t\t\tif(self sm_isHost())')
    a('\t\t\t{')
    a('\t\t\t\tself sm_addMenu("Lobby", "lobby");')
    a('\t\t\t\tself sm_addMenu("Players", "players");')
    a('\t\t\t}')
    a('\t\t\tself sm_addMenu("Settings", "settings");')
    a('\t\t\tbreak;')
    # mods
    a('\t\tcase "mods":')
    a('\t\t\tself sm_start("Main Mods");')
    a('\t\t\tself sm_add("God Mode", ::sm_god, undefined, undefined, "god");')
    a('\t\t\tself sm_add("Infinite Ammo", ::sm_ammo, undefined, undefined, "ammo");')
    a('\t\t\tself sm_add("UFO Mode", ::sm_ufo, undefined, undefined, "ufo");')
    a('\t\t\tself sm_add("Super Speed", ::sm_speed, undefined, undefined, "speed");')
    a('\t\t\tself sm_add("Third Person", ::sm_thirdPerson, undefined, undefined, "third");')
    a('\t\t\tself sm_add("Invisible", ::sm_invisible, undefined, undefined, "invis");')
    a('\t\t\tself sm_add("Teleport to Crosshair", ::sm_teleportAim);')
    a('\t\t\tself sm_add("Save Position", ::sm_savePos);')
    a('\t\t\tself sm_add("Load Position", ::sm_loadPos);')
    a('\t\t\tself sm_add("Suicide", ::sm_suicide);')
    a('\t\t\tbreak;')
    # weapons
    a('\t\tcase "weapons":')
    a('\t\t\tself sm_start("Weapons");')
    for i, (cat, _) in enumerate(g["weapons"]):
        a(f'\t\t\tself sm_addMenu({q(cat)}, "wcat{i}");')
    a('\t\t\tself sm_add("Max Ammo", ::sm_maxAmmo);')
    a('\t\t\tself sm_add("Take Current Weapon", ::sm_takeWeapon);')
    a('\t\t\tself sm_add("Drop Current Weapon", ::sm_dropWeapon);')
    a('\t\t\tbreak;')
    for i, (cat, ws) in enumerate(g["weapons"]):
        a(f'\t\tcase "wcat{i}":')
        a(f'\t\t\tself sm_start({q(cat)});')
        for w in ws:
            a(f'\t\t\tself sm_add({q(w)}, ::sm_give, {q(w)});')
        a('\t\t\tbreak;')
    # perks
    if g["perks"]:
        a('\t\tcase "perks":')
        a('\t\t\tself sm_start("Perks");')
        a('\t\t\tlist = [];')
        for i, (_, p) in enumerate(g["perks"]):
            a(f'\t\t\tlist[{i}] = {q(p)};')
        a('\t\t\tself sm_add("Give All Perks", ::sm_allPerks, list);')
        for name, p in g["perks"]:
            a(f'\t\t\tself sm_add({q(name)}, ::sm_perk, {q(p)}, {q(name)});')
        a('\t\t\tbreak;')
    if g["killstreaks"]:
        a('\t\tcase "streaks":')
        a('\t\t\tself sm_start("Killstreaks");')
        for name, k in g["killstreaks"]:
            a(f'\t\t\tself sm_add({q(name)}, ::sm_streak, {q(k)}, {q(name)});')
        a('\t\t\tbreak;')
    # fun
    a('\t\tcase "fun":')
    a('\t\t\tself sm_start("Fun");')
    a('\t\t\tself sm_add("Explosive Bullets", ::sm_exBullets, undefined, undefined, "exb");')
    a('\t\t\tself sm_add("Earthquake", ::sm_quake);')
    a('\t\t\tbreak;')
    # lobby
    a('\t\tcase "lobby":')
    a('\t\t\tself sm_start("Lobby");')
    a('\t\t\tself sm_add("Menu for Everyone", ::sm_everyone, undefined, undefined, "everyone");')
    a('\t\t\tself sm_add("Super Jump", ::sm_dvarToggle, "ljump", undefined, "ljump");')
    a('\t\t\tself sm_add("Low Gravity", ::sm_dvarToggle, "lgrav", undefined, "lgrav");')
    a('\t\t\tself sm_add("Super Speed (Everyone)", ::sm_dvarToggle, "lspeed", undefined, "lspeed");')
    a('\t\t\tself sm_add("Slow Motion", ::sm_dvarToggle, "lslow", undefined, "lslow");')
    a('\t\t\tself sm_addMenu("Visions", "visions");')
    a('\t\t\tself sm_add("No Time or Score Limit", ::sm_unlimited);')
    a('\t\t\tself sm_add("Fast Restart", ::sm_restart);')
    a('\t\t\tbreak;')
    a('\t\tcase "visions":')
    a('\t\t\tself sm_start("Visions");')
    a('\t\t\tself sm_add("Normal", ::sm_vision, "map");')
    a('\t\t\tself sm_add("Black and White", ::sm_vision, "cheat_bw");')
    a('\t\t\tself sm_add("Night", ::sm_vision, "cheat_chaplinnight");')
    if key == "MW2":
        a('\t\t\tself sm_add("Thermal", ::sm_vision, "thermal_mp");')
        a('\t\t\tself sm_add("AC-130", ::sm_vision, "ac130");')
    a('\t\t\tbreak;')
    # players
    a('\t\tcase "players":')
    a('\t\t\tself sm_start("Players");')
    a('\t\t\tplayers = getEntArray("player", "classname");')
    a('\t\t\tfor(i = 0; i < players.size; i++)')
    a('\t\t\t\tself sm_addPlayer(players[i].name, players[i]);')
    a('\t\t\tbreak;')
    a('\t\tcase "player":')
    a('\t\t\tname = "Player";')
    a('\t\t\tif(isDefined(self.sm_target) && isPlayer(self.sm_target))')
    a('\t\t\t\tname = self.sm_target.name;')
    a('\t\t\tself sm_start(name);')
    a('\t\t\tself sm_add("Give / Take Menu", ::sm_pAccess);')
    a('\t\t\tself sm_add("Teleport to Me", ::sm_pBring);')
    a('\t\t\tself sm_add("Teleport to Them", ::sm_pGoto);')
    a('\t\t\tself sm_add("Freeze / Unfreeze", ::sm_pFreeze);')
    a('\t\t\tself sm_add("Kill", ::sm_pKill);')
    a('\t\t\tself sm_add("Kick", ::sm_pKick);')
    a('\t\t\tbreak;')
    # settings
    a('\t\tcase "settings":')
    a('\t\t\tself sm_start("Settings");')
    a('\t\t\tself sm_addMenu("Menu Color", "themes");')
    a('\t\t\tself sm_add("About", ::sm_about);')
    a('\t\t\tself sm_add("Close Menu", ::sm_closeFromMenu);')
    a('\t\t\tbreak;')
    a('\t\tcase "themes":')
    a('\t\t\tself sm_start("Menu Color");')
    for name, col in THEMES:
        a(f'\t\t\tself sm_add({q(name)}, ::sm_setTheme, {col}, {q(name)});')
    a('\t\t\tbreak;')
    a('\t\tdefault:')
    a('\t\t\tself sm_start("Shmees Menu");')
    a('\t\t\tself sm_add("(empty)", ::sm_nothing);')
    a('\t\t\tbreak;')
    a("\t}\n}\n")
    a("sm_closeFromMenu(a1, a2)\n{\n\tself sm_closeMenu();\n}\n")
    return "\n".join(L)


# ----------------------------------------------------------------------------
# Zombies menu
# ----------------------------------------------------------------------------

def zm_script(key, g):
    z = g["zombies"]
    host = "\tif(self getEntityNumber() == 0)\n\t\treturn true;\n\treturn false;"
    footer = "Aim/Shoot Scroll   X Select   Knife Back"
    s = HEADER.format(ver=VERSION, title=g["name"] + " Zombies")
    s += f"""
init()
{{
	if(isDefined(level.sm_started))
		return;
	level.sm_started = true;
	level.sm_version = {q(VERSION)};
	level.sm_game = {q(g["name"])};
	level.sm_everyone = false;
	level.sm_maxLines = 11;
	precacheShader("white");
	setDvar("loc_warnings", "0");
	setDvar("loc_warningsAsErrors", "0");
	level thread sm_onConnect();
	players = getEntArray("player", "classname");
	for(i = 0; i < players.size; i++)
		players[i] thread sm_onPlayer();
}}

sm_onConnect()
{{
	for(;;)
	{{
		level waittill("connecting", player);
		player thread sm_onPlayer();
	}}
}}

sm_onPlayer()
{{
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
	{{
		self waittill("spawned_player");
		if(self sm_hasAccess() && !self.sm_welcomed)
		{{
			self.sm_welcomed = true;
			self iPrintlnBold("^2Shmees Zombies Menu^7 loaded");
			self iPrintln("Aim + Knife to open the menu");
		}}
	}}
}}

sm_isZombies()
{{
	if(isDefined(level.zombiemode) && level.zombiemode)
		return true;
	if(isSubStr(getDvar("mapname"), "zombie"))
		return true;
	return false;
}}
"""
    s += engine("zm", "default", footer, host)
    s += common_mods(z["god"], z["ufo"])
    s += zm_mods(key, g)
    s += zm_build(key, g)
    return s


def zm_mods(key, g):
    return """
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
"""


def zm_build(key, g):
    z = g["zombies"]
    L = []
    a = L.append
    a("\n// ---------------------------------------------------------------- menus ----\n")
    a("sm_build(id)\n{\n\tswitch(id)\n\t{")
    a('\t\tcase "main":')
    a('\t\t\tself sm_start("Shmees Zombies");')
    a('\t\t\tself sm_addMenu("Main Mods", "mods");')
    a('\t\t\tif(self sm_isZombies())')
    a('\t\t\t{')
    a('\t\t\t\tself sm_addMenu("Points", "points");')
    a('\t\t\t\tself sm_addMenu("Weapons", "weapons");')
    a('\t\t\t\tself sm_addMenu("Perks", "perks");')
    a('\t\t\t\tif(self sm_isHost())')
    a('\t\t\t\t\tself sm_addMenu("Zombies & Rounds", "rounds");')
    a('\t\t\t}')
    a('\t\t\tif(self sm_isHost())')
    a('\t\t\t\tself sm_addMenu("Players", "players");')
    a('\t\t\tself sm_addMenu("Settings", "settings");')
    a('\t\t\tbreak;')
    a('\t\tcase "mods":')
    a('\t\t\tself sm_start("Main Mods");')
    a('\t\t\tself sm_add("God Mode", ::sm_god, undefined, undefined, "god");')
    a('\t\t\tself sm_add("Infinite Ammo", ::sm_ammo, undefined, undefined, "ammo");')
    a('\t\t\tself sm_add("UFO Mode", ::sm_ufo, undefined, undefined, "ufo");')
    a('\t\t\tself sm_add("Super Speed", ::sm_speed, undefined, undefined, "speed");')
    a('\t\t\tself sm_add("Zombies Ignore Me", ::sm_ignoreMe, undefined, undefined, "ignore");')
    a('\t\t\tself sm_add("Teleport to Crosshair", ::sm_teleportAim);')
    a('\t\t\tself sm_add("Save Position", ::sm_savePos);')
    a('\t\t\tself sm_add("Load Position", ::sm_loadPos);')
    a('\t\t\tbreak;')
    a('\t\tcase "points":')
    a('\t\t\tself sm_start("Points");')
    a('\t\t\tself sm_add("+1,000", ::sm_points, 1000);')
    a('\t\t\tself sm_add("+10,000", ::sm_points, 10000);')
    a('\t\t\tself sm_add("+100,000", ::sm_points, 100000);')
    a('\t\t\tself sm_add("+500,000", ::sm_points, 500000);')
    a('\t\t\tbreak;')
    a('\t\tcase "weapons":')
    a('\t\t\tself sm_start("Weapons");')
    a('\t\t\tself sm_addMenu("Give a Weapon", "zmweapons");')
    a('\t\t\tself sm_add("Pack-a-Punch Current Weapon", ::sm_pap);')
    a('\t\t\tself sm_add("Max Ammo", ::sm_maxAmmo);')
    a('\t\t\tself sm_add("Take Current Weapon", ::sm_takeWeapon);')
    a('\t\t\tbreak;')
    a('\t\tcase "zmweapons":')
    a('\t\t\tself sm_start("Give a Weapon");')
    a('\t\t\tif(isDefined(level.zombie_weapons))')
    a('\t\t\t{')
    a('\t\t\t\tkeys = getArrayKeys(level.zombie_weapons);')
    a('\t\t\t\tfor(i = 0; i < keys.size && i < 60; i++)')
    a('\t\t\t\t\tself sm_add(keys[i], ::sm_zmGive, keys[i]);')
    a('\t\t\t}')
    a('\t\t\tif(self.sm_labels.size == 0)')
    a('\t\t\t\tself sm_add("(no weapons on this map)", ::sm_nothing);')
    a('\t\t\tbreak;')
    a('\t\tcase "perks":')
    a('\t\t\tself sm_start("Perks");')
    a('\t\t\tlist = [];')
    for i, (_, p) in enumerate(z["perks"]):
        a(f'\t\t\tlist[{i}] = {q(p)};')
    a('\t\t\tself sm_add("Give All Perks", ::sm_zmAllPerks, list);')
    for name, p in z["perks"]:
        a(f'\t\t\tself sm_add({q(name)}, ::sm_zmPerk, {q(p)}, {q(name)});')
    a('\t\t\tbreak;')
    a('\t\tcase "rounds":')
    a('\t\t\tself sm_start("Zombies & Rounds");')
    a('\t\t\tself sm_add("Menu for Everyone", ::sm_everyone, undefined, undefined, "everyone");')
    a('\t\t\tself sm_add("Kill All Zombies", ::sm_killZombies);')
    a('\t\t\tself sm_add("Skip Round", ::sm_skipRound, 0);')
    a('\t\t\tself sm_add("Jump 5 Rounds", ::sm_skipRound, 4);')
    a('\t\t\tself sm_add("Jump 10 Rounds", ::sm_skipRound, 9);')
    a('\t\t\tself sm_add("Zombies Ignore Everyone", ::sm_ignoreAll, undefined, undefined, "ignoreall");')
    a('\t\t\tself sm_add("Open All Doors", ::sm_openDoors);')
    a('\t\t\tself sm_add("Turn On Power", ::sm_power);')
    a('\t\t\tself sm_add("Max Ammo for Everyone", ::sm_maxAmmoAll);')
    a('\t\t\tbreak;')
    a('\t\tcase "players":')
    a('\t\t\tself sm_start("Players");')
    a('\t\t\tplayers = getEntArray("player", "classname");')
    a('\t\t\tfor(i = 0; i < players.size; i++)')
    a('\t\t\t\tself sm_addPlayer(players[i].name, players[i]);')
    a('\t\t\tbreak;')
    a('\t\tcase "player":')
    a('\t\t\tname = "Player";')
    a('\t\t\tif(isDefined(self.sm_target) && isPlayer(self.sm_target))')
    a('\t\t\t\tname = self.sm_target.name;')
    a('\t\t\tself sm_start(name);')
    a('\t\t\tself sm_add("Give / Take Menu", ::sm_pAccess);')
    a('\t\t\tself sm_add("Give 10,000 Points", ::sm_pPoints);')
    a('\t\t\tself sm_add("Toggle God Mode", ::sm_pGod);')
    a('\t\t\tself sm_add("Teleport to Me", ::sm_pBring);')
    a('\t\t\tself sm_add("Teleport to Them", ::sm_pGoto);')
    a('\t\t\tbreak;')
    a('\t\tcase "settings":')
    a('\t\t\tself sm_start("Settings");')
    a('\t\t\tself sm_addMenu("Menu Color", "themes");')
    a('\t\t\tself sm_add("About", ::sm_about);')
    a('\t\t\tself sm_add("Close Menu", ::sm_closeFromMenu);')
    a('\t\t\tbreak;')
    a('\t\tcase "themes":')
    a('\t\t\tself sm_start("Menu Color");')
    for name, col in THEMES:
        a(f'\t\t\tself sm_add({q(name)}, ::sm_setTheme, {col}, {q(name)});')
    a('\t\t\tbreak;')
    a('\t\tdefault:')
    a('\t\t\tself sm_start("Shmees Zombies");')
    a('\t\t\tself sm_add("(empty)", ::sm_nothing);')
    a('\t\t\tbreak;')
    a("\t}\n}\n")
    return "\n".join(L)


# ----------------------------------------------------------------------------
# Hook scripts (override a stock script so CoD Xe hands us control)
# ----------------------------------------------------------------------------

CLIENTIDS = """// Shmees Menu hook. Stock behaviour kept: client IDs are still handed out.
init()
{
	level.clientid = 0;
	level thread onPlayerConnect();

	// Shmees Menu
	level thread maps\\mp\\gametypes\\_shmees::init();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);
		player.clientid = level.clientid;
		level.clientid++;
	}
}
"""

# MW2 ships an empty _clientids.gsc, so the hook goes in _deathicons.gsc,
# which _gamelogic.gsc always runs. Everything below init() is the stock file.
DEATHICONS_MW2 = """// Shmees Menu hook. The rest of this file is the stock _deathicons.gsc.
#include maps\\mp\\_utility;

init()
{
	// Shmees Menu
	level thread maps\\mp\\gametypes\\_shmees::init();

	if (!level.teambased)
		return;

	precacheShader("headicon_dead");

	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connected", player);

		player.selfDeathIcons = []; // icons that other people see which point to this player when he's dead
	}
}

updateDeathIconsEnabled()
{
	//if (!self.enableDeathIcons)
	//	self removeOtherDeathIcons();
}

addDeathIcon( entity, dyingplayer, team, timeout )
{
	if ( !level.teambased )
		return;

	iconOrg = entity.origin;

	dyingplayer endon("spawned_player");
	dyingplayer endon("disconnect");

	wait .05;
	WaitTillSlowProcessAllowed();

	assert(team == "allies" || team == "axis");

	if ( getDvar( "ui_hud_showdeathicons" ) == "0" )
		return;
	if ( level.hardcoreMode )
		return;

	if ( isdefined( self.lastDeathIcon ) )
		self.lastDeathIcon destroy();

	newdeathicon = newTeamHudElem( team );
	newdeathicon.x = iconOrg[0];
	newdeathicon.y = iconOrg[1];
	newdeathicon.z = iconOrg[2] + 54;
	newdeathicon.alpha = .61;
	newdeathicon.archived = true;
	if ( level.splitscreen )
		newdeathicon setShader("headicon_dead", 14, 14);
	else
		newdeathicon setShader("headicon_dead", 7, 7);
	newdeathicon setwaypoint( true, false );

	self.lastDeathIcon = newdeathicon;

	newdeathicon thread destroySlowly ( timeout );
}

destroySlowly( timeout )
{
	self endon("death");

	wait timeout;

	self fadeOverTime(1.0);
	self.alpha = 0;

	wait 1.0;
	self destroy();
}
"""

# World at War singleplayer and Nazi Zombies: CoD Xe's own example hooks the
# tiny stock _music.gsc. Both stock functions are kept as they were.
MUSIC_WAW = """// Shmees Zombies Menu hook. Stock functions kept unchanged.
#include maps\\_utility;

music_init()
{
	assert(level.clientscripts);

	level.musicState = "";
	registerClientSys("musicCmd");

	// Shmees Zombies Menu
	level thread maps\\_shmees_zm::init();
}

setMusicState(state)
{
	if(level.musicState != state)
		setClientSysState("musicCmd", state );
	level.musicState = state;
}
"""

# Black Ops Zombies: _zombiemode.gsc calls these three functions. The stock
# file only holds day-one fixes, so the hook goes here.
FFOTD_BO1 = """// Shmees Zombies Menu hook for Black Ops Zombies.
// _zombiemode.gsc calls main_start(), main_end() and
// nazizombies_checking_for_cheats(); all three are kept.

main_start()
{
	// Shmees Zombies Menu
	level thread maps\\_shmees_zm::init();
}

main_end()
{
}

// Modded games are never uploaded to the leaderboards.
nazizombies_checking_for_cheats()
{
	return true;
}
"""


# ----------------------------------------------------------------------------
# Build
# ----------------------------------------------------------------------------

def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", newline="\r\n") as f:
        f.write(text)


def build():
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    made = []
    for key, g in GAMES.items():
        root = os.path.join(OUT, key, "files", "_codxe")
        mod = os.path.join(root, "mods", "shmees")
        write(os.path.join(root, "codxe.json"), json.dumps({"active_mod": "shmees"}, indent=2) + "\n")
        gt = os.path.join(mod, "maps", "mp", "gametypes")
        write(os.path.join(gt, "_shmees.gsc"), mp_script(key, g))
        if g["hook"] == "clientids":
            write(os.path.join(gt, "_clientids.gsc"), CLIENTIDS)
        elif g["hook"] == "deathicons":
            write(os.path.join(gt, "_deathicons.gsc"), DEATHICONS_MW2)
        if "zombies" in g:
            maps = os.path.join(mod, "maps")
            write(os.path.join(maps, "_shmees_zm.gsc"), zm_script(key, g))
            if g["zombies"]["hook"] == "music":
                write(os.path.join(maps, "_music.gsc"), MUSIC_WAW)
            elif g["zombies"]["hook"] == "ffotd":
                write(os.path.join(maps, "_zombiemode_ffotd.gsc"), FFOTD_BO1)
        made.append(key)
    print("built:", ", ".join(made))


if __name__ == "__main__":
    build()
