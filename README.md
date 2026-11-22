<p align="center"><img src="logo.png" width="128" alt="Shmees"></p>

<h1 align="center">Mod Menu Manager</h1>

<p align="center">
Download, install and remove Call of Duty mod menus on the Xbox 360 from the controller.<br>
An Aurora utility script by <b>Shmees</b>, with the Shmees Menu for CoD4, World at War, MW2 and Black Ops.
</p>

<p align="center">
<img alt="Version" src="https://img.shields.io/badge/version-0.2%20preview-9be03c">
<img alt="Platform" src="https://img.shields.io/badge/platform-Xbox%20360%20%C2%B7%20Aurora-1b1f24">
<img alt="License" src="https://img.shields.io/badge/license-MIT-1b1f24">
</p>

---

## Status

**Preview build (v0.2).** The script's install, download, backup, restore and rollback logic is tested off-console against a simulated Aurora, and the Shmees Menu scripts pass static checks. Neither has been run on hardware yet, so keep the console offline and report anything odd.

## What's new in 0.2

- **Download menus.** Browse the online library from the console and save menus straight into your library, ready to install.
- **Shmees Menu.** Shmees' own mod menu for **Call of Duty 4**, **World at War**, **Modern Warfare 2** and **Black Ops**.
- **Zombies menus.** World at War (Nazi Zombies) and Black Ops (Zombies) get their own menu: points, every box weapon, Pack-a-Punch, perks, rounds, doors and power.
- **Well-known menus.** The library also carries **Hayzen**, **CodJumper** and the **CoD Xe** plugin, credited to their authors under their own licences.
- **CoD Xe setup.** Installing a Shmees Menu offers to set up the CoD Xe plugin it runs on.
- **Offline import.** Copy zips (or `codxe.xex` / `Hayzen.xex`) into `Menus\_Inbox` and import them from the console.

## Features

