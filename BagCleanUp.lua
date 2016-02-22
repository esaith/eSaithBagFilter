﻿SLASH_BAGCLEANUP1 = '/clean';

local function printTable(tb, spacing)
    if spacing == nil then spacing = "" end
    print(spacing.."Entering table")
    for k, v in pairs(tb) do
        print(spacing.."K: "..k..", v: "..tostring(v))
        if type(v) == "table" then
            printTable(v, "   "..spacing)
        end
    end
    print(spacing.."Leaving Table")
end

local function AddLoot(obj, count) 
     local zone = GetRealZoneText()         
     if BagCleanUpInstances[zone] == nil then BagCleanUpInstances[zone] = { } end
     if BagCleanUpInstances[zone][obj] == nil then  BagCleanUpInstances[zone][obj] = { count = 0, found = false } end
     
     BagCleanUpInstances[zone][obj].count = BagCleanUpInstances[zone][obj].count + count  
 end

 local function GetRarity(ilvl) 
    return BagCleanUpVar.properties.types[ilvl] 
end  

--local function AddCurrency(amount, currency)
--    local zone = GetRealZoneText()
--    if BagCleanUpInstances[zone] == nil then BagCleanUpInstances[zone] = { } end
--    if BagCleanUpInstances[zone].Gold == nil then 
--        BagCleanUpInstances[zone].Gold = 0
--        BagCleanUpInstances[zone].Copper = 0
--        BagCleanUpInstances[zone].Silver = 0                
--    end
--
--    BagCleanUpInstances[zone][currency] = BagCleanUpInstances[zone][currency] + amount;
--    if BagCleanUpInstances[zone]["Copper"] >= 100 then
--        BagCleanUpInstances[zone]["Silver"] = BagCleanUpInstances[zone]["Silver"] + 1
--        BagCleanUpInstances[zone]["Copper"] = BagCleanUpInstances[zone]["Copper"] - 100
--    end
--        
--    if BagCleanUpInstances[zone]["Silver"] >= 100 then
--        BagCleanUpInstances[zone]["Gold"] = BagCleanUpInstances[zone]["Gold"] + 1
--        BagCleanUpInstances[zone]["Silver"] = BagCleanUpInstances[zone]["Silver"] - 100
--    end
--end

local function PassMin(ilvl, minlvl, required)
	if required then
		return ilvl >= minlvl
	else
		return true	
	end
end

local function PassMax(ilvl, maxlvl, required)
	if required then
		return ilvl <= maxlvl
	else
		return true
	end
end

 local function UpdateZoneTable()
    if BagCleanUpVar.properties.zone == nil then return end
    local zoneTable = BagCleanUpInstances[BagCleanUpVar.properties.zone];
    if zoneTable == nil then return end

    for item, itemTable in pairs(zoneTable) do
        if type(itemTable) == "table" then  itemTable.found = false end
    end

    -- Find what is still in the bags
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 0, GetContainerNumSlots(bag) do
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
            if texture then                
                if zoneTable[link] ~= nil then
                    zoneTable[link].found = true
                end	  
			end
		end	
    end

    -- Whatever wasn't found in the bags is now garbage in the table. Take out the trash!
    local count = 0
    for item, itemTable in pairs(zoneTable) do
        if itemTable ~= nil and type(itemTable) ~= "number" and item ~= "methods" and item ~= "properties" then
            if itemTable.found == false then 
                zoneTable[item] = nil 
            else
                count = count + 1
            end      
        end
    end

    if count <= 0 then BagCleanUpInstances[BagCleanUpVar.properties.zone] = nil end
end

local function DimBagSlotZone()
    if BagCleanUpVar.properties.zone == nil or BagCleanUpInstances[BagCleanUpVar.properties.zone] == nil then return end

    local alpha
    local zoneTable = BagCleanUpInstances[BagCleanUpVar.properties.zone];

    for bag = 0, NUM_BAG_SLOTS do
		for slot = 0, GetContainerNumSlots(bag) do      
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then         
                alpha = .2
				local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link);					 
                if zoneTable[link] ~= nil and zoneTable[link].count > 0 and not lootable then
                   alpha = 1                     
                end
                
                _G["ContainerFrame"..(bag + 1).."Item"..(GetContainerNumSlots(bag) - slot + 1)]:SetAlpha(alpha)                				
			end
		end	
	end
