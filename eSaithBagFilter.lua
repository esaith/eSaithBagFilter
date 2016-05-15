SLASH_ESAITHBAGFILTER1 = '/efilter'
local MAX_ITEM_COUNT = -1
local ZONE -- used for updating world coordinates
local OriginalToolTip  -- used to save original functionality to the tooltip. Used for hooking a function
local MAX_BAG_SLOTS = 200    
local eVar -- Short for eVar
local eInstances -- short for eSaithBagFilterInstances. For saving instances on all characters on all realms
local eInstanceLoot -- short for eSaithBagFilterInstanceLoot. Loot from each zone, dungeon, raid, etc.
local ALPHA = .4
local StartLootRollID = nil
local STRINGS = {
	OPEN_ADDON = "Open ESaith Item Filter",
	SELL = "Sell",
	TO_LOOT = "To use this functionality, you -must- make sure your Auto Loot is enabled. To enable, open your Interface > Controls > Auto Loot is checked. Sorry for this inconvenience. Thank you",
	STOP_TALKING_TO_VENDOR = "Sorry to be rude but to loot you mustn't be talking to a merchant. Thank you.",
	NOT_ENOUGH_SPACE = "You do not have enough bag space to safely loot item(s).",
	ADDON_UPDATED = "AddOn updated to version"
}

local function printTable(tb, spacing)
    if spacing == nil then spacing = "" end
    if tb == nil then print("Table is nil") return end
    if type(tb) ~= "table" then
        print(type(tb), tb)        
    end

    print(spacing .. "Entering table")
    for k, v in pairs(tb) do
        print(spacing .. "K: " .. k .. ", v: " .. tostring(v))
        if type(v) == "table" then
            printTable(v, "   " .. spacing)
        end
    end
    print(spacing .. "Leaving Table")
end

local function PrepreToolTip(self)
    local x = self:GetRight();
    if (x >=(GetScreenWidth() / 2)) then
        GameTooltip:SetOwner(self, "ANCHOR_LEFT");
    else
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    end
end
local function ReadToolTip(self, ...)
    local boundText =  tostring(GameTooltipTextLeft2:GetText()) .. 
                        tostring(GameTooltipTextLeft3:GetText()) .. 
                        tostring(GameTooltipTextLeft4:GetText()) .. 
                        tostring(GameTooltipTextLeft5:GetText())

    if boundText:find(".* when equip.*") or boundText:find(".*on equip*") or boundText:find(".* account.*") or 
    not (boundText:find(".* picked.*") or boundText:find(".* pick up.*") or boundText:find(".*Soulbound.*")) then
        local _, link = GameTooltip:GetItem() 
        eInstances.boe[link] = true
    end
    return OriginalToolTip(self, ...)
end
local function ResetAlphaOnAllButtons()
    for index = 1, MAX_ITEM_COUNT do
        local btn = _G["eSaithBagFilterSellItem" .. index]
        if _G["eSaithBagFilterSellItem" .. index] and _G["eSaithBagFilterSellItem" .. index]:IsShown() then
            if eVar.properties.keep[_G["eSaithBagFilterSellItem" .. index].link] or eVar.properties.keepTradeGoods[_G["eSaithBagFilterSellItem" .. index].link] then
                _G["eSaithBagFilterSellItem" .. index]:SetAlpha(ALPHA)
            else
                _G["eSaithBagFilterSellItem" .. index]:SetAlpha(1)
            end
        end
    end
end
local function AddLoot(obj, quality)    local zone = GetRealZoneText()
    if eInstanceLoot[zone] == nil then eInstanceLoot[zone] = { } end
    eInstanceLoot[zone][obj] = true    
    GameTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    GameTooltip:SetHyperlink(obj)    
    GameTooltip:Show()   
    GameTooltip:Hide()    
end
local function SetIncludedBOEItems()
    eVar.properties.BOEGreen = eSaithBagFilterOptions_BOEGreenItems:GetChecked()
end

local function ItemButton_OnPress(self, event, button)  
    eVar.properties.keep[self.link] = not eVar.properties.keep[self.link]
    ResetAlphaOnAllButtons()
end
local function ItemButton_OnEnter(self, motion)
    PrepreToolTip(self)
    GameTooltip:SetHyperlink(self.link)
    GameTooltip:Show()
end
function eSaithBagFilterSellButton_OnEnter(self, event, ...)
    PrepreToolTip(self)
    GameTooltip:AddLine(STRINGS.SELL)
    GameTooltip:Show()
end
function OnGameToolTipLeave(self, motion)
    GameTooltip:Hide()
end

function eSaithBagFilterOpenFrame_OnClick(self, event, ...)
    if eSaithBagFilter:IsShown() then
        eSaithBagFilter:Hide()
    else
        eSaithBagFilter:Show()
        if eVar.properties.LeftTab < 4 then
            eSaithBagFilterSellButton:Show()
        end
    end
end
function eSaithBagFilterOpenFrame_OnEnter(self, motion)
    PrepreToolTip(self)
    GameTooltip:AddLine(STRINGS.OPEN_ADDON)
    GameTooltip:Show()
end
function eSaithBagFilterTab_OnEnter(self, motion)
    local array = { "Filter By Zone", "Filter By iLevel", "Filter By Rarity", "Characters Log", "Options Tab" }
    PrepreToolTip(self)
    GameTooltip:AddLine(array[self:GetID()])
    GameTooltip:Show()
end

local function UpdateCoordinates(self, elapsed)
    if not eVar.properties.coordsOn then return end
    if ZONE ~= GetRealZoneText() then
        ZONE = GetRealZoneText()
        SetMapToCurrentZone()
    end

    if self.TimeSinceLastUpdate == nil then self.TimeSinceLastUpdate = 0 end
    self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
    if self.TimeSinceLastUpdate > .5 then
        self.TimeSinceLastUpdate = 0
        local posX, posY = GetPlayerMapPosition("player");
        local fontstring = eSaithBagFilterCoordinatesFontString
        local x = math.floor(posX * 10000) / 100
        local y = math.floor(posY * 10000) / 100
        fontstring:SetText("|cff98FB98(" .. x .. ", " .. y .. ")")
        fontstring:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
        fontstring:Show()
    end
end
local function CoordinatesCheckButton_OnClick(self, event, button)
    eVar.properties.coordsOn = eSaithBagFilterOptions_Coordinates:GetChecked()
    if eSaithBagFilterOptions_Coordinates:GetChecked() then
        eSaithBagFilterCoordinates:Show()
    else
        eSaithBagFilterCoordinates:Hide()
    end
