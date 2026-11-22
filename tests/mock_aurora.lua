-- Mock of the Aurora Lua API for testing Mod Menu Manager off-console.
-- Drives are folders under ROOT: "Hdd1:\Games" -> ROOT/Hdd1/Games.
-- Paths are resolved case-insensitively, like FATX.

local lfs = require("lfs")
local M = { answers = {}, transcript = {}, http = {}, notes = {}, failCopy = nil }
local ROOT

local function isdir(p) return lfs.attributes(p, "mode") == "directory" end
local function isfile(p) return lfs.attributes(p, "mode") == "file" end

-- resolve an Aurora path to a real path, matching each component case-insensitively
local function real(p)
  p = tostring(p):gsub("\\%*$", "")
  local mount, rest = p:match("^([^:\\]+):\\?(.*)$")
  assert(mount, "bad path " .. p)
  local cur = ROOT .. "/" .. mount
  for part in rest:gmatch("[^\\]+") do
    local found = nil
    if isdir(cur) then
      for e in lfs.dir(cur) do
        if e:lower() == part:lower() then found = e break end
      end
    end
    cur = cur .. "/" .. (found or part)
  end
  return cur
end
M.real = real

local function list(dirPattern, want)
  local d = real(dirPattern)
  local out = {}
  if not isdir(d) then return out end
  for e in lfs.dir(d) do
    if e ~= "." and e ~= ".." then
      local mode = lfs.attributes(d .. "/" .. e, "mode")
      if (want == "file" and mode == "file") or (want == "directory" and mode == "directory") then
        out[#out + 1] = { Name = e }
      end
    end
  end
  return out
end

local function readAll(p)
  local f = io.open(p, "rb"); if not f then return nil end
  local s = f:read("a"); f:close(); return s
end

local function say(s) M.transcript[#M.transcript + 1] = s; if M.verbose then print(s) end end

local function nextAnswer(kind, title)
  local a = table.remove(M.answers, 1)
  if a == "<back>" then a = nil end
  if a == nil then say("  (" .. kind .. " '" .. title .. "' -> back/cancel)") end
  return a
end

function M.install(root)
  ROOT = root
  FileSystem = {
    GetDrives = function()
      local out = {}
      for e in lfs.dir(ROOT) do
        if e ~= "." and e ~= ".." and isdir(ROOT .. "/" .. e) then out[#out + 1] = { MountPoint = e .. ":\\" } end
      end
      return out
    end,
    GetFiles = function(p) return list(p, "file") end,
    GetDirectories = function(p) return list(p, "directory") end,
    FileExists = function(p) return isfile(real(p)) end,
    GetFileSize = function(p) return lfs.attributes(real(p), "size") or 0 end,
    ReadFile = function(p) return readAll(real(p)) end,
    WriteFile = function(p, s)
      local f = io.open(real(p), "wb"); if not f then return false end
      f:write(s); f:close(); return true
    end,
    CreateDirectory = function(p)
      local r = real(p)
      if not isdir(r:match("^(.*)/[^/]+$")) then return false end
      return lfs.mkdir(r) == true
    end,
    CopyFile = function(src, dst, overwrite)
      if M.failCopy and tostring(dst):lower():find(M.failCopy:lower(), 1, true) then return false end
      local rs, rd = real(src), real(dst)
      if not isfile(rs) then return false end
      if not isdir(rd:match("^(.*)/[^/]+$")) then return false end   -- like Win32 CopyFile
      if isfile(rd) and not overwrite then return false end
      local data = readAll(rs)
      local f = io.open(rd, "wb"); f:write(data); f:close(); return true
    end,
    DeleteFile = function(p) return os.remove(real(p)) ~= nil end,
    DeleteDirectory = function(p) return lfs.rmdir(real(p)) == true end,   -- empty only
  }
  Script = {
    GetBasePath = function() return M.base end,
    ShowPopupList = function(title, emptyText, items)
      say("[LIST] " .. title .. (#items == 0 and ("  <" .. emptyText .. ">") or ""))
      for i, v in ipairs(items) do say("    " .. i .. ". " .. v) end
      local a = nextAnswer("list", title)
      if a == nil then return { Canceled = true } end
      local idx = a
      if type(a) == "string" then
        idx = nil
        for i, v in ipairs(items) do if v:find(a, 1, true) then idx = i break end end
        assert(idx, "answer '" .. a .. "' not found in list '" .. title .. "'")
      end
      say("    -> " .. idx .. ". " .. tostring(items[idx]))
      return { Canceled = false, Selected = { Key = idx, Value = items[idx] } }
    end,
    ShowMessageBox = function(title, text, ...)
      local buttons = { ... }
      say("[MSG] " .. title)
      for line in (text .. "\n"):gmatch("([^\n]*)\n") do say("    | " .. line) end
      say("    [" .. table.concat(buttons, "] [") .. "]")
      local a = nextAnswer("msg", title)
      if a == nil then return { Canceled = true } end
      local idx = a
      if type(a) == "string" then
        idx = nil
        for i, v in ipairs(buttons) do if v == a then idx = i end end
        assert(idx, "button '" .. a .. "' not on '" .. title .. "' (has: " .. table.concat(buttons, ", ") .. ")")
      end
      say("    -> " .. buttons[idx])
      return { Canceled = false, Button = idx }
    end,
    ShowNotification = function(m) M.notes[#M.notes + 1] = m; say("[NOTE] " .. m) end,
    SetStatus = function() end,
    SetProgress = function() end,
    IsCanceled = function() return false end,
  }
  Aurora = {
    GetDate = function() return { Year = 2026, Month = 11, Day = 21 } end,
    GetTime = function() return { Hour = 2, Minute = 14, Second = 0 } end,
    GetIPAddress = function() return "192.168.1.50" end,
  }
  -- M.web[url] = { file = "/real/path" } or { text = "..." }. Anything else fails, like an offline console.
  Http = { Get = function(url, rel)
    M.http[#M.http + 1] = url
    if url:find(":730/", 1, true) then return { Success = true, OutputData = "200- OK" } end
    local w = M.web and M.web[url]
    if not w then return { Success = false } end
    local data = w.text or readAll(w.file)
    if rel then
      local dst = real(M.base .. rel)
      local f = io.open(dst, "wb"); if not f then return { Success = false } end
      f:write(data); f:close()
      return { Success = true, OutputPath = M.base .. rel }
    end
    return { Success = true, OutputData = data }
  end }
  ZipFile = { OpenFile = function(rel)
    local zp = real(M.base .. rel)
    if not isfile(zp) then return nil end
    return { Extract = function(self, destRel)
      local d = real(M.base .. destRel)
      os.execute("mkdir -p '" .. d .. "'")
      local r = os.execute("unzip -o -q '" .. zp .. "' -d '" .. d .. "'")
      return r == true or r == 0
    end }
  end }
  Thread = { Sleep = function() end }
end

function M.run(mainPath, answers)
  M.answers = answers or {}
  M.transcript = {}
  M.http = {}
  M.notes = {}
  main = nil
  dofile(mainPath)
  main()
  if #M.answers > 0 then
    error("unused answers left: " .. #M.answers .. " (next: " .. tostring(M.answers[1]) .. ")")
  end
  return M.transcript
end

M.readAll = readAll
return M