end

local function DimBagSlotiLVL() 
    local count = 0
    for k, color in pairs(BagCleanUpVar.properties.colors) do
        if BagCleanUpVar[color].checked then 
            count = count + 1
        end
    end

    if count <= 0 then 
        for bag = 0, NUM_BAG_SLOTS do
	    	for slot = 0, GetContainerNumSlots(bag) do      
	    		local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
	    		if texture then                        
                    _G["ContainerFrame"..(bag + 1).."Item"..(GetContainerNumSlots(bag) - slot + 1)]:SetAlpha(1)                 
	    		end
	    	end	
	    end
    else
        local alpha
        for bag = 0, NUM_BAG_SLOTS do
	        for slot = 0, GetContainerNumSlots(bag) do      
	        	local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
	        	if texture then   
                    alpha = .2	
                    local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link);
                    if vendorPrice > 0 and not locked and not lootable then -- Skip all items that cannot be sold to vendors        
	                	local color = BagCleanUpVar.properties.colors[quality + 1]		
                        if BagCleanUpVar[color].checked and not lootable 
	                	and PassMin(ilvl, BagCleanUpVar[color].min, BagCleanUpVar[color].minChecked)
	                	and PassMax(ilvl, BagCleanUpVar[color].max, BagCleanUpVar[color].maxChecked) then
	                		alpha = 1
	                	end
	                end
                end
                _G["ContainerFrame"..(bag + 1).."Item"..(GetContainerNumSlots(bag) - slot + 1)]:SetAlpha(alpha)
            end        
        end
    end
end

local function DimBagSlotColor() 
    local count = 0
    for k, color in pairs(BagCleanUpVar.properties.colors) do
        if BagCleanUpVar[color] ~= nil and BagCleanUpVar[color].checked then 
            count = count + 1
        end
    end

    if count <= 0 then 
        for bag = 0, NUM_BAG_SLOTS do
	    	for slot = 0, GetContainerNumSlots(bag) do      
	    		local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
	    		if texture then                        
                    _G["ContainerFrame"..(bag + 1).."Item"..(GetContainerNumSlots(bag) - slot + 1)]:SetAlpha(1)                 
	    		end
	    	end	
	    end
    else
        local alpha
        for bag = 0, NUM_BAG_SLOTS do
	    	for slot = 0, GetContainerNumSlots(bag) do      
	    		local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
	    		if texture then 
                    alpha = .2  
                    local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link);
                    local color = BagCleanUpVar.properties.colors[quality + 1] 
                    if BagCleanUpVar[color] ~= nil and BagCleanUpVar[color].checked and vendorPrice > 0 and not lootable then 
                        alpha = 1 
                    end  
                    _G["ContainerFrame"..(bag + 1).."Item"..(GetContainerNumSlots(bag) - slot + 1)]:SetAlpha(alpha)
	    		end
	    	end	
	    end
    end
end

local function UpdateMinAndMax(self, value)
	local parent = self:GetParent();
	local peak
	if (parent:GetName() == "BagCleanUpSliderMin") then peak = "min" else peak = "max" end	
	local color = BagCleanUpVar.properties.colors[BagCleanUpVar.properties.BottomTab]	
	if BagCleanUpVar[color] ~= nil then BagCleanUpVar[color][peak] = value end
    DimBagSlotiLVL()
end

local function DropDownMenuItemFunction(self, arg1, arg2, checked) 
    BagCleanUpVar.properties.zone = self.arg1
    local zoneTable = BagCleanUpInstances[self.arg1];
    UpdateZoneTable()

    print(" -- Gained in "..self.arg1.."--")
    local size = 0	
	for item, itemTable in pairs(zoneTable) do
        if itemTable ~= nil and type(itemTable) ~= "number" and item ~= "methods" and item ~= "properties" then
            print(item.."x"..itemTable.count)
            size = size + 1
        end    
	end	
     
    if size <= 0 then 
        zoneTable = nil
        print("Instance loot has already been cleared")
        return
    else
	    print(size.." item(s) dropped in "..self.arg1)
    end    
    DimBagSlotZone()
	if (not checked) then
	    UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value);
	end
