SLASH_BAGCLEANUP1 = "/clean";
BagCleanUpVar = nil
BagCleanUpInstances = nil
function SlashCmdList.BAGCLEANUP(msg, editbox)
	if BagCleanUp:IsShown() then
		BagCleanUp:Hide();
	else
		BagCleanUp:Show();            
	end
end
 
function CreateRarityObjects()   
    if BagCleanUpVar == nil  then
		  BagCleanUpVar = { 
		    methods = {
	        GetRarity = function (ilvl) return BagCleanUpVar.properties.types[ilvl] end
	      },
		    properties = {
		      LeftTab = 1,
		      BottomTab = 1,
		      zone = nil,
		      colors = { "Gray", "White", "Green", "Blue", "Purple", "Gold" },
		      selectedColor = "Gray",
		      types = { "Junk", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Artifact/Heirloom", "Not a valid rarity"},
		      texture = {0,0, .6,.6,.6, 1,1,1, 0,1,0, .2,.2,1, 1,0,1, .8,.8,0 },
              update = false,
              updateCount = 0,
              updateInterval = 1.0
        }
      }
		  for index, color in pairs(BagCleanUpVar.properties.colors) do
		  	BagCleanUpVar[color] = { }
		  	BagCleanUpVar[color].checked = false
		  	BagCleanUpVar[color].min = 0
		  	BagCleanUpVar[color].max = 0
		  	BagCleanUpVar[color].minChecked = false
		  	BagCleanUpVar[color].maxChecked = false
		  	BagCleanUpVar[color].rarity = BagCleanUpVar.methods.GetRarity(index)
		  end
    end
    
    if BagCleanUpInstances == nil then
        BagCleanUpInstances = { 
            methods = { 
                AddLoot = function(obj, count) 
                    local zone = GetRealZoneText()
                    if BagCleanUpInstances[zone] == nil then BagCleanUpInstances[zone] = { } end
                    if BagCleanUpInstances[zone][obj] == nil then  BagCleanUpInstances[zone][obj] = { count = 0, found = false } end
                    
                    BagCleanUpInstances[zone][obj].count = BagCleanUpInstances[zone][obj].count + count
                end, 
                AddCurrency = function(amount, currency)
                    local zone = GetRealZoneText()
                    if BagCleanUpInstances[zone] == nil then BagCleanUpInstances[zone] = { } end
                    if BagCleanUpInstances[zone]["Gold"] == nil then 
                        BagCleanUpInstances[zone] = { Gold = 0, Silver = 0, Copper = 0 } 
                    end

                    BagCleanUpInstances[zone][currency] = BagCleanUpInstances[zone][currency] + amount;

                    if BagCleanUpInstances[zone]["Copper"] >= 100 then
                        BagCleanUpInstances[zone]["Silver"] = BagCleanUpInstances[zone]["Silver"] + 1
                        BagCleanUpInstances[zone]["Copper"] = BagCleanUpInstances[zone]["Copper"] - 100
                    end
                        
                    if BagCleanUpInstances[zone]["Silver"] >= 100 then
                        BagCleanUpInstances[zone]["Gold"] = BagCleanUpInstances[zone]["Gold"] + 1
                        BagCleanUpInstances[zone]["Silver"] = BagCleanUpInstances[zone]["Silver"] - 100
                    end
                end
            },
            properties = { }
        }
    end
end

function BagClearUpButton_Click(self, event, ...)    
    for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do      
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then         
				local itemNumber = tonumber(link:match("|Hitem:(%d+):"))
				local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link);
				if BagCleanUpVar.properties.LeftTab == 1 and BagCleanUpInstances[BagCleanUpVar.properties.zone] ~= nil then	         
                     BagCleanUpVar.properties.update = true
					local zoneTable = BagCleanUpInstances[BagCleanUpVar.properties.zone];	 
                        if zoneTable[link] ~= nil and zoneTable[link].count > 0 and not locked then                            
                            if class == "Trade Goods" and BagCleanUpCheckButtonTradeGoods:GetChecked() then
                                print("Not selling " .. link .. " because trade goods is checked")
                            else          
						        UseContainerItem(bag, slot)
                                zoneTable[link].found = true
                                zoneTable[link].bag = bag
                                zoneTable[link].slot = slot
                                if zoneTable[itemLink].count < 0 then zoneTable[itemLink].count = 0 end                            
                            end
                        end	 
				elseif BagCleanUpVar.properties.LeftTab == 2 then	 
					if vendorPrice > 0 and not locked and not lootable then -- Skip all items that cannot be sold to vendors								
						for index, color in pairs(BagCleanUpVar.properties.colors) do							
							if (BagCleanUpVar[color].checked and quality == index - 1
							and PassMin(ilvl, BagCleanUpVar[color].min, BagCleanUpVar[color].minChecked) 
							and PassMax(ilvl, BagCleanUpVar[color].max, BagCleanUpVar[color].maxChecked)) then
								print (link .. " sold")
								UseContainerItem(bag, slot)
							end
						end
					end
                elseif BagCleanUpVar.properties.LeftTab == 3 then                    
					if vendorPrice > 0 and not locked and not lootable then -- Skip all items that cannot be sold to vendors	
                        print("Checking color on " .. link)						
						for index, color in pairs(BagCleanUpVar.properties.colors) do	
							if BagCleanUpVar[color].checked and quality == index - 1 then							
								UseContainerItem(bag, slot)
							end
						end
					end
				end				
			end
		end	
	end	
