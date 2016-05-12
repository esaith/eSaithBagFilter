SLASH_ESAITHBAGFILTER1 = '/efilter'
local MaxItemCount = -1
local zone -- used for updating world coordinates
local OriginalToolTip  -- used to save original functionality to the tooltip. Used for hooking a function
local MAX_BAG_SLOTS = 200    

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
    if boundText:find(".* when equip.*") or boundText:find(".*on equip*") or boundText:find(".* account.*")  
            --or not (boundText:find(".* on picked.*") or boundText:find(".*Soulbound.*")) 
            then
        local _, link = GameTooltip:GetItem() 
        eSaithBagFilterInstances.boe[link] = true
    end
    return OriginalToolTip(self, ...)
end
local function ResetAlphaOnAllButtons()
    for index = 1, MaxItemCount do
        local btn = _G["eSaithBagFilterSellItem" .. index]
        if _G["eSaithBagFilterSellItem" .. index] and _G["eSaithBagFilterSellItem" .. index]:IsShown() then
            if eSaithBagFilterVar.properties.keep[_G["eSaithBagFilterSellItem" .. index].link] then
                _G["eSaithBagFilterSellItem" .. index]:SetAlpha(.3)
            else
                _G["eSaithBagFilterSellItem" .. index]:SetAlpha(1)
            end
        end
    end
end
local function AddLoot(obj, quality)
    local zone = GetRealZoneText()
    if eSaithBagFilterInstanceLoot[zone] == nil then eSaithBagFilterInstanceLoot[zone] = { } end
    eSaithBagFilterInstanceLoot[zone][obj] = true    
    GameTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    GameTooltip:SetHyperlink(obj)    
    GameTooltip:Show()   
    GameTooltip:Hide()    
end
local function SetIncludedBOEItems()
    eSaithBagFilterVar.properties.BOEGreen = eSaithBagFilterOptions_BOEGreenItems:GetChecked()
end

local function ItemButton_OnPress(self, event, button)
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
local function ItemButton_OnEnter(self, motion)
    PrepreToolTip(self)
    GameTooltip:SetHyperlink(self.link)
    GameTooltip:Show()
end
function eSaithBagFilterSellButton_OnEnter(self, event, ...)
    PrepreToolTip(self)
    GameTooltip:AddLine("Sell")
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
    end
    if MerchantFrame:IsShown() and (eSaithBagFilterVar.properties.LeftTab == 1 or
                eSaithBagFilterVar.properties.LeftTab == 2 or eSaithBagFilterVar.properties.LeftTab == 3) then
        eSaithBagFilterSellButton:Show()
    end
end
function eSaithBagFilterOpenFrame_OnEnter(self, motion)
    PrepreToolTip(self)
    GameTooltip:AddLine("Open ESaith Item Filter")
    GameTooltip:Show()
end
function eSaithBagFilterTab_OnEnter(self, motion)
    local array = { "Filter By Zone", "Filter By iLvl", "Filter By Rarity", "Characters Log", "Options Tab" }
    PrepreToolTip(self)
    self:GetID()
    GameTooltip:AddLine(array[self:GetID()])
    GameTooltip:Show()
end

local function UpdateCoordinates(self, elapsed)
    if not eSaithBagFilterVar.properties.coordsOn then return end
    if zone ~= GetRealZoneText() then
        zone = GetRealZoneText()
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
    eSaithBagFilterVar.properties.coordsOn = eSaithBagFilterOptions_Coordinates:GetChecked()
    if eSaithBagFilterOptions_Coordinates:GetChecked() then
        eSaithBagFilterCoordinates:Show()
    else
        eSaithBagFilterCoordinates:Hide()
    end
end

