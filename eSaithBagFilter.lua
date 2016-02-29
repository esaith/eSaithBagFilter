SLASH_ESAITHBAGFILTER1 = '/filter'

local function printTable(tb, spacing)
	if spacing == nil then spacing = "" end
	print(spacing .. "Entering table")
	if tb == nil then print("Table is nil") return end
	for k, v in pairs(tb) do
		print(spacing .. "K: " .. k .. ", v: " .. tostring(v))
		if type(v) == "table" then
			printTable(v, "   " .. spacing)
		end
	end
	print(spacing .. "Leaving Table")
end

local function AddLoot(obj)
	local zone = GetRealZoneText()
	if eSaithBagFilterInstanceLoot[zone] == nil then eSaithBagFilterInstanceLoot[zone] = { } end
	eSaithBagFilterInstanceLoot[zone][obj] = true
end
local function CreateCheckButtons()
	for index, _type in ipairs(eSaithBagFilterVar.properties.types) do
		local btn = CreateFrame("CheckButton", "$parentCheckButton" .. _type, eSaithBagFilter, "UICheckButtonTemplate")
		btn:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 70, -30)
		btn:SetScript("OnClick", eSaithBagFilterCheckBox_Click)
		local fontstring = btn:CreateFontString("eSaithBagFilterCheckButton" .. _type .. "FontString", "ARTWORK", "GameFontNormal")
		fontstring:SetTextColor(eSaithBagFilterVar.properties.texture[3 * index], eSaithBagFilterVar.properties.texture[3 * index + 1], eSaithBagFilterVar.properties.texture[3 * index + 2])
		fontstring:SetText("Filter " .. _type .. " Items")
		fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
		btn:SetFontString(fontstring)
		btn:Hide()
	end

	-- Reset button
	local cxBtn = CreateFrame("Button", "$parentResetButton", eSaithBagFilter, "UIPanelButtonTemplate")
	cxBtn:SetSize(100, 30)
	cxBtn:SetPoint("BOTTOMRIGHT", "$parent", "BOTTOMRIGHT", -15, 15)
	cxBtn:SetScript("OnClick", eSaithBagFilterResetButton_Click)
	local cxFont = cxBtn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	cxFont:SetText("|cffffffffReset Addon")
	cxFont:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
	cxFont:Show()
	cxBtn:Show()

	local fontstring = eSaithBagFilter:CreateFontString("$parentDoNotSellFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText("|cffff0000Do Not Sell:")
	fontstring:SetPoint("CENTER", "$parent", "TOP", 0, -87)
	fontstring:Show()

	local btn = CreateFrame("CheckButton", "eSaithBagFilterCheckButton_TradeGoods", eSaithBagFilter, "UICheckButtonTemplate")
	btn:SetPoint("CENTER", "$parent", "CENTER", -50, 60)
	local fontstring = btn:CreateFontString("eSaithBagFilterCheckButtonTradeGoodsFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText("Trade Goods")
	fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
	btn:SetFontString(fontstring)
	btn:Show()
end
local function CreateRarityObjects()
	eSaithBagFilterInstanceLoot = eSaithBagFilterInstanceLoot or { }

	if eSaithBagFilterVar == nil then
		eSaithBagFilterVar = {
			properties =
			{
				LeftTab = 1,
				BottomTab = 1,
				zone = nil,
				types = { "Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Artifact", "Heirloom", "WoW Token" },
				colors = { "Gray", "White", "Green", "Blue", "Purple", "Orange"-- , "Gold", "Gold", "Cyan"
				},
				texture = { 0, 0, .6, .6, .6, 1, 1, 1, 0, 1, 0, .2, .2, 1, 1, 0, 1, .8, .8, 0 },
				update = false,
				updateCount = 0,
				itemUpdateCount = 0,
				updateInterval = 1.0,
				maxTime = 0,
				keep = { },
				addonVersion = 0,
				point = "CENTER",
				relativeTo = "UIParent",
				relativePoint = "CENTER",
				xOffset = 0,
				yOffset = 0,
				sell = { }
			}
		}
		for index, _type in pairs(eSaithBagFilterVar.properties.types) do
			eSaithBagFilterVar[_type] = { }
			eSaithBagFilterVar[_type].checked = false
			eSaithBagFilterVar[_type].min = 0
			eSaithBagFilterVar[_type].max = 0
			eSaithBagFilterVar[_type].minChecked = false
			eSaithBagFilterVar[_type].maxChecked = false
		end
	end
end
local function CreateSliders()
	local min = CreateFrame("Frame", "$parentSliderMin", eSaithBagFilter, "eSaithBagFilterSliderTemplate")
	min:SetPoint("TOP", "$parent", "TOP", 0, -75)
	_G[min:GetName() .. 'SliderTitle']:SetText("Minimum Item Level")
	min:Hide()
	local max = CreateFrame("Frame", "$parentSliderMax", eSaithBagFilter, "eSaithBagFilterSliderTemplate")
	max:SetPoint("TOP", "$parentSliderMin", "TOP", 0, -50)
	_G[max:GetName() .. 'SliderTitle']:SetText("Maximum Item Level")
	max:Hide()
end
local function UpdateZoneTable(zone)
	if zone == nil or eSaithBagFilterInstanceLoot[zone] == nil then return end
	local zoneTable = eSaithBagFilterInstanceLoot[zone]

	-- Set all values that are currently non-nil to false. This will set the stage to filtering what is still in the
	-- bags vs what has already been sold. If the value is nil, the item has already been sold
	for item, value in pairs(zoneTable) do
		if value ~= nil then
			value = false
		end
	end

	-- Stage 2: Search each item bag slot. If the bag slot matches a non-nil table item, then the item has not been cleared
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 0, GetContainerNumSlots(bag) do
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture and zoneTable[link] ~= nil then
				zoneTable[link] = true
			end
		end
	end

	-- Stage 3. If an item in the zone table is still false, then the item is no longer in the bags. The user must have removed it at
	-- some point. Update the table. If the table is found to be full nil, then nil out the table.

	local count = 0
	for item, value in pairs(zoneTable) do
		if value then
			count = count + 1
		else
			value = nil
		end
	end

	if count == 0 then eSaithBagFilterInstanceLoot[zone] = nil end
end
local function ResetAlphaOnAllSlots()
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 0, GetContainerNumSlots(bag) do
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then
				_G["ContainerFrame" ..(bag + 1) .. "Item" ..(GetContainerNumSlots(bag) - slot + 1)]:SetAlpha(1)
			end
		end
	end
end
local function PassMin(ilvl, minlvl, required)
	return not required or ilvl >= minlvl
end
local function PassMax(ilvl, maxlvl, required)
	return not required or ilvl <= maxlvl
end
local function DimBagSlotZone(zone)
	if zone == nil or eSaithBagFilterInstanceLoot[zone] == nil then return end
	local alpha
	local zoneTable = eSaithBagFilterInstanceLoot[zone]

	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then
				alpha = .2		
				_G["ContainerFrame" ..(bag + 1) .. "Item" ..(GetContainerNumSlots(bag) - slot + 1)].newitemglowAnim:Stop()		
				local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link)
				if zoneTable[link] then alpha = 1 end
				_G["ContainerFrame" ..(bag + 1) .. "Item" ..(GetContainerNumSlots(bag) - slot + 1)]:SetAlpha(alpha)
			end
		end
	end
end
local function DimBagSlotiLVL()
	-- Quick escape. If no checkbox is marked, then make sure all slots are full alpha then exit
	local found = false
	for k, _type in pairs(eSaithBagFilterVar.properties.types) do
		if _G["eSaithBagFilterCheckButton" .. _type]:GetChecked() then
			found = true
			break
		end
	end

	if not found then
		ResetAlphaOnAllSlots()
		return
	end

	local alpha
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 0, GetContainerNumSlots(bag) do
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then
				alpha = .2
				_G["ContainerFrame" ..(bag + 1) .. "Item" ..(GetContainerNumSlots(bag) - slot + 1)].newitemglowAnim:Stop()
				local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link)
				if vendorPrice > 0 and not locked and not lootable then
					-- Skip all items that cannot be sold to vendors					
					local _type = eSaithBagFilterVar.properties.types[quality + 1]
					if _G["eSaithBagFilterCheckButton" .. _type]:GetChecked()
						and PassMin(ilvl, eSaithBagFilterVar[_type].min, eSaithBagFilterVar[_type].minChecked)
						and PassMax(ilvl, eSaithBagFilterVar[_type].max, eSaithBagFilterVar[_type].maxChecked) then
						alpha = 1
					end
				end
				_G["ContainerFrame" ..(bag + 1) .. "Item" ..(GetContainerNumSlots(bag) - slot + 1)]:SetAlpha(alpha)
			end
		end
	end
