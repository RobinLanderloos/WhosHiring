-- Load check: runs every file the .toc lists, in order, against a small
-- stand-in for the game. Catches missing files, syntax errors and nil calls
-- before logging in; it does not prove the real client behaves the same.
--   luajit tests/smoke_test.lua
local ADDON = "WhosHiring"

local files = {}
for line in io.lines(ADDON .. ".toc") do
  line = line:gsub("%s+$", "")
  if line ~= "" and not line:match("^#") then files[#files + 1] = (line:gsub("\\", "/")) end
end

-- Widgets: remember scripts, events, text, attributes, size, anchor and
-- shown state; Create* calls give child widgets. Like real frames, unknown
-- methods (capitalised) do nothing and unset fields are nil.
local widgets = {}
local function newWidget(parent)
  local w = { shown = true, scripts = {}, events = {}, parentWidget = parent }
  widgets[#widgets + 1] = w
  return setmetatable(w, { __index = function(self, key)
    if key == "Text" or key == "TitleText" then
      local child = newWidget(self); rawset(self, key, child); return child
    end
    if key == "SetScript" then return function(s, name, fn) s.scripts[name] = fn end end
    if key == "RegisterEvent" or key == "RegisterUnitEvent" then return function(s, name) s.events[name] = true end end
    if key == "UnregisterEvent" then return function(s, name) s.events[name] = nil end end
    if key == "SetText" then return function(s, text) rawset(s, "text", text) end end
    if key == "GetText" then return function(s) return rawget(s, "text") end end
    if key == "SetAttribute" then
      return function(s, name, v) rawset(s, "attrs", rawget(s, "attrs") or {}); s.attrs[name] = v end
    end
    if key == "IsShown" then return function(s) return s.shown end end
    if key == "Show" then return function(s) s.shown = true; if s.scripts.OnShow then s.scripts.OnShow(s) end end end
    if key == "Hide" then return function(s) s.shown = false end end
    if key == "SetShown" then return function(s, v) if v then s:Show() else s:Hide() end end end
    if key == "SetSize" then return function(s, w2, h) rawset(s, "width", w2); rawset(s, "height", h) end end
    if key == "GetWidth" then return function(s) return rawget(s, "width") or 0 end end
    if key == "GetHeight" then return function(s) return rawget(s, "height") or 0 end end
    if key == "SetPoint" then
      return function(s, ...) if not rawget(s, "point") then rawset(s, "point", { ... }) end end
    end
    if key == "ClearAllPoints" then return function(s) rawset(s, "point", nil) end end
    if type(key) == "string" and key:match("^Create") then
      return function(s, name) local c = newWidget(s); if type(name) == "string" then rawset(c, "name", name) end; return c end
    end
    if type(key) == "string" and key:match("^%u") then return function() end end
    return nil
  end })
end

local function fire(event, ...)
  for _, w in ipairs(widgets) do
    if w.events[event] and w.scripts.OnEvent then w.scripts.OnEvent(w, event, ...) end
  end
end

-- Shown only when it and every parent are shown, as in the game.
local function visible(w)
  while w do
    if not rawget(w, "shown") then return false end
    w = rawget(w, "parentWidget")
  end
  return true
end

local function shownTexts()
  local texts = {}
  for _, w in ipairs(widgets) do
    local text = rawget(w, "text")
    if visible(w) and type(text) == "string" then texts[#texts + 1] = text end
  end
  return table.concat(texts, "\n")
end

local function find(predicate)
  for _, w in ipairs(widgets) do if predicate(w) then return w end end
end

-- Timers wait until the test runs them, as the game would on later frames.
local timers = {}
local function runTimers()
  local guard = 0
  while #timers > 0 and guard < 100000 do
    table.remove(timers, 1)()
    guard = guard + 1
  end
end

-- The game globals the addon touches. Add what your files need.
_G.CreateFrame = function(_, name, parent)
  local w = newWidget(parent)
  rawset(w, "name", name)
  return w
end
_G.UIParent = newWidget()
_G.GameTooltip = newWidget()
_G.UISpecialFrames = {}
_G.tinsert = table.insert
_G.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
_G.InCombatLockdown = function() return false end
_G.SlashCmdList = {}
_G.GetBuildInfo = function() return "1.60.1", "70938", "Nov 1 2026", 16001 end
_G.time = function() return 1763100000 end
_G.Settings = {
  RegisterCanvasLayoutCategory = function() return newWidget() end,
  RegisterAddOnCategory = function() end,
  OpenToCategory = function() end,
}
_G[ADDON .. "DB"] = nil -- a fresh install
_G.UnitName = function() return "Me" end
_G.GetNormalizedRealmName = function() return "Realm" end
_G.GetGuildInfo = function() return "My Guild" end
_G.date = os.date
local clock = 1763100000
_G.time = function() return clock end

-- Load the addon like the client does.
local ns = {}
for _, file in ipairs(files) do
  local chunk, err = loadfile(file)
  if not chunk then error("the .toc lists a file that does not load: " .. tostring(err)) end
  chunk(ADDON, ns)
end
fire("ADDON_LOADED", ADDON)
fire("PLAYER_LOGIN")

local failed = 0
local function check(name, condition, detail)
  if not condition then
    failed = failed + 1
    print("FAIL  " .. name .. (detail and ("\n      " .. tostring(detail)) or ""))
  end
end

-- Capture chat output of slash commands.
local said = {}
local realPrint = print
local function slash(command, message)
  said = {}
  _G.print = function(text) said[#said + 1] = tostring(text) end
  local ok, err = pcall(SlashCmdList[command], message)
  _G.print = realPrint
  return ok, ok and table.concat(said, "\n") or tostring(err)
end

local function chat(event, text, sender, channelName, baseName)
  fire(event, text, sender, "Common", channelName or "", "", "", 0, 2, baseName or "")
end

check("saved list is set up on load", type(WhosHiringDB) == "table" and type(WhosHiringDB.guilds) == "table")

local ok, err = slash("WHOSHIRING", "")
check("/wh opens the window", ok, err)
check("an empty list explains itself", shownTexts():find("No recruiting guilds seen yet", 1, true) ~= nil, shownTexts())

chat("CHAT_MSG_CHANNEL", "<Night Watch> is recruiting tanks for MC", "Bob-Realm", "2. Trade - City", "Trade - City")
chat("CHAT_MSG_CHANNEL", "WTS Linen Cloth", "Sam-Realm", "2. Trade - City", "Trade - City")
chat("CHAT_MSG_SAY", "Iron Oath is recruiting all classes", "Kim")
chat("CHAT_MSG_YELL", "<My Guild> recruiting", "Lee")
chat("CHAT_MSG_WHISPER", "<Ashen Order> recruiting, want an invite?", "Max-Other")
chat("CHAT_MSG_SAY", "<Mine> recruiting", "Me")

local texts = shownTexts()
check("a channel recruit shows in the open window", texts:find("Night Watch", 1, true) ~= nil, texts)
check("a Say recruit from a same-realm sender shows", texts:find("Iron Oath", 1, true) ~= nil, texts)
check("a whisper recruit shows", texts:find("Ashen Order", 1, true) ~= nil, texts)
check("trade chat is not shown", texts:find("Linen", 1, true) == nil, texts)
check("the player's own guild is skipped", texts:find("My Guild", 1, true) == nil, texts)
check("the player's own messages are skipped", texts:find("Mine", 1, true) == nil, texts)
check("the empty text is hidden once guilds exist", texts:find("No recruiting guilds", 1, true) == nil, texts)
check("rows show posters and age", texts:find("1 poster", 1, true) ~= nil, texts)
check("the channel name is stored without its number",
  WhosHiringDB.guilds["Realm|night watch"] and WhosHiringDB.guilds["Realm|night watch"].messages[1].channel == "Trade - City")
check("a same-realm sender gets the realm added",
  WhosHiringDB.guilds["Realm|iron oath"] and WhosHiringDB.guilds["Realm|iron oath"].messages[1].sender == "Kim-Realm")
check("a cross-realm guild is keyed on the sender's realm", WhosHiringDB.guilds["Other|ashen order"] ~= nil)

chat("CHAT_MSG_CHANNEL", "We are recruiting! chill levelling guild, /w me", "Zed-Realm", "2. Trade - City", "Trade - City")
check("an unnamed recruit shows as an unknown guild", shownTexts():find("Unknown guild, posted by Zed", 1, true) ~= nil, shownTexts())
chat("CHAT_MSG_CHANNEL", "<Dawn Guard> is recruiting", "Zed-Realm", "2. Trade - City", "Trade - City")
check("the unknown guild merges once named", shownTexts():find("Unknown guild, posted by Zed", 1, true) == nil
  and shownTexts():find("Dawn Guard", 1, true) ~= nil, shownTexts())

clock = clock + 3 * 3600
slash("WHOSHIRING", "")
slash("WHOSHIRING", "")
check("ages update when reopened", shownTexts():find("seen 3h ago", 1, true) ~= nil, shownTexts())

chat("CHAT_MSG_CHANNEL", nil, "Bob-Realm")
check("a nil message does not break anything", WhosHiringDB.lastError == nil, WhosHiringDB.lastError)

io.write(failed == 0 and "load check passed\n" or (failed .. " load checks failed\n"))
os.exit(failed == 0 and 0 or 1)
