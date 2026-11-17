-- Shared look for Robin's addons: warm dark panels, thin borders, one accent
-- colour per addon. The same file ships in every addon (DustOrGold,
-- FieldGuide, OpenSpot, RouteKeeper, WhosHiring); keep the copies identical.
--
-- Widgets are made without Blizzard templates and keep the field names the
-- templates had (TitleText, CloseButton, .Text, SetText), so callers only
-- swap the template for a Skin call.
local addonName, ns = ...

local Skin = {}
ns.Skin = Skin

local WHITE = "Interface\\Buttons\\WHITE8x8"
local TITLE_FONT = "Fonts\\FRIZQT__.TTF"

local ACCENTS = {
  DustOrGold = { 0.83, 0.66, 0.29 },
  FieldGuide = { 0.58, 0.72, 0.42 },
  RouteKeeper = { 0.82, 0.49, 0.27 },
  WhosHiring = { 0.42, 0.68, 0.64 },
  OpenSpot = { 0.47, 0.64, 0.86 },
}
local accent = ACCENTS[addonName] or ACCENTS.DustOrGold
Skin.accent = accent

-- Palette (r, g, b, a).
local C = {
  bg = { 0.075, 0.062, 0.05, 0.96 },
  bgTop = { 0.13, 0.105, 0.08, 0.9 },
  titleBar = { 0.05, 0.04, 0.032, 0.9 },
  panel = { 0.11, 0.09, 0.07, 0.85 },
  border = { 0.27, 0.22, 0.16, 1 },
  button = { 0.15, 0.12, 0.09, 1 },
  buttonDown = { 0.09, 0.075, 0.06, 1 },
  input = { 0.04, 0.035, 0.03, 0.95 },
  text = { 0.93, 0.89, 0.81 },
  muted = { 0.6, 0.55, 0.47 },
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

-- A 1px frame of four textures; returns them so callers can recolour.
local function edges(frame, layer, c, alpha)
  local list = {}
  for i, spec in ipairs({
    { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true },
    { "TOPLEFT", "BOTTOMLEFT", false }, { "TOPRIGHT", "BOTTOMRIGHT", false },
  }) do
    local t = frame:CreateTexture(nil, layer, nil, 7)
    t:SetPoint(spec[1], frame, spec[1])
    t:SetPoint(spec[2], frame, spec[2])
    if spec[3] then t:SetHeight(1) else t:SetWidth(1) end
    color(t, c, alpha)
    list[i] = t
  end
  return list
end
Skin.Edges = edges

local function recolor(list, c, alpha)
  for _, t in ipairs(list) do color(t, c, alpha) end
end

local function gradient(tex, top, bottom)
  if not (tex.SetGradient and CreateColor) then return end
  pcall(tex.SetGradient, tex, "VERTICAL",
    CreateColor(bottom[1], bottom[2], bottom[3], bottom[4]),
    CreateColor(top[1], top[2], top[3], top[4]))
end

-- A background and border on any frame (no BackdropTemplate needed).
function Skin.Panel(frame, c)
  if frame.skinBg then return frame end
  frame.skinBg = fill(frame, "BACKGROUND", c or C.panel, -8)
  frame.skinBorder = edges(frame, "BORDER", C.border)
  return frame
end

-- An X drawn with two thin bars; falls back to a letter.
local function drawCross(button, size)
  local bars = {}
  for i, angle in ipairs({ math.pi / 4, -math.pi / 4 }) do
    local t = button:CreateTexture(nil, "ARTWORK")
    t:SetPoint("CENTER")
    t:SetSize(size, 2)
    color(t, C.muted, 1)
    if t.SetRotation then t:SetRotation(angle) else t:Hide() end
    bars[i] = t
  end
  if not bars[1].SetRotation then
    local fs = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("CENTER")
    fs:SetText("x")
  end
  return bars
end

function Skin.CloseButton(parent, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(22, 22)
  local bars = drawCross(b, 12)
  local hover = b:CreateTexture(nil, "HIGHLIGHT")
  hover:SetAllPoints()
  color(hover, accent, 0.18)
  b:SetScript("OnClick", onClick or function() parent:Hide() end)
  b.bars = bars
  return b
end

-- Window chrome on a plain frame: background with a soft top light, a title
-- bar with an accent rule, TitleText and CloseButton. Pass the frame made
-- with "BackdropTemplate" (or none) in place of BasicFrameTemplateWithInset.
-- opts.noClose skips the close button; opts.titleHeight changes the bar.
function Skin.Window(frame, opts)
  opts = opts or {}
  local barH = opts.titleHeight or 24
  frame.skinBg = fill(frame, "BACKGROUND", C.bg, -8)
  local glow = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
  glow:SetPoint("TOPLEFT", 1, -barH)
  glow:SetPoint("TOPRIGHT", -1, -barH)
  glow:SetHeight(90)
  glow:SetTexture(WHITE)
  gradient(glow, C.bgTop, { C.bg[1], C.bg[2], C.bg[3], 0 })
  if not (glow.SetGradient and CreateColor) then glow:Hide() end

  local bar = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
  bar:SetPoint("TOPLEFT", 1, -1)
  bar:SetPoint("TOPRIGHT", -1, -1)
  bar:SetHeight(barH - 1)
  color(bar, C.titleBar)
  local rule = frame:CreateTexture(nil, "BORDER")
  rule:SetPoint("TOPLEFT", 1, -barH)
  rule:SetPoint("TOPRIGHT", -1, -barH)
  rule:SetHeight(1)
  color(rule, accent, 0.55)
  frame.skinBorder = edges(frame, "BORDER", C.border)

  local title = frame:CreateFontString(nil, "OVERLAY")
  title:SetFont(TITLE_FONT, 12, "")
  title:SetShadowOffset(1, -1)
  title:SetTextColor(accent[1], accent[2], accent[3])
  title:SetPoint("LEFT", frame, "TOPLEFT", 10, -barH / 2)
  title:SetPoint("RIGHT", frame, "TOPRIGHT", -30, -barH / 2)
  title:SetJustifyH("LEFT")
  frame.TitleText = title
  frame.skinTitleHeight = barH

  if not opts.noClose then
    local close = Skin.CloseButton(frame)
    close:SetPoint("TOPRIGHT", -2, -1 - (barH - 23) / 2)
    frame.CloseButton = close
  end
  return frame
end

-- A flat button. Use on a Button made without UIPanelButtonTemplate; SetText,
-- Enable/Disable and LockHighlight keep working.
function Skin.Button(b, opts)
  opts = opts or {}
  b.skinBg = fill(b, "BACKGROUND", C.button)
  b.skinBorder = edges(b, "OVERLAY", C.border)
  local hover = edges(b, "HIGHLIGHT", accent, 0.9)
  local wash = b:CreateTexture(nil, "HIGHLIGHT")
  wash:SetAllPoints()
  color(wash, accent, 0.08)
  local pushed = b:CreateTexture(nil, "BORDER")
  pushed:SetAllPoints()
  color(pushed, C.buttonDown)
  b:SetPushedTexture(pushed)
  b.skinHover = hover

  local fs = b:CreateFontString(nil, "OVERLAY", opts.font or "GameFontHighlightSmall")
  fs:SetPoint("CENTER")
  b:SetFontString(fs)
  b:SetNormalFontObject(opts.font or "GameFontHighlightSmall")
  b:SetHighlightFontObject(opts.font or "GameFontHighlightSmall")
  b:SetDisabledFontObject("GameFontDisableSmall")
  if b.SetPushedTextOffset then b:SetPushedTextOffset(0, -1) end
  return b
end

-- Shows a button as the chosen one of a group (tabs, modes).
function Skin.SetSelected(b, on)
  if not b.skinBorder then return end
  if on then
    recolor(b.skinBorder, accent, 1)
    color(b.skinBg, { accent[1] * 0.3, accent[2] * 0.3, accent[3] * 0.3, 1 })
    local fs = b.GetFontString and b:GetFontString()
    if type(fs) == "table" and fs.SetTextColor then fs:SetTextColor(accent[1], accent[2], accent[3]) end
  else
    recolor(b.skinBorder, C.border)
    color(b.skinBg, C.button)
    local fs = b.GetFontString and b:GetFontString()
    if type(fs) == "table" and fs.SetTextColor then fs:SetTextColor(C.text[1], C.text[2], C.text[3]) end
  end
end

-- A flat tick box. Use on a CheckButton made without UICheckButtonTemplate;
-- gives it .Text like the template had.
function Skin.Check(cb, size)
  size = size or 24
  cb:SetSize(size, size)
  local box = CreateFrame("Frame", nil, cb)
  box:SetSize(14, 14)
  box:SetPoint("CENTER")
  fill(box, "BACKGROUND", C.input)
  local border = edges(box, "BORDER", C.border)
  local tick = cb:CreateTexture(nil, "ARTWORK")
  tick:SetPoint("TOPLEFT", box, "TOPLEFT", 3, -3)
  tick:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -3, 3)
  color(tick, accent, 1)
  cb:SetCheckedTexture(tick)
  local disabledTick = cb:CreateTexture(nil, "ARTWORK")
  disabledTick:SetAllPoints(tick)
  color(disabledTick, C.muted, 0.6)
  cb:SetDisabledCheckedTexture(disabledTick)
  local hover = cb:CreateTexture(nil, "HIGHLIGHT")
  hover:SetPoint("TOPLEFT", box, "TOPLEFT", 1, -1)
  hover:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -1, 1)
  color(hover, accent, 0.25)
  cb.skinBox, cb.skinBorder = box, border

  local text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
  cb.Text = text
  return cb