end

local function PrepareToShowSideTabs()
    -- Hide Tab 1
    for index, color in pairs(BagCleanUpVar.properties.colors) do
		_G["BagCleanUpCheckButton"..color]:Hide();
	end
    BagCleanUpBottomTabs:Hide();
	BagCleanUpSliderMin:Hide()
	BagCleanUpSliderMax:Hide()
    -- Hide Tab 2 and 3
	BagCleanUpZone:Hide();	
    BagCleanUpCheckButton_TradeGoods:Hide()
    _G["BagCleanUpDoNotSellFontString"]:Hide()
    _G["BagCleanUpCancelButton"]:Hide()

    -- If coming from tab 3 and going to tab 2, make sure checkboxes realign
    local point, relativeTo, relativePoint, xOffset, yOffset = BagCleanUpCheckButtonGray:GetPoint("TOPLEFT")    
    for index, color in pairs(BagCleanUpVar.properties.colors) do        
        _G["BagCleanUpCheckButton"..color]:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset);
    end
end

local function CreateRarityObjects() 
    BagCleanUpInstances = { }
      
    if BagCleanUpVar == nil  then
		  BagCleanUpVar = { 		    
		    properties = {
		      LeftTab = 1,
		      BottomTab = 1,
		      zone = nil,
              types = { "Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Artifact", "Heirloom", "WoW Token"},
		      colors = { "Gray", "White", "Green", "Blue", "Purple" --, "Orange", "Gold", "Gold", "Cyan"
              },
		      selectedColor = "Gray",		      
		      texture = {0,0, .6,.6,.6, 1,1,1, 0,1,0, .2,.2,1, 1,0,1, .8,.8,0 },
              update = false,
              updateCount = 0,
              itemUpdateCount = 0,
              updateInterval = 1.0,
              personalItems = { }
            }
        }
        for index, color in pairs(BagCleanUpVar.properties.colors) do
        	BagCleanUpVar[color] = { }
        	BagCleanUpVar[color].checked = false
        	BagCleanUpVar[color].min = 0
        	BagCleanUpVar[color].max = 0
        	BagCleanUpVar[color].minChecked = false
        	BagCleanUpVar[color].maxChecked = false
        	BagCleanUpVar[color].rarity = GetRarity(index)
        end    
    end
end

