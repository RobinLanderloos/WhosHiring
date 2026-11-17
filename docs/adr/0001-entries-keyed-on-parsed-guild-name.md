# Entries are keyed on the guild name parsed from the message, not on the sender

Chat events carry only the sender and free text, never the sender's guild. Each list entry is one guild, keyed on the normalised guild name parsed from the message text (lowercased, brackets and extra spaces stripped), and holds the messages of every poster who advertised it. When no name can be parsed, the entry is keyed on the poster ("Unknown guild, posted by Bob") and merges into the guild entry once that poster sends a message with a parsable name.

## Considered Options

- **Look up the sender's guild with `/who` (`C_FriendList.SendWho`)**: rejected. It is throttled by the server, answers asynchronously, and takes over the Who window the player may be using.
- **`GetGuildInfo(unit)`**: only works for units you are targeting, hovering over or grouped with, so it is useless for chat.
- **One entry per poster**: rejected. The same guild would appear several times when guildmates take turns advertising.
