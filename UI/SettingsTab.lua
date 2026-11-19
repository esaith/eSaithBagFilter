-- eSaith Bag Filter
-- Settings tab: options, maintenance tools and what to show on the Lockouts tab.

local _, ns = ...
local UI = ns.UI

local ROW_GAP = -2
local SECTION_GAP = -18

local panel
local checkboxes = {}
local containerButton
local characterList, instanceList

local OPTION_SECTIONS = {
	{
		title = "Selling",
		{ "autoSellJunk", "Auto-sell junk", "Sells gray items as soon as you talk to a vendor." },
		{ "keepGreenBoE", "Keep green BoE items", "Never sell uncommon (green) Bind on Equip items." },
		{ "keepBlueBoE", "Keep blue BoE items", "Never sell rare (blue) Bind on Equip items." },
		{ "keepEpicBoE", "Keep epic BoE items", "Never sell epic (purple) Bind on Equip items." },
		{ "keepTradeGoods", "Keep trade goods", "Never sell crafting materials and other trade goods." },
		{ "openWithVendor", "Open with vendor", "Open this window automatically when you talk to a vendor." },
	},
	{
		title = "Looting",
		{ "quickLoot", "Quick loot", "Grabs everything in the loot window instantly." },
		{ "autoGreedGreens", "Auto-greed green items", "Automatically rolls Greed on uncommon (green) items in group loot." },
		{ "saveLootBetweenSessions", "Remember loot after logout",
			"Keeps your per-zone loot history between sessions, in case you log out before selling." },
	},
	{
		title = "Extras",
		{ "autoQuest", "Quest helper",
			"Accepts and turns in quests automatically, and takes the reward when there's only one. Hold Shift while talking to an NPC to do it yourself." },
		{ "showCoordinates", "Show coordinates", "Shows your map coordinates under the minimap (not available inside instances)." },
	},
}

