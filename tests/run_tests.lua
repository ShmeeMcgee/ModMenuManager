-- Mod Menu Manager test suite. Runs the script against a simulated Aurora.
-- Usage (Linux/macOS, needs texlua from TeX Live):  texlua tests/run_tests.lua ModMenuManager [-v]
local here = ((arg and arg[0]) or ""):match("^(.*)[/\\]") or "."
package.path = here .. "/?.lua;" .. package.path
local lfs = require("lfs")
local A = require("mock_aurora")

local SRC = arg[1] or "ModMenuManager"
A.verbose = arg[2] == "-v"
local ROOT = "/tmp/mmm_mock"
local SCRIPT = ROOT .. "/Usb0/Aurora/User/Scripts/Utility/ModMenuManager"
local pass, fail = 0, 0

local function sh(cmd) assert(os.execute(cmd)) end
local function mkfile(path, text)
  sh("mkdir -p '" .. path:match("^(.*)/[^/]+$") .. "'")
  local f = assert(io.open(path, "wb")); f:write(text); f:close()
end
local function read(path) return A.readAll(path) end
local function check(name, cond, extra)
  if cond then pass = pass + 1; print("  PASS  " .. name)
  else fail = fail + 1; print("  FAIL  " .. name .. (extra and ("  -- " .. tostring(extra)) or "")) end
end
local function exists(p) return lfs.attributes(p) ~= nil end

local LAUNCH_INI = "[Settings]\r\nliveblock = true\r\nlivestrong = false\r\n\r\n[Plugins]\r\nplugin1 = Usb:\\Plugins\\xbdm.xex\r\nplugin2 = Usb:\\Plugins\\hayzen.xex\r\n\r\n[Paths]\r\nDefault = Usb:\\Aurora\\Aurora.xex\r\n"

local function fixture()
  sh("rm -rf " .. ROOT .. " && mkdir -p " .. ROOT)
  local MW2 = ROOT .. "/Hdd1/Games/Call of Duty Modern Warfare 2"
  mkfile(MW2 .. "/default.xex", "XEX2 sp")
  mkfile(MW2 .. "/default_mp.xex", "XEX2 mp")
  mkfile(MW2 .. "/patch_mp.ff", "ORIGINAL PATCH")
  mkfile(ROOT .. "/Hdd1/Games/Black Ops II/default_mp.xex", "XEX2")
  mkfile(ROOT .. "/Hdd1/Games/BO2 rfazio/default_mp.exe", "dev build")          -- no .xex: not a retail copy
  mkfile(ROOT .. "/Hdd1/Games/My Folder/default.xex", "XEX2")                   -- name matches nothing
  mkfile(ROOT .. "/Hdd1/Content/0000000000000000/41560855/00007000/ABCDEF0123", "GOD")
  mkfile(ROOT .. "/Usb0/launch.ini", LAUNCH_INI)
  mkfile(ROOT .. "/Usb0/Plugins/xbdm.xex", "xbdm")
  mkfile(ROOT .. "/Usb0/Plugins/hayzen.xex", "hayzen")
  mkfile(ROOT .. "/Game/placeholder", "x")
  -- the script itself
  sh("mkdir -p '" .. SCRIPT .. "' && cp -r '" .. SRC .. "'/. '" .. SCRIPT .. "/'")
  local MENUS = SCRIPT .. "/Menus"
  mkfile(MENUS .. "/MW2/Test Patch Menu/menu.ini",
    "; test\r\nname = Test Patch Menu\r\nversion = 1.2\r\nauthor = Tester\r\ntype = files\r\nmode = Multiplayer\r\nlaunch = default_mp.xex\r\nnote = Disable title updates if it doesn't load.\r\ndescription = A test menu ; with a semicolon\r\n")
  mkfile(MENUS .. "/MW2/Test Patch Menu/files/patch_mp.ff", "MODDED PATCH")
  mkfile(MENUS .. "/MW2/Test Patch Menu/files/maps/mp/gametypes/_clientids.gsc", "// menu gsc")
  mkfile(MENUS .. "/MW2/Other Menu/menu.ini", "name = Other Menu\ntype = files\n")
  mkfile(MENUS .. "/MW2/Other Menu/files/patch_mp.ff", "OTHER PATCH")
  mkfile(MENUS .. "/MW2/Failing Menu/menu.ini", "name = Failing Menu\ntype = files\n")
  mkfile(MENUS .. "/MW2/Failing Menu/files/patch_mp.ff", "FAIL PATCH")
  mkfile(MENUS .. "/MW2/Failing Menu/files/zz/fail_me.bin", "x")
  mkfile(MENUS .. "/ALL/Test Plugin/menu.ini", "name = Test Plugin\ntype = plugin\nplugin = TestMenu.xex\n")
  mkfile(MENUS .. "/ALL/Test Plugin/TestMenu.xex", "PLUGIN BYTES")
  mkfile(MENUS .. "/BO1/GOD Files Menu/menu.ini", "name = GOD Files Menu\ntype = files\n")
  mkfile(MENUS .. "/BO1/GOD Files Menu/files/patch_mp.ff", "x")
  mkfile(MENUS .. "/BO2/Broken/menu.ini", "name = Broken\ntype = weird\n")
  A.base = "Usb0:\\Aurora\\User\\Scripts\\Utility\\ModMenuManager\\"
