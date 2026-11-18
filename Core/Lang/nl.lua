-- Dutch (NL/BE) rules. Pure: adds patterns to Detect, GuildName and Tags.
-- One file per language; each is listed in the .toc after Core\Tags.lua.
-- Patterns run on ns.Text.normalize(text) (lowercase, spaces collapsed).
local addonName, ns = ...

local word = ns.Tags.word

ns.Detect.addRules({
  recruitSignals = {
    "%f[%a]zoek%a* %a* ?%a* ?leden%f[%A]", -- "zoekt (nieuwe) leden"
    "%f[%a]nieuwe leden%f[%A]",
    "%f[%a]rekrute%a*",                    -- "rekruteert", "rekruteren"
    "%f[%a]sluit je aan%f[%A]", "%f[%a]sluit u aan%f[%A]",
    "%f[%a]word lid%f[%A]",
    "%f[%a]kom erbij%f[%A]",
  },
  -- Count only next to "guild", "gilde" or a <Name>.
  weakSignals = {
    "%f[%a]zoek%a* %a* ?%a* ?spelers%f[%A]", -- "zoeken nog spelers"
    "%f[%a]zoek%a* %a* ?%a* ?mensen%f[%A]",
    "%f[%a]zoek%a* %a* ?%a* ?raiders%f[%A]",
  },
  guildContext = {
    "%f[%a]gilde%f[%A]",
  },
  exclusions = {
    "%f[%a]zoek%a* ee?n %a* ?gu?ilde?%f[%A]", -- "ik zoek een (gezellige) guild/gilde"
  },
})

for w in ("zoekt zoeken rekruteert rekruteren"):gmatch("%S+") do
  ns.GuildName.direct[w] = true
end
for w in ("wij ons onze jij je ik iedereen welkom een het gilde"):gmatch("%S+") do
  ns.GuildName.stopwords[w] = true
end
ns.GuildName.guildWords.gilde = true

ns.Tags.add({ id = "nl", group = "language", label = "NL", patterns = {
  word("nl"), word("dutch"), word("nederlands%a*"), word("vlaams"), word("belg%a*"), "%[nl%]" } }, "es")
ns.Tags.addPatterns("social", { word("gezellig%a*"), word("sociaal") })
ns.Tags.addPatterns("casual", { "geen verplicht%a*", word("ontspannen"), word("rustig") })
ns.Tags.addPatterns("leveling", { word("levelen") })
