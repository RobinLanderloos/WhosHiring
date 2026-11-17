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

local frame, content, emptyText, scroll, firstTab
local rows = {}
local expanded = {} -- row id -> true while open (this session only)
local currentTab = "all" -- "all", "starred" or "dismissed"
local tabButtons = {}

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

-- A small texture button with a tooltip.
local function iconButton(parent, texture, tip)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(18, 18)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints()
  b.icon:SetTexture(texture)
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.2)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(tip)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return b
end

-- Clicking a row opens or closes its poster list.
local function toggle(row)
  local key = row.data and row.data.entry and row.data.id
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

  -- Not interested (ADR 0003), star, and Restore on the Dismissed tab.
  row.dismissButton = iconButton(row, "Interface\\Buttons\\UI-GroupLoot-Pass-Up", L.DISMISS_TIP)
  row.dismissButton:SetPoint("TOPRIGHT", -6, -3)
  row.dismissButton:SetScript("OnClick", function()
    if row.data and row.data.entry then
      expanded[row.data.id] = nil
      ns.Store.dismiss(ns.db, row.data.entry, time())
      Window.Refresh()
    end
  end)
  row.starButton = iconButton(row, "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1", L.STAR_TIP)
  row.starButton:SetPoint("RIGHT", row.dismissButton, "LEFT", -6, 0)
  row.starButton:SetScript("OnClick", function()
    if row.data and row.data.entry then
      ns.Store.star(row.data.entry, not row.data.entry.starred)
      Window.Refresh()
    end
  end)
  row.restoreButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  row.restoreButton:SetSize(76, 20)
  row.restoreButton:SetPoint("TOPRIGHT", -6, -3)
  row.restoreButton:SetText(L.RESTORE)
  row.restoreButton:SetScript("OnClick", function()
    if row.data and row.data.dismissed then
      ns.Store.restore(ns.db, row.data.id)
      Window.Refresh()
    end
  end)

  row.metaText = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  row.metaText:SetPoint("TOPRIGHT", -56, -5)
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

  -- Opens the Who window on this guild's online members (shown when open).
  row.whoButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  row.whoButton:SetSize(120, 20)
  row.whoButton:SetText(L.WHO_ONLINE)
  row.whoButton:SetScript("OnClick", function()
    if row.data and row.data.name then Window.WhoOnline(row.data.name) end
  end)
  row.whoButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(L.WHO_ONLINE)
    GameTooltip:AddLine(L.WHO_ONLINE_HELP, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  row.whoButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
  row.whoButton:Hide()
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
  if r.dismissed then
    local age = ns.Query.age(math.max(now - r.dismissedAt, 0))
    return age == "now" and L.DISMISSED_NOW or L.DISMISSED_AGO:format(age)
  end
  local posters = r.posters == 1 and L.POSTERS_ONE or L.POSTERS_MANY:format(r.posters)
  local text = posters .. " · " .. ageText(now - (r.lastSeen or now))
  if r.dismissedPosterHint then text = L.HINT_DISMISSED_POSTER .. "  " .. text end
  return text
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

-- Runs /who g-"Name" through the game's own Who window, the same path as
-- typing it there, so the click counts as the player's own search.
local function tabText(tab)
  local text = tab.GetText and tab:GetText()
  if not text and tab.GetFontString and tab:GetFontString() then text = tab:GetFontString():GetText() end
  return text
end

-- Shows the Friends window on its Who tab. Tab numbers differ between
-- clients (on Forever, 2 is Raid), so the tab is found by its label.
-- What was found is saved for /reload diagnosis.
local function showWhoTab()
  local info = { tabs = {} }
  ns.db.whoDebug = info
  if not FriendsFrame then info.problem = "no FriendsFrame"; return end
  if not FriendsFrame:IsShown() then
    if ToggleFriendsFrame then ToggleFriendsFrame() elseif ShowUIPanel then ShowUIPanel(FriendsFrame) end
  end
  if WhoFrame and WhoFrame:IsShown() then info.shown = true; return end
  local label = WHO or "Who"
  local whoTab
  for i = 1, FriendsFrame.numTabs or 6 do
    local tab = _G["FriendsFrameTab" .. i]
    if tab then
      local text = tabText(tab)
      info.tabs[#info.tabs + 1] = i .. "=" .. tostring(text)
      if text == label then whoTab = tab end
    end
  end
  if whoTab then whoTab:Click() end
  info.clicked = whoTab ~= nil
  info.shown = WhoFrame ~= nil and WhoFrame:IsShown()
end

function Window.WhoOnline(name)
  local query = ns.GuildName.whoQuery(name)
  if not query then return end
  local ok, err = pcall(showWhoTab)
  if not ok then ns.db.whoDebug = { problem = tostring(err) } end
  if WhoFrameEditBox and WhoFrameWhoButton then
    WhoFrameEditBox:SetText(query)
    WhoFrameWhoButton:Click()
  elseif C_FriendList and C_FriendList.SendWho then
    C_FriendList.SendWho(query)
  end
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
  if r.name then
    row.whoButton:ClearAllPoints()
    row.whoButton:SetPoint("TOPLEFT", row, "TOPLEFT", 14, -y)
    row.whoButton:Show()
    y = y + 24
  else
    row.whoButton:Hide() -- an unknown guild has no name to search
  end
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

-- The list starts under the tabs, the toolbar and (when open) the chip panel.
local TOP_FIXED = 82
local function placeScroll(chipHeight)
  scroll:ClearAllPoints()
  scroll:SetPoint("TOPLEFT", 12, -(TOP_FIXED + (chipHeight > 0 and chipHeight + 4 or 0)))
  scroll:SetPoint("BOTTOMRIGHT", -32, 24)
end

function Window.Refresh()
  if not frame or not frame:IsShown() then return end
  local now = time()
  placeScroll(ns.Filters.Layout(frame:GetWidth() - 24))
  local options = ns.Filters.Options()
  options.now, options.tab = now, currentTab
  local list = ns.Query.list(ns.db, options)
  for tab, button in pairs(tabButtons) do
    if tab == currentTab then button:LockHighlight() else button:UnlockHighlight() end
  end
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
    row.dismissButton:SetShown(not r.dismissed)
    row.starButton:SetShown(not r.dismissed)
    row.starButton.icon:SetAlpha(r.starred and 1 or 0.25)
    row.starButton.icon:SetDesaturated(not r.starred)
    row.restoreButton:SetShown(r.dismissed == true)
    row.messageText:SetText(r.message)
    row.tagText:SetText(#r.tags > 0 and Window.TagLine(r.tags) or L.NO_TAGS)
    local height = ROW_HEIGHT
    if expanded[r.id] then
      row.messageText:Hide()
      height = fillDetails(row, r, now, width)
    else
      row.messageText:Show()
      for _, line in ipairs(row.detailLines) do line:Hide() end
      row.whoButton:Hide()
    end
    row:SetHeight(height)
    row:SetAlpha(r.stale and 0.5 or 1) -- not seen for a while
    row:Show()
    y = y + height + ROW_GAP
  end
  for i = #list + 1, #rows do rows[i]:Hide() end
  content:SetHeight(math.max(y, 1))
  local filtered = next(options.chips) ~= nil or (options.search or ""):find("%S") ~= nil
  emptyText:SetText(filtered and L.NOTHING_MATCHES or currentTab == "all" and L.NOTHING_YET or L.NOTHING_IN_TAB)
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

  scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  -- Tabs: All, Starred, Dismissed.
  local previous
  for _, tab in ipairs({ { "all", L.TAB_ALL }, { "starred", L.TAB_STARRED }, { "dismissed", L.TAB_DISMISSED } }) do
    local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    b:SetSize(84, 20)
    if previous then b:SetPoint("LEFT", previous, "RIGHT", 4, 0) else b:SetPoint("TOPLEFT", 12, -30) end
    b:SetText(tab[2])
    b.tab = tab[1]
    b:SetScript("OnClick", function(self)
      currentTab = self.tab
      Window.Refresh()
    end)
    tabButtons[tab[1]] = b
    firstTab = firstTab or b
    previous = b
  end

  ns.Filters.Build(frame, firstTab)
  placeScroll(0)
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(frame:GetWidth() - SCROLL_INSET, 1)
  scroll:SetScrollChild(content)
  frame:SetScript("OnSizeChanged", function(self, width)
    content:SetWidth(math.max((width or self:GetWidth()) - SCROLL_INSET, 1))
  end)

  emptyText = frame:CreateFontString(nil, "ARTWORK", "GameFontDisable")
  emptyText:SetPoint("CENTER")
  emptyText:SetText(L.NOTHING_YET)

  -- Whatever was in the list while it was open is no longer new.
  local function seen()
    ns.Store.markOpened(ns.db, time())
    if ns.MinimapButton then ns.MinimapButton.UpdateCount() end
  end
  frame:SetScript("OnShow", function()
    Window.Refresh()
    seen()
  end)
  frame:SetScript("OnHide", seen)
  frame:Hide()
end

function Window.Toggle()
  if not frame then build() end
  if frame:IsShown() then frame:Hide() else frame:Show() end
end

-- Opens the list on the All tab with this guild's posters shown.
function Window.ShowGuild(id)
  if not frame then build() end
  currentTab = "all"
  expanded[id] = true
  if frame:IsShown() then Window.Refresh() else frame:Show() end
end

function Window.IsShown()
  return frame ~= nil and frame:IsShown()
end

-- A new message arrived: redraw if the list is open, at most twice a second
-- so busy chat does not rebuild the list for every line.
local refreshQueued = false
function Window.OnRecorded()
  if not Window.IsShown() or refreshQueued then return end
  if not (C_Timer and C_Timer.After) then return Window.Refresh() end
  refreshQueued = true
  C_Timer.After(0.5, function()
    refreshQueued = false
    Window.Refresh()
  end)
end
