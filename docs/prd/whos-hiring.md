# Who's Hiring? — guild recruitment tracker for WoW Forever

## Problem Statement

When I'm looking for a guild, recruitment messages scroll past in Trade, General, LookingForGroup, Say, Yell and the occasional whisper. They are gone within seconds, I can't copy them out of the game, and I can't compare guilds that advertised hours or days apart. The same guilds post over and over, often from different members, and guilds I've already decided against keep catching my eye.

## Solution

An addon that listens to chat, recognises guild recruitment messages, and keeps an account-wide list of **guilds**. Each guild shows its name, its latest message, automatically assigned **tags** (focus, intensity, roles and classes wanted, schedule, language, other), how many posters advertised it and when it was last seen. Opening a guild shows every poster's messages, with a Whisper button for each poster. I can filter by tag chips and search text, **star** guilds I'm interested in (they're pinned to the top) and **dismiss** guilds I'm not interested in (they disappear and stop being recorded, and I can restore them from a Dismissed tab). A counter on the minimap button shows new guilds since I last looked. Optionally, one saved filter alerts me in chat when a new guild matches it.

## Glossary

- **Message**: one recruitment chat line, stored per poster, with a count and first/last seen times for identical repeats.
- **Poster**: the character who sent a message (`Name-Realm`).
- **Guild entry**: one row in the list, keyed on the normalised guild name (see ADR 0001).
- **Unknown entry**: an entry for a poster whose messages had no parsable guild name. It merges into a guild entry when that poster later names their guild.
- **Tag**: a label from a tag group (Focus, Intensity, Wants, Schedule, Language/Region, Other), set by a keyword rule. A guild's tags are the union over all its messages.
- **Starred**: pinned to the top and never pruned.
- **Dismissed**: hidden and no longer recorded (see ADR 0003).
- **Stale**: not seen for 14 days, shown greyed out. Pruned after 60 days unless starred (see ADR 0004).

## User Stories

1. As a guild seeker, I want recruitment messages from any numbered channel to be recorded automatically, so that I don't have to watch chat.
2. As a guild seeker, I want recruitment messages in Say and Yell to be recorded, so that city recruiters are captured.
3. As a guild seeker, I want recruitment whispers to be recorded, so that direct invites are kept too.
4. As a guild seeker, I want "LF guild", WTS/WTB and dungeon LFG messages to be ignored, so that the list contains only guilds that are recruiting.
5. As a guild seeker, I want my own messages and my own guild's recruitment to be ignored, so that the list isn't polluted.
6. As a guild seeker, I want the guild name parsed from `<Guild Name>` and from phrases like "Guild Name is recruiting", so that entries are named correctly.
7. As a guild seeker, I want messages from different members of the same guild to be grouped under one guild entry, so that each guild appears once.
8. As a guild seeker, I want messages without a parsable guild name to appear as "Unknown guild, posted by X", so that nothing is lost.
9. As a guild seeker, I want an unknown entry to merge into the guild when its poster later names the guild, so that duplicates resolve themselves.
10. As a guild seeker, I want repeated identical messages stored once, with a count and last-seen time, so that spam doesn't fill the list.
11. As a guild seeker, I want tags assigned from keywords (focus, intensity, roles, classes, schedule, language, loot system, new guild), so that I can find matching guilds quickly.
12. As a guild seeker, I want "all classes" to tag every class, so that open recruitment matches any class filter.
13. As a guild seeker, I want a guild's tags to combine all its messages, so that guildmates' different posts add up.
14. As a guild seeker, I want to hover over a tag and see which word triggered it, so that I can trust it or report a wrong rule.
15. As a guild seeker, I want to open the list with `/wh` or `/whoshiring`, so that it's quick to reach.
16. As a guild seeker, I want a minimap button that opens the list and can be dragged around the minimap or hidden, so that I can reach it with the mouse.
17. As a guild seeker, I want the minimap button to show how many new guilds appeared since I last opened the list, so that I know when to look.
18. As a guild seeker, I want a scrollable, resizable, movable window that closes with Escape and remembers its position, so that it behaves like other windows.
19. As a guild seeker, I want each row to show the guild name, tags, latest message, number of posters and last-seen time, so that I can scan quickly.
20. As a guild seeker, I want to expand a row to see every poster's messages with times and counts, so that I get the full picture.
21. As a guild seeker, I want a Whisper button per poster, so that I can contact a recruiter directly.
22. As a guild seeker, I want to filter by tag chips (OR within a group, AND across groups), so that I can narrow down to what I want.
23. As a guild seeker, I want to search guild names and message text, so that I can find something specific.
24. As a guild seeker, I want to star a guild, so that it stays at the top and is never pruned.
25. As a guild seeker, I want a Starred tab, so that I can compare my shortlist.
26. As a guild seeker, I want to dismiss a guild, so that it never shows up again.
27. As a guild seeker, I want dismissing an unknown entry to dismiss that poster, so that unnamed spam can be hidden too.
28. As a guild seeker, I want a Dismissed tab with a Restore button, so that I can undo a misclick.
29. As a guild seeker, I want a hint on a guild when I dismissed one of its posters earlier, so that I remember why it looks familiar.
30. As a guild seeker, I want the list sorted starred first, then newest last seen, with sorting by name or poster count as options, so that the relevant guilds come first.
31. As a guild seeker, I want guilds not seen for 14 days greyed out and removed after 60 days (unless starred), so that the list stays current and the saved data small.
32. As a guild seeker, I want the stale and prune day limits to be settings, so that I can keep things longer.
33. As a guild seeker, I want each guild to keep at most 20 distinct messages, so that the data stays small.
34. As a guild seeker, I want the list shared across all my characters, so that alts benefit from what my main saw.
35. As a guild seeker, I want to save the current chip selection as an alert filter, so that I'm told when a new matching guild shows up.
36. As a guild seeker, I want a single clickable chat line (and an optional sound) per newly matching guild, so that I'm alerted without spam.
37. As the developer, I want a debug mode that logs rejected near-miss messages and channel names to SavedVariables, so that detection rules can be tuned from real data.
38. As the developer, I want the original chat messages never hidden or changed, so that the addon can't interfere with chat.

## Implementation Decisions

Layout follows the user's addon convention: pure logic in `Core/` (no game calls, plain values in and out), game glue and drawing in `Game/`, shared state on the addon namespace, labels in `Locales/enUS.lua`.

**Core modules (deep, tested outside the game):**

- **Detect**: `classify(text)` returns `{ isRecruit, nearMiss, reason }`. Recruit signals and exclusion signals live in a data table. Text is normalised first (lowercased, colour codes and hyperlinks reduced to their visible text, raid-target icons `{star}` removed).
- **GuildName**: `parse(text)` returns the display name or nil. It tries `<Name>` brackets first, then patterns like "Name is recruiting", "Name (is) LF", "join Name". `normalize(name)` returns the key (lowercased, trimmed, inner spaces collapsed).
- **Tags**: `extract(text)` returns `{ [tagId] = matchedWord }`. Tag definitions (id, group, label, patterns) are a data table, so the UI can list groups and chips from it. Word boundaries come from frontier patterns. Class plurals and "all classes" are handled.
- **Store**: owns the saved database shape. Operations: `record(db, {text, sender, channel, time, ownGuildKey})` returns `"new" | "updated" | "dismissed" | "ignored"` plus the entry; `star(key, bool)`; `dismiss(key)`; `restore(key)`; `prune(now, settings)`; `markSeen(now)` and `newCount()`. It handles deduplication per poster, the 20-message cap, merging unknown entries, the dismissed-poster hint, and union of tags (stored per entry together with the trigger word).
- **Query**: `list(db, {tab, chips, search, sort, now, staleDays})` returns ordered row view-models (name, tags, latest message, poster count, last seen, stale flag, starred, hint). Chips are OR within a group and AND across groups.
- **Alert**: `shouldAlert(entry, savedFilter, result)` fires only for an entry that is new or newly matching and hasn't been alerted yet.

**Saved data (account-wide `WhosHiringDB`):**

```
{ version = 1,
  settings = { staleDays = 14, pruneDays = 60, maxMessages = 20, minimap = { hide, angle }, alert = { enabled, chips, sound }, debug },
  guilds = { [key] = { key, name, realm, firstSeen, lastSeen, starred, alerted, unknownPoster?,
                       tags = { [tagId] = word }, messages = { { sender, text, channel, first, last, count } } } },
  dismissed = { [key] = { name, time, tags } },
  dismissedPosters = { [sender] = time },
  lastOpened = time,
  report = { ... } }
```

Keys include the realm of the sighting so that different realms don't collide. Unknown entries use key `?<sender>`.

**Game modules:**

- **ChatListener**: registers `CHAT_MSG_CHANNEL`, `CHAT_MSG_SAY`, `CHAT_MSG_YELL`, `CHAT_MSG_WHISPER`, skips the player, passes plain values to Store, and fires the alert or counter update. Wrapped in `pcall` so chat is never broken.
- **Window**: the list window (tabs, chip rows built from the tag table, search box, scroll list with expandable rows, star, dismiss and restore buttons, Whisper buttons via `ChatFrame_SendTell` or the equivalent, tag tooltips).
- **MinimapButton**: as in DustOrGold, plus a counter.
- **Options**: a settings panel (stale/prune days, minimap, alert sound, debug).
- **Slash**: `/wh`, `/whoshiring`, and subcommands (`debug`, `report`).
- **Report**: diagnostics written to SavedVariables.

## Testing Decisions

- Tests check external behaviour only: what `classify`, `parse`, `extract`, Store operations and `list` return for given inputs, never internal tables.
- Detection, name parsing and tags are tested against a corpus of realistic recruitment and non-recruitment messages. Real messages from the debug log are added as they are collected.
- Every Core module gets unit tests (LuaJIT, `tests/run.lua`, as in DustOrGold).
- A smoke test (`tests/smoke_test.lua`) loads every `.toc` file against the game stand-in, fires chat events, opens the window, clicks star, dismiss and restore, and checks the shown text.
- Prior art: DustOrGold `tests/run.lua` and `tests/smoke_test.lua`.
- Passing outside the game doesn't prove client behaviour. The events, the whisper call and the player menu must be checked in-game.

## Out of Scope

- `/who` or any other lookup of the sender's guild (ADR 0001).
- Editing tags, adding custom tags or notes in-game.
- More than one saved alert filter.
- Guild Finder / Club Finder integration.
- Hiding or changing chat messages.
- Publishing to WowUp or CurseForge (a later decision).

## Further Notes

- The name of Forever's recruitment channel, if it has one, is unknown. Debug mode logs the channel names it sees.
- `/wh` must be checked against other addons' slash commands in-game.
- The ADRs in `docs/adr/` record the guild-keying, detection, dismissal and retention decisions.