end

-- A flat text box. Use on an EditBox made without InputBoxTemplate.
function Skin.Input(eb)
  Skin.Panel(eb, C.input)
  eb:SetFontObject(ChatFontNormal or "ChatFontNormal")
  eb:SetTextInsets(6, 6, 2, 2)
  eb:SetAutoFocus(false)
  local focus = edges(eb, "OVERLAY", accent, 0.8)
  for _, t in ipairs(focus) do t:Hide() end
  eb:HookScript("OnEditFocusGained", function() for _, t in ipairs(focus) do t:Show() end end)
  eb:HookScript("OnEditFocusLost", function() for _, t in ipairs(focus) do t:Hide() end end)
  eb:HookScript("OnEscapePressed", function(self) self:ClearFocus() end)
  return eb
end

-- Slims the scroll bar of a UIPanelScrollFrameTemplate: no arrows, a thin
-- track and an accent thumb. Leaves the bar alone if it isn't the shape
-- this expects.
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
  bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 6, 0)
  bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 6, 0)
  bar:SetWidth(6)
  local track = bar:CreateTexture(nil, "BACKGROUND", nil, -8)
  track:SetAllPoints()
  color(track, C.input, 0.8)
  if bar.SetThumbTexture then
    bar:SetThumbTexture(WHITE)
    local thumb = bar.GetThumbTexture and bar:GetThumbTexture()
    if type(thumb) == "table" and thumb.SetVertexColor then
      thumb:SetVertexColor(accent[1], accent[2], accent[3], 0.75)
      thumb:SetSize(6, 28)
      thumb:SetAlpha(1)
    end
  end
  bar.skinTrack = track
  return bar