end

local MW2 = ROOT .. "/Hdd1/Games/Call of Duty Modern Warfare 2"
local MAIN = SCRIPT .. "/main.lua"

local function run(name, answers)
  print("\n== " .. name)
  local ok, err = pcall(A.run, MAIN, answers)
  check(name .. " ran without errors", ok, err)
  return A.transcript
end
local function seen(text)
  for _, l in ipairs(A.transcript) do if l:find(text, 1, true) then return true end end
  return false
end

fixture()
A.install(ROOT)

-- 1. First run notice, install a file menu, launch the game
run("Install file menu into MW2", {
  "I understand",
  "Install a mod menu", "Modern Warfare 2", "Test Patch Menu", "Install",
  "Install", "Launch now", "OK",
})
check("game scan found MW2, BO2 and BO1 (GOD) but not the dev build", seen("3 games") and not seen("rfazio"))
check("notice shown on first run", seen("[MSG] Mod Menu Manager - Before you start"))
check("inline comment kept out of description", seen("A test menu") and not seen("with a semicolon"))
check("patch_mp.ff replaced", read(MW2 .. "/patch_mp.ff") == "MODDED PATCH")
check("new GSC copied into new folders", read(MW2 .. "/maps/mp/gametypes/_clientids.gsc") == "// menu gsc")
local bak = SCRIPT .. "/Backups/Hdd1_Games_Call_of_Duty_Modern_Warfare_2/patch_mp.ff"
check("original backed up", read(bak) == "ORIGINAL PATCH", bak)
local state = read(SCRIPT .. "/installed.txt") or ""
check("record saved with status ok", state:find("status=ok", 1, true) and state:find("file=B|patch_mp.ff", 1, true) and state:find("dir=maps", 1, true), state)
check("launch used Xbdm drive name and default_mp.xex",
  A.http[1] == 'http://192.168.1.50:730/x\r\nmagicboot title="HDD:\\Games\\Call of Duty Modern Warfare 2\\default_mp.xex" directory="HDD:\\Games\\Call of Duty Modern Warfare 2"\r\n', A.http[1])
check("log written", (read(SCRIPT .. "/manager.log") or ""):find("Install 'Test Patch Menu'", 1, true))

