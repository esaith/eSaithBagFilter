SLASH_BAGCLEANUP1 = "/clean";
function SlashCmdList.BAGCLEANUP(msg, editbox)
	if BagCleanUp:IsShown() then
		BagCleanUp:Hide();
	else
		BagCleanUp:Show();
	end
end

BagCleanUpVar = { }
BagCleanUpInstances = { }

local BagCleanUpColorTexture = {0,0, .6,.6,.6, 1,1,1, 0,1,0, .2,.2,1, 1,0,1 }
local BagCleanUpColor = { "Gray", "White", "Green", "Blue", "Purple" }
local BagCleanUpTypes = { "Junk", "Common", "Uncommon", "Rare", "Epic"}

function CreateRarityObjects()
	if BagCleanUpVar == nil then
		BagCleanUpVar = { }
		BagCleanUpVar.LeftTab = 1
		BagCleanUpVar.BottomTab = 1
		
		for index, color in pairs(BagCleanUpColor) do
			BagCleanUpVar[color] = { }
			BagCleanUpVar[color].checked = false
			BagCleanUpVar[color].min = 0
			BagCleanUpVar[color].max = 0
			BagCleanUpVar[color].minChecked = false
			BagCleanUpVar[color].maxChecked = false
			print("Created ")
		end
	end
end

