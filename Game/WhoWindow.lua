-- The Who window: runs /who g-"Name" for one guild and lists the members
-- online, with a filter box, sort buttons and a Whisper button each.
-- Forever has no Who tab in the Friends window (its Who list sits in the
-- LFG window), and small results go to chat, so the addon shows them itself.
local addonName, ns = ...

local L = ns.L

local WhoWindow = {}
ns.WhoWindow = WhoWindow

local WIDTH, HEIGHT = 540, 440
local ROW_HEIGHT = 20
local LIST_TOP = 144
local FRAME_NAME = "WhosHiringWhoFrame"
local WHO_TIMEOUT = 6 -- seconds; the server answers nothing when throttled

local frame, content, scroll, statusText, warnText, searchBox, postersCheck, exactCheck
local sortButtons = {}
local rows = {}
-- The search shown: { name, messages, status = "searching" | "done" | "noanswer", members }
local current
local pending -- the search waiting for WHO_LIST_UPDATE

-- Sort and tick-box choices, kept between sessions.
local function settings()
  ns.db.ui = type(ns.db.ui) == "table" and ns.db.ui or {}
  local s = type(ns.db.ui.who) == "table" and ns.db.ui.who or {}
  ns.db.ui.who = s
  if s.sort == nil then s.sort = "name" end
  if s.postersFirst == nil then s.postersFirst = true end
  if s.exact == nil then s.exact = true end
  return s
end

-- "Bob" from "Bob-Realm".
local function shortName(sender)
  return (sender:match("^[^-]+")) or sender
end

local function postedText(seconds)
  local age = ns.Query.age(math.max(seconds, 0))
  return age == "now" and L.WHO_POSTED_NOW or L.WHO_POSTED:format(age)
end

local SORT_LABELS = {
  name = { L.WHO_SORT_NAME, L.WHO_AZ, L.WHO_ZA },
  level = { L.WHO_SORT_LEVEL, L.WHO_HIGH, L.WHO_LOW },
  class = { L.WHO_SORT_CLASS, L.WHO_AZ, L.WHO_ZA },
  zone = { L.WHO_SORT_ZONE, L.WHO_AZ, L.WHO_ZA },
}

