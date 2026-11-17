local ns, test, eq = ...
local Store, Alert = ns.Store, ns.Alert

local function record(db, text, sender, time)
  return select(2, Store.record(db, { text = text, sender = sender, channel = "Trade", time = time, realm = "Realm" }))
end

test("a new guild matching the saved filter alerts once", function()
  local db = Store.init(nil)
  Alert.save(db, { raiding = true, healer = true }, 100)
  local entry = record(db, "<Night Watch> recruiting healers for MC", "Bob-Realm", 200)
  eq(Alert.check(db, entry), true, "first match alerts")
  entry = record(db, "<Night Watch> recruiting healers for MC, apply", "Alice-Realm", 300)
  eq(Alert.check(db, entry), false, "a repost does not alert again")
end)

test("a guild that does not match does not alert", function()
  local db = Store.init(nil)
  Alert.save(db, { raiding = true, healer = true }, 100)
  eq(Alert.check(db, record(db, "<Night Watch> recruiting tanks for MC", "Bob-Realm", 200)), false)
end)

test("a guild that starts matching after a later message alerts then", function()
  local db = Store.init(nil)
  Alert.save(db, { raiding = true, healer = true }, 100)
  local entry = record(db, "<Night Watch> recruiting for MC", "Bob-Realm", 200)
  eq(Alert.check(db, entry), false, "no healer yet")
  entry = record(db, "<Night Watch> also needs healers", "Alice-Realm", 300)
  eq(Alert.check(db, entry), true, "now it matches")
end)

test("guilds already matching when the filter is saved do not alert", function()
  local db = Store.init(nil)
  local entry = record(db, "<Night Watch> recruiting healers for MC", "Bob-Realm", 100)
  Alert.save(db, { raiding = true, healer = true }, 200)
  entry = record(db, "<Night Watch> recruiting healers for MC again", "Bob-Realm", 300)
  eq(Alert.check(db, entry), false)
end)

test("no alerts without a saved filter or when alerts are off", function()
  local db = Store.init(nil)
  eq(Alert.check(db, record(db, "<A> recruiting healers", "A-Realm", 100)), false, "no filter")
  Alert.save(db, { healer = true }, 150)
  Alert.setEnabled(db, false)
  eq(Alert.check(db, record(db, "<B> recruiting healers", "B-Realm", 200)), false, "off")
  Alert.setEnabled(db, true)
  eq(Alert.check(db, record(db, "<C> recruiting healers", "C-Realm", 300)), true, "on again")
  Alert.save(db, {}, 400)
  eq(Alert.check(db, record(db, "<D> recruiting healers", "D-Realm", 500)), false, "empty filter")
end)

test("the saved filter is a copy of the chips", function()
  local db = Store.init(nil)
  local chips = { healer = true }
  Alert.save(db, chips, 100)
  chips.tank = true
  eq(db.alert.chips.tank, nil)
end)