end

local function LootContainers()
    eVar.properties.autoloot = true
    print("|cffff0000"..STRINGS.TO_LOOT)   

    if MerchantFrame:IsShown() then
        print("|cffffff00"..STRINGS.STOP_TALKING_TO_VENDOR)
        MerchantFrame:Hide()
    end

    local count = 0
    local found = false
    for bag = 0, NUM_BAG_SLOTS do
        count = count + GetContainerNumFreeSlots(bag)
    end

    if count > 0 then   -- save on runtime on dual loop
        for bag = 0, NUM_BAG_SLOTS do
            if not found then
                for slot = 1, GetContainerNumSlots(bag) do
                    local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
                    if texture and lootable then
                        if not locked and count > 0 then
                            UseContainerItem(bag, slot, false)
                            found = true
                        end
                    end
                end
            end
        end
    else    
        print(STRINGS.NOT_ENOUGH_SPACE)
    end

    if not found then
        eVar.properties.autoloot = false
    end
end
local function SellListedItems()
    eVar.properties.update = true
    local count = 0
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local texture, _, locked, _, _, _, link = GetContainerItemInfo(bag, slot)
            if texture and eVar.properties.sell[link] then
                if not locked then UseContainerItem(bag, slot) end
                count = count + 1
            end
        end
    end
    return count
end
local function AutoSellGrayCheckButton_OnClick()
    eVar.properties.autoSellGrays = eSaithBagFilterOptions_AutoSellGray:GetChecked()
end
local function SellByQuality(_type)
    local texture, locked, quality, lootable, link, vendorPrice, personalItem
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            texture, _, locked, quality, _, lootable, link = GetContainerItemInfo(bag, slot)
            if texture then
                _, _, _, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(link)
                personalItem = eVar.properties.keep[link] or eVar.properties.keepTradeGoods[link]
                if (personalItem == nil or not personalItem) and not (locked or lootable) and vendorPrice > 0 and quality < 5 then
                    if eVar.properties.types[quality + 1] == _type then
                        if eVar.properties.sell[link] == nil then eVar.properties.sell[link] = true end                        
                    end
                end
            end
        end
    end
    SellListedItems()
end
local function SetAutoGreedGreenItems()
    eVar.properties.AutoGreedGreenItems = eSaithBagFilterOptions_AutoGreedGreen:GetChecked()
end
local function ToggleKeepTradeGoods()
	eVar.properties.IsTradeGoodKept = eSaithBagFilterCheckButton_TradeGoods:GetChecked()
	eVar.properties.keepTradeGoods = { } 
end

