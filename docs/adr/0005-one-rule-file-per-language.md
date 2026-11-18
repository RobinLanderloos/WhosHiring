# Each language's rules live in their own file

Recruitment ads on Forever's EU realms come in several languages; the first non-English one we missed was Dutch ("The Bloodline zoekt nieuwe leden!"). The English rules stay in `Core/Detect.lua`, `Core/GuildName.lua` and `Core/Tags.lua`. Every other language gets one file in `Core/Lang/<code>.lua`, listed in the .toc after `Core\Tags.lua`. It adds its patterns through `Detect.addRules`, `GuildName.direct/stopwords/guildWords`, and `Tags.add`/`Tags.addPatterns`, and gets its own test file (`tests/lang_<code>_test.lua`) built from real chat lines.

All languages are always on: rules are additive and cheap, and a player may want guilds in several languages. Bump `Store.RULES_VERSION` when a language file changes, so saved entries are re-tagged.
