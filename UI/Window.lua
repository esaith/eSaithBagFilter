-- eSaith Bag Filter
-- Window: the main frame, its tabs, shared widget helpers and the vendor button.

local _, ns = ...
local L = ns.L

local UI = {}
ns.UI = UI

local MIN_WIDTH, MIN_HEIGHT = 700, 440
local MAX_WIDTH, MAX_HEIGHT = 1600, 1100

-- Shared look: every tab uses these, so the window reads as one design.
UI.ACCENT = CreateColor(0.17, 0.76, 0.89)    -- the addon's signature cyan: addon-specific highlights
UI.MUTED = CreateColor(0.62, 0.62, 0.62)     -- secondary text, counts, empty cells
UI.GOOD = CreateColor(0.3, 0.9, 0.3)         -- complete / ready
UI.WARN = CreateColor(1, 0.55, 0.25)         -- saved / attention
UI.SIDEBAR_WIDTH = 160                        -- left column on the Loot and Settings tabs
UI.HEADER_BUTTON_WIDTH = 120                  -- buttons in the strip under the title
UI.FOOTER_BUTTON_WIDTH = 130                  -- buttons in the bottom bar
UI.HEADER_Y = -44                             -- vertical center of the strip under the title
UI.HEADER_X = 66                              -- first control, just right of the portrait

local frame
local tabs = {}
local panels = {}     -- key -> { Build = fn(panel), Refresh = fn() }
local panelOrder = {}
local currentKey

---------------------------------------------------------------------------
-- Shared widget helpers
---------------------------------------------------------------------------

function UI.SetTooltip(widget, title, body)
	widget:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(GameTooltip, title)
		if body then GameTooltip_AddNormalLine(GameTooltip, body, true) end
		GameTooltip:Show()
	end)
	widget:SetScript("OnLeave", GameTooltip_Hide)
end

function UI.CreateCheckbox(parent, label, tooltip, getValue, setValue)
	local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	check:SetSize(24, 24)
	check.Text:SetFontObject("GameFontHighlight")
	check.Text:SetText(label)
	check:SetHitRectInsets(0, -(check.Text:GetStringWidth() + 8), 0, 0)

	check:SetScript("OnClick", function(self)
		local on = self:GetChecked()
		PlaySound(on and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		setValue(on)
	end)
	if tooltip then UI.SetTooltip(check, label, tooltip) end

	function check:Refresh()
		self:SetChecked(getValue() and true or false)
	end
	check:SetScript("OnShow", check.Refresh)

	--- Dependent options are greyed out while the option they depend on is off.
	function check:SetDependentEnabled(enabled)
		self:SetEnabled(enabled)
		self.Text:SetFontObject(enabled and "GameFontHighlight" or "GameFontDisable")
	end
	return check
end

function UI.CreateButton(parent, text, width, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width or 140, 22)
	button:SetText(text)
	button:SetMotionScriptsWhileDisabled(true)
	button:SetScript("OnClick", onClick)
	return button
end

--- "3d 4h", "2h 15m", "8m".
function UI.FormatDuration(seconds)
	seconds = math.max(0, seconds or 0)
	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	if days > 0 then return L["%dd %dh"]:format(days, hours) end
	local minutes = math.floor((seconds % 3600) / 60)
	if hours > 0 then return L["%dh %dm"]:format(hours, minutes) end
	return L["%dm"]:format(math.max(1, minutes))
end

--- A sidebar / page background matching the Loot tab's sidebar.
function UI.CreateSidebar(parent)
	local sidebar = CreateFrame("Frame", nil, parent)
	sidebar:SetPoint("TOPLEFT")
	sidebar:SetPoint("BOTTOMLEFT")
	sidebar:SetWidth(UI.SIDEBAR_WIDTH)

	local bg = sidebar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.25)

	local divider = sidebar:CreateTexture(nil, "ARTWORK")
	divider:SetColorTexture(1, 1, 1, 0.08)
	divider:SetWidth(1)
	divider:SetPoint("TOPRIGHT")
	divider:SetPoint("BOTTOMRIGHT")
	return sidebar
end

--- A label with a dropdown of choices to its right. choices = { { value, label }, ... }.
function UI.CreateDropdownRow(parent, label, tooltip, choices, getValue, setValue)
	local row = CreateFrame("Frame", nil, parent)
	row:SetSize(360, 28)

	row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.label:SetPoint("LEFT", 4, 0)
	row.label:SetText(label)

	row.dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
	row.dropdown:SetWidth(170)
	row.dropdown:SetPoint("LEFT", row.label, "RIGHT", 10, 0)
	row.dropdown:SetupMenu(function(_, root)
		for _, choice in ipairs(choices) do
			root:CreateRadio(choice[2],
				function() return getValue() == choice[1] end,
				function() setValue(choice[1]) end)
		end
	end)
	if tooltip then
		row:EnableMouse(true)
		UI.SetTooltip(row, label, tooltip)
	end

	function row:Refresh()
		self.dropdown:GenerateMenu()
	end

	function row:SetEnabled(enabled)
		self.dropdown:SetEnabled(enabled)
		self.label:SetFontObject(enabled and "GameFontHighlight" or "GameFontDisable")
	end
	return row
