-- /wh and /whoshiring.
local addonName, ns = ...

local L, Report = ns.L, ns.Report

SLASH_WHOSHIRING1 = "/wh"
SLASH_WHOSHIRING2 = "/whoshiring"

local function say(text)
  print("|cff40c0ffWho's Hiring:|r " .. text)
end

local function count(t)
  local n = 0
  for _ in pairs(t or {}) do n = n + 1 end
  return n
end

-- Facts for checking the addon in the live client; stored in the saved
-- variables so they can be read after /reload.
local function report()
  local db = ns.db
  Report.Start()
  Report.Say(("guilds %d, dismissed %d, dismissed posters %d, new %d"):format(
    count(db.guilds), count(db.dismissed), count(db.dismissedPosters), ns.Store.newCount(db)))
  Report.Say("realm: " .. tostring(GetNormalizedRealmName and GetNormalizedRealmName()))
  Report.Say("own guild: " .. tostring(GetGuildInfo and GetGuildInfo("player")))
  local owner = hash_SlashCmdList and hash_SlashCmdList["/WH"]
  Report.Say("/wh is ours: " .. tostring(owner == nil or owner == SlashCmdList.WHOSHIRING))
  Report.Say(("whisper: ChatFrame_SendTell %s, ChatFrameUtil.SendTell %s, ChatFrame_OpenChat %s"):format(
    tostring(ChatFrame_SendTell ~= nil), tostring(ChatFrameUtil ~= nil and ChatFrameUtil.SendTell ~= nil),
    tostring(ChatFrame_OpenChat ~= nil)))
  Report.Say("issecretvalue exists: " .. tostring(issecretvalue ~= nil))
  Report.Say("debug mode: " .. tostring(db.settings.debug == true))
  local log = db.debugLog
  if log then
    local names = {}
    for name, n in pairs(log.channels or {}) do names[#names + 1] = name .. "=" .. n end
    table.sort(names)
    Report.Say("channels seen: " .. table.concat(names, ", "))
    Report.Say("near misses logged: " .. #(log.nearMisses or {}))
  end
  if db.lastError then Report.Say("last error: " .. db.lastError) end
  Report.Finish(db)
  say(L.REPORT_DONE)
end

SlashCmdList.WHOSHIRING = function(message)
  local command = (message or ""):match("^%s*(%S*)"):lower()
  if command == "config" or command == "options" then
    ns.OpenOptions()
  elseif command == "debug" then
    ns.db.settings.debug = not ns.db.settings.debug or nil
    say(ns.db.settings.debug and L.DEBUG_ON or L.DEBUG_OFF)
  elseif command == "report" then
    report()
  elseif command == "help" then
    say(L.HELP)
  else
    ns.Window.Toggle()
  end
end
