# Recruitment detection and tagging use keyword rules in a pure Core table

A message is recruitment when it contains a recruit signal (recruiting, `<Guild>` plus "looking for", "join us", ...) and no exclusion signal ("LF guild", WTS/WTB, LFG for a dungeon, ...). Tags (Focus, Intensity, Wants, Schedule, Language/Region, Other) come from keyword patterns in the same kind of data table. The rules live in `Core/` with no game calls and are unit-tested against real chat messages. Tags can't be edited in-game in v1. Instead, a tooltip shows which word set each tag, so wrong rules can be reported and fixed in code. Debug mode logs messages that came close but were rejected, into SavedVariables, so the rules can be tuned.

Listened to: all numbered channels, Say, Yell and Whisper. Not guild, party or raid chat. The player's own messages and those of the player's own guild are skipped.