-- 2. Plugin menu into an empty slot (slot line missing from launch.ini)
run("Install plugin menu into plugin3", {
  "Install a mod menu", "Black Ops II    ", "Test Plugin", "Install",
  "plugin3", "Install", "OK",
})
check("notice not shown again", not seen("Before you start"))
check("broken package flagged", seen("Broken") and seen("(menu.ini needs fixing)"))
local ini = read(ROOT .. "/Usb0/launch.ini")
check("plugin3 line inserted after plugin2", ini:find("plugin2 = Usb:\\Plugins\\hayzen.xex\r\nplugin3 = Usb:\\Plugins\\ModMenus\\TestMenu.xex\r\n", 1, true), ini)
check("rest of launch.ini untouched", ini:find("liveblock = true\r\n", 1, true) and ini:find("[Paths]\r\nDefault = Usb:\\Aurora\\Aurora.xex\r\n", 1, true))
check("plugin copied", read(ROOT .. "/Usb0/Plugins/ModMenus/TestMenu.xex") == "PLUGIN BYTES")
check("launch.ini backed up", read(SCRIPT .. "/Backups/launch.ini.last") == LAUNCH_INI)

-- 3. Same plugin again is refused
run("Refuse duplicate plugin", { "Install a mod menu", "Modern Warfare 2", "Test Plugin", "Install", "OK" })
check("duplicate plugin refused", seen("Already loaded"))

-- 4. Replacing a slot that holds xbdm warns first; cancel leaves things alone
fixture(); A.install(ROOT)
run("Warn before replacing xbdm", {
  "I understand", "Install a mod menu", "Black Ops II    ", "Test Plugin", "Install", "plugin1", "Cancel",
})
check("xbdm warning shown", seen("xbdm.xex is what Dev Map Launcher"))
check("launch.ini unchanged after cancel", read(ROOT .. "/Usb0/launch.ini") == LAUNCH_INI)

-- 5. Replace an installed file menu with another one; originals stay safe
run("Install then replace", {
  "Install a mod menu", "Modern Warfare 2", "Test Patch Menu", "Install", "Install", "Done",
  "Other Menu", "Install", "Replace", "Install", "Done",
})
check("second menu in place", read(MW2 .. "/patch_mp.ff") == "OTHER PATCH")
check("first menu's GSC removed during replace", not exists(MW2 .. "/maps"))
check("backup still holds the true original", read(bak) == "ORIGINAL PATCH")
local recs = read(SCRIPT .. "/installed.txt")
check("only one record for the folder", select(2, recs:gsub("%[record%]", "")) == 1, recs)

-- 6. Remove everything from Installed menus
run("Install plugin, then remove both", {
  "Install a mod menu", "Black Ops II    ", "Test Plugin", "Install", "plugin3", "Install", "OK", "<back>", "<back>",
  "Installed menus", "Other Menu", "Remove", "Remove", "OK",
  "Test Plugin", "Remove", "Remove", "OK",
})
check("original patch restored", read(MW2 .. "/patch_mp.ff") == "ORIGINAL PATCH")
check("backup folder cleaned up", not exists(SCRIPT .. "/Backups/Hdd1_Games_Call_of_Duty_Modern_Warfare_2"))
local ini2 = read(ROOT .. "/Usb0/launch.ini")
check("plugin3 emptied again", ini2:find("plugin3 = \r\n", 1, true) and ini2:find("plugin1 = Usb:\\Plugins\\xbdm.xex", 1, true), ini2)
check("copied plugin deleted", not exists(ROOT .. "/Usb0/Plugins/ModMenus/TestMenu.xex"))
check("no records left", not (read(SCRIPT .. "/installed.txt") or ""):find("[record]", 1, true))

-- 7. Copy failure rolls everything back
A.failCopy = "fail_me.bin"
run("Roll back a failed install", {
  "Install a mod menu", "Modern Warfare 2", "Failing Menu", "Install", "Install", "OK",
})
A.failCopy = nil
check("failure reported", seen("Install stopped") and seen("Everything was put back"))
check("original still in place after rollback", read(MW2 .. "/patch_mp.ff") == "ORIGINAL PATCH")
check("no stray folder left in game", not exists(MW2 .. "/zz"))
check("no record left after rollback", not (read(SCRIPT .. "/installed.txt") or ""):find("[record]", 1, true))