local function CreateCheckButtons()
	for index, color in ipairs(BagCleanUpVar.properties.colors) do
		local btn = CreateFrame("CheckButton", "$parentCheckButton"..color, BagCleanUp, "UICheckButtonTemplate")
		btn:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 70, -30);
		btn:SetScript("OnClick", BagCleanUpCheckBox_Click)
		local fontstring = btn:CreateFontString("BagCleanUpCheckBtn"..color.."FontString", "ARTWORK", "GameFontNormal")
		fontstring:SetTextColor(BagCleanUpVar.properties.texture[3 * index], BagCleanUpVar.properties.texture[3*index + 1], BagCleanUpVar.properties.texture[3 * index + 2] )
		fontstring:SetText("Filter "..color.." Items")
		fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
		btn:SetFontString(fontstring)
		btn:Hide();
	end

    --Cancel button
    local cxBtn = CreateFrame("Button", "$parentCancelButton", BagCleanUp, "UIPanelButtonTemplate")
    cxBtn:SetSize(100, 30);
	cxBtn:SetPoint("BOTTOMRIGHT", "$parent", "BOTTOMRIGHT", -15, 15);
	cxBtn:SetScript("OnClick", BagCleanUpCancelButton_Click)
    local cxFont = cxBtn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
    cxFont:SetText("|cffffffffReset Addon")
	cxFont:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
    cxFont:Show()
	cxBtn:Show();

	local fontstring = BagCleanUp:CreateFontString("$parentDoNotSellFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText("|cffff0000Do Not Sell:")
	fontstring:SetPoint("CENTER", "$parent", "TOP", 0, -87)
    fontstring:Show()

    local btn = CreateFrame("CheckButton", "BagCleanUpCheckButton_TradeGoods", BagCleanUp, "UICheckButtonTemplate")
	btn:SetPoint("CENTER", "$parent", "CENTER", -50, 60);
	local fontstring = btn:CreateFontString("BagCleanUpCheckBtnReagentsFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText("Trade Goods")
	fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
	btn:SetFontString(fontstring)
	btn:Show();
end

function CreateSliders()
	local min = CreateFrame("Frame", "$parentSliderMin", BagCleanUp, "BagCleanUpSliderTemplate")
	min:SetPoint("TOP", "$parent", "TOP", 0, -75)
	_G[min:GetName()..'SliderTitle']:SetText("Minimum Item Level");
	min:Hide();
	local max = CreateFrame("Frame", "$parentSliderMax", BagCleanUp, "BagCleanUpSliderTemplate")
	max:SetPoint("TOP", "$parentSliderMin", "TOP", 0, -50)
	_G[max:GetName()..'SliderTitle']:SetText("Maximum Item Level");		
	max:Hide();
end


function BagCleanUp_OnLoad(self, event,...)
    self:RegisterForDrag("LeftButton");
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("CHAT_MSG_LOOT")
    --self:RegisterEvent("CHAT_MSG_MONEY")
	self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")
    self:RegisterEvent("BAG_UPDATE")	
    self:RegisterEvent("MODIFIER_STATE_CHANGED")
end

function BagCleanUp_OnHide()
    for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do 
            _G["ContainerFrame"..(bag + 1).."Item"..slot]:SetAlpha(1)     
            _G["ContainerFrame"..(bag + 1).."Item"..slot].BattlepayItemTexture:Hide()            
		end	
	end
end

function BagCleanUp_OnShow()
    if BagCleanUpVar.properties.LeftTab == 1 then
        DimBagSlotZone()
    elseif BagCleanUpVar.properties.LeftTab == 2 then
        DimBagSlotiLVL()
    elseif BagCleanUpVar.properties.LeftTab == 3 then
        DimBagSlotColor()
    end

    for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do 
            BagCleanUpContainerHook_OnLeave(_G["ContainerFrame"..(bag + 1).."Item"..slot])            
		end	
	end
end

function BagCleanUp_OnEvent(self, event,...) 
	if event == "ADDON_LOADED" and...== "BagCleanUp" then
	    self:UnregisterEvent("ADDON_LOADED")	
        BagCleanUpVar = BagCleanUpVar or nil
		CreateRarityObjects()
        --printTable(BagCleanUpInstances)
		CreateCheckButtons();	
		CreateSliders();	
		BagCleanUp_ShowZoneFilter()	
		tinsert(UISpecialFrames, BagCleanUp:GetName())	
        for bag = 0, NUM_BAG_SLOTS do
		    for slot = 1, GetContainerNumSlots(bag) do 
                _G["ContainerFrame"..(bag + 1).."Item"..slot]:HookScript("OnClick", BagCleanUpContainerHook_OnClick)
                _G["ContainerFrame"..(bag + 1).."Item"..slot]:HookScript("OnLeave", BagCleanUpContainerHook_OnLeave)
                _G["ContainerFrame"..(bag + 1).."Item"..slot]:HookScript("OnUpdate", BagCleanUpContainerHook_OnUpdate)            
		    end	
	    end
	elseif event == "CHAT_MSG_LOOT" and...~= nil then	  
        if string.find(..., "You receive item: ") ~= nil or 
            string.find(..., "You receive loot: ") ~= nil or
            string.find(..., "Received item: ") ~= nil then

            local bulk
            if string.find(..., "You receive item: ") ~= nil or string.find(..., "Received item: ") ~= nil then
                bulk = string.match(..., ".* item: (.+)%.");
            else
                bulk = string.match(..., ".* loot: (.+)%.");
            end

            local amount = 1     
            local dItemID = bulk
                        
            if string.find(bulk, "%]x(%d+)") ~= nil then 
                dItemID, amount = string.match(bulk, "(.*)x(%d+)") 
            end
		
			local name, dItemLink, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(dItemID);	
            if vendorPrice ~= nil and vendorPrice > 0 then         
                AddLoot(dItemLink, tonumber(amount)) 
            end
		end
    --elseif event == "CHAT_MSG_MONEY" and...~= nill then
    --    if string.find(..., "You loot") or string.find(..., "Received") ~= nil then
    --        local amount1, currency1, amount2, currency2, amount3, currency3 = string.match(..., ".*(%d+) (%a+),?%s*(%d*)%s*(%a*),?%s*(%d*)%s*(%a*).?")
    --        AddCurrency(tonumber(amount1), currency1)
    --                   
    --        if amount2 ~= nil and amount2 ~= "" then AddCurrency(tonumber(amount2), currency2) end
    --        if amount3 ~= nil and amount3 ~= "" then AddCurrency(tonumber(amount3), currency3) end
    --    end
	elseif event == "MERCHANT_SHOW" then
		BagCleanUp:Show()
		BagCleanUpButton:Show();
	elseif event == "MERCHANT_CLOSED" then
		BagCleanUpButton:Hide();
	end	
end


function BagCleanUpContainerHook_OnClick(self, button) 
    if self.count <= 0 or 
    not IsAltKeyDown() or
    not BagCleanUp:IsShown() then 
        return 
    end

    local bag = self:GetParent():GetID()
    local slot = self:GetID()
    local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot);

    if BagCleanUpVar.properties.personalItems[link] == nil then 
        BagCleanUpVar.properties.personalItems[link] = true
        self.BattlepayItemTexture:Show()
    else
        if BagCleanUpVar.properties.personalItems[link] then
            BagCleanUpVar.properties.personalItems[link] = false
            self.BattlepayItemTexture:Hide()
        else
            BagCleanUpVar.properties.personalItems[link] = true 
            self.BattlepayItemTexture:Show()
        end
    end
end

function BagCleanUpContainerHook_OnLeave(self, motion)
    local bag = self:GetParent():GetID()
    local slot = self:GetID()
    local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot);
    local newItemAnim = self.newitemglowAnim;

    if BagCleanUpVar.properties.personalItems[link] == nil then return end;
    if BagCleanUpVar.properties.personalItems[link] and BagCleanUp:IsShown() then    
        self.BattlepayItemTexture:Show()
    else
        self.BattlepayItemTexture:Hide() 
    end