StaticPopupDialogs.ESAITHBAGFILTER_CLEAR_KEPT = {
	text = "Clear your keep list?\n\nItems you're currently wearing stay protected.",
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		wipe(ns.db.kept)
		ns:ProtectEquippedItems()
		ns:Fire("LOOT_CHANGED")
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

---------------------------------------------------------------------------
-- Checklists (characters / instances shown on the Lockouts tab)
---------------------------------------------------------------------------

local function CreateChecklist(parent, title, emptyMessage, getItems, isChecked, setChecked)
	local list = CreateFrame("Frame", nil, parent)

	list.header = UI.CreateHeader(list, title)
	list.header:SetPoint("TOPLEFT")

	local bg = list:CreateTexture(nil, "BACKGROUND")
	bg:SetPoint("TOPLEFT", 0, -22)
	bg:SetPoint("BOTTOMRIGHT")
	bg:SetColorTexture(0, 0, 0, 0.25)

	local scroll, content = UI.CreateScrollArea(list)
	scroll:SetPoint("TOPLEFT", 4, -26)
	scroll:SetPoint("BOTTOMRIGHT", -22, 4)

	local empty = list:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	empty:SetPoint("TOPLEFT", scroll, "TOPLEFT", 6, -6)
	empty:SetPoint("RIGHT", scroll, "RIGHT", -6, 0)
	empty:SetJustifyH("LEFT")
	empty:SetText(emptyMessage)

	local pool = UI.CreatePool(function()
		local check = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
		check:SetSize(22, 22)
		check.Text:SetFontObject("GameFontHighlightSmall")
		check:SetScript("OnClick", function(self)
			setChecked(self.key, self:GetChecked())
			ns:Fire("LOCKOUTS_CHANGED")
		end)
		return check
	end)

	function list:Refresh()
		pool:ReleaseAll()
		local items = getItems()
		local labelWidth = math.max(80, scroll:GetWidth() - 30)
		for index, item in ipairs(items) do
			local check = pool:Acquire()
			check.key = item.key
			check.Text:SetText(item.label)
			check.Text:SetWidth(labelWidth)
			check.Text:SetWordWrap(false)
			check:SetHitRectInsets(0, -labelWidth, 0, 0)
			check:SetChecked(isChecked(item.key))
			check:ClearAllPoints()
			check:SetPoint("TOPLEFT", 0, -(index - 1) * 22)
		end
		content:SetHeight(math.max(1, #items * 22))
		empty:SetShown(#items == 0)
	end

	return list
end

local function GetCharacters()
	local items = {}
	for _, player in ipairs(ns:GetLockoutPlayers(true)) do
		local color = player.info.class and C_ClassColor.GetClassColor(player.info.class)
		local label = player.key
		if color then label = color:WrapTextInColorCode(player.info.name or player.key) .. " - " .. (player.info.realm or "") end
		table.insert(items, { key = player.key, label = label })
	end
	return items
end

local function GetInstances()
	local items = {}
	for _, instance in ipairs(ns:GetLockoutInstances(true)) do
		table.insert(items, { key = instance, label = instance })
	end
	return items
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------

local function BuildOptionColumns(column1, column2)
	local columnForSection = { column1, column1, column2 }
	local lastInColumn = {}

	for sectionIndex, section in ipairs(OPTION_SECTIONS) do
		local column = columnForSection[sectionIndex]
		local header = UI.CreateHeader(column, section.title)
		if lastInColumn[column] then
			header:SetPoint("TOPLEFT", lastInColumn[column], "BOTTOMLEFT", 4, SECTION_GAP)
		else
			header:SetPoint("TOPLEFT", 0, 0)
		end

		local previous
		for _, option in ipairs(section) do
			local key, label, tooltip = option[1], option[2], option[3]
			local check = UI.CreateCheckbox(column, label, tooltip,
				function() return ns.db.options[key] end,
				function(on)
					ns.db.options[key] = on
					ns:Fire("SETTINGS_CHANGED")
				end)
			if previous then
				check:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, ROW_GAP)
			else
				check:SetPoint("TOPLEFT", header, "BOTTOMLEFT", -4, -8)
			end
			table.insert(checkboxes, check)
			previous = check
		end
		lastInColumn[column] = previous
	end

	-- Tools
	local tools = UI.CreateHeader(column2, "Tools")
	tools:SetPoint("TOPLEFT", lastInColumn[column2], "BOTTOMLEFT", 4, SECTION_GAP)

	containerButton = UI.CreateButton(column2, "Open Containers", 180, function()
		if ns:IsOpeningContainers() then
			ns:StopOpeningContainers("Stopped opening containers.")
		else
			ns:OpenContainers()
		end
	end)
	containerButton:SetPoint("TOPLEFT", tools, "BOTTOMLEFT", 0, -12)
	UI.SetTooltip(containerButton, "Open Containers",
		"Opens clams, unlocked lockboxes, bags of loot and other containers in your bags, one after another. Doesn't work on items with a cast time.")

	local clearLoot = UI.CreateButton(column2, "Clear Loot History", 180, function()
		ns:ClearLootHistory()
		ns.Print("Loot history cleared. Your keep list wasn't changed.")
	end)
	clearLoot:SetPoint("TOPLEFT", containerButton, "BOTTOMLEFT", 0, -6)
	UI.SetTooltip(clearLoot, "Clear Loot History",
		"Forgets which zone each item was looted in. Your keep list isn't affected.")

	local clearKept = UI.CreateButton(column2, "Clear Keep List", 180, function()
		StaticPopup_Show("ESAITHBAGFILTER_CLEAR_KEPT")
	end)
	clearKept:SetPoint("TOPLEFT", clearLoot, "BOTTOMLEFT", 0, -6)
	UI.SetTooltip(clearKept, "Clear Keep List", "Lets every item you marked as kept be sold again.")

	local reset = UI.CreateButton(column2, "Reset Everything", 180, function() ns:ConfirmReset() end)
	reset:SetPoint("TOPLEFT", clearKept, "BOTTOMLEFT", 0, -6)
	UI.SetTooltip(reset, "Reset Everything", "Erases all settings, your keep list, loot history and lockouts.")
end

local function RefreshContainerButton()
	if not containerButton then return end
	if ns:IsOpeningContainers() then
		containerButton:SetText("Stop Opening")
	else
		local count = ns:CountContainers()
		containerButton:SetText(count > 0 and ("Open Containers (%d)"):format(count) or "Open Containers")
	end
end

local function Refresh()
	for _, check in ipairs(checkboxes) do check:Refresh() end
	RefreshContainerButton()
	characterList:Refresh()
	instanceList:Refresh()
end

UI.RegisterPanel("settings", SETTINGS or "Settings", {
	Build = function(frame, window)
		panel = frame

		local column1 = CreateFrame("Frame", nil, panel)
		column1:SetPoint("TOPLEFT", 18, -14)
		column1:SetPoint("BOTTOMLEFT", 18, 14)
		column1:SetWidth(230)

		local column2 = CreateFrame("Frame", nil, panel)
		column2:SetPoint("TOPLEFT", column1, "TOPRIGHT", 12, 0)
		column2:SetPoint("BOTTOMLEFT", column1, "BOTTOMRIGHT", 12, 0)
		column2:SetWidth(230)

		local column3 = CreateFrame("Frame", nil, panel)
		column3:SetPoint("TOPLEFT", column2, "TOPRIGHT", 12, 0)
		column3:SetPoint("BOTTOMRIGHT", -14, 14)

		panel:SetScript("OnSizeChanged", function(self, width)
			local columnWidth = math.floor((width - 70) / 3)
			column1:SetWidth(columnWidth)
			column2:SetWidth(columnWidth)
		end)

		BuildOptionColumns(column1, column2)

		characterList = CreateChecklist(column3, "Lockouts: Characters",
			"Characters appear here after you log in on them.",
			GetCharacters,
			function(key) return ns.lockoutDB.players[key] and ns.lockoutDB.players[key].shown end,
			function(key, on)
				if ns.lockoutDB.players[key] then ns.lockoutDB.players[key].shown = on end
			end)
		characterList:SetPoint("TOPLEFT")
		characterList:SetPoint("RIGHT")
		characterList:SetPoint("BOTTOM", column3, "CENTER", 0, 8)

		instanceList = CreateChecklist(column3, "Lockouts: Instances",
			"Instances appear here once one of your characters is saved to them.",
			GetInstances,
			function(key) return ns.lockoutDB.shownInstances[key] ~= false end,
			function(key, on) ns.lockoutDB.shownInstances[key] = on end)
		instanceList:SetPoint("TOP", column3, "CENTER", 0, -8)
		instanceList:SetPoint("LEFT")
		instanceList:SetPoint("BOTTOMRIGHT")

		local version = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		version:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 14, 9)
		version:SetText(("%s %s  ·  /efilter help for commands"):format(ns.title, ns.version))
	end,
	Refresh = Refresh,
})

ns:On("SETTINGS_CHANGED", function() UI.RequestRefresh("settings") end)
ns:On("LOCKOUTS_CHANGED", function() UI.RequestRefresh("settings") end)
ns:On("CONTAINERS_CHANGED", RefreshContainerButton)
ns:RegisterEvent("BAG_UPDATE_DELAYED", function()
	if panel and panel:IsVisible() then RefreshContainerButton() end
end)
