SLASH_BAGCLEANUP1 = "/clean";
function SlashCmdList.BAGCLEANUP(msg, editbox)
	if BagCleanUp:IsShown() then
		BagCleanUp:Hide();
	else
		BagCleanUp:Show();
	end
end

BagCleanUpVar = nil
BagCleanUpInstances = nil

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
		      texture = {0,0, .6,.6,.6, 1,1,1, 0,1,0, .2,.2,1, 1,0,1 }
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
                AddLoot = function(zone, obj, amount) 
                    if BagCleanUpInstances[zone] == nil then BagCleanUpInstances[zone] = { } end
                    if BagCleanUpInstances[zone][obj] == nil then 
                        BagCleanUpInstances[zone][obj] = amount 
                    else
                        BagCleanUpInstances[zone][obj] = BagCleanUpInstances[zone][obj] + amount                        
                    end
                end, 
                AddCurrency = function(zone, amount, currency)
                  if BagCleanUpInstances[zone] == nil then BagCleanUpInstances[zone] = { } end
                  if BagCleanUpInstances[zone]["Gold"] == nil then BagCleanUpInstances[zone]["Gold"] = 0 end
                  if BagCleanUpInstances[zone]["Silver"] == nil then BagCleanUpInstances[zone]["Silver"] = 0 end
                  if BagCleanUpInstances[zone]["Copper"] == nil then BagCleanUpInstances[zone]["Copper"] = 0 end

                  BagCleanUpInstances[zone][currency] = BagCleanUpInstances[zone][currency] + amount;
                  if BagCleanUpInstances[zone][currency] >= 100 and currency == "Copper" then
                    BagCleanUpInstances[zone]["Silver"] = BagCleanUpInstances[zone]["Silver"] + 1
                    BagCleanUpInstances[zone][currency] = BagCleanUpInstances[zone][currency] - 100
                  elseif BagCleanUpInstances[zone][currency] >= 100 and currency == "Silver" then
                    BagCleanUpInstances[zone]["Gold"] = BagCleanUpInstances[zone]["Gold"] + 1
                    BagCleanUpInstances[zone][currency] = BagCleanUpInstances[zone][currency] - 100
                  end
                end
            },

            properties = { }
        }
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

function BagClearUpButton_Click(self, event, ...)  
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 0, GetContainerNumSlots(bag) do      
			local texture, NumOfItems, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then         
				local itemNumber = tonumber(link:match("|Hitem:(%d+):"))
				local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link);
				if BagCleanUpVar.properties.LeftTab == 1 and BagCleanUpInstances[BagCleanUpVar.properties.zone] ~= nil then	         
					local zoneTable = BagCleanUpInstances[BagCleanUpVar.properties.zone];	 
                        if zoneTable[link] ~= nil and zoneTable[link] > 0 then
                            if class == "Trade Goods" and BagCleanUpCheckButtonTradeGoods:GetChecked() then
                                print("Not selling " .. link .. " because trade goods is checked")
                            else                    
						        UseContainerItem(bag, slot)
						        zoneTable[itemLink] = zoneTable[itemLink] - NumOfItems; 
                                if zoneTable[itemLink] < 0 then zoneTable[itemLink] = 0 end
                                print (NumOfItems .. " " .. link .. "'s sold. " .. zoneTable[itemLink] .. " remaining" )                             
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
				end
			end
		end	
	end
end

function VerifyItemSold(item, bag, slot)
    local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
    if item == link then
        print("Item " .. link .. " should have sold")
        --print("Count: " .. tostring(count))
        --print("locked: " .. tostring(locked))
        --print("quality: " .. tostring(quality))
        --print("readable: " .. tostring(readable))
        --print("lootable: " .. tostring(lootable))
        --print("link: " .. tostring(link))
        --print("Attemping to sell again")
        UseContainerItem(bag, slot)
        texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
        if texture then
            print("Did not sell on second attempt")
            return false
        end
    end
    return true
