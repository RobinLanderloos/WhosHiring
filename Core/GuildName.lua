-- Finds the guild name in a recruitment message (ADR 0001). Pure.
local addonName, ns = ...

local GuildName = {}
ns.GuildName = GuildName

-- Words that are never part of a guild name found without brackets.
local stopwords = {}
for w in ([[we our us you i my the a an new hey hi hello all guild guilds
  lf lfm come join is are recruiting casual friendly]]):gmatch("%S+") do
  stopwords[w] = true
end

-- Verbs that follow a guild name: "<name> is recruiting", "<name> recruiting".
local afterIs = { recruiting = true, lf = true, lfm = true, looking = true, seeking = true,
  accepting = true, recruits = true }
local direct = { recruiting = true, recruits = true }

local function split(text)
  local words = {}
  for raw in text:gmatch("%S+") do
    local core = raw:match("^%p*(.-)%p*$")
    words[#words + 1] = {
      raw = raw,
      core = core,
      lower = core:lower(),
      capital = core:find("^%u") ~= nil,
      endsClause = raw:find("[%.,!%?;:]$") ~= nil,
      startsClause = raw:find("^[%(%[]") ~= nil,
    }
  end
  return words
end

local function usable(word)
  return word.capital and word.core ~= "" and not stopwords[word.lower]
end

local function join(words, first, last)
  local parts = {}
  for i = first, last do parts[#parts + 1] = words[i].core end
  return table.concat(parts, " ")
end

-- Capitalised words ending just before index i, at most four.
local function nameBefore(words, i)
  local last = i - 1
  if words[last] and words[last].lower == "guild" then last = last - 1 end
  local first = last + 1
  while first > 1 and last - first < 3 do
    local w = words[first - 1]
    if not usable(w) then break end
    if first - 1 < last and w.endsClause then break end
    first = first - 1
    if w.startsClause then break end
  end
  if first <= last and not words[last].endsClause then return join(words, first, last) end
end

-- Capitalised words starting just after index i, at most four.
local function nameAfter(words, i)
  local first, last = i + 1, i
  while words[last + 1] and usable(words[last + 1]) and last - first < 3 do
    last = last + 1
    if words[last].endsClause then break end
  end
  if last >= first then return join(words, first, last) end
end

-- The guild name as written, or nil when none can be found.
function GuildName.parse(text)
  local clean = ns.Text.strip(text)
  local name = clean:match("<%s*([^<>]-)%s*>")
  if name and name ~= "" then return name end

  local words = split(clean)
  for i, w in ipairs(words) do
    local nextWord = words[i + 1]
    if (w.lower == "is" or w.lower == "are") and nextWord and afterIs[nextWord.lower] then
      name = nameBefore(words, i)
    elseif direct[w.lower] then
      name = nameBefore(words, i)
    end
    if name then return name end
  end
  for i, w in ipairs(words) do
    if w.lower == "guild" or w.lower == "join" then
      name = nameAfter(words, i)
      if name then return name end
    end
  end
end

-- The key a guild is stored under: lowercase, single spaces.
function GuildName.normalize(name)
  return (name:lower():gsub("%s+", " "):gsub("^ ", ""):gsub(" $", ""))
end

-- The /who search for a guild's online members, e.g. g-"Night Watch".
function GuildName.whoQuery(name)
  if not name or name == "" then return nil end
  return 'g-"' .. name:gsub('"', "") .. '"'
end