end

function BagClearUpButton_OnUpdate(self, elapsed)
    self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed;
    if BagCleanUpVar.properties.zone == nil then return end

    if BagCleanUpVar.properties.update  and self.TimeSinceLastUpdate > BagCleanUpVar.properties.updateInterval then     
        BagClearUpButton_Click()
        UpdateZoneTable()
        self.TimeSinceLastUpdate = 0  
        
        if BagCleanUpInstances[BagCleanUpVar.properties.zone] == nil then
            BagCleanUpVar.properties.update = false
        end             
    end
end

function BagClearUpButton_OnHide(self, event, ...)
    BagCleanUpVar.properties.update = false
end

function BagCleanUp_OnLoad(self, event, ...)
    self:RegisterForDrag("LeftButton");
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("CHAT_MSG_LOOT")
    self:RegisterEvent("CHAT_MSG_MONEY")
	self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")
    self:RegisterEvent("BAG_UPDATE")	
end

function BagCleanUpTabs_OnLoad(self, event, ...)
	PanelTemplates_SetNumTabs(self, 5);
	PanelTemplates_SetTab(BagCleanUpTabs, 1);
end

function BagCleanUpTabs_OnShow(self, event, ...)	
	PanelTemplates_SetTab(BagCleanUpTabs, BagCleanUpVar.properties.BottomTab);
end

function BagCleanUp_OnEvent(self, event, ...)                  
	if event == "ADDON_LOADED" and ... == "BagCleanUp" then
	    self:UnregisterEvent("ADDON_LOADED")	
        BagCleanUpVar = nil
        BagCleanUpInstances = nil
		CreateRarityObjects()
		CreateCheckButtons();	
		CreateSliders();	
		ShowZoneFilter(nil, nil)	
		tinsert(UISpecialFrames, BagCleanUp:GetName())	
	elseif event == "CHAT_MSG_LOOT" and ... ~= nil then	    
        local zone = GetRealZoneText();
        if string.find( ... , "You receive item: ") ~= nil or 
            string.find( ... , "You receive loot: ") ~= nil or
            string.find( ... , "Received item: ") ~= nil then
            local bulk = string.match( ... , ".*: (.+)%.");
            local amount = 1     
            local dItemID = bulk

            if string.find(... , "Pattern:") ~= nil then print("Item is a pattern") end   -- TODO, need to implement
            if string.find(... , "Design:") ~= nil then print("Item is a design") end   -- TODO, need to implement
            if string.find(bulk, "x(%d+)") ~= nil then 
                dItemID, amount = string.match(bulk, "(.*)x(%d+)") 
            end

			local _, dItemLink = GetItemInfo(dItemID);			
			local name, dItemLink, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(dItemID);	
            if vendorPrice~= nil and vendorPrice > 0 then         
                BagCleanUpInstances.methods.AddLoot(dItemLink, tonumber(amount)) 
            end
		end
    elseif event == "CHAT_MSG_MONEY" and ... ~= nill then
        if string.find(..., "You loot") ~= nil then
            local amount1, currency1, amount2, currency2, amount3, currency3 = string.match( ... , "You loot (%d+) (%a+),?%s*(%d*)%s*(%a*),?%s*(%d*)%s*(%a*).?")
            BagCleanUpInstances.methods.AddCurrency(tonumber(amount1), currency1)
                       
            if amount2 ~= nil and amount2 ~= "" then BagCleanUpInstances.methods.AddCurrency(tonumber(amount2), currency2) end
            if amount3 ~= nil and amount3 ~= "" then BagCleanUpInstances.methods.AddCurrency(tonumber(amount3), currency3) end
        elseif string.find(..., "Received") ~= nil then
            local amount1, currency1, amount2, currency2, amount3, currency3 = string.match( ... , "Received (%d+) (%a+),?%s*(%d*)%s*(%a*),?%s*(%d*)%s*(%a*).?")
            BagCleanUpInstances.methods.AddCurrency(tonumber(amount1), currency1)
                       
            if amount2 ~= nil and amount2 ~= "" then BagCleanUpInstances.methods.AddCurrency(tonumber(amount2), currency2) end
            if amount3 ~= nil and amount3 ~= "" then BagCleanUpInstances.methods.AddCurrency(tonumber(amount3), currency3) end
        end
	elseif event == "MERCHANT_SHOW" then
		BagCleanUp:Show()
		BagCleanUpButton:Show();
	elseif event == "MERCHANT_CLOSED" then
		BagCleanUpButton:Hide();
	end	