end
local function DimBagSlotType()
	-- Quick escape. If no checkbox is marked, then make sure all slots are full alpha then exit
	local found = false
	for k, _type in pairs(eSaithBagFilterVar.properties.types) do
		if _G["eSaithBagFilterCheckButton" .. _type]:GetChecked() then
			found = true
			break
		end
	end

	if not found then
		ResetAlphaOnAllSlots()
		return
	end

	local alpha
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 0, GetContainerNumSlots(bag) do
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then
				alpha = .2
				_G["ContainerFrame" ..(bag + 1) .. "Item" ..(GetContainerNumSlots(bag) - slot + 1)].newitemglowAnim:Stop()
				local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link)
				local _type = eSaithBagFilterVar.properties.types[quality + 1]
				if _G["eSaithBagFilterCheckButton" .. _type]:GetChecked() and vendorPrice > 0 and not lootable then
					alpha = 1
				end
				_G["ContainerFrame" ..(bag + 1) .. "Item" ..(GetContainerNumSlots(bag) - slot + 1)]:SetAlpha(alpha)
			end
		end
	end
end

local function ZoneMenuItemFunction(self, arg1, arg2, checked)
	eSaithBagFilterVar.properties.zone = self.arg1

	-- Update the table prior to using it
	UpdateZoneTable(self.arg1)
	local zoneTable = eSaithBagFilterInstanceLoot[self.arg1]
	if zoneTable == nil then
		print("Updated instance loot info. All items from " .. self.arg1 .. " appear to have been sold/discarded/etc")
		return
	end

	print(" -- Gained in " .. self.arg1 .. "--")
	local NumOfItemsFound = 0
	for item, value in pairs(zoneTable) do
		if value ~= nil then
			 --print("  " .. item .. " found in zone")
			NumOfItemsFound = NumOfItemsFound + 1
		end
	end

	if NumOfItemsFound == 0 then
		zoneTable = nil
		return
	else
		print(NumOfItemsFound .. " item(s) dropped in " .. self.arg1)
	end
	DimBagSlotZone(eSaithBagFilterVar.properties.zone)
	if (not checked) then
		UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
	end
