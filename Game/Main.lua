-- Loads the saved list and feeds chat messages into it.
local addonName, ns = ...

local Game = {}
ns.Game = Game

-- Chat events listened to (ADR 0002) and the channel label for each.
local CHAT_EVENTS = {
  CHAT_MSG_CHANNEL = false, -- named from the event's channel arguments
  CHAT_MSG_SAY = "Say",
  CHAT_MSG_YELL = "Yell",
  CHAT_MSG_WHISPER = "Whisper",
}

local function playerRealm()
  return (GetNormalizedRealmName and GetNormalizedRealmName()) or ""
end

-- "Name-Realm" for every sender, so the same player is always one poster.
function Game.FullName(sender)
  if sender:find("-", 1, true) then return sender end
  return sender .. "-" .. playerRealm()
end

function Game.RealmOf(fullName)
  return fullName:match("%-(.+)$") or playerRealm()
end

local function myName()
  local name = UnitName("player")
  return name and Game.FullName(name)
end

local function channelLabel(event, channelName, channelBaseName)
  local label = CHAT_EVENTS[event]
  if label then return label end
  if type(channelBaseName) == "string" and channelBaseName ~= "" then return channelBaseName end
  if type(channelName) == "string" then return (channelName:gsub("^%d+%.%s*", "")) end
  return "Channel"
end

local function secret(v)
  return issecretvalue and issecretvalue(v)
end

function Game.OnChat(event, text, sender, _, channelName, _, _, _, _, channelBaseName)
  if not ns.db then return end
  if type(text) ~= "string" or type(sender) ~= "string" or secret(text) or secret(sender) then return end
  if sender == "" then return end
  local full = Game.FullName(sender)
  if full == myName() then return end

  local status, entry, verdict = ns.Store.record(ns.db, {
    text = text,
    sender = full,
    channel = channelLabel(event, channelName, channelBaseName),
    time = time(),
    realm = Game.RealmOf(full),
    ownGuild = GetGuildInfo and GetGuildInfo("player") or nil,
  })
  if ns.OnRecorded then ns.OnRecorded(status, entry, verdict, text, full) end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
  if event == "ADDON_LOADED" then
    if ... ~= addonName then return end
    WhosHiringDB = ns.Store.init(WhosHiringDB)
    ns.db = WhosHiringDB
    ns.Store.prune(ns.db, time()) -- ADR 0004
    for chatEvent in pairs(CHAT_EVENTS) do self:RegisterEvent(chatEvent) end
    self:UnregisterEvent("ADDON_LOADED")
    return
  end
  -- A rule error must never break chat for the player.
  local ok, err = pcall(Game.OnChat, event, ...)
  if not ok and ns.db then ns.db.lastError = tostring(err) end
end)

-- Called after every recorded message; the window and later features hook in.
function ns.OnRecorded(status, entry)
  if status == "ignored" or status == "dismissed" then return end
  if ns.Window then ns.Window.OnRecorded(status, entry) end
  if ns.MinimapButton then ns.MinimapButton.UpdateCount() end
end
