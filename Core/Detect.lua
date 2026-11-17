-- Decides whether a chat message is guild recruitment (ADR 0002).
-- Pure: plain text in, a plain table out.
local addonName, ns = ...

local Detect = {}
ns.Detect = Detect

-- Patterns run on ns.Text.normalize(text) (lowercase, spaces collapsed).
-- Strong signals count on their own.
Detect.recruitSignals = {
  "recruit",
  "%f[%a]accepting %a*",              -- "accepting all classes", "accepting new members"
  "%f[%a]join us%f[%A]",
  "%f[%a]join <",
  "%f[%a]apply%f[%A]",
  "%f[%a]applications? %a*open",
  "%f[%a]guild inv",                  -- "guild invite", "guild inv"
  "%f[%a]ginv%f[%A]",
  "for an? inv",                       -- "/w for a invite"
  "for inv%f[%A]", "for invite",
}

-- Weak signals count only next to the word "guild" or a <Name>.
Detect.weakSignals = {
  "looking for %a* ?%a* ?members",
  "looking for %a* ?%a* ?players",
  "looking for %a* ?%a* ?raiders",
  "looking for %a* ?%a* ?people",
  "%f[%a]lfm%f[%A]",
  "%f[%a]is lf%f[%A]",
  "%f[%a]is looking for%f[%A]",
  "%f[%a]seeking%f[%A]",
  "%f[%a]are looking for%f[%A]",
  "%f[%a]needs? %a* ?%a* ?tanks?%f[%A]",
  "%f[%a]needs? %a* ?%a* ?heal",
  "%f[%a]needs? %a* ?%a* ?dps%f[%A]",
}

-- What makes a weak signal count.
Detect.guildContext = {
  "%f[%a]guild%f[%A]",
  "<[^>]+>",
}

-- Any of these means the message is not a guild advertising itself.
Detect.exclusions = {
  "%f[%a]lf ?an? ?guild",           -- "LF guild", "lf a guild"
  "%f[%a]lf ?%a* guild%f[%A]",      -- "lf raiding guild"
  "looking for an? %a* ?guild%f[%A]", -- "looking for a (chill) guild"
  "%f[%a]any ?%a* guilds? recruit", -- "any guild(s) recruiting"
  "%f[%a]charter",                  -- buying signatures for a guild charter
  "%f[%a]signatures?%f[%A]",
}

-- Trade and services: never a guild advert.
Detect.tradeExclusions = {
  "%f[%a]wt[sbt]%f[%A]", -- WTS, WTB, WTT
  "%f[%a]lfw%f[%A]",     -- looking for work
}

-- Group finding: excludes only when there is no guild context, so a guild
-- that mentions the dungeons it runs still counts.
Detect.groupExclusions = {
  "%f[%a]lf%d+m?%f[%A]", "%f[%a]lf%d*m%f[%A]", "%f[%a]lfg%f[%A]",
  "%f[%a]need %d* ?%a* ?tank", "%f[%a]need %d* ?%a* ?heal", "%f[%a]need %d* ?dps",
  "%f[%a]rfc%f[%A]", "%f[%a]wc%f[%A]", "deadmines", "%f[%a]vc%f[%A]", "%f[%a]sfk%f[%A]",
  "%f[%a]bfd%f[%A]", "stockade", "%f[%a]stocks%f[%A]", "gnomer", "%f[%a]rfk%f[%A]",
  "%f[%a]sm%f[%A]", "%f[%a]rfd%f[%A]", "%f[%a]ulda", "%f[%a]zf%f[%A]", "%f[%a]mara%f[%A]",
  "%f[%a]brd%f[%A]", "%f[%a][lu]brs%f[%A]", "%f[%a]scholo", "%f[%a]strat%f[%A]",
}

local function firstMatch(t, patterns)
  for _, p in ipairs(patterns) do
    if t:find(p) then return p end
  end
end

function Detect.classify(text)
  local t = ns.Text.normalize(text)
  local context = firstMatch(t, Detect.guildContext)
  local signal = firstMatch(t, Detect.recruitSignals)
  local weak = firstMatch(t, Detect.weakSignals)
  if not signal and weak and context then signal = weak end
  local exclusion = firstMatch(t, Detect.exclusions) or firstMatch(t, Detect.tradeExclusions)
  if not exclusion and not context then exclusion = firstMatch(t, Detect.groupExclusions) end
  local isRecruit = signal ~= nil and exclusion == nil
  return {
    isRecruit = isRecruit,
    -- Close but rejected: logged in debug mode to tune the rules.
    nearMiss = not isRecruit and (signal ~= nil or weak ~= nil) or nil,
    signal = signal or weak,
    exclusion = exclusion,
  }
end
