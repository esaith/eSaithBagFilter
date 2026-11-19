-- eSaith Bag Filter
-- Settings tab: a page list on the left (matching the Loot tab's sidebar) and one page of options at a time.

local _, ns = ...
local L = ns.L
local UI = ns.UI

local ROW_HEIGHT = 26
local INDENT = 22
local PAGE_PADDING = 18

local panel, scopeText
local pages = {}      -- built pages, in order
local navButtons = {}
local currentPage

local SCALE_CHOICES = {
	{ 0.8, "80%" }, { 0.9, "90%" }, { 1, "100%" }, { 1.1, "110%" }, { 1.25, "125%" },
}

local AUCTION_CHOICES = {
	{ 2, L["2× the vendor price"] },
	{ 3, L["3× the vendor price"] },
	{ 5, L["5× the vendor price"] },
	{ 10, L["10× the vendor price"] },
}

---------------------------------------------------------------------------
-- Page definitions
--
-- Row types:
--   { "check", optionKey, label, tooltip, parent = optionKey }   -- parent: greyed out while that option is off
--   { "dropdown", optionKey, label, tooltip, choices, parent = optionKey }
--   { "note", function() return text end }
--   { "button", label, description, onClick }
---------------------------------------------------------------------------

StaticPopupDialogs.ESAITHBAGFILTER_CLEAR_KEPT = {
	text = L["Clear your keep list?\n\nItems you're currently wearing stay protected."],
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

local function PriceSourceNote()
	local source = ns:GetPriceSourceName()
	if source then
		return UI.GOOD:WrapTextInColorCode(L["Using prices from %s."]:format(source))
	end
	return UI.MUTED:WrapTextInColorCode(L["Needs TradeSkillMaster or Auctionator for Auction House prices."])
end

local function ScopeNote()
	local name = UnitName("player")
	if ns.charDB.useCharacterSettings then
		return UI.ACCENT:WrapTextInColorCode(L["%s is using its own settings."]:format(name))
	end
	return UI.MUTED:WrapTextInColorCode(L["%s is using the settings shared by all your characters."]:format(name))
end

local PAGE_DEFINITIONS = {
	{
		title = L["Selling"],
		description = L["What happens when you talk to a vendor."],
		{ "check", "autoSellJunk", L["Auto-sell junk"], L["Sells gray items as soon as you talk to a vendor."] },
		{ "check", "confirmSales", L["Confirm big sales"],
			L["Asks before selling more than 12 stacks (more than the vendor can buy back) or more than 100 gold of items at once."] },
		{ "check", "autoRepair", L["Auto-repair"], L["Repairs all your gear when you talk to a vendor that can repair."] },
		{ "check", "repairWithGuildFunds", L["Use guild funds first"],
			L["Pays for repairs from the guild bank when your guild allows it, and from your own gold otherwise."],
			parent = "autoRepair" },
		{ "check", "openWithVendor", L["Open with vendor"], L["Open this window automatically when you talk to a vendor."] },
	},
	{
		title = L["Keep Rules"],
		description = L["Items matching any rule are faded on the Loot tab and never sold."],
		{ "check", "keepGreenBoE", L["Keep green BoE items"], L["Never sell uncommon (green) Bind on Equip items."] },
		{ "check", "keepBlueBoE", L["Keep blue BoE items"], L["Never sell rare (blue) Bind on Equip items."] },
		{ "check", "keepEpicBoE", L["Keep epic BoE items"], L["Never sell epic (purple) Bind on Equip items."] },
		{ "check", "keepUpgrades", L["Keep gear at your item level"],
			L["Never sell weapons or armor at or above your equipped item level, including gear for your other specs."] },
		{ "check", "keepTradeGoods", L["Keep trade goods"], L["Never sell crafting materials and other trade goods."] },
		{ "check", "keepAuctionValue", L["Keep items worth more on the Auction House"],
			L["Never sell items that would fetch much more on the Auction House than from a vendor."] },
		{ "dropdown", "auctionMultiplier", L["When worth at least"],
			L["How much more than the vendor price an item must be worth on the Auction House to be kept."],
			AUCTION_CHOICES, parent = "keepAuctionValue" },
		{ "note", PriceSourceNote, parent = "keepAuctionValue" },
	},
	{
		title = L["Looting & Quests"],
		description = L["Helpers for while you're out playing."],
		{ "check", "quickLoot", L["Quick loot"], L["Grabs everything in the loot window instantly."] },
		{ "check", "autoGreedGreens", L["Auto-greed green items"],
			L["Automatically rolls Greed on uncommon (green) items in group loot."] },
		{ "check", "saveLootBetweenSessions", L["Remember loot after logout"],
			L["Keeps your per-zone loot history between sessions, in case you log out before selling."] },
		{ "check", "autoQuest", L["Quest helper"],
			L["Accepts and turns in quests automatically, and takes the reward when there's only one. Hold Shift while talking to an NPC to do it yourself."] },
	},
	{
		title = L["Interface"],
		description = L["How the addon looks and where it shows up."],
		{ "dropdown", "uiScale", L["Window size"], L["Makes this window bigger or smaller."], SCALE_CHOICES },
		{ "check", "showMinimapButton", L["Minimap button"],
			L["Left-click opens the window, right-click opens settings, drag to move it."] },
		{ "check", "markBagItems", L["Mark sellable items in bags"],
			L["Puts a small coin on items in your bags that the Loot tab would sell. Works with Blizzard's bags and Baganator."] },
		{ "check", "showCoordinates", L["Show coordinates"],
			L["Shows your map coordinates under the minimap (not available inside instances)."] },
	},
	{
		title = L["This Character"],
		description = L["By default every character shares the same settings."],
		{ "scope" },
		{ "note", ScopeNote },
		{ "note", function()
			return UI.MUTED:WrapTextInColorCode(L["Your keep list, hidden items, loot history and recent runs are always shared."])
		end },
	},
	{
		title = L["Tools"],
		description = L["One-off actions. Clearing and resetting can't be undone."],
		{ "button", L["Open Containers"],
			L["Opens clams, unlocked lockboxes and other containers in your bags, one after another."],
			function()
				if ns:IsOpeningContainers() then
					ns:StopOpeningContainers(L["Stopped opening containers."])
				else
					ns:OpenContainers()
				end
			end, key = "containers" },
		{ "button", L["Clear Loot History"], L["Forgets which zone each item was looted in."], function()
			ns:ClearLootHistory()
			ns.Print(L["Loot history cleared. Your keep list wasn't changed."])
		end },
		{ "button", L["Clear Recent Runs"], L["Empties the Recent Runs list on the Loot tab."], function()
			ns:ClearRuns()
			ns.Print(L["Recent runs cleared."])
		end },
		{ "button", L["Unhide All Items"], L["Brings back every item you hid with right-click."], function()
			wipe(ns.db.hidden)
			ns:Fire("LOOT_CHANGED")
			ns.Print(L["All hidden items are shown again."])
		end },
		{ "button", L["Clear Keep List"], L["Lets every item you marked as kept be sold again."], function()
			StaticPopup_Show("ESAITHBAGFILTER_CLEAR_KEPT")
		end },
		{ "button", L["Reset Everything"], L["Erases all settings, lists, history and lockouts."], function()
			ns:ConfirmReset()
		end },
	},
}

---------------------------------------------------------------------------
-- Building pages
---------------------------------------------------------------------------

local function SetOption(key, value)
	ns.opts[key] = value
	ns:Fire("SETTINGS_CHANGED")
end

local function BuildRow(page, def)
	local kind = def[1]

	if kind == "check" then
		local key = def[2]
		return UI.CreateCheckbox(page, def[3], def[4],
			function() return ns.opts[key] end,
			function(on) SetOption(key, on) end), ROW_HEIGHT

	elseif kind == "dropdown" then
		local key = def[2]
		return UI.CreateDropdownRow(page, def[3], def[4], def[5],
			function() return ns.opts[key] end,
			function(value) SetOption(key, value) end), ROW_HEIGHT + 6

	elseif kind == "note" then
		local note = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		note:SetJustifyH("LEFT")
		note:SetWidth(420)
		note.Refresh = function(self) self:SetText(def[2]()) end
		return note, 20

	elseif kind == "scope" then
		return UI.CreateCheckbox(page, L["Use separate settings for this character"],
			L["Gives this character its own copy of every option, starting from your current settings."],
			function() return ns.charDB.useCharacterSettings end,
			function(on) ns:SetUseCharacterSettings(on) end), ROW_HEIGHT

	elseif kind == "button" then
		local button = UI.CreateButton(page, def[2], 170, def[4])
		button.description = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		button.description:SetPoint("LEFT", button, "RIGHT", 12, 0)
		button.description:SetPoint("RIGHT", page, "RIGHT", -PAGE_PADDING, 0)
		button.description:SetJustifyH("LEFT")
		button.description:SetText(UI.MUTED:WrapTextInColorCode(def[3]))
		if def.key == "containers" then page.containerButton = button end
		return button, ROW_HEIGHT + 6
	end
end

local function BuildPage(definition)
	local page = CreateFrame("Frame", nil, panel)
	page:SetPoint("TOPLEFT", UI.SIDEBAR_WIDTH + PAGE_PADDING, -14)
	page:SetPoint("BOTTOMRIGHT", -PAGE_PADDING, 14)
	page:Hide()
	page.rows = {}

	local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT")
	title:SetText(definition.title)

	local description = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	description:SetText(UI.MUTED:WrapTextInColorCode(definition.description))

	local rule = page:CreateTexture(nil, "ARTWORK")
	rule:SetColorTexture(1, 0.82, 0, 0.18)
	rule:SetHeight(1)
	rule:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -8)
	rule:SetPoint("RIGHT", page, "RIGHT")

	local y = -60
	for _, def in ipairs(definition) do
		local widget, height = BuildRow(page, def)
		local x = def.parent and INDENT or 0
		if def[1] == "note" then x = x + 4 end
		widget:SetPoint("TOPLEFT", x, y - (def[1] == "note" and 4 or 0))
		widget.parentKey = def.parent
		table.insert(page.rows, widget)
		y = y - height
	end

	return page
end

local function RefreshContainerButton()
	local page = pages[#pages]
	local button = page and page.containerButton
	if not button then return end
	if ns:IsOpeningContainers() then
		button:SetText(L["Stop Opening"])
	else
		local count = ns:CountContainers()
		button:SetText(count > 0 and L["Open Containers (%d)"]:format(count) or L["Open Containers"])
	end
end

local function RefreshPage(page)
	for _, widget in ipairs(page.rows) do
		if widget.Refresh then widget:Refresh() end
		if widget.parentKey then
			local enabled = ns.opts[widget.parentKey] and true or false
			if widget.SetDependentEnabled then
				widget:SetDependentEnabled(enabled)
			elseif widget.SetEnabled then
				widget:SetEnabled(enabled)
			elseif widget.SetAlpha then
				widget:SetAlpha(enabled and 1 or 0.5)
			end
		end
	end
end

---------------------------------------------------------------------------
-- Navigation
---------------------------------------------------------------------------

local function SelectPage(index)
	currentPage = index
	for i, page in ipairs(pages) do
		page:SetShown(i == index)
		navButtons[i]:SetSelected(i == index)
	end
	RefreshPage(pages[index])
	RefreshContainerButton()
end

local function CreateNavButton(sidebar, index, text)
	local button = CreateFrame("Button", nil, sidebar)
	button:SetHeight(26)

	button.selected = button:CreateTexture(nil, "BACKGROUND")
	button.selected:SetAllPoints()
	button.selected:SetColorTexture(UI.ACCENT.r, UI.ACCENT.g, UI.ACCENT.b, 0.18)

	button.bar = button:CreateTexture(nil, "ARTWORK")
	button.bar:SetColorTexture(UI.ACCENT:GetRGB())
	button.bar:SetWidth(2)
	button.bar:SetPoint("TOPLEFT")
	button.bar:SetPoint("BOTTOMLEFT")

	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(1, 1, 1, 0.06)

	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	button.text:SetPoint("LEFT", 10, 0)
	button.text:SetText(text)

	function button:SetSelected(selected)
		self.selected:SetShown(selected)
		self.bar:SetShown(selected)
		self.text:SetFontObject(selected and "GameFontHighlight" or "GameFontNormal")
	end

	button:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		SelectPage(index)
	end)
	return button
end

local function Refresh()
	scopeText:SetText(ns.charDB.useCharacterSettings
		and UI.ACCENT:WrapTextInColorCode(L["Settings for this character only"])
		or UI.MUTED:WrapTextInColorCode(L["Settings shared by all characters"]))
	SelectPage(currentPage or 1)
end

UI.RegisterPanel("settings", SETTINGS or L["Settings"], {
	Build = function(frame, window)
		panel = frame

		local sidebar = UI.CreateSidebar(panel)
		local previous
		for index, definition in ipairs(PAGE_DEFINITIONS) do
			pages[index] = BuildPage(definition)
			local button = CreateNavButton(sidebar, index, definition.title)
			if previous then
				button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -2)
				button:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -2)
			else
				button:SetPoint("TOPLEFT", 6, -10)
				button:SetPoint("TOPRIGHT", -6, -10)
			end
			navButtons[index] = button
			previous = button
		end

		scopeText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		scopeText:SetPoint("LEFT", window, "TOPLEFT", UI.HEADER_X + 4, UI.HEADER_Y)

		local version = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		version:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 14, 9)
		version:SetText(("%s %s  ·  %s"):format(ns.title, ns.version, L["/efilter help for commands"]))
	end,
	Refresh = Refresh,
})

ns:On("SETTINGS_CHANGED", function() UI.RequestRefresh("settings") end)
ns:On("CONTAINERS_CHANGED", RefreshContainerButton)
ns:RegisterEvent("BAG_UPDATE_DELAYED", function()
	if panel and panel:IsVisible() then RefreshContainerButton() end
end)
