# Star, dismiss and restore

Type: AFK

## State

Completed

## What to build

Each row has star and dismiss buttons, and the window has All, Starred and Dismissed tabs. Dismissing stops recording the guild and keeps only a dismissed record. Dismissing an unknown entry dismisses the poster. The Dismissed tab can restore. Guilds that have a dismissed poster show a hint. Starred guilds sort first.

## Acceptance criteria

- [x] Messages of a dismissed guild are not stored (unit test)
- [x] Dismissing an unknown entry dismisses the poster; a later named guild from that poster is not dismissed but shows the hint (unit test)
- [x] Restore brings the guild back into the list
- [x] Starred guilds sort first; the tabs show the right sets

## Blocked by

- 001-record-recruiting-guilds-and-show-them-in-a-list.md
