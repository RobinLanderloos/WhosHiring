-- Shared look for Robin's addons: the game's STOCK UI (trial, 2026-11-22;
-- the classic-art skin is on each addon's pre-stock-ui tag). Windows,
-- buttons, tick boxes and text boxes are made from the client's own
-- templates; callers pass Skin.TEMPLATES.<Kind> to CreateFrame and then hand
-- the widget to the matching Skin call, which only fills in what callers
-- rely on (TitleText, CloseButton, .Text, small button fonts). The same file
-- ships in every addon (DustOrGold, FieldGuide, JunkAway, OpenSpot,
-- RouteKeeper, Warehouse, WhosHiring); keep the copies identical.
--
-- If a template is missing in the client, CreateFrame is retried without
-- it by Skin.Create and the Skin call draws a plain stand-in, so nothing
-- breaks. Each addon keeps an accent colour (ACCENTS) for its own small
-- marks: row hover, chosen chips, badges.
local addonName, ns = ...

local Skin = {}
ns.Skin = Skin

local WHITE = "Interface\\Buttons\\WHITE8x8"
local TOOLTIP_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
local TOOLTIP_TILE = "Interface\\Tooltips\\UI-Tooltip-Background"
local ROW_LIT = "Interface\\QuestFrame\\UI-QuestTitleHighlight"

-- The client templates each kind of widget is made from.
Skin.TEMPLATES = {
  Window = "BasicFrameTemplateWithInset",
  Button = "UIPanelButtonTemplate",
  Check = "UICheckButtonTemplate",
  Input = "InputBoxTemplate",
}

-- CreateFrame with a template, and without it if the client lacks it.
function Skin.Create(kind, name, parent, template)
  local ok, f = pcall(CreateFrame, kind, name, parent, template)
  if ok and f then return f end
  return CreateFrame(kind, name, parent)
end

local ACCENTS = {
  DustOrGold = { 0.83, 0.66, 0.29 },
  FieldGuide = { 0.58, 0.72, 0.42 },
  RouteKeeper = { 0.82, 0.49, 0.27 },
  WhosHiring = { 0.42, 0.68, 0.64 },
  OpenSpot = { 0.47, 0.64, 0.86 },
  Warehouse = { 0.66, 0.53, 0.8 },
  JunkAway = { 0.85, 0.45, 0.3 },
}
local accent = ACCENTS[addonName] or ACCENTS.DustOrGold
Skin.accent = accent

-- The game's own gold (NORMAL_FONT_COLOR) for titles and headings.
local GOLD = { 1, 0.82, 0 }
Skin.gold = GOLD

-- Palette (r, g, b, a). Callers read button, border, panel and input.
local C = {
  bg = { 0.04, 0.04, 0.05, 0.95 },
  panel = { 0, 0, 0, 0.35 },
  border = { 0.5, 0.5, 0.5, 1 },
  edge = { 0.6, 0.6, 0.6, 1 },
  button = { 0.24, 0.07, 0.05, 1 },
  buttonDown = { 0.14, 0.04, 0.03, 1 },
  input = { 0, 0, 0, 0.5 },
  text = { 1, 1, 1 },
  muted = { 0.6, 0.6, 0.6 },
}
Skin.colors = C

local function color(tex, c, alpha)
  tex:SetColorTexture(c[1], c[2], c[3], alpha or c[4] or 1)
  return tex
end

local function fill(frame, layer, c, sublevel)
  local t = frame:CreateTexture(nil, layer, nil, sublevel)
  t:SetAllPoints(frame)
  return color(t, c)
end

-- A tiled texture over the frame, inset by `inset`.
local function tile(frame, path, layer, sublevel, inset)
  inset = inset or 0
  local t = frame:CreateTexture(nil, layer, nil, sublevel)
  t:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
  t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
  t:SetTexture(path, "REPEAT", "REPEAT")
  if t.SetHorizTile then t:SetHorizTile(true) end
  if t.SetVertTile then t:SetVertTile(true) end
  return t
end

-- A 1px frame of four textures around `around` (default: the frame itself);
-- returns them so callers can recolour.
local function edges(frame, layer, c, alpha, around)
  around = around or frame
  local list = {}
  for i, spec in ipairs({
    { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true },
    { "TOPLEFT", "BOTTOMLEFT", false }, { "TOPRIGHT", "BOTTOMRIGHT", false },
  }) do
    local t = frame:CreateTexture(nil, layer, nil, 7)
    t:SetPoint(spec[1], around, spec[1])
    t:SetPoint(spec[2], around, spec[2])
    if spec[3] then t:SetHeight(1) else t:SetWidth(1) end
    color(t, c, alpha)
    list[i] = t
  end
  return list
end
Skin.Edges = edges

-- The tooltip's border, drawn piece by piece as BackdropTemplate cuts its
-- edge file (eight squares in a strip; top and bottom lie on their side).
local S, E = 0.0625, 0.9375
local EDGE_UV = {
  { 0.5078125, S, 0.5078125, E, 0.6171875, S, 0.6171875, E }, -- top left
  { 0.6328125, S, 0.6328125, E, 0.7421875, S, 0.7421875, E }, -- top right
  { 0.7578125, S, 0.7578125, E, 0.8671875, S, 0.8671875, E }, -- bottom left
  { 0.8828125, S, 0.8828125, E, 0.9921875, S, 0.9921875, E }, -- bottom right
  { 0.2578125, E, 0.3671875, E, 0.2578125, S, 0.3671875, S }, -- top
  { 0.3828125, E, 0.4921875, E, 0.3828125, S, 0.4921875, S }, -- bottom
  { 0.0078125, S, 0.0078125, E, 0.1171875, S, 0.1171875, E }, -- left
  { 0.1328125, S, 0.1328125, E, 0.2421875, S, 0.2421875, E }, -- right
}
local function artEdge(frame, path, e, out, c, layer, sublevel)
  local p = {}
  for i = 1, 8 do
    local t = frame:CreateTexture(nil, layer or "BORDER", nil, sublevel or 0)
    t:SetTexture(path)
    t:SetTexCoord(unpack(EDGE_UV[i]))
    if c then t:SetVertexColor(c[1], c[2], c[3], c[4] or 1) end
    p[i] = t
  end
  p[1]:SetPoint("TOPLEFT", frame, "TOPLEFT", -out, out)
  p[2]:SetPoint("TOPRIGHT", frame, "TOPRIGHT", out, out)
  p[3]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -out, -out)
  p[4]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", out, -out)
  for i = 1, 4 do p[i]:SetSize(e, e) end
  p[5]:SetPoint("TOPLEFT", p[1], "TOPRIGHT"); p[5]:SetPoint("BOTTOMRIGHT", p[2], "BOTTOMLEFT")
  p[6]:SetPoint("TOPLEFT", p[3], "TOPRIGHT"); p[6]:SetPoint("BOTTOMRIGHT", p[4], "BOTTOMLEFT")
  p[7]:SetPoint("TOPLEFT", p[1], "BOTTOMLEFT"); p[7]:SetPoint("BOTTOMRIGHT", p[3], "TOPRIGHT")
  p[8]:SetPoint("TOPLEFT", p[2], "BOTTOMLEFT"); p[8]:SetPoint("BOTTOMRIGHT", p[4], "TOPRIGHT")
  return p
