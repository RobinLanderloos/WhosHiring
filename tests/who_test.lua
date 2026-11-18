local ns, test, eq = ...
local Who = ns.Who

local RESULTS = {
  { fullName = "Zed", fullGuildName = "Night Watch", level = 60, classStr = "Warrior", area = "Orgrimmar" },
  { fullName = "Amy", fullGuildName = "night watch", level = 42, classStr = "Priest", area = "Barrens" },
  { fullName = "Bo", fullGuildName = "Night Watchers", level = 30, classStr = "Mage", area = "Durotar" },
  { fullName = "Cy-Other", fullGuildName = "Night Watch", level = 42, classStr = "Mage", area = "Stormwind" },
}
local MESSAGES = {
  { sender = "Zed-Realm", last = 100 },
  { sender = "Cy-Other", last = 300 },
  { sender = "Zed-Realm", last = 200 },
}

local function names(list)
  local out = {}
  for _, m in ipairs(list) do out[#out + 1] = m.name end
  return table.concat(out, ",")
end

local function view(opts)
  local members = Who.members(RESULTS, MESSAGES, "Realm")
  opts.guild = opts.guild or "Night Watch"
  return Who.view(members, opts)
end

test("who members carry the result fields and their latest post", function()
  local members = Who.members(RESULTS, MESSAGES, "Realm")
  eq(#members, 4, "all results")
  eq(members[1].name, "Zed", "name")
  eq(members[1].guild, "Night Watch", "guild")
  eq(members[1].level, 60, "level")
  eq(members[1].class, "Warrior", "class")
  eq(members[1].zone, "Orgrimmar", "zone")
  eq(members[1].posted, 200, "same-realm poster matched without realm, latest post")
  eq(members[4].posted, 300, "other-realm poster matched")
  eq(members[2].posted, nil, "not a poster")
end)

test("exact keeps only the guild's own members, ignoring case", function()
  local list, info = view({ exact = true, sort = "name" })
  eq(names(list), "Amy,Cy-Other,Zed", "Night Watchers left out")
  eq(info.total, 4, "total results")
  eq(info.exact, 3, "exact matches")
end)

test("without exact every result is listed", function()
  local list = view({ exact = false, sort = "name" })
  eq(names(list), "Amy,Bo,Cy-Other,Zed")
end)

test("sorting by level goes high to low, ties by name", function()
  eq(names(view({ exact = true, sort = "level" })), "Zed,Amy,Cy-Other")
  eq(names(view({ exact = true, sort = "level", reverse = true })), "Amy,Cy-Other,Zed", "reversed, ties still by name")
end)

test("sorting by name, class and zone", function()
  eq(names(view({ exact = true, sort = "name", reverse = true })), "Zed,Cy-Other,Amy", "name Z-A")
  eq(names(view({ exact = true, sort = "class" })), "Cy-Other,Amy,Zed", "class A-Z")
  eq(names(view({ exact = true, sort = "zone" })), "Amy,Zed,Cy-Other", "zone A-Z")
end)

test("posters on top come first, newest post first, then the chosen sort", function()
  eq(names(view({ exact = true, sort = "name", postersFirst = true })), "Cy-Other,Zed,Amy")
end)

test("search matches name, class or zone", function()
  eq(names(view({ exact = false, sort = "name", search = "mage" })), "Bo,Cy-Other", "class")
  eq(names(view({ exact = false, sort = "name", search = "ORG" })), "Zed", "zone, any case")
  eq(names(view({ exact = false, sort = "name", search = "  " })), "Amy,Bo,Cy-Other,Zed", "blank search")
end)

test("a missing level sorts last and an unknown sort falls back to name", function()
  local members = Who.members({ { fullName = "Nolvl", fullGuildName = "G" }, { fullName = "Hi", fullGuildName = "G", level = 5 } })
  eq(names(Who.view(members, { guild = "G", exact = true, sort = "level" })), "Hi,Nolvl", "missing level")
  eq(names(Who.view(members, { guild = "G", exact = true, sort = "bogus" })), "Hi,Nolvl", "fallback")
end)

test("the server cap is known", function()
  eq(Who.MAX_RESULTS, 50)
end)