end

function BagCleanUpContainerHook_OnUpdate(self, elapsed)
    BagCleanUpVar.properties.itemUpdateCount = BagCleanUpVar.properties.itemUpdateCount + elapsed;

    if BagCleanUpVar.properties.itemUpdateCount > BagCleanUpVar.properties.updateInterval then  
        BagCleanUpContainerHook_OnLeave(self, nil)
        BagCleanUpVar.properties.updateCount = 0
    end
end


function BagCleanUpSellButton_Click(self, event,...)  
    BagCleanUpVar.properties.update = true  
    for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do      
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then         
				local itemNumber = tonumber(link:match("|Hitem:(%d+):"))
				local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link);
                local personalItem = BagCleanUpVar.properties.personalItems[link]
				if BagCleanUpVar.properties.LeftTab == 1 and BagCleanUpInstances[BagCleanUpVar.properties.zone] ~= nil then	  
					local zoneTable = BagCleanUpInstances[BagCleanUpVar.properties.zone];	 
                    if zoneTable[link] ~= nil and zoneTable[link].count > 0 and not locked and (BagCleanUpVar.properties.personalItems[link] == nil or BagCleanUpVar.properties.personalItems[link] == false) then                            
                        if class == "Trade Goods" and BagCleanUpCheckButton_TradeGoods:GetChecked() then
                            print("Not selling "..link.." because trade goods is checked")
                        else          
					        UseContainerItem(bag, slot)                          
                            zoneTable[link].found = true
                            if zoneTable[itemLink].count < 0 then zoneTable[itemLink].count = 0 end                            
                        end
                    end	 
				elseif BagCleanUpVar.properties.LeftTab == 2 then	 
					if vendorPrice > 0 and not locked and not lootable and (personalItem == nil or personalItem == false) then							
						local color = BagCleanUpVar.properties.colors[quality + 1]		
                        if BagCleanUpVar[color] ~= nil and BagCleanUpVar[color].checked 
	                    and PassMin(ilvl, BagCleanUpVar[color].min, BagCleanUpVar[color].minChecked)
	                    and PassMax(ilvl, BagCleanUpVar[color].max, BagCleanUpVar[color].maxChecked) then
	                    	UseContainerItem(bag, slot)                          
	                    end
					end
                elseif BagCleanUpVar.properties.LeftTab == 3 then                    
					if vendorPrice > 0 and not locked and not lootable and (personalItem == nil or personalItem == false) then		
						local color = BagCleanUpVar.properties.colors[quality + 1]	
						if BagCleanUpVar[color] ~= nil and BagCleanUpVar[color].checked then							
							UseContainerItem(bag, slot)                        
						end
					end
				end				
			end
		end	
	end	
