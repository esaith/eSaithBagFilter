-- eSaith Bag Filter
-- Loot tab: everything you've looted (per zone) that's still in your bags, ready to sell.

local _, ns = ...
local L = ns.L
local UI = ns.UI

local BUTTON_SIZE = 37
local BUTTON_GAP = 6
local SIDEBAR_WIDTH = UI.SIDEBAR_WIDTH
local HEADER_HEIGHT = 24
local GRID_PADDING = 10

-- Ask before selling more than the vendor can buy back, or anything worth a lot.
local CONFIRM_VALUE = 100 * COPPER_PER_GOLD

local selectedZone -- nil means every zone
local searchText = ""
local panel, dropdown, searchBox, scroll, content, emptyText, statusText, sellButton, undoButton, hiddenToggle
local qualityRows = {}
local buttonPool, headerPool

---------------------------------------------------------------------------
-- Item buttons
---------------------------------------------------------------------------

local function ItemButton_OnEnter(self)
	local entry = self.entry
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if C_Container.GetContainerItemID(entry.bag, entry.slot) == entry.itemID then
		GameTooltip:SetBagItem(entry.bag, entry.slot)
	elseif entry.link then
		GameTooltip:SetHyperlink(entry.link)
	end

	if ns:GetPriceSourceName() then
		local auction = ns:GetAuctionValue(entry.link, entry.itemID)
		if auction then
			GameTooltip_AddNormalLine(GameTooltip, L["Auction House: "] .. GetMoneyString(auction, true))
		end
	end

	GameTooltip_AddBlankLineToTooltip(GameTooltip)
	if entry.keepReason then
		GameTooltip_AddColoredLine(GameTooltip, L["Kept: "] .. entry.keepReason, UI.ACCENT)
	end
	if entry.hidden then
		GameTooltip_AddInstructionLine(GameTooltip, L["Right-click to show this item again"])
	else
		if ns.db.kept[entry.itemID] then
			GameTooltip_AddInstructionLine(GameTooltip, L["Click to allow selling"])
		else
			GameTooltip_AddInstructionLine(GameTooltip, L["Click to keep this item"])
		end
		GameTooltip_AddInstructionLine(GameTooltip, L["Right-click to hide it from this list"])
	end
	GameTooltip:Show()
end

local function ItemButton_OnClick(self, mouseButton)
	if HandleModifiedItemClick(self.entry.link) then return end
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	if mouseButton == "RightButton" then
		ns:ToggleHidden(self.entry.itemID)
	else
		ns:ToggleKept(self.entry.itemID)
	end
end

local function CreateItemButton()
	local button = CreateFrame("ItemButton", nil, content)
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	button.lock = button:CreateTexture(nil, "OVERLAY", nil, 7)
	button.lock:SetTexture("Interface\\PetBattles\\PetBattle-LockIcon")
	button.lock:SetSize(16, 16)
	button.lock:SetPoint("TOPRIGHT", 2, 2)

	button.hiddenMark = button:CreateTexture(nil, "OVERLAY", nil, 7)
	button.hiddenMark:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
	button.hiddenMark:SetSize(18, 18)
	button.hiddenMark:SetPoint("TOPRIGHT", 3, 3)

	button:SetScript("OnEnter", ItemButton_OnEnter)
	button:SetScript("OnLeave", GameTooltip_Hide)
	button:SetScript("OnClick", ItemButton_OnClick)
	return button
end

local function SetupItemButton(button, entry)
	button.entry = entry
	SetItemButtonTexture(button, entry.icon)
	SetItemButtonCount(button, entry.count)
	SetItemButtonQuality(button, entry.quality, entry.link)

	local kept = entry.keepReason ~= nil
	SetItemButtonDesaturated(button, kept)
	local alpha = entry.hidden and 0.3 or (kept and 0.45 or 1)
	button.icon:SetAlpha(alpha)
	if button.IconBorder then button.IconBorder:SetAlpha(alpha) end
	button.lock:SetShown(kept and not entry.hidden)
	button.hiddenMark:SetShown(entry.hidden)

	if GameTooltip:GetOwner() == button then ItemButton_OnEnter(button) end
end

local function CreateGroupHeader()
	local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	header:SetJustifyH("LEFT")
	return header
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------

local function SortByName(a, b)
	local an = a.data and a.data.name or ""
	local bn = b.data and b.data.name or ""
	if an == bn then return a.itemID < b.itemID end
	return an < bn
end

local function MatchesSearch(entry)
	if searchText == "" then return true end
	local name = entry.data and entry.data.name
	return name == nil or name:lower():find(searchText, 1, true) ~= nil
end

