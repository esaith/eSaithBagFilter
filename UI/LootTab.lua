-- eSaith Bag Filter
-- Loot tab: everything you've looted (per zone) that's still in your bags, ready to sell.

local _, ns = ...
local UI = ns.UI

local BUTTON_SIZE = 37
local BUTTON_GAP = 6
local SIDEBAR_WIDTH = 160
local HEADER_HEIGHT = 24
local GRID_PADDING = 10

local selectedZone -- nil means every zone
local panel, dropdown, scroll, content, emptyText, statusText, sellButton
local qualityRows = {}
local buttonPool, headerPool

---------------------------------------------------------------------------
-- Item buttons
---------------------------------------------------------------------------

local function ItemButton_OnEnter(self)
	local entry = self.entry
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	local hasBagItem = C_Container.GetContainerItemID(entry.bag, entry.slot) == entry.itemID
	if hasBagItem then
		GameTooltip:SetBagItem(entry.bag, entry.slot)
	elseif entry.link then
		GameTooltip:SetHyperlink(entry.link)
	end

	GameTooltip_AddBlankLineToTooltip(GameTooltip)
	if entry.keepReason then
		GameTooltip_AddColoredLine(GameTooltip, "Kept: " .. entry.keepReason, UI.ACCENT)
	end
	if ns.db.kept[entry.itemID] then
		GameTooltip_AddInstructionLine(GameTooltip, "Click to allow selling")
	else
		GameTooltip_AddInstructionLine(GameTooltip, "Click to keep this item")
	end
	GameTooltip:Show()
end

local function ItemButton_OnClick(self)
	if HandleModifiedItemClick(self.entry.link) then return end
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	ns:ToggleKept(self.entry.itemID)
end

local function CreateItemButton()
	local button = CreateFrame("ItemButton", nil, content)
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	button.lock = button:CreateTexture(nil, "OVERLAY", nil, 7)
	button.lock:SetTexture("Interface\\PetBattles\\PetBattle-LockIcon")
	button.lock:SetSize(16, 16)
	button.lock:SetPoint("TOPRIGHT", 2, 2)

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
	button.icon:SetAlpha(kept and 0.45 or 1)
	if button.IconBorder then button.IconBorder:SetAlpha(kept and 0.45 or 1) end
	button.lock:SetShown(kept)

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

