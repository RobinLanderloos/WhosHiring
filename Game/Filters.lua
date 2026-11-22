-- The filter controls of the list window: search box, sort button, and a
-- panel of tag chips (OR within a group, AND across groups; see Core/Query).
local addonName, ns = ...

local L = ns.L

local Filters = {}
ns.Filters = Filters

local CHIP_HEIGHT, CHIP_GAP, LABEL_WIDTH = 18, 4, 70
local SORTS = { "seen", "name", "posters" }

local panel, toolbar, searchBox, sortButton, toggleButton, clearButton, alertButton, alertText
local chips = {}     -- tagId -> button
local labels = {}    -- groupId -> font string
local searchText = ""

-- Saved choices: selected chips, sort order, whether the chip panel is open.
local function ui()
  ns.db.ui = type(ns.db.ui) == "table" and ns.db.ui or {}
  local u = ns.db.ui
  u.chips = type(u.chips) == "table" and u.chips or {}
  u.sort = u.sort or "seen"
  return u
end

local function refresh()
  if ns.Window then ns.Window.Refresh() end
end

local function selectedCount()
  local n = 0
  for id in pairs(ui().chips) do
    if ns.Tags.byId[id] then n = n + 1 end
  end
  return n
end

-- What Core/Query.list needs from the controls.
function Filters.Options()
  local u = ui()
  return { chips = u.chips, search = searchText, sort = u.sort }
end

function Filters.IsOpen()
  return ui().filtersOpen == true
end

local function paintChip(button)
  local on = ui().chips[button.tagId] == true
  local a, c = ns.Skin.accent, ns.Skin.colors
  if on then
    button.bg:SetColorTexture(a[1] * 0.35, a[2] * 0.35, a[3] * 0.35, 1)
    for _, t in ipairs(button.edges) do t:SetColorTexture(a[1], a[2], a[3], 1) end
    button.text:SetTextColor(1, 1, 1)
  else
    button.bg:SetColorTexture(c.button[1], c.button[2], c.button[3], 1)
    for _, t in ipairs(button.edges) do t:SetColorTexture(c.border[1], c.border[2], c.border[3], 1) end
    button.text:SetTextColor(0.8, 0.77, 0.7)
  end
end

-- "Raiding + Healer" for the saved alert chips, in definition order.
local function alertSummary()
  local parts = {}
  for _, def in ipairs(ns.Tags.definitions) do
    if ns.db.alert and ns.db.alert.chips and ns.db.alert.chips[def.id] then parts[#parts + 1] = def.label end
  end
  return #parts > 0 and table.concat(parts, " + ") or nil
end

function Filters.Update()
  if not toolbar then return end
  for _, button in pairs(chips) do paintChip(button) end
  local n = selectedCount()
  toggleButton:SetText(n > 0 and L.FILTERS_COUNT:format(n) or L.FILTERS)
  sortButton:SetText(L["SORT_" .. ui().sort:upper()] or L.SORT_SEEN)
  clearButton:SetShown(n > 0 or searchText ~= "")
  panel:SetShown(Filters.IsOpen())
  local summary = alertSummary()
  alertText:SetText(summary and L.ALERT_ON:format(summary) or L.ALERT_NONE)
  alertButton:SetText(n > 0 and L.ALERT_SAVE or L.ALERT_CLEAR)
  alertButton:SetEnabled(n > 0 or summary ~= nil)
end

local function newChip(def)
  local button = CreateFrame("Button", nil, panel)
  button:SetHeight(CHIP_HEIGHT)
  button.tagId = def.id
  button.bg = button:CreateTexture(nil, "BACKGROUND")
  button.bg:SetAllPoints()
  local highlight = button:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetColorTexture(ns.Skin.accent[1], ns.Skin.accent[2], ns.Skin.accent[3], 0.15)
  button.edges = ns.Skin.Edges(button, "BORDER", ns.Skin.colors.border)
  button.text = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  button.text:SetPoint("CENTER")
  button.text:SetText(def.label)
  button:SetWidth(math.max((button.text:GetStringWidth() or 0) + 12, 28))
  button:SetScript("OnClick", function(self)
    local selected = ui().chips
    selected[self.tagId] = not selected[self.tagId] or nil
    Filters.Update()
    refresh()
  end)
  return button
end

-- Places the chips in rows that fit `width`; returns the panel's height.
function Filters.Layout(width)
  if not panel or not Filters.IsOpen() then return 0 end
  local y = 0
  for _, group in ipairs(ns.Tags.groups) do
    labels[group.id]:ClearAllPoints()
    labels[group.id]:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -y - 3)
    local x = LABEL_WIDTH
    for _, def in ipairs(ns.Tags.definitions) do
      if def.group == group.id then
        local button = chips[def.id]
        local w = button:GetWidth()
        if x + w > width and x > LABEL_WIDTH then
          x = LABEL_WIDTH
          y = y + CHIP_HEIGHT + CHIP_GAP
        end
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -y)
        x = x + w + CHIP_GAP
      end
    end
    y = y + CHIP_HEIGHT + CHIP_GAP
  end
  -- The saved-filter alert sits under the chips.
  alertButton:ClearAllPoints()
  alertButton:SetPoint("TOPLEFT", panel, "TOPLEFT", LABEL_WIDTH, -y - 2)
  y = y + 26
  panel:SetHeight(y)
  return y