end

function BagCleanUp_SliderOnLoad(self, event, ...)
	local minSize, maxSize = self:GetMinMaxValues();
	_G[self:GetName() .. 'Low']:SetText(minSize);	
	_G[self:GetName() .. 'High']:SetText(maxSize);	
end

function BagCleanUpSlider_DownButton(self, event, ...)
	local parent = self:GetParent();	
	local value = _G[parent:GetName() .. "Slider"]:GetValue() - _G[parent:GetName() .. "Slider"]:GetValueStep();
	_G[parent:GetName() .. "Slider"]:SetValue( math.floor(value));
	UpdateMinAndMax(self, math.floor(value));
end

function BagCleanUpSlider_UpButton(self, event, ...)
	local parent = self:GetParent();
	local value = _G[parent:GetName() .. "Slider"]:GetValue() + _G[parent:GetName() .. "Slider"]:GetValueStep();
	_G[parent:GetName() .. "Slider"]:SetValue(math.floor(value));
	UpdateMinAndMax(self, math.floor(value))	
end

function BagCleanUpSlider_SliderValueChanged(self, value)
	local parent = self:GetParent();
	_G[parent:GetName() .. "SliderValue"]:SetText(math.floor(value));
	UpdateMinAndMax(self, math.floor(value))
end

function UpdateMinAndMax(self, value)
	local parent = self:GetParent();
	local peak
	if (parent:GetName() == "BagCleanUpSliderMin") then peak = "min" else peak = "max" end	
	local color = BagCleanUpVar.properties.colors[BagCleanUpVar.properties.BottomTab]	
	BagCleanUpVar[color][peak] = value;
end

function BagCleanUpSlider_CheckBoxClick(self, button, down)
    local btn = self:GetParent():GetName() .. "CheckButton";		
    local color = BagCleanUpVar.properties.colors[BagCleanUpVar.properties.BottomTab]
	
	if string.find(self:GetName(), "Min") ~= nil then
		BagCleanUpVar[color].minChecked = self:GetChecked();
	elseif string.find(self:GetName(), "Max") ~= nil then
		BagCleanUpVar[color].maxChecked = self:GetChecked();
    end	
end

function BagCleanUpCheckBox_Click(self, button, down)
    local color = string.match(self:GetName(), "BagCleanUpCheckButton(.*)")
    BagCleanUpVar[color].checked = self:GetChecked();
end

function BagCleanUpBottomTab_Click(self, event, ...)		
	local parent = self:GetParent():GetName() .. "Tab"; 	
	_G["BagCleanUpCheckButton" .. BagCleanUpVar.properties.colors[BagCleanUpVar.properties.BottomTab]]:Hide();
	
	for index, color in ipairs(BagCleanUpVar.properties.colors) do
		if (parent .. index == self:GetName()) then
			BagCleanUpVar.properties.BottomTab = index		
			BagCleanUpSliderMinSlider:SetValue(BagCleanUpVar[color].min)
			BagCleanUpSliderMaxSlider:SetValue(BagCleanUpVar[color].max)
			BagCleanUpSliderMinCheckButton:SetChecked(BagCleanUpVar[color].minChecked)
			BagCleanUpSliderMaxCheckButton:SetChecked(BagCleanUpVar[color].maxChecked)			
			_G["BagCleanUpCheckButton" .. color]:Show();			
		end
	end	
