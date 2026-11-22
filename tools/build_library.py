#!/usr/bin/env python3
"""
Builds the online menu library for Mod Menu Manager:

  library/catalog.ini              the list the script downloads
  library/packages/<id>.zip        Shmees Menu packages (built from ../shmees_menu/out)
  library/README.md                what's in the library and who made it

Third-party files come from vendor/ (see vendor/README.md): the CoD Xe and
Hayzen plugins are mirrored into library/packages/ next to their licences, and
the CodJumper packages are built from CoD Xe's own resources (MIT).
"""
import os
import shutil
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
MENU_OUT = HERE.parent / "ShmeesMenu"
LIB = HERE.parent / "library"
PKG = LIB / "packages"
VENDOR = HERE.parent / "vendor"
RAW = "https://raw.githubusercontent.com/ShmeeMcgee/ModMenuManager/main/library/packages/"
VERSION = "1.0"
UPDATED = "2026-11-22"

SHMEES = {
    "COD4": dict(name="Call of Duty 4", tu="TU4", mode="Multiplayer", launch="default_mp.xex",
                 desc="Shmees' own mod menu: god mode, infinite ammo, UFO, every base weapon, all perks, explosive bullets, lobby controls and player options. Aim + Knife to open."),
    "WAW": dict(name="World at War", tu="TU7", mode="Multiplayer + Nazi Zombies", launch="",
                desc="Shmees' own mod menu for multiplayer, plus a Zombies menu: points, every box weapon, Pack-a-Punch, perks, skip rounds, open doors and power. Aim + Knife to open."),
    "MW2": dict(name="Modern Warfare 2", tu="TU9", mode="Multiplayer", launch="default_mp.xex",
                desc="Shmees' own mod menu: god mode, infinite ammo, UFO, every base weapon, perks, all killstreaks up to the Nuke, lobby and player controls. Aim + Knife to open."),
    "BO1": dict(name="Black Ops", tu="TU11", mode="Multiplayer + Zombies", launch="",
                desc="Shmees' own mod menu for multiplayer, plus a Zombies menu: points, every box weapon, Pack-a-Punch, all 8 perks, skip rounds, open doors and power. Aim + Knife to open."),
}

MIT = """MIT License

Copyright (c) 2026 Shmees

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""


def crlf(text):
    return text.replace("\r\n", "\n").replace("\n", "\r\n")


def readme_txt(key, g):
    zombies = "Zombies" in g["mode"]
    lines = [
        f"SHMEES MENU v{VERSION} - {g['name']}",
        "by Shmees  |  youtube.com/@Shmees14  |  github.com/ShmeeMcgee",
        "",
        "CONTROLS",
        "  Open ............ Aim + Knife",
        "  Scroll .......... Aim (up) / Shoot (down)",
        "  Select .......... Use (X)",
        "  Back / close .... Knife",
        "",
        "The host gets the menu. Give it to other players from Players, or turn on",
        "Menu for Everyone in Lobby.",
        "",
        "NEEDS",
        f"  - CoD Xe (github.com/michaeloliverx/codxe), loaded by DashLaunch",
        f"  - {g['name']} title update {g['tu']}",
        "",
        "HOW IT LOADS",
        "  The files go in the game folder under _codxe. CoD Xe's GSC loader reads",
        "  the 'shmees' mod set in _codxe\\codxe.json. Mod Menu Manager backs up",
        "  anything it replaces and removes it all again from Installed menus.",
    ]
    if zombies:
        lines += [
            "",
            "ZOMBIES",
            "  Start Zombies from the campaign/main executable (default.xex). The",
            "  Zombies menu opens with the same buttons.",
        ]
    lines += ["", "For offline play, private matches and system link only."]
    return crlf("\n".join(lines) + "\n")


def menu_ini(key, g):
    rows = [
        ("name", "Shmees Menu"), ("version", VERSION), ("author", "Shmees"), ("game", key),
        ("type", "files"), ("mode", g["mode"]), ("launch", g["launch"]), ("requires", "codxe"),
        ("tu", g["tu"]), ("license", "MIT"), ("homepage", "github.com/ShmeeMcgee/ModMenuManager"),
        ("description", g["desc"]),
        ("note", f"Runs through CoD Xe and needs title update {g['tu']}. For offline play, private matches and system link."),
    ]
    out = ["; Shmees Menu - Mod Menu Manager package"]
    out += [f"{k:<11} = {v}" for k, v in rows if v]
    return crlf("\n".join(out) + "\n")


CJ_CONTROLS = """CONTROLS (from the CoD Xe CodJumper readme)
  Save position .......... double-tap RS
  Load position .......... LB
  UFO on/off ............. RB
  Spawn static bot ....... D-pad Up
  Open menu .............. double-tap X
  Scroll / select ........ LT, RT / X
  Close menu ............. RS
  Record / play movement . D-pad Down / D-pad Right
