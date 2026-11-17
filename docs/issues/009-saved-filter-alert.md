# Saved-filter alert

Type: AFK

## State

Open

## What to build

'Alert me on this filter' saves the current chip selection. When a new or newly matching guild matches it, one clickable chat line (and an optional sound) appears, once per guild.

## Acceptance criteria

- [ ] Alert.shouldAlert fires once per guild for new matches (unit tests)
- [ ] The chat line opens the window on that guild
- [ ] Alerts and the sound can be turned off in settings

## Blocked by

- 006-filter-chips-search-and-sorting.md
- 008-minimap-button-with-new-guild-counter.md
