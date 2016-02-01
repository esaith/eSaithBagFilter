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
	gray = false,
	white = false,
	green = false,
	blue = false,
	purple = false,
	
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
				local itemName, itemLink, itemRarity, ilvl = GetItemInfo(link);
								
				if (BagCleanUpVar.gray == true and quality == 0  
					and PassMin(ilvl, BagCleanUpVar.grayMin, BagCleanUpVar.minCheckedgray) 
					and PassMax(ilvl, BagCleanUpVar.grayMax, BagCleanUpVar.maxCheckedgray)) then
						print (link .. ", rarity: " .. GetRarity(quality) .. ", ilvl: " .. ilvl .. " sold")
						UseContainerItem(bag, slot)
				elseif (BagCleanUpVar.white == true and quality == 1 
					and PassMin(ilvl, BagCleanUpVar.whiteMin, BagCleanUpVar.minCheckedwhite) 
					and PassMax(ilvl, BagCleanUpVar.whiteMax, BagCleanUpVar.maxCheckedwhite)) then
						print (link .. ", rarity: " .. GetRarity(quality) .. ", ilvl: " .. ilvl .. " sold")
						UseContainerItem(bag, slot)
				elseif (BagCleanUpVar.green == true and quality == 2 
					and PassMin(ilvl, BagCleanUpVar.greenMin, BagCleanUpVar.minCheckedgreen) 
					and PassMax(ilvl, BagCleanUpVar.greenMax, BagCleanUpVar.maxCheckedgreen)) then
						print (link .. ", rarity: " .. GetRarity(quality) .. ", ilvl: " .. ilvl .. " sold")
						UseContainerItem(bag, slot)
				elseif (BagCleanUpVar.blue   == true and quality == 3 
					and PassMin(ilvl, BagCleanUpVar.blueMin, BagCleanUpVar.minCheckedblue) 
					and PassMax(ilvl, BagCleanUpVar.blueMax, BagCleanUpVar.maxCheckedblue)) then
						print (link .. ", rarity: " .. GetRarity(quality) .. ", ilvl: " .. ilvl .. " sold")
						UseContainerItem(bag, slot)
				elseif (BagCleanUpVar.white == purple and quality == 4 
					and PassMin(ilvl, BagCleanUpVar.purpleMin, BagCleanUpVar.minCheckedpurple) 
					and PassMax(ilvl, BagCleanUpVar.purpleMax, BagCleanUpVar.maxCheckedpurple)) then
						print (link .. ", rarity: " .. GetRarity(quality) .. ", ilvl: " .. ilvl .. " sold")
						UseContainerItem(bag, slot)
				end
			end
		end
	end				
end

function BagCleanUp_OnLoad(self, event, ...)
	self:RegisterForDrag("LeftButton");
	self:RegisterEvent("ADDON_LOADED")
end

function BagCleanUp_OnEvent(self, event, ...)
	if event == "ADDON_LOADED" and ... == "BagClearUp" then
		self:UnregisterEvent("ADDON_LOADED")	
		if BagCleanUpVar ~= nil then
			BagCleanUpVar.tab = 1;
			CreateCheckButtons();			
			BagCleanUpMinILevelSlider:SetValue(BagCleanUpVar.grayMin)
			BagCleanUpMaxILevelSlider:SetValue(BagCleanUpVar.grayMax)			
			BagCleanUpCheckButtonGray:SetChecked(BagCleanUpVar.gray)
			BagCleanUpCheckButtonWhite:SetChecked(BagCleanUpVar.white)
			BagCleanUpCheckButtonGreen:SetChecked(BagCleanUpVar.green)
			BagCleanUpCheckButtonBlue:SetChecked(BagCleanUpVar.blue)
			BagCleanUpCheckButtonPurple:SetChecked(BagCleanUpVar.purple)			
			BagCleanUpMinILevelCheckButtonMin:SetChecked(BagCleanUpVar.minCheckedgray)
			BagCleanUpMaxILevelCheckButtonMax:SetChecked(BagCleanUpVar.maxCheckedgray)
		_G["BagCleanUpCheckButtonGray"]:Show();
		end
	end	
end

function BagCleanUp_SliderOnLoad(self, event, ...)
	local minSize, maxSize = self:GetMinMaxValues();
	_G[self:GetName() .. 'Low']:SetText(minSize);	
	_G[self:GetName() .. 'High']:SetText(maxSize);	
end

function BagCleanUp_SliderDown(self, event, ...)
	local parent = self:GetParent();	
	local value = _G[parent:GetName() .. "Slider"]:GetValue() - _G[parent:GetName() .. "Slider"]:GetValueStep();
	_G[parent:GetName() .. "Slider"]:SetValue( math.floor(value));
	UpdateMinAndMax(self, math.floor(value));
end

function BagCleanUp_SliderUp(self, event, ...)
	local parent = self:GetParent();
	local value = _G[parent:GetName() .. "Slider"]:GetValue() + _G[parent:GetName() .. "Slider"]:GetValueStep();
	_G[parent:GetName() .. "Slider"]:SetValue(math.floor(value));
	UpdateMinAndMax(self, math.floor(value))	
end

