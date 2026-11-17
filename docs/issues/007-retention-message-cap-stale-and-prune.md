# Retention: message cap, stale and prune

Type: AFK

## State

Completed

## What to build

Each guild keeps at most 20 distinct messages. Guilds not seen for staleDays are greyed out, and after pruneDays they are removed at login unless starred. Dismissed records are never pruned. A settings panel exposes the day limits.

## Acceptance criteria

- [x] The message cap keeps the newest messages (unit test)
- [x] Prune removes old, unstarred guilds and keeps starred guilds and dismissed records (unit test)
- [x] Stale rows show greyed out with 'last seen Nd ago'
- [x] Settings panel changes staleDays and pruneDays

## Blocked by

- 001-record-recruiting-guilds-and-show-them-in-a-list.md
