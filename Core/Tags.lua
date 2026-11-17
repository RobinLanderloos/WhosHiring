-- Tags parsed from recruitment messages (ADR 0002). Pure: the definitions
-- are data, `extract` takes text and returns { [tagId] = matched word }.
local addonName, ns = ...

local Tags = {}
ns.Tags = Tags

-- Shown in this order as chip rows in the window.
Tags.groups = {
  { id = "focus", label = "Focus" },
  { id = "intensity", label = "Intensity" },
  { id = "wants", label = "Wants" },
  { id = "schedule", label = "Schedule" },
  { id = "language", label = "Language" },
  { id = "other", label = "Other" },
}

local function word(w) return "%f[%w]" .. w .. "%f[^%w]" end

-- patterns run on ns.Text.normalize(text); `except` patterns are blanked out
-- first (so "semi-hardcore" never counts as "hardcore").
Tags.definitions = {
  -- Focus
  { id = "raiding", group = "focus", label = "Raiding", patterns = {
    word("raid%a*"), word("mc"), "molten core", word("ony"), word("onyxia"), word("bwl"), "blackwing",
    word("zg"), "zul'?gurub", word("aq%d*"), word("naxx%a*"), word("progression") } },
  { id = "pvp", group = "focus", label = "PvP", patterns = {
    word("pvp"), word("bgs?"), "battlegrounds?", word("wsg"), word("av"), "alterac", word("ab"), "arathi basin",
    word("honor"), word("ranking") } },
  { id = "leveling", group = "focus", label = "Leveling", patterns = {
    word("level+ing"), word("lvl+ing"), word("leveler?s"), word("all levels"), word("lowbies?") } },
  { id = "social", group = "focus", label = "Social", patterns = {
    word("social"), word("chill"), word("family"), word("friendly"), word("community"), word("fun") } },
  { id = "rp", group = "focus", label = "RP", patterns = { word("rp"), "role%-?play%a*" } },
  { id = "dungeons", group = "focus", label = "Dungeons", patterns = {
    word("dungeons?"), word("5 ?%-?man"), word("instances?") } },

  -- Intensity
  { id = "casual", group = "intensity", label = "Casual", patterns = {
    word("casual"), word("relaxed"), "laid[%s%-]back", word("no pressure"), "without %a* ?pressure",
    word("real life"), word("rl first"), word("life first") } },
  { id = "semihardcore", group = "intensity", label = "Semi-hardcore", patterns = {
    "semi[%s%-]?hardcore", "semi[%s%-]?hc", word("semi") } },
  { id = "hardcore", group = "intensity", label = "Hardcore",
    except = { "semi[%s%-]?hardcore", "semi[%s%-]?hc" },
    patterns = { word("hardcore"), word("hc"), word("sweaty"), word("tryhard"), word("speedrun%a*") } },

  -- Wants: roles
  { id = "tank", group = "wants", label = "Tank", patterns = { word("tanks?"), word("tanking") } },
  { id = "healer", group = "wants", label = "Healer", patterns = {
    word("heals?"), word("healers?"), word("healing"), word("healz"), word("healy"), word("heallers?") } },
  { id = "dps", group = "wants", label = "DPS", patterns = { word("[mr]?dps"), word("dd"), "damage dealers?" } },
  -- Wants: classes ("all classes" adds every one, see below)
  { id = "warrior", group = "wants", label = "Warrior", class = true, patterns = { word("warr?iors?"), word("warr?s?") } },
  { id = "paladin", group = "wants", label = "Paladin", class = true, patterns = { word("paladins?"), word("pal+y"), word("pal+ies"), word("palas?") } },
  { id = "hunter", group = "wants", label = "Hunter", class = true, patterns = { word("hunters?"), word("hunts?") } },
  { id = "rogue", group = "wants", label = "Rogue", class = true, patterns = { word("rogues?") } },
  { id = "priest", group = "wants", label = "Priest", class = true, patterns = { word("priests?") } },
  { id = "shaman", group = "wants", label = "Shaman", class = true, patterns = { word("shamans?"), word("sham+y"), word("sham+ies") } },
  { id = "mage", group = "wants", label = "Mage", class = true, patterns = { word("mages?") } },
  { id = "warlock", group = "wants", label = "Warlock", class = true, patterns = { word("warlocks?"), word("locks?") } },
  { id = "druid", group = "wants", label = "Druid", class = true, patterns = { word("druids?") } },

  -- Schedule
  { id = "weekdays", group = "schedule", label = "Weekdays", patterns = { word("weekdays?"), word("weeknights?") } },
  { id = "weekend", group = "schedule", label = "Weekend", patterns = { word("weekends?") } },
  { id = "evenings", group = "schedule", label = "Evenings", patterns = {
    word("evenings?"), word("nights?"), "after work", "%f[%d]1[7-9][:%.h]%d*", "%f[%d]2[0-3][:%.h]%d*",
    "%f[%d][5-9] ?pm", "%f[%d]1[01] ?pm" } },
  { id = "mon", group = "schedule", label = "Mon", patterns = { word("mon"), word("mondays?") } },
  { id = "tue", group = "schedule", label = "Tue", patterns = { word("tues?"), word("tuesdays?") } },
  { id = "wed", group = "schedule", label = "Wed", patterns = { word("wed"), word("wednesdays?") } },
  { id = "thu", group = "schedule", label = "Thu", patterns = { word("thu"), word("thurs?"), word("thursdays?") } },
  { id = "fri", group = "schedule", label = "Fri", patterns = { word("fri"), word("fridays?") } },
  { id = "sat", group = "schedule", label = "Sat", patterns = { word("sat"), word("saturdays?") } },
  { id = "sun", group = "schedule", label = "Sun", patterns = { word("sun"), word("sundays?") } },

  -- Language and region
  { id = "en", group = "language", label = "EN", patterns = { word("english"), word("eng"), "%[en%]" } },
  { id = "de", group = "language", label = "DE", patterns = { word("german"), word("deutsch%a*"), "%[de%]", word("ger") } },
  { id = "fr", group = "language", label = "FR", patterns = { word("french"), "fran.-ais", "%[fr%]" } },
  { id = "es", group = "language", label = "ES", patterns = { word("spanish"), "espa.-ol", "%[es%]" } },
  -- Written in another alphabet (the game's English fonts cannot show these).
  { id = "gr", group = "language", label = "GR", reason = "Greek letters",
    patterns = { word("greek"), "%[gr%]", "[\206\207][\128-\191]" } },
  { id = "ru", group = "language", label = "RU", reason = "Cyrillic letters",
    patterns = { word("russian"), "%[ru%]", "[\208\209][\128-\191]" } },
  { id = "eu", group = "language", label = "EU times", patterns = { word("eu"), word("cet"), word("cest"), word("gmt"), word("bst") } },
  { id = "na", group = "language", label = "NA times", patterns = { word("na"), word("est"), word("pst"), word("cst"), word("[ep]dt") } },

  -- Other
  { id = "newguild", group = "other", label = "New guild", patterns = {
    "new guild", "newly formed", "fresh guild", "just started", "starting guild" } },
  { id = "dkp", group = "other", label = "DKP", patterns = { word("dkp"), word("epgp") } },
  { id = "lootcouncil", group = "other", label = "Loot council", patterns = { "loot council", word("lc") } },
  { id = "softres", group = "other", label = "Soft res", patterns = { "soft[%s%-]?res%a*", word("sr") } },
  { id = "adult", group = "other", label = "18+", patterns = { "18%+", word("adults?"), word("mature") } },
}

Tags.byId = {}
for _, def in ipairs(Tags.definitions) do Tags.byId[def.id] = def end

local ALL_CLASSES = { "all classes", "any class", "all class" }

-- The earliest match of any pattern: its text, or nil.
local function earliest(t, patterns)
  local best, bestText
  for _, p in ipairs(patterns) do
    local s, e = t:find(p)
    if s and (not best or s < best) then best, bestText = s, t:sub(s, e) end
  end
  return bestText
end

-- Lua pattern that matches `s` literally.
local function literal(s)
  return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

-- { [tagId] = the word that set it }. The guild's own name (in <brackets>, or
-- `guildName` when given) is left out: "Night Watch" is not about evenings.
function Tags.extract(text, guildName)
  local t = ns.Text.normalize(text):gsub("<[^>]*>", " ")
  if guildName and guildName ~= "" then
    t = t:gsub(literal(ns.Text.normalize(guildName)), " ")
  end
  local found = {}
  for _, def in ipairs(Tags.definitions) do
    local source = t
    if def.except then
      for _, p in ipairs(def.except) do source = source:gsub(p, " ") end
    end
    local hit = earliest(source, def.patterns)
    -- A matched letter of another alphabet is unreadable in the tooltip.
    if hit and def.reason and hit:byte(1) > 127 then hit = def.reason end
    if hit then found[def.id] = hit end
  end
  local all = earliest(t, ALL_CLASSES)
  if all then
    for _, def in ipairs(Tags.definitions) do
      if def.class then found[def.id] = all end
    end
  end
  return found
end
