# Who's online button

Type: AFK

## State

Completed

## What to build

An open guild row has a "Who's online" button that opens the game's Who window with /who g-"<Guild Name>", so another member can be whispered when the poster is offline. One search per click, run through the Who window's own search box and button (not automatic, so ADR 0001's reasons against /who do not apply). Unknown guilds have no button.

Changed after the in-game check (2026-11-17): Forever's Friends window has only Contacts and Raid tabs; the Who list lives in the LFG window (tab 3), and small results go to chat. So the button now runs the search itself (`C_FriendList.SendWho` with `SetWhoToUi(true)` for that one search) and lists the online members inside the row, each with a Whisper button.

## Acceptance criteria

- [x] GuildName.whoQuery builds g-"Name" and drops quotes (unit test)
- [x] The button shows only on open rows of named guilds
- [x] Clicking opens the Who tab and runs the search (smoke test)
- [x] /wh report lists which Who functions exist in the client

## Blocked by

- 003-expand-a-guild-to-see-every-poster.md