local function newRow(index)
  local row = CreateFrame("Frame", nil, content)
  row:SetHeight(ROW_HEIGHT)
  ns.Skin.Row(row, index)
  row:EnableMouse(true)
  local function text(x, width, font)
    local fs = row:CreateFontString(nil, "ARTWORK", font or "GameFontHighlightSmall")
    fs:SetPoint("LEFT", x, 0)
    if width then fs:SetWidth(width) end
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    return fs
  end
  row.nameText = text(6, 140)
  row.levelText = text(150, 30)
  row.classText = text(184, 76)
  row.zoneText = text(264)
  row.whisper = ns.Skin.Button(CreateFrame("Button", nil, row))
  row.whisper:SetSize(70, 16)
  row.whisper:SetPoint("RIGHT", -4, 0)
  row.whisper:SetText(L.WHISPER)
  row.whisper:SetScript("OnClick", function() if row.member then ns.Window.Whisper(row.member.name) end end)
  row.zoneText:SetPoint("RIGHT", row.whisper, "LEFT", -6, 0)
  row:SetScript("OnEnter", function(self)
    local m = self.member
    if not m then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:SetText(m.name)
    if m.guild then GameTooltip:AddLine(m.guild, 1, 1, 1) end
    if m.posted then GameTooltip:AddLine(postedText(time() - m.posted), 1, 0.82, 0) end
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return row
end

function WhoWindow.Refresh()
  if not frame or not frame:IsShown() or not current then return end
  local s = settings()
  frame.TitleText:SetText(L.WHO_TITLE:format(current.name))
  for key, b in pairs(sortButtons) do
    local labels = SORT_LABELS[key]
    local on = s.sort == key
    b:SetText(on and (labels[1] .. " " .. (s.reverse and labels[3] or labels[2])) or labels[1])
    ns.Skin.SetSelected(b, on)
  end
  postersCheck:SetChecked(s.postersFirst)
  exactCheck:SetChecked(s.exact)

  local list, info = {}, { total = 0, exact = 0 }
  if current.status == "done" then
    list, info = ns.Who.view(current.members, {
      guild = current.name, exact = s.exact, search = searchBox:GetText(),
      sort = s.sort, reverse = s.reverse, postersFirst = s.postersFirst,
    })
  end

  local status, warn = "", nil
  if current.status == "searching" then
    status = L.WHO_SEARCHING
  elseif current.status == "noanswer" then
    status = L.WHO_NO_ANSWER
  elseif info.total == 0 then
    status = L.WHO_NOBODY
  elseif #list == 0 then
    status = (s.exact and info.exact == 0) and L.WHO_NO_EXACT or L.WHO_NONE_MATCH
  else
    local posters = 0
    for _, m in ipairs(list) do if m.posted then posters = posters + 1 end end
    status = L.WHO_COUNT:format(#list, posters)
  end
  if current.status == "done" and info.total >= ns.Who.MAX_RESULTS then
    warn = L.WHO_CAPPED:format(info.total)
  end
  statusText:SetText(status)
  warnText:SetText(warn or "")
  warnText:SetShown(warn ~= nil)

  local now = time()
  for i, m in ipairs(list) do
    local row = rows[i] or newRow(i)
    rows[i] = row
    row.member = m
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
    row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    local name = shortName(m.name)
    row.nameText:SetText(m.posted and ("|cffffd100" .. name .. "|r") or name)
    row.levelText:SetText(tostring(m.level or "?"))
    row.classText:SetText(m.class or "")
    local zone = m.zone or ""
    if not s.exact and m.guild then zone = zone .. "  |cff909090<" .. m.guild .. ">|r" end
    if m.posted then zone = zone .. "  |cffffd100" .. postedText(now - m.posted) .. "|r" end
    row.zoneText:SetText(zone)
    row:Show()
  end
  for i = #list + 1, #rows do rows[i]:Hide() end
  content:SetHeight(math.max(#list * ROW_HEIGHT, 1))
end

local whoEvents = CreateFrame("Frame")
whoEvents:RegisterEvent("WHO_LIST_UPDATE")
whoEvents:SetScript("OnEvent", function()
  local search = pending
  if not search then return end
  pending = nil
  if C_FriendList.SetWhoToUi then C_FriendList.SetWhoToUi(false) end -- /who behaves as before
  local ok, results = pcall(function()
    local out = {}
    local n = C_FriendList.GetNumWhoResults and C_FriendList.GetNumWhoResults() or 0
    for i = 1, n do
      local info = C_FriendList.GetWhoInfo(i)
      if info then out[#out + 1] = info end
    end
    return out
  end)
  if not ok then results = {} end
  local realm = GetNormalizedRealmName and GetNormalizedRealmName()
  search.status = "done"
  search.members = ns.Who.members(results, search.messages, realm)
  if ns.db.whoDebug then
    ns.db.whoDebug.answered = true
    ns.db.whoDebug.results = #results
    ns.db.whoDebug.error = not ok and tostring(results) or nil
  end
  WhoWindow.Refresh()
end)

local function search(name, messages)
  local query = ns.GuildName.whoQuery(name)
  if not query or not (C_FriendList and C_FriendList.SendWho) then return end
  ns.db.whoDebug = { query = query, setWhoToUi = C_FriendList.SetWhoToUi ~= nil }
  -- Results to the event instead of chat, for this search only.
  if C_FriendList.SetWhoToUi then C_FriendList.SetWhoToUi(true) end
  local this = { name = name, messages = messages, status = "searching", members = {} }
  current, pending = this, this
  local origin = Enum and Enum.SocialWhoOrigin and Enum.SocialWhoOrigin.Social
  C_FriendList.SendWho(query, origin)
  C_Timer.After(WHO_TIMEOUT, function()
    if pending == this then
      pending = nil
      if C_FriendList.SetWhoToUi then C_FriendList.SetWhoToUi(false) end
      this.status = "noanswer"
      WhoWindow.Refresh()
    end
  end)
end

local function savePosition()
  local point, _, relativePoint, x, y = frame:GetPoint()
  ns.db.whoWindow = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function place()
  frame:ClearAllPoints()
  local saved = ns.db.whoWindow
  if saved and saved.point and saved.x and saved.y then
    frame:SetPoint(saved.point, UIParent, saved.relativePoint or saved.point, saved.x, saved.y)
  else
    local main = _G.WhosHiringFrame
    if main and main:IsShown() then
      frame:SetPoint("TOPLEFT", main, "TOPRIGHT", 14, 0)
    else
      frame:SetPoint("CENTER")
    end
  end
end

local function check(label, help, key)
  local cb = ns.Skin.Check(CreateFrame("CheckButton", nil, frame), 20)
  cb.Text:SetFontObject("GameFontHighlightSmall")
  cb.Text:SetText(label)
  cb:SetScript("OnClick", function(self)
    settings()[key] = self:GetChecked() and true or false
    WhoWindow.Refresh()
  end)
  cb:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(label)
    GameTooltip:AddLine(help, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return cb
end

local function build()
  frame = ns.Skin.Window(CreateFrame("Frame", FRAME_NAME, UIParent))
  frame:SetSize(WIDTH, HEIGHT)
  frame:SetFrameStrata("HIGH")
  frame:SetToplevel(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    savePosition()
  end)
  frame:SetClampedToScreen(true)
  tinsert(UISpecialFrames, FRAME_NAME) -- Escape closes it

  local again = ns.Skin.Button(CreateFrame("Button", nil, frame))
  again:SetSize(110, 20)
  again:SetPoint("TOPLEFT", 12, -32)
  again:SetText(L.WHO_AGAIN)
  again:SetScript("OnClick", function()
    if current then
      search(current.name, current.messages)
      WhoWindow.Refresh()
    end
  end)

  searchBox = ns.Skin.Input(CreateFrame("EditBox", nil, frame))
  searchBox:SetSize(170, 20)
  searchBox:SetPoint("TOPRIGHT", -12, -32)
  searchBox:SetScript("OnTextChanged", function() WhoWindow.Refresh() end)
  searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  local hint = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  hint:SetPoint("RIGHT", searchBox, "LEFT", -6, 0)
  hint:SetText(L.WHO_FILTER)

  local sortLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  sortLabel:SetPoint("TOPLEFT", 12, -64)
  sortLabel:SetText(L.WHO_SORT)
  local previous = sortLabel
  for _, key in ipairs(ns.Who.SORTS) do
    local b = ns.Skin.Button(CreateFrame("Button", nil, frame))
    b:SetSize(96, 20)
    b:SetPoint("LEFT", previous, "RIGHT", previous == sortLabel and 8 or 4, 0)
    b:SetScript("OnClick", function()
      local s = settings()
      if s.sort == key then s.reverse = not s.reverse else s.sort, s.reverse = key, false end
      WhoWindow.Refresh()
    end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText(L.WHO_SORT_TIP)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    sortButtons[key] = b
    previous = b
  end

  postersCheck = check(L.WHO_POSTERS_FIRST, L.WHO_POSTERS_FIRST_HELP, "postersFirst")
  postersCheck:SetPoint("TOPLEFT", 8, -88)
  exactCheck = check(L.WHO_EXACT, L.WHO_EXACT_HELP, "exact")
  exactCheck:SetPoint("LEFT", postersCheck.Text, "RIGHT", 20, 0)

  statusText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  statusText:SetPoint("TOPLEFT", 14, -116)
  statusText:SetPoint("RIGHT", -14, 0)
  statusText:SetJustifyH("LEFT")
  warnText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  warnText:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", 0, -3)
  warnText:SetPoint("RIGHT", -14, 0)
  warnText:SetJustifyH("LEFT")
  warnText:SetTextColor(1, 0.55, 0.25)

  scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  ns.Skin.ScrollBar(scroll)
  scroll:SetPoint("TOPLEFT", 12, -LIST_TOP)
  scroll:SetPoint("BOTTOMRIGHT", -22, 12)
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(WIDTH - 34, 1)
  scroll:SetScrollChild(content)

  frame:SetScript("OnShow", WhoWindow.Refresh)
  frame:Hide()
  place()
end

-- Opens the window on a guild and searches its online members.
-- `messages` are the guild's saved messages, to mark who posted the ad.
function WhoWindow.Open(name, messages)
  if not name then return end
  if not frame then build() end
  searchBox:SetText("")
  search(name, messages)
  if frame:IsShown() then WhoWindow.Refresh() else frame:Show() end
end

function WhoWindow.IsShown()
  return frame ~= nil and frame:IsShown()
end
