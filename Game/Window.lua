-- The list window: one row per guild entry, newest first.
local addonName, ns = ...

local L = ns.L

local Window = {}
ns.Window = Window

local WIDTH, HEIGHT = 560, 520
local MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT = 400, 260, 1400, 1200
local ROW_HEIGHT, ROW_GAP = 56, 4
local SCROLL_INSET = 44 -- frame width minus the scroll child's width
local FRAME_NAME = "WhosHiringFrame"

local frame, content, emptyText
local rows = {}
local expanded = {} -- row id -> true while open (this session only)

-- "Bob" from "Bob-Realm".
local function shortName(sender)
  return (sender:match("^[^-]+")) or sender
end

local function saveLayout()
  local point, _, relativePoint, x, y = frame:GetPoint()
  ns.db.window = {
    width = math.floor(frame:GetWidth() + 0.5), height = math.floor(frame:GetHeight() + 0.5),
    point = point, relativePoint = relativePoint, x = x, y = y,
  }
end

local function restoreLayout()
  local saved = ns.db.window
  local width = saved and saved.width and math.min(math.max(saved.width, MIN_WIDTH), MAX_WIDTH) or WIDTH
  local height = saved and saved.height and math.min(math.max(saved.height, MIN_HEIGHT), MAX_HEIGHT) or HEIGHT
  frame:SetSize(width, height)
  frame:ClearAllPoints()
  if saved and saved.point and saved.x and saved.y then
    frame:SetPoint(saved.point, UIParent, saved.relativePoint or saved.point, saved.x, saved.y)
  else
    frame:SetPoint("CENTER")
  end
end

-- Clicking a row opens or closes its poster list.
local function toggle(row)
  local key = row.data and row.data.id
  if key then
    expanded[key] = not expanded[key] or nil
    Window.Refresh()
  end
end

local function newRow()
  local row = CreateFrame("Button", nil, content)
  row:SetHeight(ROW_HEIGHT)

  local bg = row:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(1, 1, 1, 0.04)
  local highlight = row:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetColorTexture(1, 1, 1, 0.08)

  row.nameText = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  row.nameText:SetPoint("TOPLEFT", 6, -4)
  row.nameText:SetJustifyH("LEFT")

  row.metaText = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  row.metaText:SetPoint("TOPRIGHT", -6, -5)
  row.metaText:SetJustifyH("RIGHT")
  row.nameText:SetPoint("RIGHT", row.metaText, "LEFT", -8, 0)

  -- Tags, coloured by group; hovering explains which word set each one.
  row.tagText = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  row.tagText:SetPoint("TOPLEFT", row.nameText, "BOTTOMLEFT", 0, -3)
  row.tagText:SetPoint("RIGHT", -6, 0)
  row.tagText:SetJustifyH("LEFT")
  row.tagText:SetWordWrap(false)
  row.tagHit = CreateFrame("Frame", nil, row)
  row.tagHit:SetPoint("TOPLEFT", row.tagText, "TOPLEFT")
  row.tagHit:SetPoint("BOTTOMRIGHT", row.tagText, "BOTTOMRIGHT")
  row.tagHit:EnableMouse(true)
  row.tagHit:SetScript("OnEnter", function(self) Window.ShowTagTooltip(self, row.data) end)
  row.tagHit:SetScript("OnLeave", function() GameTooltip:Hide() end)
  row.tagHit:SetScript("OnMouseUp", function() toggle(row) end)

  row.messageText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  row.messageText:SetPoint("TOPLEFT", row.tagText, "BOTTOMLEFT", 0, -3)
  row.messageText:SetPoint("RIGHT", -6, 0)
  row.messageText:SetJustifyH("LEFT")
  row.messageText:SetWordWrap(false)

  row.detailLines = {} -- reused widgets of the expanded part
  row:RegisterForClicks("LeftButtonUp")
  row:SetScript("OnClick", toggle)
  return row
end

-- "Night Watch", or "Unknown guild, posted by Bob" (realm left off).
function Window.DisplayName(r)
  if r.name then return r.name end
  return L.UNKNOWN_GUILD:format(shortName(r.unknownPoster or "?"))
end

local function ageText(seconds)
  local age = ns.Query.age(math.max(seconds, 0))
  return age == "now" and L.SEEN_NOW or L.SEEN:format(age)
end

local function meta(r, now)
  local posters = r.posters == 1 and L.POSTERS_ONE or L.POSTERS_MANY:format(r.posters)
  return posters .. " · " .. ageText(now - (r.lastSeen or now))
end

-- Colour per tag group, so the line reads at a glance.
local GROUP_COLORS = {
  focus = "ffd100", intensity = "ff8040", wants = "40c0ff",
  schedule = "a0e080", language = "d0a0ff", other = "c0c0c0",
}

