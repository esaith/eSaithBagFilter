SLASH_BAGCLEANUP1 = "/clean";
function SlashCmdList.BAGCLEANUP(msg, editbox)
	if BagCleanUp:IsShown() then
		BagCleanUp:Hide();
	else
		BagCleanUp:Show();
	end
end

BagCleanUpVar = 
{
	Gray = false,
	White = false,
	Green = false,
	Blue = false,
	Purple = false,
	
	grayMin = 0,
	grayMax = 0,
	whiteMin = 0,
	whiteMax = 0,
	greenMin = 0,
	greenMax = 0,
	blueMin = 0,
	blueMax = 0,
	purpleMin = 0,
	purpleMax = 0,
	
	tab = 1,
	
	minCheckedgray = false,
	maxCheckedgray = false,
	minCheckedwhite = false,
	maxCheckedwhite = false,
	minCheckedgreen = false,
	maxCheckedgreen = false,
	minCheckedblue = false,
	maxCheckedblue = false,
	minCheckedpurple = false,
	maxCheckedpurple = false
	
}

local BagCleanUpColorTexture = {0,0, .6,.6,.6, 1,1,1, 0,1,0, .2,.2,1, 1,0,1 }
local BagCleanUpColor = { "Gray", "White", "Green", "Blue", "Purple" }
local BagCleanUpTypes = { "Junk", "Common", "Uncommon", "Rare", "Epic"}

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

				if vendorPrice > 0 then -- Skip all items that cannot be sold to vendors								
					if (BagCleanUpVar.Gray == true and quality == 0  
						and PassMin(ilvl, BagCleanUpVar.grayMin, BagCleanUpVar.minCheckedgray) 
						and PassMax(ilvl, BagCleanUpVar.grayMax, BagCleanUpVar.maxCheckedgray)) then
							print (link .. ", rarity: " .. GetRarity(quality) .. ", ilvl: " .. ilvl .. " sold")
							UseContainerItem(bag, slot)
					elseif (BagCleanUpVar.White == true and quality == 1 
						and PassMin(ilvl, BagCleanUpVar.whiteMin, BagCleanUpVar.minCheckedwhite) 
						and PassMax(ilvl, BagCleanUpVar.whiteMax, BagCleanUpVar.maxCheckedwhite)) then
							print (link .. ", rarity: " .. GetRarity(quality) .. ", ilvl: " .. ilvl .. " sold")
							UseContainerItem(bag, slot)
					elseif (BagCleanUpVar.Green == true and quality == 2 
						and PassMin(ilvl, BagCleanUpVar.greenMin, BagCleanUpVar.minCheckedgreen) 
						and PassMax(ilvl, BagCleanUpVar.greenMax, BagCleanUpVar.maxCheckedgreen)) then
							print (link .. ", rarity: " .. GetRarity(quality) .. ", ilvl: " .. ilvl .. " sold")
							UseContainerItem(bag, slot)
					elseif (BagCleanUpVar.Blue   == true and quality == 3 
						and PassMin(ilvl, BagCleanUpVar.blueMin, BagCleanUpVar.minCheckedblue) 
						and PassMax(ilvl, BagCleanUpVar.blueMax, BagCleanUpVar.maxCheckedblue)) then
							print (link .. ", rarity: " .. GetRarity(quality) .. ", ilvl: " .. ilvl .. " sold")
							UseContainerItem(bag, slot)
					elseif (BagCleanUpVar.Purple == true and quality == 4 
						and PassMin(ilvl, BagCleanUpVar.purpleMin, BagCleanUpVar.minCheckedpurple) 
						and PassMax(ilvl, BagCleanUpVar.purpleMax, BagCleanUpVar.maxCheckedpurple)) then
							print (link .. ", rarity: " .. GetRarity(quality) .. ", ilvl: " .. ilvl .. " sold")
							UseContainerItem(bag, slot)
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
end

