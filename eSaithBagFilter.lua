SLASH_ESAITHBAGFILTER1 = '/efilter'
local MaxItemCount = -1
local zone -- used for updating world coordinates

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
local function ResetAlphaOnAllButtons()
	for index = 1, MaxItemCount do
		local btn = _G["eSaithBagFilterSellItem"..index]
		if _G["eSaithBagFilterSellItem"..index] and _G["eSaithBagFilterSellItem"..index]:IsShown() then
			if eSaithBagFilterVar.properties.keep[_G["eSaithBagFilterSellItem"..index].link] then
				_G["eSaithBagFilterSellItem"..index]:SetAlpha(.3)
			else
				_G["eSaithBagFilterSellItem"..index]:SetAlpha(1)
			end
		end
	end
end
local function AddLoot(obj)
	local zone = GetRealZoneText()
	if eSaithBagFilterInstanceLoot[zone] == nil then eSaithBagFilterInstanceLoot[zone] = { } end
	eSaithBagFilterInstanceLoot[zone][obj] = true
end

local function ItemButton_Press(self, event, button)
	local alpha = self:GetAlpha()
	if alpha ~= 1 then 
		self:SetAlpha(1)
		eSaithBagFilterVar.properties.keep[self.link] = false
	else
		self:SetAlpha(.2)
		eSaithBagFilterVar.properties.keep[self.link] = true
	end
	ResetAlphaOnAllButtons()
end
local function ItemButton_OnEnter(self, event, ...)
	local x = self:GetRight();
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	if ( x >= ( GetScreenWidth() / 2 ) ) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	end

	GameTooltip:SetHyperlink(self.link)
	GameTooltip:Show()	
end

local function ItemButton_OnLeave(self, event, ...)
	GameTooltip:Hide()	
end

local function UpdateCoordinates(self, elapsed)
	if zone ~= GetRealZoneText() then
		zone = GetRealZoneText()
		SetMapToCurrentZone()
	end

	if self.TimeSinceLastUpdate == nil then self.TimeSinceLastUpdate = 0 end
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
	if self.TimeSinceLastUpdate > .5 then	
		self.TimeSinceLastUpdate = 0
		local posX, posY = GetPlayerMapPosition("player");
		local fontstring = _G["eSaithBagFilterCoordinatesFontString"]
		local x = math.floor(posX * 10000)/100
		local y = math.floor(posY*10000)/100
		fontstring:SetText("|cff98FB98("..x..", "..y..")")
		fontstring:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
		fontstring:Show()
	end
end

local function CreateCheckButtons()
	local width = eSaithBagFilter:GetWidth()
	for index, _type in ipairs(eSaithBagFilterVar.properties.types) do
		local btn = CreateFrame("CheckButton", "$parentCheckButton" .. _type, eSaithBagFilter, "UICheckButtonTemplate")
		btn:SetPoint("TOP", "$parent", "TOP", -math.floor(width / 5), -30)
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
	btn:SetPoint("TOP", "$parent", "TOP", -50, -90)
	local fontstring = btn:CreateFontString("eSaithBagFilterCheckButtonTradeGoodsFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText("Trade Goods")
	fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
	btn:SetFontString(fontstring)
	btn:Show()

	for i = 1, 200 do
		local btn = CreateFrame("Button", "eSaithBagFilterSellItem"..i, eSaithBagFilter, "eSaithBagFilterItemButtonTemplate")
		btn:SetPoint("CENTER", "$parent", "CENTER", i, i)
		btn.texture = btn:CreateTexture("$parentTexture", "OVERLAY");
		btn.texture:SetTexture("Interface\ICONS\INV_Misc_QuestionMark");
		btn.texture:SetSize(40,40)	
		btn.texture:SetAllPoints();
		btn.texture = btn:CreateTexture("$parentTextureBorder", "BORDER");
		btn.texture:SetTexture(1,1,1,1)
		btn.texture:SetSize(10, 10)
		btn.texture:SetAllPoints()
		btn:SetScript("OnClick", ItemButton_Press)
		btn:SetScript("OnEnter", ItemButton_OnEnter)
		btn:SetScript("OnLeave", ItemButton_OnLeave)
		btn:Hide();
	end
	local fontstring = eSaithBagFilter:CreateFontString("$parentInstanceInfoFontString", "ARTWORK", "GameFontNormal")
	
	local coords = CreateFrame("Frame", "eSaithBagFilterCoordinates", UIParent)
	coords:SetSize(100, 50)
	coords:SetPoint("TOP", "Minimap", "BOTTOM", 5, 0)
	coords:SetScript("OnUpdate", UpdateCoordinates)
	local coordsFont = coords:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	coordsFont:SetText("|cffffffffLocation:")
	coordsFont:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
	coordsFont:Show()
	coords:Show()

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
				updateInterval = 0.5,
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

local function PassMin(ilvl, minlvl, required)
	return not required or ilvl >= minlvl
end
local function PassMax(ilvl, maxlvl, required)
	return not required or ilvl <= maxlvl
end




local function ShowListedItems(count)
	for i = 1, MaxItemCount do
		_G["eSaithBagFilterSellItem"..i]:Hide()
	end

	if eSaithBagFilterVar.properties.sell == nil then return end	 
	local MAX_ROW = 8
	local yoffset = 0
	local xoffset = 0
	local height = math.ceil(count / MAX_ROW) * 45
	local list = eSaithBagFilterVar.properties.sell
	for index = 1, count do 
		if index % MAX_ROW == 1 then 
			yoffset = yoffset + 1
			xoffset = 0
		end

		local btn = _G["eSaithBagFilterSellItem"..index]
		btn:Show()
		btn:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 46 * xoffset + 20, -150 - yoffset * 50)	
		btn.texture = _G[btn:GetName().."Texture"]
		btn.texture:Show()
		btn.texture:SetTexture(list[index].text)
		btn.texture = _G[btn:GetName().."TextureBorder"]
		btn.texture:Show()
		btn.texture:SetTexture(eSaithBagFilterVar.properties.texture[3 * list[index].colorIndex], eSaithBagFilterVar.properties.texture[3 * list[index].colorIndex + 1], eSaithBagFilterVar.properties.texture[3 * list[index].colorIndex + 2], 1)

		btn.link = list[index].link
		xoffset = xoffset + 1		
	end

	if MaxItemCount > count then
		for i = count + 1, MaxItemCount do
			_G["eSaithBagFilterSellItem"..i]:Hide()
		end
	end
	MaxItemCount = count	

	local x = eSaithBagFilter:GetSize()
	eSaithBagFilter:SetSize(x, 280 + height)	
