-- eSaith Bag Filter
-- Lockouts tab: this week's keystones and Great Vault progress, plus raid & dungeon saves,
-- for every character you've logged in on.

local _, ns = ...
local L = ns.L
local UI = ns.UI

local NAME_COLUMN_WIDTH = 230
local MIN_COLUMN_WIDTH, MAX_COLUMN_WIDTH = 74, 120
local ROW_HEIGHT = 24
local HEADER_HEIGHT = 40
local VAULT_SLOTS = 3

local panel, headerBar, scroll, content, emptyText
local headerPool, rowPool

local SAVED_COLOR = UI.WARN
local DONE_COLOR = UI.GOOD

local VAULT_LABELS = {
	raid = L["Great Vault: Raids"],
	dungeons = L["Great Vault: Dungeons"],
	world = L["Great Vault: World"],
}

local function ClassColor(classFile)
	local color = classFile and C_ClassColor and C_ClassColor.GetClassColor(classFile)
	return color or HIGHLIGHT_FONT_COLOR
end

local ShortTime = UI.FormatDuration

local function IsStale(player)
	return not player.info.lastSeen or player.info.lastSeen < ns.GetLastWeeklyReset()
end

local EMPTY = "-"

---------------------------------------------------------------------------
-- Cell values
---------------------------------------------------------------------------

local function KeystoneCell(player)
	local weekly = ns:GetWeekly(player.key)
	local key = weekly and weekly.keystone
	if not key then return UI.MUTED:WrapTextInColorCode(EMPTY) end
	local mapName = C_ChallengeMode and C_ChallengeMode.GetMapUIInfo(key.mapID)
	return ("+%d %s"):format(key.level, mapName or "")
end

local function VaultCell(vaultKey)
	return function(player)
		local weekly = ns:GetWeekly(player.key)
		local unlocked = weekly and weekly.vault and weekly.vault[vaultKey]
		if not unlocked then return UI.MUTED:WrapTextInColorCode(EMPTY) end
		local text = ("%d/%d"):format(unlocked, VAULT_SLOTS)
		if unlocked >= VAULT_SLOTS then return DONE_COLOR:WrapTextInColorCode(text) end
		if unlocked == 0 then return UI.MUTED:WrapTextInColorCode(text) end
		return text
	end
end

local function ClaimCell(player)
	local weekly = ns:GetWeekly(player.key)
	if weekly and weekly.canClaim then return DONE_COLOR:WrapTextInColorCode(L["Claim!"]) end
	return UI.MUTED:WrapTextInColorCode(EMPTY)
end

local function CurrencyCell(currencyID)
	return function(player)
		local currency = player.info.currencies and player.info.currencies[currencyID]
		if not currency then return UI.MUTED:WrapTextInColorCode(EMPTY) end
		local text = BreakUpLargeNumbers(currency.quantity)
		if currency.max and currency.max > 0 and currency.quantity >= currency.max then
			return DONE_COLOR:WrapTextInColorCode(text)
		end
		return text
	end
end

local function CurrencyLabel(currencyID)
	local info = ns.lockoutDB.currencyInfo[currencyID]
	local icon = info.icon and ("|T%s:14:14:0:0|t "):format(info.icon) or ""
	return icon .. (info.name or tostring(currencyID))
end

local function LockoutCell(instance)
	return function(player)
		local left = ns:GetLockoutTimeLeft(instance, player.key)
		if left then return SAVED_COLOR:WrapTextInColorCode(ShortTime(left)) end
		return UI.MUTED:WrapTextInColorCode(EMPTY)
	end
end

--- Builds the list of rows to draw: section titles, weekly rows, then instances.
local function BuildRows(players, instances)
	local rows = {}

	local hasWeekly, anyClaim = false, false
	for _, player in ipairs(players) do
		local weekly = ns:GetWeekly(player.key)
		if weekly then
			hasWeekly = true
			if weekly.canClaim then anyClaim = true end
		end
	end

	if hasWeekly then
		table.insert(rows, { section = L["This week"] })
		table.insert(rows, { label = L["Mythic+ keystone"], cell = KeystoneCell })
		for _, vaultRow in ipairs(ns.VAULT_ROWS) do
			table.insert(rows, { label = VAULT_LABELS[vaultRow.key], cell = VaultCell(vaultRow.key) })
		end
		if anyClaim then
			table.insert(rows, { label = L["Great Vault rewards waiting"], cell = ClaimCell })
		end
	end

	local currencies = ns:GetTrackedCurrencies(players)
	if #currencies > 0 then
		table.insert(rows, { section = L["Currencies"] })
		for _, currencyID in ipairs(currencies) do
			table.insert(rows, { label = CurrencyLabel(currencyID), cell = CurrencyCell(currencyID) })
		end
	end

	if #instances > 0 then
		table.insert(rows, { section = L["Raids & dungeons"] })
		for _, instance in ipairs(instances) do
			table.insert(rows, { label = instance, cell = LockoutCell(instance) })
		end
	end

	return rows