function BagCleanUp_OnEvent(self, event, ...)
	if event == "ADDON_LOADED" and ... == "BagClearUp" then
		self:UnregisterEvent("ADDON_LOADED")	
		CreateCheckButtons();					
		CreateSliders();	
		if BagCleanUpVar ~= nil then			
			BagCleanUpVar.tab = 1;					
			BagCleanUpSliderMinSlider:SetValue(BagCleanUpVar.grayMin)
			BagCleanUpSliderMaxSlider:SetValue(BagCleanUpVar.grayMax)			
			BagCleanUpCheckButtonGray:SetChecked(BagCleanUpVar.Gray)
			BagCleanUpCheckButtonWhite:SetChecked(BagCleanUpVar.White)
			BagCleanUpCheckButtonGreen:SetChecked(BagCleanUpVar.Green)
			BagCleanUpCheckButtonBlue:SetChecked(BagCleanUpVar.Blue)
			BagCleanUpCheckButtonPurple:SetChecked(BagCleanUpVar.Purple)			
			BagCleanUpSliderMinCheckButton:SetChecked(BagCleanUpVar.minCheckedgray)
			BagCleanUpSliderMaxCheckButton:SetChecked(BagCleanUpVar.maxCheckedgray)
		_G["BagCleanUpCheckButtonGray"]:Show();
		end
	elseif event == "CHAT_MSG_LOOT" and ... ~= nill then	
		if string.find( ... , "You receive item") ~= nil then
			local bulk = string.match( ... , "You receive item: (.+)%.");
			local _, _, dItemID = string.find(bulk, ".*|Hitem:(%d+):.*");
			local _, dItemLink = GetItemInfo(dItemID);
			print("Parsed: " .. dItemLink);
		end
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
	
	if (parent:GetName() == "BagCleanUpSliderMin") then
		if BagCleanUpVar.tab == 1 then
			BagCleanUpVar.grayMin = value;
		elseif BagCleanUpVar.tab == 2 then
			BagCleanUpVar.whiteMin = value;
		elseif BagCleanUpVar.tab == 3 then
			BagCleanUpVar.greenMin = value;
		elseif BagCleanUpVar.tab == 4 then
			BagCleanUpVar.blueMin = value;
		elseif BagCleanUpVar.tab == 5 then
			BagCleanUpVar.purpleMin = value;
		end
	else
		if BagCleanUpVar.tab == 1 then
			BagCleanUpVar.grayMax = value;
		elseif BagCleanUpVar.tab == 2 then
			BagCleanUpVar.whiteMax = value;
		elseif BagCleanUpVar.tab == 3 then
			BagCleanUpVar.greenMax = value;
		elseif BagCleanUpVar.tab == 4 then
			BagCleanUpVar.blueMax = value;
		elseif BagCleanUpVar.tab == 5 then
			BagCleanUpVar.purpleMax = value;
		end		
	end
end

function BagCleanUpSlider_CheckBoxClick(self, button, down)
	local btn = self:GetParent():GetName() .. "CheckButton";		
	
	if (btn .. "Gray" == self:GetName()) then
		BagCleanUpVar.Gray = self:GetChecked();
	elseif (btn .. "White" == self:GetName()) then
		BagCleanUpVar.White = self:GetChecked();
	elseif (btn .. "Green" == self:GetName()) then
		BagCleanUpVar.Green = self:GetChecked();
	elseif (btn .. "Blue" == self:GetName()) then
		BagCleanUpVar.Blue = self:GetChecked();
	elseif (btn .. "Purple" == self:GetName()) then
		BagCleanUpVar.Purple = self:GetChecked();
	elseif string.find(self:GetName(), "Min") ~= nil then
		if BagCleanUpVar.tab == 1 then
			BagCleanUpVar.minCheckedgray = self:GetChecked();
		elseif BagCleanUpVar.tab == 2 then
			BagCleanUpVar.minCheckedwhite = self:GetChecked();
		elseif BagCleanUpVar.tab == 3 then
			BagCleanUpVar.minCheckedgreen = self:GetChecked();
		elseif BagCleanUpVar.tab == 4 then
			BagCleanUpVar.minCheckedblue = self:GetChecked();
		elseif BagCleanUpVar.tab == 5 then
			BagCleanUpVar.minCheckedpurple = self:GetChecked();
		end		
	elseif string.find(self:GetName(), "Max") ~= nil then
		if BagCleanUpVar.tab == 1 then
			BagCleanUpVar.maxCheckedgray = self:GetChecked();
		elseif BagCleanUpVar.tab == 2 then
			BagCleanUpVar.maxCheckedwhite = self:GetChecked();
		elseif BagCleanUpVar.tab == 3 then
			BagCleanUpVar.maxCheckedgreen = self:GetChecked();
		elseif BagCleanUpVar.tab == 4 then
			BagCleanUpVar.maxCheckedblue = self:GetChecked();
		elseif BagCleanUpVar.tab == 5 then
			BagCleanUpVar.maxCheckedpurple = self:GetChecked();
		end
	end
end

