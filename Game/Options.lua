-- The settings panel (Options > AddOns > Who's Hiring?), also /wh config.
local addonName, ns = ...

local L = ns.L
local category
local refreshers = {} -- functions that show the saved values when the panel opens

local function help(widget, title, text)
  widget:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(title)
    GameTooltip:AddLine(text, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- A label with a number box for a day setting.
local function dayBox(panel, anchor, settingKey, label, helpText, min, max)
  local text = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  text:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -16)
  text:SetText(label)
  local box = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
  box:SetSize(50, 20)
  box:SetPoint("LEFT", text, "RIGHT", 12, 0)
  box:SetAutoFocus(false)
  box:SetMaxLetters(3)
  local function show() box:SetText(tostring(ns.db.settings[settingKey])) end
  local function apply()
    local value = ns.Store.parseDays(box:GetText(), min, max)
    if value then ns.db.settings[settingKey] = value end
    show()
    box:ClearFocus()
    if ns.Window then ns.Window.Refresh() end
  end
  box:SetScript("OnEnterPressed", apply)
  box:SetScript("OnEditFocusLost", apply)
  box:SetScript("OnEscapePressed", function(self) show(); self:ClearFocus() end)
  help(box, label, helpText)
  refreshers[#refreshers + 1] = show
  return text
end

-- A checkbox; `get`/`set` read and write the setting.
local function checkbox(panel, anchor, label, helpText, get, set)
  local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
  check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -4, -10)
  if type(check.Text) == "table" then check.Text:SetText(label) end
  check:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
  help(check, label, helpText)
  refreshers[#refreshers + 1] = function() check:SetChecked(get()) end
  return check
end

-- Other features add their own checkboxes below the day settings.
ns.OptionsExtras = ns.OptionsExtras or {}

local function build()
  local panel = CreateFrame("Frame")
  panel:Hide() -- so OnShow fires the first time the settings show it
  panel.name = L.TITLE

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText(L.TITLE)
  local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  sub:SetText(L.HELP)

  local last = dayBox(panel, sub, "staleDays", L.OPTION_STALE, L.OPTION_STALE_HELP, 1, 365)
  last = dayBox(panel, last, "pruneDays", L.OPTION_PRUNE, L.OPTION_PRUNE_HELP, 1, 999)
  for _, extra in ipairs(ns.OptionsExtras) do
    last = checkbox(panel, last, extra.label, extra.help, extra.get, extra.set)
  end

  panel:SetScript("OnShow", function()
    for _, fn in ipairs(refreshers) do fn() end
  end)

  category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  Settings.RegisterAddOnCategory(category)
end

function ns.OpenOptions()
  if category then Settings.OpenToCategory(category:GetID()) end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
  local ok, err = pcall(build)
  if not ok then print("|cff40c0ffWho's Hiring:|r the settings panel could not be built: " .. tostring(err)) end
end)