local function CreateCheckButtons()
    local width = eSaithBagFilter:GetWidth()
    local fontstring, btn
    for index, _type in ipairs(eVar.properties.types) do
        btn = CreateFrame("CheckButton", "$parentCheckButton" .. _type, eSaithBagFilter, "UICheckButtonTemplate")
        btn:SetPoint("TOP", "$parent", "TOP", - math.floor(width / 5), -30)
        btn:SetScript("OnClick", eSaithBagFilterCheckBox_Click)
        fontstring = btn:CreateFontString("eSaithBagFilterCheckButton" .. _type .. "FontString", "ARTWORK", "GameFontNormal")
        fontstring:SetTextColor(eVar.properties.texture[3 * index], eVar.properties.texture[3 * index + 1], eVar.properties.texture[3 * index + 2])
        fontstring:SetText("Filter " .. _type .. " Items")
        fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
        btn:SetFontString(fontstring)
        btn:Hide()
    end

    -- Reset button
    btn = CreateFrame("Button", "$parentResetButton", eSaithBagFilter, "UIPanelButtonTemplate")
    btn:SetSize(100, 30)
    btn:SetPoint("BOTTOMRIGHT", "$parent", "BOTTOMRIGHT", -15, 15)
    btn:SetScript("OnClick", eSaithBagFilterResetButton_Click)
    fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
    fontstring:SetText("|cffffffffReset Addon")
    fontstring:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
    fontstring:Show()
    btn:Show()

    -- Create all widgets that could possibly sell
    for i = 1, MAX_BAG_SLOTS do
        btn = CreateFrame("Button", "eSaithBagFilterSellItem" .. i, eSaithBagFilter, "eSaithBagFilterItemButtonTemplate")
        btn:SetPoint("CENTER", "$parent", "CENTER", i, i)
        btn:SetSize(35, 35)
        btn.texture = btn:CreateTexture("$parentTexture", "OVERLAY");
        btn.texture:SetTexture("Interface\ICONS\INV_Misc_QuestionMark");
        btn.texture:SetSize(35, 35)
        btn.texture:SetAllPoints();
        btn.texture = btn:CreateTexture("$parentTextureBorder", "ARTWORK");
        btn.texture:SetTexture(1, 1, 1, 1)
        btn.texture:SetSize(10, 10)
        btn.texture:SetAllPoints()
        btn:SetScript("OnClick", ItemButton_OnPress)
        btn:SetScript("OnEnter", ItemButton_OnEnter)
        btn:SetScript("OnLeave", OnGameToolTipLeave)
        btn:Hide();
    end
    
    -- Just create the fontstring for now. They will be used later on when player views save dungeons/raid listing  
    eSaithBagFilter:CreateFontString("$parentInstanceInfoFontStringFreshTitle", "ARTWORK", "GameFontNormal")
    eSaithBagFilter:CreateFontString("$parentInstanceInfoFontStringFreshList", "ARTWORK", "GameFontNormal")
    eSaithBagFilter:CreateFontString("$parentInstanceInfoFontStringSavedTitle", "ARTWORK", "GameFontNormal")
    eSaithBagFilter:CreateFontString("$parentInstanceInfoFontStringSavedList", "ARTWORK", "GameFontNormal")
	
	-- Just create the frames for now. They will be used when items are filtered into their types
	local h = -120
	--local frame
	index = 1
	for index, _colors in ipairs(eVar.properties.colors) do
		frame = CreateFrame("Frame", "eSaithBagFilterFrame".._colors, eSaithBagFilter)
		frame:SetPoint("LEFT", "$parent", "LEFT", 8, 0)
		frame:SetPoint("RIGHT", "$parent", "RIGHT", -10, 0)
		frame:SetPoint("TOP", "$parent", "TOP", 0, h - 10)
		frame:SetHeight(50)
		frame.texture = frame:CreateTexture("$parentTexture", "ARTWORK")
		frame.texture:SetTexture(eVar.properties.texture[3 * index], eVar.properties.texture[3 * index + 1], eVar.properties.texture[3 * index + 2], ALPHA - .3);
		frame.texture:SetAllPoints()
		frame:Hide()
		h = h - 50
	end
    
    -- Coordinates
    frame = CreateFrame("Frame", "eSaithBagFilterCoordinates", UIParent)
    frame:SetSize(100, 50)
    frame:SetPoint("TOP", "Minimap", "BOTTOM", 5, -5)
    frame:SetScript("OnUpdate", UpdateCoordinates)
    fontstring = frame:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
    fontstring:SetText("|cff33ff33")
    fontstring:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
    fontstring:Show()
    
    -- Option Buttons

	 -- Coordinates
    btn = CreateFrame("CheckButton", "$parentOptions_Coordinates", eSaithBagFilter, "UICheckButtonTemplate")
    btn:SetPoint("TOP", "$parent", "TOP", -125, -25)
    btn:SetScript("OnClick", CoordinatesCheckButton_OnClick)
    fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
    fontstring:SetText("Turn On Coordinates (Located Under Mini-Map)")
    fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
    btn:SetFontString(fontstring)
    btn:Show()
    
    -- Auto Sell Gray items checkbox
    btn = CreateFrame("CheckButton", "$parentOptions_AutoSellGray", eSaithBagFilter, "UICheckButtonTemplate")
    btn:SetPoint("TOP", "$parentOptions_Coordinates", "TOP", 0, -25)
    btn:SetScript("OnClick", AutoSellGrayCheckButton_OnClick)
    fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
    fontstring:SetText("Auto Sell Gray Items")
    fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
    btn:SetFontString(fontstring)
    btn:Show()
    
    -- BOE green items (Does user want to include these as well)
    btn = CreateFrame("CheckButton", "$parentOptions_BOEGreenItems", eSaithBagFilter, "UICheckButtonTemplate")
    btn:SetPoint("TOP", "$parentOptions_AutoSellGray", "TOP", 0, -25)
    btn:SetScript("OnClick", SetIncludedBOEItems)
    fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
    fontstring:SetText("Filter Uncommon (Green) BOE items")
    fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
    btn:SetFontString(fontstring)
    btn:Show()

    -- Auto greed on green items
    btn = CreateFrame("CheckButton", "$parentOptions_AutoGreedGreen", eSaithBagFilter, "UICheckButtonTemplate")
    btn:SetPoint("TOP", "$parentOptions_BOEGreenItems", "TOP", 0, -25)
    btn:SetScript("OnClick", SetAutoGreedGreenItems)
    fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
    fontstring:SetText("Auto greed Uncommon (Green) items.")
    fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
    btn:SetFontString(fontstring)
    btn:Show()
    
	-- Do not sell trade goods
    btn = CreateFrame("CheckButton", "$parentCheckButton_TradeGoods", eSaithBagFilter, "UICheckButtonTemplate")
	btn:SetScript("OnClick", ToggleKeepTradeGoods)
    btn:SetPoint("TOP", "$parentOptions_AutoGreedGreen", "TOP", 0, -25)
    fontstring = btn:CreateFontString("eSaithBagFilterCheckButtonTradeGoodsFontString", "ARTWORK", "GameFontNormal")
    fontstring:SetText("Do not sell Trade Goods")
    fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
    btn:SetFontString(fontstring)
    btn:Show()
	
    -- Auto loot containers
    btn = CreateFrame("Button", "$parentLootButton", eSaithBagFilter, "UIPanelButtonTemplate")
    btn:SetSize(125, 30)
    btn:SetPoint("TOP", "$parentCheckButton_TradeGoods", "TOP", 100, -30)
    btn:SetScript("OnClick", LootContainers)
    fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
    fontstring:SetText("|cffffffffLoot Containers")
    fontstring:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
    fontstring:Show()
    btn:Show()
	
    -- BOE font string
    fontstring = eSaithBagFilter:CreateFontString("$parentBOEFontString", "ARTWORK", "GameFontNormal")
    fontstring:SetText("|cffff0000Bind On Equip Items:")
end
local function CreateRarityObjects()
    eInstanceLoot = eInstanceLoot or { }
    eInstances = eSaithBagFilterInstances or 
    {   
        players = { }, 
        boe = { } 
    }

    if eVar == nil then
        eVar = {
            properties =
            {
                LeftTab = 1,
                BottomTab = 1,
                zone = nil,
                types =
                {
                    "Poor","Common","Uncommon","Rare","Epic"-- , "Legendary", "Artifact", "Heirloom", "WoW Token" },
                },
                colors =
                {
                    "Gray","White","Green","Blue","Purple"-- , "Orange" , "Gold", "FoolsGold", "Cyan"
                },
                texture = { 0, 0, .6, .6, .6, 1, 1, 1, 0, 1, 0, .2, .2, 1, 1, 0, 1, .8, .8, 0 },
                update = false,
				IsTradeGoodKept = false,
                updateCount = 0,
                itemUpdateCount = 0,
                updateInterval = 0.5,
                maxTime = 0,
                keep = { },
                sell = { },
				keepTradeGoods = { },
                coordsOn = false,
                autoloot = false,
                autoSellGrays = false,
                version = 1.33,
                BOEGreen = false,
                AutoGreedGreenItems,
                MAX_ITEMS_PER_ROW = 15,
				SetSizeX = 500,
				SetSizeY = 600
            }
        }
        for index, _type in pairs(eVar.properties.types) do
            if _type ~= properties then 
                eVar[_type] = { }
                eVar[_type]:SetChecked(false)
                eVar[_type].min = 0
                eVar[_type].max = 0
                eVar[_type].minChecked = false
                eVar[_type].maxChecked = false
            end
        end
    end
	
	eSaithBagFilter:SetSize(eVar.properties.SetSizeX, eVar.properties.SetSizeY)
    -- TODO Any gear the character is current wearing when logging in should be immediately put in kept list each time the character logs in
    --    local slots = {
    --        "HEADSLOT","NECKSLOT","SHOULDERSLOT","BACKSLOT","CHESTSLOT","SHIRTSLOT","TABARDSLOT","WRISTSLOT","HANDSSLOT",
    --        "WAISTSLOT","LEGSSLOT","FEETSLOT","FINGER0SLOT","FINGER1SLOT","TRINKET0SLOT","TRINKET1SLOT","MAINHANDSLOT","SECONDARYHANDSLOT"
    --    }

    --    local slotId, _texture, itemId, link
    --    for _index, item in pairs(slots) do
    --        slotId = GetInventorySlotInfo(item)
    --        itemId = GetInventoryItemID("player", slotId)
    --        if itemId ~= nil then
    --            _, link = GetItemInfo(itemId)
    --            eVar.properties.keep[link] = true
    --        end
    --    end

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
    if zone == nil or eInstanceLoot[zone] == nil then return end
    local zoneTable = eInstanceLoot[zone]
    local texture, link

    -- Set all values that are currently non-nil to false. This will set the stage to filtering what is still in the
    -- bags vs what has already been sold. If the value is nil, the item has already been sold
    for item, value in pairs(zoneTable) do
        if value ~= nil then
            value = false
        end
    end

    -- Stage 2: Search each item bag slot. If the bag slot matches a non-nil table item, then the item has not been sold
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 0, GetContainerNumSlots(bag) do
            texture, _, _, _, _, _, link = GetContainerItemInfo(bag, slot)
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

    if count == 0 then eInstanceLoot[zone] = nil end