"""


def cj_desc(key, name):
    extra = ", static bots, a movement recorder and forge tools" if key == "COD4" else " and static bots"
    return f"CoD Xe's CodJumper mod for {name}: save and load positions, UFO{extra} for practising trick jumps."


def cj_build(zip_path, key, tu, name, src):
    assert src.is_dir(), src
    ini = [
        "; CodJumper - from CoD Xe (github.com/michaeloliverx/codxe), MIT",
        "name        = CodJumper", "version     = r351", "author      = michaeloliverx (CoD Xe)",
        f"game        = {key}", "type        = files", "mode        = Multiplayer", "launch      = default_mp.xex",
        "requires    = codxe", f"tu          = {tu}", "license     = MIT", "homepage    = github.com/michaeloliverx/codxe",
        f"description = {cj_desc(key, name)}",
        "note        = Sets CoD Xe's active mod to codjumper. Only one CoD Xe mod runs at a time, so this replaces the Shmees Menu until you remove it.",
    ]
    readme = "\n".join([
        f"CODJUMPER for {name} (CoD Xe r351)",
        "Made by michaeloliverx as part of CoD Xe: github.com/michaeloliverx/codxe",
        "Packaged for Mod Menu Manager by Shmees. MIT licence in LICENSE.txt.",
        "", CJ_CONTROLS if key == "COD4" else "CONTROLS\n  See the CodJumper section of github.com/michaeloliverx/codxe\n",
        "NEEDS", "  - CoD Xe loaded by DashLaunch", f"  - {name} title update {tu}", "",
        "CoD Xe runs one mod at a time (set in _codxe\\codxe.json). Installing this",
        "switches the active mod to codjumper; removing it puts the old file back.", "",
    ])
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("menu.ini", crlf("\n".join(ini) + "\n"))
        z.writestr("README.txt", crlf(readme))
        z.writestr("LICENSE.txt", crlf((VENDOR / "codxe" / "LICENSE").read_text()))
        z.writestr("files/_codxe/codxe.json", '{"active_mod": "codjumper"}\r\n')
        for p in sorted(src.rglob("*")):
            if p.is_file():
                z.write(p, "files/_codxe/mods/codjumper/" + p.relative_to(src).as_posix())


def kb(n):
    return f"{max(1, round(n / 1024))} KB"


def build():
    if LIB.exists():
        shutil.rmtree(LIB)
    PKG.mkdir(parents=True)
    catalog = [
        "; Mod Menu Manager menu library",
        "; Each [section] is one download. format = zip (a package with menu.ini)",
        "; or xex (a plugin downloaded from its author's own release).",
        "",
        "[library]",
        "name    = Shmees Menu Library",
        f"updated = {UPDATED}",
        "",
    ]
    for key, g in SHMEES.items():
        files_root = MENU_OUT / key / "files"
        assert files_root.is_dir(), files_root
        zip_path = PKG / f"shmees-menu-{key.lower()}.zip"
        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
            z.writestr("menu.ini", menu_ini(key, g))
            z.writestr("README.txt", readme_txt(key, g))
            z.writestr("LICENSE.txt", crlf(MIT))
            for p in sorted(files_root.rglob("*")):
                if p.is_file():
                    z.write(p, "files/" + p.relative_to(files_root).as_posix())
        catalog += [
            f"[shmees-menu-{key.lower()}]",
            "name        = Shmees Menu",
            f"game        = {key}",
            f"version     = {VERSION}",
            "author      = Shmees",
            "type        = files",
            "format      = zip",
            f"mode        = {g['mode']}",
            f"launch      = {g['launch']}" if g["launch"] else None,
            "requires    = codxe",
            f"tu          = {g['tu']}",
            "license     = MIT",
            f"size        = {kb(zip_path.stat().st_size)}",
            "folder      = Shmees Menu",
            f"description = {g['desc']}",
            f"url         = {RAW}{zip_path.name}",
            "",
        ]
    catalog += [
        "[codxe]",
        "name        = CoD Xe",
        "game        = ALL",
        "version     = r351",
        "author      = michaeloliverx",
        "type        = plugin",
        "format      = xex",
        "file        = codxe.xex",
        "license     = MIT",
        "homepage    = github.com/michaeloliverx/codxe",
        "folder      = CoD Xe",
        "description = Open-source modding plugin for CoD2, CoD4, World at War, MW2, Black Ops and MW3. Loads plain GSC scripts, which is how Shmees Menus run.",
        "note        = Needs CoD4 TU4, World at War TU7, MW2 TU9 or Black Ops TU11.",
        f"size        = {kb((VENDOR / 'codxe' / 'codxe.xex').stat().st_size)}",
        f"url         = {RAW}codxe.xex",
        "",
        "[hayzen]",
        "name        = Hayzen",
        "game        = ALL",
        "version     = 9.7.2",
        "author      = ClementDreptin",
        "type        = plugin",
        "format      = xex",
        "file        = Hayzen.xex",
        "license     = Apache-2.0",
        "homepage    = github.com/ClementDreptin/Hayzen",
        "folder      = Hayzen",
        "description = Popular open-source mod menu plugin for CoD4, World at War, MW2, MW3, the Ghosts alpha and NX1. Also lets the console run debug builds.",
        "note        = Needs CoD4 TU4, World at War TU7, MW2 TU9 or MW3 TU24.",
        f"size        = {kb((VENDOR / 'hayzen' / 'Hayzen.xex').stat().st_size)}",
        f"url         = {RAW}Hayzen.xex",
        "",
    ]
    for src, dst in (("codxe/codxe.xex", "codxe.xex"), ("codxe/LICENSE", "codxe-LICENSE.txt"),
                     ("hayzen/Hayzen.xex", "Hayzen.xex"), ("hayzen/LICENSE", "Hayzen-LICENSE.txt")):
        data = (VENDOR / src).read_bytes()
        if dst.endswith(".xex"):
            assert data[:4] == b"XEX2", src
        (PKG / dst).write_bytes(data)
    for key, tu, name, eng in (("COD4", "TU4", "Call of Duty 4", "iw3"), ("WAW", "TU7", "World at War", "t4"),
                               ("MW2", "TU9", "Modern Warfare 2", "iw4")):
        zip_path = PKG / f"codjumper-{key.lower()}.zip"
        cj_build(zip_path, key, tu, name, VENDOR / "codxe" / "resources" / eng / "_codxe" / "mods" / "codjumper")
        catalog += [
            f"[codjumper-{key.lower()}]",
            "name        = CodJumper",
            f"game        = {key}",
            "version     = r351",
            "author      = michaeloliverx (CoD Xe)",
            "type        = files",
            "format      = zip",
            "mode        = Multiplayer",
            "launch      = default_mp.xex",
            "requires    = codxe",
            f"tu          = {tu}",
            "license     = MIT",
            "homepage    = github.com/michaeloliverx/codxe",
            f"size        = {kb(zip_path.stat().st_size)}",
            "folder      = CodJumper",
            f"description = {cj_desc(key, name)}",
            f"url         = {RAW}codjumper-{key.lower()}.zip",
            "",
        ]
    (LIB / "catalog.ini").write_text(crlf("\n".join(l for l in catalog if l is not None)))
    (LIB / "README.md").write_text(LIB_README)
    for p in sorted(LIB.rglob("*")):
        if p.is_file():
            print(f"{p.relative_to(HERE.parent)}  {p.stat().st_size} bytes")


LIB_README = """# Mod Menu Manager library