--- Items currently listed: the selected zone, quality filters and search applied.
local function GetShownItems()
	local shown = {}
	local all = ns:GetLootedItems(selectedZone, ns.db.showHidden)
	for itemID, entry in pairs(all) do
		if ns.db.filters[entry.quality] and MatchesSearch(entry) then
			shown[itemID] = entry
		end
	end
	return shown, all
end

local function Refresh()
	-- Fall back to "All zones" if the selected zone has nothing left.
	if selectedZone and not tContains(ns:GetLootZones(), selectedZone) then
		selectedZone = nil
	end
	dropdown:GenerateMenu()

	local shownItems, allItems = GetShownItems()

	-- Sidebar counts (everything in the zone, before filters)
	local counts, hiddenCount = {}, 0
	for _, quality in ipairs(ns.QUALITIES) do counts[quality] = 0 end
	for itemID, entry in pairs(ns:GetLootedItems(selectedZone, true)) do
		if ns.db.hidden[itemID] then
			hiddenCount = hiddenCount + 1
		elseif counts[entry.quality] then
			counts[entry.quality] = counts[entry.quality] + 1
		end
	end
	for quality, row in pairs(qualityRows) do
		row.count:SetText(counts[quality] > 0 and counts[quality] or "")
		row:Refresh()
	end
	hiddenToggle.count:SetText(hiddenCount > 0 and hiddenCount or "")
	hiddenToggle:Refresh()

	-- Group by quality, from junk upwards
	local groups = {}
	for _, quality in ipairs(ns.QUALITIES) do groups[quality] = {} end

	local sellCount, sellValue, keptCount = 0, 0, 0
	for _, entry in pairs(shownItems) do
		local group = groups[entry.quality]
		if group then
			table.insert(group, entry)
			if entry.keepReason then
				keptCount = keptCount + 1
			else
				sellCount = sellCount + 1
				sellValue = sellValue + (entry.data and entry.data.sellPrice or 0) * entry.count
			end
		end
	end

	-- Grid
	buttonPool:ReleaseAll()
	headerPool:ReleaseAll()

	local width = scroll:GetWidth()
	local perRow = math.max(1, math.floor((width - GRID_PADDING * 2 + BUTTON_GAP) / (BUTTON_SIZE + BUTTON_GAP)))
	local y = -GRID_PADDING
	local shown = 0

	for _, quality in ipairs(ns.QUALITIES) do
		local group = groups[quality]
		if #group > 0 then
			table.sort(group, SortByName)

			local header = headerPool:Acquire()
			header:ClearAllPoints()
			header:SetPoint("TOPLEFT", GRID_PADDING, y)
			header:SetText(ns.QualityColor(quality):WrapTextInColorCode(ns.QualityName(quality))
				.. UI.MUTED:WrapTextInColorCode("  " .. #group))
			y = y - HEADER_HEIGHT

			for index, entry in ipairs(group) do
				local column = (index - 1) % perRow
				local row = math.floor((index - 1) / perRow)
				local button = buttonPool:Acquire()
				button:ClearAllPoints()
				button:SetPoint("TOPLEFT", GRID_PADDING + column * (BUTTON_SIZE + BUTTON_GAP),
					y - row * (BUTTON_SIZE + BUTTON_GAP))
				SetupItemButton(button, entry)
				shown = shown + 1
			end

			y = y - math.ceil(#group / perRow) * (BUTTON_SIZE + BUTTON_GAP) - 8
		end
	end
	content:SetHeight(-y + GRID_PADDING)

	if shown == 0 then
		if searchText ~= "" then
			emptyText:SetText(L["No items match your search."])
		elseif next(allItems) then
			emptyText:SetText(L["No items match the selected qualities."])
		else
			emptyText:SetText(L["Nothing to sell yet.\n\nItems you loot are listed here, grouped by the zone you looted them in."])
		end
		emptyText:Show()
	else
		emptyText:Hide()
	end

	-- Status bar
	local parts = {}
	if sellCount > 0 then
		table.insert(parts, L["%d to sell"]:format(sellCount) .. "  " .. GetMoneyString(sellValue, true))
	end
	if keptCount > 0 then
		table.insert(parts, UI.MUTED:WrapTextInColorCode(L["%d kept"]:format(keptCount)))
	end
	if ns.session.soldMoney > 0 then
		table.insert(parts, UI.MUTED:WrapTextInColorCode(L["Sold this session:"]) .. " "
			.. GetMoneyString(ns.session.soldMoney, true))
	end
	statusText:SetText(table.concat(parts, UI.MUTED:WrapTextInColorCode("  ·  ")))

	sellButton.sellCount = sellCount
	sellButton:SetEnabled(ns.atMerchant and sellCount > 0 and not ns:IsSelling())
	sellButton:SetText(ns:IsSelling() and L["Selling..."] or L["Sell Items"])
	undoButton:SetEnabled(ns:CanUndoLastSale())
end

---------------------------------------------------------------------------
-- Selling
---------------------------------------------------------------------------

StaticPopupDialogs.ESAITHBAGFILTER_CONFIRM_SELL = {
	text = L["Sell %s for %s?\n\nThe vendor can only buy back the last 12 stacks you sell."],
	button1 = L["Sell"],
	button2 = CANCEL,
	OnAccept = function(_, itemIDs) ns:SellItems(itemIDs) end,
	showAlert = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

local function SellShownItems()
	local toSell, slots, value = {}, 0, 0
	for itemID, entry in pairs(GetShownItems()) do
		if not entry.keepReason then
			toSell[itemID] = true
			slots = slots + entry.slots
			value = value + (entry.data and entry.data.sellPrice or 0) * entry.count
		end
	end
	if not next(toSell) then return end

	if ns.opts.confirmSales and (slots > ns.BUYBACK_SLOTS or value >= CONFIRM_VALUE) then
		StaticPopup_Show("ESAITHBAGFILTER_CONFIRM_SELL", L["%d stacks"]:format(slots), GetMoneyString(value, true), toSell)
	else
		ns:SellItems(toSell)
	end
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------

local function CreateCountLabel(row, parent)
	local count = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	count:SetPoint("RIGHT", row, "LEFT", SIDEBAR_WIDTH - 20, 0)
	count:SetTextColor(UI.MUTED:GetRGB())
	return count
end

local function BuildSidebar()
	local sidebar = UI.CreateSidebar(panel)

	local header = UI.CreateHeader(sidebar, L["Show"])
	header:SetPoint("TOPLEFT", 12, -12)

	local previous
	for _, quality in ipairs(ns.QUALITIES) do
		local row = UI.CreateCheckbox(sidebar, ns.QualityName(quality), nil,
			function() return ns.db.filters[quality] end,
			function(on)
				ns.db.filters[quality] = on
				Refresh()
			end)
		row.Text:SetTextColor(ns.QualityColor(quality):GetRGB())
		if previous then
			row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -2)
		else
			row:SetPoint("TOPLEFT", header, "BOTTOMLEFT", -4, -10)
		end
		row.count = CreateCountLabel(row, sidebar)
		qualityRows[quality] = row
		previous = row
	end

	hiddenToggle = UI.CreateCheckbox(sidebar, L["Hidden items"],
		L["Show items you've hidden with right-click, so you can bring them back."],
		function() return ns.db.showHidden end,
		function(on)
			ns.db.showHidden = on
			Refresh()
		end)
	hiddenToggle.Text:SetTextColor(UI.MUTED:GetRGB())
	hiddenToggle:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -12)
	hiddenToggle.count = CreateCountLabel(hiddenToggle, sidebar)

	local hint = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hint:SetPoint("BOTTOMLEFT", 12, 12)
	hint:SetPoint("BOTTOMRIGHT", -12, 12)
	hint:SetJustifyH("LEFT")
	hint:SetSpacing(2)
	hint:SetText(L["Click: keep or sell\nRight-click: hide\nShift-click: link"])
end

local function BuildGrid()
	scroll, content = UI.CreateScrollArea(panel)
	scroll:SetPoint("TOPLEFT", SIDEBAR_WIDTH + 4, -4)
	scroll:SetPoint("BOTTOMRIGHT", -24, 4)
	scroll:HookScript("OnSizeChanged", function() UI.RequestRefresh("loot") end)

	buttonPool = UI.CreatePool(CreateItemButton)
	headerPool = UI.CreatePool(CreateGroupHeader)

	emptyText = panel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	emptyText:SetPoint("CENTER", scroll, "CENTER")
	emptyText:SetWidth(320)
	emptyText:SetSpacing(3)
end

local function BuildHeaderAndFooter(window)
	dropdown = CreateFrame("DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
	dropdown:SetWidth(220)
	dropdown:SetPoint("LEFT", window, "TOPLEFT", UI.HEADER_X, UI.HEADER_Y)
	dropdown:SetDefaultText(L["All zones"])
	dropdown:SetupMenu(function(_, root)
		root:SetScrollMode(400)
		root:CreateRadio(L["All zones"],
			function() return selectedZone == nil end,
			function() selectedZone = nil; Refresh() end)

		local zones = ns:GetLootZones()
		if #zones > 0 then
			root:CreateDivider()
			root:CreateTitle(L["Looted in"])
		end
		for _, zone in ipairs(zones) do
			root:CreateRadio(zone,
				function() return selectedZone == zone end,
				function() selectedZone = zone; Refresh() end)
		end
	end)

	local runsButton = UI.CreateButton(panel, L["Recent Runs"], UI.HEADER_BUTTON_WIDTH, function(self)
		MenuUtil.CreateContextMenu(self, function(_, root)
			root:CreateTitle(L["Recent runs"])
			local runs = ns:GetRuns()
			if #runs == 0 then
				root:CreateTitle(UI.MUTED:WrapTextInColorCode(L["Dungeon, raid and delve runs show up here."]))
				return
			end
			root:SetScrollMode(420)
			local current = ns:GetCurrentRun()
			for _, run in ipairs(runs) do
				root:CreateDivider()
				local title = run.difficulty and run.difficulty ~= "" and ("%s (%s)"):format(run.zone, run.difficulty) or run.zone
				if run == current then title = title .. "  " .. UI.ACCENT:WrapTextInColorCode(L["now"]) end
				root:CreateTitle(title)
				local duration = UI.FormatDuration((run.ended or time()) - run.started)
				root:CreateTitle(HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(L["%s  ·  %s gold  ·  %s in items"]:format(
					duration, GetMoneyString(run.money, true), GetMoneyString(run.itemValue, true))))
			end
		end)
	end)
	runsButton:SetPoint("LEFT", dropdown, "RIGHT", 8, 0)
	UI.SetTooltip(runsButton, L["Recent Runs"],
		L["What your last dungeon, raid and delve runs earned: gold looted, plus the vendor value of the items you picked up."])

	searchBox = CreateFrame("EditBox", nil, panel, "SearchBoxTemplate")
	searchBox:SetSize(170, 20)
	searchBox:SetPoint("RIGHT", window, "TOPRIGHT", -16, UI.HEADER_Y)
	searchBox:SetAutoFocus(false)
	searchBox:HookScript("OnTextChanged", function(self)
		searchText = strtrim(self:GetText() or ""):lower()
		UI.RequestRefresh("loot")
	end)

	statusText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	statusText:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 14, 7)
	statusText:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -24 - UI.FOOTER_BUTTON_WIDTH * 2 - 12, 7)
	statusText:SetJustifyH("LEFT")
	statusText:SetWordWrap(false)

	sellButton = UI.CreateButton(panel, L["Sell Items"], UI.FOOTER_BUTTON_WIDTH, function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
		SellShownItems()
	end)
	sellButton:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -24, 4)
	sellButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip_SetTitle(GameTooltip, L["Sell Items"])
		if not ns.atMerchant then
			GameTooltip_AddErrorLine(GameTooltip, L["Talk to a vendor to sell."])
		elseif (self.sellCount or 0) == 0 then
			GameTooltip_AddNormalLine(GameTooltip, L["Nothing to sell with the current filters."])
		else
			GameTooltip_AddNormalLine(GameTooltip,
				L["Sells every item shown here that isn't faded. You can buy back the last 12 from the vendor."], true)
		end
		GameTooltip:Show()
	end)
	sellButton:SetScript("OnLeave", GameTooltip_Hide)

	undoButton = UI.CreateButton(panel, L["Undo Last Sale"], UI.FOOTER_BUTTON_WIDTH, function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
		ns:UndoLastSale()
	end)
	undoButton:SetPoint("RIGHT", sellButton, "LEFT", -6, 0)
	undoButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip_SetTitle(GameTooltip, L["Undo Last Sale"])
		if ns:CanUndoLastSale() then
			GameTooltip_AddNormalLine(GameTooltip,
				L["Buys back the %d stack(s) you just sold from this vendor's buyback list."]:format(ns:GetLastSaleCount()), true)
		else
			GameTooltip_AddNormalLine(GameTooltip,
				L["Available right after you sell, while the items are still on the vendor's buyback list."], true)
		end
		GameTooltip:Show()
	end)
	undoButton:SetScript("OnLeave", GameTooltip_Hide)
end

UI.RegisterPanel("loot", L["Loot"], {
	Build = function(frame, window)
		panel = frame
		BuildSidebar()
		BuildGrid()
		BuildHeaderAndFooter(window)

		-- Each time the window opens, start on the zone you're in (if you've looted anything there).
		window:HookScript("OnShow", function()
			local zone = ns.GetCurrentZone()
			selectedZone = (zone and tContains(ns:GetLootZones(), zone)) and zone or nil
			searchBox:SetText("")
		end)
	end,
	Refresh = Refresh,
})

local function QueueRefresh() UI.RequestRefresh("loot") end
ns:On("LOOT_CHANGED", QueueRefresh)
ns:On("ITEM_INFO_READY", QueueRefresh)
ns:On("SETTINGS_CHANGED", QueueRefresh)
ns:On("MERCHANT_CHANGED", QueueRefresh)
ns:On("SELLING_CHANGED", QueueRefresh)
ns:RegisterEvent("BAG_UPDATE_DELAYED", QueueRefresh)
ns:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE", QueueRefresh)
