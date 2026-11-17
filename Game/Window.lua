-- The list window: one row per guild entry, newest first.
local addonName, ns = ...

local L = ns.L

local Window = {}
ns.Window = Window

local WIDTH, HEIGHT = 560, 520
local MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT = 400, 260, 1400, 1200
local ROW_HEIGHT, ROW_GAP = 40, 4
local SCROLL_INSET = 44 -- frame width minus the scroll child's width
local FRAME_NAME = "WhosHiringFrame"

local frame, content, emptyText
local rows = {}

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

  row.messageText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  row.messageText:SetPoint("TOPLEFT", row.nameText, "BOTTOMLEFT", 0, -4)
  row.messageText:SetPoint("RIGHT", -6, 0)
  row.messageText:SetJustifyH("LEFT")
  row.messageText:SetWordWrap(false)
  return row
end

local function meta(r, now)
  local posters = r.posters == 1 and L.POSTERS_ONE or L.POSTERS_MANY:format(r.posters)
  local age = ns.Query.age(math.max(now - (r.lastSeen or now), 0))
  return posters .. " · " .. (age == "now" and L.SEEN_NOW or L.SEEN:format(age))
end

function Window.Refresh()
  if not frame or not frame:IsShown() then return end
  local now = time()
  local list = ns.Query.list(ns.db, { now = now })
  local y = 0
  for i, r in ipairs(list) do
    local row = rows[i] or newRow()
    rows[i] = row
    row.data = r
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
    row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    row.nameText:SetText(r.name)
    row.metaText:SetText(meta(r, now))
    row.messageText:SetText(r.message)
    row:Show()
    y = y + ROW_HEIGHT + ROW_GAP
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
