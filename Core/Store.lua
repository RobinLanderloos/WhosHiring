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
  return db
end

function Store.get(db, realm, key)
  return db.guilds[id(realm, key)]
end

-- message = { text, sender, channel, time, realm }
-- Returns a status ("new", "updated", "ignored") and the entry.
function Store.record(db, message)
  local verdict = ns.Detect.classify(message.text)
  if not verdict.isRecruit then return "ignored", nil, verdict end

  local name = ns.GuildName.parse(message.text)
  local key = ns.GuildName.normalize(name)
  if message.ownGuild and ns.GuildName.normalize(message.ownGuild) == key then
    return "ignored", nil, verdict
  end
  local entry = Store.get(db, message.realm, key)
  local status = "updated"
  if not entry then
    status = "new"
    entry = { key = key, realm = message.realm, name = name, firstSeen = message.time, messages = {} }
    db.guilds[id(message.realm, key)] = entry
  end
  entry.lastSeen = message.time
  entry.messages[#entry.messages + 1] = {
    sender = message.sender, text = message.text, channel = message.channel,
    first = message.time, last = message.time, count = 1,
  }
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