end

function BagCleanUp_OnLoad(self, event, ...)
    self:RegisterForDrag("LeftButton");
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("CHAT_MSG_LOOT")
    self:RegisterEvent("CHAT_MSG_MONEY")
	self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")	
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
		CreateRarityObjects()
		CreateCheckButtons();	
		CreateSliders();	
		ShowZoneFilter(nil, nil)	
		tinsert(UISpecialFrames, BagCleanUp:GetName())	
	elseif event == "CHAT_MSG_LOOT" and ... ~= nill then	    
        local zone = GetRealZoneText();
        if string.find( ... , "You receive item: ") ~= nil or 
            string.find( ... , "You receive loot: ") ~= nil or
            string.find( ... , "Received item: ") ~= nil then
                --Need to check if item is  Pattern:
            
		    local bulk = string.match( ... , ".*: (.+)%.");
			local _, _, dItemID = string.find(bulk, ".*|Hitem:(%d+):.*"); 
            local amount = 1
            if string.find(bulk, "x(%d)") ~= nil then
                amount =  string.match(bulk, ".*x(%d+)")
            end
			local _, dItemLink = GetItemInfo(dItemID);			
			local name, dItemLink, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(dItemID);	
            if vendorPrice > 0 then         
                BagCleanUpInstances.methods.AddLoot(zone, dItemLink, tonumber(amount)) 
            else
                print("Not adding " .. dItemLink .. " to the list because it cannot be sold to a vendor")
            end

		end
    elseif event == "CHAT_MSG_MONEY" and ... ~= nill then
        local zone = GetRealZoneText();
        if string.find(..., "You loot") ~= nil then
            local amount1, currency1, amount2, currency2, amount3, currency3 = string.match( ... , "You loot (%d+) (%a+),?%s*(%d*)%s*(%a*),?%s*(%d*)%s*(%a*)")     
            BagCleanUpInstances.methods.AddCurrency(zone, tonumber(amount1), currency1)
           
            if amount2 ~= nil and amount2 ~= "" and amount ~= "0" then BagCleanUpInstances.methods.AddCurrency(zone, tonumber(amount2), currency2) end
            if amount3 ~= nil and amount3 ~= "" and amount3 ~= "0" then BagCleanUpInstances.methods.AddCurrency(zone, tonumber(amount3), currency3) end
            local gold = 0
            local silver = 0
            local copper = 0
            if tostring(BagCleanUpInstances[zone]["Gold"]) ~= nil then gold = tostring(BagCleanUpInstances[zone]["Gold"]) end
            if tostring(BagCleanUpInstances[zone]["Silver"]) ~= nil then silver = tostring(BagCleanUpInstances[zone]["Silver"]) end
            if tostring(BagCleanUpInstances[zone]["Copper"]) ~= nil then copper = tostring(BagCleanUpInstances[zone]["Copper"]) end
            --print("Zone: " .. zone .. ", Gold: " .. gold .. ", Silver: " .. silver .. ", Copper: " .. copper )
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
	else 
		BagCleanUpVar[color].checked = self:GetChecked();
	end
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
		btn:SetScript("OnClick", BagCleanUpSlider_CheckBoxClick)
		local fontstring = btn:CreateFontString("BagCleanUpCheckBtn" .. color .. "FontString", "ARTWORK", "GameFontNormal")
		fontstring:SetTextColor(BagCleanUpVar.properties.texture[3 * index], BagCleanUpVar.properties.texture[3*index + 1], BagCleanUpVar.properties.texture[3 * index + 2] )
		fontstring:SetText("Filter " .. color .. " Items")
		fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
		btn:SetFontString(fontstring)
		btn:Hide();
	end

    local btn = CreateFrame("CheckButton", "BagCleanUpCheckButtonTradeGoods", BagCleanUp, "UICheckButtonTemplate")
		btn:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 70, -60);
		btn:SetScript("OnClick", BagCleanUpSlider_CheckBoxClick)
		local fontstring = btn:CreateFontString("BagCleanUpCheckBtnReagentsFontString", "ARTWORK", "GameFontNormal")
		fontstring:SetText("Do not sell trade goods")
		fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
		btn:SetFontString(fontstring)
		btn:Show();
