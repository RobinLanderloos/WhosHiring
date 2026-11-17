# Filter chips, search and sorting

Type: AFK

## State

Completed

## What to build

Chip rows built from the tag definitions filter the list: OR within a group, AND across groups. A search box matches guild names and message text. Sorting by last seen (default), name or poster count, always with starred first.

## Acceptance criteria

- [x] Query.list implements OR within a group and AND across groups (unit tests)
- [x] Search matches names and message text, ignoring case (unit tests)
- [x] Chips and search box in the window update the list

## Blocked by

- 002-tags-on-guild-entries.md