end

local function DimBagSlotZone(zone)
	if zone == nil or eSaithBagFilterInstanceLoot[zone] == nil then return end
	local zoneTable = eSaithBagFilterInstanceLoot[zone]

	eSaithBagFilterVar.properties.sell = { }
	
	local count = 0
	for bag = 0, NUM_BAG_SLOTS do		
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then	
				local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link)
				if zoneTable[link] then
					count = count + 1
					eSaithBagFilterVar.properties.sell[count] = { link = link, text = texture, colorIndex = quality + 1 }					
				end
			end
		end
	end
	ShowListedItems(count)
	ResetAlphaOnAllButtons()
end
local function DimBagSlotiLVL()
	eSaithBagFilterVar.properties.sell = { }
	
	local count = 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then		
				local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link)
				if vendorPrice > 0 and not locked and not lootable then
					-- Skip all items that cannot be sold to vendors					
					local _type = eSaithBagFilterVar.properties.types[quality + 1]
					if _G["eSaithBagFilterCheckButton" .. _type]:GetChecked()
						and PassMin(ilvl, eSaithBagFilterVar[_type].min, eSaithBagFilterVar[_type].minChecked)
						and PassMax(ilvl, eSaithBagFilterVar[_type].max, eSaithBagFilterVar[_type].maxChecked) then
						count = count + 1
						eSaithBagFilterVar.properties.sell[count] = { link = link, text = texture, colorIndex = quality + 1 }	
					end
				end
			end
		end
	end
	ShowListedItems(count)
	ResetAlphaOnAllButtons()
end