end

function CreateSliders()
	local min = CreateFrame("Frame", "$parentSliderMin", BagCleanUp, "BagCleanUpSliderTemplate")
	min:SetPoint("TOP", "$parent", "TOP", 0, -75)
	_G[min:GetName() .. 'SliderTitle']:SetText("Minimum Item Level");
	min:Hide();
	local max = CreateFrame("Frame", "$parentSliderMax", BagCleanUp, "BagCleanUpSliderTemplate")
	max:SetPoint("TOP", "$parentSliderMin", "TOP", 0, -50)
	_G[max:GetName() .. 'SliderTitle']:SetText("Maximum Item Level");		
	max:Hide();
end

function ShowRarityFilter(self, event)
	if BagCleanUpVar.properties.LeftTab == 2 then return end	
	if BagCleanUpVar.properties.BottomTab == nil then BagCleanUpVar.properties.BottomTab = 1 end
	BagCleanUpVar.properties.LeftTab = 2
	local color = BagCleanUpVar.properties.colors[BagCleanUpVar.properties.BottomTab]
	
	_G["BagCleanUpTabs"]:Show();
	_G["BagCleanUpCheckButton" .. color]:SetChecked(BagCleanUpVar[color].checked);
	_G["BagCleanUpCheckButton" .. color]:Show();
	BagCleanUpSliderMinSlider:SetValue(BagCleanUpVar[color].min)
	BagCleanUpSliderMin:Show()
	BagCleanUpSliderMaxSlider:SetValue(BagCleanUpVar[color].max)
	BagCleanUpSliderMax:Show()
	BagCleanUpZone:Hide();	
    BagCleanUpCheckButtonTradeGoods:Hide();
end

function ShowZoneFilter(self, event)
	for index, color in pairs(BagCleanUpVar.properties.colors) do
		_G["BagCleanUpCheckButton" .. color]:Hide();
	end
	BagCleanUpVar.properties.LeftTab = 1	
	BagCleanUpTabs:Hide();
	BagCleanUpSliderMin:Hide()
	BagCleanUpSliderMax:Hide()
	BagCleanUpZone:Show();	
    BagCleanUpCheckButtonTradeGoods:Show()
end

function CreateDropDownList()	
  if BagCleanUpInstances == nil then
    return
  end	
	local i = 1;
	for v, k in pairs (BagCleanUpInstances) do
		if v ~= "methods" and v ~= "properties" then
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
  local size = table.getn(BagCleanUpInstances[self.arg1]) 
	BagCleanUpVar.properties.zone = self.arg1
	print(size .. " item(s) dropped in " .. self.arg1)
	for v, k in pairs(BagCleanUpInstances[self.arg1]) do
        if v ~= "Gold" and
           v ~= "Silver" and
           v ~= "Copper" and
           k > 0 and
           k ~= nil 
           then
            print(v, k)
        end    
	end	
	 
	if (not checked) then
		UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value);
	end
end

-- reset/cancel button for rarity
-- remove if item has been traded or trashed (not traded but "thrown away")
-- If items can be stacked, don't duplicate it - find out what max stacks are
-- Add gold looted, add gold from selling
-- Long term stats of each raid
-- Add additional filter list - Allow Right Click/Shift Click - Have icon that is added to icon when editable mode



-- In edit mode, black/darken all items that cannot be sold
-- Encircle/gold items that have chosen to be on the goldlist - keep list
-- List potential mounts that drop in instance/zone/raid
-- Have a huge table of reagents to sort to filter through


