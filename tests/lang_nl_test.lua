local ns, test, eq = ...

local BLOODLINE = "The Bloodline zoekt nieuwe leden! Wij zijn een gezellige NL/BE Social Guild. Iedereen Welkom! Samen spelen, lachen, dungeons & raids doen. Geen verplichtingen, alleen gezelligheid! Join The Bloodline - For the Horde!"

test("nl: a Dutch guild looking for members is recruitment", function()
  eq(ns.Detect.classify(BLOODLINE).isRecruit, true, "live ad")
  eq(ns.Detect.classify("<De Wachters> rekruteert! Iedereen welkom").isRecruit, true, "rekruteert")
  eq(ns.Detect.classify("Ons gilde zoekt nog spelers voor raids, whisper mij").isRecruit, true, "gilde zoekt spelers")
  eq(ns.Detect.classify("Sluit je aan bij <Lage Landen>, gezellige guild").isRecruit, true, "sluit je aan")
end)

test("nl: a Dutch player looking for a guild is not recruitment", function()
  eq(ns.Detect.classify("Ik zoek een gezellige guild, lvl 30 priest").isRecruit, false, "zoek een guild")
  eq(ns.Detect.classify("zoek een nederlandse gilde om mee te levelen").isRecruit, false, "zoek een gilde")
end)

test("nl: Dutch group finding is not recruitment", function()
  eq(ns.Detect.classify("zoeken nog spelers voor RFC").isRecruit, false, "group for RFC")
end)

test("nl: the guild name comes before zoekt", function()
  eq(ns.GuildName.parse(BLOODLINE), "Bloodline")
  eq(ns.GuildName.parse("Ons gilde De Wachters zoekt nog spelers"), "De Wachters")
end)

test("nl: Dutch tags", function()
  local tags = ns.Tags.extract(BLOODLINE, "Bloodline")
  eq(tags.nl, "nl", "language")
  eq(tags.social ~= nil, true, "social")
  eq(tags.casual, "geen verplichtingen", "casual")
  eq(tags.raiding, "raids", "raiding")
  eq(tags.dungeons, "dungeons", "dungeons")
  eq(ns.Tags.extract("Wij levelen samen, nederlandstalig").leveling, "levelen", "levelen")
end)
