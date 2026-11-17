-- The saved guild list: recording messages into guild entries.
-- Pure: works on a plain table (the SavedVariables) and plain values.
local addonName, ns = ...

local Store = {}
ns.Store = Store

local function id(realm, key) return realm .. "|" .. key end

-- Fills in a missing or partial saved table and returns it.
function Store.init(db)
  db = type(db) == "table" and db or {}
  db.version = db.version or 1
  db.guilds = db.guilds or {}
  db.posters = db.posters or {} -- sender -> guild key, once a sender named a guild
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
    key = known and Store.get(db, message.realm, known) and known or Store.unknownKey(message.sender)
  end
  if name and message.ownGuild and ns.GuildName.normalize(message.ownGuild) == key then
    return "ignored", nil, verdict
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
  return status, entry, verdict
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
