# Record recruiting guilds and show them in a list

Type: AFK

## State

Completed

## What to build

Tracer bullet. The project skeleton (.toc, Core/Game split, test runner, smoke stub, junction into AddOns) is in place. Chat events (numbered channels, Say, Yell, Whisper) go through recruitment detection and guild-name parsing into the account-wide store, skipping the player's own messages and the player's own guild's. `/wh` and `/whoshiring` open a movable, resizable, Escape-closable window listing guild entries (name, latest message, number of posters, last seen), newest first.

## Acceptance criteria

- [x] Detect.classify accepts recruitment and rejects LF guild, WTS/WTB and dungeon LFG messages (unit tests with a message corpus)
- [x] GuildName.parse handles <Brackets> and 'Name is recruiting' style phrases; normalize gives a stable key (unit tests)
- [x] Store.record creates and updates guild entries keyed per realm and skips the player's own guild
- [x] /wh and /whoshiring toggle the window; rows show name, latest message, poster count and last seen
- [x] Smoke test fires chat events and sees the rows in the window

## Blocked by

None - can start immediately
