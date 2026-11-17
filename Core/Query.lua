-- Turns the saved guilds into the rows the window shows: filtering, search
-- and sorting. Pure.
local addonName, ns = ...

local Query = {}
ns.Query = Query

local function row(entry)
  local latest = ns.Store.latest(entry)
  return {
    id = entry.realm .. "|" .. entry.key,
    entry = entry,
    name = entry.name,
    message = latest and latest.text or "",
    unknownPoster = entry.unknownPoster,
    sortName = (entry.name or entry.unknownPoster or ""):lower(),
    posters = ns.Store.posterCount(entry),
    lastSeen = entry.lastSeen,
  }
end

-- options = { now }
function Query.list(db, options)
  local rows = {}
  for _, entry in pairs(db.guilds) do
    rows[#rows + 1] = row(entry)
  end
  table.sort(rows, function(a, b)
    if a.lastSeen ~= b.lastSeen then return a.lastSeen > b.lastSeen end
    return a.sortName < b.sortName
  end)
  return rows
end

-- "now", "12m", "2h", "3d": how long ago something was seen.
function Query.age(seconds)
  if seconds < 60 then return "now" end
  if seconds < 3600 then return math.floor(seconds / 60) .. "m" end
  if seconds < 86400 then return math.floor(seconds / 3600) .. "h" end
  return math.floor(seconds / 86400) .. "d"
end
