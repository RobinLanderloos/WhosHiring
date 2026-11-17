local ns, test, eq = ...
local parse = function(text) return ns.GuildName.parse(text) end

test("a name in angle brackets is the guild name", function()
  eq(parse("<Night Watch> is recruiting tanks"), "Night Watch")
  eq(parse("Join <Iron Oath> today!"), "Iron Oath")
end)

test("colour codes and links around the brackets are ignored", function()
  eq(parse("{star} |cffffd000<Night Watch>|r Recruiting"), "Night Watch")
end)

test("capitalised words before 'is recruiting' or 'is LF' are the guild name", function()
  eq(parse("Night Watch is recruiting all classes"), "Night Watch")
  eq(parse("Hey all! Night Watch is LF more tanks for BWL"), "Night Watch")
  eq(parse("Night Watch guild is recruiting"), "Night Watch")
  eq(parse("NIGHT WATCH IS RECRUITING HEALERS"), "NIGHT WATCH")
end)

test("capitalised words after 'guild' or 'join' are the guild name", function()
  eq(parse("New guild Ashen Order accepting all classes"), "Ashen Order")
  eq(parse("Come join Iron Oath, friendly levelling guild"), "Iron Oath")
end)

test("no name is found when the message does not name the guild", function()
  eq(parse("We are recruiting! chill levelling guild, /w me"), nil, "we are recruiting")
  eq(parse("Our guild is recruiting all classes"), nil, "our guild")
  eq(parse("casual guild looking for members"), nil, "lowercase")
  eq(parse("Guild recruiting, whisper for invite"), nil, "Guild recruiting")
  eq(parse("Come join us, we are a fun guild"), nil, "join us")
end)

test("the who query searches the guild name in quotes", function()
  eq(ns.GuildName.whoQuery("Night Watch"), 'g-"Night Watch"', "name")
  eq(ns.GuildName.whoQuery('The "Best" Guild'), 'g-"The Best Guild"', "quotes removed")
  eq(ns.GuildName.whoQuery(nil), nil, "no name, no query")
end)