function BagCleanUp_ValueChanged(self, value)
	local parent = self:GetParent();
	_G[parent:GetName() .. "SliderStringValue"]:SetText(math.floor(value));
	UpdateMinAndMax(self, math.floor(value))
end

function UpdateMinAndMax(self, value)
	local parent = self:GetParent();
	
	if (parent:GetName() == "BagCleanUpMinILevel") then
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

function CheckBox_Click(self, button, down)
	local btn = self:GetParent():GetName() .. "CheckButton";		
	
	if (btn .. "Gray" == self:GetName()) then
		BagCleanUpVar.gray = self:GetChecked();
	elseif (btn .. "White" == self:GetName()) then
		BagCleanUpVar.white = self:GetChecked();
	elseif (btn .. "Green" == self:GetName()) then
		BagCleanUpVar.green = self:GetChecked();
	elseif (btn .. "Blue" == self:GetName()) then
		BagCleanUpVar.blue = self:GetChecked();
	elseif (btn .. "Purple" == self:GetName()) then
		BagCleanUpVar.purple = self:GetChecked();
	elseif (btn .. "Min" == self:GetName()) then
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
	elseif (btn .. "Max" == self:GetName()) then
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

local BagCleanUpColorTexture = {0,0, .6,.6,.6, 1,1,1, 0,1,0, .2,.2,1, 1,0,1 }
local BagCleanUpColor = { "Gray", "White", "Green", "Blue", "Purple" }
local BagCleanUpTypes = { "Junk", "Common", "Uncommon", "Rare", "Epic"}

function BagCleanUpTab_Click(self, event, ...)		
	local parent = self:GetParent():GetName(); 	
	_G["BagCleanUpCheckButton" .. BagCleanUpColor[BagCleanUpVar.tab]]:Hide();
	
	if (parent .. "Gray" == self:GetName()) then	
		BagCleanUpVar.tab = 1;	
		BagCleanUpMinILevelSlider:SetValue(BagCleanUpVar.grayMin)
		BagCleanUpMaxILevelSlider:SetValue(BagCleanUpVar.grayMax)	
		BagCleanUpMinILevelCheckButtonMin:SetChecked(BagCleanUpVar.minCheckedgray)
		BagCleanUpMaxILevelCheckButtonMax:SetChecked(BagCleanUpVar.maxCheckedgray)		
		_G["BagCleanUpCheckButtonGray"]:Show();
	elseif (parent .. "White" == self:GetName()) then	
		BagCleanUpVar.tab = 2	
		BagCleanUpMinILevelSlider:SetValue(BagCleanUpVar.whiteMin)
		BagCleanUpMaxILevelSlider:SetValue(BagCleanUpVar.whiteMax)		
		BagCleanUpMinILevelCheckButtonMin:SetChecked(BagCleanUpVar.minCheckedwhite)
		BagCleanUpMaxILevelCheckButtonMax:SetChecked(BagCleanUpVar.maxCheckedwhite)
		_G["BagCleanUpCheckButtonWhite"]:Show();
	elseif (parent .. "Green" == self:GetName()) then	
		BagCleanUpVar.tab = 3	
		BagCleanUpMinILevelSlider:SetValue(BagCleanUpVar.greenMin)
		BagCleanUpMaxILevelSlider:SetValue(BagCleanUpVar.greenMax)	
		BagCleanUpMinILevelCheckButtonMin:SetChecked(BagCleanUpVar.minCheckedgreen)
		BagCleanUpMaxILevelCheckButtonMax:SetChecked(BagCleanUpVar.maxCheckedgreen)		
		_G["BagCleanUpCheckButtonGreen"]:Show();
	elseif (parent .. "Blue" == self:GetName()) then	
		BagCleanUpVar.tab = 4
		BagCleanUpMinILevelSlider:SetValue(BagCleanUpVar.blueMin)
		BagCleanUpMaxILevelSlider:SetValue(BagCleanUpVar.blueMax)		
		BagCleanUpMinILevelCheckButtonMin:SetChecked(BagCleanUpVar.minCheckedblue)
		BagCleanUpMaxILevelCheckButtonMax:SetChecked(BagCleanUpVar.maxCheckedblue)
		_G["BagCleanUpCheckButtonBlue"]:Show();
	elseif (parent .. "Purple" == self:GetName()) then		
		BagCleanUpVar.tab = 5
		BagCleanUpMinILevelSlider:SetValue(BagCleanUpVar.purpleMin)
		BagCleanUpMaxILevelSlider:SetValue(BagCleanUpVar.purpleMax)		
		BagCleanUpMinILevelCheckButtonMin:SetChecked(BagCleanUpVar.minCheckedpurple)
		BagCleanUpMaxILevelCheckButtonMax:SetChecked(BagCleanUpVar.maxCheckedpurple)
		_G["BagCleanUpCheckButtonPurple"]:Show();
	end	
end

function CreateCheckButtons()
	local index = 1;

	for _, color in ipairs(BagCleanUpColor) do
		local btn = CreateFrame("CheckButton", "BagCleanUpCheckButton" .. color, BagCleanUp, "UICheckButtonTemplate")
		btn:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 70, -30);
		btn:SetScript("OnClick", CheckBox_Click)
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

