end

function BagCleanUpSellButton_OnUpdate(self, elapsed)
    self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed;
    if BagCleanUpVar.properties.update and self.TimeSinceLastUpdate > BagCleanUpVar.properties.updateInterval + 1 then  
        print("Selling")
        BagCleanUpSellButton_Click()
        UpdateZoneTable()
        self.TimeSinceLastUpdate = 0       
    end
end

function BagCleanUpCancelButton_Click(self, event)
    BagCleanUpVar = nil
    BagCleanUpInstances = nil
    ReloadUI()
end

function BagCleanUpBottomTabs_OnLoad(self, event,...)
	PanelTemplates_SetNumTabs(self, 5);
	PanelTemplates_SetTab(BagCleanUpBottomTabs, 1);
end

function BagCleanUpBottomTabs_OnShow(self, event,...)	
	PanelTemplates_SetTab(BagCleanUpBottomTabs, BagCleanUpVar.properties.BottomTab);    
end


function BagCleanUpSlider_OnLoad(self, event,...)
	local minSize, maxSize = self:GetMinMaxValues();
	_G[self:GetName()..'Low']:SetText(minSize);	
	_G[self:GetName()..'High']:SetText(maxSize);	
end

function BagCleanUpSlider_DownButton(self, event,...)
	local parent = self:GetParent();	
	local value = _G[parent:GetName().."Slider"]:GetValue() - _G[parent:GetName().."Slider"]:GetValueStep();
	_G[parent:GetName().."Slider"]:SetValue( math.floor(value));
	UpdateMinAndMax(self, math.floor(value));
end

function BagCleanUpSlider_UpButton(self, event,...)
	local parent = self:GetParent();
	local value = _G[parent:GetName().."Slider"]:GetValue() + _G[parent:GetName().."Slider"]:GetValueStep();
	_G[parent:GetName().."Slider"]:SetValue(math.floor(value));
	UpdateMinAndMax(self, math.floor(value))	
end

function BagCleanUpSlider_SliderValueChanged(self, value)
	local parent = self:GetParent();
	_G[parent:GetName().."SliderValue"]:SetText(math.floor(value));
	UpdateMinAndMax(self, math.floor(value))
end

function BagCleanUpSlider_CheckBoxClick(self, button, down)
    local btn = self:GetParent():GetName().."CheckButton";		
    local color = BagCleanUpVar.properties.colors[BagCleanUpVar.properties.BottomTab]
	
	if string.find(self:GetName(), "Min") ~= nil then
		BagCleanUpVar[color].minChecked = self:GetChecked();
	elseif string.find(self:GetName(), "Max") ~= nil then
		BagCleanUpVar[color].maxChecked = self:GetChecked();
    end	
    DimBagSlotiLVL()
end


function BagCleanUpCheckBox_Click(self, button, down)
    local color = string.match(self:GetName(), "BagCleanUpCheckButton(.*)")
    if BagCleanUpVar[color] ~= nil then
        BagCleanUpVar[color].checked = self:GetChecked();
    end
    DimBagSlotColor()
end

