local ns, test, eq = ...
local Store, Query = ns.Store, ns.Query

local function record(db, text, sender, time)
  return select(2, Store.record(db, { text = text, sender = sender or "Bob-Realm", channel = "Trade", time = time, realm = "Realm" }))
end

test("the list shows guilds newest first with their latest message", function()
  local db = Store.init(nil)
  record(db, "<Night Watch> recruiting tanks", "Bob-Realm", 100)
  record(db, "<Iron Oath> recruiting all", "Kim-Realm", 300)
  record(db, "<Night Watch> recruiting healers now", "Alice-Realm", 200)
  local rows = Query.list(db, { now = 400 })
  eq(#rows, 2, "rows")
  eq(rows[1].name, "Iron Oath", "first")
  eq(rows[2].name, "Night Watch", "second")
  eq(rows[2].message, "<Night Watch> recruiting healers now", "latest message")
  eq(rows[2].posters, 2, "posters")
  eq(rows[2].lastSeen, 200, "lastSeen")
end)

test("ages are shown in the largest whole unit", function()
  eq(Query.age(30), "now", "seconds")
  eq(Query.age(12 * 60 + 5), "12m", "minutes")
  eq(Query.age(2 * 3600 + 100), "2h", "hours")
  eq(Query.age(3 * 86400 + 5), "3d", "days")
end)

test("unknown entries are listed with their poster and no name", function()
  local db = Store.init(nil)
  record(db, "We are recruiting! /w me", "Bob-Realm", 100)
  record(db, "Our guild is recruiting all classes", "Kim-Realm", 100)
  record(db, "<Night Watch> recruiting", "Alice-Realm", 100)
  local rows = Query.list(db, { now = 200 })
  eq(#rows, 3, "rows")
  local unknown = 0
  for _, r in ipairs(rows) do
    if r.unknownPoster then
      unknown = unknown + 1
      eq(r.name, nil, "no name")
    end
  end
  eq(unknown, 2, "unknown rows")
end)
