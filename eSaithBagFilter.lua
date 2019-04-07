SLASH_ESAITHBAGFILTER1 = '/efilter'

if not LibStub then
	print("Saith Bag Filter requires LibStub.")
	return
end

local MAX_ITEM_COUNT = -1
local ORIGINALTOOLTIP  -- used to save original functionality to the tooltip. Used for hooking a function
local MAX_BAG_SLOTS = 175    
local eVar -- Short for eSaithBagFilter
local savedInstances -- short for eSaithBagFilterInstances. For saving instances on all characters on all realms
local instanceLoot = nil -- short for eSaithBagFilterInstanceLoot. Loot from each zone, dungeon, raid, etc.
	-- eVar.instance[instanceName][item]
local StartLootRollID = nil
local items = {} -- list of all items that player has ever dealt with regardless of quality|rarity
local tab = 1
local isSelling = isSelling or false
local SavedInstancesTable
local InstanceTable
 
local itemTextureColors = {  
	.6, .6, .6, --Gray
	1, 1, 1, 	--White
	0, 1, 0, 	--Green
	.2, .2, 1, 	--Blue
	1, 0, 1, 	--Purple
	.8, .8, 0, 	--Orange
	.83, .68, 0, --Gold
	.37,.62,.63, --Lightblue
	0, 1, 1		--Cyan
}

local selectedZone = nil
local sellList

local ItemQualityString = {
	"Poor",
	"Common", 
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Artifact",
	"Heirloom"
}
local itemQuality = {
	Poor = 0,
	Common = 1, 
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Artifact = 6,
	Heirloom = 7
}

local function convertIntToString_ItemQuality(_quality)
	for rarity, quality in pairs(itemQuality) do
		if quality == _quality then
			return rarity
		end
	end
end
local function convertStrToInt_ItemQuality(_quality)
	for index, quality in ipairs(ItemQualityString) do
		if quality == _quality then
			return index - 1
		end
	end 
end

local function printTable(tb, spacing)
	if spacing == nil then spacing = "" end
	if tb == nil then print("Table is nil") return end
	if type(tb) ~= "table" then
		print(type(tb), tb) 
		return
	end

	print(spacing .. "Entering table")
	for k, v in pairs(tb) do
		print(spacing .. "K: " .. k .. ", v: " .. tostring(v))
		if type(v) == "table" then
			printTable(v, "   " .. spacing)
		end
	end
	print(spacing.."Leaving table")
end
local function PrepreToolTip(self)
	local x = self:GetRight();
	if (x >=(GetScreenWidth() / 2)) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end
end
local function AddItemToItemList(link, isBOE)	
	if not link or type(link) ~= 'string' then 
		return 
	end
	
	if items[link] == nil then
		local name, _, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link) 
		items[link] = {
			name = name,
			quality = quality,
			rarity = convertIntToString_ItemQuality(quality),
			iLevel, iLevel,
			reqLevel = reqLevel,
			class = class,
			subclass = subclass,
			maxStack = maxStack,
			equipSlot = equipSlot, 
			texture = texture, 
			vendorPrice = vendorPrice or 0,
			isBOE = isBOE,
			link = link
		}

		if isBOE == nil then
			-- item has not been seen before. Show the tooltip to get isBOE value prior to adding to items list
			GameTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
			GameTooltip:SetHyperlink(link)    
			GameTooltip:Show()   
			GameTooltip:Hide() 	
			return
		end
	end	
end
local function ReadToolTip(self, ...)
	local boundText =  tostring(GameTooltipTextLeft2:GetText()) .. 
						tostring(GameTooltipTextLeft3:GetText()) .. 
						tostring(GameTooltipTextLeft4:GetText()) .. 
						tostring(GameTooltipTextLeft5:GetText())	

	local link = select(2, GameTooltip:GetItem())
    
	-- Link items can only be items. If scrolling over professions button in professions tab or similar action then link is nil    
	if link and type(link) == 'string' then            
		local isBOE = false
		if boundText:find(".* when equip.*") or boundText:find(".*on equip*") or boundText:find(".* account.*") or 
		not (boundText:find(".* picked.*") or boundText:find(".* pick up.*") or boundText:find(".*Soulbound.*")) then
			isBOE = true
		end
		
		if items[link] then
			items[link].isBOE = isBOE
		else
			AddItemToItemList(link, isBOE)
		end
	end
	return ORIGINALTOOLTIP(self, ...)
end
local function SetAlphaOnItems()
	local itemBtn
	for index = 1, MAX_BAG_SLOTS do
		itemBtn = _G["eSaithBagFilter_LootFrame_Item" .. index]
		if itemBtn and itemBtn:IsShown() then
			if eVar.items.kept[itemBtn.link] == true
			or itemBtn.class == 'Trade Goods' and  eVar.options.keepTradeGoods == true
			or itemBtn.class == 'Tradeskill' and  eVar.options.keepTradeGoods == true
			or itemBtn.qualtiy == itemQuality.Uncommon and  eVar.options.keepUncommonBOEItems == true
			or itemBtn.qualtiy == itemQuality.Rare and  eVar.options.keepRareBOEItems == true			
			then
				itemBtn:SetAlpha(.4)
			else
				itemBtn:SetAlpha(1)
			end
		end
	end
end
local function AddLoot(link)
	AddItemToItemList(link)	
	if link then 
		local zone = GetRealZoneText()
		if zone ~= nil then 
			instanceLoot[zone] = instanceLoot[zone] or {}
			instanceLoot[zone][link] = true
		end 
		
		instanceLoot['All'][link] = true
	end
end	
local function Item_OnPress(self)  
	eVar.items.kept[self.link] = not eVar.items.kept[self.link]
	SetAlphaOnItems()
end
local function Item_OnEnter(self, motion)
	PrepreToolTip(self)
	GameTooltip:SetHyperlink(self.link) 
	GameTooltip:Show()
end
local function Option_OnEnter(self, motion)
    PrepreToolTip(self)
	GameTooltip:AddLine(tostring(self.HoverText))
	GameTooltip:Show()
end
function eSaithBagFilter_SellButton_OnEnter(self, event, ...)
	PrepreToolTip(self)
	GameTooltip:AddLine("Sell items")
	GameTooltip:Show()
end
function eSaithBagFilter_OnGameToolTipLeave(self, motion)
	GameTooltip:Hide()
end
function eSaithBagFilter_OnClick(self, event, ...)
	if eSaithBagFilter:IsShown() then
		eSaithBagFilter:Hide()
	else
		eSaithBagFilter:Show()
		if tab == 1 then
			eSaithBagFilter_SellButton:Show()
		end
	end
end
function eSaithBagFilter_OnEnter(self, motion)
	PrepreToolTip(self)
	GameTooltip:AddLine("Open ESaith Item Filter")
	GameTooltip:Show()