local function LootContainers()
    eSaithBagFilterVar.properties.autoloot = true
    print("|cffff0000To use this functionality, you -must- make sure your Auto Loot is enabled")
    print("|cffffaa00To enable, open your Interface > Controls > Auto Loot is checked. Sorry for this inconvenience. Thank you")

    if MerchantFrame:IsShown() then
        print("|cffffff00Sorry to be rude but to loot you mustn't be talking to a merchant. Thank you.")
        MerchantFrame:Hide()
        eSaithBagFilter:Show()
    end

    local count = 0
    local leftOver = 0
    local found = false
    for bag = 0, 4 do
        count = count + GetContainerNumFreeSlots(bag)
    end

    for bag = 0, NUM_BAG_SLOTS do
        if not found then
            for slot = 1, GetContainerNumSlots(bag) do
                local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
                if texture and lootable then
                    if not locked and count > 0 then
                        UseContainerItem(bag, slot, false)
                        found = true
                    else
                        leftOver = leftOver + 1
                    end
                end
            end
        end
    end

    if leftOver <= 0 then
        eSaithBagFilterVar.properties.autoloot = false
    end
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
local function AutoSellGrayCheckButton_OnClick()
    eSaithBagFilterVar.properties.autoSellGrays = eSaithBagFilterOptions_AutoSellGray:GetChecked()
end
local function SellByQuality(_type)
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
            if texture then
                local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link)
                local personalItem = eSaithBagFilterVar.properties.keep[link]
                if (personalItem == nil or not personalItem) and not locked and not lootable and vendorPrice > 0 and quality < 5 then
                    if eSaithBagFilterVar.properties.types[quality + 1] == _type then
                        if eSaithBagFilterVar.properties.sell[link] == nil then eSaithBagFilterVar.properties.sell[link] = { } end
                        eSaithBagFilterVar.properties.sell[link] = true
                    end
                end
            end
        end
    end
    SellListedItems()
end