end

--- A gold section title with a faint rule underneath.
function UI.CreateHeader(parent, text)
	local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	header:SetText(text)
	header:SetJustifyH("LEFT")

	local rule = parent:CreateTexture(nil, "ARTWORK")
	rule:SetColorTexture(1, 0.82, 0, 0.18)
	rule:SetHeight(1)
	rule:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
	rule:SetPoint("RIGHT", parent, "RIGHT", -12, 0)
	header.rule = rule
	return header
end

--- Vertical scroll area with Blizzard's modern scroll bar. Returns scrollFrame, content.
function UI.CreateScrollArea(parent)
	local scroll = CreateFrame("ScrollFrame", nil, parent, "ScrollFrameTemplate")
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	scroll:SetScript("OnSizeChanged", function(self, width)
		content:SetWidth(width)
	end)
	return scroll, content
end

--- A button that opens a menu of checkboxes, e.g. which characters to show.
--- getItems() returns { { key = ..., label = ... }, ... }.
function UI.CreateFilterButton(parent, text, emptyText, getItems, isChecked, setChecked)
	local button = UI.CreateButton(parent, text, 130, nil)
	button:SetScript("OnClick", function(self)
		MenuUtil.CreateContextMenu(self, function(_, root)
			local items = getItems()
			if #items == 0 then
				root:CreateTitle(emptyText)
				return
			end
			root:SetScrollMode(400)
			for _, item in ipairs(items) do
				root:CreateCheckbox(item.label,
					function() return isChecked(item.key) end,
					function() setChecked(item.key, not isChecked(item.key)) end)
			end
		end)
	end)
	return button
end

--- Simple object pool: pool:Acquire() returns a new or recycled object, pool:ReleaseAll() hides them all.
function UI.CreatePool(factory)
	local pool = { active = 0, objects = {} }
	function pool:Acquire()
		self.active = self.active + 1
		local obj = self.objects[self.active]
		if not obj then
			obj = factory()
			self.objects[self.active] = obj
		end
		obj:Show()
		return obj
	end
	function pool:ReleaseAll()
		for _, obj in ipairs(self.objects) do obj:Hide() end
		self.active = 0
	end
	return pool
end

---------------------------------------------------------------------------
-- Panels / tabs
---------------------------------------------------------------------------

--- Tab modules call this at load time; panels are built the first time the window opens.
function UI.RegisterPanel(key, label, definition)
	definition.key = key
	definition.label = label
	panels[key] = definition
	table.insert(panelOrder, key)
end

--- Refresh a panel only when it's actually on screen. Coalesces bursts of events into one redraw.
function UI.RequestRefresh(key)
	local panel = panels[key]
	if not panel or not panel.frame or not panel.frame:IsVisible() or panel.refreshQueued then return end
	panel.refreshQueued = true
	C_Timer.After(0, function()
		panel.refreshQueued = false
		if panel.frame:IsVisible() then panel.Refresh() end
	end)
end

local function SelectPanel(key)
	currentKey = key
	for index, panelKey in ipairs(panelOrder) do
		local panel = panels[panelKey]
		local selected = panelKey == key
		panel.frame:SetShown(selected)
		if selected then
			PanelTemplates_SetTab(frame, index)
			panel.Refresh()
		end
	end
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------

local function SaveGeometry()
	local db = ns.db.window
	local point, _, relativePoint, x, y = frame:GetPoint(1)
	db.point, db.relativePoint, db.x, db.y = point, relativePoint, x, y
	db.width, db.height = frame:GetSize()
end

local function RestoreGeometry()
	local db = ns.db.window
	frame:SetSize(
		Clamp(db.width or 760, MIN_WIDTH, MAX_WIDTH),
		Clamp(db.height or 520, MIN_HEIGHT, MAX_HEIGHT)
	)
	frame:ClearAllPoints()
	if db.point then
		frame:SetPoint(db.point, UIParent, db.relativePoint or db.point, db.x or 0, db.y or 0)
	else
		frame:SetPoint("CENTER")
	end
end

local function CreateResizeGrip()
	local grip = CreateFrame("Button", nil, frame)
	grip:SetSize(16, 16)
	grip:SetPoint("BOTTOMRIGHT", -3, 3)
	grip:SetFrameLevel(frame:GetFrameLevel() + 10)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
	grip:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
		SaveGeometry()
	end)
end