function BagCleanUpTab_Click(self, event, ...)		
	local parent = self:GetParent():GetName(); 	
	_G["BagCleanUpCheckButton" .. BagCleanUpColor[BagCleanUpVar.tab]]:Hide();
	
	if (parent .. "Gray" == self:GetName()) then	
		BagCleanUpVar.tab = 1;	
		BagCleanUpSliderMinSlider:SetValue(BagCleanUpVar.grayMin)
		BagCleanUpSliderMaxSlider:SetValue(BagCleanUpVar.grayMax)	
		BagCleanUpSliderMinCheckButton:SetChecked(BagCleanUpVar.minCheckedgray)
		BagCleanUpSliderMaxCheckButton:SetChecked(BagCleanUpVar.maxCheckedgray)		
		_G["BagCleanUpCheckButtonGray"]:Show();
	elseif (parent .. "White" == self:GetName()) then	
		BagCleanUpVar.tab = 2	
		BagCleanUpSliderMinSlider:SetValue(BagCleanUpVar.whiteMin)
		BagCleanUpSliderMaxSlider:SetValue(BagCleanUpVar.whiteMax)		
		BagCleanUpSliderMinCheckButton:SetChecked(BagCleanUpVar.minCheckedwhite)
		BagCleanUpSliderMaxCheckButton:SetChecked(BagCleanUpVar.maxCheckedwhite)
		_G["BagCleanUpCheckButtonWhite"]:Show();
	elseif (parent .. "Green" == self:GetName()) then	
		BagCleanUpVar.tab = 3	
		BagCleanUpSliderMinSlider:SetValue(BagCleanUpVar.greenMin)
		BagCleanUpSliderMaxSlider:SetValue(BagCleanUpVar.greenMax)	
		BagCleanUpSliderMinCheckButton:SetChecked(BagCleanUpVar.minCheckedgreen)
		BagCleanUpSliderMaxCheckButton:SetChecked(BagCleanUpVar.maxCheckedgreen)		
		_G["BagCleanUpCheckButtonGreen"]:Show();
	elseif (parent .. "Blue" == self:GetName()) then	
		BagCleanUpVar.tab = 4
		BagCleanUpSliderMinSlider:SetValue(BagCleanUpVar.blueMin)
		BagCleanUpSliderMaxSlider:SetValue(BagCleanUpVar.blueMax)		
		BagCleanUpSliderMinCheckButton:SetChecked(BagCleanUpVar.minCheckedblue)
		BagCleanUpSliderMaxCheckButton:SetChecked(BagCleanUpVar.maxCheckedblue)
		_G["BagCleanUpCheckButtonBlue"]:Show();
	elseif (parent .. "Purple" == self:GetName()) then		
		BagCleanUpVar.tab = 5
		BagCleanUpSliderMinSlider:SetValue(BagCleanUpVar.purpleMin)
		BagCleanUpSliderMaxSlider:SetValue(BagCleanUpVar.purpleMax)		
		BagCleanUpSliderMinCheckButton:SetChecked(BagCleanUpVar.minCheckedpurple)
		BagCleanUpSliderMaxCheckButton:SetChecked(BagCleanUpVar.maxCheckedpurple)
		_G["BagCleanUpCheckButtonPurple"]:Show();
	end	
end

function CreateCheckButtons()
	local index = 1;
	for _, color in ipairs(BagCleanUpColor) do
		local btn = CreateFrame("CheckButton", "BagCleanUpCheckButton" .. color, BagCleanUp, "UICheckButtonTemplate")
		btn:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 70, -30);
		btn:SetScript("OnClick", BagCleanUpSlider_CheckBoxClick)
		fontstring = btn:CreateFontString("BagCleanUpCheckBtn" .. color .. "FontString", "ARTWORK", "GameFontNormal")
		fontstring:SetTextColor(BagCleanUpColorTexture[3 * index], BagCleanUpColorTexture[3*index + 1], BagCleanUpColorTexture[3 * index + 2] )
		fontstring:SetText("Filter " .. BagCleanUpTypes[index] .. " Items")
		fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
		btn:SetFontString(fontstring)
		btn:Hide();
		index = index + 1;
	end

	_G["BagCleanUpCheckButtonGray"]:Show()
end

function CreateSliders()
	local min = CreateFrame("Frame", "$parentSliderMin", BagCleanUp, "BagCleanUpSliderTemplate")
	min:SetPoint("TOP", "$parent", "TOP", 0, -75)
	_G[min:GetName() .. 'SliderTitle']:SetText("Minimum Item Level");	
	local max = CreateFrame("Frame", "$parentSliderMax", BagCleanUp, "BagCleanUpSliderTemplate")
	max:SetPoint("TOP", "$parentSliderMin", "TOP", 0, -50)
	_G[max:GetName() .. 'SliderTitle']:SetText("Maximum Item Level");		
	end
























-- Notes:
-- Consider a reset/Clear button. 