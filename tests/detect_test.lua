local ns, test, eq = ...
local classify = function(text) return ns.Detect.classify(text) end

test("a bracketed guild that is recruiting is recruitment", function()
  eq(classify("<Night Watch> is recruiting tanks and healers for MC/BWL").isRecruit, true)
end)

test("a player looking for a guild is not recruitment", function()
  eq(classify("LF guild, 40 mage, any guilds recruiting?").isRecruit, false, "LF guild")
  eq(classify("looking for a chill guild to level with").isRecruit, false, "looking for a guild")
  eq(classify("any guild recruiting a lvl 30 priest?").isRecruit, false, "any guild recruiting")
end)

test("recruitment without the word recruit is recognised", function()
  eq(classify("<Dawnbreakers> chill levelling guild looking for members, /w me for invite").isRecruit, true, "looking for members")
  eq(classify("Night Watch is LF more tanks for BWL, apply on discord").isRecruit, true, "is LF")
  eq(classify("Join <Iron Oath> today! Friendly guild for all levels").isRecruit, true, "join <guild>")
  eq(classify("<Sunwell Pact> LFM healers for weekly raids").isRecruit, true, "<guild> LFM")
  eq(classify("New guild <Ashen Order> accepting all classes, whisper for invite").isRecruit, true, "accepting")
  eq(classify("Guild invite? Whisper me, we are a small social guild and growing").isRecruit, true, "whisper for invite + guild")
end)

test("group finding and trade are not recruitment", function()
  eq(classify("LFM healer for Deadmines").isRecruit, false, "LFM dungeon")
  eq(classify("anyone want to join us for RFC? need 2 dps").isRecruit, false, "join us dungeon")
  eq(classify("LF2M SM cath, need tank and heals, then apply buffs").isRecruit, false, "LF2M")
  eq(classify("WTS [Lesser Magic Essence], recruit the alchemist in me").isRecruit, false, "WTS")
  eq(classify("WTB Linen Cloth, guild bank accepting donations").isRecruit, false, "WTB")
  eq(classify("LFW enchanter, accepting tips").isRecruit, false, "LFW")
end)

test("a guild mentioning dungeons is still recruitment", function()
  eq(classify("<Night Watch> recruiting all levels, we run Deadmines and SM daily").isRecruit, true)
end)

test("weak signals without guild context are near misses, not recruitment", function()
  local r = classify("looking for more players to quest with in Duskwood")
  eq(r.isRecruit, false, "isRecruit")
  eq(r.nearMiss, true, "nearMiss")
end)

test("chat links and raid icons do not hide signals", function()
  eq(classify("{star} |cffffd000<Night Watch>|r |cff00ff00Recruiting|r {star}").isRecruit, true)
end)
