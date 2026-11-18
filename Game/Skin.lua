-- Shared look for Robin's addons: the classic game art. Stone dialog border
-- round the quest log's parchment (toned down so light text reads on it), the gold header plate for the title, red panel
-- buttons, the stock tick boxes, text box and scroll knob, tooltip-bordered
-- inner panels. The same file ships in every addon (DustOrGold, FieldGuide,
-- OpenSpot, RouteKeeper, WhosHiring); keep the copies identical.
--
-- Every piece is a texture drawn on the frame itself (no BackdropTemplate),
-- cut from the vanilla files the way the client's templates cut them; the
-- coordinates follow Polestar_Looks, which draws the same files on Forever.
--
-- Widgets are made without Blizzard templates and keep the field names the
-- templates had (TitleText, CloseButton, .Text, SetText), so callers only
-- swap the template for a Skin call. Each addon keeps an accent colour
-- (ACCENTS) for its own small marks: row hover, chosen chips, badges.
local addonName, ns = ...

local Skin = {}
ns.Skin = Skin

local WHITE = "Interface\\Buttons\\WHITE8x8"
local DIALOG_EDGE = "Interface\\DialogFrame\\UI-DialogBox-Border"
local PARCHMENT = "Interface\\QuestFrame\\QuestBG"
local HEADER = "Interface\\DialogFrame\\UI-DialogBox-Header"
local TOOLTIP_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
local TOOLTIP_TILE = "Interface\\Tooltips\\UI-Tooltip-Background"
local PANEL_UP = "Interface\\Buttons\\UI-Panel-Button-Up"
local PANEL_DOWN = "Interface\\Buttons\\UI-Panel-Button-Down"
local PANEL_DISABLED = "Interface\\Buttons\\UI-Panel-Button-Disabled"
local PANEL_LIT = "Interface\\Buttons\\UI-Panel-Button-Highlight"
local INPUT = "Interface\\Common\\Common-Input-Border"
local ROW_LIT = "Interface\\QuestFrame\\UI-QuestTitleHighlight"

local ACCENTS = {
  DustOrGold = { 0.83, 0.66, 0.29 },
  FieldGuide = { 0.58, 0.72, 0.42 },
  RouteKeeper = { 0.82, 0.49, 0.27 },
  WhosHiring = { 0.42, 0.68, 0.64 },
  OpenSpot = { 0.47, 0.64, 0.86 },
}
local accent = ACCENTS[addonName] or ACCENTS.DustOrGold
Skin.accent = accent

-- The game's own gold (NORMAL_FONT_COLOR) for titles and headings.
local GOLD = { 1, 0.82, 0 }
Skin.gold = GOLD