end

---------------------------------------------------------------------------
-- Widgets
---------------------------------------------------------------------------

local function ColumnHeader_OnEnter(self)
	local player = self.player
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	GameTooltip_SetTitle(GameTooltip, player.info.name or player.key, ClassColor(player.info.class))
	GameTooltip_AddNormalLine(GameTooltip, player.info.realm or "")
	if player.info.lastSeen then
		GameTooltip_AddHighlightLine(GameTooltip, L["Last seen %s ago"]:format(ShortTime(time() - player.info.lastSeen)))
	end
	if IsStale(player) then
		GameTooltip_AddErrorLine(GameTooltip, L["Not logged in since the weekly reset, so this week's info may be missing."], true)
	end
	GameTooltip_AddInstructionLine(GameTooltip, L["Right-click for options"])
	GameTooltip:Show()
end

StaticPopupDialogs.ESAITHBAGFILTER_REMOVE_CHARACTER = {
	text = L["Remove %s from the Lockouts tab?\n\nThey'll come back the next time you log in on them."],
	button1 = REMOVE or L["Remove"],
	button2 = CANCEL,
	OnAccept = function(_, playerKey) ns:RemovePlayer(playerKey) end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

local function ColumnHeader_OnMouseUp(self, mouseButton)
	if mouseButton ~= "RightButton" then return end
	local player = self.player
	GameTooltip:Hide()
	MenuUtil.CreateContextMenu(self, function(_, root)
		root:CreateTitle(player.info.name or player.key)
		root:CreateButton(L["Hide this character"], function()
			player.info.shown = false
			ns:Fire("LOCKOUTS_CHANGED")
		end)
		root:CreateButton(L["Remove this character..."], function()
			StaticPopup_Show("ESAITHBAGFILTER_REMOVE_CHARACTER", player.key, nil, player.key)
		end)
	end)
end

local function CreateColumnHeader()
	local header = CreateFrame("Frame", nil, headerBar)
	header:SetHeight(HEADER_HEIGHT)
	header:EnableMouse(true)
	header:SetScript("OnEnter", ColumnHeader_OnEnter)
	header:SetScript("OnLeave", GameTooltip_Hide)
	header:SetScript("OnMouseUp", ColumnHeader_OnMouseUp)

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
	row:EnableMouse(true)

	row.stripe = row:CreateTexture(nil, "BACKGROUND")
	row.stripe:SetAllPoints()
	row.stripe:SetColorTexture(1, 1, 1, 0.035)

	row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
	row.highlight:SetAllPoints()
	row.highlight:SetColorTexture(UI.ACCENT.r, UI.ACCENT.g, UI.ACCENT.b, 0.10)

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
		cell:SetWordWrap(false)
		row.cells[index] = cell
	end
	return cell
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------

local function Refresh()
	local players = ns:GetLockoutPlayers()
	local rows = BuildRows(players, ns:GetLockoutInstances())

	headerPool:ReleaseAll()
	rowPool:ReleaseAll()

	if #players == 0 or #rows == 0 then
		headerBar:Hide()
		content:SetHeight(1)
		if next(ns.lockoutDB.players) == nil then
			emptyText:SetText(L["Nothing recorded yet.\n\nLog in on each of your max-level characters once and their keystones, Great Vault progress, currencies and raid & dungeon saves will show up here."])
		else
			emptyText:SetText(L["Nothing to show for the selected characters.\n\nUse the Characters and Instances buttons above to choose what's shown."])
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
		header.player = player
		header:ClearAllPoints()
		header:SetPoint("TOPLEFT", headerBar, "TOPLEFT", NAME_COLUMN_WIDTH + (index - 1) * columnWidth, 0)
		header:SetWidth(columnWidth)
		header.name:SetText(player.info.name or player.key)
		local color = IsStale(player) and UI.MUTED or ClassColor(player.info.class)
		header.name:SetTextColor(color:GetRGB())
		header.realm:SetText(player.info.realm or "")
	end

	local stripe = false
	for rowIndex, rowInfo in ipairs(rows) do
		local row = rowPool:Acquire()
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, -(rowIndex - 1) * ROW_HEIGHT)
		row:SetPoint("RIGHT", content, "RIGHT")
		for _, cell in ipairs(row.cells) do cell:Hide() end

		if rowInfo.section then
			row.name:SetFontObject("GameFontNormalSmall")
			row.name:SetText(rowInfo.section:upper())
			row.name:SetTextColor(UI.ACCENT:GetRGB())
			row.stripe:Hide()
			row.highlight:SetAlpha(0)
			stripe = false
		else
			row.name:SetFontObject("GameFontNormal")
			row.name:SetText(rowInfo.label)
			row.name:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
			row.highlight:SetAlpha(1)
			stripe = not stripe
			row.stripe:SetShown(stripe)

			for index, player in ipairs(players) do
				local cell = GetCell(row, index)
				cell:ClearAllPoints()
				cell:SetPoint("CENTER", row, "LEFT", NAME_COLUMN_WIDTH + (index - 0.5) * columnWidth, 0)
				cell:SetWidth(columnWidth - 6)
				cell:SetText(rowInfo.cell(player))
				cell:Show()
			end
		end
	end

	content:SetHeight(#rows * ROW_HEIGHT)
end

---------------------------------------------------------------------------
-- Filters (which characters / instances to show)
---------------------------------------------------------------------------

local function GetCharacterItems()
	local items = {}
	for _, player in ipairs(ns:GetLockoutPlayers(true)) do
		local name = ClassColor(player.info.class):WrapTextInColorCode(player.info.name or player.key)
		table.insert(items, { key = player.key, label = ("%s - %s"):format(name, player.info.realm or "") })
	end
	return items
end

local function GetInstanceItems()
	local items = {}
	for _, instance in ipairs(ns:GetLockoutInstances(true)) do
		table.insert(items, { key = instance, label = instance })
	end
	return items
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------

UI.RegisterPanel("lockouts", L["Lockouts"], {
	Build = function(frame, window)
		panel = frame

		local characters = UI.CreateFilterButton(panel, L["Characters"],
			L["Characters appear after you log in on them."],
			GetCharacterItems,
			function(key) return ns.lockoutDB.players[key] and ns.lockoutDB.players[key].shown end,
			function(key, on)
				if ns.lockoutDB.players[key] then ns.lockoutDB.players[key].shown = on end
				ns:Fire("LOCKOUTS_CHANGED")
			end)
		characters:SetWidth(UI.HEADER_BUTTON_WIDTH)
		characters:SetPoint("LEFT", window, "TOPLEFT", UI.HEADER_X + 4, UI.HEADER_Y)

		local instances = UI.CreateFilterButton(panel, L["Instances"],
			L["Instances appear once one of your characters is saved to them."],
			GetInstanceItems,
			function(key) return ns.lockoutDB.shownInstances[key] ~= false end,
			function(key, on)
				ns.lockoutDB.shownInstances[key] = on
				ns:Fire("LOCKOUTS_CHANGED")
			end)
		instances:SetWidth(UI.HEADER_BUTTON_WIDTH)
		instances:SetPoint("LEFT", characters, "RIGHT", 8, 0)

		headerBar = CreateFrame("Frame", nil, panel)
		headerBar:SetPoint("TOPLEFT", 0, -4)
		headerBar:SetPoint("TOPRIGHT", -24, -4)
		headerBar:SetHeight(HEADER_HEIGHT)

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
		emptyText:SetWidth(380)
		emptyText:SetSpacing(3)

		local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		hint:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 14, 9)
		hint:SetText(L["Times show how long until each save resets. Currencies are the ones each character tracks on their backpack."])

		panel:SetScript("OnShow", function()
			RequestRaidInfo()
			if C_MythicPlus and C_MythicPlus.RequestMapInfo then C_MythicPlus.RequestMapInfo() end
		end)
	end,
	Refresh = Refresh,
})

ns:On("LOCKOUTS_CHANGED", function() UI.RequestRefresh("lockouts") end)