end
local function UpdateCoordinates(self, elapsed)	
	self.TimeSinceLastUpdate =  (self.TimeSinceLastUpdate or 0) + elapsed

	if self.TimeSinceLastUpdate > .75 then
		self.TimeSinceLastUpdate = 0
		local playerLocal = C_Map.GetBestMapForUnit("player")
		if playerLocal ~= nil then 
			local playerPos = C_Map.GetPlayerMapPosition(playerLocal, "player")
			if playerPos ~= nil then 
				local posX, posY =  playerPos:GetXY();
				local fontstring = eSaithBagFilter_Coordinates_FontString
				if posX and posY then 
					local x = math.floor(posX * 10000) / 100
					local y = math.floor(posY * 10000) / 100		
					fontstring:SetText("|cff98FB98(" .. x .. ", " .. y .. ")") --todo, allow player to change color or at min change location on minimap			
				else
					fontstring:SetText("|cff98FB98(Not Available)")
				end

				fontstring:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
				fontstring:Show()
			end
		end
	end
end
local function ToggleCoordinates(self, event, button)
	if self:GetChecked() then
		eVar.options.coordinatesEnabled = true
		eSaithBagFilter_Coordinates:Show()
	else
		eVar.options.enableCoordinates = false
		eSaithBagFilter_Coordinates:Hide()
	end
end
local function ToggleOption(self)
	eVar.options[self.OptionName] = self:GetChecked();
end
local function StageAndShowItem(link, index, linkTo, nextLine)
	if link == nil then return end
	
	local itemBtn = _G["eSaithBagFilter_LootFrame_Item" .. index]
	itemBtn:ClearAllPoints()

	if index == 1 then 
		itemBtn:SetPoint("TOPLEFT", eSaithBagFilter_LootFrame, "TOPLEFT", 20, -20)
	else
		local linkToBtn = _G["eSaithBagFilter_LootFrame_Item" .. linkTo]
		if nextLine then
			itemBtn:SetPoint("TOPLEFT", linkToBtn, "BOTTOMLEFT", 0, -5)
		else
			itemBtn:SetPoint("LEFT", linkToBtn, "RIGHT", 5, 0)
		end
	end 
	
	itemBtn.texture = _G[itemBtn:GetName() .. "_Texture"] 
	itemBtn.texture:Show()
	itemBtn.texture:SetTexture(items[link].texture)
	itemBtn.texture = _G[itemBtn:GetName() .. "_TextureBorder"]
	itemBtn.texture:Show()
	itemBtn.texture:SetColorTexture(itemTextureColors[3 * items[link].quality + 1], itemTextureColors[3 * items[link].quality + 2], itemTextureColors[3 * items[link].quality + 3])
	itemBtn:Show()
	itemBtn.link = link
end
local function GetItemsPerRow()
	local btnWidth = _G["eSaithBagFilter_LootFrame_Item1"]:GetWidth() + 5
	local result = math.floor( (eSaithBagFilter_LootFrame:GetWidth() - 20) / btnWidth)
	return result
end
local function HideItems()
	for i = 1, MAX_BAG_SLOTS do
		if _G["eSaithBagFilter_LootFrame_Item" .. i]:IsShown() then
			_G["eSaithBagFilter_LootFrame_Item" .. i]:Hide()
		end
	end
end
local function FilterItemsByRarity(list, quality)
	local i = {};
	if list then 
		for link, val in pairs(list) do
			if (items[link].rarity == convertIntToString_ItemQuality(quality)) then
				i[link] = true
			end
		end
	end

	return i
end
local function ShowByQuality(index, anchor, itemsPerRow, qualityItems)
	local qualityCount = 0
	
	for link, v in pairs(qualityItems) do			
		if (qualityCount % itemsPerRow == 0) then
			StageAndShowItem(link, index, anchor, true)
			anchor = index
		else 
			StageAndShowItem(link, index, index - 1, false)
		end
		
		index = index + 1
		qualityCount = qualityCount + 1
	end

	return index, anchor
end
local function ShowSelectedItems(list)
	local anchor = 1
	local index = 1
	
	local itemsPerRow = GetItemsPerRow()
	
	local poorItems = FilterItemsByRarity(list, itemQuality.Poor);
	local commonItems = FilterItemsByRarity(list, itemQuality.Common);
	local uncommonItems = FilterItemsByRarity(list, itemQuality.Uncommon);
	local rareItems = FilterItemsByRarity(list, itemQuality.Rare);
	local epicItems = FilterItemsByRarity(list, itemQuality.Epic);		
	
	index, anchor = ShowByQuality(index, anchor, itemsPerRow, poorItems)
	index, anchor = ShowByQuality(index, anchor, itemsPerRow, commonItems)
	index, anchor = ShowByQuality(index, anchor, itemsPerRow, uncommonItems)
	index, anchor = ShowByQuality(index, anchor, itemsPerRow, rareItems)
	index, anchor = ShowByQuality(index, anchor, itemsPerRow, epicItems)
end
local function CreateSellList(selectedZone)
	if selectedZone == nil then
		selectedZone = "All"
	end

	local list = { }
	local loot = instanceLoot[selectedZone]
	if loot == nil then 
		return
	 end

	local sellTypeAllowed = {}
	local rarityCheckButton
	for i, rarity in ipairs(ItemQualityString) do		
		rarityCheckButton = _G["eSaithBagFilter_LootFilterFrame_"..rarity.."_CheckButton"]
		sellTypeAllowed[rarity] =  rarityCheckButton ~= nil and rarityCheckButton:IsShown() and rarityCheckButton:GetChecked()
	end
	
	local texture, locked, lootable, link  -- todo, add options to sell locked boxes and lootable items
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			texture, _, locked, _, _, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then
				-- If not already in the list then not an item to sell. Add item to list and move on
				if items[link] == nil then 
					AddItemToItemList(link) 
				end 
				-- Skip all items that cannot be sold to vendors. Do not sell lockboxes				
				if loot[link] and items[link].vendorPrice > 0 and sellTypeAllowed[items[link].rarity] and not locked and not lootable then					
					list[link] = true;
				end
			end
		end
	end

	return list
end
local function SelectItemsToShow(selectedZone)
	sellList = CreateSellList(selectedZone)
	HideItems()
	ShowSelectedItems(sellList)
	SetAlphaOnItems()
