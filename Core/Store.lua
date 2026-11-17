-- The saved guild list: recording messages into guild entries.
-- Pure: works on a plain table (the SavedVariables) and plain values.
local addonName, ns = ...

local Store = {}
ns.Store = Store

local function id(realm, key) return realm .. "|" .. key end

-- Raise when Detect or Tags rules change, so saved entries are re-checked.
Store.RULES_VERSION = 3

-- An unknown entry whose messages now show a guild name moves into that
-- guild (created if needed). Returns true when it moved.
local function nameUnknown(db, eid, entry)
  local name
  for _, m in ipairs(entry.messages) do
    name = name or ns.GuildName.parse(m.text)
  end
  if not name then return false end
  local key = ns.GuildName.normalize(name)
  local targetId = entry.realm .. "|" .. key
  if db.dismissed[targetId] then
    db.guilds[eid] = nil
    return true
  end
  local target = db.guilds[targetId]
  if not target then
    target = { key = key, realm = entry.realm, name = name, firstSeen = entry.firstSeen,
      lastSeen = entry.lastSeen, messages = {} }
    db.guilds[targetId] = target
  end
  for _, m in ipairs(entry.messages) do target.messages[#target.messages + 1] = m end
  target.firstSeen = math.min(target.firstSeen or entry.firstSeen, entry.firstSeen or target.firstSeen)
  target.lastSeen = math.max(target.lastSeen or entry.lastSeen, entry.lastSeen or target.lastSeen)
  db.posters[entry.unknownPoster] = key
  db.guilds[eid] = nil
  Store.retag(target)
  return true
end

-- Re-applies the current rules to every saved entry: messages that no longer
-- count as recruitment are dropped (and entries left empty), unknown entries
-- whose guild name can now be read move into it, tags are recomputed.
function Store.recheck(db)
  local ids = {}
  for eid in pairs(db.guilds) do ids[#ids + 1] = eid end
  for _, eid in ipairs(ids) do
    local entry = db.guilds[eid]
    local kept = {}
    for _, m in ipairs(entry.messages or {}) do
      if ns.Detect.classify(m.text).isRecruit then kept[#kept + 1] = m end
    end
    entry.messages = kept
    if #kept == 0 then
      db.guilds[eid] = nil
    elseif not (entry.unknownPoster and nameUnknown(db, eid, entry)) then
      Store.retag(entry)
    end
  end
end

-- Retention limits (ADR 0004); all of them are settings.
Store.defaults = { staleDays = 14, pruneDays = 60, maxMessages = 20 }

-- Fills in a missing or partial saved table and returns it.
function Store.init(db)
  db = type(db) == "table" and db or {}
  db.version = db.version or 1
  db.guilds = db.guilds or {}
  db.posters = db.posters or {} -- sender -> guild key, once a sender named a guild
  db.dismissed = db.dismissed or {} -- id -> small record (ADR 0003)
  db.dismissedPosters = db.dismissedPosters or {} -- sender -> time
  db.settings = type(db.settings) == "table" and db.settings or {}
  for k, v in pairs(Store.defaults) do
    if db.settings[k] == nil then db.settings[k] = v end
  end
  if db.rulesVersion ~= Store.RULES_VERSION then
    Store.recheck(db)
    db.rulesVersion = Store.RULES_VERSION
  end
  return db
end

-- Entries without a guild name are keyed on their poster.
function Store.unknownKey(sender)
  return "?" .. sender:lower()
end

function Store.get(db, realm, key)
  return db.guilds[id(realm, key)]
end

-- The poster named their guild: their unknown entry folds into it (ADR 0001).
local function mergeUnknown(db, entry, sender)
  local unknownId = id(entry.realm, Store.unknownKey(sender))
  local unknown = db.guilds[unknownId]
  if not unknown or unknown == entry then return end
  for _, m in ipairs(unknown.messages) do entry.messages[#entry.messages + 1] = m end
  table.sort(entry.messages, function(a, b) return a.first < b.first end)
  entry.firstSeen = math.min(entry.firstSeen, unknown.firstSeen)
  db.guilds[unknownId] = nil
end

-- Drops the oldest messages beyond the cap.
local function cap(entry, max)
  if #entry.messages <= max then return end
  table.sort(entry.messages, function(a, b) return a.last > b.last end)
  for i = #entry.messages, max + 1, -1 do table.remove(entry.messages, i) end
  table.sort(entry.messages, function(a, b) return a.first < b.first end)
end

-- A repeat of the same text by the same poster only counts (spam macros).
local function addMessage(entry, message)
  local same = ns.Text.normalize(message.text)
  for _, m in ipairs(entry.messages) do
    if m.sender == message.sender and ns.Text.normalize(m.text) == same then
      m.count = m.count + 1
      m.last = math.max(m.last, message.time)
      m.text = message.text
      m.channel = message.channel
      return m
    end
  end
  local m = {
    sender = message.sender, text = message.text, channel = message.channel,
    first = message.time, last = message.time, count = 1,
  }
  entry.messages[#entry.messages + 1] = m
  return m
end

-- message = { text, sender, channel, time, realm }
-- Returns a status ("new", "updated", "ignored") and the entry.
function Store.record(db, message)
  local verdict = ns.Detect.classify(message.text)
  if not verdict.isRecruit then return "ignored", nil, verdict end

  local name = ns.GuildName.parse(message.text)
  local key
  if name then
    key = ns.GuildName.normalize(name)
  else
    -- An unnamed message from a poster whose guild is known goes there.
    local known = db.posters[message.sender]
    local knownId = known and id(message.realm, known)
    key = known and (db.guilds[knownId] or db.dismissed[knownId]) and known or Store.unknownKey(message.sender)
  end
  if name and message.ownGuild and ns.GuildName.normalize(message.ownGuild) == key then
    return "ignored", nil, verdict
  end
  if db.dismissed[id(message.realm, key)] or (not name and db.dismissedPosters[message.sender]) then
    if name then db.posters[message.sender] = key end
    return "dismissed", nil, verdict
  end

  local entry = Store.get(db, message.realm, key)
  local status = "updated"
  if not entry then
    status = "new"
    entry = { key = key, realm = message.realm, name = name, firstSeen = message.time, messages = {} }
    if not name then entry.unknownPoster = message.sender end
    db.guilds[id(message.realm, key)] = entry
  end
  if name then
    db.posters[message.sender] = key
    mergeUnknown(db, entry, message.sender)
  end
  entry.lastSeen = math.max(entry.lastSeen or message.time, message.time)
  addMessage(entry, message)
  cap(entry, db.settings.maxMessages)
  Store.retag(entry)
  return status, entry, verdict
end

-- "Not interested": the entry leaves the list and is no longer recorded.
-- Only a small record stays, with the last message so Restore can show it.
function Store.dismiss(db, entry, now)
  local eid = id(entry.realm, entry.key)
  local latest = Store.latest(entry)
  db.dismissed[eid] = {
    key = entry.key, realm = entry.realm, name = entry.name, unknownPoster = entry.unknownPoster,
    time = now, tags = entry.tags, message = latest,
  }
  if entry.unknownPoster then db.dismissedPosters[entry.unknownPoster] = now end
  db.guilds[eid] = nil
end

-- Undoes a dismissal; returns the entry that is back in the list.
function Store.restore(db, eid)
  local record = db.dismissed[eid]
  if not record then return nil end
  db.dismissed[eid] = nil
  if record.unknownPoster then db.dismissedPosters[record.unknownPoster] = nil end
  local m = record.message
  local entry = {
    key = record.key, realm = record.realm, name = record.name, unknownPoster = record.unknownPoster,
    firstSeen = m and m.first or record.time, lastSeen = m and m.last or record.time,
    messages = { m },
  }
  Store.retag(entry)
  db.guilds[eid] = entry
  return entry
end

-- True when the player dismissed one of this guild's posters earlier.
function Store.hasDismissedPoster(db, entry)
  for _, m in ipairs(entry.messages) do
    if db.dismissedPosters[m.sender] then return true end
  end
  return false
end

-- Removes guilds not seen for pruneDays, except starred ones. Dismissed
-- records stay forever. Returns how many guilds were removed.
function Store.prune(db, now)
  local limit = now - db.settings.pruneDays * 86400
  local removed = 0
  for eid, entry in pairs(db.guilds) do
    if not entry.starred and (entry.lastSeen or 0) < limit then
      db.guilds[eid] = nil
      removed = removed + 1
    end
  end
  for sender, key in pairs(db.posters) do
    local realm = sender:match("%-(.+)$") or ""
    if not db.guilds[id(realm, key)] and not db.dismissed[id(realm, key)] then db.posters[sender] = nil end
  end
  return removed
end

function Store.star(entry, on)
  entry.starred = on and true or nil
end

-- Tags are the union over the stored messages; the oldest message's word wins.
function Store.retag(entry)
  local tags = {}
  for _, m in ipairs(entry.messages) do
    for id, w in pairs(ns.Tags.extract(m.text, entry.name)) do
      if not tags[id] then tags[id] = w end
    end
  end
  entry.tags = tags
end

-- The most recently seen message of an entry.
function Store.latest(entry)
  local best
  for _, m in ipairs(entry.messages) do
    if not best or m.last >= best.last then best = m end
  end
  return best
end

function Store.posterCount(entry)
  local seen, n = {}, 0
  for _, m in ipairs(entry.messages) do
    if not seen[m.sender] then seen[m.sender] = true; n = n + 1 end
  end
  return n
end

-- Each poster once, most recently seen first, with their messages newest first.
function Store.posters(entry)
  local bySender, list = {}, {}
  for _, m in ipairs(entry.messages) do
    local p = bySender[m.sender]
    if not p then
      p = { sender = m.sender, messages = {}, lastSeen = m.last }
      bySender[m.sender] = p
      list[#list + 1] = p
    end
    p.messages[#p.messages + 1] = m
    if m.last > p.lastSeen then p.lastSeen = m.last end
  end
  local function newest(a, b) return a.last > b.last end
  for _, p in ipairs(list) do table.sort(p.messages, newest) end
  table.sort(list, function(a, b)
    if a.lastSeen ~= b.lastSeen then return a.lastSeen > b.lastSeen end
    return a.sender < b.sender
  end)
  return list
end

-- A day count typed in the settings, or nil when it is not a whole number in range.
function Store.parseDays(text, min, max)
  local n = tonumber(((text or ""):match("^%s*(%d+)%s*$")))
  if n and n >= min and n <= max then return n end
end

-- The list was opened: everything seen so far is no longer new.
function Store.markOpened(db, now)
  db.lastOpened = now
end

-- Guilds first seen since the list was last opened (the minimap counter).
function Store.newCount(db)
  local since, n = db.lastOpened or -math.huge, 0
  for _, entry in pairs(db.guilds) do
    if (entry.firstSeen or 0) > since then n = n + 1 end
  end
  return n
end

local DEBUG_LOG_MAX = 200

-- Debug mode: remembers rejected messages that came close, and the channel
-- names seen, so the rules can be tuned from the saved variables (ADR 0002).
function Store.logDebug(db, item)
  db.debugLog = type(db.debugLog) == "table" and db.debugLog or {}
  local log = db.debugLog
  log.nearMisses = log.nearMisses or {}
  log.channels = log.channels or {}
  log.channels[item.channel] = (log.channels[item.channel] or 0) + 1
  if not item.verdict then return end
  table.insert(log.nearMisses, 1, {
    text = item.text, sender = item.sender, channel = item.channel, time = item.time,
    signal = item.verdict.signal, exclusion = item.verdict.exclusion,
  })
  for i = #log.nearMisses, DEBUG_LOG_MAX + 1, -1 do log.nearMisses[i] = nil end
end