local function CreateCheckButtons()
    local width = eSaithBagFilter:GetWidth()
    local fontstring, btn
    for index, _type in ipairs(eSaithBagFilterVar.properties.types) do
        btn = CreateFrame("CheckButton", "$parentCheckButton" .. _type, eSaithBagFilter, "UICheckButtonTemplate")
        btn:SetPoint("TOP", "$parent", "TOP", - math.floor(width / 5), -30)
        btn:SetScript("OnClick", eSaithBagFilterCheckBox_Click)
        fontstring = btn:CreateFontString("eSaithBagFilterCheckButton" .. _type .. "FontString", "ARTWORK", "GameFontNormal")
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

    -- Do Not Sell label
    local fontstring = eSaithBagFilter:CreateFontString("$parentDoNotSellFontString", "ARTWORK", "GameFontNormal")
    fontstring:SetText("|cffff0000Do Not Sell:")
    fontstring:SetPoint("CENTER", "$parent", "TOP", 0, -87)
    fontstring:Show()

    -- Do not sell trade goods
    local btn = CreateFrame("CheckButton", "eSaithBagFilterCheckButton_TradeGoods", eSaithBagFilter, "UICheckButtonTemplate")
    btn:SetPoint("TOP", "$parent", "TOP", -50, -90)
    local fontstring = btn:CreateFontString("eSaithBagFilterCheckButtonTradeGoodsFontString", "ARTWORK", "GameFontNormal")
    fontstring:SetText("Trade Goods")
    fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
    btn:SetFontString(fontstring)
    btn:Show()



    -- Create all widgets that could possibly sell
    for i = 1, MAX_BAG_SLOTS do
        local btn = CreateFrame("Button", "eSaithBagFilterSellItem" .. i, eSaithBagFilter, "eSaithBagFilterItemButtonTemplate")
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
    

    local fontstring  
    -- Just create the fontstring. They will be used later on 
    eSaithBagFilter:CreateFontString("$parentInstanceInfoFontStringFreshTitle", "ARTWORK", "GameFontNormal")
    eSaithBagFilter:CreateFontString("$parentInstanceInfoFontStringFreshList", "ARTWORK", "GameFontNormal")
    eSaithBagFilter:CreateFontString("$parentInstanceInfoFontStringSavedTitle", "ARTWORK", "GameFontNormal")
    eSaithBagFilter:CreateFontString("$parentInstanceInfoFontStringSavedList", "ARTWORK", "GameFontNormal")
    

    -- Coordinates
    local coords = CreateFrame("Frame", "eSaithBagFilterCoordinates", UIParent)
    coords:SetSize(100, 50)
    coords:SetPoint("TOP", "Minimap", "BOTTOM", 5, -5)
    coords:SetScript("OnUpdate", UpdateCoordinates)
    local coordsFont = coords:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
    coordsFont:SetText("|cff33ff33")
    coordsFont:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
    coordsFont:Show()
    coords:Show()

    -- Option Buttons
    btn = CreateFrame("CheckButton", "$parentOptions_Coordinates", eSaithBagFilter, "UICheckButtonTemplate")
    btn:SetPoint("TOP", "$parent", "TOP", -125, -25)
    btn:SetScript("OnClick", CoordinatesCheckButton_OnClick)
    fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
    fontstring:SetText("Turn On Coordinates (Located Under Mini-Map)")
    fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
    btn:SetFontString(fontstring)
    btn:SetChecked(eSaithBagFilterVar.properties.coordsOn)
    if eSaithBagFilterVar.properties.coordsOn then
        coords:Show()
    end

    -- Auto Sell Gray items checkbox
    btn = CreateFrame("CheckButton", "$parentOptions_AutoSellGray", eSaithBagFilter, "UICheckButtonTemplate")
    btn:SetPoint("TOP", "$parent", "TOP", -125, -50)
    btn:SetScript("OnClick", AutoSellGrayCheckButton_OnClick)
    fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
    fontstring:SetText("Auto Sell Gray Items")
    fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
    btn:SetFontString(fontstring)
    btn:Show()
    if eSaithBagFilterVar.properties.autoSellGrays then
        btn:SetChecked(true)
    end

    -- BOE green items (Does user want to include these as well)
    btn = CreateFrame("CheckButton", "$parentOptions_BOEGreenItems", eSaithBagFilter, "UICheckButtonTemplate")
    btn:SetPoint("TOP", "$parent", "TOP", -125, -75)
    btn:SetScript("OnClick", SetIncludedBOEItems)
    fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
    fontstring:SetText("Include BOE Green Items")
    fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
    btn:SetFontString(fontstring)
    btn:Show()
    if eSaithBagFilterVar.properties.BOEGreen then
        btn:SetChecked(true)
    end

    -- Auto loot containers
    local lootItemBtn = CreateFrame("Button", "$parentLootButton", eSaithBagFilter, "UIPanelButtonTemplate")
    lootItemBtn:SetSize(125, 30)
    lootItemBtn:SetPoint("TOP", "$parent", "TOP", -15, -110)
    lootItemBtn:SetScript("OnClick", LootContainers)
    local lootFont = lootItemBtn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
    lootFont:SetText("|cffffffffLoot Containers")
    lootFont:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
    lootFont:Show()
    lootItemBtn:Show()

    -- BOE font string
    local fontstring = eSaithBagFilter:CreateFontString("$parentBOEFontString", "ARTWORK", "GameFontNormal")
    fontstring:SetText("|cffff0000Bind On Equip Items:")
end
local function CreateRarityObjects()
    eSaithBagFilterInstanceLoot = eSaithBagFilterInstanceLoot or { }
    eSaithBagFilterInstances = eSaithBagFilterInstances or 
    {   
        players = { }, 
        boe = { } 
    }

    if eSaithBagFilterVar == nil then
        eSaithBagFilterVar = {
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
                updateCount = 0,
                itemUpdateCount = 0,
                updateInterval = 0.5,
                maxTime = 0,
                keep = { },
                sell = { },
                coordsOn = false,
                autoloot = false,
                autoSellGrays = false,
                version = 1.3,
                boe = { },
                BOEGreen = false
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
    -- Any gear the character is current wearing when logging in should be immediately put in kept list each time the character logs in
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
    --            eSaithBagFilterVar.properties.keep[link] = true
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

local function CreateItemButton(item, index, xoffset, yoffset, currentPositionThisRow, typesIncluded)
    local btn = _G["eSaithBagFilterSellItem" .. index]
    btn:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 41 * xoffset + 20, -200 - yoffset * 45)
    btn.texture = _G[btn:GetName() .. "Texture"]
    btn.texture:Show()
    btn.texture:SetTexture(item.text)
    btn.texture = _G[btn:GetName() .. "TextureBorder"]
    btn.texture:Show()
    btn.texture:SetTexture(eSaithBagFilterVar.properties.texture[3 * item.colorIndex], eSaithBagFilterVar.properties.texture[3 * item.colorIndex + 1], eSaithBagFilterVar.properties.texture[3 * item.colorIndex + 2], 1)
    btn:Show()
    btn.link = item.link

