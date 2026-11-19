-- eSaith Bag Filter
-- Minimap button: click to open, drag to move around the minimap. No libraries needed.

local _, ns = ...
local L = ns.L

local button

local function UpdatePosition()
	local angle = math.rad(ns.db.minimap.angle or 225)
	local radius = (Minimap:GetWidth() / 2) + 10
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function OnDragUpdate()
	local mx, my = Minimap:GetCenter()
	local scale = Minimap:GetEffectiveScale()
	local cx, cy = GetCursorPosition()
	cx, cy = cx / scale, cy / scale
	ns.db.minimap.angle = math.deg(math.atan2(cy - my, cx - mx)) % 360
	UpdatePosition()
end

local function CreateButton()
	button = CreateFrame("Button", "eSaithBagFilterMinimapButton", Minimap)
	button:SetSize(31, 31)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	background:SetSize(20, 20)
	background:SetPoint("TOPLEFT", 7, -5)

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(ns.icon)
	icon:SetSize(17, 17)
	icon:SetPoint("TOPLEFT", 7, -6)
	icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetSize(53, 53)
	border:SetPoint("TOPLEFT")

	button:SetScript("OnClick", function(_, mouseButton)
		if mouseButton == "RightButton" then
			ns:ToggleWindow("settings")
		else
			ns:ToggleWindow()
		end
	end)
	button:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", OnDragUpdate)
		GameTooltip:Hide()
	end)
	button:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
	end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip_SetTitle(GameTooltip, ns.title)
		GameTooltip_AddInstructionLine(GameTooltip, L["Left-click to open"])
		GameTooltip_AddInstructionLine(GameTooltip, L["Right-click for settings"])
		GameTooltip_AddInstructionLine(GameTooltip, L["Drag to move"])
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", GameTooltip_Hide)

	UpdatePosition()
end

local function UpdateVisibility()
	if ns.opts.showMinimapButton then
		if not button then CreateButton() end
		button:Show()
	elseif button then
		button:Hide()
	end
end

ns:RegisterEvent("PLAYER_LOGIN", UpdateVisibility)
ns:On("SETTINGS_CHANGED", UpdateVisibility)
