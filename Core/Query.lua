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

-- Name and every message, lowercased, for the search box.
local function searchText(name, messages)
  local parts = { name or "" }
  for _, m in ipairs(messages) do parts[#parts + 1] = ns.Text.normalize(m.text) end
  return table.concat(parts, " | "):lower()
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
    searchText = searchText(entry.name, entry.messages),
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
    searchText = searchText(record.name, { record.message }),
    posters = record.message and 1 or 0,
    lastSeen = record.message and record.message.last or record.time,
    dismissed = true,
    dismissedAt = record.time,
  }
end

-- Chips: OR within a tag group, AND across groups.
local function matchesChips(r, chips)
  if not chips or next(chips) == nil then return true end
  local wanted, hit = {}, {}
  for id in pairs(chips) do
    local def = ns.Tags.byId[id]
    if def then wanted[def.group] = true end
  end
  for _, t in ipairs(r.tags) do
    if chips[t.id] then hit[t.group] = true end
  end
  for group in pairs(wanted) do
    if not hit[group] then return false end
  end
  return true
end

local function matchesSearch(r, search)
  if not search then return true end
  return r.searchText:find(search, 1, true) ~= nil
end

local orders = {
  seen = function(a, b)
    if a.lastSeen ~= b.lastSeen then return a.lastSeen > b.lastSeen end
    return a.sortName < b.sortName
  end,
  name = function(a, b)
    if a.sortName ~= b.sortName then return a.sortName < b.sortName end
    return a.lastSeen > b.lastSeen
  end,
  posters = function(a, b)
    if a.posters ~= b.posters then return a.posters > b.posters end
    if a.lastSeen ~= b.lastSeen then return a.lastSeen > b.lastSeen end
    return a.sortName < b.sortName
  end,
}

-- Starred first, then the chosen order.
local function starredFirst(order)
  return function(a, b)
    if (a.starred or false) ~= (b.starred or false) then return a.starred == true end
    return order(a, b)
  end
end

local function byDismissal(a, b)
  if a.dismissedAt ~= b.dismissedAt then return a.dismissedAt > b.dismissedAt end
  return a.sortName < b.sortName
end

-- options = { now, tab = "all" | "starred" | "dismissed", chips = { [tagId] = true },
--             search = text, sort = "seen" | "name" | "posters", staleDays }
function Query.list(db, options)
  options = options or {}
  local tab = options.tab or "all"
  local search = options.search and options.search:lower():gsub("^%s+", ""):gsub("%s+$", "")
  if search == "" then search = nil end
  local function keep(r) return matchesChips(r, options.chips) and matchesSearch(r, search) end
  local staleDays = options.staleDays or (db.settings and db.settings.staleDays)
  local staleBefore = options.now and staleDays and options.now - staleDays * 86400
  local rows = {}
  if tab == "dismissed" then
    for eid, record in pairs(db.dismissed) do
      local r = dismissedRow(eid, record)
      if keep(r) then rows[#rows + 1] = r end
    end
    table.sort(rows, byDismissal)
    return rows
  end
  for _, entry in pairs(db.guilds) do
    if tab ~= "starred" or entry.starred then
      local r = row(db, entry, staleBefore)
      if keep(r) then rows[#rows + 1] = r end
    end
  end
  table.sort(rows, starredFirst(orders[options.sort] or orders.seen))
  return rows
end

-- "now", "12m", "2h", "3d": how long ago something was seen.
function Query.age(seconds)
  if seconds < 60 then return "now" end
  if seconds < 3600 then return math.floor(seconds / 60) .. "m" end
  if seconds < 86400 then return math.floor(seconds / 3600) .. "h" end
  return math.floor(seconds / 86400) .. "d"
end

-- True when an entry's tags satisfy the chips (OR within a group, AND across).
function Query.matches(entry, chips)
  return matchesChips({ tags = tagList(entry) }, chips)
end
