# Retention: message cap, stale and prune

Type: AFK

## State

Open

## What to build

Each guild keeps at most 20 distinct messages. Guilds not seen for staleDays are greyed out, and after pruneDays they are removed at login unless starred. Dismissed records are never pruned. A settings panel exposes the day limits.

## Acceptance criteria

- [ ] The message cap keeps the newest messages (unit test)
- [ ] Prune removes old, unstarred guilds and keeps starred guilds and dismissed records (unit test)
- [ ] Stale rows show greyed out with 'last seen Nd ago'
- [ ] Settings panel changes staleDays and pruneDays

## Blocked by

- 001-record-recruiting-guilds-and-show-them-in-a-list.md