-- 8. File menus are refused for Games on Demand
run("Block file menu on GOD install", {
  "Install a mod menu", "Black Ops    ", "GOD Files Menu", "Install", "OK",
})
check("GOD install explained", seen("Can't install here"))
check("GOD container untouched", not exists(ROOT .. "/Hdd1/Content/0000000000000000/41560855/00007000/patch_mp.ff"))

-- 9. Add a folder by hand, then remove it from the list
run("Add and remove a manual game folder", {
  "Game library", "Add a game folder", "Black Ops III",
  "Hdd1:\\", "Games", "My Folder", "Use this folder",
  "My Folder", "Remove from list",
})
check("manual folder was listed with marker", seen("Black Ops III  (Hdd1:\\Games\\My Folder)  *"))
check("manual folder removed", not (read(SCRIPT .. "/folders.txt") or ""):find("My Folder", 1, true))

-- 10. A half-finished install is reported on the next launch
local f = io.open(SCRIPT .. "/installed.txt", "wb")
f:write("[record]\r\nid=x\r\nkind=files\r\nstatus=installing\r\ngame=MW2\r\nmenu=Crashy\r\nfolder=Hdd1:\\Games\\Call of Duty Modern Warfare 2\r\n")
f:close()
run("Warn about unfinished install", { "OK" })
check("unfinished install warning shown", seen("Unfinished install"))

-- 11. Help and About open
run("Help and about", { "OK", "Help", "Adding menus", "OK", "<back>", "About", "OK" })
check("help and about shown", seen("Menus\\<GAME>\\<Menu name>") and seen("Released under the MIT License"))

-- 12+. Downloads from the online library (built by library/build_library.py)
local LIB = arg[3] or (here .. "/../library")
local RAWBASE = "https://raw.githubusercontent.com/ShmeeMcgee/ModMenuManager/main/library/"
local FAKE_XEX = "XEX2" .. string.rep("\0", 4096)
local function webLibrary()
  A.web = {
    [RAWBASE .. "catalog.ini"] = { file = LIB .. "/catalog.ini" },
    [RAWBASE .. "packages/shmees-menu-mw2.zip"] = { file = LIB .. "/packages/shmees-menu-mw2.zip" },
    [RAWBASE .. "packages/shmees-menu-cod4.zip"] = { file = LIB .. "/packages/shmees-menu-cod4.zip" },
    [RAWBASE .. "packages/codxe.xex"] = { text = FAKE_XEX },
    [RAWBASE .. "packages/codjumper-mw2.zip"] = { file = LIB .. "/packages/codjumper-mw2.zip" },
  }
end

fixture(); A.install(ROOT); webLibrary()
run("Download Shmees Menu for MW2, set up CoD Xe, install", {
  "I understand", "Download menus", "Modern Warfare 2", "Shmees Menu", "Download", "Install now",
  "Set up CoD Xe", "plugin3", "Install", "OK", "Install", "Done",
})
check("library title shown", seen("Shmees Menu Library  (updated 2026-11-22)"))
check("Shmees Menu package saved to library", exists(SCRIPT .. "/Menus/MW2/Shmees Menu/menu.ini") and
  exists(SCRIPT .. "/Menus/MW2/Shmees Menu/files/_codxe/mods/shmees/maps/mp/gametypes/_shmees.gsc"))
check("CoD Xe prompt shown with title update", seen("CoD Xe needed") and seen("title update TU9"))
check("CoD Xe plugin downloaded with menu.ini", read(SCRIPT .. "/Menus/ALL/CoD Xe/codxe.xex") == FAKE_XEX and
  (read(SCRIPT .. "/Menus/ALL/CoD Xe/menu.ini") or ""):find("plugin      = codxe.xex", 1, true))