end

local function CreateZoneDropDownList()
	if eSaithBagFilterInstanceLoot == nil then
		return
	end

	local i = 1
	for v, k in pairs(eSaithBagFilterInstanceLoot) do
		if k ~= nil and type(k) ~= "number" then
			info = UIDropDownMenu_CreateInfo()
			info.text = tostring(v)
			info.arg1 = tostring(v)
			info.value = i
			info.func = ZoneMenuItemFunction
			UIDropDownMenu_AddButton(info)
			i = i + 1
		end
	end
end

local function GetPlayerInfo()
	local t = time()
	local NumPerRow = 4
	local count = 1
	local realmName = GetRealmName()
	local playerName = UnitName("player")
	local maxWidth = 0

	for zone, players in pairs(eSaithBagFilterInstances) do
		if zone ~= "players" then
			if count > 20 then break end
			local text = "|cffffff00" .. zone
			for k, player in ipairs(eSaithBagFilterInstances.players) do
				local name = player
				if player:find(realmName) then name = player:match("(.*) %- ") end

				if players[player] ~= nil and players[player].time > t then
					if name == playerName then
						text = text .. "\n|cffB0C4DE*** |cff20B2AA" .. name .. "|cffff2222 - In Progress/Complete|cffB0C4DE ***"
					else
						text = text .. "\n|cffff2222" .. name .. " - In Progress/Complete"
					end
				else
					if name == playerName then
						text = text .. "\n|cffB0C4DE*** |cff20B2AA" .. name .. "|cffB0C4DE ***"
					else
						text = text .. "\n|cffffffff" .. name
					end
				end
			end
			local fontstring = _G["eSaithBagFilterInstanceInfoFontString" .. count]
			if fontstring == nil then
				fontstring = eSaithBagFilter:CreateFontString("$parentInstanceInfoFontString" .. count, "ARTWORK", "GameFontNormal")
			end

			if count == 1 then
				fontstring:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 60, -60)
			elseif count > NumPerRow then
				fontstring:SetPoint("TOP", "$parentInstanceInfoFontString" ..(count - NumPerRow), "BOTTOM", 0, -40)
			else
				fontstring:SetPoint("LEFT", "$parentInstanceInfoFontString" ..(count - 1), "RIGHT", 60, 0)
			end

			fontstring:SetText(text)
			fontstring:Show()
			count = count + 1
			if maxWidth < fontstring:GetWidth() then
				maxWidth = fontstring:GetWidth()
			else
				fontstring:SetWidth(maxWidth)			
			end
		end
	end

	local fontstring = _G["eSaithBagFilterInstanceInfoFontString" .. count]
	if fontstring == nil then
		fontstring = eSaithBagFilter:CreateFontString("$parentInstanceInfoFontString" .. count, "ARTWORK", "GameFontNormal")
	end
	fontstring:SetPoint("BOTTOM", "$parent", "BOTTOM", 0, 30)
	fontstring:SetWidth(400)
	fontstring:SetText("\n|cffB0C4DE*** |cff20B2AA CHARACTER |cffB0C4DE *** is your current character\n|cffffffff CHARACTER|cffB0C4DE has a refreshed instance \n|cffff2222 CHARACTER - In Progress/Complete |cffB0C4DEis self explanatory")
	fontstring:Show()

	if count < NumPerRow then
		eSaithBagFilter:SetSize(maxWidth * NumPerRow * 1.05, 350)
	else
		eSaithBagFilter:SetSize(maxWidth * NumPerRow * 1.05, 85 *(count / NumPerRow) + 50 * #eSaithBagFilterInstances.players)
	end
end
local function GetRarity(ilvl)
	return eSaithBagFilterVar.properties.types[ilvl]
end  
local function ParseRaidInfo()
	local difficulty = {
		"5 Player Normal ",
		"5 Player Heroic ",
		"10 Player Normal ",
		"25 Player Normal ",
		"10 Player Heroic ",
		"25 Player Heroic ",
		"25 Player LFR ",
		"5 Player Challenge Mode ",
		"40 Player Classic "
	}

	local num = GetNumSavedInstances()
	local playerName = UnitName("player")
	local realmName = GetRealmName()
	local key = playerName .. " - " .. realmName

	if eSaithBagFilterInstances.players == nil then eSaithBagFilterInstances.players = { } end
	local found = false
	for j, k in pairs(eSaithBagFilterInstances.players) do
		if k == key then
			found = true
		end
	end

	local lvl = UnitLevel("player")
	if not found and lvl > 70 then table.insert(eSaithBagFilterInstances.players, key) end

	for i = 1, num do
		local instanceName, instanceID, instanceReset, instanceDifficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, maxBosses, defeatedBosses = GetSavedInstanceInfo(i)

		if eSaithBagFilterInstances == nil then eSaithBagFilterInstances = { } end
		if eSaithBagFilterInstances[instanceName] == nil and instanceDifficulty > 1 then
			eSaithBagFilterInstances[instanceName] = { }
		end

		local instance = eSaithBagFilterInstances[instanceName][key]
		if instance == nil then instance = { time = 0 } end
		if instanceReset > 0 then
			instance.time = time() + instanceReset
		end

		eSaithBagFilterInstances[instanceName][key] = instance
	end

	if eSaithBagFilter:IsShown() and eSaithBagFilterVar.properties.LeftTab == 4 then GetPlayerInfo() end
end

local function PrepareToShowSideTabs()
	eSaithBagFilterVar.properties.update = false
	if _G["MerchantFrame"]:IsShown() then
		_G["eSaithBagFilterSellButton"]:Show()
	else
		_G["eSaithBagFilterSellButton"]:Hide()
	end

	-- Hide Zone tab
	eSaithBagFilterDropDown:Hide()
	_G["eSaithBagFilterDoNotSellFontString"]:Hide()
	eSaithBagFilterCheckButton_TradeGoods:Hide()


	-- Hide Tab iLvl and Rarity tabs
	for index, _type in pairs(eSaithBagFilterVar.properties.types) do
		_G["eSaithBagFilterCheckButton" .. _type]:Hide()
	end

	eSaithBagFilterBottomTabs:Hide()
	eSaithBagFilterSliderMin:Hide()
	eSaithBagFilterSliderMax:Hide()


	-- Hide Info tab
	_G["eSaithBagFilterResetButton"]:Hide()

	eSaithBagFilter:SetSize(325, 350)
	local count = 1
	if eSaithBagFilterInstances ~= nil then
		for k, v in pairs(eSaithBagFilterInstances) do
			if _G["eSaithBagFilterInstanceInfoFontString" .. count] ~= nil then
				_G["eSaithBagFilterInstanceInfoFontString" .. count]:Hide()
				count = count + 1
			end
		end
	end

	if eSaithBagFilterVar ~= nil then
		eSaithBagFilter:ClearAllPoints()
		eSaithBagFilter:SetPoint(eSaithBagFilterVar.properties.point,
		eSaithBagFilterVar.properties.relativeTo,
		eSaithBagFilterVar.properties.relativePoint,
		eSaithBagFilterVar.properties.xOffset,
		eSaithBagFilterVar.properties.yOffset)
	end
end

local function SellListedItems()
	eSaithBagFilterVar.properties.update = true
	local count = 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture and eSaithBagFilterVar.properties.sell[link] ~= nil and eSaithBagFilterVar.properties.sell[link] == true and not locked then
				UseContainerItem(bag, slot)
				count = count + 1
			end
		end
	end
	return count
end
local function UpdateMinAndMax(self, value)
	if self == nil or value == nil or eSaithBagFilterVar == nil then return end
	local _type = eSaithBagFilterVar.properties.types[eSaithBagFilterVar.properties.BottomTab]

	if self:GetName():find("Min") ~= nil then
		eSaithBagFilterVar[_type].min = value
	elseif self:GetName():find("Max") ~= nil then
		eSaithBagFilterVar[_type].max = value
	end

	DimBagSlotiLVL()
end

function eSaithBagFilter_OnEvent(self, event, ...)
	if event == "ADDON_LOADED" and ... == "eSaithBagFilter" then
		self:UnregisterEvent("ADDON_LOADED")
		eSaithBagFilterVar = eSaithBagFilterVar or nil
		eSaithBagFilterInstances = eSaithBagFilterInstances or { }
		CreateRarityObjects()
		CreateCheckButtons()
		CreateSliders()
		eSaithBagFilter_ShowFilterZone()
		tinsert(UISpecialFrames, eSaithBagFilter:GetName())
	elseif event == "CHAT_MSG_LOOT" and ... ~= nil then
		if string.find(..., "You receive item: ") ~= nil or
			string.find(..., "You receive loot: ") ~= nil or
			string.find(..., "Received item: ") ~= nil then

			local bulk
			if string.find(..., "You receive item: ") ~= nil or string.find(..., "Received item: ") ~= nil then
				bulk = string.match(..., ".* item: (.+)%.")
			else
				bulk = string.match(..., ".* loot: (.+)%.")
			end

			local dItemID

			if string.find(bulk, "%]x(%d+)") ~= nil then
				dItemID = string.match(bulk, "(.*)x(%d+)")
			else
				dItemID = bulk
			end

			local name, dItemLink, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(dItemID)
			if vendorPrice ~= nil and vendorPrice > 0 then
				AddLoot(dItemLink)
			end
		end
	elseif event == "MERCHANT_SHOW" then
		eSaithBagFilter:Show()
		eSaithBagFilterSellButton:Show()
	elseif event == "MERCHANT_CLOSED" then
		eSaithBagFilterSellButton:Hide()
	elseif event == "UPDATE_INSTANCE_INFO" then
		ParseRaidInfo()
	elseif event == "PLAYER_ENTERING_WORLD" then
		for bag = 0, NUM_BAG_SLOTS do
			for slot = 1, GetContainerNumSlots(bag) do
				_G["ContainerFrame" ..(bag + 1) .. "Item" .. slot]:HookScript("OnClick", eSaithBagFilterContainerHook_OnClick)
				_G["ContainerFrame" ..(bag + 1) .. "Item" .. slot]:HookScript("OnLeave", eSaithBagFilterContainerHook_OnLeave)
				_G["ContainerFrame" ..(bag + 1) .. "Item" .. slot]:HookScript("OnUpdate", eSaithBagFilterContainerHook_OnUpdate)
			end
		end
	end
end
function eSaithBagFilter_OnHide()
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			_G["ContainerFrame" ..(bag + 1) .. "Item" .. slot]:SetAlpha(1)
			_G["ContainerFrame" ..(bag + 1) .. "Item" .. slot].BattlepayItemTexture:Hide()
		end
	end
end
function eSaithBagFilter_OnLoad(self, event, ...)
	self:RegisterForDrag("LeftButton")
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("CHAT_MSG_LOOT")
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("UPDATE_INSTANCE_INFO")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function eSaithBagFilter_OnShow()
	if eSaithBagFilterVar.properties.LeftTab == nil then
		eSaithBagFilterVar.properties.LeftTab = 1
	end

	if eSaithBagFilterVar.properties.LeftTab == 1 then
		DimBagSlotZone(eSaithBagFilterVar.properties.zone)
	elseif eSaithBagFilterVar.properties.LeftTab == 2 then
		DimBagSlotiLVL()
	elseif eSaithBagFilterVar.properties.LeftTab == 3 then
		DimBagSlotType()
	end

	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			eSaithBagFilterContainerHook_OnLeave(_G["ContainerFrame" ..(bag + 1) .. "Item" .. slot])
		end
	end
	eSaithBagFilterSideTabs_OnClick(_G["eSaithBagFilterSideTabsTab" .. eSaithBagFilterVar.properties.LeftTab])
end
function eSaithBagFilter_OnStopDrag(self, event, ...)
	self:StopMovingOrSizing()
	local point, relativeTo, relativePoint, xOffset, yOffset = eSaithBagFilter:GetPoint(1)

	eSaithBagFilterVar.properties.point = point
	eSaithBagFilterVar.properties.relativeTo = relativeTo
	eSaithBagFilterVar.properties.relativePoint = relativePoint
	eSaithBagFilterVar.properties.xOffset = xOffset
	eSaithBagFilterVar.properties.yOffset = yOffset
end

function eSaithBagFilterSellButton_Click(self, event, ...)
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then
				local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link)
				local personalItem = eSaithBagFilterVar.properties.keep[link]
				if (personalItem == nil or not personalItem) and not locked and not lootable and vendorPrice > 0 then
					if eSaithBagFilterVar.properties.sell == nil then eSaithBagFilterVar.properties.sell = { } end
					if eSaithBagFilterVar.properties.LeftTab == 1 and eSaithBagFilterInstanceLoot[eSaithBagFilterVar.properties.zone] ~= nil then
						local zoneTable = eSaithBagFilterInstanceLoot[eSaithBagFilterVar.properties.zone]
						if zoneTable[link] and(class ~= "Trade Goods" or not eSaithBagFilterCheckButton_TradeGoods:GetChecked()) then
							if eSaithBagFilterVar.properties.sell[link] == nil then eSaithBagFilterVar.properties.sell[link] = { } end
							eSaithBagFilterVar.properties.sell[link] = true
						end
					elseif eSaithBagFilterVar.properties.LeftTab == 2 then
						local _type = eSaithBagFilterVar.properties.types[quality + 1]
						if _G["eSaithBagFilterCheckButton" .. _type]:GetChecked()
							and PassMin(ilvl, eSaithBagFilterVar[_type].min, eSaithBagFilterVar[_type].minChecked)
							and PassMax(ilvl, eSaithBagFilterVar[_type].max, eSaithBagFilterVar[_type].maxChecked) then
							if eSaithBagFilterVar.properties.sell[link] == nil then eSaithBagFilterVar.properties.sell[link] = { } end
							eSaithBagFilterVar.properties.sell[link] = true
						end
					elseif eSaithBagFilterVar.properties.LeftTab == 3 then
						local _type = eSaithBagFilterVar.properties.types[quality + 1]
						if _G["eSaithBagFilterCheckButton" .. _type]:GetChecked() then
							if eSaithBagFilterVar.properties.sell[link] == nil then eSaithBagFilterVar.properties.sell[link] = { } end
							eSaithBagFilterVar.properties.sell[link] = true
						end
					end
				end
			end
		end
	end
	SellListedItems()