local function CreateTabs()
	for index, key in ipairs(panelOrder) do
		local tab = CreateFrame("Button", "eSaithBagFilterFrameTab" .. index, frame, "PanelTabButtonTemplate")
		tab:SetID(index)
		tab.Text:SetText(panels[key].label)
		if index == 1 then
			tab:SetPoint("BOTTOMLEFT", 12, -30)
		else
			tab:SetPoint("LEFT", tabs[index - 1], "RIGHT", 4, 0)
		end
		tab:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
			SelectPanel(key)
		end)
		tabs[index] = tab
	end
	frame.Tabs = tabs
	PanelTemplates_SetNumTabs(frame, #tabs)
end

local function CreateWindow()
	frame = CreateFrame("Frame", "eSaithBagFilterFrame", UIParent, "ButtonFrameTemplate")
	frame:Hide()
	frame:SetFrameStrata("HIGH")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SaveGeometry()
	end)
	frame:SetScript("OnShow", function()
		PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
		ns:Fire("WINDOW_TOGGLED", true)
	end)
	frame:SetScript("OnHide", function()
		PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
		ns:Fire("WINDOW_TOGGLED", false)
	end)

	frame:SetScale(ns.opts.uiScale or 1)
	frame:SetTitle(ns.title)
	frame:SetPortraitToAsset(ns.icon)
	tinsert(UISpecialFrames, frame:GetName()) -- close with Escape

	RestoreGeometry()
	CreateResizeGrip()

	for _, key in ipairs(panelOrder) do
		local panel = panels[key]
		panel.frame = CreateFrame("Frame", nil, frame)
		panel.frame:SetAllPoints(frame.Inset)
		panel.frame:SetFrameLevel(frame.Inset:GetFrameLevel() + 1)
		panel.frame:Hide()
		panel.Build(panel.frame, frame)
	end

	CreateTabs()
end

function UI.GetWindow()
	return frame
end

function ns:ShowWindow(key)
	if not frame then CreateWindow() end
	frame:Show()
	SelectPanel(key or currentKey or panelOrder[1])
end

function ns:HideWindow()
	if frame then frame:Hide() end
end

function ns:IsWindowShown()
	return frame ~= nil and frame:IsShown()
end

function ns:ToggleWindow(key)
	if self:IsWindowShown() and (not key or key == currentKey) then
		self:HideWindow()
	else
		self:ShowWindow(key)
	end
end

function ns:ResetWindowPosition()
	local db = ns.db.window
	db.point, db.relativePoint, db.x, db.y = nil, nil, nil, nil
	db.width, db.height = nil, nil
	if frame then RestoreGeometry() end
end

---------------------------------------------------------------------------
-- Reset confirmation
---------------------------------------------------------------------------

StaticPopupDialogs.ESAITHBAGFILTER_RESET = {
	text = L["Reset eSaith Bag Filter?\n\nThis erases your keep list, hidden items, loot history, lockouts for every character and all settings."],
	button1 = YES,
	button2 = NO,
	OnAccept = function() ns:ResetEverything() end,
	showAlert = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

function ns:ConfirmReset()
	StaticPopup_Show("ESAITHBAGFILTER_RESET")
end

---------------------------------------------------------------------------
-- "eFilter" tab on the vendor window + "open with vendor"
---------------------------------------------------------------------------

local openedByVendor = false

-- The tab only looks like a merchant tab. It isn't added to MerchantFrame's own tab list, because
-- changing Blizzard's merchant code from an addon can taint it. Clicking it opens or closes this window.
local function CreateMerchantTab()
	if not MerchantFrame or _G.eSaithBagFilterMerchantTab then return end

	local tab = CreateFrame("Button", "eSaithBagFilterMerchantTab", MerchantFrame, "PanelTabButtonTemplate")
	tab.Text:SetText("eFilter")

	local buybackTab = _G.MerchantFrameTab2
	if buybackTab then
		tab:SetPoint("LEFT", buybackTab, "RIGHT", 3, 0)
	else
		tab:SetPoint("TOPLEFT", MerchantFrame, "BOTTOMLEFT", 180, 2)
	end

	-- Show the tab as selected while the window is open.
	local function UpdateTabState()
		if ns:IsWindowShown() then
			PanelTemplates_SelectTab(tab)
		else
			PanelTemplates_DeselectTab(tab)
		end
	end
	UpdateTabState()
	tab:HookScript("OnShow", UpdateTabState) -- hook, not replace: the template sizes the tab in OnShow

	tab:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
		ns:ToggleWindow("loot")
	end)
	UI.SetTooltip(tab, ns.title, L["Choose which looted items to sell to this vendor."])

	ns:On("WINDOW_TOGGLED", UpdateTabState)
end

ns:RegisterEvent("PLAYER_LOGIN", CreateMerchantTab)

ns:On("SETTINGS_CHANGED", function()
	if frame then frame:SetScale(ns.opts.uiScale or 1) end
end)

ns:On("MERCHANT_CHANGED", function(atMerchant)
	if atMerchant then
		if ns.opts.openWithVendor and not ns:IsWindowShown() then
			openedByVendor = true
			ns:ShowWindow("loot")
		end
	elseif openedByVendor then
		openedByVendor = false
		ns:HideWindow()
	end
end)
