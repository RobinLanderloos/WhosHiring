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

test("rows list their tags in definition order with the trigger word", function()
  local db = Store.init(nil)
  record(db, "<Night Watch> casual guild recruiting healers and tanks for MC", "Bob-Realm", 100)
  local tags = Query.list(db, { now = 200 })[1].tags
  local ids = {}
  for i, t in ipairs(tags) do ids[i] = t.id end
  eq(table.concat(ids, ","), "raiding,casual,tank,healer", "order")
  eq(tags[1].label, "Raiding", "label")
  eq(tags[1].word, "mc", "word")
end)

local function names(rows)
  local list = {}
  for i, r in ipairs(rows) do list[i] = r.name or r.unknownPoster end
  return table.concat(list, ",")
end

test("starred guilds come first, then newest", function()
  local db = Store.init(nil)
  local old = record(db, "<Old Friends> recruiting", "A-Realm", 100)
  record(db, "<Newest> recruiting", "B-Realm", 300)
  record(db, "<Middle> recruiting", "C-Realm", 200)
  Store.star(old, true)
  local rows = Query.list(db, { now = 400 })
  eq(names(rows), "Old Friends,Newest,Middle")
  eq(rows[1].starred, true, "starred flag")
end)

test("the starred tab shows only starred guilds", function()
  local db = Store.init(nil)
  local a = record(db, "<Alpha> recruiting", "A-Realm", 100)
  record(db, "<Beta> recruiting", "B-Realm", 200)
  Store.star(a, true)
  eq(names(Query.list(db, { now = 300, tab = "starred" })), "Alpha")
end)

test("the dismissed tab shows dismissed guilds, newest dismissal first", function()
  local db = Store.init(nil)
  local a = record(db, "<Alpha> recruiting", "A-Realm", 100)
  local b = record(db, "<Beta> recruiting tanks", "B-Realm", 200)
  record(db, "<Gamma> recruiting", "C-Realm", 200)
  Store.dismiss(db, a, 300)
  Store.dismiss(db, b, 400)
  local rows = Query.list(db, { now = 500, tab = "dismissed" })
  eq(names(rows), "Beta,Alpha", "order")
  eq(rows[1].dismissed, true, "flag")
  eq(rows[1].message, "<Beta> recruiting tanks", "last message")
  eq(rows[1].tags[1].id, "tank", "tags")
  eq(names(Query.list(db, { now = 500 })), "Gamma", "all tab hides dismissed")
end)

test("a guild with a dismissed poster carries a hint", function()
  local db = Store.init(nil)
  local unknown = record(db, "We are recruiting! /w me", "Bob-Realm", 100)
  Store.dismiss(db, unknown, 150)
  record(db, "<Night Watch> is recruiting", "Bob-Realm", 200)
  eq(Query.list(db, { now = 300 })[1].dismissedPosterHint, true)
end)

test("guilds not seen for staleDays are marked stale", function()
  local db = Store.init(nil)
  record(db, "<Old> recruiting", "A-Realm", 0)
  record(db, "<Fresh> recruiting", "B-Realm", 10 * 86400)
  local rows = Query.list(db, { now = 15 * 86400 })
  eq(rows[1].name, "Fresh", "order")
  eq(rows[1].stale, nil, "fresh is not stale")
  eq(rows[2].stale, true, "old is stale")
end)

local function filterDb()
  local db = Store.init(nil)
  record(db, "<Raid Tanks> recruiting tanks for MC", "A-Realm", 100)
  record(db, "<Raid Heals> recruiting healers for BWL", "B-Realm", 200)
  record(db, "<PvP Tanks> recruiting tanks for battlegrounds", "C-Realm", 300)
  record(db, "<Social Club> chill guild recruiting all levels", "D-Realm", 400)
  return db
end

test("chips in the same group are OR", function()
  local rows = Query.list(filterDb(), { now = 500, chips = { tank = true, healer = true } })
  eq(names(rows), "PvP Tanks,Raid Heals,Raid Tanks")
end)

test("chips in different groups are AND", function()
  local rows = Query.list(filterDb(), { now = 500, chips = { raiding = true, tank = true } })
  eq(names(rows), "Raid Tanks")
  rows = Query.list(filterDb(), { now = 500, chips = { raiding = true, tank = true, healer = true } })
  eq(names(rows), "Raid Heals,Raid Tanks")
end)

test("search matches guild names and message text, ignoring case", function()
  eq(names(Query.list(filterDb(), { now = 500, search = "social" })), "Social Club", "name")
  eq(names(Query.list(filterDb(), { now = 500, search = "BATTLEGROUNDS" })), "PvP Tanks", "message")
  eq(names(Query.list(filterDb(), { now = 500, search = "  " })), "Social Club,PvP Tanks,Raid Heals,Raid Tanks", "blank")
  eq(names(Query.list(filterDb(), { now = 500, search = "mc (" })), "", "pattern characters are plain text")
end)

test("search also matches older messages of a guild", function()
  local db = Store.init(nil)
  record(db, "<Night Watch> recruiting, raids on wednesday", "A-Realm", 100)
  record(db, "<Night Watch> recruiting all classes", "B-Realm", 200)
  eq(names(Query.list(db, { now = 300, search = "wednesday" })), "Night Watch")
end)

test("sorting by name or poster count, starred still first", function()
  local db = filterDb()
  record(db, "<Raid Tanks> recruiting tanks", "E-Realm", 50)
  eq(names(Query.list(db, { now = 500, sort = "name" })), "PvP Tanks,Raid Heals,Raid Tanks,Social Club", "name")
  eq(names(Query.list(db, { now = 500, sort = "posters" })):match("^[^,]+"), "Raid Tanks", "posters")
  Store.star(Store.get(db, "Realm", "social club"), true)
  eq(names(Query.list(db, { now = 500, sort = "name" })):match("^[^,]+"), "Social Club", "starred first")
end)

test("filters apply to the dismissed tab too", function()
  local db = filterDb()
  Store.dismiss(db, Store.get(db, "Realm", "raid tanks"), 600)
  Store.dismiss(db, Store.get(db, "Realm", "social club"), 700)
  eq(names(Query.list(db, { now = 800, tab = "dismissed", chips = { tank = true } })), "Raid Tanks")
end)