local ini3 = read(ROOT .. "/Usb0/launch.ini")
check("CoD Xe loaded in plugin3", ini3:find("plugin3 = Usb:\\Plugins\\ModMenus\\codxe.xex", 1, true), ini3)
check("codxe.json put in the game folder", (read(MW2 .. "/_codxe/codxe.json") or ""):find('"active_mod": "shmees"', 1, true))
check("MW2 hook and menu scripts installed", exists(MW2 .. "/_codxe/mods/shmees/maps/mp/gametypes/_deathicons.gsc") and
  exists(MW2 .. "/_codxe/mods/shmees/maps/mp/gametypes/_shmees.gsc"))
local recs2 = read(SCRIPT .. "/installed.txt") or ""
check("both installs recorded", select(2, recs2:gsub("%[record%]", "")) == 2 and recs2:find("menu=CoD Xe", 1, true) and
  recs2:find("menu=Shmees Menu", 1, true), recs2)
check("downloads folder cleaned up", #(function() local t = {} for e in lfs.dir(SCRIPT .. "/Downloads") do
  if e ~= "." and e ~= ".." then t[#t + 1] = e end end return t end)() == 0)

run("No CoD Xe prompt once it's loaded", {
  "Install a mod menu", "Modern Warfare 2", "Shmees Menu", "Install", "Cancel",
})
check("CoD Xe not asked for again", not seen("CoD Xe needed") and seen("Replace menu?"))

run("Plugin download that fails explains the PC route", {
  "Download menus", "All games", "Hayzen", "Download", "OK",
})
check("failed download explained", seen("Download didn't finish") and seen("library/packages/Hayzen.xex"))
check("Hayzen entry prepared for a manual copy", exists(SCRIPT .. "/Menus/ALL/Hayzen/menu.ini") and
  not exists(SCRIPT .. "/Menus/ALL/Hayzen/Hayzen.xex"))

mkfile(SCRIPT .. "/Menus/_Inbox/Hayzen.xex", FAKE_XEX)
sh("cp '" .. LIB .. "/packages/shmees-menu-cod4.zip' '" .. SCRIPT .. "/Menus/_Inbox/'")
run("Import a zip and a plugin from Menus\\_Inbox", {
  "Download menus", "Import from Menus", "OK",
})
check("zip imported into its game", exists(SCRIPT .. "/Menus/COD4/Shmees Menu/menu.ini") and
  exists(SCRIPT .. "/Menus/COD4/Shmees Menu/files/_codxe/mods/shmees/maps/mp/gametypes/_clientids.gsc"))
check("known plugin imported", read(SCRIPT .. "/Menus/ALL/Hayzen/Hayzen.xex") == FAKE_XEX)
check("inbox files moved to Imported", exists(SCRIPT .. "/Menus/_Inbox/Imported/shmees-menu-cod4.zip") and
  not exists(SCRIPT .. "/Menus/_Inbox/Hayzen.xex"))

run("Remove the Shmees Menu and CoD Xe", {
  "Installed menus", "Shmees Menu", "Remove", "Remove", "OK",
  "CoD Xe", "Remove", "Remove", "OK",
})
check("game folder clean again (no _codxe left)", not exists(MW2 .. "/_codxe") and read(MW2 .. "/patch_mp.ff") == "ORIGINAL PATCH")
check("CoD Xe slot emptied", (read(ROOT .. "/Usb0/launch.ini") or ""):find("plugin3 = \r\n", 1, true))

run("Download CodJumper for MW2", { "Download menus", "Modern Warfare 2", "CodJumper", "Download", "Later" })
local cj = read(SCRIPT .. "/Menus/MW2/CodJumper/menu.ini") or ""
check("CodJumper package saved with its licence", cj:find("author      = michaeloliverx (CoD Xe)", 1, true) and
  exists(SCRIPT .. "/Menus/MW2/CodJumper/LICENSE.txt") and
  (read(SCRIPT .. "/Menus/MW2/CodJumper/files/_codxe/codxe.json") or ""):find('"codjumper"', 1, true), cj)

A.web = {}
run("Library offline", { "Download menus", "Try the library again", "OK" })
check("offline explained", seen("Library offline") and seen("Menus\\_Inbox"))

print(string.format("\n%d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