function GetRarity(ilvl)
	if ilvl == 0 then
		return "junk"
	elseif ilvl == 1 then
		return "common"
	elseif ilvl == 2 then
		return "uncommon"
	elseif ilvl == 3 then
		return "rare"
	elseif ilvl == 4 then
		return "epic"
	else
		return "More than epic"
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
			local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then
				local itemNumber = tonumber(link:match("|Hitem:(%d+):"))
				local itemName, itemLink, itemRarity, ilvl, reqlvl, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link);

				if BagCleanUpVar.LeftTab == 1 and BagCleanUpInstances[BagCleanUpInstances.zone] ~= nil then	
					local zoneTable = BagCleanUpInstances[BagCleanUpInstances.zone];	
					local size = table.getn(zoneTable)			
					for n = 1, size do
						if zoneTable[n] == link then							
							print (link .. ", rarity: " .. GetRarity(quality) .. ", ilvl: " .. ilvl .. " sold")
							UseContainerItem(bag, slot)
							zoneTable[n] = nil;
						end
					end	
				elseif BagCleanUpVar.LeftTab == 2 then	
					print(vendorPrice)
					if vendorPrice > 0 then -- Skip all items that cannot be sold to vendors								
						for index, color in pairs(BagCleanUpColor) do
							if (BagCleanUpVar[color].checked and quality == index 
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

function BagCleanUp_OnLoad(self, event, ...)
	self:RegisterForDrag("LeftButton");
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("CHAT_MSG_LOOT")
	self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")	
end

function BagCleanUpTabs_OnLoad(self, event, ...)
	PanelTemplates_SetNumTabs(self, 5);
	PanelTemplates_SetTab(BagCleanUpTabs, 1);
end

function BagCleanUpTabs_OnShow(self, event, ...)	
	PanelTemplates_SetTab(BagCleanUpTabs, BagCleanUpVar.BottomTab);
end

function BagCleanUpInstances:Add(obj)
	if BagCleanUpInstances[self] == nil then
		BagCleanUpInstances[self] = {}
	end
	
	local size = table.getn(BagCleanUpInstances[self])
	BagCleanUpInstances[self][size + 1] = obj
end

function BagCleanUp_OnEvent(self, event, ...)
	if event == "ADDON_LOADED" and ... == "BagClearUp" then
		self:UnregisterEvent("ADDON_LOADED")	
		CreateRarityObjects()
		CreateCheckButtons();	
		CreateSliders();	
		ShowZoneFilter(nil, nil)		
		
	elseif event == "CHAT_MSG_LOOT" and ... ~= nill then	
		if string.find( ... , "You receive item") ~= nil then
			local bulk = string.match( ... , "You receive item: (.+)%.");
			print("bulk:" .. bulk)
			local _, _, dItemID = string.find(bulk, ".*|Hitem:(%d+):.*");
			local _, dItemLink = GetItemInfo(dItemID);
			local zone = GetRealZoneText();
			BagCleanUpInstances.Add(zone, dItemLink)
		elseif string.find( ... , "You receive loot") ~= nil then
			local it = tostring(...)
			local bulk = string.match( ... , "You receive loot: (.+)%.");
			local _, _, dItemID = string.find(bulk, ".*|Hitem:(%d+):.*");
			local _, dItemLink = GetItemInfo(dItemID);
			local zone = GetRealZoneText();
			BagCleanUpInstances.Add(zone, dItemLink)
		end
	elseif event == "MERCHANT_SHOW" then
		_G["BagCleanUpButton"]:Show();
	elseif event == "MERCHANT_CLOSED" then
		_G["BagCleanUpButton"]:Hide();
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
	local color = BagCleanUpColor[BagCleanUpVar.BottomTab]	
	BagCleanUpVar[color][peak] = value;
end

function BagCleanUpSlider_CheckBoxClick(self, button, down)
	local btn = self:GetParent():GetName() .. "CheckButton";		
	local color = BagCleanUpColor[BagCleanUpVar.BottomTab]
	
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
	_G["BagCleanUpCheckButton" .. BagCleanUpColor[BagCleanUpVar.BottomTab]]:Hide();
	
	for index, color in ipairs(BagCleanUpColor) do
		if (parent .. index == self:GetName()) then
			BagCleanUpVar.BottomTab = index		
			BagCleanUpSliderMinSlider:SetValue(BagCleanUpVar[color].min)
			BagCleanUpSliderMaxSlider:SetValue(BagCleanUpVar[color].max)
			BagCleanUpSliderMinCheckButton:SetChecked(BagCleanUpVar[color].minChecked)
			BagCleanUpSliderMaxCheckButton:SetChecked(BagCleanUpVar[color].maxChecked)			
			_G["BagCleanUpCheckButton" .. color]:Show();			
		end
	end	
end

function CreateCheckButtons()
	for index, color in ipairs(BagCleanUpColor) do
		local btn = CreateFrame("CheckButton", "BagCleanUpCheckButton" .. color, BagCleanUp, "UICheckButtonTemplate")
		btn:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 70, -30);
		btn:SetScript("OnClick", BagCleanUpSlider_CheckBoxClick)
		fontstring = btn:CreateFontString("BagCleanUpCheckBtn" .. color .. "FontString", "ARTWORK", "GameFontNormal")
		fontstring:SetTextColor(BagCleanUpColorTexture[3 * index], BagCleanUpColorTexture[3*index + 1], BagCleanUpColorTexture[3 * index + 2] )
		fontstring:SetText("Filter " .. BagCleanUpTypes[index] .. " Items")
		fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
		btn:SetFontString(fontstring)
		btn:Hide();
	end
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
	if BagCleanUpVar.LeftTab == 2 then return end	
	if BagCleanUpVar.BottomTab == nil then BagCleanUpVar.BottomTab = 1 end
	BagCleanUpVar.LeftTab = 2
	local color = BagCleanUpColor[BagCleanUpVar.BottomTab]
	
	_G["BagCleanUpTabs"]:Show();
	_G["BagCleanUpCheckButton" .. color]:SetChecked(BagCleanUpVar[color].checked);
	_G["BagCleanUpCheckButton" .. color]:Show();
	BagCleanUpSliderMinSlider:SetValue(BagCleanUpVar[color].min)
	BagCleanUpSliderMin:Show()
	BagCleanUpSliderMaxSlider:SetValue(BagCleanUpVar[color].max)
	BagCleanUpSliderMax:Show()
	BagCleanUpZone:Hide();		
end

function ShowZoneFilter(self, event)
	for index, color in pairs(BagCleanUpColor) do
		_G["BagCleanUpCheckButton" .. color]:Hide();
	end

	BagCleanUpVar.LeftTab = 1	
	_G["BagCleanUpTabs"]:Hide();
	_G["BagCleanUpSliderMin"]:Hide()
	_G["BagCleanUpSliderMax"]:Hide()
	_G["BagCleanUpZone"]:Show();	
end

function CreateDropDownList()		
	local i = 1;
	for v, k in pairs (BagCleanUpInstances) do
		if v ~= "Add" and v ~= "zone" then
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
	BagCleanUpInstances.zone = self.arg1
	print(size .. " item(s) dropped in " .. self.arg1)
	for n = 1, size do
		print(BagCleanUpInstances[self.arg1][n])
	end	
	 
	if (not checked) then
		UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value);
	end
end





















