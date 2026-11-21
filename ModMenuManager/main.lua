--[[============================================================================

   M O D   M E N U   M A N A G E R                                  by Shmees
   Call of Duty mod menus for the Xbox 360, managed from the controller

   ----------------------------------------------------------------------------
   Version   0.1 (preview)
   Type      Aurora utility script
   License   MIT (see LICENSE)
   GitHub    https://github.com/ShmeeMcgee
   ----------------------------------------------------------------------------

   What it does
     - Finds your Call of Duty games on every drive (extracted folders and
       Games on Demand installs).
     - Keeps a library of mod menu packages in the Menus folder beside this
       script, sorted by game.
     - Installs two kinds of menu:
         files   menu files copied into an extracted game folder
                 (patch .ff files, GSC scripts and so on)
         plugin  a .xex menu plugin placed in a DashLaunch plugin slot
     - Backs up every file and launch.ini line it changes, and puts them all
       back with one press.
     - Boots the game straight from the script through Xbdm, the same way
       Dev Map Launcher does.

   Every change is written to manager.log beside this script.

============================================================================]]--

scriptTitle       = "Mod Menu Manager"
scriptAuthor      = "Shmees"
scriptVersion     = 0.1
scriptDescription = "Install and remove Call of Duty mod menus from the controller. Every file it replaces is backed up and can be restored in one press."
scriptIcon        = "icon.png"
scriptPermissions = { "http", "filesystem" }


--==============================================================================
-- SETTINGS  (safe to edit)
--==============================================================================

-- Folders, on every drive, that hold your extracted games.
local GameParents = { "Games", "XBOX360", "Xbox 360\\Games" }

-- How Xbdm names each Aurora drive. Used by "Launch a game".
-- Keep these the same as XbdmDriveNames in Dev Map Launcher.
local XbdmDriveNames = { Hdd1 = "HDD", Usb0 = "Usb0", Usb1 = "Usb1", Usb2 = "Usb2" }

-- Where plugin menus are copied, on the drive that holds launch.ini.
local PluginFolder = "Plugins\\ModMenus"

-- DashLaunch device names. Only used when launch.ini has no existing plugin
-- line to copy the drive style from.
local DashLaunchDevices = { Hdd1 = "Hdd:", Usb0 = "Usb:", Usb1 = "Usb:", Usb2 = "Usb:" }

-- Number of DashLaunch plugin slots (plugin1 ... plugin5).
local PluginSlots = 5


--==============================================================================
-- GAME CATALOG
--==============================================================================
-- Order matters: more specific names come first so "Black Ops II" is never
-- mistaken for "Black Ops", or "Modern Warfare 2" for "Modern Warfare".

local GAMES = {
  { key = "BO3",    name = "Black Ops III",            tid = "4156091D", words = { "black ops iii", "black ops 3", "bo3" } },
  { key = "BO2",    name = "Black Ops II",             tid = "415608C3", words = { "black ops ii", "black ops 2", "bo2" } },
  { key = "BO1",    name = "Black Ops",                tid = "41560855", words = { "black ops", "bo1" } },
  { key = "MW3",    name = "Modern Warfare 3",         tid = "415608CB", words = { "modern warfare 3", "mw3" } },
  { key = "MW2",    name = "Modern Warfare 2",         tid = "41560817", words = { "modern warfare 2", "mw2" } },
  { key = "GHOSTS", name = "Ghosts",                   tid = "415608FC", words = { "ghosts" } },
  { key = "AW",     name = "Advanced Warfare",         tid = "41560914", words = { "advanced warfare" } },
  { key = "WAW",    name = "World at War",             tid = "4156081C", words = { "world at war", "waw", "cod5" } },
  { key = "COD4",   name = "Call of Duty 4",           tid = "415607E6", words = { "call of duty 4", "cod4", "cod 4", "modern warfare" } },
}

local ALL_GAMES = { key = "ALL", name = "All games" }

-- Drives that never hold games.
local SKIP_MOUNTS = { game = true, aurora = true, flash = true, sysext = true, sysaux = true }

local VERSION_TEXT = "0.1 (preview)"
local LOG_LIMIT    = 20000
local RECORD_KEYS  = { "id", "kind", "status", "game", "menu", "version", "package", "when",
                       "folder", "ini", "slot", "previous", "value", "plugin" }


--==============================================================================
-- BASICS
--==============================================================================

local unpackArgs = table.unpack or unpack

local function safe(fn, ...)
  local ok, a, b = pcall(fn, ...)
  if ok then return a, b end
  return nil
end

local function trim(s)
  return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function trimSlash(p)
  p = tostring(p or "")
  while #p > 0 and (p:sub(-1) == "\\" or p:sub(-1) == "/") do p = p:sub(1, -2) end
  return p
end

local function join(a, b)
  if b == nil or b == "" then return trimSlash(a) end
  return trimSlash(a) .. "\\" .. b
end

local function parentOf(path)
  return (trimSlash(path):match("^(.*)\\[^\\]+$"))
end

local function leafOf(path)
  return (trimSlash(path):match("([^\\]+)$")) or path
end

local function mountName(path)
  return (tostring(path or ""):match("^([^:\\]+):")) or ""
end

local function sameText(a, b)
  local function norm(s) return trim((tostring(s or ""):gsub("\r\n", "\n"))) end
  return norm(a) == norm(b)
end

local function plural(n, word)
  return n .. " " .. word .. (n == 1 and "" or "s")
end

local function idFor(path)
  return (tostring(path):gsub("[:\\/%s]+", "_"):gsub("[^%w_%-%.]", ""))
end


--==============================================================================
-- FILE SYSTEM
--==============================================================================

