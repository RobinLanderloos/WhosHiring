-- /wh and /whoshiring.
local addonName, ns = ...

SLASH_WHOSHIRING1 = "/wh"
SLASH_WHOSHIRING2 = "/whoshiring"

SlashCmdList.WHOSHIRING = function(message)
  local command = (message or ""):match("^%s*(%S*)"):lower()
  if command == "config" or command == "options" then
    ns.OpenOptions()
  elseif command == "help" then
    print("|cff40c0ffWho's Hiring:|r " .. ns.L.HELP)
  else
    ns.Window.Toggle()
  end
end