end
local function SellListedItems(list)
	print("My list to sell")
	printTable(list)

	if list == nil then return end

	print("My list to sell")
	printTable(list)
	local total = 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, _, locked, quality, _, lootable, link, _ = GetContainerItemInfo(bag, slot)					
			if texture then 				
				-- If attempting to sell Junk items that have NOT been added to the items array then do so now before attempting to sell otherwise an error will be thrown 
				-- when comparing against type.
				if items[link] == null then 
					AddItemToItemList(link)
				end

				local item = items[link]
				if list[link] and not locked and not lootable and not (
					eVar.items.kept[link] or 
					(eVar.options.keepTradeGoods and item.class == 'Trade Goods') or
					(eVar.options.keepTradeGoods and item.class == 'Tradeskill') or
					(eVar.options.keepUncommonBOEItems and item.isBOE and item.quality == itemQuality.Uncommon) or 
					(eVar.options.keepRareBOEItems and item.isBOE and item.quality ==  itemQuality.Rare) 
				) then 
					UseContainerItem(bag, slot) 	
					total = total + 1
				elseif locked then
					total = total + 1
				end
			end
		end
	end	

	UIErrorsFrame:Clear()
	return total
end
local function SellByQuality(_type)
	sellList = { }
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, _, _, quality, _, _, link = GetContainerItemInfo(bag, slot)
			if texture and quality == itemQuality[_type] then
				sellList[link] = true
			end
		end
	end

	isSelling = true	
	SellListedItems(sellList)
end
local function LootContainers()
	eVar.options.enableAutoLoot = true
	local found = false

	if MerchantFrame:IsShown() then
		print("|cffffff00Sorry but merchant window must be closed prior to looting. This is to prevent accidental selling of item")
		MerchantFrame:Hide()
	end
	
	for bag = 0, NUM_BAG_SLOTS do
		if found then
			break
		else 
			for slot = 1, GetContainerNumSlots(bag) do
				local texture, _, locked, _, _, lootable, _ = GetContainerItemInfo(bag, slot)
				if texture and lootable and not locked then
					UseContainerItem(bag, slot, false)
					found = true
					break
				end
			end
		end
	end
		
	if not found then
		eVar.options.enableAutoLoot = false
	end
end
local function ToggleOptionsFrame(self)
    -- Hide everything but options when it is open. 	
	self.open = not self.open;
	if self.open then 
        eSaithBagFilter_BottomTabs:Hide()
		eSaithBagFilter_LootFrame:Hide()
        eSaithBagFilter_SellButton:Hide()
		eSaithBagFilter_LootFilterFrame:Hide()
		eSaithBagFilter_OptionsFrame:Show()
		eSaithBagFilter_DropDown:Hide()
	else
		eSaithBagFilter_LootFrame:Show()
        eSaithBagFilter_BottomTabs:Show()        
		eSaithBagFilter_DropDown:Show()
        if MerchantFrame:IsShown() then eSaithBagFilter_SellButton:Show() end
		eSaithBagFilter_LootFilterFrame:Show()
		eSaithBagFilter_OptionsFrame:Hide()
		PanelTemplates_SetTab(eSaithBagFilter_BottomTabs, tab)
	end
end
local function eSaithBagFilter_RarityFilter_OnClick(self, button, down)
	SelectItemsToShow(eSaithBagFilter_DropDown.Title)
end
local function SetLootFilterFrameSize()
	local lootFilterFrame = eSaithBagFilter_LootFilterFrame
	lootFilterFrame:SetPoint("TOPLEFT", eSaithBagFilter, "TOPLEFT", 5, -30)
	lootFilterFrame:SetSize(eSaithBagFilter:GetWidth() - 20, eSaithBagFilter:GetHeight() - 50)
end
local function CreateLootFilterFrame()
	local lootFilterFrame = CreateFrame("Frame", "$parent_LootFilterFrame", eSaithBagFilter)
	SetLootFilterFrameSize()
	lootFilterFrame:Show()
	lootFilterFrame:SetFrameLevel(3)
	lootFilterFrame.texture = lootFilterFrame:CreateTexture("$parentTexture", "BACKGROUND");
	lootFilterFrame.texture:SetAllPoints()
	lootFilterFrame.texture:Show()	

	local prior_type = eSaithBagFilter_LootFilterFrame

	for index, _type in ipairs(ItemQualityString) do
		if index - 1 >= itemQuality.Legendary then
			break
		end

		-- Create CheckButtones for each of the rarity types. Used to show/hide their respective types
		local btn = CreateFrame("CheckButton", "$parent_"..tostring(_type).."_CheckButton", lootFilterFrame, "UICheckButtonTemplate")
		btn:SetPoint("TOP", prior_type, "TOP", 0, -25)
		btn:SetSize(25, 25)
		btn.type = _type		
		btn:SetScript("OnClick", eSaithBagFilter_RarityFilter_OnClick)
		btn.HoverText = "Show or hide ".._type.." items"
		btn:SetScript("OnEnter", Option_OnEnter)
		btn:SetScript("OnLeave", eSaithBagFilter_OnGameToolTipLeave)
		local fontstring = btn:CreateFontString("$parent_".._type.."_FontString", "ARTWORK", "GameFontNormal")
		fontstring:SetTextColor(itemTextureColors[3 * (index - 1) + 1], itemTextureColors[3 * (index - 1) + 2], itemTextureColors[3 * (index - 1) + 3])
		fontstring:SetText("Filter ".._type.." Items")
		fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
		btn:SetFontString(fontstring)
		btn:Show()
		prior_type = btn:GetName()
	end		

	eSaithBagFilter_LootFilterFrame_Poor_CheckButton:ClearAllPoints()
	eSaithBagFilter_LootFilterFrame_Poor_CheckButton:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 20, -30)
end
local function SetLootFrameSize()
	local lootFrame = eSaithBagFilter_LootFrame
	lootFrame:SetPoint("TOPLEFT", eSaithBagFilter, "TOPLEFT", 200, -40)
	lootFrame:SetSize(eSaithBagFilter:GetWidth() - 200, eSaithBagFilter:GetHeight() - 50)
end
local function CreateLootFrame() 
	local lootFrame = CreateFrame("Frame", "$parent_LootFrame", eSaithBagFilter)
	SetLootFrameSize()
	lootFrame.texture = eSaithBagFilter:CreateTexture("$parentTexture", "BACKGROUND")
	lootFrame.texture:SetColorTexture(1, 1, 1)
	lootFrame:Show()

	-- Create as many buttons for as many items that could possibly sell
	for i = 1, MAX_BAG_SLOTS do
		local btn = CreateFrame("Button", "$parent_Item" .. i, lootFrame, "eSaithBagFilterItemButtonTemplate")
		btn:SetPoint("CENTER", "$parent", "CENTER", i, i)
		btn:SetSize(35, 35)		
		btn.texture = btn:CreateTexture("$parent_Texture", "OVERLAY");
		btn.texture:SetTexture("Interface\ICONS\INV_Misc_QuestionMark");
		btn.texture:SetSize(35, 35)
		btn.texture:SetAllPoints();
		btn.texture = btn:CreateTexture("$parent_TextureBorder", "ARTWORK");
		btn.texture:SetSize(10, 10)
		btn.texture:SetAllPoints()
		btn:SetScript("OnClick", Item_OnPress)
		btn:SetScript("OnEnter", Item_OnEnter)
		btn:SetScript("OnLeave", eSaithBagFilter_OnGameToolTipLeave)
		btn:Hide(); 
	end
    
	 -- BOE font string
	fontstring = lootFrame:CreateFontString("$parent_BOEFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText("|cff02DBDBBind On Equip Items:")	
end
local function SetOptionsFrameSize()
	local optionsFrame = eSaithBagFilter_OptionsFrame
	optionsFrame:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 5, -60)
	optionsFrame:SetSize(eSaithBagFilter:GetWidth() - 15, eSaithBagFilter:GetHeight() - 65)