end
local function ShowListedItems(count)
    -- Hide old items prior to showing updated list
    for i = 1, MaxItemCount do
        _G["eSaithBagFilterSellItem" .. i]:Hide()
    end

    if eSaithBagFilterVar.properties.sell == nil then return end

    local MAX_ROW = 11
    local yoffset = 0
    local xoffset = 0
    local list = eSaithBagFilterVar.properties.sell
    local currentPositionThisRow = 1
    local typesIncluded = { }
    local boe = nil
    local ButtonIndex = 0

    for _index, color in pairs(eSaithBagFilterVar.properties.colors) do
        for index = 1, count do
            if list[index].colorIndex == _index then
                if currentPositionThisRow % MAX_ROW == 0 then
                    yoffset = yoffset + 1
                    xoffset = 0
                    currentPositionThisRow = 1
                end

                if eSaithBagFilterInstances.boe[list[index].link] and 
                        (list[index].colorIndex > 3  or (eSaithBagFilterVar.properties.BOEGreen and list[index].colorIndex > 2)) then
                    if boe == nil then boe = { } end
                    boe[list[index].link] = list[index]
                else
                    ButtonIndex = ButtonIndex + 1
                    CreateItemButton(list[index], ButtonIndex, xoffset, yoffset, currentPositionThisRow, typesIncluded)
                    xoffset = xoffset + 1
                    currentPositionThisRow = currentPositionThisRow + 1
                    typesIncluded[list[index].colorIndex] = true;
                end
            end
        end
        if typesIncluded[_index] ~= nil then
            yoffset = yoffset + 1
            -- each new color will be on its own row
            -- but only if that color was seen
            currentPositionThisRow = 1
        end
        xoffset = 0
    end

    -- Append BOE items at the end
    local AnyBoE = 0
    if boe ~= nil then
        AnyBoE = 1
        yoffset = yoffset + 1
        local fontstring = eSaithBagFilterBOEFontString
        fontstring:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 41 * xoffset + 20, -180 - yoffset * 45)
        fontstring:Show()
        for item, content in pairs(boe) do
            if currentPositionThisRow % MAX_ROW == 0 then
                yoffset = yoffset + 1
                xoffset = 0
                currentPositionThisRow = 1
            end
            ButtonIndex = ButtonIndex + 1
            CreateItemButton(content, ButtonIndex, xoffset, yoffset, currentPositionThisRow, typesIncluded)
            xoffset = xoffset + 1
            currentPositionThisRow = currentPositionThisRow + 1
            typesIncluded[content.colorIndex] = true;
        end
    else
        
        eSaithBagFilterBOEFontString:Hide()
    end

    if MaxItemCount > count then
        for i = count + 1, MaxItemCount do
            _G["eSaithBagFilterSellItem" .. i]:Hide()
        end
    end
    MaxItemCount = count

    local x = eSaithBagFilter:GetSize()

    if yoffset < 4 then yoffset = 4 end
    eSaithBagFilter:SetSize(x, 200 + yoffset * 45 + AnyBoE * 50)
end

local function SelectZoneItems()
    local zone = eSaithBagFilterVar.properties.zone
    if eSaithBagFilterInstanceLoot[zone] == nil then return end
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
                    eSaithBagFilterVar.properties.sell[count] = { link = link, text = texture, colorIndex = quality + 1, itemName = itemName }
                end
            end
        end
    end
    ShowListedItems(count)
    ResetAlphaOnAllButtons()
