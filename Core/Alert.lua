-- The saved-filter alert: one chat line per guild that matches the filter
-- the player saved. Pure: works on the saved table.
local addonName, ns = ...

local Alert = {}
ns.Alert = Alert

local function settings(db)
  db.alert = type(db.alert) == "table" and db.alert or {}
  if db.alert.enabled == nil then db.alert.enabled = true end
  db.alert.chips = db.alert.chips or {}
  return db.alert
end

-- Saves a copy of the chips as the alert filter. Guilds that already match
-- are treated as known, so saving does not set off a burst of alerts.
function Alert.save(db, chips, now)
  local a = settings(db)
  a.chips = {}
  for id, on in pairs(chips or {}) do
    if on then a.chips[id] = true end
  end
  a.savedAt = now
  if next(a.chips) then
    for _, entry in pairs(db.guilds) do
      if ns.Query.matches(entry, a.chips) then entry.alertedFor = now end
    end
  end
end

function Alert.setEnabled(db, on)
  settings(db).enabled = on and true or false
end

function Alert.isEnabled(db)
  return settings(db).enabled
end

function Alert.hasFilter(db)
  return next(settings(db).chips) ~= nil
end

-- Call after recording a message into `entry`. True once per guild per saved
-- filter, as soon as the guild matches it.
function Alert.check(db, entry)
  local a = settings(db)
  if not entry or not a.enabled or not a.savedAt or next(a.chips) == nil then return false end
  if entry.alertedFor == a.savedAt then return false end
  if not ns.Query.matches(entry, a.chips) then return false end
  entry.alertedFor = a.savedAt
  return true
end
