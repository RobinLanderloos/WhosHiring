-- The Who's online list: /who results turned into members, then filtered and
-- sorted for the Who window. No game calls here, so it is tested outside.
local addonName, ns = ...

local Who = {}
ns.Who = Who

-- The server sends at most this many /who results; more members may exist.
Who.MAX_RESULTS = 50
Who.SORTS = { "name", "level", "class", "zone" }

-- Members from /who results (C_FriendList.GetWhoInfo tables). Members who
-- posted one of the guild's `messages` get `posted`, their latest post time.
-- /who leaves the realm off same-realm names; `realm` puts it back to match.
function Who.members(results, messages, realm)
  local posted = {}
  for _, m in ipairs(messages or {}) do
    if m.sender then posted[m.sender] = math.max(posted[m.sender] or 0, m.last or 0) end
  end
  local members = {}
  for _, info in ipairs(results) do
    local full = info.fullName or "?"
    if realm and not full:find("-", 1, true) then full = full .. "-" .. realm end
    members[#members + 1] = {
      name = info.fullName or "?", guild = info.fullGuildName,
      level = info.level, class = info.classStr, zone = info.area,
      posted = posted[full],
    }
  end
  return members
end

local function lower(s) return (s or ""):lower() end

-- Each sort's natural direction: names A-Z, levels high to low.
local KEYS = {
  name = function(m) return lower(m.name) end,
  level = function(m) return -(m.level or -1) end,
  class = function(m) return lower(m.class) end,
  zone = function(m) return lower(m.zone) end,
}

-- opts = { guild, exact, search, sort, reverse, postersFirst }
-- Returns the members to show and { total, exact } counts.
-- `g-` in /who matches part of a guild name; `exact` keeps only the guild.
function Who.view(members, opts)
  local key = ns.GuildName.normalize(opts.guild or "")
  local search = lower(opts.search):match("^%s*(.-)%s*$")
  local list, exactCount = {}, 0
  for _, m in ipairs(members) do
    local own = m.guild ~= nil and ns.GuildName.normalize(m.guild) == key
    if own then exactCount = exactCount + 1 end
    local found = search == "" or lower(m.name):find(search, 1, true) or lower(m.class):find(search, 1, true)
      or lower(m.zone):find(search, 1, true)
    if (own or not opts.exact) and found then list[#list + 1] = m end
  end

  local sortKey = KEYS[opts.sort] or KEYS.name
  table.sort(list, function(a, b)
    if opts.postersFirst and (a.posted or -1) ~= (b.posted or -1) then
      return (a.posted or -1) > (b.posted or -1)
    end
    local ka, kb = sortKey(a), sortKey(b)
    if ka ~= kb then
      if opts.reverse then return ka > kb end
      return ka < kb
    end
    return lower(a.name) < lower(b.name)
  end)
  return list, { total = #members, exact = exactCount }
end