local function DimBagSlotType()
	eSaithBagFilterVar.properties.sell = { }
	
	local count = 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag)  do					
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)			
			if texture then											
				local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link)
				local _type = eSaithBagFilterVar.properties.types[quality + 1]
				if _G["eSaithBagFilterCheckButton" .. _type]:GetChecked() and vendorPrice > 0 and not lootable then			
					count = count + 1
					eSaithBagFilterVar.properties.sell[count] = { link = link, text = texture, colorIndex = quality + 1 }	
				end
			end
		end
	end	
	ShowListedItems(count)
	ResetAlphaOnAllButtons()
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

	
	local NumOfItemsFound = 0
	for item, value in pairs(zoneTable) do
		if value ~= nil then
			NumOfItemsFound = NumOfItemsFound + 1
		end
	end

	if NumOfItemsFound == 0 then
		zoneTable = nil
		return
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
		eSaithBagFilter:SetSize(maxWidth * NumPerRow * 1.10, 350)
	else
		eSaithBagFilter:SetSize(maxWidth * NumPerRow * 1.10, 85 *(count / NumPerRow) + 50 * #eSaithBagFilterInstances.players)
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

	--if eSaithBagFilter:IsShown() and eSaithBagFilterVar.properties.LeftTab == 4 then GetPlayerInfo() end
end

local function PrepareToShowSideTabs()
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

	for i = 1, 200 do
		local btn =_G["eSaithBagFilterSellItem"..i]
		btn:Hide();
	end

	-- Hide Info tab
	_G["eSaithBagFilterResetButton"]:Hide()

	eSaithBagFilter:SetSize(400, 200)
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

	local fontstring = _G["eSaithBagFilterInstanceInfoFontString"]
	if fontstring:IsShown() then fontstring:Hide() end
end

local function SellListedItems()
	eSaithBagFilterVar.properties.update = true
	local count = 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture and eSaithBagFilterVar.properties.sell[link] then
				if not locked then UseContainerItem(bag, slot) end
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
		eSaithBagFilter:Hide()
	elseif event == "UPDATE_INSTANCE_INFO" then
		ParseRaidInfo()		
 	end
end

function eSaithBagFilter_OnHide()

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

	if eSaithBagFilterVar.properties.update and self.TimeSinceLastUpdate > eSaithBagFilterVar.properties.updateInterval then	
		self.TimeSinceLastUpdate = 0
		eSaithBagFilterVar.properties.maxTime = eSaithBagFilterVar.properties.maxTime + 1
				
		if  SellListedItems() == 0 then
			eSaithBagFilterVar.properties.update = false
		end

		if eSaithBagFilterVar.properties.maxTime > 60 or eSaithBagFilterVar.properties.update == false then
			eSaithBagFilterVar.properties.maxTime = 0
			eSaithBagFilterVar.properties.update = false
			eSaithBagFilterVar.properties.sell = { }
			UpdateZoneTable(eSaithBagFilterVar.properties.zone)

			if eSaithBagFilterVar.properties.LeftTab == 1 then
				DimBagSlotZone(eSaithBagFilterVar.properties.zone)
			elseif eSaithBagFilterVar.properties.LeftTab == 2 then
				DimBagSlotiLVL()
			elseif eSaithBagFilterVar.properties.LeftTab == 3 then
				DimBagSlotType()
			end
		end 
	end
end
function eSaithBagFilterSellButton_OnEnter(self, event, ...)
	local x;
	x = self:GetRight();
	if ( x >= ( GetScreenWidth() / 2 ) ) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end

	GameTooltip:AddLine("Sell")
	GameTooltip:Show()
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
	eSaithBagFilterDropDown:Show()
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

local function PlayerInfoItemFunction(self, arg1, arg2, checked)
	eSaithBagFilter:SetSize(325, 400)
    local t = time()
	local realmName = GetRealmName()
	local CurrentPlayersName = UnitName("player")
	local text = ""
    local playersInSelectedInstance = eSaithBagFilterInstances[self.arg1]
		
	for index, player in ipairs(eSaithBagFilterInstances.players) do
		local charName = player
		if player:find(realmName) then charName = player:match("(.*)%s%-") end

		if playersInSelectedInstance[player] ~= nil and playersInSelectedInstance[player].time > t then
			if charName == CurrentPlayersName then
				text = text .. "\n|cffB0C4DE*** |cff20B2AA" .. charName .. "|cffff2222 - In Progress/Complete|cffB0C4DE ***"
			else
				text = text .. "\n|cffff2222" .. charName .. " - In Progress/Complete"
			end
		else
			if charName == CurrentPlayersName then
				text = text .. "\n|cffB0C4DE*** |cff20B2AA" .. charName .. "|cffB0C4DE ***"
			else
				text = text .. "\n|cffffffff" .. charName
			end
		end
	end

	local fontstring = _G["eSaithBagFilterInstanceInfoFontString"]	 
	fontstring:SetPoint("TOP", "$parent", "TOP", 0, -60)  
	fontstring:SetText(text)
	fontstring:SetWidth(250)
	fontstring:Show()
	if (not checked) then
		UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
	end
end

function CreatePlayerInfoDropDownList()
    local i = 1;          
    for v, k in pairs (eSaithBagFilterInstances) do
    	if k ~= nil then
    		info = UIDropDownMenu_CreateInfo();
    		info.text = tostring(v)
    		info.arg1 = tostring(v)
    		info.value = i; 
    		info.func = PlayerInfoItemFunction; 
    		UIDropDownMenu_AddButton(info);
    		i = i + 1;
    	end
    end 
end

function eSaithBagFilter_CreateDropDownList()
	if eSaithBagFilterVar == nil then return end

	if eSaithBagFilterVar.properties.LeftTab == 1 then
		CreateZoneDropDownList()
	elseif eSaithBagFilterVar.properties.LeftTab == 4 then
        CreatePlayerInfoDropDownList()		
	end
end





function SlashCmdList.ESAITHBAGFILTER(msg, editbox)
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

--[[ Notes:
-- reset/cancel button for ilvl
-- Add gold looted, add gold from selling
-- Long term stats of each raid

-- List potential mounts that drop in instance/zone/raid
-- Have a huge table of reagents to sort to filter through
-- Consider disenchanting if selected
-- Consider attempting to loot if lootable when originally looting - only white items.
--]]