-- How bright the parchment is drawn (the file's own colours times this):
-- 1 is the quest log's page; lower keeps white and gold text readable.
local PARCHMENT_TINT = { 0.5, 0.45, 0.38 }

-- Palette (r, g, b, a). Callers read button, border, panel and input.
local C = {
  bg = { 0.05, 0.035, 0.02, 1 },
  panel = { 0.1, 0.07, 0.04, 0.6 },
  border = { 0.45, 0.4, 0.32, 1 },
  edge = { 0.7, 0.58, 0.4, 1 },
  button = { 0.24, 0.07, 0.05, 1 },
  buttonDown = { 0.14, 0.04, 0.03, 1 },
  input = { 0.06, 0.045, 0.03, 0.72 },
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

-- A tiled texture over `around` (default: the frame), inset by `inset`.
local function tile(frame, path, layer, sublevel, inset, around)
  around, inset = around or frame, inset or 0
  local t = frame:CreateTexture(nil, layer, nil, sublevel)
  t:SetPoint("TOPLEFT", around, "TOPLEFT", inset, -inset)
  t:SetPoint("BOTTOMRIGHT", around, "BOTTOMRIGHT", -inset, inset)
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

-- A vanilla backdrop edge, drawn piece by piece as BackdropTemplate cuts its
-- edge file: eight squares in a strip (left, right, top, bottom, then the
-- corners); the top and bottom squares lie on their side, so they take the
-- eight-number form of SetTexCoord. Corners `e` a side, moved `out` past the
-- frame's corners; the edges stretched between.
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

-- Three pieces across the frame: fixed-width ends cut from one file at
-- u-coordinates cuts[1] and cuts[2], the middle stretched; the art runs from
-- cuts.start (default 0) to cuts[3] (default 1).
local function threePiece(frame, path, capW, cuts, v0, v1, layer, sublevel)
  local p = {}
  local us = { { cuts.start or 0, cuts[1] }, { cuts[1], cuts[2] }, { cuts[2], cuts[3] or 1 } }
  for i = 1, 3 do
    local t = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
    if path then t:SetTexture(path) end
    t:SetTexCoord(us[i][1], us[i][2], v0 or 0, v1 or 1)
    p[i] = t
  end
  p[1]:SetPoint("TOPLEFT"); p[1]:SetPoint("BOTTOMLEFT"); p[1]:SetWidth(capW)
  p[3]:SetPoint("TOPRIGHT"); p[3]:SetPoint("BOTTOMRIGHT"); p[3]:SetWidth(capW)
  p[2]:SetPoint("TOPLEFT", p[1], "TOPRIGHT"); p[2]:SetPoint("BOTTOMRIGHT", p[3], "BOTTOMLEFT")
  return p
end

-- An inner box: a dark ground in the tooltip's rounded grey border.
-- `c` sets the ground colour (Skin.colors.input for text areas).
function Skin.Panel(frame, c)
  if frame.skinBg then return frame end
  c = c or C.panel
  local bg = tile(frame, TOOLTIP_TILE, "BACKGROUND", -8, 2)
  bg:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
  frame.skinBg = bg
  frame.skinBorder = artEdge(frame, TOOLTIP_EDGE, 12, 2, C.edge, "BORDER", 6)
  return frame
end

-- The round red-framed close button of the game's panels.
function Skin.CloseButton(parent, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(28, 28)
  b:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
  b:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
  b:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
  b:SetScript("OnClick", onClick or function() parent:Hide() end)
  return b
end

-- Window chrome on a plain frame: the stone dialog border just outside the
-- frame, a parchment ground shaded at its edges, the gold header plate on the top edge holding
-- TitleText, and CloseButton. Content keeps its old anchors (first row about
-- 30 below the top, 10 in from the sides).
-- opts.noClose skips the close button.
local BORDER_E, BORDER_OUT = 24, 6
function Skin.Window(frame, opts)
  opts = opts or {}
  frame.skinBg = fill(frame, "BACKGROUND", C.bg, -8)
  local page = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
  page:SetPoint("TOPLEFT", 2, -2)
  page:SetPoint("BOTTOMRIGHT", -2, 2)
  page:SetTexture(PARCHMENT)
  -- The page fills only the top-left 0.58 x 0.66 of QuestBG, burnt at its
  -- right and bottom ends: stretch the clean part (measured in the client).
  page:SetTexCoord(0, 0.55, 0, 0.62)
  page:SetVertexColor(PARCHMENT_TINT[1], PARCHMENT_TINT[2], PARCHMENT_TINT[3], 1)
  frame.skinPage = page
  -- Darker towards the edges, as an old page is. Each band runs from the
  -- frame's side inwards; SetGradient goes from its first colour (bottom or
  -- left) to its second.
  if CreateColor then
    local dark, clear = CreateColor(0.04, 0.025, 0.01, 0.6), CreateColor(0.04, 0.025, 0.01, 0)
    for _, spec in ipairs({
      { "TOPLEFT", 2, -2, "TOPRIGHT", -2, -2, "VERTICAL", 70, clear, dark },
      { "BOTTOMLEFT", 2, 2, "BOTTOMRIGHT", -2, 2, "VERTICAL", 50, dark, clear },
      { "TOPLEFT", 2, -2, "BOTTOMLEFT", 2, 2, "HORIZONTAL", 40, dark, clear },
      { "TOPRIGHT", -2, -2, "BOTTOMRIGHT", -2, 2, "HORIZONTAL", 40, clear, dark },
    }) do
      local t = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
      t:SetPoint(spec[1], spec[2], spec[3])
      t:SetPoint(spec[4], spec[5], spec[6])
      if spec[7] == "VERTICAL" then t:SetHeight(spec[8]) else t:SetWidth(spec[8]) end
      t:SetTexture(WHITE)
      if not (t.SetGradient and pcall(t.SetGradient, t, spec[7], spec[9], spec[10])) then t:Hide() end
    end
  end
  frame.skinBorder = artEdge(frame, DIALOG_EDGE, BORDER_E, BORDER_OUT, nil, "BORDER", 0)
  if frame.SetClampRectInsets then frame:SetClampRectInsets(-BORDER_OUT, BORDER_OUT, 14, -BORDER_OUT) end

  -- The header bracket (the grey metal plate with spiked ends). In its
  -- 256 x 64 file the art spans columns 0.227-0.758 and the top 0.44
  -- (measured in the client); the spiked ends are kept 20 wide, the middle
  -- stretched to the title. It straddles the top edge, as the game's
  -- dialogs place it (TOP + 14), with the title inside it.
  local plate = CreateFrame("Frame", nil, frame)
  plate:SetHeight(28)
  plate:SetPoint("TOP", frame, "TOP", 0, 14)
  plate:SetWidth(140)
  if plate.SetFrameLevel and frame.GetFrameLevel then plate:SetFrameLevel((frame:GetFrameLevel() or 0) + 5) end
  plate.parts = threePiece(plate, HEADER, 20, { 0.305, 0.68, 0.758, start = 0.227 }, 0, 0.44, "ARTWORK", 0)
  frame.skinHeader = plate

  local title = plate:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("CENTER", plate, "CENTER", 0, -2)
  title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
  frame.TitleText = title
  local function fit()
    local w = title.GetStringWidth and title:GetStringWidth() or 0
    if type(w) ~= "number" then w = 0 end
    local most = (frame.GetWidth and frame:GetWidth() or 0)
    if type(most) ~= "number" or most <= 0 then most = 600 end
    plate:SetWidth(math.max(120, math.min(w + 64, most - 60)))
  end
  if hooksecurefunc then hooksecurefunc(title, "SetText", fit) end
  fit()

  if not opts.noClose then
    local close = Skin.CloseButton(frame)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 3, 3)
    if close.SetFrameLevel and frame.GetFrameLevel then close:SetFrameLevel((frame:GetFrameLevel() or 0) + 6) end
    frame.CloseButton = close
  end
  return frame
end

-- The red panel button (UIPanelButtonTemplate's art: left 12, stretched
-- middle, right 12 of UI-Panel-Button-*). Use on a Button made without the
-- template; SetText, Enable/Disable and LockHighlight keep working.
local function paintButton(b)
  local file = PANEL_UP
  if b.IsEnabled and not b:IsEnabled() then
    file = PANEL_DISABLED
  elseif b.skinDown or b.skinSelected then
    file = PANEL_DOWN
  end
  for i = 1, 3 do b.skinParts[i]:SetTexture(file) end
end

function Skin.Button(b, opts)
  opts = opts or {}
  b.skinParts = threePiece(b, PANEL_UP, 12, { 0.09375, 0.53125, 0.625 }, 0, 0.6875, "BACKGROUND", 0)
  local lit = b:CreateTexture(nil, "HIGHLIGHT")
  lit:SetTexture(PANEL_LIT)
  lit:SetTexCoord(0, 0.625, 0, 0.6875)
  lit:SetBlendMode("ADD")
  lit:SetAllPoints()
  b.skinLit = lit
  paintButton(b)
  b:HookScript("OnMouseDown", function(self)
    if not (self.IsEnabled and not self:IsEnabled()) then self.skinDown = true; paintButton(self) end
  end)
  b:HookScript("OnMouseUp", function(self) self.skinDown = nil; paintButton(self) end)
  b:HookScript("OnHide", function(self) self.skinDown = nil; paintButton(self) end)
  b:HookScript("OnEnable", paintButton)
  b:HookScript("OnDisable", paintButton)

  b.skinFont = opts.font or "GameFontNormalSmall"
  local fs = b:CreateFontString(nil, "OVERLAY", b.skinFont)
  fs:SetPoint("CENTER", 0, 1)
  b:SetFontString(fs)
  b:SetNormalFontObject(b.skinFont)
  b:SetHighlightFontObject(opts.font or "GameFontHighlightSmall")
  b:SetDisabledFontObject("GameFontDisableSmall")
  if b.SetPushedTextOffset then b:SetPushedTextOffset(1, -1) end
  return b
end

-- Shows a button as the chosen one of a group (tabs, modes): pressed in,
-- lit, white text.
function Skin.SetSelected(b, on)
  if not b.skinParts then return end
  b.skinSelected = on and true or nil
  paintButton(b)
  if on then
    if b.LockHighlight then b:LockHighlight() end
    b:SetNormalFontObject("GameFontHighlightSmall")
  else
    if b.UnlockHighlight then b:UnlockHighlight() end
    b:SetNormalFontObject(b.skinFont or "GameFontNormalSmall")
  end
end

-- The game's tick box. Use on a CheckButton made without
-- UICheckButtonTemplate; gives it .Text like the template had. The art is
-- the check button's own textures, so the tick always draws above the box.
function Skin.Check(cb, size)
  size = size or 24
  cb:SetSize(size, size)
  cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
  cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
  cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
  cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
  local off = cb:CreateTexture(nil, "ARTWORK")
  off:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
  off:SetAllPoints()
  if off.SetDesaturated then off:SetDesaturated(true) end
  off:SetVertexColor(0.6, 0.6, 0.6, 0.8)
  cb:SetDisabledCheckedTexture(off)

  local text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  text:SetPoint("LEFT", cb, "RIGHT", 2, 1)
  cb.Text = text
  return cb
end

-- The game's text box (InputBoxTemplate's rounded field, its 8-wide ends
-- and stretched middle). Use on a single-line EditBox made without the
-- template.
function Skin.Input(eb)
  local p = threePiece(eb, INPUT, 8, { 8 / 128, 120 / 128 }, 0, 20 / 32, "BACKGROUND", 0)
  local ground = eb:CreateTexture(nil, "BACKGROUND", nil, -8)
  ground:SetPoint("TOPLEFT", 3, -3)
  ground:SetPoint("BOTTOMRIGHT", -3, 3)
  color(ground, C.input)
  eb.skinBg, eb.skinParts = ground, p
  eb:SetFontObject(ChatFontNormal or "ChatFontNormal")
  eb:SetTextInsets(7, 7, 2, 2)
  eb:SetAutoFocus(false)
  local function lit(on)
    for i = 1, 3 do
      if on then p[i]:SetVertexColor(1, 0.9, 0.6) else p[i]:SetVertexColor(1, 1, 1) end
    end
  end
  eb:HookScript("OnEditFocusGained", function() lit(true) end)
  eb:HookScript("OnEditFocusLost", function() lit(false) end)
  eb:HookScript("OnEscapePressed", function(self) self:ClearFocus() end)
  return eb
