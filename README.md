# Who's Hiring?

Made mainly for me and my friends. It's shared in case it's useful to others too, but expect it to follow our needs first.

A World of Warcraft (WoW Forever) addon that keeps a list of guilds recruiting in chat: every numbered channel, Say, Yell and whispers. Each guild shows its name, its latest message, tags parsed from its messages (focus, intensity, roles and classes wanted, schedule, language) and everyone who advertised it. Star the guilds you like and dismiss the ones you don't: dismissed guilds never show up again.

Open the list with `/wh` or `/whoshiring`.

## Development

- `luajit tests/run.lua`: unit tests for the pure logic in `Core/`
- `luajit tests/smoke_test.lua`: loads every file in the .toc against a stand-in for the game
- Design: `docs/prd/`, decisions: `docs/adr/`, work items: `docs/issues/`