end

-- An inner box: a dark ground in the tooltip's grey border, as the game's
-- own inset boxes. `c` sets the ground colour (Skin.colors.input for text).
function Skin.Panel(frame, c)
  if frame.skinBg then return frame end
  c = c or C.panel
  local bg = tile(frame, TOOLTIP_TILE, "BACKGROUND", -8, 2)
  bg:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
  frame.skinBg = bg
  frame.skinBorder = artEdge(frame, TOOLTIP_EDGE, 12, 2, C.edge, "BORDER", 6)
  return frame
end

-- The game's close button (UIPanelCloseButton).
function Skin.CloseButton(parent, onClick)
  local b = Skin.Create("Button", nil, parent, "UIPanelCloseButton")
  b:SetSize(24, 24)
  if not b:GetNormalTexture() then
    b:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    b:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
  end
  b:SetScript("OnClick", onClick or function() parent:Hide() end)
  return b
end

-- A window made with TEMPLATES.Window: makes sure TitleText and
-- CloseButton exist (the template's own when it has them). Content keeps
-- its old anchors (first row about 30 below the top, 10 in from the sides).
-- opts.noClose hides the close button. A frame made without the template
-- gets a plain dark ground and border.
function Skin.Window(frame, opts)
  opts = opts or {}
  local templated = type(frame.Bg) == "table" or type(frame.TitleBg) == "table" or type(frame.Inset) == "table"
    or type(frame.NineSlice) == "table"
  if not templated then
    frame.skinBg = fill(frame, "BACKGROUND", C.bg, -8)
    frame.skinBorder = artEdge(frame, TOOLTIP_EDGE, 16, 0, C.edge, "BORDER", 0)
  end

  local title = type(frame.TitleText) == "table" and frame.TitleText or nil
  if not title and type(frame.TitleContainer) == "table" and type(frame.TitleContainer.TitleText) == "table" then
    title = frame.TitleContainer.TitleText
  end
  if not title then
    title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -5)
    title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
  end
  frame.TitleText = title

  local close = type(frame.CloseButton) == "table" and frame.CloseButton or nil
  if opts.noClose then
    if close then close:Hide() end
  elseif not close then
    close = Skin.CloseButton(frame)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 1)
    frame.CloseButton = close
  end
  return frame
end