end

-- Section heading in the accent colour, with an optional rule to its right.
function Skin.Heading(parent, text, withRule)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetFont(TITLE_FONT, 11, "")
  fs:SetShadowOffset(1, -1)
  fs:SetTextColor(accent[1], accent[2], accent[3])
  if text then fs:SetText(text) end
  if withRule then
    local rule = parent:CreateTexture(nil, "BORDER")
    rule:SetPoint("LEFT", fs, "RIGHT", 6, 0)
    rule:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
    rule:SetHeight(1)
    color(rule, C.border)
    fs.rule = rule
  end
  return fs
end

-- The bottom-right resize grip, tinted to match. Scripts stay the caller's.
function Skin.Grip(grip)
  grip:SetSize(14, 14)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture" }) do
    local t = grip[get] and grip[get](grip)
    if type(t) == "table" and t.SetDesaturated then
      t:SetDesaturated(true)
      t:SetVertexColor(accent[1], accent[2], accent[3], 0.8)
    end
  end
  return grip
end

-- A 1px divider line.
function Skin.Divider(parent, layer)
  local t = parent:CreateTexture(nil, layer or "BORDER")
  t:SetHeight(1)
  return color(t, C.border)
end

-- Row striping and hover for list rows (Buttons or Frames).
function Skin.Row(row, index)
  local stripe = row:CreateTexture(nil, "BACKGROUND", nil, -8)
  stripe:SetAllPoints()
  color(stripe, { 1, 0.9, 0.7 }, (index or 0) % 2 == 0 and 0.03 or 0)
  row.skinStripe = stripe
  local hover = row:CreateTexture(nil, "HIGHLIGHT")
  hover:SetAllPoints()
  color(hover, accent, 0.1)
  return row
end

function Skin.StripeRow(row, index)
  if row.skinStripe then
    row.skinStripe:SetColorTexture(1, 0.9, 0.7, (index or 0) % 2 == 0 and 0.03 or 0)
  end
end
