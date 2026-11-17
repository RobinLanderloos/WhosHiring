-- Announces guilds that match the saved alert filter: one clickable chat
-- line (and an optional sound) per guild. Clicking it opens the guild.
local addonName, ns = ...

local L = ns.L

local Alerts = {}
ns.Alerts = Alerts

-- Links carry a small number, not the guild id: ids contain "|", which
-- would end the link early.
local LINK_PREFIX = "addon:whoshiring:"
local linked = {}

local function settings()
  ns.db.alert = type(ns.db.alert) == "table" and ns.db.alert or {}
  if ns.db.alert.sound == nil then ns.db.alert.sound = true end
  return ns.db.alert
end

function Alerts.OnRecorded(entry)
  if not ns.Alert.check(ns.db, entry) then return end
  linked[#linked + 1] = entry.realm .. "|" .. entry.key
  local name = (entry.name or "?"):gsub("|", "||")
  local link = "|cff71d5ff|H" .. LINK_PREFIX .. #linked .. "|h[" .. name .. "]|h|r"
  print("|cff40c0ffWho's Hiring:|r " .. L.ALERT_LINE:format(link))
  if settings().sound and PlaySound then
    PlaySound(SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081)
  end
end

-- Called with the link text when any chat link is clicked.
function Alerts.OnLink(link)
  if type(link) ~= "string" or link:sub(1, #LINK_PREFIX) ~= LINK_PREFIX then return end
  local id = linked[tonumber(link:sub(#LINK_PREFIX + 1))]
  if id then ns.Window.ShowGuild(id) end
end

if SetItemRef and hooksecurefunc then
  hooksecurefunc("SetItemRef", function(link) Alerts.OnLink(link) end)
end

ns.OptionsExtras = ns.OptionsExtras or {}
table.insert(ns.OptionsExtras, {
  label = L.OPTION_ALERTS,
  help = L.OPTION_ALERTS_HELP,
  get = function() return ns.Alert.isEnabled(ns.db) end,
  set = function(on) ns.Alert.setEnabled(ns.db, on) end,
})
table.insert(ns.OptionsExtras, {
  label = L.OPTION_ALERT_SOUND,
  help = L.OPTION_ALERT_SOUND_HELP,
  get = function() return settings().sound end,
  set = function(on) settings().sound = on end,
})