end

-- Restyles the scroll bar of a UIPanelScrollFrameTemplate: no arrows, a
-- dark rounded track and the game's gold scroll knob. Leaves the bar alone
-- if it isn't the shape this expects.
function Skin.ScrollBar(scroll, bar)
  bar = bar or scroll.ScrollBar
  if type(bar) ~= "table" or not bar.GetRegions then return end
  for _, r in ipairs({ bar:GetRegions() }) do
    if type(r) == "table" and r.GetObjectType and r:GetObjectType() == "Texture" then r:SetAlpha(0) end
  end
  for _, key in ipairs({ "ScrollUpButton", "ScrollDownButton" }) do
    local arrow = bar[key]
    if type(arrow) == "table" and arrow.SetAlpha then
      arrow:SetAlpha(0)
      arrow:SetSize(1, 1)
      if arrow.EnableMouse then arrow:EnableMouse(false) end
    end
  end
  bar:ClearAllPoints()
  bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 5, 0)
  bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 5, 0)
  bar:SetWidth(10)
  local track = bar:CreateTexture(nil, "BACKGROUND", nil, -8)
  track:SetPoint("TOPLEFT", 1, 0)
  track:SetPoint("BOTTOMRIGHT", -1, 0)
  color(track, C.input, 0.7)
  local rim = edges(bar, "BACKGROUND", C.border, 0.6, track)
  if bar.SetThumbTexture then
    bar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    local thumb = bar.GetThumbTexture and bar:GetThumbTexture()
    if type(thumb) == "table" then
      if thumb.SetTexCoord then thumb:SetTexCoord(0.25, 0.75, 0.25, 0.75) end
      if thumb.SetSize then thumb:SetSize(10, 18) end
      if thumb.SetAlpha then thumb:SetAlpha(1) end
    end
  end
  bar.skinTrack, bar.skinRim = track, rim
  return bar
end

-- Section heading in the game's gold, with an optional faded rule to its
-- right.
function Skin.Heading(parent, text, withRule)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
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

-- A 1px divider line in the border's muted gold.
function Skin.Divider(parent, layer)
  local t = parent:CreateTexture(nil, layer or "BORDER")
  t:SetHeight(1)
  return color(t, C.border, 0.7)
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