end
local function SelectiLvlItems()
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
                    if _type ~= nil and _G["eSaithBagFilterCheckButton" .. _type]:GetChecked()
                        and PassMin(ilvl, eSaithBagFilterVar[_type].min, eSaithBagFilterVar[_type].minChecked)
                        and PassMax(ilvl, eSaithBagFilterVar[_type].max, eSaithBagFilterVar[_type].maxChecked) then
                        count = count + 1
                        eSaithBagFilterVar.properties.sell[count] = { link = link, text = texture, colorIndex = quality + 1, itemName = itemName }
                    end
                end
            end
        end
    end
    ShowListedItems(count)
    ResetAlphaOnAllButtons()
end
local function SelectRarityItems()
    eSaithBagFilterVar.properties.sell = { }

    local count = 0
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
            if texture then
                local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link)
                local _type = eSaithBagFilterVar.properties.types[quality + 1]
                if _type ~= nil and _G["eSaithBagFilterCheckButton" .. _type]:GetChecked() and vendorPrice > 0 and not lootable then
                    count = count + 1
                    eSaithBagFilterVar.properties.sell[count] = { link = link, text = texture, colorIndex = quality + 1, itemName = itemName }
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
    SelectZoneItems()
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

local function GetRarity(ilvl)
    return eSaithBagFilterVar.properties.types[ilvl]
end  
local function ParseRaidInfo() 
    -- Don't save any character lower than level 70.
    if UnitLevel("player") < 70 then return end

    -- Current Player Info
    local NumOfInstances = GetNumSavedInstances()
    local PlayerIndex = UnitName("player").." ("..GetRealmName()..")"
    if eSaithBagFilterInstances.players == nil then eSaithBagFilterInstances.players = {} end
    if eSaithBagFilterInstances.players[PlayerIndex] == nil then 
        eSaithBagFilterInstances.players[PlayerIndex] = { name = UnitName("player"), server = GetRealmName() }
    end    

    for i = 1, NumOfInstances do
        local iName, _, iReset, iDifficulty, _, _, _, _, _, iDifficultyName = GetSavedInstanceInfo(i)
        -- Remove 'the' from "The ..." in instance name, if applicable        
        if string.find(iName, 'The ') == 1 then 
            iName = string.sub(iName, 5)
        end        
        local instance = iName..' - '..iDifficultyName
        
        if eSaithBagFilterInstances[instance] == nil then eSaithBagFilterInstances[instance] = { } end
        if eSaithBagFilterInstances[instance][PlayerIndex] == nil then eSaithBagFilterInstances[instance][PlayerIndex] = { time = 0 } end
                
        if iReset > 0 then
            eSaithBagFilterInstances[instance][PlayerIndex].time = time() + iReset
        end        
    end
end
local function PrepareToShowSideTabs()
    -- TODO fix PrepareToShowSideTabs function. No need to do this entire thing

    eSaithBagFilterSellButton:Hide()
    eSaithBagFilterBOEFontString:Hide()
    -- Hide Zone tab
    eSaithBagFilterDropDown:Hide()
    eSaithBagFilterDoNotSellFontString:Hide()
    eSaithBagFilterCheckButton_TradeGoods:Hide()
    eSaithBagFilterLootButton:Hide()

    -- Hide Tab iLvl and Rarity tabs
    for index, _type in pairs(eSaithBagFilterVar.properties.types) do
        _G["eSaithBagFilterCheckButton" .. _type]:Hide()
    end

    eSaithBagFilterILVLBottomTabs:Hide()
    eSaithBagFilterSliderMin:Hide()
    eSaithBagFilterSliderMax:Hide()

    for i = 1, MAX_BAG_SLOTS do
        local btn = _G["eSaithBagFilterSellItem" .. i]
        btn:Hide();
    end

    -- Hide Character Raid tab
    eSaithBagFilterResetButton:Hide()

    eSaithBagFilter:SetSize(450, 400)
   
    if eSaithBagFilterInstanceInfoFontStringFreshTitle:IsShown() then eSaithBagFilterInstanceInfoFontStringFreshTitle:Hide() end
    if eSaithBagFilterInstanceInfoFontStringFreshList:IsShown() then eSaithBagFilterInstanceInfoFontStringFreshList:Hide() end
    if eSaithBagFilterInstanceInfoFontStringSavedTitle:IsShown() then eSaithBagFilterInstanceInfoFontStringSavedTitle:Hide() end
    if eSaithBagFilterInstanceInfoFontStringSavedList:IsShown() then eSaithBagFilterInstanceInfoFontStringSavedList:Hide() end

    -- Options Tab	
    if eSaithBagFilterOptions_Coordinates:IsShown() then eSaithBagFilterOptions_Coordinates:Hide() end
    if eSaithBagFilterOptions_AutoSellGray:IsShown() then eSaithBagFilterOptions_AutoSellGray:Hide() end
    if eSaithBagFilterOptions_BOEGreenItems:IsShown() then eSaithBagFilterOptions_BOEGreenItems:Hide() end

