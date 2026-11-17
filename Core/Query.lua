-- Turns the saved guilds into the rows the window shows: filtering, search
-- and sorting. Pure.
local addonName, ns = ...

local Query = {}
ns.Query = Query

local function tagList(entry)
  local list = {}
  for _, def in ipairs(ns.Tags.definitions) do
    local w = entry.tags and entry.tags[def.id]
    if w then list[#list + 1] = { id = def.id, group = def.group, label = def.label, word = w } end
  end
  return list
end

local function row(db, entry, staleBefore)
  local latest = ns.Store.latest(entry)
  return {
    id = entry.realm .. "|" .. entry.key,
    entry = entry,
    name = entry.name,
    message = latest and latest.text or "",
    unknownPoster = entry.unknownPoster,
    tags = tagList(entry),
    sortName = (entry.name or entry.unknownPoster or ""):lower(),
    posters = ns.Store.posterCount(entry),
    lastSeen = entry.lastSeen,
    starred = entry.starred,
    stale = staleBefore and (entry.lastSeen or 0) < staleBefore or nil,
    dismissedPosterHint = ns.Store.hasDismissedPoster(db, entry) or nil,
  }
end

-- A row for the Dismissed tab, from the small dismissed record.
local function dismissedRow(eid, record)
  return {
    id = eid,
    name = record.name,
    message = record.message and record.message.text or "",
    unknownPoster = record.unknownPoster,
    tags = tagList(record),
    sortName = (record.name or record.unknownPoster or ""):lower(),
    posters = record.message and 1 or 0,
    lastSeen = record.message and record.message.last or record.time,
    dismissed = true,
    dismissedAt = record.time,
  }
end

local function byStarThenNewest(a, b)
  if (a.starred or false) ~= (b.starred or false) then return a.starred == true end
  if a.lastSeen ~= b.lastSeen then return a.lastSeen > b.lastSeen end
  return a.sortName < b.sortName
end

local function byDismissal(a, b)
  if a.dismissedAt ~= b.dismissedAt then return a.dismissedAt > b.dismissedAt end
  return a.sortName < b.sortName
end

-- options = { now, tab = "all" | "starred" | "dismissed" }
function Query.list(db, options)
  options = options or {}
  local tab = options.tab or "all"
  local staleDays = options.staleDays or (db.settings and db.settings.staleDays)
  local staleBefore = options.now and staleDays and options.now - staleDays * 86400
  local rows = {}
  if tab == "dismissed" then
    for eid, record in pairs(db.dismissed) do rows[#rows + 1] = dismissedRow(eid, record) end
    table.sort(rows, byDismissal)
    return rows
  end
  for _, entry in pairs(db.guilds) do
    if tab ~= "starred" or entry.starred then rows[#rows + 1] = row(db, entry, staleBefore) end
  end
  table.sort(rows, byStarThenNewest)
  return rows
end

-- "now", "12m", "2h", "3d": how long ago something was seen.
function Query.age(seconds)
  if seconds < 60 then return "now" end
  if seconds < 3600 then return math.floor(seconds / 60) .. "m" end
  if seconds < 86400 then return math.floor(seconds / 3600) .. "h" end
  return math.floor(seconds / 86400) .. "d"
end