local function listNames(kind, dir)
  local out = {}
  local t = safe(function()
    if kind == "files" then return FileSystem.GetFiles(trimSlash(dir) .. "\\*") end
    return FileSystem.GetDirectories(trimSlash(dir) .. "\\*")
  end)
  if type(t) == "table" then
    for _, e in pairs(t) do
      local n = type(e) == "table" and e.Name or e
      if type(n) == "string" and n ~= "" and n ~= "." and n ~= ".." then out[#out + 1] = n end
    end
  end
  table.sort(out, function(x, y) return x:lower() < y:lower() end)
  return out
end

local function listFiles(dir) return listNames("files", dir) end
local function listDirs(dir)  return listNames("dirs", dir) end

local function exists(path)
  return safe(function() return FileSystem.FileExists(path) end) == true
end

local function dirExists(path)
  path = trimSlash(path)
  local parent = parentOf(path)
  if not parent then return true end            -- a drive root
  local want = leafOf(path):lower()
  for _, d in ipairs(listDirs(parent)) do
    if d:lower() == want then return true end
  end
  return false
end

local function sizeOf(path)
  return tonumber(safe(function() return FileSystem.GetFileSize(path) end))
end

local function readText(path)
  local s = safe(function() return FileSystem.ReadFile(path) end)
  if type(s) == "string" then return s end
  return nil
end

local function writeText(path, text)
  safe(function() return FileSystem.WriteFile(path, text) end)
  return sameText(readText(path), text)
end

local function mkdirs(path)
  path = trimSlash(path)
  local mount, rest = path:match("^([^\\]+:)\\?(.*)$")
  if not mount then return false end
  local cur = mount
  for part in rest:gmatch("[^\\]+") do
    cur = cur .. "\\" .. part
    if not dirExists(cur) then safe(function() return FileSystem.CreateDirectory(cur) end) end
  end
  return dirExists(path)
end

local function copyFile(src, dst)
  local parent = parentOf(dst)
  if parent and not mkdirs(parent) then return false end
  safe(function() return FileSystem.CopyFile(src, dst, true) end)
  if not exists(dst) then return false end
  local a, b = sizeOf(src), sizeOf(dst)
  return a == nil or b == nil or a == b
end

local function deleteFile(path)
  safe(function() return FileSystem.DeleteFile(path) end)
  return not exists(path)
end

local function isEmptyDir(dir)
  return #listFiles(dir) == 0 and #listDirs(dir) == 0
end

-- Removes empty folders under (and including) dir. Never touches files.
local function pruneEmpty(dir, depth)
  depth = depth or 0
  if depth > 16 then return end
  for _, d in ipairs(listDirs(dir)) do pruneEmpty(join(dir, d), depth + 1) end
  if dirExists(dir) and isEmptyDir(dir) then
    safe(function() return FileSystem.DeleteDirectory(dir) end)
  end
end

-- Every file under dir, as paths relative to dir.
local function walk(dir, rel, out, depth)
  out, depth = out or {}, depth or 0
  if depth > 16 then return out end
  for _, f in ipairs(listFiles(dir)) do out[#out + 1] = rel and (rel .. "\\" .. f) or f end
  for _, d in ipairs(listDirs(dir)) do
    walk(join(dir, d), rel and (rel .. "\\" .. d) or d, out, depth + 1)
  end
  return out
end

local function drives()
  local out = {}
  local t = safe(function() return FileSystem.GetDrives() end)
  if type(t) == "table" then
    for _, d in pairs(t) do
      local m = type(d) == "table" and d.MountPoint or d
      if type(m) == "string" and m ~= "" then out[#out + 1] = trimSlash(m) end
    end
  end
  table.sort(out, function(x, y) return x:lower() < y:lower() end)
  return out
end

local function gameDrives()
  local out = {}
  for _, d in ipairs(drives()) do
    if not SKIP_MOUNTS[mountName(d):lower()] then out[#out + 1] = d end
  end
  return out
end


--==============================================================================
-- PATHS, LOG AND SETTINGS
--==============================================================================

local BASE      = trimSlash(safe(function() return Script.GetBasePath() end) or "Game:")
local MENUS     = join(BASE, "Menus")
local BACKUPS   = join(BASE, "Backups")
local STATE     = join(BASE, "installed.txt")
local FOLDERS   = join(BASE, "folders.txt")
local SETTINGS  = join(BASE, "settings.ini")
local LOGFILE   = join(BASE, "manager.log")

local function num(t, ...)
  if type(t) ~= "table" then return nil end
  for _, k in ipairs({ ... }) do
    if t[k] ~= nil then return tonumber(t[k]) end
  end
  return nil
end

local function stamp()
  local d = safe(function() return Aurora.GetDate() end)
  local t = safe(function() return Aurora.GetTime() end)
  local y, mo, da = num(d, "Year", "year", "wYear"), num(d, "Month", "month", "wMonth"), num(d, "Day", "day", "wDay")
  local h, mi = num(t, "Hour", "hour", "wHour"), num(t, "Minute", "minute", "wMinute")
  local s = ""
  if y and mo and da then s = string.format("%04d-%02d-%02d", y, mo, da) end
  if h and mi then s = s .. (s ~= "" and " " or "") .. string.format("%02d:%02d", h, mi) end
  return s ~= "" and s or "--"
end

local function log(msg)
  local old = readText(LOGFILE) or ""
  if #old > LOG_LIMIT then
    old = old:sub(-math.floor(LOG_LIMIT / 2)):gsub("^[^\n]*\n", "")
  end
  safe(function() return FileSystem.WriteFile(LOGFILE, old .. "[" .. stamp() .. "] " .. msg .. "\r\n") end)
end

local function parseIni(text)
  local t = {}
  for line in tostring(text or ""):gmatch("[^\r\n]+") do
    local l = trim(line)
    if l ~= "" and not l:match("^[;#]") and not l:match("^%[") then
      local k, v = l:match("^([%w_%.%-]+)%s*=%s*(.-)$")
      if k then t[k:lower()] = trim((v:gsub("%s+;.*$", ""))) end
    end
  end
  return t
end

local function getSetting(key)
  return parseIni(readText(SETTINGS))[key]
end

local function setSetting(key, value)
  local t = parseIni(readText(SETTINGS))
  t[key] = tostring(value)
  local lines = { "; Mod Menu Manager settings" }
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys)
  for _, k in ipairs(keys) do lines[#lines + 1] = k .. " = " .. t[k] end
  writeText(SETTINGS, table.concat(lines, "\r\n") .. "\r\n")
end


--==============================================================================
-- INTERFACE
--==============================================================================

local function popup(title, items, emptyText)
  local list = {}
  for i, v in ipairs(items) do list[i] = v end
  local ret = Script.ShowPopupList(title, emptyText or "Nothing here yet.", list)
  if ret == nil or ret.Canceled or ret.Selected == nil then return nil end
  local key = tonumber(ret.Selected.Key)
  if key and items[key] then return key end
  for i, v in ipairs(items) do
    if v == ret.Selected.Value then return i end
  end
  return nil
end

local function ask(title, text, ...)
  local r = Script.ShowMessageBox(title, text, ...)
  if r == nil or r.Canceled then return nil end
  return r.Button
end

local function info(title, text)
  ask(title, text, "OK")
end

local function notify(msg)
  safe(function() Script.ShowNotification(msg) end)
end

local function progress(text, cur, total)
  safe(function()
    if text then Script.SetStatus(text) end
    if total and total > 0 then Script.SetProgress(math.floor((cur or 0) * 100 / total)) end
  end)
end

local function canceled()
  return safe(function() return Script.IsCanceled() end) == true
end

local function title(screen)
  return screen and ("Mod Menu Manager - " .. screen) or "Mod Menu Manager"
end


--==============================================================================
-- GAME DETECTION
--==============================================================================

local function gameByKey(key)
  if key == "ALL" then return ALL_GAMES end
  for _, g in ipairs(GAMES) do
    if g.key == key then return g end
  end
  return nil
end

local function matchGame(folderName)
  local padded = " " .. tostring(folderName):lower():gsub("[^%w]+", " ") .. " "
  for _, g in ipairs(GAMES) do
    if padded:find(" " .. g.tid:lower() .. " ", 1, true) then return g end
  end
  for _, g in ipairs(GAMES) do
    for _, w in ipairs(g.words) do
      if padded:find(" " .. w .. " ", 1, true) then return g end
    end
  end
  return nil
end

local function findExes(folder)
  local out = {}
  for _, f in ipairs(listFiles(folder)) do
    if f:lower():match("%.xex$") then out[#out + 1] = f end
  end
  -- multiplayer first, then the main executable
  table.sort(out, function(a, b)
    local function rank(n)
      n = n:lower()
      if n == "default_mp.xex" then return 1 end
      if n == "default.xex" then return 2 end
      return 3
    end
    local ra, rb = rank(a), rank(b)
    if ra ~= rb then return ra < rb end
    return a:lower() < b:lower()
  end)
  return out
end

local function loadManualFolders()
  local out = {}
  for line in (readText(FOLDERS) or ""):gmatch("[^\r\n]+") do
    local key, path = line:match("^%s*([%w]+)|(.-)%s*$")
    if key and gameByKey(key) and path ~= "" then out[#out + 1] = { key = key, path = path } end
  end
  return out
end

local function saveManualFolders(list)
  local lines = { "; Game folders added by hand: GAME|path" }
  for _, e in ipairs(list) do lines[#lines + 1] = e.key .. "|" .. e.path end
  return writeText(FOLDERS, table.concat(lines, "\r\n") .. "\r\n")
end

local installCache = nil

local function scanGames(force)
  if installCache and not force then return installCache end
  progress("Looking for Call of Duty games...", 0, 1)
  local found, seen = {}, {}
  local function add(entry)
    local k = entry.path:lower()
    if seen[k] then return end
    seen[k] = true
    found[#found + 1] = entry
  end

  for _, drive in ipairs(gameDrives()) do
    -- Extracted games
    for _, parent in ipairs(GameParents) do
      local base = join(drive, parent)
      for _, dir in ipairs(listDirs(base)) do
        local g = matchGame(dir)
        if g then
          local path = join(base, dir)
          if #findExes(path) > 0 then add({ game = g, path = path, format = "folder", source = "auto" }) end
        end
      end
    end
    -- Games on Demand
    local content = join(drive, "Content\\0000000000000000")
    local tids = {}
    for _, d in ipairs(listDirs(content)) do tids[d:upper()] = d end
    for _, g in ipairs(GAMES) do
      local real = tids[g.tid]
      if real then
        local god = join(join(content, real), "00007000")
        if dirExists(god) then add({ game = g, path = god, format = "god", source = "auto" }) end
      end
    end
  end

  for _, m in ipairs(loadManualFolders()) do
    local god = m.path:lower():find("\\content\\0000000000000000\\", 1, true) ~= nil
    add({ game = gameByKey(m.key), path = m.path, format = god and "god" or "folder", source = "manual" })
  end

  local order = {}
  for i, g in ipairs(GAMES) do order[g.key] = i end
  table.sort(found, function(a, b)
    if a.game.key ~= b.game.key then return order[a.game.key] < order[b.game.key] end
    return a.path:lower() < b.path:lower()
  end)

  installCache = found
  log("Scan found " .. plural(#found, "game install"))
  return found
end

local function installsFor(key)
  local out = {}
  for _, inst in ipairs(scanGames()) do
    if inst.game.key == key then out[#out + 1] = inst end
  end
  return out
end

local function describeInstall(inst)
  if inst.format == "god" then
    return inst.game.name .. "  (Games on Demand, " .. mountName(inst.path) .. ")"
  end
  return inst.game.name .. "  (" .. inst.path .. ")"
end


--==============================================================================
-- INSTALL RECORDS
--==============================================================================

local function loadRecords()
  local recs, cur = {}, nil
  for line in (readText(STATE) or ""):gmatch("[^\r\n]+") do
    line = trim(line)
    if line == "[record]" then
      cur = { files = {}, dirs = {} }
      recs[#recs + 1] = cur
    elseif cur and not line:match("^;") then
      local k, v = line:match("^(%w+)=(.*)$")
      if k == "file" then
        local flag, rel = v:match("^([BN])|(.+)$")
        if flag then cur.files[#cur.files + 1] = { flag = flag, rel = rel } end
      elseif k == "dir" then
        cur.dirs[#cur.dirs + 1] = v
      elseif k then
        cur[k] = v
      end
    end
  end
  return recs
end

local function saveRecords(recs)
  local out = { "; Mod Menu Manager install records. Don't edit while the script is open." }
  for _, r in ipairs(recs) do
    out[#out + 1] = ""
    out[#out + 1] = "[record]"
    for _, k in ipairs(RECORD_KEYS) do
      if r[k] ~= nil and tostring(r[k]) ~= "" then out[#out + 1] = k .. "=" .. tostring(r[k]) end
    end
    for _, d in ipairs(r.dirs or {}) do out[#out + 1] = "dir=" .. d end
    for _, f in ipairs(r.files or {}) do out[#out + 1] = "file=" .. f.flag .. "|" .. f.rel end
  end
  return writeText(STATE, table.concat(out, "\r\n") .. "\r\n")
end

local function findRecord(recs, test)
  for i, r in ipairs(recs) do
    if test(r) then return r, i end
  end
  return nil
end

local function dropRecord(recs, rec)
  for i, r in ipairs(recs) do
    if r == rec then table.remove(recs, i) return end
  end
end

local function describeRecord(r)
  local game = gameByKey(r.game)
  local where
  if r.kind == "plugin" then
    where = "plugin" .. tostring(r.slot)
  else
    where = r.folder or "?"
  end
  local flag = (r.status ~= "ok") and "[!] " or ""
  return flag .. (game and game.key or tostring(r.game)) .. "  " .. tostring(r.menu) .. "  (" .. where .. ")"
end


--==============================================================================
-- MENU PACKAGES
--==============================================================================

local function loadPackages(gameKey)
  local list = {}
  local scopes = { gameKey }
  if gameKey ~= "ALL" then scopes[2] = "ALL" end
  for _, scope in ipairs(scopes) do
    local dir = join(MENUS, scope)
    for _, folder in ipairs(listDirs(dir)) do
      if folder:sub(1, 1) ~= "_" then
        local pdir = join(dir, folder)
        local ini = parseIni(readText(join(pdir, "menu.ini")))
        local pkg = {
          dir         = pdir,
          scope       = scope,
          name        = (ini.name and ini.name ~= "") and ini.name or folder,
          version     = ini.version or "",
          author      = ini.author or "",
          kind        = (ini.type or "files"):lower(),
          description = ini.description or "",
          mode        = ini.mode or "",
          note        = ini.note or "",
          launch      = ini.launch or "",
          plugin      = ini.plugin or "",
        }
        if pkg.kind == "plugin" and pkg.plugin == "" then
          for _, f in ipairs(listFiles(pdir)) do
            if f:lower():match("%.xex$") then pkg.plugin = f break end
          end
        end
        if pkg.kind ~= "files" and pkg.kind ~= "plugin" then
          pkg.problem = "Unknown type '" .. pkg.kind .. "' in menu.ini. Use files or plugin."
        end
        list[#list + 1] = pkg
      end
    end
  end
  table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
  return list
end

local function countPackages(key)
  return #loadPackages(key)
end

local function packageDetails(pkg, game)
  local lines = {}
  local head = pkg.name
  if pkg.version ~= "" then head = head .. "  v" .. pkg.version end
  lines[#lines + 1] = head
  if pkg.author ~= "" then lines[#lines + 1] = "By " .. pkg.author end
  lines[#lines + 1] = ""
  if pkg.description ~= "" then
    lines[#lines + 1] = pkg.description
    lines[#lines + 1] = ""
  end
  lines[#lines + 1] = "Game:  " .. (pkg.scope == "ALL" and "All supported games" or game.name)
  lines[#lines + 1] = "Type:  " .. (pkg.kind == "plugin" and ("Plugin menu (" .. pkg.plugin .. ")") or "Game files")
  if pkg.mode ~= "" then lines[#lines + 1] = "Mode:  " .. pkg.mode end
  if pkg.note ~= "" then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Note:  " .. pkg.note
  end
  return table.concat(lines, "\n")
end


--==============================================================================
-- LAUNCHING (Xbdm magicboot, as in Dev Map Launcher)
--==============================================================================

local function xbdmPath(path)
  local mount, rest = trimSlash(path):match("^([^:\\]+):\\?(.*)$")
  if not mount then return path end
  return (XbdmDriveNames[mount] or mount) .. ":\\" .. rest
end

local function bootTitle(folder, exe)
  local cmd = 'magicboot title="' .. xbdmPath(join(folder, exe)) .. '" directory="' .. xbdmPath(folder) .. '"'
  log("Launch: " .. cmd)
  local hosts = {}
  local ip = safe(function() return Aurora.GetIPAddress() end)
  if type(ip) == "string" and ip:match("^%d+%.%d+%.%d+%.%d+$") and ip ~= "0.0.0.0" then hosts[#hosts + 1] = ip end
  hosts[#hosts + 1] = "127.0.0.1"

  notify("Launching " .. exe .. "...")
  for _, host in ipairs(hosts) do
    local url = "http://" .. host .. ":730/x\r\n" .. cmd .. "\r\n"
    local http = safe(function() return Http.Get(url) end)
    local ok = http ~= nil and http.Success
    log("  " .. host .. " -> " .. (http == nil and "no response" or ("Success=" .. tostring(http.Success))))
    if ok then break end
    safe(function() Thread.Sleep(1500) end)
  end
  -- If the console is rebooting, the script ends before this point.
  safe(function() Thread.Sleep(3000) end)
  info(title("Launch"),
    "The launch command was sent.\n\nIf the console didn't restart, make sure xbdm.xex is loaded in launch.ini " ..
    "(Dev Map Launcher needs it too), or start the game from Aurora as usual.")
end

local function chooseExe(inst, preferred)
  local exes = findExes(inst.path)
  if #exes == 0 then return nil end
  if preferred and preferred ~= "" then
    for _, e in ipairs(exes) do
      if e:lower() == preferred:lower() then return e end
    end
  end
  if #exes == 1 then return exes[1] end
  local labels = {}
  for i, e in ipairs(exes) do
    local l = e:lower()
    labels[i] = e .. ((l == "default_mp.xex" and "   (Multiplayer)") or (l == "default.xex" and "   (Campaign / main)") or "")
  end
  local n = popup(title("Choose executable"), labels)
  return n and exes[n] or nil
end

local function launchInstall(inst, preferred)
  if inst.format == "god" then
    info(title("Launch"), "Games on Demand installs can't be booted by path. Start this game from Aurora's game list.")
    return
  end
  local exe = chooseExe(inst, preferred)
  if not exe then
    info(title("Launch"), "No .xex was found in:\n" .. inst.path)
    return
  end
  bootTitle(inst.path, exe)
end


--==============================================================================
-- FILE MENUS
--==============================================================================

local function restoreFiles(rec)
  local backupDir = join(BACKUPS, rec.id)
  local failed = {}
  local total = #rec.files
  for i, f in ipairs(rec.files) do
    progress("Restoring " .. f.rel, i - 1, total)
    local dst = join(rec.folder, f.rel)
    if f.flag == "B" then
      local bak = join(backupDir, f.rel)
      if exists(bak) then
        if copyFile(bak, dst) then deleteFile(bak) else failed[#failed + 1] = f.rel end
      else
        failed[#failed + 1] = f.rel .. "  (backup missing)"
      end
    elseif exists(dst) and not deleteFile(dst) then
      failed[#failed + 1] = f.rel
    end
  end
  -- folders this menu created inside the game, deepest first
  table.sort(rec.dirs, function(a, b) return #a > #b end)
  for _, d in ipairs(rec.dirs) do
    local full = join(rec.folder, d)
    if dirExists(full) and isEmptyDir(full) then
      safe(function() return FileSystem.DeleteDirectory(full) end)
    end
  end
  pruneEmpty(backupDir)
  progress("Done", 1, 1)
  return failed
end

local function removeFilesRecord(rec, recs)
  log("Remove '" .. tostring(rec.menu) .. "' from " .. tostring(rec.folder))
  local failed = restoreFiles(rec)
  if #failed == 0 then
    dropRecord(recs, rec)
    saveRecords(recs)
    log("  Restored " .. plural(#rec.files, "file"))
    return true
  end
  rec.status = "partial"
  rec.files = (function()
    local keep, bad = {}, {}
    for _, f in ipairs(failed) do bad[(f:gsub("  %(backup missing%)$", ""))] = true end
    for _, f in ipairs(rec.files) do
      if bad[f.rel] then keep[#keep + 1] = f end
    end
    return keep
  end)()
  saveRecords(recs)
  log("  Could not restore: " .. table.concat(failed, ", "))
  info(title("Restore problem"),
    "These files couldn't be put back:\n\n" .. table.concat(failed, "\n") ..
    "\n\nThe record was kept, so you can try again from Installed menus. Backups are in:\n" .. join(BACKUPS, rec.id))
  return false
end

local function installFiles(pkg, inst)
  if inst.format == "god" then
    info(title("Can't install here"),
      inst.game.name .. " is installed as Games on Demand, so its files can't be replaced.\n\n" ..
      "Extract the game to a folder (XEX format) and add it under Game library, or use a plugin menu.")
    return false
  end

  local src = join(pkg.dir, "files")
  local rels = walk(src)
  if #rels == 0 then
    info(title("Empty package"),
      "No files were found in:\n" .. src .. "\n\nPut the menu's files in the package's 'files' folder, " ..
      "laid out exactly as they go in the game folder.")
    return false
  end

  local recs = loadRecords()
  local current = findRecord(recs, function(r) return r.kind == "files" and r.folder and r.folder:lower() == inst.path:lower() end)
  if current then
    local b = ask(title("Replace menu?"),
      tostring(current.menu) .. " is installed in this game right now.\n\nRemove it and install " .. pkg.name .. " instead?",
      "Replace", "Cancel")
    if b ~= 1 then return false end
    if not removeFilesRecord(current, recs) then return false end
    recs = loadRecords()
  end

  local replacing = 0
  for _, rel in ipairs(rels) do
    if exists(join(inst.path, rel)) then replacing = replacing + 1 end
  end
  local summary = "Game:    " .. inst.game.name .. "\nFolder:  " .. inst.path ..
    "\n\n" .. plural(#rels, "file") .. " will be copied." ..
    (replacing > 0 and ("\n" .. plural(replacing, "original file") .. " will be backed up first.") or "") ..
    (pkg.note ~= "" and ("\n\nNote: " .. pkg.note) or "")
  if ask(title("Install " .. pkg.name), summary, "Install", "Cancel") ~= 1 then return false end

  log("Install '" .. pkg.name .. "' (" .. pkg.dir .. ") into " .. inst.path)
  local id = idFor(inst.path)
  local backupDir = join(BACKUPS, id)
  local rec = {
    id = id, kind = "files", status = "installing", game = inst.game.key, menu = pkg.name,
    version = pkg.version, package = pkg.dir, when = stamp(), folder = inst.path, files = {}, dirs = {},
  }

  -- 1. Back up every original this menu will replace.
  for i, rel in ipairs(rels) do
    progress("Backing up " .. rel, i - 1, #rels)
    local dst = join(inst.path, rel)
    if exists(dst) then
      local bak = join(backupDir, rel)
      if not exists(bak) and not copyFile(dst, bak) then
        log("  Backup failed: " .. rel)
        info(title("Install stopped"), "Couldn't back up:\n" .. rel .. "\n\nNothing in the game was changed.")
        pruneEmpty(backupDir)
        return false
      end
      rec.files[#rec.files + 1] = { flag = "B", rel = rel }
    else
      rec.files[#rec.files + 1] = { flag = "N", rel = rel }
    end
  end

  -- Folders the menu adds that the game doesn't have yet.
  local seenDir = {}
  for _, rel in ipairs(rels) do
    local p = parentOf(rel)
    while p and not seenDir[p:lower()] do
      seenDir[p:lower()] = true
      if not dirExists(join(inst.path, p)) then rec.dirs[#rec.dirs + 1] = p end
      p = parentOf(p)
    end
  end

  recs[#recs + 1] = rec
  if not saveRecords(recs) then
    info(title("Install stopped"), "Couldn't write the install record beside the script, so nothing was changed.\n\n" .. STATE)
    return false
  end

  -- 2. Copy the menu in. Any failure rolls everything back.
  for i, rel in ipairs(rels) do
    progress("Installing " .. rel, i - 1, #rels)
    if canceled() or not copyFile(join(src, rel), join(inst.path, rel)) then
      log("  Copy failed or canceled at " .. rel .. ", rolling back")
      local ok = removeFilesRecord(rec, recs)
      info(title("Install stopped"),
        "Couldn't copy:\n" .. rel .. "\n\n" .. (ok and "Everything was put back the way it was." or "Some files need restoring, see the last message."))
      return false
    end
  end

  rec.status = "ok"
  saveRecords(recs)
  progress("Done", 1, 1)
  log("  Installed " .. plural(#rels, "file") .. ", backed up " .. replacing)
  notify(pkg.name .. " installed")

  if #findExes(inst.path) > 0 then
    if ask(title("Installed"), pkg.name .. " is installed in " .. inst.game.name .. ".\n\nLaunch the game now?",
        "Launch now", "Done") == 1 then
      launchInstall(inst, pkg.launch)
    end
  else
    info(title("Installed"), pkg.name .. " is installed in " .. inst.game.name .. ".")
  end
  return true
end


--==============================================================================
-- PLUGIN MENUS (DashLaunch launch.ini)
--==============================================================================

local function eolOf(text)
  return text:find("\r\n", 1, true) and "\r\n" or "\n"
end

local function splitLines(text)
  local lines = {}
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = (line:gsub("\r$", "")) end
  if lines[#lines] == "" then lines[#lines] = nil end
  return lines
end

local function readSlots(text)
  local slots, inPlugins = {}, false
  for _, line in ipairs(splitLines(text or "")) do
    local l = trim(line)
    local sec = l:match("^%[(.-)%]")
    if sec then
      inPlugins = sec:lower() == "plugins"
    elseif inPlugins then
      local k, v = l:match("^([%w_]+)%s*=%s*(.-)%s*$")
      local n = k and tonumber(k:lower():match("^plugin(%d+)$"))
      if n then slots[n] = trim((v:gsub("%s*;.*$", ""))) end
    end
  end
  return slots
end

local function writeSlot(text, n, value)
  local eol = eolOf(text)
  local lines = splitLines(text)
  local inPlugins, header, lastPlugin, done = false, nil, nil, false
  for i, line in ipairs(lines) do
    local l = trim(line)
    local sec = l:match("^%[(.-)%]")
    if sec then
      inPlugins = sec:lower() == "plugins"
      if inPlugins then header = i end
    elseif inPlugins then
      local k = l:match("^([%w_]+)%s*=")
      local m = k and tonumber(k:lower():match("^plugin(%d+)$"))
      if m then
        lastPlugin = i
        if m == n and not done then
          lines[i] = "plugin" .. n .. " = " .. value
          done = true
        end
      end
    end
  end
  if not done then
    local at = lastPlugin or header
    if not at then return nil end
    table.insert(lines, at + 1, "plugin" .. n .. " = " .. value)
  end
  return table.concat(lines, eol) .. eol
end

local function findLaunchInis()
  local out = {}
  for _, drive in ipairs(gameDrives()) do
    local path = join(drive, "launch.ini")
    local text = readText(path)
    if text and text:lower():find("[plugins]", 1, true) then
      out[#out + 1] = { path = path, drive = drive, text = text }
    end
  end
  return out
end

-- Builds the path DashLaunch should load, copying the style of the plugins
-- already in launch.ini when it can.
local function dashPath(ini, slots, file)
  local rel = PluginFolder .. "\\" .. file
  local mount = mountName(ini.drive)
  local family = mount:lower():match("^(%a+)") or ""
  local fallback = nil
  for _, v in pairs(slots) do
    local prefix, rest = tostring(v):match("^([^\\]+:)\\(.+)$")
    if prefix and exists(join(ini.drive, rest)) then
      if prefix:lower():sub(1, #family) == family then return prefix .. "\\" .. rel end
      fallback = fallback or prefix
    end
  end
  if fallback then return fallback .. "\\" .. rel end
  return (DashLaunchDevices[mount] or (mount .. ":")) .. "\\" .. rel
end

local function chooseLaunchIni()
  local inis = findLaunchInis()
  if #inis == 0 then
    info(title("launch.ini not found"),
      "DashLaunch's launch.ini wasn't found in the root of any drive.\n\nPlugin menus need DashLaunch. File menus still work.")
    return nil
  end
  if #inis == 1 then return inis[1] end
  local labels = {}
  for i, e in ipairs(inis) do labels[i] = e.path end
  local n = popup(title("Which launch.ini?"), labels)
  return n and inis[n] or nil
end

local function pluginStillUsed(recs, path, except)
  for _, r in ipairs(recs) do
    if r ~= except and r.kind == "plugin" and r.plugin and r.plugin:lower() == path:lower() then return true end
  end
  return false
end

local function removePluginRecord(rec, recs)
  log("Remove plugin '" .. tostring(rec.menu) .. "' from plugin" .. tostring(rec.slot) .. " in " .. tostring(rec.ini))
  local n = tonumber(rec.slot)
  local text = readText(rec.ini)
  if not text then
    info(title("Restore problem"), "Couldn't read:\n" .. tostring(rec.ini) .. "\n\nIs that drive connected?")
    return false
  end
  local current = readSlots(text)[n] or ""
  local note = ""
  if current:lower() == tostring(rec.value):lower() then
    local newText = writeSlot(text, n, rec.previous or "")
    if not newText or not writeText(rec.ini, newText) then
      info(title("Restore problem"), "Couldn't update launch.ini. A copy from before the install is in:\n" .. join(BACKUPS, "launch.ini.last"))
      return false
    end
    log("  plugin" .. n .. " set back to: " .. ((rec.previous or "") ~= "" and rec.previous or "(empty)"))
  else
    note = "\n\nplugin" .. n .. " had already been changed (for example by Profile Switcher), so launch.ini was left alone."
    log("  plugin" .. n .. " already changed, launch.ini left alone")
  end
  if rec.plugin and not pluginStillUsed(recs, rec.plugin, rec) then deleteFile(rec.plugin) end
  dropRecord(recs, rec)
  saveRecords(recs)
  info(title("Removed"), tostring(rec.menu) .. " was removed." .. note .. "\n\nFully power off the console and turn it back on to unload it.")
  return true
end

local function installPlugin(pkg, game)
  local src = pkg.plugin ~= "" and join(pkg.dir, pkg.plugin) or nil
  if not src or not exists(src) then
    info(title("Plugin missing"),
      "This package needs its .xex plugin file.\n\nCopy " .. (pkg.plugin ~= "" and pkg.plugin or "the plugin .xex") ..
      " into:\n" .. pkg.dir)
    return false
  end

  local ini = chooseLaunchIni()
  if not ini then return false end
  local slots = readSlots(ini.text)
  local dest = join(ini.drive, join(PluginFolder, pkg.plugin))
  local value = dashPath(ini, slots, pkg.plugin)

  for s = 1, PluginSlots do
    if (slots[s] or ""):lower() == value:lower() then
      info(title("Already loaded"), pkg.name .. " is already in plugin" .. s .. ".")
      return false
    end
  end

  local labels = {}
  for s = 1, PluginSlots do
    local v = slots[s] or ""
    labels[s] = "plugin" .. s .. "    " .. (v ~= "" and v or "(empty)")
  end
  local n = popup(title("Choose a plugin slot"), labels)
  if not n then return false end

  local prev = slots[n] or ""
  if prev ~= "" then
    local warn = ""
    if prev:lower():find("xbdm", 1, true) then
      warn = "\n\nxbdm.xex is what Dev Map Launcher and Launch a game use. Pick another slot if you need them."
    end
    if ask(title("Slot in use"),
        "plugin" .. n .. " currently loads:\n" .. prev .. "\n\nReplace it with " .. pkg.name ..
        "? It goes back when you remove the menu." .. warn, "Replace", "Cancel") ~= 1 then
      return false
    end
  end

  if ask(title("Install " .. pkg.name),
      "Plugin:      " .. pkg.plugin .. "\nCopied to:  " .. dest .. "\nSlot:        plugin" .. n ..
      "\nlaunch.ini:  " .. ini.path .. "\n\nlaunch.ini is backed up first. Plugins load at boot, so you'll need to " ..
      "power the console off and on afterwards." .. (pkg.note ~= "" and ("\n\nNote: " .. pkg.note) or ""),
      "Install", "Cancel") ~= 1 then
    return false
  end

  log("Install plugin '" .. pkg.name .. "' into plugin" .. n .. " of " .. ini.path)
  progress("Copying " .. pkg.plugin, 0, 3)
  if not copyFile(src, dest) then
    log("  Copy failed: " .. dest)
    info(title("Install stopped"), "Couldn't copy the plugin to:\n" .. dest .. "\n\nlaunch.ini was not changed.")
    return false
  end

  progress("Backing up launch.ini", 1, 3)
  local backup = join(BACKUPS, "launch.ini.last")
  if not copyFile(ini.path, backup) then
    log("  launch.ini backup failed")
    info(title("Install stopped"), "Couldn't back up launch.ini, so it was not changed.")
    return false
  end

  progress("Updating launch.ini", 2, 3)
  local newText = writeSlot(ini.text, n, value)
  if not newText or not writeText(ini.path, newText) or (readSlots(readText(ini.path))[n] or "") ~= value then
    copyFile(backup, ini.path)
    log("  launch.ini update failed, original restored")
    info(title("Install stopped"), "Couldn't update launch.ini. The original was put back.")
    return false
  end

  local recs = loadRecords()
  local older = findRecord(recs, function(r)
    return r.kind == "plugin" and r.ini and r.ini:lower() == ini.path:lower() and tonumber(r.slot) == n
  end)
  if older then
    prev = older.previous or ""
    if older.plugin and older.plugin:lower() ~= dest:lower() and not pluginStillUsed(recs, older.plugin, older) then
      deleteFile(older.plugin)
    end
    dropRecord(recs, older)
  end
  recs[#recs + 1] = {
    id = idFor(ini.path) .. "_plugin" .. n, kind = "plugin", status = "ok",
    game = pkg.scope == "ALL" and "ALL" or game.key, menu = pkg.name, version = pkg.version,
    package = pkg.dir, when = stamp(), ini = ini.path, slot = n, previous = prev, value = value, plugin = dest,
    files = {}, dirs = {},
  }
  saveRecords(recs)
  progress("Done", 3, 3)
  log("  plugin" .. n .. " = " .. value)
  notify(pkg.name .. " installed")
  info(title("Installed"),
    pkg.name .. " is in plugin" .. n .. ".\n\nFully power off the console and turn it back on. Plugins only load at boot." ..
    "\n\nIf you switch profiles with Profile Switcher, install the menu again afterwards.")
  return true
end


--==============================================================================
-- SCREENS
--==============================================================================

local function chooseInstall(game)
  local list = installsFor(game.key)
  if #list == 0 then
    local b = ask(title("Game not found"),
      "No copy of " .. game.name .. " was found.\n\nExtracted games are looked for in these folders on every drive:\n" ..
      table.concat(GameParents, ", ") .. "\n\nYou can also pick the game's folder yourself.",
      "Choose folder", "Cancel")
    if b ~= 1 then return nil end
    return nil, "browse"
  end
  if #list == 1 then return list[1] end
  local labels = {}
  for i, inst in ipairs(list) do labels[i] = describeInstall(inst) end
  local n = popup(title("Which copy of " .. game.name .. "?"), labels)
  return n and list[n] or nil
end

local function browseForFolder(prompt)
  local path = nil
  while true do
    local items, actions = {}, {}
    if path == nil then
      for _, d in ipairs(gameDrives()) do
        items[#items + 1] = d .. "\\"
        actions[#actions + 1] = { go = d }
      end
    else
      local exes = findExes(path)
      items[#items + 1] = "[ Use this folder ]" .. (#exes > 0 and ("  - " .. table.concat(exes, ", ")) or "  - no .xex here")
      actions[#actions + 1] = { pick = true }
      items[#items + 1] = "[ Up one level ]"
      actions[#actions + 1] = { up = true }
      for _, d in ipairs(listDirs(path)) do
        items[#items + 1] = d
        actions[#actions + 1] = { go = join(path, d) }
      end
    end
    local n = popup(prompt .. (path and ("  -  " .. path) or ""), items, "No drives found.")
    if not n then return nil end
    local a = actions[n]
    if a.pick then
      return path
    elseif a.up then
      path = parentOf(path)
    else
      path = a.go
    end
  end
end

local function addFolderFor(game)
  local path = browseForFolder("Folder for " .. game.name)
  if not path then return nil end
  if #findExes(path) == 0 then
    if ask(title("No .xex found"), "There's no .xex in:\n" .. path .. "\n\nAdd it anyway?", "Add", "Cancel") ~= 1 then
      return nil
    end
  end
  local list, known = loadManualFolders(), false
  for _, e in ipairs(list) do
    if e.path:lower() == path:lower() then e.key = game.key known = true end
  end
  if not known then list[#list + 1] = { key = game.key, path = path } end
  saveManualFolders(list)
  log("Added game folder for " .. game.key .. ": " .. path)
  scanGames(true)
  notify("Game folder added")
  for _, inst in ipairs(installsFor(game.key)) do
    if inst.path:lower() == path:lower() then return inst end
  end
  return nil
end

local function screenInstall()
  while true do
    local labels, games = {}, {}
    for _, g in ipairs(GAMES) do
      local menus = countPackages(g.key)
      local copies = #installsFor(g.key)
      labels[#labels + 1] = g.name .. "    " .. plural(menus, "menu") .. ", " ..
        (copies == 1 and "1 copy" or (copies .. " copies")) .. " found"
      games[#games + 1] = g
    end
    local gi = popup(title("Choose a game"), labels)
    if not gi then return end
    local game = games[gi]

    while true do
      local pkgs = loadPackages(game.key)
      local items = {}
      for i, p in ipairs(pkgs) do
        items[i] = p.name .. (p.version ~= "" and ("  v" .. p.version) or "") ..
          "    [" .. (p.kind == "plugin" and "Plugin" or "Files") .. (p.scope == "ALL" and ", all games" or "") .. "]" ..
          (p.problem and "  (menu.ini needs fixing)" or "")
      end
      local pi = popup(title(game.name .. " menus"), items,
        "No menus yet. Add them to Menus\\" .. game.key .. " beside this script.")
      if not pi then break end
      local pkg = pkgs[pi]

      if pkg.problem then
        info(title(pkg.name), pkg.problem .. "\n\n" .. join(pkg.dir, "menu.ini"))
      elseif ask(title(pkg.name), packageDetails(pkg, game), "Install", "Back") == 1 then
        if pkg.kind == "plugin" then
          installPlugin(pkg, game)
        else
          local inst, action = chooseInstall(game)
          if action == "browse" then inst = addFolderFor(game) end
          if inst then installFiles(pkg, inst) end
        end
      end
    end
  end
end

local function screenInstalled()
  while true do
    local recs = loadRecords()
    local labels = {}
    for i, r in ipairs(recs) do labels[i] = describeRecord(r) end
    local n = popup(title("Installed menus"), labels, "No menus are installed.")
    if not n then return end
    local r = recs[n]
    local game = gameByKey(r.game)
    local lines = {
      tostring(r.menu) .. ((r.version and r.version ~= "") and ("  v" .. r.version) or ""),
      "",
      "Game:       " .. (game and game.name or tostring(r.game)),
      "Installed:  " .. tostring(r.when or "--"),
    }
    if r.kind == "plugin" then
      lines[#lines + 1] = "Type:       Plugin menu in plugin" .. tostring(r.slot)
      lines[#lines + 1] = "launch.ini: " .. tostring(r.ini)
      lines[#lines + 1] = "Was before: " .. ((r.previous or "") ~= "" and r.previous or "(empty)")
    else
      local b = 0
      for _, f in ipairs(r.files) do if f.flag == "B" then b = b + 1 end end
      lines[#lines + 1] = "Type:       Game files"
      lines[#lines + 1] = "Folder:     " .. tostring(r.folder)
      lines[#lines + 1] = "Files:      " .. #r.files .. " (" .. b .. " originals backed up)"
    end
    if r.status ~= "ok" then
      lines[#lines + 1] = ""
      lines[#lines + 1] = "Status: " .. tostring(r.status) .. ". Remove it to put the originals back."
    end

    local buttons = { "Remove", "Back" }
    local canLaunch = r.kind == "files" and r.folder
    if canLaunch then buttons = { "Remove", "Launch game", "Back" } end
    local b = ask(title(tostring(r.menu)), table.concat(lines, "\n"), unpackArgs(buttons))
    if b == 1 then
      if ask(title("Remove " .. tostring(r.menu) .. "?"),
          (r.kind == "plugin" and "launch.ini will be set back to how it was." or "Every original file will be put back."),
          "Remove", "Cancel") == 1 then
        if r.kind == "plugin" then
          removePluginRecord(r, recs)
        elseif removeFilesRecord(r, recs) then
          notify(tostring(r.menu) .. " removed")
          info(title("Removed"), tostring(r.menu) .. " was removed and the original files are back.")
        end
      end
    elseif b == 2 and canLaunch then
      local inst = { game = game or GAMES[1], path = r.folder, format = "folder" }
      local pkgLaunch = parseIni(readText(join(r.package or "", "menu.ini"))).launch
      launchInstall(inst, pkgLaunch)
    end
  end
end

local function screenLibrary()
  while true do
    local list = scanGames()
    local labels, actions = { "[ Scan again ]", "[ Add a game folder ]" }, { "scan", "add" }
    for _, inst in ipairs(list) do
      labels[#labels + 1] = describeInstall(inst) .. (inst.source == "manual" and "  *" or "")
      actions[#actions + 1] = inst
    end
    local n = popup(title("Game library (" .. #list .. ")"), labels)
    if not n then return end
    local a = actions[n]
    if a == "scan" then
      scanGames(true)
      notify(plural(#installCache, "game") .. " found")
    elseif a == "add" then
      local names = {}
      for i, g in ipairs(GAMES) do names[i] = g.name end
      local gi = popup(title("Which game is it?"), names)
      if gi then addFolderFor(GAMES[gi]) end
    else
      local lines = {
        a.game.name .. "  (" .. a.game.tid .. ")",
        "",
        "Folder:  " .. a.path,
        "Format:  " .. (a.format == "god" and "Games on Demand (plugin menus only)" or "Extracted folder"),
        "Added:   " .. (a.source == "manual" and "By hand" or "Found automatically"),
      }
      if a.format ~= "god" then
        local exes = findExes(a.path)
        lines[#lines + 1] = "Files:   " .. (#exes > 0 and table.concat(exes, ", ") or "no .xex found")
      end
      local buttons = { "Launch game", "Back" }
      if a.source == "manual" then buttons = { "Launch game", "Remove from list", "Back" } end
      local b = ask(title(a.game.name), table.concat(lines, "\n"), unpackArgs(buttons))
      if b == 1 then
        launchInstall(a)
      elseif b == 2 and a.source == "manual" then
        local keep = {}
        for _, e in ipairs(loadManualFolders()) do
          if e.path:lower() ~= a.path:lower() then keep[#keep + 1] = e end
        end
        saveManualFolders(keep)
        scanGames(true)
      end
    end
  end
end

local function screenLaunch()
  local list = scanGames()
  local usable = {}
  for _, inst in ipairs(list) do
    if inst.format ~= "god" then usable[#usable + 1] = inst end
  end
  local labels = {}
  for i, inst in ipairs(usable) do labels[i] = describeInstall(inst) end
  local n = popup(title("Launch a game"), labels, "No extracted Call of Duty games were found.")
  if n then launchInstall(usable[n]) end
end

local HELP = {
  { "How it works",
    "Mod Menu Manager installs Call of Duty mod menus from a library beside the script.\n\n" ..
    "Pick a game, pick a menu, and it does the rest. Every file it replaces is backed up first, " ..
    "and Installed menus puts everything back with one press." },
  { "Adding menus",
    "Put each menu in its own folder:\n\nMenus\\<GAME>\\<Menu name>\\menu.ini\n\n" ..
    "GAME is one of: BO3 BO2 BO1 MW3 MW2 GHOSTS AW WAW COD4, or ALL for plugins that work in every game.\n\n" ..
    "File menus keep their files in a 'files' folder, laid out exactly as they go in the game folder. " ..
    "Plugin menus keep their .xex next to menu.ini.\n\nSee Menus\\_Templates for examples." },
  { "File menus vs plugin menus",
    "File menus (patch .ff files, GSC scripts) are copied into an extracted game folder. " ..
    "They don't work with Games on Demand installs.\n\n" ..
    "Plugin menus are .xex files loaded by DashLaunch at boot. They work with any install, " ..
    "but need a free plugin slot and a full power cycle." },
  { "Staying safe",
    "Use mod menus offline, in private matches or on system link.\n\n" ..
    "Keep liveblock enabled in launch.ini and stay off Xbox Live while running modified software." },
  { "Files and logs",
    "Script folder:\n" .. BASE .. "\n\nBackups:  Backups\nRecords:  installed.txt\nLog:      manager.log" },
}

local function screenHelp()
  while true do
    local labels = {}
    for i, h in ipairs(HELP) do labels[i] = h[1] end
    local n = popup(title("Help"), labels)
    if not n then return end
    info(title(HELP[n][1]), HELP[n][2])
  end
end

local function screenAbout()
  info(title("About"),
    "Mod Menu Manager  v" .. VERSION_TEXT .. "\nby Shmees\n\n" ..
    "Install and remove Call of Duty mod menus from the controller, with a backup of every change.\n\n" ..
    "Released under the MIT License.\ngithub.com/ShmeeMcgee  |  youtube.com/@Shmees14")
end

local function firstRunNotice()
  if getSetting("notice") == "1" then return true end
  local b = ask(title("Before you start"),
    "Mod menus are for offline play, private matches and system link.\n\n" ..
    "Keep liveblock enabled in launch.ini and stay off Xbox Live while running modified software.\n\n" ..
    "Every file this script changes is backed up and can be restored from Installed menus.",
    "I understand", "Exit")
  if b ~= 1 then return false end
  setSetting("notice", "1")
  return true
end


--==============================================================================
-- ENTRY POINT
--==============================================================================

function main()
  log("Opened Mod Menu Manager v" .. VERSION_TEXT .. " from " .. BASE)
  mkdirs(BACKUPS)
  for _, g in ipairs(GAMES) do
    if not dirExists(join(MENUS, g.key)) then mkdirs(join(MENUS, g.key)) end
  end
  if not dirExists(join(MENUS, "ALL")) then mkdirs(join(MENUS, "ALL")) end
  if not firstRunNotice() then return end

  -- Warn about anything left half-done by a crash or power loss.
  for _, r in ipairs(loadRecords()) do
    if r.status ~= "ok" then
      info(title("Unfinished install"),
        tostring(r.menu) .. " didn't finish installing last time.\n\nOpen Installed menus and remove it to put the original files back.")
      break
    end
  end

  while true do
    local games = scanGames()
    local recs = loadRecords()
    local items = {
      "Install a mod menu",
      "Installed menus  (" .. #recs .. ")",
      "Game library  (" .. plural(#games, "game") .. ")",
      "Launch a game",
      "Help",
      "About",
    }
    local n = popup("Mod Menu Manager  v" .. VERSION_TEXT .. "  |  by Shmees", items)
    if not n then break end
    if n == 1 then screenInstall()
    elseif n == 2 then screenInstalled()
    elseif n == 3 then screenLibrary()
    elseif n == 4 then screenLaunch()
    elseif n == 5 then screenHelp()
    elseif n == 6 then screenAbout()
    end
  end
  log("Closed")
end