- **Finds your games.** Scans every drive for Call of Duty: extracted game folders and Games on Demand installs. Folders that aren't found automatically can be added by hand.
- **A menu library per game.** Menus live in `Menus\<GAME>\` beside the script, each with a short `menu.ini` describing it.
- **Two kinds of menu.**
  - *File menus*: GSC scripts, patch `.ff` files and other files copied into an extracted game folder.
  - *Plugin menus*: a `.xex` plugin placed in a free DashLaunch plugin slot.
- **Backups of everything.** Every file it replaces, and every `launch.ini` line it changes, is saved first. **Installed menus** puts it all back with one press.
- **Automatic rollback.** If a copy fails partway through, everything already changed is put back.
- **Launch from the script.** Boots the game straight after installing, through Xbdm, the same way Dev Map Launcher does.
- **Logged.** Every download, install, removal and launch is written to `manager.log`.

## The Shmees Menu

| Game | Modes | Title update | Highlights |
| --- | --- | --- | --- |
| Call of Duty 4 | Multiplayer | TU4 | God mode, UFO, every base weapon, all 11 perks, explosive bullets |
| World at War | Multiplayer + Nazi Zombies | TU7 | Weapons, all 12 perks, plus the Zombies menu |
| Modern Warfare 2 | Multiplayer | TU9 | Every base weapon, perks, every killstreak up to the Tactical Nuke |
| Black Ops | Multiplayer + Zombies | TU11 | Every base weapon, plus the Zombies menu with all 8 perks |

**Controls:** open with **Aim + Knife**. Scroll with **Aim** (up) and **Shoot** (down), select with **Use (X)**, go back with **Knife**.

**Multiplayer menu:** Main Mods (god mode, infinite ammo, UFO, super speed, third person, invisible, teleport, save and load position), Weapons, Perks, Killstreaks (MW2), Fun, Lobby (menu for everyone, super jump, low gravity, slow motion, visions, no time limit, fast restart), Players (give the menu, teleport, freeze, kill, kick) and Settings (six menu colours).

**Zombies menu:** Main Mods (god mode, infinite ammo, UFO, super speed, zombies ignore me, teleport), Points, Weapons (every weapon on the map, Pack-a-Punch, max ammo), Perks, Zombies & Rounds (kill all, skip or jump rounds, open all doors, turn on power), Players and Settings.

The host gets the menu. Hand it to other players from **Players**, or turn on **Menu for Everyone**.

### How it runs

The Shmees Menu is plain GSC, loaded by [CoD Xe](https://github.com/michaeloliverx/codxe)'s raw script loader, so no `.ff` files are edited. Its files go in the game folder under `_codxe\`, and `_codxe\codxe.json` selects the `shmees` mod. Each game hooks one small stock script so CoD Xe hands the menu control:

| Game | Hook |
| --- | --- |
| CoD4, World at War, Black Ops (MP) | `maps\mp\gametypes\_clientids.gsc` |
| Modern Warfare 2 (MP) | `maps\mp\gametypes\_deathicons.gsc` (MW2's `_clientids.gsc` is empty) |
| World at War (Nazi Zombies) | `maps\_music.gsc` |
| Black Ops (Zombies) | `maps\_zombiemode_ffotd.gsc` |

The Black Ops Zombies hook replaces the game's day-one fix script, and a modded game never uploads to the leaderboards.

Black Ops II, MW3, Ghosts, Advanced Warfare and Black Ops III aren't covered yet: CoD Xe doesn't load plain GSC scripts for them.

## The menu library

| Menu | Games | By | Licence |
| --- | --- | --- | --- |
| Shmees Menu | CoD4, World at War, MW2, Black Ops | Shmees | MIT |
| CoD Xe (loader plugin) | CoD2, CoD4, World at War, MW2, Black Ops, MW3 | [michaeloliverx](https://github.com/michaeloliverx/codxe) | MIT |
| Hayzen | CoD4, World at War, MW2, MW3, Ghosts alpha, NX1 | [ClementDreptin](https://github.com/ClementDreptin/Hayzen) | Apache-2.0 |
| CodJumper | CoD4, World at War, MW2 | [michaeloliverx](https://github.com/michaeloliverx/codxe) | MIT |

CoD Xe and Hayzen are unchanged copies of their authors' releases (CoD Xe r351, Hayzen 9.7.2), mirrored in this repository with their licences so everything downloads from one place. CoD Xe runs one mod at a time per game, so installing CodJumper switches the Shmees Menu off for that game until CodJumper is removed. If the console can't fetch a file, the script shows the address to use on a PC and where to copy it. See [`library/`](library) for the catalog format.

## Supported games

| Folder in `Menus` | Game | Title ID |
| --- | --- | --- |
| `COD4` | Call of Duty 4: Modern Warfare | 415607E6 |
| `WAW` | Call of Duty: World at War | 4156081C |
| `MW2` | Modern Warfare 2 | 41560817 |
| `BO1` | Black Ops | 41560855 |
| `MW3` | Modern Warfare 3 | 415608CB |
| `BO2` | Black Ops II | 415608C3 |
| `GHOSTS` | Ghosts | 415608FC |
| `AW` | Advanced Warfare | 41560914 |
| `BO3` | Black Ops III | 4156091D |
| `ALL` | Plugin menus that work in every game | |

## Requirements

- A homebrew-capable Xbox 360 running **Aurora**.
- For **plugin menus** and the **Shmees Menu**: DashLaunch, with `launch.ini` in the root of a drive.
- For **Launch a game**: the `xbdm.xex` plugin loaded (port 730), as for Dev Map Launcher.
- For **file menus**: the game extracted to a folder (XEX format). Games on Demand installs can only use plugin menus.
- For **Download menus**: the console online.

## Install

1. Download `ModMenuManager-v0.2.zip` and unzip it.
2. Copy the `ModMenuManager` folder to `Aurora\User\Scripts\Utility\` on your console (FTP works well). Updating from 0.1? Copy over the old folder: your menus, backups and records are kept.
3. Restart Aurora, then open **Utilities > Scripts > Mod Menu Manager**.

### Quick start: Shmees Menu

1. **Download menus** > your game > **Shmees Menu** > **Download** > **Install now**.
2. Choose **Set up CoD Xe** when asked, and pick a free plugin slot.
3. Make sure the game has the title update in the table above.
4. Power the console fully off and on, start the game, and press **Aim + Knife**.

## Adding menus

Each menu gets its own folder:

```
ModMenuManager\
  Menus\
    MW2\
      My Patch Menu\
        menu.ini
        files\
          patch_mp.ff                      <- copied to the game folder
          maps\mp\gametypes\_clientids.gsc <- folders are created as needed
    ALL\
      My Plugin Menu\
        menu.ini
        MyMenu.xex
    _Inbox\                                <- drop zips here to import them