end
local function CreateOption(title, hoverText, variableName, under)
	local OptionsColor = "|cff2bc3e2"
	local btn = CreateFrame("CheckButton", "$parent_"..variableName, eSaithBagFilter_OptionsFrame, "UICheckButtonTemplate")
	btn:SetPoint("TOP", "$parent_"..under, "BOTTOM", 0, 5)
	btn.OptionName = variableName
	btn:SetScript("OnClick", ToggleOption)
	btn.HoverText = hoverText
    btn:SetScript("OnEnter", Option_OnEnter)
    btn:SetScript("OnLeave", eSaithBagFilter_OnGameToolTipLeave)
	fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText(OptionsColor..title.."|r")
	fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
	btn:SetFontString(fontstring)
	btn:SetChecked(eVar.options[variableName])
	btn:Show()
	ToggleOption(btn)
end
local function CreateOptionsFrame()
	local OptionsColor = "|cff2bc3e2"

	-- Options Frame
	local optionsFrame = CreateFrame("Frame", "$parent_OptionsFrame", eSaithBagFilter)
	SetOptionsFrameSize()	
	optionsFrame:SetFrameLevel(10)
	optionsFrame.texture = optionsFrame:CreateTexture("$parentTexture", "BACKGROUND");
	optionsFrame.texture:SetAllPoints()
	optionsFrame.texture:Show()	
	optionsFrame:Hide()
	
	-- Options button
	local btn = CreateFrame("Button", "$parent_OptionsButton", eSaithBagFilter, "eSaithBagFilterItemButtonTemplate")
	btn:SetSize(25, 25)
	btn.open = false
	btn:SetPoint("TOPRIGHT", "$parent", "TOPRIGHT", -15, -30)
	btn:SetScript("OnClick", ToggleOptionsFrame)
	btn.HoverText = "Options"
	btn:SetScript("OnEnter", Option_OnEnter)
	btn:SetScript("OnLeave", eSaithBagFilter_OnGameToolTipLeave)
	btn.texture = btn:CreateTexture("$parentTexture", "OVERLAY");
	btn.texture:SetTexture("Interface\\HELPFRAME\\HelpIcon-CharacterStuck")
	btn.texture:SetAlpha(.4)
	btn.texture:SetAllPoints()
	btn.texture:Show()
	btn:Show()
	
	-- Reset button
	local btn = CreateFrame("Button", "$parent_OptionsFrame_Reset", optionsFrame, "UIPanelButtonTemplate")
	btn:SetSize(100, 30)
	btn:SetPoint("BOTTOMLEFT", "$parent", "BOTTOMLEFT", 15, 15)
	btn:SetScript("OnClick", eSaithBagFilter_ResetButton_OnClick)
	local fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText("|cffffffffReset Addon")
	fontstring:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
	fontstring:Show()
	btn:Show()

	-- Loot containers
	local btn = CreateFrame("Button", "$parent_Loot", eSaithBagFilter_OptionsFrame, "UIPanelButtonTemplate")
	btn:SetSize(125, 30)
	btn:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 15, 30)
	btn:SetScript("OnClick", LootContainers)
	btn.HoverText = "Auto loot containers that do not have a cast time. \n(e.g. Unlocked lock boxes, clams, etc) Does not work on salvage items"
    btn:SetScript("OnEnter", Option_OnEnter)
    btn:SetScript("OnLeave", eSaithBagFilter_OnGameToolTipLeave)
	fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText("|cffffffffLoot Containers")
	fontstring:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
	fontstring:Show()	
	btn:Show()
	
	 -- Coordinates
	local btn = CreateFrame("CheckButton", "$parent_Coordinates", eSaithBagFilter_OptionsFrame, "UICheckButtonTemplate")
	btn:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 15, -15)
	btn:SetScript("OnClick", ToggleCoordinates)
	btn.HoverText = "Shows (x, y) coordinates under mini-map - when available. \nUnavailable in instances since Legion"
    btn:SetScript("OnEnter", Option_OnEnter)
    btn:SetScript("OnLeave", eSaithBagFilter_OnGameToolTipLeave)
	fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText(OptionsColor.."Coordinates|r")
	fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
	btn:SetFontString(fontstring)
	btn:SetChecked(eVar.options.coordinatesEnabled)
	ToggleCoordinates(btn)
	btn:Show()
	
	CreateOption(
		"Auto-Sell Junk",	
		"Auto sells junk items. \n(Gray items)",
		"enableAutoSellGrays",
		"Coordinates"
	)
	
	CreateOption(
		"Auto-keep Green BOE's",
		"Keep all uncommon (green) BOE items",
		"keepUncommonBOEItems",
		"enableAutoSellGrays"
	)
	
	CreateOption(
		"Auto Greed greens",
		"The Need or Greed pop-up is disabled for all items \nand is automatically auto-greeded.",
		"enableAutoGreedGreenItems",
		"keepUncommonBOEItems"
	)
	
	CreateOption(
		"Auto-keep Blue BOE's",
		"Keep all rare (blue) BOE items.\nNote: This disables the normal toggle keep or sell functionality",
		"keepRareBOEItems",
		"enableAutoGreedGreenItems"
	)

	CreateOption(
		"Keep trade goods",
		"Does not vendor trade good items. \nNote: This disables the normal toggle keep or sell functionality",
		"keepTradeGoods",
		"keepRareBOEItems"
	)
	
	CreateOption(
		"Quick Quest Complete",
		"Quickly obtains and complete quests.\nQuest rewards are chosen at random.",
		"questComplete",
		"keepTradeGoods"
	)