local function Refresh()
	-- Fall back to "All zones" if the selected zone has nothing left.
	if selectedZone and not tContains(ns:GetLootZones(), selectedZone) then
		selectedZone = nil
	end
	dropdown:GenerateMenu()

	local items = ns:GetLootedItems(selectedZone)
	local groups, counts = {}, {}
	for _, quality in ipairs(ns.QUALITIES) do
		groups[quality], counts[quality] = {}, 0
	end

	local sellCount, sellValue, keptCount = 0, 0, 0
	for _, entry in pairs(items) do
		local quality = entry.quality
		if groups[quality] then
			counts[quality] = counts[quality] + 1
			if ns.db.filters[quality] then
				table.insert(groups[quality], entry)
				if entry.keepReason then
					keptCount = keptCount + 1
				else
					sellCount = sellCount + 1
					sellValue = sellValue + (entry.data and entry.data.sellPrice or 0) * entry.count
				end
			end
		end
	end

	-- Sidebar counts
	for quality, row in pairs(qualityRows) do
		row.count:SetText(counts[quality] > 0 and counts[quality] or "")
		row:Refresh()
	end

	-- Grid, grouped by quality from junk upwards
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

			local rows = math.ceil(#group / perRow)
			y = y - rows * (BUTTON_SIZE + BUTTON_GAP) - 8
		end
	end
	content:SetHeight(-y + GRID_PADDING)

	if shown == 0 then
		emptyText:SetText(next(items) and "No items match the selected qualities."
			or "Nothing to sell yet.\n\nItems you loot are listed here, grouped by the zone you looted them in.")
		emptyText:Show()
	else
		emptyText:Hide()
	end

	-- Status bar
	if sellCount > 0 then
		statusText:SetFormattedText("%d to sell  |cff9d9d9d·|r  %s%s", sellCount, GetMoneyString(sellValue, true),
			keptCount > 0 and ("  |cff9d9d9d·  %d kept|r"):format(keptCount) or "")
	elseif keptCount > 0 then
		statusText:SetFormattedText("|cff9d9d9d%d kept, nothing to sell|r", keptCount)
	else
		statusText:SetText("")
	end

	sellButton.sellCount = sellCount
	sellButton:SetEnabled(ns.atMerchant and sellCount > 0 and not ns:IsSelling())
	sellButton:SetText(ns:IsSelling() and "Selling..." or "Sell Items")
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------

local function SellShownItems()
	local items = ns:GetLootedItems(selectedZone)
	local toSell = {}
	for itemID, entry in pairs(items) do
		if ns.db.filters[entry.quality] and not entry.keepReason then
			toSell[itemID] = true
		end
	end
	ns:SellItems(toSell)
end

local function BuildSidebar()
	local sidebar = CreateFrame("Frame", nil, panel)
	sidebar:SetPoint("TOPLEFT")
	sidebar:SetPoint("BOTTOMLEFT")
	sidebar:SetWidth(SIDEBAR_WIDTH)

	local bg = sidebar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.25)

	local divider = sidebar:CreateTexture(nil, "ARTWORK")
	divider:SetColorTexture(1, 1, 1, 0.08)
	divider:SetWidth(1)
	divider:SetPoint("TOPRIGHT")
	divider:SetPoint("BOTTOMRIGHT")

	local header = UI.CreateHeader(sidebar, "Show")
	header:SetPoint("TOPLEFT", 12, -12)

	local previous
	for _, quality in ipairs(ns.QUALITIES) do
		local row = UI.CreateCheckbox(sidebar, ns.QualityName(quality),
			nil,
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

		row.count = sidebar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.count:SetPoint("RIGHT", row, "LEFT", SIDEBAR_WIDTH - 20, 0)
		row.count:SetTextColor(UI.MUTED:GetRGB())

		qualityRows[quality] = row
		previous = row
	end

	local hint = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hint:SetPoint("BOTTOMLEFT", 12, 12)
	hint:SetPoint("BOTTOMRIGHT", -12, 12)
	hint:SetJustifyH("LEFT")
	hint:SetSpacing(2)
	hint:SetText("Click an item to keep it.\nKept items are faded and never sold.\nShift-click to link.")
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
	dropdown:SetWidth(240)
	dropdown:SetPoint("TOPLEFT", window, "TOPLEFT", 66, -30)
	dropdown:SetDefaultText("All zones")
	dropdown:SetupMenu(function(_, root)
		root:SetScrollMode(400)
		root:CreateRadio("All zones",
			function() return selectedZone == nil end,
			function() selectedZone = nil; Refresh() end)

		local zones = ns:GetLootZones()
		if #zones > 0 then
			root:CreateDivider()
			root:CreateTitle("Looted in")
		end
		for _, zone in ipairs(zones) do
			root:CreateRadio(zone,
				function() return selectedZone == zone end,
				function() selectedZone = zone; Refresh() end)
		end
	end)

	statusText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	statusText:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 14, 7)
	statusText:SetJustifyH("LEFT")

	sellButton = UI.CreateButton(panel, "Sell Items", 130, function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
		SellShownItems()
	end)
	sellButton:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -24, 4)
	sellButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip_SetTitle(GameTooltip, "Sell Items")
		if not ns.atMerchant then
			GameTooltip_AddErrorLine(GameTooltip, "Talk to a vendor to sell.")
		elseif (self.sellCount or 0) == 0 then
			GameTooltip_AddNormalLine(GameTooltip, "Nothing to sell with the current filters.")
		else
			GameTooltip_AddNormalLine(GameTooltip,
				"Sells every item shown here that isn't faded. You can buy back the last 12 from the vendor.", true)
		end
		GameTooltip:Show()
	end)
	sellButton:SetScript("OnLeave", GameTooltip_Hide)
end

UI.RegisterPanel("loot", "Loot", {
	Build = function(frame, window)
		panel = frame
		BuildSidebar()
		BuildGrid()
		BuildHeaderAndFooter(window)
		-- Start from "All zones" each time the window opens.
		window:HookScript("OnShow", function() selectedZone = nil end)
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