end

local function UpdateMinAndMax(self, value)
    if self == nil or value == nil or eSaithBagFilterVar == nil then return end
    local _type = eSaithBagFilterVar.properties.types[eSaithBagFilterVar.properties.BottomTab]

    if self:GetName():find("Min") ~= nil then
        eSaithBagFilterVar[_type].min = value
    elseif self:GetName():find("Max") ~= nil then
        eSaithBagFilterVar[_type].max = value
    end

    SelectiLvlItems()
end

function eSaithBagFilter_OnEvent(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "eSaithBagFilter" then
        self:UnregisterEvent("ADDON_LOADED")
        eSaithBagFilterVar = eSaithBagFilterVar or nil

        -- Check if an older version. If so do a soft reset
        local version = GetAddOnMetadata("eSaithBagFilter", "Version")
        if eSaithBagFilterVar ~= nil and tostring(eSaithBagFilterVar.properties.version) ~= tostring(version) then    
            eSaithBagFilterResetButton_Click()
            eSaithBagFilterVar.properties.version = version            
            print("|cffffff99eSaith Bag Filter has been updated. Thank you for sticking with me and good luck in all of your endeavors.")
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

            local bulk
            if string.find(arg1, "You receive item: ") ~= nil or string.find(arg1, "Received item: ") ~= nil then  -- TODO, consider rewrite
                bulk = string.match(arg1, ".* item: (.+)%.")
            else
                bulk = string.match(arg1, ".* loot: (.+)%.")
            end

            local dItemID

            if string.find(bulk, "%]x(%d+)") ~= nil then
                dItemID = string.match(bulk, "(.*)x(%d+)")
            else
                dItemID = bulk
            end

            local name, dItemLink, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(dItemID)
            if vendorPrice ~= nil and vendorPrice > 0 then
                AddLoot(dItemLink, quality)
            end
        end
    elseif event == "MERCHANT_SHOW" then
        if eSaithBagFilterVar.properties.autoSellGrays then SellByQuality("Poor") end
         if MerchantFrame:IsShown() and (eSaithBagFilterVar.properties.LeftTab == 1 or
                eSaithBagFilterVar.properties.LeftTab == 2 or eSaithBagFilterVar.properties.LeftTab == 3) then
        eSaithBagFilterSellButton:Show()
    end
    elseif event == "MERCHANT_CLOSED" then
        eSaithBagFilterSellButton:Hide()
    elseif event == "UPDATE_INSTANCE_INFO" then
        ParseRaidInfo()
        -- elseif event == "MODIFIER_STATE_CHANGED" then
        --    if (arg1 == "LSHIFT" or arg1 == "RSHIFT") and self.link ~= nil then
        --        PrepreToolTip(self)
        --        if arg2 == 1 then
        --            GameTooltip:SetHyperlinkCompareItem(self.link)
        --        else
        --            GameTooltip:SetHyperlink(self.link)
        --            GameTooltip:Hide()
        --        end
        --        GameTooltip:Show()
        --    end
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
    self:RegisterEvent("UPDATE_INSTANCE_INFO")
    -- self:RegisterEvent("MODIFIER_STATE_CHANGED")
end
function eSaithBagFilter_OnShow()
    if eSaithBagFilterVar.properties.LeftTab == nil then
        eSaithBagFilterVar.properties.LeftTab = 1
    end

    if eSaithBagFilterVar.properties.LeftTab == 1 then
        SelectZoneItems()
    elseif eSaithBagFilterVar.properties.LeftTab == 2 then
        SelectiLvlItems()
    elseif eSaithBagFilterVar.properties.LeftTab == 3 then
        SelectRarityItems()
    end

    eSaithBagFilterSideTabs_OnClick(_G["eSaithBagFilterSideTabsTab" .. eSaithBagFilterVar.properties.LeftTab])
end
function eSaithBagFilter_OnStopDrag(self, event, ...)
    self:StopMovingOrSizing()
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
                        if _type ~= nil and _G["eSaithBagFilterCheckButton" .. _type]:GetChecked()
                            and PassMin(ilvl, eSaithBagFilterVar[_type].min, eSaithBagFilterVar[_type].minChecked)
                            and PassMax(ilvl, eSaithBagFilterVar[_type].max, eSaithBagFilterVar[_type].maxChecked) then
                            if eSaithBagFilterVar.properties.sell[link] == nil then eSaithBagFilterVar.properties.sell[link] = { } end
                            eSaithBagFilterVar.properties.sell[link] = true
                        end
                    elseif eSaithBagFilterVar.properties.LeftTab == 3 then
                        local _type = eSaithBagFilterVar.properties.types[quality + 1]
                        if _type ~= nil and _G["eSaithBagFilterCheckButton" .. _type]:GetChecked() then
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

        if SellListedItems() == 0 then
            eSaithBagFilterVar.properties.update = false
        end

        if eSaithBagFilterVar.properties.maxTime > 60 or eSaithBagFilterVar.properties.update == false then
            eSaithBagFilterVar.properties.maxTime = 0
            eSaithBagFilterVar.properties.update = false
            eSaithBagFilterVar.properties.sell = { }
            UpdateZoneTable(eSaithBagFilterVar.properties.zone)

            if eSaithBagFilterVar.properties.LeftTab == 1 then
                SelectZoneItems()
            elseif eSaithBagFilterVar.properties.LeftTab == 2 then
                SelectiLvlItems()
            elseif eSaithBagFilterVar.properties.LeftTab == 3 then
                SelectRarityItems()
            end
        end
    end
    eSaithBagFilterVar.properties.autoloot = false
    if eSaithBagFilterVar.properties.autoloot and self.TimeSinceLastUpdate > eSaithBagFilterVar.properties.updateInterval + 3 then
        self.TimeSinceLastUpdate = 0
        LootContainers();
    end

end

function eSaithBagFilterILVLBottomTabs_OnLoad(self, event, ...)
    PanelTemplates_SetNumTabs(self, 5)
    PanelTemplates_SetTab(eSaithBagFilterILVLBottomTabs, 1)
end
function eSaithBagFilterILVLBottomTabs_OnShow(self, event, ...)
    if eSaithBagFilterVar == nil then eSaithBagFilterVar = { BottomTab = 1 } end
    PanelTemplates_SetTab(eSaithBagFilterILVLBottomTabs, eSaithBagFilterVar.properties.BottomTab)
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
    print("Resetting AddOn")
    local keep = {}

    if eSaithBagFilterVar ~= nil then
        keep = eSaithBagFilterVar.properties.keep
    end
     
    eSaithBagFilterVar = nil
    eSaithBagFilterInstanceLoot = nil
    eSaithBagFilterInstances = nil
    CreateRarityObjects()
    eSaithBagFilterVar.properties.keep = keep
    if self ~= nil then
        ReloadUI()
    end
end

function eSaithBagFilterSlider_CheckBoxClick(self, button, down)
    local btn = self:GetParent():GetName() .. "CheckButton"
    local _type = eSaithBagFilterVar.properties.types[eSaithBagFilterVar.properties.BottomTab]

    if string.find(self:GetName(), "Min") ~= nil then
        eSaithBagFilterVar[_type].minChecked = self:GetChecked()
    elseif string.find(self:GetName(), "Max") ~= nil then
        eSaithBagFilterVar[_type].maxChecked = self:GetChecked()
    end
    SelectiLvlItems()
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
    SelectRarityItems()
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

function eSaithBagFilter_ShowFilterZone(self, event)
    PrepareToShowSideTabs()
    eSaithBagFilterVar.properties.LeftTab = 1
    SelectZoneItems()
    eSaithBagFilterDropDown:Show()
    eSaithBagFilterCheckButton_TradeGoods:Show()
    eSaithBagFilterDoNotSellFontString:Show()
    if MerchantFrame:IsShown() then
        eSaithBagFilterSellButton:Show()
    end

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
    eSaithBagFilterILVLBottomTabs:Show()
    _G["eSaithBagFilterCheckButton" .. _type]:SetChecked(eSaithBagFilterVar[_type].checked)
    _G["eSaithBagFilterCheckButton" .. _type]:Show()
    eSaithBagFilterSliderMinSlider:SetValue(eSaithBagFilterVar[_type].min)
    eSaithBagFilterSliderMin:Show()
    eSaithBagFilterSliderMaxSlider:SetValue(eSaithBagFilterVar[_type].max)
    eSaithBagFilterSliderMax:Show()
    SelectiLvlItems()
    if MerchantFrame:IsShown() then
        eSaithBagFilterSellButton:Show()
    end
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
    SelectRarityItems()
    if MerchantFrame:IsShown() then
        eSaithBagFilterSellButton:Show()
    end
end
function eSaithBagFilter_ShowCharacterInfo(self, event)
    if eSaithBagFilterVar.properties.LeftTab ~= 4 then
        RequestRaidInfo()
        PrepareToShowSideTabs()
        eSaithBagFilterSellButton:Hide()
    end

    eSaithBagFilterVar.properties.LeftTab = 4
    eSaithBagFilterDropDown:Show()
    eSaithBagFilterSellButton:Hide()

end
function eSaithBagFilter_ShowOptions(self, event)
    PrepareToShowSideTabs()
    eSaithBagFilterSellButton:Hide()
    eSaithBagFilterVar.properties.LeftTab = 5
    eSaithBagFilterOptions_Coordinates:Show()
    eSaithBagFilterOptions_Coordinates.checked = eSaithBagFilterVar.properties.coordsOn
    eSaithBagFilterResetButton:Show()
    eSaithBagFilterOptions_AutoSellGray:Show()
    eSaithBagFilterOptions_AutoSellGray.checked = eSaithBagFilterVar.properties.auto
    eSaithBagFilterLootButton:Show()
    eSaithBagFilterOptions_BOEGreenItems:Show()
end


local function PlayerInfoItemFunction(self, arg1, arg2, checked)
    local time = time()
    local realm = GetRealmName()
    local CurrentPlayersName = UnitName("player")
    local SavedText = ""
    local CleanText = ""
    local instance = eSaithBagFilterInstances[self.arg1]
    local count = 0

    for PlayerServerName, playerInfo in pairs(eSaithBagFilterInstances.players) do
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
    for instance, TableOfNames in pairs(eSaithBagFilterInstances) do        
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
    if eSaithBagFilterVar == nil then return end

    if eSaithBagFilterVar.properties.LeftTab == 1 then
        CreateZoneDropDownList()
    elseif eSaithBagFilterVar.properties.LeftTab == 4 then
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

    local command, rest = msg:match("^(%S*)%s*(.-)$")
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
    -- Remove "player' and 'boe' from the saved instances
    -- Make instances alphabetical
    -- Allow player to add/remove desired saved instances
    -- Allow option to choose miniumum required raid level (ie, no need to show lvl 80s when you only want to show level 100s)
-- Consider renaming eSaithBagFilter to eSFilter
--]]

--[[
  Updates:    
]]--



--[[


]]--