```

- **File menus:** put the files in `files\`, laid out exactly as they go in the game folder.
- **Plugin menus:** put the `.xex` next to `menu.ini`.
- Folders starting with `_` are ignored. Ready-to-copy examples are in `Menus\_Templates`.

### menu.ini

```ini
name        = My Patch Menu
version     = 1.0
author      = Original author's name
game        = MW2              ; used when importing a zip from _Inbox
type        = files            ; files or plugin
description = One or two lines shown before installing.
mode        = Multiplayer      ; optional
launch      = default_mp.xex   ; optional, file menus: what "Launch now" boots
plugin      = MyMenu.xex       ; plugin menus: the plugin file
requires    = codxe            ; optional: offers to set up CoD Xe first
tu          = TU9              ; optional: title update the menu needs
license     = MIT              ; optional
note        = Turn off title updates in Aurora if the menu doesn't load.   ; optional
```

Only `type` is really needed. Without `name`, the folder name is used.

## Using it

| Screen | What it does |
| --- | --- |
| **Install a mod menu** | Pick a game, pick a menu, confirm. File menus ask which copy of the game if you have more than one. Plugin menus ask which plugin slot to use. |
| **Download menus** | Browse the online library by game and download menus into your library. Also imports zips from `Menus\_Inbox`. |
| **Installed menus** | Everything installed, with when and where. Select one to remove it and restore the originals, or to launch the game. |
| **Game library** | Every copy of each game that was found. Scan again, add a folder by hand, or launch from here. |
| **Launch a game** | Boot any extracted copy straight from the script. |
| **Help** | Short guides on the console itself, including the Shmees Menu controls. |

Only one file menu can be installed in a game folder at a time. Installing another offers to swap them, restoring the originals in between.

## How it works

- **File menus** back up each original into `Backups\<game folder>\`, write a record to `installed.txt`, then copy the menu in. Removing it copies the originals back, deletes files the menu added, and removes any folders it created.
- **Plugin menus** copy the `.xex` to `Plugins\ModMenus\` on the drive that holds `launch.ini`, save `launch.ini` to `Backups\launch.ini.last`, then set the chosen `pluginN` line. The drive style (`Usb:\`, `Hdd:\`) is copied from the plugins already listed. Removing it sets the line back to what it was. If something else has changed that line since (for example **Profile Switcher**), the line is left alone.
- **Downloads** use Aurora's `Http.Get` to fetch `library/catalog.ini` from this repository, save zips to `Downloads\`, unpack them with `ZipFile`, and copy the package into `Menus\<GAME>\`. Plugins are checked for an `XEX2` header before they're kept.
- **Launching** sends an Xbdm `magicboot` command to port 730 through Aurora's `Http.Get`, exactly like Dev Map Launcher.

## Settings

The tables at the top of `main.lua` can be edited:

| Setting | Default | Purpose |
| --- | --- | --- |
| `GameParents` | `Games`, `XBOX360`, `Xbox 360\Games` | Folders searched for extracted games on every drive |
| `XbdmDriveNames` | `Hdd1 = HDD` ... | How Xbdm names each drive for launching. Keep it matching Dev Map Launcher. |
| `PluginFolder` | `Plugins\ModMenus` | Where plugin menus are copied |
| `DashLaunchDevices` | `Hdd1 = Hdd:`, `Usb0 = Usb:` ... | Fallback drive names for `launch.ini` |
| `PluginSlots` | `5` | Number of DashLaunch plugin slots |
| `LibraryUrls` | this repository's `library/catalog.ini` | Where Download menus looks. `library = <url>` in `settings.ini` is tried first. |

## Limitations

- File menus need an extracted game. Games on Demand containers can't be edited.
- An active title update can load its own patch files over a `.ff` file menu. If one doesn't show up, turn off title updates for that game in Aurora. The Shmees Menu is the opposite: CoD Xe needs the title update listed above.
- Plugin menus load at boot: power the console fully off and on after installing or removing one.
- Switching profiles with Profile Switcher rewrites `launch.ini`, so install plugin menus again afterwards.
- Some consoles can't reach GitHub at all. The script then shows the address to use on a PC and the folder to copy the file into.

## Staying safe

- Use mod menus **offline, in private matches or on system link**.
- Keep `liveblock` enabled in `launch.ini` and stay off Xbox Live while running modified software.
- Everything the script changes can be undone from **Installed menus**. Backups live in the script's `Backups` folder.

## Development

```
python3 tools/gen_shmees_menu.py   # writes ShmeesMenu/<GAME>/files/...
python3 tools/lint_gsc.py          # static checks on every generated script
python3 tools/build_library.py     # writes library/catalog.ini and the zips
texlua tests/run_tests.lua ModMenuManager
```

`tests/` runs the script against a simulated Aurora (fake drives, popups, button presses, downloads and zips) and checks every install, download, import, swap, removal, rollback and plugin-slot change. It needs `texlua` (TeX Live) and `unzip`.

## Credits and license

Written by **Shmees**. Released under the [MIT License](LICENSE): use it, change it and share it.

- [CoD Xe](https://github.com/michaeloliverx/codxe) by michaeloliverx (MIT) loads the Shmees Menu.
- [Hayzen](https://github.com/ClementDreptin/Hayzen) by ClementDreptin (Apache-2.0) is mirrored in the library with its licence.
- CodJumper ships with CoD Xe (MIT) and is repackaged in the library with its licence.

- YouTube: [@Shmees14](https://www.youtube.com/@Shmees14)
- GitHub: [ShmeeMcgee](https://github.com/ShmeeMcgee)

Also by Shmees: [Dev Map Launcher](https://github.com/ShmeeMcgee/DevMapLauncher) · [Profile Switcher](https://github.com/ShmeeMcgee/ProfileSwitcher) · [Shmees Media Center](https://github.com/ShmeeMcgee/ShmeesMediaCenter)

*Not affiliated with Microsoft or Activision. Xbox 360 and Call of Duty are trademarks of their respective owners.*
