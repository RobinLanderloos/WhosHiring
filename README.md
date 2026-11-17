# Who's Hiring?

Made mainly for me and my friends. It's shared in case it's useful to others too, but expect it to follow our needs first.

A World of Warcraft (WoW Forever) addon that keeps a list of guilds recruiting in chat: every numbered channel, Say, Yell and whispers. Each guild shows its name, its latest message, tags parsed from its messages (focus, intensity, roles and classes wanted, schedule, language) and everyone who advertised it. Star the guilds you like and dismiss the ones you don't: dismissed guilds never show up again.

Open the list with `/wh`, `/whoshiring` or the minimap button.

- **Rows** show the guild, its tags (hover over them to see which word set each), its latest message, how many people advertised it and when. Click a row to see every poster's messages, each with a Whisper button.
- **Star** a guild to keep it at the top; **✕** (not interested) hides it and stops recording it. The Dismissed tab can restore it.
- **Filters** opens tag chips: chips in the same row are OR, rows are AND. Search matches names and messages.
- **Alert me on these chips** announces each new guild that matches, once, in chat (click the name to open it).
- Guilds fade after 14 days without posting and are forgotten after 60, unless starred (`/wh config`).
- `/wh debug` logs messages that almost counted; `/wh report` writes a report into the saved variables.

## Development

- `luajit tests/run.lua`: unit tests for the pure logic in `Core/`
- `luajit tests/smoke_test.lua`: loads every file in the .toc against a stand-in for the game
- Design: `docs/prd/`, decisions: `docs/adr/`, work items: `docs/issues/`
