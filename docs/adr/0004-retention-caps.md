# Retention caps keep the saved data small

SavedVariables are read at every login and written at every logout, and busy Trade chat produces hundreds of recruiting posts a week. Each guild keeps at most 20 distinct messages; a repeated identical message from the same poster is stored once, with a count and a last-seen time. Guilds not seen for 14 days are shown greyed out, and after 60 days they are pruned at login unless starred. Both limits are settings with these defaults.