end
local function CreateCoordinates()
	-- Coordinates
	local frame = CreateFrame("Frame", "eSaithBagFilter_Coordinates", UIParent)
	frame:SetSize(100, 50)
	frame:SetPoint("TOP", "Minimap", "BOTTOM", 5, -5)
	frame:SetScript("OnUpdate", UpdateCoordinates)
	fontstring = frame:CreateFontString("$parent_FontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText("|cff33ff33")
	fontstring:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
	fontstring:Show()
end
local function ToggleIncludeInstance(self) 
	savedInstances.instances = savedInstances.instances or {}
	savedInstances.instances[self.instance] = self:GetChecked()
end
local function IsInstanceShown(instance)
	savedInstances.instances = savedInstances.instances or {}
	if savedInstances.instances[instance] ~= nil and savedInstances.instances[instance] == true then
		return true
	else
		return false
	end	
end
local function ToggleIncludePlayer(self) 
	savedInstances.players[self.player].shown = self:GetChecked()
end
local function IsPlayerShown(player)
	savedInstances.players = savedInstances.players or {}
	if savedInstances.players[player] ~= nil 
	and savedInstances.players[player].shown == true then
		return true
	else
		return false
	end	
end
local function ScrollFrameValueChange(self, value)	
	eSaithBagFilter_OptionsFrame_ScrollFrame:SetVerticalScroll(value)
	eSaithBagFilter_OptionsFrame_ScrollFrame_Slider:SetValue(value)
end
local function ScrollFrameMouseWheel(self, value)	
	local scroll = 0
	local range = eSaithBagFilter_OptionsFrame_ScrollFrame:GetVerticalScrollRange() * .10
	local result = 0

	if value > 0 then 		
		if eSaithBagFilter_OptionsFrame_ScrollFrame:GetVerticalScroll() - range < 0 then 
			result = 0
		else 
			result = eSaithBagFilter_OptionsFrame_ScrollFrame:GetVerticalScroll() - range
		end	
	else 
		if eSaithBagFilter_OptionsFrame_ScrollFrame:GetVerticalScroll() + range > eSaithBagFilter_OptionsFrame_ScrollFrame:GetVerticalScrollRange() then 
			result = eSaithBagFilter_OptionsFrame_ScrollFrame:GetVerticalScrollRange() 
		else
			result = eSaithBagFilter_OptionsFrame_ScrollFrame:GetVerticalScroll() + range
		end
	end
	ScrollFrameValueChange(self, result)
end
local function UpdateSavedInstanceFrameHeight()
	local savedFrame = eSaithBagFilter_OptionsFrame_SavedInstanceFrame
	savedFrame:SetSize(350, eSaithBagFilter_OptionsFrame:GetHeight())

	local scrollFrame = eSaithBagFilter_OptionsFrame_ScrollFrame
	scrollFrame:SetSize(savedFrame:GetWidth() - 20, savedFrame:GetHeight() - 10)

	local scrollFrameSlider = eSaithBagFilter_OptionsFrame_ScrollFrame_Slider
	scrollFrameSlider:SetHeight(savedFrame:GetHeight() - 10)
end
local function CreateSavedInstanceFrame()
	local savedFrame = CreateFrame("Frame", "$parent_SavedInstanceFrame", eSaithBagFilter_OptionsFrame)
	savedFrame:SetPoint("TOPRIGHT", "$parent", "TOPRIGHT", 0, 0)
	savedFrame:SetSize(350, eSaithBagFilter_OptionsFrame:GetHeight())	
	savedFrame.texture = savedFrame:CreateTexture("$parentTexture", "BACKGROUND")
	savedFrame.texture:SetColorTexture(1, 1, 1)
	savedFrame:Show()

	 -- Add scroll Frame
	local scrollFrame = CreateFrame("ScrollFrame", "$parent_ScrollFrame", eSaithBagFilter_OptionsFrame)
	scrollFrame:SetPoint("TOPRIGHT", "$parent", "TOPRIGHT", 10, 0)
	scrollFrame:SetSize(savedFrame:GetWidth() - 20, savedFrame:GetHeight() - 10)
	scrollFrame:Show()
	
	-- Add child frame
	local childFrame = CreateFrame("Frame", "$parent_InstanceOption", eSaithBagFilter_OptionsFrame)
	childFrame:SetPoint("TOPRIGHT", "$parent", "TOPRIGHT", 30, 0)
	childFrame:SetWidth(savedFrame:GetWidth() - 60)
	childFrame:EnableMouseWheel(true)
	childFrame:SetScript("OnMouseWheel", ScrollFrameMouseWheel)
	childFrame:Show()
	scrollFrame:SetScrollChild(childFrame)
	
	local instances = {}
	for key, value in pairs(savedInstances) do table.insert(instances, key)	end
	table.sort(instances)
	local OptionsColor = "|cff2bc3e2"
	local previousItem = childFrame
	local count = 0
	for _, instance in pairs(instances) do        		
		if instance ~= "boe" and instance ~= 'players' and instance ~= 'hiddenInstances' and instance ~= 'instances' then
			 -- Create button for each instance available			
			local btn = CreateFrame("CheckButton", "$parent_"..instance, childFrame, "UICheckButtonTemplate")
			btn:SetPoint("TOP", previousItem, "BOTTOM", 0, 0)
			btn:SetSize(20, 20)
			btn:SetScript("OnClick", ToggleIncludeInstance)
			btn.instance = instance
			fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
			fontstring:SetText(OptionsColor..instance.."|r")
			fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
			btn:SetFontString(fontstring)
			btn:SetChecked(IsInstanceShown(instance))
			btn:Show()
			count = count + 1
			previousItem = btn
		end
	end

	if _G[childFrame:GetName().."_"..instances[1]] ~= nil then
		_G[childFrame:GetName().."_"..instances[1]]:SetPoint("TOPLEFT", childFrame, "TOPLEFT", 10, -10)
	end
	childFrame:SetHeight(count * 20 + 30)

	local sliderFrame = CreateFrame("Slider", "$parent_Slider", scrollFrame, UIPanelScrollBarButton)
	sliderFrame:SetSize(30, scrollFrame:GetHeight())
	sliderFrame:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)
	sliderFrame:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
	sliderFrame.texture = sliderFrame:GetThumbTexture()
	sliderFrame:SetOrientation("Vertical")
	sliderFrame:EnableMouseWheel(true)

	local height = 0
	if childFrame:GetHeight() - scrollFrame:GetHeight() > 0 then
		height = childFrame:GetHeight() - scrollFrame:GetHeight()
	end

	sliderFrame:SetMinMaxValues(0, height)
	sliderFrame:SetValue(0)
	sliderFrame:SetValueStep(5)
	sliderFrame:SetScript("OnValueChanged", ScrollFrameValueChange)
	sliderFrame:Show()