end
function eSaithBagFilterSellButton_OnUpdate(self, elapsed)
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed

	if eSaithBagFilterVar.properties.update and self.TimeSinceLastUpdate > eSaithBagFilterVar.properties.updateInterval + 1 then
		if SellListedItems() == 0 then
			eSaithBagFilterVar.properties.update = false
		end

		self.TimeSinceLastUpdate = 0
		eSaithBagFilterVar.properties.maxTime = eSaithBagFilterVar.properties.maxTime + 1

		if eSaithBagFilterVar.properties.maxTime > 12 or eSaithBagFilterVar.properties.update == false then
			eSaithBagFilterVar.properties.maxTime = 0
			eSaithBagFilterVar.properties.update = false
			eSaithBagFilterVar.properties.sell = { }
			UpdateZoneTable(eSaithBagFilterVar.properties.zone)
		end
	end
end

function eSaithBagFilterBottomTabs_OnLoad(self, event, ...)
	PanelTemplates_SetNumTabs(self, 5)
	PanelTemplates_SetTab(eSaithBagFilterBottomTabs, 1)
end
function eSaithBagFilterBottomTabs_OnShow(self, event, ...)
	PanelTemplates_SetTab(eSaithBagFilterBottomTabs, eSaithBagFilterVar.properties.BottomTab)