This folder is the online library that **Mod Menu Manager** reads from its
**Download menus** screen. `catalog.ini` lists every download.

| Menu | Games | By | Licence |
| --- | --- | --- | --- |
| Shmees Menu | CoD4, World at War, MW2, Black Ops (WaW and Black Ops include Zombies) | Shmees | MIT |
| CoD Xe | Loader plugin for the menus above | [michaeloliverx](https://github.com/michaeloliverx/codxe) | MIT |
| Hayzen | CoD4, World at War, MW2, MW3, Ghosts alpha, NX1 | [ClementDreptin](https://github.com/ClementDreptin/Hayzen) | Apache-2.0 |
| CodJumper | CoD4, World at War, MW2 | [michaeloliverx](https://github.com/michaeloliverx/codxe) (part of CoD Xe) | MIT |

CoD Xe (`codxe.xex`) and Hayzen (`Hayzen.xex`) are unchanged copies of their
authors' releases, mirrored here with their licences (`codxe-LICENSE.txt`,
`Hayzen-LICENSE.txt`). CodJumper is repackaged from the CoD Xe repository with
its licence included. CoD Xe runs one mod at a time, so installing CodJumper
switches off the Shmees Menu for that game until CodJumper is removed.

## Shmees Menu

Open with **Aim + Knife**. Scroll with Aim and Shoot, select with Use (X), go
back with Knife. It runs through CoD Xe's GSC loader, so it needs CoD Xe in a
DashLaunch plugin slot and the title update listed for each game:

| Game | Title update | Hook script |
| --- | --- | --- |
| Call of Duty 4 | TU4 | `maps/mp/gametypes/_clientids.gsc` |
| World at War | TU7 | `maps/mp/gametypes/_clientids.gsc`, Zombies `maps/_music.gsc` |
| Modern Warfare 2 | TU9 | `maps/mp/gametypes/_deathicons.gsc` |
| Black Ops | TU11 | `maps/mp/gametypes/_clientids.gsc`, Zombies `maps/_zombiemode_ffotd.gsc` |

The menu scripts are generated by `tools/gen_shmees_menu.py` in this repository.

## Adding to the library

Add a `[section]` to `catalog.ini`:

```ini
[my-menu-mw2]
name        = My Menu
game        = MW2            ; COD4 WAW MW2 BO1 MW3 BO2 GHOSTS AW BO3, or ALL
version     = 1.0
author      = Me
type        = files          ; files or plugin
format      = zip            ; zip (package with menu.ini) or xex (plugin file)
url         = https://...
description = One or two lines.
```

Only add menus whose authors allow sharing them.
"""

if __name__ == "__main__":
    build()