end
local function CreateCharacterListFrame()
	local characterFrame = CreateFrame("Frame", "$parent_CharacterListFrame", eSaithBagFilter_OptionsFrame)
	characterFrame:SetPoint("TOPRIGHT", "$parent_SavedInstanceFrame", "TOPLEFT", 0, 0)
	characterFrame:SetSize(350, eSaithBagFilter_OptionsFrame:GetHeight())	
	characterFrame.texture = characterFrame:CreateTexture("$parentTexture", "BACKGROUND")
	characterFrame.texture:SetColorTexture(1, 1, 1)
	characterFrame:Show()

	 -- Add scroll Frame
	local scrollFrame = CreateFrame("ScrollFrame", "$parent_ScrollFrame", characterFrame)
	scrollFrame:SetPoint("TOPRIGHT", "$parent", "TOPRIGHT", 10, 0)
	scrollFrame:SetSize(characterFrame:GetWidth() - 20, characterFrame:GetHeight() - 10)
	scrollFrame:Show()
	
	-- Add child frame
	local childFrame = CreateFrame("Frame", "$parent_InstanceOption", eSaithBagFilter_OptionsFrame)
	childFrame:SetPoint("TOPRIGHT", "$parent", "TOPRIGHT", 30, 0)
	childFrame:SetWidth(characterFrame:GetWidth() - 60)
	childFrame:EnableMouseWheel(true)
	-- childFrame:SetScript("OnMouseWheel", ScrollFrameMouseWheel)  -- TODO
	childFrame:Show()
	scrollFrame:SetScrollChild(childFrame)
	
	local players = {}
	for key, value in pairs(savedInstances.players) do table.insert(players, key)	end
	table.sort(players)
	local OptionsColor = "|cff2bc3e2"
	local previousItem = childFrame
	local count = 0
	for _, player in pairs(players) do        		
			-- Create button for each player available			
		local btn = CreateFrame("CheckButton", "$parent_"..player, childFrame, "UICheckButtonTemplate")
		btn:SetPoint("TOP", previousItem, "BOTTOM", 0, 0)
		btn:SetSize(20, 20)
		btn:SetScript("OnClick", ToggleIncludePlayer)
		btn.player = player
		fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
		fontstring:SetText(OptionsColor..player.."|r")
		fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
		btn:SetFontString(fontstring)
		btn:SetChecked(IsPlayerShown(player))
		btn:Show()
		count = count + 1
		previousItem = btn
	end

	if _G[childFrame:GetName().."_"..players[1]] ~= nil then
		_G[childFrame:GetName().."_"..players[1]]:SetPoint("TOPLEFT", childFrame, "TOPLEFT", 10, -10)
	end
	childFrame:SetHeight(count * 20 + 30)

	local sliderFrame = CreateFrame("Slider", "$parent_Slider", scrollFrame, UIPanelScrollBarButton)
	sliderFrame:SetSize(30, scrollFrame:GetHeight())
	sliderFrame:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)
	sliderFrame:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
	sliderFrame.texture = sliderFrame:GetThumbTexture()
	sliderFrame:SetOrientation("Vertical")
	sliderFrame:EnableMouseWheel(true)

	local height = 0
	if childFrame:GetHeight() - scrollFrame:GetHeight() > 0 then
		height = childFrame:GetHeight() - scrollFrame:GetHeight()
	end

	sliderFrame:SetMinMaxValues(0, height)
	sliderFrame:SetValue(0)
	sliderFrame:SetValueStep(5)
	sliderFrame:SetScript("OnValueChanged", ScrollFrameValueChange)
	sliderFrame:Show()
end
local function UpdateTable()
	local rowValue, row, rows, rowColor, cols, t, addText, players, instances

	if savedInstances.players ~= nil and savedInstances.instances ~= nil then
		rowColor = { r = 1, g = 1, b = 1, a = 1}
		rows = {}
		t = time()
		players = {}
		for key, value in pairs(savedInstances.players) do 
			if savedInstances.players[key].shown then
				table.insert(players, key)			
			end
		 end
		table.sort(players)

		instances = {}
		for key, value in pairs(savedInstances.instances) do table.insert(instances, key)	end
		table.sort(instances)
		
		for index, instance in pairs(instances) do
			if IsInstanceShown(instance) then
				cols = {
					{["value"] = instance }
				}
				
				for index, player in ipairs(players) do
					local val = ""
					if savedInstances[instance] ~= nil and savedInstances[instance][player] ~= nil and savedInstances[instance][player].time > t then
						val = 'X'
					end

					table.insert(cols, { ["value"] = val , ["color"] = rowColor})
				end

				row = { ["cols"] = cols }   
				table.insert(rows, row) 
			end
		end

		if #rows > 0 then
			eSaithBagFilter_RaidFrame_NoRaidFontString:Hide()
			InstanceTable:Show()
			InstanceTable:SetData(rows)
		else 
			InstanceTable:SetData(rows)
			InstanceTable:Hide()
			eSaithBagFilter_RaidFrame_NoRaidFontString:Show()
		end
	end