end

function eSaithBagFilterSideTabs_OnClick(self, button)
	PlaySound("igAbiliityPageTurn")
	local tab = self:GetName():match("eSaithBagFilterSideTabs(.*)")

	for i = 1, 4 do
		_G["eSaithBagFilterSideTabsTab" .. i]:SetAlpha(.5)
	end
	_G["eSaithBagFilterSideTabs" .. tab]:SetAlpha(1)
end

function eSaithBagFilterResetButton_Click(self, event)
	local keep = eSaithBagFilterVar.properties.keep
	eSaithBagFilterVar = nil
	eSaithBagFilterInstanceLoot = nil
	eSaithBagFilterInstances = nil
	CreateRarityObjects()
	eSaithBagFilterVar.properties.keep = keep
	ReloadUI()
end

function eSaithBagFilterSlider_CheckBoxClick(self, button, down)
	eSaithBagFilterVar.properties.update = false
	local btn = self:GetParent():GetName() .. "CheckButton"
	local _type = eSaithBagFilterVar.properties.types[eSaithBagFilterVar.properties.BottomTab]

	if string.find(self:GetName(), "Min") ~= nil then
		eSaithBagFilterVar[_type].minChecked = self:GetChecked()
	elseif string.find(self:GetName(), "Max") ~= nil then
		eSaithBagFilterVar[_type].maxChecked = self:GetChecked()
	end
	DimBagSlotiLVL()