end
local function PassMin(ilevel, minlvl, required)
    return not required or ilevel >= minlvl
end
local function PassMax(ilevel, maxlvl, required)
    return not required or ilevel <= maxlvl
end

local function CreateItemButton(item, index, xoffset, yoffset)
    local btn = _G["eSaithBagFilterSellItem" .. index]
    btn:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 41 * xoffset - 27, -200 - yoffset * 45)
    btn.texture = _G[btn:GetName() .. "Texture"]
    btn.texture:Show()
    btn.texture:SetTexture(item.text)
    btn.texture = _G[btn:GetName() .. "TextureBorder"]
    btn.texture:Show()
    btn.texture:SetTexture(eVar.properties.texture[3 * item.colorIndex], eVar.properties.texture[3 * item.colorIndex + 1], eVar.properties.texture[3 * item.colorIndex + 2], 1)
    btn:Show()
    btn.link = item.link
end
local function ShowListedItems(count)
    -- Hide old items prior to showing updated list
    for i = 1, MAX_ITEM_COUNT do
        _G["eSaithBagFilterSellItem" .. i]:Hide()
    end
    MAX_ITEM_COUNT = count
    if eVar.properties.sell == nil then return end
	
    local MAX_ROW = eVar.properties.MAX_ITEMS_PER_ROW
    local yoffset = 0
    local xoffset = 1
    local list = eVar.properties.sell
    local color_found
	local begin_height
    local boe = nil
    local ButtonIndex = 0
	local base = 155
	
    for _index, color in pairs(eVar.properties.colors) do
        color_found = false
		begin_height = yoffset
        for index = 1, count do			
            if tostring(list[index].colorIndex) == tostring(_index) then				
                if xoffset % MAX_ROW == 0 then
                    yoffset = yoffset + .85
                    xoffset = 1
                end
				
                if eInstances.boe[list[index].link] and (list[index].colorIndex > 3  or (eVar.properties.BOEGreen and list[index].colorIndex > 2)) then    
                    if boe == nil then boe = { } end          
                    boe[list[index].link] = list[index]
                else					
                    ButtonIndex = ButtonIndex + 1
                    CreateItemButton(list[index], ButtonIndex, xoffset, yoffset)
                    xoffset = xoffset + 1
                    color_found = true                    
                end
            end
        end
		
		local frame = _G["eSaithBagFilterFrame"..color]
        if color_found then -- Create background only for rarities that are listed
			yoffset = yoffset + 1
			frame:SetPoint("LEFT", "$parent", "LEFT", 8, 0)
			frame:SetPoint("RIGHT", "$parent", "RIGHT", -10, 0)
			frame:SetPoint("TOP", "$parent", "TOP", 0, -base - (begin_height + 1) * 45 + 5)
			frame:SetHeight( (yoffset - begin_height) * 45 )
			frame:Show()
		else
			frame:Hide()
		end  
        xoffset = 1
    end
	    -- Append BOE items at the end
	local frameHeight = -base - (begin_height + 1) * 45 + 5 - ((yoffset - begin_height) * 45 +15)
	begin_height = yoffset
    if boe ~= nil then
		zoffset = 1
        local fontstring = eSaithBagFilterBOEFontString
        fontstring:SetPoint("TOP", "$parent", "TOP", 0, frameHeight)
        fontstring:Show()
		yoffset = yoffset + .5
        for item, content in pairs(boe) do
            if xoffset % MAX_ROW == 0 then
                yoffset = yoffset + 1
                xoffset = 1
            end				
            ButtonIndex = ButtonIndex + 1
            CreateItemButton(content, ButtonIndex, xoffset, yoffset)
            xoffset = xoffset + 1			
        end
    else        
        eSaithBagFilterBOEFontString:Hide()
    end

	frameHeight = base + (begin_height + 2) * 45 + ((yoffset - begin_height) * 45)
    local x = eSaithBagFilter:GetSize()
	--local NewHeight = frameHeight + zoffset * 45 
    if frameHeight > eSaithBagFilter:GetHeight() then 
		eSaithBagFilter:SetSize(x, frameHeight)
	else
		eSaithBagFilter:SetSize(x, eVar.properties.SetSizeY)
	end
end

local function SelectZoneItems()
    local zone = eVar.properties.zone
    if eInstanceLoot[zone] == nil then return end
    local zoneTable = eInstanceLoot[zone]
    local texture, quality, lootable, link, itemName
    eVar.properties.sell = { }

    local count = 0
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            texture, _, _, quality, _, lootable, link = GetContainerItemInfo(bag, slot)
            if texture and not locked and not lootable then
                itemName = GetItemInfo(link)
                if zoneTable[link] then
                    count = count + 1
                    eVar.properties.sell[count] = { link = link, text = texture, colorIndex = quality + 1, itemName = itemName }
                end
            end
        end
    end
    ShowListedItems(count)
    ResetAlphaOnAllButtons()
end
local function SelectiLevelItems()
    eVar.properties.sell = { }

    local texture, locked, quality, lootable, link, ItemName, ilevel
    local count = 0
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local texture, _, locked, quality, _, lootable, link = GetContainerItemInfo(bag, slot)
            if texture then
                ItemName, _, _, ilevel, _, _, _, _, _, _, vendorPrice = GetItemInfo(link)
                if vendorPrice > 0 and not locked and not lootable then
                    -- Skip all items that cannot be sold to vendors					
                    local _type = eVar.properties.types[quality + 1]
                    if _type ~= nil and _G["eSaithBagFilterCheckButton" .. _type]:GetChecked()
                        and PassMin(ilevel, eVar[_type].min, eVar[_type].minChecked)
                        and PassMax(ilevel, eVar[_type].max, eVar[_type].maxChecked) then
                        count = count + 1
                        eVar.properties.sell[count] = { link = link, text = texture, colorIndex = quality + 1, itemName = ItemName }
						
							-- If item is a Trade Good and "Do not sell trade good items options" is selected. Add to KeepTradeGoods list
						if eVar.properties.IsTradeGoodKept and class == "Trade Goods" then							
							eVar.properties.keepTradeGoods[link] = true
						end
                    end
                end
            end
        end
    end
    ShowListedItems(count)
    ResetAlphaOnAllButtons()
