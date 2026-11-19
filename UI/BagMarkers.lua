-- eSaith Bag Filter
-- Bag markers: a small coin on items in your bags that the Loot tab would sell.
-- Works with Blizzard's bags and Baganator. Other bag addons (e.g. W2UI Bags) aren't supported.

local _, ns = ...
local L = ns.L

local MARKER_TEXTURE = "Interface\\MoneyFrame\\UI-GoldIcon"
local sellable = {}

--- itemIDs the Loot tab would currently sell (looted, not kept, not hidden).
local function RebuildSellable()
	wipe(sellable)
	if not ns.opts.markBagItems then return end
	for itemID, entry in pairs(ns:GetLootedItems(nil)) do
		if not entry.keepReason then sellable[itemID] = true end
	end
end

function ns:WouldSell(itemID)
	return sellable[itemID] == true
end

---------------------------------------------------------------------------
-- Blizzard bags
---------------------------------------------------------------------------

local function GetMarker(button)
	if not button.eSaithSellMarker then
		local marker = button:CreateTexture(nil, "OVERLAY", nil, 6)
		marker:SetTexture(MARKER_TEXTURE)
		marker:SetSize(12, 12)
		marker:SetPoint("TOPLEFT", 2, -2)
		button.eSaithSellMarker = marker
	end
	return button.eSaithSellMarker
end

local function UpdateContainerFrame(frame)
	if not frame or not frame:IsShown() then return end
	for _, child in ipairs({ frame:GetChildren() }) do
		if child.GetBagID and child.GetID then
			local bag, slot = child:GetBagID(), child:GetID()
			local itemID = bag and slot and C_Container.GetContainerItemID(bag, slot)
			local show = itemID ~= nil and sellable[itemID] == true
			if show or child.eSaithSellMarker then
				GetMarker(child):SetShown(show)
			end
		end
	end
end

local function UpdateBlizzardBags()
	UpdateContainerFrame(ContainerFrameCombinedBags)
	for index = 1, NUM_CONTAINER_FRAMES or 13 do
		UpdateContainerFrame(_G["ContainerFrame" .. index])
	end
end

local function HookBlizzardBags()
	local frames = { ContainerFrameCombinedBags }
	for index = 1, NUM_CONTAINER_FRAMES or 13 do
		table.insert(frames, _G["ContainerFrame" .. index])
	end
	for _, frame in pairs(frames) do
		-- Wait a frame so Blizzard has filled the item buttons first.
		frame:HookScript("OnShow", function(self) C_Timer.After(0, function() UpdateContainerFrame(self) end) end)
	end
end

---------------------------------------------------------------------------
-- Baganator (optional). Its API is called with pcall so a change on its side can't cause errors here.
---------------------------------------------------------------------------

local baganatorRegistered = false

local function RegisterBaganator()
	if baganatorRegistered or not (Baganator and Baganator.API and Baganator.API.RegisterCornerWidget) then return end
	baganatorRegistered = pcall(Baganator.API.RegisterCornerWidget,
		L["eFilter: will sell"], "esaith_bag_filter_sell",
		function(marker, details)
			return details and details.itemID ~= nil and sellable[details.itemID] == true
		end,
		function(itemButton)
			local marker = itemButton:CreateTexture(nil, "OVERLAY")
			marker:SetTexture(MARKER_TEXTURE)
			marker:SetSize(12, 12)
			return marker
		end,
		{ corner = "top_left", priority = 1 })
end

local function RefreshBaganator()
	if baganatorRegistered and Baganator.API.RequestItemButtonsRefresh then
		pcall(Baganator.API.RequestItemButtonsRefresh)
	end
end

---------------------------------------------------------------------------
-- Updates
---------------------------------------------------------------------------

local pending = false
local function QueueUpdate()
	if pending then return end
	pending = true
	C_Timer.After(0.1, function()
		pending = false
		RebuildSellable()
		UpdateBlizzardBags()
		RefreshBaganator()
	end)
end

ns:RegisterEvent("PLAYER_LOGIN", function()
	HookBlizzardBags()
	RegisterBaganator()
	QueueUpdate()
end)
ns:RegisterEvent("ADDON_LOADED", function(_, name)
	if name == "Baganator" then RegisterBaganator() end
end)
ns:RegisterEvent("BAG_UPDATE_DELAYED", QueueUpdate)
ns:On("LOOT_CHANGED", QueueUpdate)
ns:On("SETTINGS_CHANGED", QueueUpdate)
ns:On("ITEM_INFO_READY", QueueUpdate)
