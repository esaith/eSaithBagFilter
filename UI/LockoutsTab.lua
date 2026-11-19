-- eSaith Bag Filter
-- Lockouts tab: which of your characters are saved to which raids and dungeons.

local _, ns = ...
local UI = ns.UI

local NAME_COLUMN_WIDTH = 230
local MIN_COLUMN_WIDTH, MAX_COLUMN_WIDTH = 74, 120
local ROW_HEIGHT = 24
local HEADER_HEIGHT = 40

local panel, headerBar, scroll, content, emptyText
local headerPool, rowPool

local SAVED_COLOR = CreateColor(1, 0.55, 0.25)

local function ClassColor(classFile)
	local color = classFile and C_ClassColor and C_ClassColor.GetClassColor(classFile)
	return color or HIGHLIGHT_FONT_COLOR
end

local function ShortTime(seconds)
	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	if days > 0 then return ("%dd %dh"):format(days, hours) end
	local minutes = math.floor((seconds % 3600) / 60)
	if hours > 0 then return ("%dh %dm"):format(hours, minutes) end
	return ("%dm"):format(math.max(1, minutes))
end

---------------------------------------------------------------------------
-- Widgets
---------------------------------------------------------------------------

local function CreateColumnHeader()
	local header = CreateFrame("Frame", nil, headerBar)
	header:SetHeight(HEADER_HEIGHT)
	header.name = header:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	header.name:SetPoint("BOTTOMLEFT", header, "LEFT", 2, 1)
	header.name:SetPoint("BOTTOMRIGHT", header, "RIGHT", -2, 1)
	header.name:SetWordWrap(false)
	header.realm = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	header.realm:SetPoint("TOPLEFT", header, "LEFT", 2, -1)
	header.realm:SetPoint("TOPRIGHT", header, "RIGHT", -2, -1)
	header.realm:SetWordWrap(false)
	return header
end

local function CreateRow()
	local row = CreateFrame("Frame", nil, content)
	row:SetHeight(ROW_HEIGHT)

	row.stripe = row:CreateTexture(nil, "BACKGROUND")
	row.stripe:SetAllPoints()
	row.stripe:SetColorTexture(1, 1, 1, 0.035)

	row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
	row.highlight:SetAllPoints()
	row.highlight:SetColorTexture(UI.ACCENT.r, UI.ACCENT.g, UI.ACCENT.b, 0.10)
	row:EnableMouse(true)

	row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.name:SetPoint("LEFT", 10, 0)
	row.name:SetWidth(NAME_COLUMN_WIDTH - 16)
	row.name:SetJustifyH("LEFT")
	row.name:SetWordWrap(false)

	row.cells = {}
	return row
end

local function GetCell(row, index)
	local cell = row.cells[index]
	if not cell then
		cell = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.cells[index] = cell
	end
	return cell
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------

local function Refresh()
	local players = ns:GetLockoutPlayers()
	local instances = ns:GetLockoutInstances()

	headerPool:ReleaseAll()
	rowPool:ReleaseAll()

	if #players == 0 or #instances == 0 then
		headerBar:Hide()
		content:SetHeight(1)
		if next(ns.lockoutDB.players) == nil then
			emptyText:SetText("No lockouts recorded yet.\n\nLog in on each of your characters once and their raid and dungeon saves will show up here.")
		else
			emptyText:SetText("None of the selected characters are saved anywhere right now.\n\nChoose which characters and instances to show on the Settings tab.")
		end
		emptyText:Show()
		return
	end
	emptyText:Hide()
	headerBar:Show()

	local available = scroll:GetWidth() - NAME_COLUMN_WIDTH
	local columnWidth = Clamp(math.floor(available / #players), MIN_COLUMN_WIDTH, MAX_COLUMN_WIDTH)

	for index, player in ipairs(players) do
		local header = headerPool:Acquire()
		header:ClearAllPoints()
		header:SetPoint("TOPLEFT", headerBar, "TOPLEFT", NAME_COLUMN_WIDTH + (index - 1) * columnWidth, 0)
		header:SetWidth(columnWidth)
		header.name:SetText(player.info.name or player.key)
		header.name:SetTextColor(ClassColor(player.info.class):GetRGB())
		header.realm:SetText(player.info.realm or "")
	end

	for rowIndex, instance in ipairs(instances) do
		local row = rowPool:Acquire()
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, -(rowIndex - 1) * ROW_HEIGHT)
		row:SetPoint("RIGHT", content, "RIGHT")
		row.stripe:SetShown(rowIndex % 2 == 0)
		row.name:SetText(instance)

		for _, cell in ipairs(row.cells) do cell:Hide() end
		for index, player in ipairs(players) do
			local cell = GetCell(row, index)
			cell:ClearAllPoints()
			cell:SetPoint("CENTER", row, "LEFT", NAME_COLUMN_WIDTH + (index - 0.5) * columnWidth, 0)
			local left = ns:GetLockoutTimeLeft(instance, player.key)
			if left then
				cell:SetText(SAVED_COLOR:WrapTextInColorCode(ShortTime(left)))
			else
				cell:SetText(UI.MUTED:WrapTextInColorCode("-"))
			end
			cell:Show()
		end
	end

	content:SetHeight(#instances * ROW_HEIGHT)
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------

UI.RegisterPanel("lockouts", "Lockouts", {
	Build = function(frame, window)
		panel = frame

		headerBar = CreateFrame("Frame", nil, panel)
		headerBar:SetPoint("TOPLEFT", 0, -4)
		headerBar:SetPoint("TOPRIGHT", -24, -4)
		headerBar:SetHeight(HEADER_HEIGHT)

		local instanceLabel = headerBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		instanceLabel:SetPoint("LEFT", 10, 0)
		instanceLabel:SetText("Instance")

		local rule = headerBar:CreateTexture(nil, "ARTWORK")
		rule:SetColorTexture(1, 0.82, 0, 0.18)
		rule:SetHeight(1)
		rule:SetPoint("BOTTOMLEFT", 6, 0)
		rule:SetPoint("BOTTOMRIGHT")

		scroll, content = UI.CreateScrollArea(panel)
		scroll:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -2)
		scroll:SetPoint("BOTTOMRIGHT", -24, 4)
		scroll:HookScript("OnSizeChanged", function() UI.RequestRefresh("lockouts") end)

		headerPool = UI.CreatePool(CreateColumnHeader)
		rowPool = UI.CreatePool(CreateRow)

		emptyText = panel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
		emptyText:SetPoint("CENTER")
		emptyText:SetWidth(360)
		emptyText:SetSpacing(3)

		local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		hint:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 14, 9)
		hint:SetText("Times show how long until each save resets.")

		panel:SetScript("OnShow", RequestRaidInfo)
	end,
	Refresh = Refresh,
})

ns:On("LOCKOUTS_CHANGED", function() UI.RequestRefresh("lockouts") end)