end
local function CreateTable()
    local evenColor = { r = 0.94, g = 0.98, b = 1.0, a = 1.0 }    
    local evenBgColor = { r = 0.11, g = 0.16, b = 0.18, a = 1.0 }
    local oddColor = { r = 0.94, g = 0.98, b = 1.0, a = 1.0 }       -- #2C3E45 
    local oddBgColor = { r = 0.17, g = 0.24, b = 0.27, a = 1.0 }  
    local isEven = false

    local headers = 
    {            
        {
            ["name"] = "Raid",
            ["width"] = 250,
            ["align"] = "CENTER",
            ["color"] = evenColor,
            ["colorargs"] = nil,
            ["bgcolor"] = evenBgColor
        }    
    }

    local playerInfo, players
	players = {}
	for key, value in pairs(savedInstances.players) do 
		if savedInstances.players[key].shown then
			table.insert(players, key)
		end
	 end

	table.sort(players)
	
    for index, player in ipairs(players) do
		-- Format player with server
		local name = savedInstances.players[player].name..'\n'..savedInstances.players[player].server

		--savedInstances.players[player].server:match(%s)

		playerInfo = 
		{
		    ["name"] = name,
		    ["width"] = 75,
		    ["align"] = "CENTER",
		    ["color"] = oddColor,
		    ["colorargs"] = nil,
		    ["bgcolor"] = oddBgColor
		}
		
		if isEven then 
			    playerInfo["color"] = evenColor
			    playerInfo["bgcolor"] = evenBgColor
		end
					
		isEven = not isEven
		table.insert(headers, playerInfo)
    end
    local rowHighlight = {r = .93, g = .90, b = .74, a = .5}
	local raidFrame = CreateFrame("Frame", "$parent_RaidFrame", eSaithBagFilter)
	raidFrame:SetPoint("TOP", eSaithBagFilter, "TOP", 0, -50)
	raidFrame:SetSize(eSaithBagFilter:GetWidth() * .85, eSaithBagFilter:GetHeight() * .85)
	raidFrame:Show()

    InstanceTable = SavedInstancesTable:CreateST(headers, 10, 30, rowHighlight, raidFrame);
	raidFrame:Hide()
	InstanceTable:Show()

	-- Need to get actual child of eSaithBagFilter_RaidFrame, scrollframe. Cannot just assume its the only one (ie, other addons may use this same library)
	-- Need to position
	local children = raidFrame:GetChildren()



	local fontstring = eSaithBagFilter_RaidFrame:CreateFontString("$parent_NoRaidFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText("|cff02DBDBPlease check the options tab to include any instances you'd like to view.")
	fontstring:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
end
local function CreateSavedInstanceTable()
	SavedInstancesTable = LibStub("ScrollingTable");
	CreateTable()
	UpdateTable()
end
local function CreateWidgets()
	CreateCoordinates()	
	CreateLootFrame()
	CreateLootFilterFrame()
	CreateOptionsFrame()
	CreateSavedInstanceFrame()
	CreateCharacterListFrame()
	CreateSavedInstanceTable()
end	
local function InitializeVariables()
	instanceLoot = {}
	instanceLoot["All"] = {}
	if items == nil then items = {} end
	savedInstances = eSaithBagFilterInstances 

	if savedInstances == nil then 
		savedInstances = {}
		savedInstances.players = {}
	end

	eVar = eSaithBagFilterVar
	
	if eVar == nil then
		eVar = {
			properties = {
				version = 1.37,
				SetSizeX = 900,
				SetSizeY = 450
			},
			items = {
				kept = {}
			},
			options = {},
			options = {
				keepTradeGoods = false,
				coordinatesEnabled = false,
				enableAutoLoot = false,
				enableAutoSellGrays = false,
				keepUncommonBOEItems = false,
				keepRareBOEItems = false,
				enableAutoGreedGreenItems = false,
				enableSliders = false,
				questComplete = false
			}
		}
	end

	tab = tab or 1	 
	sellList = { }
	
	eSaithBagFilter:SetSize(eVar.properties.SetSizeX, eVar.properties.SetSizeY)
	
	local slots = {
	    "HEADSLOT","NECKSLOT","SHOULDERSLOT","BACKSLOT","CHESTSLOT","SHIRTSLOT","TABARDSLOT","WRISTSLOT","HANDSSLOT",
	    "WAISTSLOT","LEGSSLOT","FEETSLOT","FINGER0SLOT","FINGER1SLOT","TRINKET0SLOT","TRINKET1SLOT","MAINHANDSLOT","SECONDARYHANDSLOT"
	}
    
	for _index, item in pairs(slots) do
		local link = GetInventoryItemLink("player",GetInventorySlotInfo(item))
	    if link then	            
            eVar.items.kept[link] = true
	    end            
	end

	eSaithBagFilterVar = eVar
	eSaithBagFilterInstances = savedInstances
end
local function ZoneMenuItemFunction(self, selectedZone)
	for index, _type in ipairs(ItemQualityString) do
		if index - 1 < itemQuality.Legendary then
			local btn = _G["eSaithBagFilter_LootFilterFrame_".._type.."_CheckButton"]
			btn:SetChecked(true)
		end
	end

	UIDropDownMenu_SetText(eSaithBagFilter_DropDown, selectedZone);
	SelectItemsToShow(selectedZone)	
end
local function CreateZoneLootDropDownList()
	if instanceLoot == nil then instanceLoot = {} end
	if instanceLoot['All'] == nil then instanceLoot['All'] = {} end

	for instanceName, k in pairs(instanceLoot) do
		if k ~= nil then
			local info = UIDropDownMenu_CreateInfo()
			info.text, info.checked = tostring(instanceName), false
			info.arg1 = tostring(instanceName)
			info.func = ZoneMenuItemFunction
			UIDropDownMenu_AddButton(info)
		end
	end
end
local function ParseRaidInfo() 
	-- Don't save any character lower than level 60. No need to fill a list of level 1's that haven't run ICC
	if UnitLevel("player") < 60 then return end
	-- Current Player Info
	local num = GetNumSavedInstances()
	local player = UnitName("player").." ("..GetRealmName()..')'
	
	savedInstances.players = savedInstances.players or {}
	if savedInstances.players[player] == nil then 
		savedInstances.players[player] = { name = UnitName("player"), server = GetRealmName() }
	end    

	local instance, reset, difficulty
	for i = 1, num do
		instance, _, reset, _, _, _, _, _, _, difficulty = GetSavedInstanceInfo(i)
		-- Remove 'the' from "The ..." in dungeon/raid name, if applicable to sort dungeons or raids in alphabetical order      
		if string.find(instance, 'The ') == 1 then 
			instance = string.sub(instance, 5)
		end        

		instance = instance..' - '..difficulty		
		savedInstances[instance] = savedInstances[instance] or { }
		savedInstances[instance][player] = savedInstances[instance][player] or { time = 0 }
				
		if reset > 0 then
			savedInstances[instance][player].time = time() + reset
		end        
	end

	UpdateTable()
end
local function AddToolTipHandler()
	ORIGINALTOOLTIP = GameTooltip:GetScript("OnTooltipSetItem")
	GameTooltip:SetScript("OnTooltipSetItem", ReadToolTip)
end
local function SetAddonDimensions()
	eSaithBagFilter:SetResizable(true);
	eSaithBagFilter:SetMinResize(900, 300)
	eSaithBagFilter:IsClampedToScreen(true)
end
function eSaithBagFilter_OnEvent(self, event, arg1, arg2)
	if event == "ADDON_LOADED" and arg1 == "eSaithBagFilter" then
		self:UnregisterEvent("ADDON_LOADED")
		InitializeVariables() 
		CreateWidgets()	
		AddToolTipHandler()
		SetAddonDimensions()
		tinsert(UISpecialFrames, eSaithBagFilter:GetName())		
	elseif event == "CHAT_MSG_LOOT" and arg1 ~= nil then
		if string.find(arg1, "You receive item: ") ~= nil or
			string.find(arg1, "You receive loot: ") ~= nil or
			string.find(arg1, "Received item: ") ~= nil then

			-- skip everything before and after the [], but include the [] for the item
			local link = string.match(arg1, ".*(|c.*|r).*")		
			AddLoot(link)
		end
	elseif event == "MERCHANT_SHOW" then
		if eVar.options.enableAutoSellGrays then SellByQuality("Poor") end
		if tab == 1 and not eSaithBagFilter_OptionsButton:IsShown() then eSaithBagFilter_SellButton:Show() end
	elseif event == "MERCHANT_CLOSED" then
		eSaithBagFilter_SellButton:Hide()
	elseif event == "UPDATE_INSTANCE_INFO" then
		ParseRaidInfo()
	elseif event == "PLAYER_LOGOUT" then
		eSaithBagFilterVar = eVar 
		eSaithBagFilterInstances = savedInstances
	elseif event == "START_LOOT_ROLL" then
		StartLootRollID = arg1
	elseif event == "LOOT_ITEM_AVAILABLE" and StartLootRollID ~= nil then
		local item = arg1       
		local _, _, quality = GetItemInfo(item)
		if quality + 1 == 3 and eVar.options.enableAutoGreedGreenItems then   -- Quality 3 is Uncommon (green items) 
			if GroupLootContainer:IsShown() then
				RollOnLoot(StartLootRollID , 2);
			end
		end
		StartLootRollID = nil
     elseif (event == "QUEST_ACCEPTED" or event == "QUEST_DETAIL") and eVar.options.questComplete then
        AcceptQuest()
    elseif event == "QUEST_PROGRESS" then       
        if eVar.options.questComplete then
            CompleteQuest()
        end
    elseif event == "QUEST_COMPLETE" then
        if eVar.options.questComplete then
            local reward
			local num = GetNumQuestRewards()
			if num <= 1 then 
				reward = 1 
				GetQuestReward(reward)
			end
        end
	end
end
function eSaithBagFilter_OnLoad(self, event, ...)
	self:RegisterForDrag("LeftButton", "RightButton")
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("CHAT_MSG_LOOT")
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")
	self:RegisterEvent("UPDATE_INSTANCE_INFO")
	self:RegisterEvent("PLAYER_LOGOUT")
	self:RegisterEvent("START_LOOT_ROLL")
	self:RegisterEvent("LOOT_ITEM_AVAILABLE") 
    self:RegisterEvent("QUEST_DETAIL")
    self:RegisterEvent("QUEST_ACCEPTED")
    self:RegisterEvent("QUEST_PROGRESS")
    self:RegisterEvent("QUEST_COMPLETE")
end
local function StageLootTab()
	eSaithBagFilter_LootFilterFrame:Show()
	SelectItemsToShow(eSaithBagFilter_DropDown.Title)	
	if MerchantFrame:IsShown() then eSaithBagFilter_SellButton:Show() end
	eSaithBagFilter_OptionsButton:Show()  
	eSaithBagFilter_DropDown:Show()
	eSaithBagFilter_LootFrame:Show()
	eSaithBagFilter:SetWidth(eVar.properties.SetSizeX)
	eSaithBagFilter:SetHeight(eVar.properties.SetSizeY)
end
local function PrepareTab()
	if eSaithBagFilter_LootFilterFrame:IsShown() then
		eSaithBagFilter_LootFilterFrame:Hide()
	end

	if eSaithBagFilter_LootFrame:IsShown() then
		eSaithBagFilter_LootFrame:Hide()
	end

	if eSaithBagFilter_OptionsFrame:IsShown() then
		eSaithBagFilter_OptionsFrame:Hide()
	end

	eSaithBagFilter_RaidFrame:Hide()

	UIDropDownMenu_SetText(eSaithBagFilter_DropDown, "");
	eSaithBagFilter_DropDown:Hide()

	eSaithBagFilter_SellButton:Hide()
	eSaithBagFilter_OptionsButton:Hide()
end
function eSaithBagFilter_OnShow()	
	PrepareTab()
	PanelTemplates_SetTab(eSaithBagFilter_BottomTabs, 1)
	StageLootTab()	
end
local function ResizeFrames()
	SetLootFilterFrameSize()
	SetLootFrameSize()
	SetOptionsFrameSize()
	SelectItemsToShow(eSaithBagFilter_DropDown.Title)
	UpdateSavedInstanceFrameHeight()
end
function eSaithBagFilter_OnMouseDown(self, event, ...)
	if event == 'RightButton' then
		self:StartSizing()
		ResizeFrames()
	elseif event == 'LeftButton' then
		self:StartMoving();		
	end
end
function eSaithBagFilter_OnMouseUp(self, event, ...)
	self:StopMovingOrSizing()

	if event == 'RightButton' then
		ResizeFrames()
		eVar.properties.SetSizeX = eSaithBagFilter:GetWidth()
		eVar.properties.SetSizeY = eSaithBagFilter:GetHeight()
	end
end
function eSaithBagFilter_OnStopDrag(self, event, ...)
	self:StopMovingOrSizing()
end
function eSaithBagFilter_SellButton_OnClick(self, event, ...)
	isSelling = true;
	SellListedItems(sellList)
end
function eSaithButton_MerchantFrame_OnUpdate(self, elapsed)
	if not self.TimeSinceLastUpdate then self.TimeSinceLastUpdate = 0 end

	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
	if isSelling and self.TimeSinceLastUpdate > .5 then
		self.TimeSinceLastUpdate = 0

		if SellListedItems(sellList) == 0 then
			isSelling = false
			sellList = { }
			HideItems()
		end		
	end
	
	-- Timer for auto loot items (lockboxes, etc)
	if eVar.options.enableAutoLoot and self.TimeSinceLastUpdate > .5 + 3 then
		self.TimeSinceLastUpdate = 0
		LootContainers();
	end
end
function eSaithBagFilter_SellButton_OnHide(self, event, ...)
	isSelling = false
	sellList = {}
end
function eSaithBagFilter_ResetButton_OnClick(self, event)    
	eVar = {}
	eSaithBagFilterVar = {}
	eSaithBagFilterInstances = {}
	eSaithBagFilterInstanceLoot = {}
	eSaithBagFilterItems = {}
	savedInstances = {}
	instanceLoot = {}	
	InitializeVariables()       
end
function eSaithBagFilter_BottomTab_OnClick(self, event, ... )
	PrepareTab()
	tab = self:GetID()
	
	if tab == 1 then 
		StageLootTab()
	elseif tab == 2 then
		RequestRaidInfo()	
		eSaithBagFilter_RaidFrame:Show()

		if eSaithBagFilter:GetWidth() < ScrollTable1:GetWidth() then
			eSaithBagFilter:SetWidth(ScrollTable1:GetWidth() + 20)
		end

		if eSaithBagFilter:GetHeight() < ScrollTable1:GetHeight() + 100 then
			eSaithBagFilter:SetHeight(ScrollTable1:GetHeight() + 100)
		end

		UpdateSavedInstanceFrameHeight()
	end
end
function eSaithBagFilter_CreateDropDownList(self)
	CreateZoneLootDropDownList()	
end
function SlashCmdList.ESAITHBAGFILTER(msg, editbox)
	if eSaithBagFilter:IsShown() then
		eSaithBagFilter:Hide()
	else
		eSaithBagFilter:Show()
	end

	local command = msg:match("^(%S*)%s*(.-)$")
	if command == "center" then
		eSaithBagFilter:ClearAllPoints()
		eSaithBagFilter:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		eSaithBagFilter:Show()
	end

	if command == "reset" then
		eSaithBagFilter_ResetButton_OnClick()
		eSaithBagFilter:ClearAllPoints()
		eSaithBagFilter:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		eSaithBagFilter:Show()
	end
end

--[[ Notes:

-- Instead of showing multiples of the same loot, count and condense with # showing how many
-- Consider adding transparency button if mouse is not over AddOn
-- Add a "Never sell list" so that items never show up on list. Allow the list to be modified

-- Auto loot multiple items even if there is a cast timer. Possibly check out how TSM does it with auto auction and clicking 100x
-- Open immediately to the last zone that player looted from. If last zone has already been sold then open from the zone prior to that one
-- Add BOE section back in
-- Add background color, or distinction 

--]]