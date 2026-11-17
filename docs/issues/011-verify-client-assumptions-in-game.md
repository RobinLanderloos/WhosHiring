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