function BagCleanUpBottomTab_Click(self, event,...)		
	local parent = self:GetParent():GetName().."Tab"; 	
	_G["BagCleanUpCheckButton"..BagCleanUpVar.properties.colors[BagCleanUpVar.properties.BottomTab]]:Hide();
	
	for index, color in ipairs(BagCleanUpVar.properties.colors) do
		if (parent..index == self:GetName()) then
			BagCleanUpVar.properties.BottomTab = index		
			BagCleanUpSliderMinSlider:SetValue(BagCleanUpVar[color].min)
			BagCleanUpSliderMaxSlider:SetValue(BagCleanUpVar[color].max)
			BagCleanUpSliderMinCheckButton:SetChecked(BagCleanUpVar[color].minChecked)
			BagCleanUpSliderMaxCheckButton:SetChecked(BagCleanUpVar[color].maxChecked)			
			_G["BagCleanUpCheckButton"..color]:Show();			
		end
	end	
end

function BagCleanUp_ShowZoneFilter(self, event)
    PrepareToShowSideTabs()

	BagCleanUpVar.properties.LeftTab = 1
    DimBagSlotZone()	
	BagCleanUpZone:Show();	
    BagCleanUpCheckButton_TradeGoods:Show()
    _G["BagCleanUpDoNotSellFontString"]:Show()

end

function BagCleanUp_ShowILVLFilter(self, event)    
    PrepareToShowSideTabs()

    BagCleanUpVar.properties.LeftTab = 2
	if BagCleanUpVar.properties.BottomTab == nil then BagCleanUpVar.properties.BottomTab = 1 end
	
	local color = BagCleanUpVar.properties.colors[BagCleanUpVar.properties.BottomTab]
	_G["BagCleanUpBottomTabs"]:Show();
	_G["BagCleanUpCheckButton"..color]:SetChecked(BagCleanUpVar[color].checked);
	_G["BagCleanUpCheckButton"..color]:Show();
    _G["BagCleanUpCancelButton"]:Show()
	BagCleanUpSliderMinSlider:SetValue(BagCleanUpVar[color].min)
	BagCleanUpSliderMin:Show()
	BagCleanUpSliderMaxSlider:SetValue(BagCleanUpVar[color].max)
	BagCleanUpSliderMax:Show()
    DimBagSlotiLVL()
end

function BagCleanUp_ShowRarityFilter(self, event)
    PrepareToShowSideTabs()
    BagCleanUpVar.properties.LeftTab = 3

    local point, relativeTo, relativePoint, xOffset, yOffset = BagCleanUpCheckButtonGray:GetPoint("TOPLEFT")
    local offset = yOffset
    
    for index, color in pairs(BagCleanUpVar.properties.colors) do      
        if BagCleanUpVar[color] ~= nil then              
            _G["BagCleanUpCheckButton"..color]:SetPoint(point, relativeTo, relativePoint, xOffset, offset);
            _G["BagCleanUpCheckButton"..color]:SetChecked(BagCleanUpVar[color].checked)
            _G["BagCleanUpCheckButton"..color]:Show()
            offset = offset - 30
        end
    end
    DimBagSlotColor()
end

function BagCleanUp_CreateDropDownList()	
    if BagCleanUpInstances == nil then
      return
    end

    local i = 1;          
    for v, k in pairs (BagCleanUpInstances) do
    	if k ~= nil and type(k) ~= "number" and v ~= "methods" and v ~= "properties" then
    		info = UIDropDownMenu_CreateInfo();
    		info.text = tostring(v)
    		info.arg1 = tostring(v)
    		info.value = i; 
    		info.func = DropDownMenuItemFunction; 
    		UIDropDownMenu_AddButton(info);
    		i = i + 1;
    	end
    end
end

function SlashCmdList.BAGCLEANUP(msg, editbox)
	if BagCleanUp:IsShown() then
		BagCleanUp:Hide();
	else    
		BagCleanUp:Show();            
	end
end

--Notes:
-- reset/cancel button for ilvl
-- Add gold looted, add gold from selling
-- Long term stats of each raid

-- List potential mounts that drop in instance/zone/raid
-- Have a huge table of reagents to sort to filter through
-- Consider disenchanting if selected
-- Change labeling from "Colors" to 'Types'

-- Changes

-- Problems

-- Worth Mentioning:
-- On rare occassion when looting Blizzard does not state that item has been looted the addon will not add item to zone table