function Window.TagLine(tags)
  local parts = {}
  for _, t in ipairs(tags) do
    parts[#parts + 1] = "|cff" .. (GROUP_COLORS[t.group] or "ffffff") .. t.label .. "|r"
  end
  return table.concat(parts, "  ")
end

function Window.ShowTagTooltip(owner, r)
  if not r or #r.tags == 0 then return end
  GameTooltip:SetOwner(owner, "ANCHOR_TOPLEFT")
  GameTooltip:AddLine(L.TAGS_TOOLTIP_TITLE)
  for _, t in ipairs(r.tags) do
    GameTooltip:AddDoubleLine(t.label, L.TAG_FROM:format(t.word), 1, 1, 1, 0.7, 0.7, 0.7)
  end
  GameTooltip:Show()
end

-- Opens a whisper to a poster in the chat edit box.
function Window.Whisper(sender)
  if ChatFrame_SendTell then
    ChatFrame_SendTell(sender)
  elseif ChatFrameUtil and ChatFrameUtil.SendTell then
    ChatFrameUtil.SendTell(sender)
  elseif ChatFrame_OpenChat then
    ChatFrame_OpenChat("/w " .. sender .. " ")
  end
end

-- One widget of the expanded part: a poster header or one of their messages.
local function detailLine(row, index)
  local line = row.detailLines[index]
  if line then return line end
  line = CreateFrame("Frame", nil, row)
  line.text = line:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  line.text:SetPoint("TOPLEFT", 0, 0)
  line.text:SetPoint("RIGHT", line, "RIGHT", -84, 0)
  line.text:SetJustifyH("LEFT")
  line.whisper = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
  line.whisper:SetSize(76, 18)
  line.whisper:SetPoint("TOPRIGHT", 0, 2)
  line.whisper:SetText(L.WHISPER)
  line.whisper:SetScript("OnClick", function(self) Window.Whisper(self.sender) end)
  row.detailLines[index] = line
  return line
end

-- Lays out every poster and their messages below the row; returns the height.
local function fillDetails(row, r, now, width)
  local used, y = 0, ROW_HEIGHT - 14 -- the message line is hidden when open
  for _, poster in ipairs(ns.Store.posters(r.entry)) do
    used = used + 1
    local header = detailLine(row, used)
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", row, "TOPLEFT", 14, -y)
    header:SetSize(width - 20, 18)
    header.text:SetText(L.POSTER_LINE:format(shortName(poster.sender), poster.messages[1].channel or "",
      ageText(now - poster.lastSeen)))
    header.text:SetFontObject("GameFontNormalSmall")
    header.whisper.sender = poster.sender
    header.whisper:Show()
    header:Show()
    y = y + 20
    for _, m in ipairs(poster.messages) do
      used = used + 1
      local line = detailLine(row, used)
      line:ClearAllPoints()
      line:SetPoint("TOPLEFT", row, "TOPLEFT", 24, -y)
      line.text:SetFontObject("GameFontHighlightSmall")
      line.text:SetWidth(width - 34)
      line.text:SetWordWrap(true)
      line.text:SetText(m.count > 1 and (m.text .. "  " .. L.REPEATS:format(m.count)) or m.text)
      local height = math.max((line.text:GetStringHeight() or 0) + 4, 14)
      line:SetSize(width - 34, height)
      line.whisper:Hide()
      line:Show()
      y = y + height
    end
    y = y + 4
  end
  for i = used + 1, #row.detailLines do row.detailLines[i]:Hide() end
  return y + 2
end

function Window.Refresh()
  if not frame or not frame:IsShown() then return end
  local now = time()
  local list = ns.Query.list(ns.db, { now = now })
  local width = content:GetWidth()
  local y = 0
  for i, r in ipairs(list) do
    local row = rows[i] or newRow()
    rows[i] = row
    row.data = r
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
    row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    row.nameText:SetText(Window.DisplayName(r))
    row.metaText:SetText(meta(r, now))
    row.messageText:SetText(r.message)
    row.tagText:SetText(#r.tags > 0 and Window.TagLine(r.tags) or L.NO_TAGS)
    local height = ROW_HEIGHT
    if expanded[r.id] then
      row.messageText:Hide()
      height = fillDetails(row, r, now, width)
    else
      row.messageText:Show()
      for _, line in ipairs(row.detailLines) do line:Hide() end
    end
    row:SetHeight(height)
    row:Show()
    y = y + height + ROW_GAP
  end
  for i = #list + 1, #rows do rows[i]:Hide() end
  content:SetHeight(math.max(y, 1))
  emptyText:SetShown(#list == 0)
end

local function build()
  frame = CreateFrame("Frame", FRAME_NAME, UIParent, "BasicFrameTemplateWithInset")
  frame:SetFrameStrata("HIGH")
  frame:SetMovable(true)
  frame:SetResizable(true)
  if frame.SetResizeBounds then frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT) end
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    saveLayout()
  end)
  frame:SetClampedToScreen(true)
  restoreLayout()
  if type(frame.TitleText) == "table" then frame.TitleText:SetText(L.TITLE) end
  tinsert(UISpecialFrames, FRAME_NAME) -- Escape closes it

  -- Drag the bottom-right corner to resize.
  local grip = CreateFrame("Button", nil, frame)
  grip:SetSize(16, 16)
  grip:SetPoint("BOTTOMRIGHT", -4, 4)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  grip:SetScript("OnMouseDown", function()
    -- Anchored by its centre, the window would grow on both sides at once.
    local left, top = frame:GetLeft(), frame:GetTop()
    if left and top then
      frame:ClearAllPoints()
      frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    end
    frame:StartSizing("BOTTOMRIGHT")
  end)
  grip:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing()
    saveLayout()
    Window.Refresh()
  end)

  local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 12, -32)
  scroll:SetPoint("BOTTOMRIGHT", -32, 24)
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(frame:GetWidth() - SCROLL_INSET, 1)
  scroll:SetScrollChild(content)
  frame:SetScript("OnSizeChanged", function(self, width)
    content:SetWidth(math.max((width or self:GetWidth()) - SCROLL_INSET, 1))
  end)

  emptyText = frame:CreateFontString(nil, "ARTWORK", "GameFontDisable")
  emptyText:SetPoint("CENTER")
  emptyText:SetText(L.NOTHING_YET)

  frame:SetScript("OnShow", function() Window.Refresh() end)
  frame:Hide()
end

function Window.Toggle()
  if not frame then build() end
  if frame:IsShown() then frame:Hide() else frame:Show() end
end

function Window.IsShown()
  return frame ~= nil and frame:IsShown()
end

-- A new message arrived: redraw if the list is open.
function Window.OnRecorded()
  Window.Refresh()
end
