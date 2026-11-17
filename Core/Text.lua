-- Text helpers shared by the Core modules. Pure.
local addonName, ns = ...

local Text = {}
ns.Text = Text

-- Text as the player reads it: escape codes and raid-target icons removed,
-- hyperlinks reduced to their visible text. Case is kept.
function Text.strip(text)
  local t = text
  t = t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  t = t:gsub("|H.-|h(.-)|h", "%1")
  t = t:gsub("|T.-|t", ""):gsub("|A.-|a", "")
  t = t:gsub("{[^}]*}", " ")
  return (t:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", ""))
end

-- Lowercased text for rule matching: escape codes and raid-target icons
-- removed, hyperlinks reduced to their visible text, spaces collapsed.
function Text.normalize(text)
  local t = Text.strip(text):lower()
  t = t:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
  return t
end
