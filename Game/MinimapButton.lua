-- The minimap button: left-click opens the list, right-click the settings,
-- drag to move it around the minimap. Shows how many guilds are new since
-- the list was last opened.
local addonName, ns = ...

local L = ns.L
local ICON = "Interface\\Icons\\INV_Misc_Note_02"

local MinimapButton = {}
ns.MinimapButton = MinimapButton

local button

local function settings()
  local s = ns.db.settings
  s.minimap = type(s.minimap) == "table" and s.minimap or {}
  s.minimap.angle = s.minimap.angle or 200
  return s.minimap
end

local function radius()
  return (Minimap:GetWidth() / 2) + 10
end

local function place()
  local x, y = ns.Geometry.minimapOffset(settings().angle, radius())
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- While dragging, follow the cursor around the minimap.
local function follow()
  local centerX, centerY = Minimap:GetCenter()
  local cursorX, cursorY = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  settings().angle = ns.Geometry.minimapAngle(cursorX / scale - centerX, cursorY / scale - centerY)
  place()
end

-- Only stored once complete, so a failed build never leaves half a button.
local function build()
  local button = CreateFrame("Button", "WhosHiringMinimapButton", Minimap)
  button:SetSize(31, 31)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetSize(20, 20)
  background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  background:SetPoint("TOPLEFT", 7, -5)

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetSize(17, 17)
  icon:SetPoint("TOPLEFT", 7, -6)
  icon:SetTexture(ICON)
  icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53)
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetPoint("TOPLEFT")

  -- The new-guild counter, a small badge on the top right.
  button.badge = CreateFrame("Frame", nil, button)
  button.badge:SetSize(16, 14)
  button.badge:SetPoint("TOPRIGHT", 2, 0)
  button.badge:SetFrameLevel((button:GetFrameLevel() or 8) + 2)
  local badgeBg = button.badge:CreateTexture(nil, "BACKGROUND")
  badgeBg:SetAllPoints()
  badgeBg:SetColorTexture(0.8, 0.1, 0.1, 0.9)
  button.count = button.badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  button.count:SetPoint("CENTER", 0, 0)

  button:SetScript("OnClick", function(_, mouseButton)
    if mouseButton == "RightButton" then
      if ns.OpenOptions then ns.OpenOptions() end
    else
      ns.Window.Toggle()
    end
  end)
  button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", follow) end)
  button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(L.TITLE)
    local n = ns.Store.newCount(ns.db)
    if n > 0 then GameTooltip:AddLine(L.MINIMAP_NEW:format(n), 0.25, 1, 0.25) end
    GameTooltip:AddLine(L.MINIMAP_LEFT, 1, 1, 1)
    GameTooltip:AddLine(L.MINIMAP_RIGHT, 1, 1, 1)
    GameTooltip:AddLine(L.MINIMAP_DRAG, 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return button
end

-- Redraws the counter; cheap enough to call on every recorded message.
function MinimapButton.UpdateCount()
  if not button then return end
  local n = ns.Store.newCount(ns.db)
  button.count:SetText(n > 99 and "99+" or tostring(n))
  button.badge:SetWidth(n > 9 and 22 or 16)
  button.badge:SetShown(n > 0)
end

-- Shows or hides the button to match the settings.
function MinimapButton.Update()
  if not Minimap or not ns.db then return end
  if not button then button = build() end
  place()
  button:SetShown(not settings().hide)
  MinimapButton.UpdateCount()
end

-- Settings panel checkbox.
ns.OptionsExtras = ns.OptionsExtras or {}
table.insert(ns.OptionsExtras, {
  label = L.OPTION_MINIMAP,
  help = L.OPTION_MINIMAP_HELP,
  get = function() return not settings().hide end,
  set = function(on)
    settings().hide = not on
    MinimapButton.Update()
  end,
})

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
  local ok, err = pcall(MinimapButton.Update)
  if not ok then print("|cff40c0ffWho's Hiring:|r the minimap button could not be built: " .. tostring(err)) end
end)