end
local function SelectRarityItems()
    eVar.properties.sell = { }
    
    local texture, locked, quality, lootable, link, class 
    local count = 0
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            texture, _, locked, quality, _, lootable, link = GetContainerItemInfo(bag, slot)
            if texture and not (locked or lootable) then
                local ItemName, _, _, _, _, class, _, _, _, _, vendorPrice = GetItemInfo(link)
                local _type = eVar.properties.types[quality + 1]
                if _type ~= nil and _G["eSaithBagFilterCheckButton" .. _type]:GetChecked() and vendorPrice > 0 then
                    count = count + 1
                    eVar.properties.sell[count] = { link = link, text = texture, colorIndex = quality + 1, itemName = ItemName }					
					-- If item is a Trade Good and "Do not sell trade good items options" is selected. Add to KeepTradeGoods list
					if eVar.properties.IsTradeGoodKept and class == "Trade Goods" then
						eVar.properties.keepTradeGoods[link] = true
					end
                end
            end
        end
    end
    ShowListedItems(count)
    ResetAlphaOnAllButtons()
end

local function ZoneMenuItemFunction(self, arg1, arg2, checked)
    eVar.properties.zone = self.arg1

    -- Update the table prior to using it
    UpdateZoneTable(self.arg1)
    local zoneTable = eInstanceLoot[self.arg1]
    if zoneTable == nil then
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
    SelectZoneItems()
    if (not checked) then
        UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
    end
end
local function CreateZoneDropDownList()
    if eInstanceLoot == nil then return end

    local i = 1
    for v, k in pairs(eInstanceLoot) do
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

local function GetRarity(ilevel)
    return eVar.properties.types[ilevel]
end  
local function ParseRaidInfo() 
    -- Don't save any character lower than level 70. No need to fill a list of level 1's that haven't run ICC
    if UnitLevel("player") < 70 then return end
    
    local iName, iReset, iDifficulty, iDifficultyName, instance

    -- Current Player Info
    local NumOfInstances = GetNumSavedInstances()
    local PlayerIndex = UnitName("player").." ("..GetRealmName()..")"
    

    if eInstances.players == nil then eInstances.players = {} end
    if eInstances.players[PlayerIndex] == nil then 
        eInstances.players[PlayerIndex] = { name = UnitName("player"), server = GetRealmName() }
    end    
    
    for i = 1, NumOfInstances do
        iName, _, iReset, iDifficulty, _, _, _, _, _, iDifficultyName = GetSavedInstanceInfo(i)
        -- Remove 'the' from "The ..." in dungeon/raid name, if applicable        
        if string.find(iName, 'The ') == 1 then 
            iName = string.sub(iName, 5)
        end        
        instance = iName..' - '..iDifficultyName
        
        if eInstances[instance] == nil then eInstances[instance] = { } end
        if eInstances[instance][PlayerIndex] == nil then eInstances[instance][PlayerIndex] = { time = 0 } end
                
        if iReset > 0 then
            eInstances[instance][PlayerIndex].time = time() + iReset
        end        
    end
end
local function PrepareToShowSideTabs()
    -- TODO -may- fix PrepareToShowSideTabs function. No need to do this entire thing every time a tab is switched. Function isnt as large as originally thought

    eSaithBagFilterSellButton:Hide()
    eSaithBagFilterBOEFontString:Hide()
    -- Hide Zone tab
    eSaithBagFilterDropDown:Hide()
    eSaithBagFilterCheckButton_TradeGoods:Hide()
    eSaithBagFilterLootButton:Hide()

    -- Hide Tab iLvl and Rarity tabs
    for index, _type in pairs(eVar.properties.types) do
        _G["eSaithBagFilterCheckButton" .. _type]:Hide()
    end

    eSaithBagFilterILVLBottomTabs:Hide()
    eSaithBagFilterSliderMin:Hide()
    eSaithBagFilterSliderMax:Hide()

	local btn
    for i = 1, MAX_BAG_SLOTS do
        btn = _G["eSaithBagFilterSellItem" .. i]
        btn:Hide();
    end
	
	for index, _colors in ipairs(eVar.properties.colors) do
		btn = _G["eSaithBagFilterFrame".._colors]
		btn:Hide()
	end
    -- Hide Character Raid tab
    eSaithBagFilterResetButton:Hide()
    eSaithBagFilter:SetSize(600, 500)
   
    if eSaithBagFilterInstanceInfoFontStringFreshTitle:IsShown() then eSaithBagFilterInstanceInfoFontStringFreshTitle:Hide() end
    if eSaithBagFilterInstanceInfoFontStringFreshList:IsShown() then eSaithBagFilterInstanceInfoFontStringFreshList:Hide() end
    if eSaithBagFilterInstanceInfoFontStringSavedTitle:IsShown() then eSaithBagFilterInstanceInfoFontStringSavedTitle:Hide() end
    if eSaithBagFilterInstanceInfoFontStringSavedList:IsShown() then eSaithBagFilterInstanceInfoFontStringSavedList:Hide() end

    -- Options Tab	
    if eSaithBagFilterOptions_Coordinates:IsShown() then eSaithBagFilterOptions_Coordinates:Hide() end
    if eSaithBagFilterOptions_AutoSellGray:IsShown() then eSaithBagFilterOptions_AutoSellGray:Hide() end
    if eSaithBagFilterOptions_BOEGreenItems:IsShown() then eSaithBagFilterOptions_BOEGreenItems:Hide() end
    if eSaithBagFilterOptions_AutoGreedGreen:IsShown() then eSaithBagFilterOptions_AutoGreedGreen:Hide() end
    
end
local function UpdateAddOn()
	local keep = {}
	if eVar ~= nil then
        keep = eVar.properties.keep
    end
	
	eSaithBagFilterResetButton_Click()
	eVar.properties.keep = keep 
	print(STRINGS.ADDON_UPDATED..tostring(eVar.properties.version))