-- A button made with TEMPLATES.Button (the game's red panel button):
-- the small fonts the addons' layouts were made for. SetText,
-- Enable/Disable and LockHighlight keep working.
function Skin.Button(b, opts)
  opts = opts or {}
  b.skinFont = opts.font or "GameFontNormalSmall"
  if not b:GetFontString() then
    local fs = b:CreateFontString(nil, "OVERLAY", b.skinFont)
    fs:SetPoint("CENTER", 0, 1)
    b:SetFontString(fs)
  end
  -- The template draws with Left/Middle/Right (newer clients) or a normal
  -- texture (older ones); with neither, the template was missing.
  local templated = type(b.Left) == "table" or type(b.Middle) == "table" or b:GetNormalTexture() ~= nil
  if not templated then
    -- No template: a plain dark button with a thin border.
    local ground = fill(b, "BACKGROUND", C.button, 0)
    b.skinGround = ground
    edges(b, "BORDER", C.border, 0.8)
    local lit = b:CreateTexture(nil, "HIGHLIGHT")
    lit:SetAllPoints()
    lit:SetColorTexture(1, 1, 1, 0.12)
  end
  b:SetNormalFontObject(b.skinFont)
  b:SetHighlightFontObject(opts.font or "GameFontHighlightSmall")
  b:SetDisabledFontObject("GameFontDisableSmall")
  return b
end

-- Shows a button as the chosen one of a group (tabs, modes): lit, white text.
function Skin.SetSelected(b, on)
  b.skinSelected = on and true or nil
  if on then
    if b.LockHighlight then b:LockHighlight() end
    b:SetNormalFontObject("GameFontHighlightSmall")
  else
    if b.UnlockHighlight then b:UnlockHighlight() end
    b:SetNormalFontObject(b.skinFont or "GameFontNormalSmall")
  end
end

-- A tick box made with TEMPLATES.Check; makes sure it has .Text.
function Skin.Check(cb, size)
  size = size or 24
  cb:SetSize(size, size)
  if not cb:GetNormalTexture() then
    cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
  end
  local text = type(cb.Text) == "table" and cb.Text or type(cb.text) == "table" and cb.text or nil
  if not text then
    local name = cb.GetName and cb:GetName()
    text = name and type(_G[name .. "Text"]) == "table" and _G[name .. "Text"] or nil
  end
  if not text then
    text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("LEFT", cb, "RIGHT", 2, 1)
  end
  cb.Text = text
  return cb
end

-- A single-line text box made with TEMPLATES.Input.
function Skin.Input(eb)
  if not eb:GetFontObject() then eb:SetFontObject(ChatFontNormal or "ChatFontNormal") end
  eb:SetAutoFocus(false)
  local hasArt = type(eb.Left) == "table" or type(eb.Middle) == "table"
  if not hasArt then
    local ground = eb:CreateTexture(nil, "BACKGROUND", nil, -8)
    ground:SetAllPoints()
    color(ground, C.input)
    edges(eb, "BORDER", C.border, 0.8)
    eb:SetTextInsets(6, 6, 2, 2)
  end
  eb:HookScript("OnEscapePressed", function(self) self:ClearFocus() end)
  return eb
end

-- UIPanelScrollFrameTemplate's own bar is the stock look: left as it is.
function Skin.ScrollBar(scroll, bar)
  return bar or scroll.ScrollBar
end

-- Section heading in the game's gold, with an optional faded rule to its
-- right.
function Skin.Heading(parent, text, withRule)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  if text then fs:SetText(text) end
  if withRule then
    local rule = parent:CreateTexture(nil, "BORDER")
    rule:SetPoint("LEFT", fs, "RIGHT", 6, 0)
    rule:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
    rule:SetHeight(1)
    rule:SetTexture(WHITE)
    if rule.SetGradient and CreateColor then
      pcall(rule.SetGradient, rule, "HORIZONTAL", CreateColor(GOLD[1], GOLD[2], GOLD[3], 0.5), CreateColor(GOLD[1], GOLD[2], GOLD[3], 0))
    else
      color(rule, C.border)
    end
    fs.rule = rule
  end
  return fs
end

-- The bottom-right resize grip, the chat frame's own.
function Skin.Grip(grip)
  grip:SetSize(16, 16)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  return grip
end

-- A 1px divider line.
function Skin.Divider(parent, layer)
  local t = parent:CreateTexture(nil, layer or "BORDER")
  t:SetHeight(1)
  return color(t, C.border, 0.45)
end

-- Row striping and hover for list rows (Buttons or Frames): the quest log's
-- title glow under the cursor, in the addon's accent.
function Skin.Row(row, index)
  local stripe = row:CreateTexture(nil, "BACKGROUND", nil, -8)
  stripe:SetAllPoints()
  color(stripe, { 1, 1, 1 }, (index or 0) % 2 == 0 and 0.035 or 0)
  row.skinStripe = stripe
  local hover = row:CreateTexture(nil, "HIGHLIGHT")
  hover:SetAllPoints()
  hover:SetTexture(ROW_LIT)
  hover:SetBlendMode("ADD")
  hover:SetVertexColor(accent[1], accent[2], accent[3], 0.6)
  return row
end

function Skin.StripeRow(row, index)
  if row.skinStripe then
    row.skinStripe:SetColorTexture(1, 1, 1, (index or 0) % 2 == 0 and 0.035 or 0)
  end
end
