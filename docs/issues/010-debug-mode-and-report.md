# Debug mode and report

Type: AFK

## State

Completed

## What to build

`/wh debug` toggles logging of near-miss rejected messages and channel names seen. `/wh report` writes a summary. Both are stored in SavedVariables so they can be read after /reload.

## Acceptance criteria

- [x] Near misses and channel names are logged to SavedVariables while debug is on, with a capped size
- [x] /wh report writes counts and settings to SavedVariables

## Blocked by

- 001-record-recruiting-guilds-and-show-them-in-a-list.md