end

-- Builds the toolbar (and the hidden chip panel) at the top of `frame`.
-- Returns the toolbar; the chip panel hangs under it.
function Filters.Build(frame, anchor)
  toolbar = CreateFrame("Frame", nil, frame)
  toolbar:SetHeight(22)
  toolbar:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
  toolbar:SetPoint("RIGHT", frame, "RIGHT", -12, 0)

  toggleButton = ns.Skin.Button(ns.Skin.Create("Button", nil, toolbar, ns.Skin.TEMPLATES.Button))
  toggleButton:SetSize(96, 20)
  toggleButton:SetPoint("LEFT", 0, 0)
  toggleButton:SetScript("OnClick", function()
    ui().filtersOpen = not Filters.IsOpen()
    Filters.Update()
    refresh()
  end)

  sortButton = ns.Skin.Button(ns.Skin.Create("Button", nil, toolbar, ns.Skin.TEMPLATES.Button))
  sortButton:SetSize(120, 20)
  sortButton:SetPoint("LEFT", toggleButton, "RIGHT", 4, 0)
  sortButton:SetScript("OnClick", function()
    local u = ui()
    local index = 1
    for i, s in ipairs(SORTS) do if s == u.sort then index = i end end
    u.sort = SORTS[index % #SORTS + 1]
    Filters.Update()
    refresh()
  end)

  clearButton = ns.Skin.Button(ns.Skin.Create("Button", nil, toolbar, ns.Skin.TEMPLATES.Button))
  clearButton:SetSize(60, 20)
  clearButton:SetPoint("LEFT", sortButton, "RIGHT", 4, 0)
  clearButton:SetText(L.CLEAR)
  clearButton:SetScript("OnClick", function()
    wipe(ui().chips)
    searchText = ""
    searchBox:SetText("")
    Filters.Update()
    refresh()
  end)

  searchBox = ns.Skin.Input(ns.Skin.Create("EditBox", nil, toolbar, ns.Skin.TEMPLATES.Input))
  searchBox:SetSize(150, 20)
  searchBox:SetPoint("RIGHT", toolbar, "RIGHT", -4, 0)
  searchBox:SetAutoFocus(false)
  searchBox:SetScript("OnTextChanged", function(self)
    -- EditBoxes double a typed "|" (see the addon notes); search the plain text.
    searchText = (self:GetText() or ""):gsub("||", "|")
    Filters.Update()
    refresh()
  end)
  searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  local hint = toolbar:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  hint:SetPoint("RIGHT", searchBox, "LEFT", -6, 0)
  hint:SetText(L.SEARCH)

  panel = CreateFrame("Frame", nil, frame)
  panel:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 0, -4)
  panel:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
  for _, group in ipairs(ns.Tags.groups) do
    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetTextColor(unpack(ns.Skin.accent))
    label:SetText(group.label)
    labels[group.id] = label
  end
  for _, def in ipairs(ns.Tags.definitions) do chips[def.id] = newChip(def) end

  -- Saves the selected chips as the alert filter (or clears it with none).
  alertButton = ns.Skin.Button(ns.Skin.Create("Button", nil, panel, ns.Skin.TEMPLATES.Button))
  alertButton:SetSize(170, 20)
  alertButton:SetScript("OnClick", function()
    ns.Alert.save(ns.db, ui().chips, time())
    Filters.Update()
  end)
  alertText = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  alertText:SetPoint("LEFT", alertButton, "RIGHT", 8, 0)
  alertText:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
  alertText:SetJustifyH("LEFT")

  Filters.Update()
  return toolbar, panel
end
