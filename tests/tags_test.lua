local ns, test, eq = ...
local function tags(text) return ns.Tags.extract(text) end
local function has(t, id) return t[id] ~= nil end

test("focus tags come from what the guild does", function()
  local t = tags("<Night Watch> recruiting for MC and BWL raids, also some PvP and battlegrounds")
  eq(has(t, "raiding"), true, "raiding")
  eq(has(t, "pvp"), true, "pvp")
  eq(has(t, "leveling"), false, "leveling")
  t = tags("chill levelling guild, family friendly, we do dungeons together. RP welcome")
  eq(has(t, "leveling"), true, "leveling")
  eq(has(t, "social"), true, "social")
  eq(has(t, "dungeons"), true, "dungeons")
  eq(has(t, "rp"), true, "rp")
end)

test("the matched word is remembered for each tag", function()
  eq(tags("<Night Watch> recruiting for MC")["raiding"], "mc")
end)

test("semi-hardcore is not hardcore", function()
  local t = tags("<X> semi-hardcore raiding guild recruiting")
  eq(has(t, "semihardcore"), true, "semi")
  eq(has(t, "hardcore"), false, "hardcore")
  t = tags("<X> hardcore progression, recruiting")
  eq(has(t, "hardcore"), true, "hardcore")
  eq(has(t, "casual"), false, "casual")
  eq(has(tags("casual and relaxed guild recruiting"), "casual"), true, "casual")
end)

test("roles and classes wanted, with plurals and nicknames", function()
  local t = tags("<X> LF tanks, healz and a few dps. Need priests, a pally and locks")
  eq(has(t, "tank"), true, "tank")
  eq(has(t, "healer"), true, "healer")
  eq(has(t, "dps"), true, "dps")
  eq(has(t, "priest"), true, "priest")
  eq(has(t, "paladin"), true, "paladin")
  eq(has(t, "warlock"), true, "warlock")
  eq(has(t, "mage"), false, "mage")
end)

test("all classes tags every class", function()
  local t = tags("<X> recruiting all classes!")
  for _, class in ipairs({ "warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid" }) do
    eq(t[class], "all classes", class)
  end
end)

test("schedule tags from days and times of the week", function()
  local t = tags("<X> raids Wed/Thu 20:00 ST and weekends")
  eq(has(t, "wed"), true, "wed")
  eq(has(t, "thu"), true, "thu")
  eq(has(t, "weekend"), true, "weekend")
  eq(has(t, "mon"), false, "mon")
  eq(has(t, "evenings"), true, "evenings from 20:00")
  eq(has(tags("<Sunwell> recruiting"), "sun"), false, "Sunwell is not Sunday")
end)

test("language and region tags", function()
  local t = tags("<X> German guild (Deutsch) recruiting, EU times")
  eq(has(t, "de"), true, "de")
  eq(has(t, "eu"), true, "eu")
  eq(has(tags("[EN] <X> recruiting"), "en"), true, "en")
  eq(has(tags("come join us, we recruit"), "na"), false, "us is not NA")
end)

test("other tags: new guild, loot systems, adults", function()
  local t = tags("Newly formed guild <X> recruiting, DKP loot, 18+ only")
  eq(has(t, "newguild"), true, "new")
  eq(has(t, "dkp"), true, "dkp")
  eq(has(t, "adult"), true, "adult")
  eq(has(tags("<X> loot council, soft res for MC"), "lootcouncil"), true, "lc")
  eq(has(tags("<X> loot council, soft res for MC"), "softres"), true, "sr")
end)

test("every tag belongs to a known group and has a label", function()
  local groups = {}
  for _, g in ipairs(ns.Tags.groups) do groups[g.id] = true end
  for _, def in ipairs(ns.Tags.definitions) do
    eq(groups[def.group], true, def.id .. " group")
    eq(type(def.label), "string", def.id .. " label")
  end
end)

test("the guild's own name does not set tags", function()
  eq(has(tags("<Night Watch> recruiting"), "evenings"), false, "bracketed name")
  eq(has(ns.Tags.extract("Night Watch is recruiting", "Night Watch"), "evenings"), false, "named")
  eq(has(ns.Tags.extract("Social Butterflies is recruiting raiders", "Social Butterflies"), "social"), false, "named social")
end)

test("real Trade message: <Yes> (seen in game)", function()
  local t = tags("<Yes> is recruiting! We're former tryhards who still love the game, but now prefer a healthier balance with real life. We look forward to efficient raiding, PvP and endgame progression together, without the pressure and drama.")
  eq(has(t, "healer"), false, "healthier is not healer")
  eq(has(t, "raiding"), true, "raiding")
  eq(has(t, "pvp"), true, "pvp")
  eq(has(t, "casual"), true, "without the pressure / real life")
  eq(has(t, "hardcore"), false, "former tryhards")
end)

test("healer words still match", function()
  for _, w in ipairs({ "heal", "heals", "healer", "healers", "healing", "healz", "healy" }) do
    eq(has(tags("<X> recruiting " .. w), "healer"), true, w)
  end
end)