end
function eSaithBagFilterSlider_DownButton(self, event, ...)
	local parent = self:GetParent()
	local value = _G[parent:GetName() .. "Slider"]:GetValue() - _G[parent:GetName() .. "Slider"]:GetValueStep()
	_G[parent:GetName() .. "Slider"]:SetValue(math.floor(value))
	UpdateMinAndMax(self, math.floor(value))
end
function eSaithBagFilterSlider_OnLoad(self, event, ...)
	local minSize, maxSize = self:GetMinMaxValues()
	_G[self:GetName() .. 'Low']:SetText(minSize)
	_G[self:GetName() .. 'High']:SetText(maxSize)
end
function eSaithBagFilterSlider_SliderValueChanged(self, value)
	eSaithBagFilterVar.properties.update = false
	local parent = self:GetParent()
	_G[parent:GetName() .. "SliderValue"]:SetText(math.floor(value))
	UpdateMinAndMax(self, math.floor(value))
end
function eSaithBagFilterSlider_UpButton(self, event, ...)
	local parent = self:GetParent()
	local value = _G[parent:GetName() .. "Slider"]:GetValue() + _G[parent:GetName() .. "Slider"]:GetValueStep()
	_G[parent:GetName() .. "Slider"]:SetValue(math.floor(value))
	UpdateMinAndMax(self, math.floor(value))