end

local function UpdateMinAndMax(self, value)
    if self == nil or value == nil or eVar == nil then return end
    local _type = eVar.properties.types[eVar.properties.BottomTab]

    if self:GetName():find("Min") ~= nil then
        eVar[_type].min = value
    elseif self:GetName():find("Max") ~= nil then
        eVar[_type].max = value
    end
    SelectiLevelItems()
end

function eSaithBagFilter_OnEvent(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "eSaithBagFilter" then
        self:UnregisterEvent("ADDON_LOADED")
        eVar = eSaithBagFilterVar or nil
        -- Check if an older version. If so do a soft reset
        local version = GetAddOnMetadata("eSaithBagFilter", "Version")    
        if eVar ~= nil and tostring(eVar.properties.version) ~= tostring(version) then    
            UpdateAddon()
        else
            CreateRarityObjects()
        end
        
        CreateCheckButtons()
        CreateSliders()
        eSaithBagFilter_ShowFilterZone()
        tinsert(UISpecialFrames, eSaithBagFilter:GetName())
        OriginalToolTip = GameTooltip:GetScript("OnTooltipSetItem")
        GameTooltip:SetScript("OnTooltipSetItem", ReadToolTip)
    elseif event == "CHAT_MSG_LOOT" and arg1 ~= nil then
        if string.find(arg1, "You receive item: ") ~= nil or
            string.find(arg1, "You receive loot: ") ~= nil or
            string.find(arg1, "Received item: ") ~= nil then

            local bulk = string.match(arg1, ".*: (.+)%.")
            local dItemID = (string.find(bulk, "%]x(%d+)") ~= nil and string.match(bulk, "(.*)x(%d+)")) or bulk
            
            local _, dItemLink, quality, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(dItemID)
            if vendorPrice ~= nil and vendorPrice > 0 then
                AddLoot(dItemLink, quality)
            end
        end
    elseif event == "MERCHANT_SHOW" then
        if eVar.properties.autoSellGrays then SellByQuality("Poor") end
        if eVar.properties.LeftTab < 4 then
            eSaithBagFilterSellButton:Show()
        end    
    elseif event == "MERCHANT_CLOSED" then
        eSaithBagFilterSellButton:Hide()
    elseif event == "UPDATE_INSTANCE_INFO" then
        ParseRaidInfo()
    elseif event == "PLAYER_LOGOUT" then
        eSaithBagFilterVar = eVar  
        eSaithBagFilterInstances = eInstances
    elseif event == "START_LOOT_ROLL" then
        StartLootRollID = arg1
    elseif event == "LOOT_ITEM_AVAILABLE" and StartLootRollID ~= nil then
        local item = arg1       
        local _, _, quality = GetItemInfo(item)
        if quality + 1 == 3 and eVar.properties.AutoGreedGreenItems then   -- Quality 3 is Uncommon (green items) 
            if GroupLootContainer:IsShown() then
                RollOnLoot(StartLootRollID , 2);
            end
        end
        StartLootRollID = nil
    end
end

function eSaithBagFilter_OnLoad(self, event, ...)
    self:RegisterForDrag("LeftButton")
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("CHAT_MSG_LOOT")
    self:RegisterEvent("MERCHANT_SHOW")
    self:RegisterEvent("MERCHANT_CLOSED")
    self:RegisterEvent("UPDATE_INSTANCE_INFO")
    self:RegisterEvent("PLAYER_LOGOUT")
    self:RegisterEvent("START_LOOT_ROLL")
    self:RegisterEvent("LOOT_ITEM_AVAILABLE") 
end
function eSaithBagFilter_OnShow()
    if eVar.properties.LeftTab == nil then
        eVar.properties.LeftTab = 1
    end

    -- Update the filtering pages when viewing AddOn again as loot item buttons will  be stale
    if eVar.properties.LeftTab == 1 then
        SelectZoneItems()
    elseif eVar.properties.LeftTab == 2 then
        SelectiLevelItems()
    elseif eVar.properties.LeftTab == 3 then
        SelectRarityItems()
    end

    eSaithBagFilterSideTabs_OnClick(_G["eSaithBagFilterSideTabsTab" .. eVar.properties.LeftTab])
end
function eSaithBagFilter_OnStopDrag(self, event, ...)
    self:StopMovingOrSizing()
end

function eSaithBagFilterSellButton_Click(self, event, ...)
    local texture, locked, quality, lootable, link, ilevel, class, zoneTable, personalItem, _type
    if eVar.properties.sell == nil then eVar.properties.sell = { } end

    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            texture, _, locked, quality, _, lootable, link = GetContainerItemInfo(bag, slot)            
            if texture then               
                _, _, _, ilevel, _, class, _, _, _, _, vendorPrice = GetItemInfo(link)
                personalItem = eVar.properties.keep[link] or eVar.properties.keepTradeGoods[link]
                if (personalItem == nil or not personalItem) and not (locked or lootable) and vendorPrice > 0  then      
                     _type = eVar.properties.types[quality + 1]             
                    if eVar.properties.LeftTab == 1 and eInstanceLoot[eVar.properties.zone] ~= nil then
                        zoneTable = eInstanceLoot[eVar.properties.zone]
                        if zoneTable[link] then
                            if eVar.properties.sell[link] == nil then eVar.properties.sell[link] = true end                            
                        end     
                    elseif _type ~= nil and _G["eSaithBagFilterCheckButton" .. _type]:GetChecked() then      
                        if eVar.properties.LeftTab == 2 and                    
                        PassMin(ilevel, eVar[_type].min, eVar[_type].minChecked) and 
                        PassMax(ilevel, eVar[_type].max, eVar[_type].maxChecked) then
                            if eVar.properties.sell[link] == nil then 
                                eVar.properties.sell[link] = true 
                            end                        
                        elseif eVar.properties.LeftTab == 3 then           
                            if eVar.properties.sell[link] == nil then 
                                eVar.properties.sell[link] = true 
                            end 
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

    -- Update for mass auto selling
    if eVar.properties.update and self.TimeSinceLastUpdate > eVar.properties.updateInterval then
        self.TimeSinceLastUpdate = 0
        eVar.properties.maxTime = eVar.properties.maxTime + 1

        if SellListedItems() == 0 then
            eVar.properties.update = false
        end

        if eVar.properties.maxTime > 60 or eVar.properties.update == false then
            eVar.properties.maxTime = 0
            eVar.properties.update = false
            eVar.properties.sell = { }
            UpdateZoneTable(eVar.properties.zone)

            if eVar.properties.LeftTab == 1 then
                SelectZoneItems()
            elseif eVar.properties.LeftTab == 2 then
                SelectiLevelItems()
            elseif eVar.properties.LeftTab == 3 then
                SelectRarityItems()
            end
        end
    end

    -- Update for auto gray loot selling
    eVar.properties.autoloot = false
    if eVar.properties.autoloot and self.TimeSinceLastUpdate > eVar.properties.updateInterval + 3 then
        self.TimeSinceLastUpdate = 0
        LootContainers();
    end

end
function eSaithBagFilterSellButton_OnHide(self, event, ...)
    eVar.properties.update = false
end
function eSaithBagFilterILVLBottomTabs_OnLoad(self, event, ...)
    PanelTemplates_SetNumTabs(self, 5)
    PanelTemplates_SetTab(eSaithBagFilterILVLBottomTabs, 1)
end
function eSaithBagFilterILVLBottomTabs_OnShow(self, event, ...)
    if eVar == nil then eVar = { BottomTab = 1 } end
    PanelTemplates_SetTab(eSaithBagFilterILVLBottomTabs, eVar.properties.BottomTab)
end

function eSaithBagFilterSideTabs_OnClick(self, button)
    PlaySound("igAbiliityPageTurn")
    local tab = self:GetName():match("eSaithBagFilterSideTabs(.*)")

    for i = 1, 5 do
        _G["eSaithBagFilterSideTabsTab" .. i]:SetAlpha(.5)
    end
    _G["eSaithBagFilterSideTabs" .. tab]:SetAlpha(1)
end
function eSaithBagFilterResetButton_Click(self, event)
    eVar = nil
    eInstanceLoot = nil
    eInstances = nil
    CreateRarityObjects()       
end

function eSaithBagFilterSlider_CheckBoxClick(self, button, down)
    local btn = self:GetParent():GetName() .. "CheckButton"
    local _type = eVar.properties.types[eVar.properties.BottomTab]

    if string.find(self:GetName(), "Min") ~= nil then
        eVar[_type].minChecked = self:GetChecked()
    elseif string.find(self:GetName(), "Max") ~= nil then
        eVar[_type].maxChecked = self:GetChecked()
    end
    SelectiLevelItems()
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
    if eVar[_type] ~= nil then
        eVar[_type].checked = self:GetChecked()
    end
    SelectRarityItems()
end
function eSaithBagFilterBottomTab_Click(self, event, ...)
    local parent = self:GetParent():GetName() .. "Tab"
    local col = eVar.properties.types[eVar.properties.BottomTab]
    _G["eSaithBagFilterCheckButton" .. col]:Hide()

    for index, _type in pairs(eVar.properties.types) do
        if (parent .. index == self:GetName()) then
            eVar.properties.BottomTab = index
            eSaithBagFilterSliderMinSlider:SetValue(eVar[_type].min)
            eSaithBagFilterSliderMaxSlider:SetValue(eVar[_type].max)
            eSaithBagFilterSliderMinCheckButton:SetChecked(eVar[_type].minChecked)
            eSaithBagFilterSliderMaxCheckButton:SetChecked(eVar[_type].maxChecked)
            _G["eSaithBagFilterCheckButton" .. _type]:Show()
            return
        end
    end
end

function eSaithBagFilter_ShowFilterZone(self, event)
    PrepareToShowSideTabs()
    eVar.properties.LeftTab = 1
    SelectZoneItems()
    eSaithBagFilterDropDown:Show()    
    if MerchantFrame:IsShown() then
        eSaithBagFilterSellButton:Show()
    end

end
function eSaithBagFilter_ShowFilteriLVL(self, event)
    PrepareToShowSideTabs()
    local _type

    -- Verify checkboxes are aligned correctly - mostly if coming from zone tab
    local point, relativeTo, relativePoint, xOffset, yOffset = eSaithBagFilterCheckButtonPoor:GetPoint("TOPLEFT")    
    for index, _type in pairs(eVar.properties.types) do
        _G["eSaithBagFilterCheckButton" .. _type]:ClearAllPoints()
        _G["eSaithBagFilterCheckButton" .. _type]:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    end

    eVar.properties.LeftTab = 2
    if eVar.properties.BottomTab == nil then eVar.properties.BottomTab = 1 end

    _type = eVar.properties.types[eVar.properties.BottomTab]
    eSaithBagFilterILVLBottomTabs:Show()
    _G["eSaithBagFilterCheckButton" .. _type]:SetChecked(eVar[_type].checked)
    _G["eSaithBagFilterCheckButton" .. _type]:Show()
    eSaithBagFilterSliderMinSlider:SetValue(eVar[_type].min)
    eSaithBagFilterSliderMin:Show()
    eSaithBagFilterSliderMaxSlider:SetValue(eVar[_type].max)
    eSaithBagFilterSliderMax:Show()
    SelectiLevelItems()
    if MerchantFrame:IsShown() then
        eSaithBagFilterSellButton:Show()
    end
end
function eSaithBagFilter_ShowFilterRarity(self, event)
    PrepareToShowSideTabs()
    eVar.properties.LeftTab = 3

    local point, relativeTo, relativePoint, xOffset, yOffset = eSaithBagFilterCheckButtonPoor:GetPoint("TOPLEFT")
    local count = 0
    for index, _type in pairs(eVar.properties.types) do
        if eVar[_type] ~= nil then
            _G["eSaithBagFilterCheckButton" .. _type]:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
            _G["eSaithBagFilterCheckButton" .. _type]:SetChecked(eVar[_type].checked)
            _G["eSaithBagFilterCheckButton" .. _type]:Show()
            yOffset = yOffset - 30
        end
        count = count + 1
        if count >= 5 then break end
    end
    SelectRarityItems()
    if MerchantFrame:IsShown() then
        eSaithBagFilterSellButton:Show()
    end
end
function eSaithBagFilter_ShowCharacterInfo(self, event)
    if eVar.properties.LeftTab ~= 4 then
        RequestRaidInfo()
        PrepareToShowSideTabs()
        eSaithBagFilterSellButton:Hide()
    end

    eVar.properties.LeftTab = 4
    eSaithBagFilterDropDown:Show()
    eSaithBagFilterSellButton:Hide()
end
function eSaithBagFilter_ShowOptions(self, event)
    PrepareToShowSideTabs()
    eSaithBagFilterSellButton:Hide()
    eVar.properties.LeftTab = 5

    eSaithBagFilterOptions_Coordinates:GetChecked(eVar.properties.coordsOn)
    eSaithBagFilterOptions_AutoSellGray:GetChecked(eVar.properties.auto)
    eSaithBagFilterOptions_BOEGreenItems:GetChecked(eVar.properties.BOEGreen)
    eSaithBagFilterOptions_AutoGreedGreen:GetChecked(eVar.properties.AutoGreedGreenItems)
	eSaithBagFilterCheckButton_TradeGoods:GetChecked(eVar.properties.IsTradeGoodKept)
	
    eSaithBagFilterOptions_Coordinates:Show()
    eSaithBagFilterOptions_AutoSellGray:Show()
    eSaithBagFilterOptions_BOEGreenItems:Show()
    eSaithBagFilterOptions_AutoGreedGreen:Show()
	eSaithBagFilterCheckButton_TradeGoods:Show()

    eSaithBagFilterResetButton:Show()
    eSaithBagFilterLootButton:Show()
end

local function PlayerInfoItemFunction(self, arg1, arg2, checked)
    local time = time()
    local realm = GetRealmName()
    local CurrentPlayersName = UnitName("player")
    local SavedText = ""
    local CleanText = ""
    local instance = eInstances[self.arg1]
    local count = 0

    for PlayerServerName, playerInfo in pairs(eInstances.players) do
        local charName
        if CurrentPlayersName == playerInfo.name and realm == playerInfo.server then 
            charName = playerInfo.name 
        else
            charName = PlayerServerName
        end

        if instance[PlayerServerName] ~= nil and instance[PlayerServerName].time > time then
            if charName == CurrentPlayersName then
                SavedText = SavedText .. "\n|cffFFAA33---> |cff96bdc4" .. charName .. "|cffFAAE33 <---"
            else
                SavedText = SavedText .. "\n|cff96bdc4" .. charName
            end
        else
            if charName == CurrentPlayersName then
                CleanText = CleanText .. "\n|cffFAAE33---> |cff96bdc4" .. charName .. "|cffFAAE33 <---"
            else
                CleanText = CleanText .. "\n|cffffffff" .. charName
            end
        end
        count = count + 1
    end

    -- Font strings for character instance info
    local fontstring = eSaithBagFilterInstanceInfoFontStringFreshTitle
    fontstring:SetFont("Fonts\\FRIZQT__.TTF", 25, "OUTLINE, THICKOUTLINE")
    fontstring:SetPoint("TOP", "$parent", "TOP", 0, -70)    
    fontstring:SetText("|cffbdf3ff Fresh Instance")
    fontstring:SetWidth(250)    
    fontstring:Show()

    fontstring = eSaithBagFilterInstanceInfoFontStringFreshList
    fontstring:SetPoint("TOP", eSaithBagFilterInstanceInfoFontStringFreshTitle, "BOTTOM", 0, 7)
    fontstring:SetFont("Fonts\\FRIZQT__.TTF", 13)
    fontstring:SetText(CleanText)
    fontstring:SetWidth(250)    
    fontstring:Show()

    fontstring = eSaithBagFilterInstanceInfoFontStringSavedTitle
    fontstring:SetPoint("TOP", eSaithBagFilterInstanceInfoFontStringFreshList, "BOTTOM", 0, -34)
    fontstring:SetFont("Fonts\\FRIZQT__.TTF", 23, "OUTLINE, THICKOUTLINE")
    fontstring:SetText("|cff719096 Saved Instance")
    fontstring:SetWidth(250)
    fontstring:Show()

    fontstring = eSaithBagFilterInstanceInfoFontStringSavedList
    fontstring:SetPoint("TOP", eSaithBagFilterInstanceInfoFontStringSavedTitle, "BOTTOM", 0, 7)
    fontstring:SetFont("Fonts\\FRIZQT__.TTF", 13)
    fontstring:SetText(SavedText)    
    fontstring:SetWidth(250)
    fontstring:Show()    

    if (not checked) then
        UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
    end

    if count > 15 then
        local extend = ((count - 15) / 100) * 5 + 1.0
        eSaithBagFilter:SetHeight(eSaithBagFilter:GetHeight() * extend + 300)
    end
end

function CreatePlayerInfoDropDownList()
    local i = 1;
    for instance, TableOfNames in pairs(eInstances) do        
        if TableOfNames ~= nil and instance ~= "boe" and instance ~= 'players' then
            info = UIDropDownMenu_CreateInfo();
            info.text = tostring(instance)
            info.arg1 = tostring(instance)
            info.value = i;
            info.func = PlayerInfoItemFunction;
            UIDropDownMenu_AddButton(info);
            i = i + 1;
        end
    end
end
function eSaithBagFilter_CreateDropDownList()
    if eVar == nil then return end
    if eVar.properties.LeftTab == 1 then
        CreateZoneDropDownList()
    elseif eVar.properties.LeftTab == 4 then
        CreatePlayerInfoDropDownList()
    end
end
function eSaithBagFilterOptions_OnLoad()
    PrepareToShowSideTabs()
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
        eSaithBagFilterResetButton_Click()
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

-- ReOrg Saved Instances 
    -- Make instances alphabetical
    -- Allow player to add/remove desired saved instances
    -- Allow option to choose miniumum required raid level (ie, no need to show lvl 80s when you only want to show level 100s)

-- Replace strings with local global string
-- consider making all loot item buttons local globals
-- Instead of showing multiples of the same loot, count and condense with # showing how many
-- If an item does not have an item level, then assume it is one or zero. 
-- Consider if all the frames that are created are really necessary? ie, frame.._type. If they will be rerasterized over and over again, may as well use the same frame
-- Consider adding transparency button if mouse is not over AddOn
-- consider sorting by ilevel
-- Add a "Never sell list" so that items never show up on list. Allow the list to be modified
--]]

--[[
  Updates:   
    -- Updated global variable to use local variables for easy writing and shorter lines of code.  
    -- Added Auto greed on green items 
	-- Included background colors to selected filtered items to more easily distinquish which levels are which rarities
	-- Increased the base height of the addon so that it doesn't jump as much when 
	-- Moved the Do Not Sell Trade Goods to the options page. Now all filtering pages have that option.
		-- When checkbox is marked all trade goods are added to a secondary saved list and become transparent like the normal trade goods. If Trade Goods becomes unmarked then all items will lose their transparency unless they are saved by the manual toggle (normal kept list)
	-- When Reset now does not reload the game. 
	-- Included items that don't have 'bind on pickup', 'bind on pick up', or 'soulbound' in the item description. This should help with other items such as patterns 
	
]]--



--[[


]]--