end

function CreateCheckButtons()
	for index, color in ipairs(BagCleanUpVar.properties.colors) do
		local btn = CreateFrame("CheckButton", "BagCleanUpCheckButton" .. color, BagCleanUp, "UICheckButtonTemplate")
		btn:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 70, -30);
		btn:SetScript("OnClick", BagCleanUpCheckBox_Click)
		local fontstring = btn:CreateFontString("BagCleanUpCheckBtn" .. color .. "FontString", "ARTWORK", "GameFontNormal")
		fontstring:SetTextColor(BagCleanUpVar.properties.texture[3 * index], BagCleanUpVar.properties.texture[3*index + 1], BagCleanUpVar.properties.texture[3 * index + 2] )
		fontstring:SetText("Filter " .. color .. " Items")
		fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
		btn:SetFontString(fontstring)
		btn:Hide();
	end

    local btn = CreateFrame("CheckButton", "BagCleanUpCheckButtonTradeGoods", BagCleanUp, "UICheckButtonTemplate")
	btn:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 70, -60);
	local fontstring = btn:CreateFontString("BagCleanUpCheckBtnReagentsFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText("Do not sell trade goods")
	fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
	btn:SetFontString(fontstring)
	btn:Show();
end

function CreateSliders()
	local min = CreateFrame("Frame", "$parentSliderMin", BagCleanUp, "BagCleanUpSliderTemplate")
	min:SetPoint("TOP", "$parent", "TOP", 0, -75)
	_G[min:GetName() .. 'SlidqerTitle']:SetText("Minimum Item Level");
	min:Hide();
	local max = CreateFrame("Frame", "$parentSliderMax", BagCleanUp, "BagCleanUpSliderTemplate")
	max:SetPoint("TOP", "$parentSliderMin", "TOP", 0, -50)
	_G[max:GetName() .. 'SliderTitle']:SetText("Maximum Item Level");		
	max:Hide();
end

function ShowZoneFilter(self, event)
    if BagCleanUpVar.properties.LeftTab == 1 then return end
    PrepShowSideTab()

	BagCleanUpVar.properties.LeftTab = 1	
	BagCleanUpZone:Show();	
    BagCleanUpCheckButtonTradeGoods:Show()
end

function ShowILVLFilter(self, event)    
	if BagCleanUpVar.properties.LeftTab == 2 then return end	
    PrepShowSideTab()

    BagCleanUpVar.properties.LeftTab = 2
	if BagCleanUpVar.properties.BottomTab == nil then BagCleanUpVar.properties.BottomTab = 1 end
	
	local color = BagCleanUpVar.properties.colors[BagCleanUpVar.properties.BottomTab]
	_G["BagCleanUpTabs"]:Show();
	_G["BagCleanUpCheckButton" .. color]:SetChecked(BagCleanUpVar[color].checked);
	_G["BagCleanUpCheckButton" .. color]:Show();
	BagCleanUpSliderMinSlider:SetValue(BagCleanUpVar[color].min)
	BagCleanUpSliderMin:Show()
	BagCleanUpSliderMaxSlider:SetValue(BagCleanUpVar[color].max)
	BagCleanUpSliderMax:Show()
end

function ShowRarityFilter(self, event)
    if BagCleanUpVar.properties.LeftTab == 3 then return end
    PrepShowSideTab()
    BagCleanUpVar.properties.LeftTab = 3

    local point, relativeTo, relativePoint, xOffset, yOffset = BagCleanUpCheckButtonGray:GetPoint("TOPLEFT")
    local offset = yOffset
    
    for index, color in pairs(BagCleanUpVar.properties.colors) do      
        if color ~= "Gold" then  
            _G["BagCleanUpCheckButton" .. color]:SetPoint(point, relativeTo, relativePoint, xOffset, offset);
            _G["BagCleanUpCheckButton" .. color]:SetChecked(BagCleanUpVar[color].checked)
            _G["BagCleanUpCheckButton" .. color]:Show()
            offset = offset - 30
        end
    end
end

function PrepShowSideTab()
    -- Hide Tab 1
    for index, color in pairs(BagCleanUpVar.properties.colors) do
		_G["BagCleanUpCheckButton" .. color]:Hide();
	end
    BagCleanUpTabs:Hide();
	BagCleanUpSliderMin:Hide()
	BagCleanUpSliderMax:Hide()
    -- Hide Tab 2 and 3
	BagCleanUpZone:Hide();	
    BagCleanUpCheckButtonTradeGoods:Hide()

    -- If coming from tab 3 and going to tab 2, make sure checkboxes realign
    local point, relativeTo, relativePoint, xOffset, yOffset = BagCleanUpCheckButtonGray:GetPoint("TOPLEFT")    
    for index, color in pairs(BagCleanUpVar.properties.colors) do        
        _G["BagCleanUpCheckButton" .. color]:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset);
    end
