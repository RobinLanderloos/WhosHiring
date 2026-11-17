# Who's online button

Type: AFK

## State

Completed

## What to build

An open guild row has a "Who's online" button that opens the game's Who window with /who g-"<Guild Name>", so another member can be whispered when the poster is offline. One search per click, run through the Who window's own search box and button (not automatic, so ADR 0001's reasons against /who do not apply). Unknown guilds have no button.

## Acceptance criteria

- [x] GuildName.whoQuery builds g-"Name" and drops quotes (unit test)
- [x] The button shows only on open rows of named guilds
- [x] Clicking opens the Who tab and runs the search (smoke test)
- [x] /wh report lists which Who functions exist in the client

## Blocked by

- 003-expand-a-guild-to-see-every-poster.md