end

function eSaithBagFilterCheckBox_Click(self, button, down)
	local _type = string.match(self:GetName(), "eSaithBagFilterCheckButton(.*)")
	if eSaithBagFilterVar[_type] ~= nil then
		eSaithBagFilterVar[_type].checked = self:GetChecked()
	end
	DimBagSlotType()
end
function eSaithBagFilterBottomTab_Click(self, event, ...)
	local parent = self:GetParent():GetName() .. "Tab"
	local col = eSaithBagFilterVar.properties.types[eSaithBagFilterVar.properties.BottomTab]
	_G["eSaithBagFilterCheckButton" .. col]:Hide()

	for index, _type in pairs(eSaithBagFilterVar.properties.types) do
		if (parent .. index == self:GetName()) then
			eSaithBagFilterVar.properties.BottomTab = index
			eSaithBagFilterSliderMinSlider:SetValue(eSaithBagFilterVar[_type].min)
			eSaithBagFilterSliderMaxSlider:SetValue(eSaithBagFilterVar[_type].max)
			eSaithBagFilterSliderMinCheckButton:SetChecked(eSaithBagFilterVar[_type].minChecked)
			eSaithBagFilterSliderMaxCheckButton:SetChecked(eSaithBagFilterVar[_type].maxChecked)
			_G["eSaithBagFilterCheckButton" .. _type]:Show()
			return
		end
	end
end

function eSaithBagFilter_ShowCharacterInfo(self, event)
	if eSaithBagFilterVar.properties.LeftTab ~= 4 then
		RequestRaidInfo()
		PrepareToShowSideTabs()
		_G["eSaithBagFilterSellButton"]:Hide()

		if eSaithBagFilterVar.properties.point ~= nil then
			eSaithBagFilter:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)
		end
	end

	eSaithBagFilterVar.properties.LeftTab = 4
	_G["eSaithBagFilterResetButton"]:Show()

end
function eSaithBagFilter_ShowFilteriLVL(self, event)
	PrepareToShowSideTabs()

	-- Verify checkboxes are aligned correctly - mostly if coming from zone tab
	local point, relativeTo, relativePoint, xOffset, yOffset = eSaithBagFilterCheckButtonPoor:GetPoint("TOPLEFT")
	for index, _type in pairs(eSaithBagFilterVar.properties.types) do
		_G["eSaithBagFilterCheckButton" .. _type]:ClearAllPoints()
		_G["eSaithBagFilterCheckButton" .. _type]:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
	end


	eSaithBagFilterVar.properties.LeftTab = 2
	if eSaithBagFilterVar.properties.BottomTab == nil then eSaithBagFilterVar.properties.BottomTab = 1 end

	local _type = eSaithBagFilterVar.properties.types[eSaithBagFilterVar.properties.BottomTab]
	_G["eSaithBagFilterBottomTabs"]:Show()
	_G["eSaithBagFilterCheckButton" .. _type]:SetChecked(eSaithBagFilterVar[_type].checked)
	_G["eSaithBagFilterCheckButton" .. _type]:Show()
	eSaithBagFilterSliderMinSlider:SetValue(eSaithBagFilterVar[_type].min)
	eSaithBagFilterSliderMin:Show()
	eSaithBagFilterSliderMaxSlider:SetValue(eSaithBagFilterVar[_type].max)
	eSaithBagFilterSliderMax:Show()
	DimBagSlotiLVL()
end
function eSaithBagFilter_ShowFilterRarity(self, event)
	PrepareToShowSideTabs()
	eSaithBagFilterVar.properties.LeftTab = 3

	local point, relativeTo, relativePoint, xOffset, yOffset = eSaithBagFilterCheckButtonPoor:GetPoint("TOPLEFT")
	local offset = yOffset
	local count = 0
	for index, _type in pairs(eSaithBagFilterVar.properties.types) do
		if eSaithBagFilterVar[_type] ~= nil then
			_G["eSaithBagFilterCheckButton" .. _type]:SetPoint(point, relativeTo, relativePoint, xOffset, offset)
			_G["eSaithBagFilterCheckButton" .. _type]:SetChecked(eSaithBagFilterVar[_type].checked)
			_G["eSaithBagFilterCheckButton" .. _type]:Show()
			offset = offset - 30
		end
		count = count + 1
		if count >= 5 then break end
	end
	DimBagSlotType()