end

function CreateDropDownList()	
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

function DropDownMenuItemFunction(self, arg1, arg2, checked) 
    local zoneTable = BagCleanUpInstances[self.arg1];
    BagCleanUpVar.properties.zone = self.arg1
    UpdateZoneTable()

    print(" -- Gained in "..self.arg1.."--")
    local size = 0	
	for item, itemTable in pairs(zoneTable) do
        if itemTable ~= nil and type(itemTable) ~= "number" and item ~= "methods" and item ~= "properties" and itemTable.count > 0 then
            print(item .."x" .. itemTable.count)
            size = size + 1
        end    
	end	
     
    if size <= 0 then 
        zoneTable = nil
        print("Instance loot has already been cleared")
        return
    else
	    print(size .. " item(s) dropped in " .. self.arg1)
    end    
    HighlightBagSlot()
	if (not checked) then
	    UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value);
	end
end

function UpdateZoneTable()
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

function HighlightBagSlot()
    for bag = 0, NUM_BAG_SLOTS do
		for slot = 0, GetContainerNumSlots(bag) do      
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then         
				local itemNumber = tonumber(link:match("|Hitem:(%d+):"))
				local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link);
				if BagCleanUpVar.properties.LeftTab == 1 and BagCleanUpInstances[BagCleanUpVar.properties.zone] ~= nil then	         
					local zoneTable = BagCleanUpInstances[BagCleanUpVar.properties.zone];	 
                    if zoneTable[link] == nil or zoneTable[link].count <= 0 then
                       _G["ContainerFrame".. (bag + 1).."Item".. (GetContainerNumSlots(bag) - slot + 1)]:SetAlpha(.3)
                    else
                        _G["ContainerFrame".. (bag + 1).."Item".. (GetContainerNumSlots(bag) - slot + 1)]:SetAlpha(1)
                    end
				end
			end
		end	
	end
end

function ClearBagItemsAlpha()
    for bag = 0, NUM_BAG_SLOTS do
		for slot = 0, GetContainerNumSlots(bag) do  
            _G["ContainerFrame".. (bag + 1).."Item".. (GetContainerNumSlots(bag) - slot + 1)]:SetAlpha(1)                
		end	
	end
end

function PassMin(ilvl, minlvl, required)
	if required then
		return ilvl >= minlvl
	else
		return true	
	end
end

function PassMax(ilvl, maxlvl, required)
	if required then
		return ilvl <= maxlvl
	else
		return true
	end
end

--Notes:
-- reset/cancel button for ilvl
-- Add gold looted, add gold from selling
-- Long term stats of each raid
-- Add additional filter list - Allow Right Click/Shift Click - Have icon that is added to icon when editable mode

-- Encircle/gold items that have chosen to be on the goldlist - keep list
-- List potential mounts that drop in instance/zone/raid
-- Have a huge table of reagents to sort to filter through
-- Need to implement filtering on "Pattern:" and Design


-- Changes
-- Made sure that the bag does not sell if equipped even if it fits the criteria
-- Added another side tab. Rarity. Instead of paging through ilvl and rarity, user may just choose rarity when all known rarity is needed to be sold.


-- Problems
-- If a bag is emtpy and equipped and fits the criteria for the ilvl sell, the bag sells to the vendor!


-- Worth Mentioning:
-- On rare occassion when looting Blizzard does not state that item has been looted. In such case, addon will not add item to zone table