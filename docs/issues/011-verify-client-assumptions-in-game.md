# Verify client assumptions in-game

Type: HITL

## State

Open

## What to build

The user runs the addon live: chat events arrive with the expected arguments, /wh isn't taken, Whisper and the player menu work, the minimap button works, and SavedVariables persist. Detection rules are tuned from the debug log.

## Acceptance criteria

- [ ] Real recruitment messages are captured and tagged sensibly
- [ ] /wh works (no conflict)
- [ ] Whisper button and alerts work in the client
- [ ] Rules tuned from the debug log

## How to check

1. **Restart the client fully** (the addon is new, so `/reload` is not enough), then log in.
2. Type `/wh debug` (turns logging on), then stay in a city with Trade or General open for a while.
3. Open the list with `/wh` or the minimap button: check rows, tags (hover over them), expanding a row, Whisper, Who's online (opens the Who window on the guild), star, dismiss, Restore, filters, search, sort.
4. Optional: open Filters, pick a chip, click "Alert me on these chips", and wait for a match in chat; click the link.
5. Type `/wh report`, then `/reload`. Claude reads `WTF\Account\<account>\SavedVariables\WhosHiring.lua`: the report, the near-miss log, channel names, and the captured guilds, to tune the rules.

Unverified client facts the report answers: `/wh` is not taken, which whisper function exists, whether the Who window search works, sender name format, secret values in chat.

## Blocked by

- 001-record-recruiting-guilds-and-show-them-in-a-list.md
- 002-tags-on-guild-entries.md
- 003-expand-a-guild-to-see-every-poster.md
- 004-unknown-guild-entries-that-merge-later.md
- 005-star-dismiss-and-restore.md
- 006-filter-chips-search-and-sorting.md
- 007-retention-message-cap-stale-and-prune.md
- 008-minimap-button-with-new-guild-counter.md
- 009-saved-filter-alert.md
- 010-debug-mode-and-report.md