end
function eSaithBagFilter_ShowFilterZone(self, event)
	PrepareToShowSideTabs()

	eSaithBagFilterVar.properties.LeftTab = 1
	DimBagSlotZone(eSaithBagFilterVar.properties.zone)
	eSaithBagFilterDropDown:Show()
	eSaithBagFilterCheckButton_TradeGoods:Show()
	_G["eSaithBagFilterDoNotSellFontString"]:Show()

end

function eSaithBagFilter_CreateDropDownList()
	if eSaithBagFilterVar == nil then return end

	if eSaithBagFilterVar.properties.LeftTab == 1 then
		CreateZoneDropDownList()
	end
end

function SlashCmdList.eSaithBagFilter(msg, editbox)
	if eSaithBagFilter:IsShown() then
		eSaithBagFilter:Hide()
	else
		eSaithBagFilter:Show()
	end

	local command, rest = msg:match("^(%S*)%s*(.-)$")
	if command == "center" then
		eSaithBagFilter:ClearAllPoints()
		eSaithBagFilter:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		eSaithBagFilter:Show()
	end
end

function eSaithBagFilterContainerHook_OnClick(self, button)
	if self.count <= 0 or
		not IsAltKeyDown() or
		not eSaithBagFilter:IsShown() then
		return
	end
	local bag = self:GetParent():GetID()
	local slot = self:GetID()
	local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)

	if eSaithBagFilterVar.properties.keep[link] == nil then
		eSaithBagFilterVar.properties.keep[link] = true
		self.BattlepayItemTexture:Show()
	else
		if eSaithBagFilterVar.properties.keep[link] then
			eSaithBagFilterVar.properties.keep[link] = false
			self.BattlepayItemTexture:Hide()
		else
			eSaithBagFilterVar.properties.keep[link] = true
			self.BattlepayItemTexture:Show()
		end
	end
end
function eSaithBagFilterContainerHook_OnLeave(self, motion)
	local bag = self:GetParent():GetID()
	local slot = self:GetID()
	local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
	local newItemAnim = self.newitemglowAnim

	if eSaithBagFilterVar.properties.keep == nil then eSaithBagFilterVar.properties.keep = { } end
	if eSaithBagFilterVar.properties.keep[link] == nil then return end
	if eSaithBagFilterVar.properties.keep[link] and eSaithBagFilter:IsShown() then
		self.BattlepayItemTexture:Show()
	else
		self.BattlepayItemTexture:Hide()
	end
end
function eSaithBagFilterContainerHook_OnUpdate(self, elapsed)
	eSaithBagFilterVar.properties.itemUpdateCount = eSaithBagFilterVar.properties.itemUpdateCount + elapsed

	if eSaithBagFilterVar.properties.itemUpdateCount > eSaithBagFilterVar.properties.updateInterval then
		eSaithBagFilterContainerHook_OnLeave(self, nil)
		eSaithBagFilterVar.properties.updateCount = 0
	end
end

--[[ Notes:
-- reset/cancel button for ilvl
-- Add gold looted, add gold from selling
-- Long term stats of each raid

-- List potential mounts that drop in instance/zone/raid
-- Have a huge table of reagents to sort to filter through
-- Consider disenchanting if selected
-- Consider attempting to loot if lootable when originally looting - only white items.
--]]

--[[ Changes
-- Refactored code to make functions more mininal in code in hopes to reduce complexity in logic and improve correctness.
-- Added a "sell" list. Once sell button is clicked items that are to be sold are added to the list. This helps to prevent items
	 that may potentially sell once added to bags during the "sell period". The problem occurs mostly when selling an item by rarity. If
	 an item is the same color rarity as being sold then the new item may accidentally sell along with the mass sell. This
	 new "sell list" should reduce that chance. It is assumed that the player will not attempt to add an item into their
	 bags with an item in their "sell list" in the first place. This assumption cannot always be guaranteed due to accidental click of the
	 sell button or not placing the item in the "keep" list prior to mass selling.
-- "Sell Button" now hides in the Player Info tab even if Merchant Frame is viewable. Button becomes viewable once clicking back to
	other sell tabs
-- When player "Resets" addon when upgrading their original "keep list" is saved by default
-- Added simplified left side tab "highlight", or rather alpha dimmed/muted tab selection. This confirms with the user of the selected tab
-- Fixed Player Info screen to fix better with different size UI scaling
-- Attempted to fix bug where occassionally when showing addon /clean shows both first and fourth tab contents when the first tab is the selected tab.
-- Renamed titles from the "Color" to Types for a more "professional" look
--]]