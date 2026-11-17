# Unknown guild entries that merge later

Type: AFK

## State

Open

## What to build

Messages without a parsable guild name create an 'Unknown guild, posted by X' entry keyed on the poster. When that poster later names the guild, the unknown entry merges into the guild entry.

## Acceptance criteria

- [ ] An unparsable message creates an unknown entry (unit test)
- [ ] A later named message by the same poster merges messages and tags into the guild and removes the unknown entry (unit test)
- [ ] Unknown entries show as 'Unknown guild, posted by X'

## Blocked by

- 001-record-recruiting-guilds-and-show-them-in-a-list.md
