SLASH_ESAITHBAGFILTER1 = '/efilter'
local MAX_ITEM_COUNT = -1
local ZONE -- used for updating world coordinates
local OriginalToolTip  -- used to save original functionality to the tooltip. Used for hooking a function
local MAX_BAG_SLOTS = 200    
local eVar -- Short for eSaithBagFilter
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
local LOOT_IMAGES = {
	{"Interface\\GLUES\\CREDITS\\1000px-Coilfangpaintover1", 
	"Interface\\GLUES\\CREDITS\\1000px-Coilfangpaintover2",
	"Interface\\GLUES\\CREDITS\\1000px-Coilfangpaintover4",
	"Interface\\GLUES\\CREDITS\\1000px-Coilfangpaintover5"},
	
	{"Interface\\GLUES\\CREDITS\\Acrest1", 
	"Interface\\GLUES\\CREDITS\\Acrest2",
	"Interface\\GLUES\\CREDITS\\Acrest3",
	"Interface\\GLUES\\CREDITS\\Acrest4"},
	
	{"Interface\\GLUES\\CREDITS\\Axe2Drak1", 
	"Interface\\GLUES\\CREDITS\\Axe2Drak2",
	"Interface\\GLUES\\CREDITS\\Axe2Drak5",
	"Interface\\GLUES\\CREDITS\\Axe2Drak6"},
	
	{"Interface\\GLUES\\CREDITS\\AxeDrak1", 
	"Interface\\GLUES\\CREDITS\\AxeDrak2",
	"Interface\\GLUES\\CREDITS\\AxeDrak5",
	"Interface\\GLUES\\CREDITS\\AxeDrak6"},
	
	{"Interface\\GLUES\\CREDITS\\BE_Building_Two2", 
	"Interface\\GLUES\\CREDITS\\BE_Building_Two3",
	"Interface\\GLUES\\CREDITS\\BE_Building_Two5",
	"Interface\\GLUES\\CREDITS\\BE_Building_Two6"},
	
	{"Interface\\GLUES\\CREDITS\\BladesEdgeMountains1", 
	"Interface\\GLUES\\CREDITS\\BladesEdgeMountains2",
	"Interface\\GLUES\\CREDITS\\BladesEdgeMountains4",
	"Interface\\GLUES\\CREDITS\\BladesEdgeMountains5"},
	
	{"Interface\\GLUES\\CREDITS\\BlastedLands1", 
	"Interface\\GLUES\\CREDITS\\BlastedLands2",
	"Interface\\GLUES\\CREDITS\\BlastedLands4",
	"Interface\\GLUES\\CREDITS\\BlastedLands5"},
		
	{"Interface\\GLUES\\CREDITS\\BloodElf_Priestess_Master1", 
	"Interface\\GLUES\\CREDITS\\BloodElf_Priestess_Master2",
	"Interface\\GLUES\\CREDITS\\BloodElf_Priestess_Master4",
	"Interface\\GLUES\\CREDITS\\BloodElf_Priestess_Master5"},
	
	{"Interface\\GLUES\\CREDITS\\Bloodelf_Two2", 
	"Interface\\GLUES\\CREDITS\\Bloodelf_Two3",
	"Interface\\GLUES\\CREDITS\\Bloodelf_Two5",
	"Interface\\GLUES\\CREDITS\\Bloodelf_Two6"},
	
	{"Interface\\GLUES\\CREDITS\\BloodElf_Webimage1", 
	"Interface\\GLUES\\CREDITS\\BloodElf_Webimage2",
	"Interface\\GLUES\\CREDITS\\BloodElf_Webimage3",
	"Interface\\GLUES\\CREDITS\\BloodElf_Webimage4"},
	
	{"Interface\\GLUES\\CREDITS\\Centaur1", 
	"Interface\\GLUES\\CREDITS\\Centaur2",
	"Interface\\GLUES\\CREDITS\\Centaur4",
	"Interface\\GLUES\\CREDITS\\Centaur5"},
	
	{"Interface\\GLUES\\CREDITS\\DeathKnight501", 
	"Interface\\GLUES\\CREDITS\\DeathKnight502",
	"Interface\\GLUES\\CREDITS\\DeathKnight505",
	"Interface\\GLUES\\CREDITS\\DeathKnight506"},
	
	{"Interface\\GLUES\\CREDITS\\Draenei_Character1", 
	"Interface\\GLUES\\CREDITS\\Draenei_Character2",
	"Interface\\GLUES\\CREDITS\\Draenei_Character3",
	"Interface\\GLUES\\CREDITS\\Draenei_Character4"},
	
	{"Interface\\GLUES\\CREDITS\\Dranei_F_Hair2", 
	"Interface\\GLUES\\CREDITS\\Dranei_F_Hair3",
	"Interface\\GLUES\\CREDITS\\Dranei_F_Hair4",
	"Interface\\GLUES\\CREDITS\\Dranei_F_Hair5"},
	
	{"Interface\\GLUES\\CREDITS\\EpicSwordTGA1", 
	"Interface\\GLUES\\CREDITS\\EpicSwordTGA2",
	"Interface\\GLUES\\CREDITS\\EpicSwordTGA5",
	"Interface\\GLUES\\CREDITS\\EpicSwordTGA6"},
	
	{"Interface\\GLUES\\CREDITS\\Frostwyrm01TGA1", 
	"Interface\\GLUES\\CREDITS\\Frostwyrm01TGA2",
	"Interface\\GLUES\\CREDITS\\Frostwyrm01TGA5",
	"Interface\\GLUES\\CREDITS\\Frostwyrm01TGA6"},
	
	{"Interface\\GLUES\\CREDITS\\gargoyle1", 
	"Interface\\GLUES\\CREDITS\\gargoyle2",
	"Interface\\GLUES\\CREDITS\\gargoyle3",
	"Interface\\GLUES\\CREDITS\\gargoyle4"},
	
	{"Interface\\GLUES\\CREDITS\\Grizzlemaw2TGA2", 
	"Interface\\GLUES\\CREDITS\\Grizzlemaw2TGA3",
	"Interface\\GLUES\\CREDITS\\Grizzlemaw2TGA6",
	"Interface\\GLUES\\CREDITS\\Grizzlemaw2TGA7"},
	
	{"Interface\\GLUES\\CREDITS\\GRIZZLYHILLS2TGA1", 
	"Interface\\GLUES\\CREDITS\\GRIZZLYHILLS2TGA2",
	"Interface\\GLUES\\CREDITS\\GRIZZLYHILLS2TGA5",
	"Interface\\GLUES\\CREDITS\\GRIZZLYHILLS2TGA6"},
	
	{"Interface\\GLUES\\CREDITS\\GrizzlyHills3TGA1", 
	"Interface\\GLUES\\CREDITS\\GrizzlyHills3TGA2",
	"Interface\\GLUES\\CREDITS\\GrizzlyHills3TGA5",
	"Interface\\GLUES\\CREDITS\\GrizzlyHills3TGA6"},
	
	{"Interface\\GLUES\\CREDITS\\Hunter01TGA1", 
	"Interface\\GLUES\\CREDITS\\Hunter01TGA2",
	"Interface\\GLUES\\CREDITS\\Hunter01TGA5",
	"Interface\\GLUES\\CREDITS\\Hunter01TGA6"},
	
	{"Interface\\GLUES\\CREDITS\\Illidan1", 
	"Interface\\GLUES\\CREDITS\\Illidan2",
	"Interface\\GLUES\\CREDITS\\Illidan5",
	"Interface\\GLUES\\CREDITS\\Illidan6"},
	
	{"Interface\\GLUES\\CREDITS\\L60ETC1", 
	"Interface\\GLUES\\CREDITS\\L60ETC2",
	"Interface\\GLUES\\CREDITS\\L60ETC3",
	"Interface\\GLUES\\CREDITS\\L60ETC4"},
	
	{"Interface\\GLUES\\CREDITS\\MaginnisTGA1", 
	"Interface\\GLUES\\CREDITS\\MaginnisTGA2",
	"Interface\\GLUES\\CREDITS\\MaginnisTGA5",
	"Interface\\GLUES\\CREDITS\\MaginnisTGA6"},
	
	{"Interface\\GLUES\\CREDITS\\Magnataur21", 
	"Interface\\GLUES\\CREDITS\\Magnataur22",
	"Interface\\GLUES\\CREDITS\\Magnataur25",
	"Interface\\GLUES\\CREDITS\\Magnataur26"},
	
	{"Interface\\GLUES\\CREDITS\\Mergul011", 
	"Interface\\GLUES\\CREDITS\\Mergul012",
	"Interface\\GLUES\\CREDITS\\Mergul015",
	"Interface\\GLUES\\CREDITS\\Mergul016"},
	
	{"Interface\\GLUES\\CREDITS\\Nightelfcrest1", 
	"Interface\\GLUES\\CREDITS\\Nightelfcrest2",
	"Interface\\GLUES\\CREDITS\\Nightelfcrest3",
	"Interface\\GLUES\\CREDITS\\Nightelfcrest4"},
	
	{"Interface\\GLUES\\CREDITS\\NorthGiant1", 
	"Interface\\GLUES\\CREDITS\\NorthGiant2",
	"Interface\\GLUES\\CREDITS\\NorthGiant5",
	"Interface\\GLUES\\CREDITS\\NorthGiant6"},
	
	{"Interface\\GLUES\\CREDITS\\Orcshield1", 
	"Interface\\GLUES\\CREDITS\\Orcshield2",
	"Interface\\GLUES\\CREDITS\\Orcshield3",
	"Interface\\GLUES\\CREDITS\\Orcshield4"},
	
	{"Interface\\GLUES\\CREDITS\\Revanent21", 
	"Interface\\GLUES\\CREDITS\\Revanent22",
	"Interface\\GLUES\\CREDITS\\Revanent25",
	"Interface\\GLUES\\CREDITS\\Revanent26"},
	
	{"Interface\\GLUES\\CREDITS\\Sanctification1", 
	"Interface\\GLUES\\CREDITS\\Sanctification2",
	"Interface\\GLUES\\CREDITS\\Sanctification5",
	"Interface\\GLUES\\CREDITS\\Sanctification6"},
	
	{"Interface\\GLUES\\CREDITS\\Shivan1", 
	"Interface\\GLUES\\CREDITS\\Shivan2",
	"Interface\\GLUES\\CREDITS\\Shivan3",
	"Interface\\GLUES\\CREDITS\\Shivan4"},
	
	{"Interface\\GLUES\\CREDITS\\Shol021", 
	"Interface\\GLUES\\CREDITS\\Shol022",
	"Interface\\GLUES\\CREDITS\\Shol025",
	"Interface\\GLUES\\CREDITS\\Shol026"},
	
	{"Interface\\GLUES\\CREDITS\\Sword_1H1", 
	"Interface\\GLUES\\CREDITS\\Sword_1H2",
	"Interface\\GLUES\\CREDITS\\Sword_1H5",
	"Interface\\GLUES\\CREDITS\\Sword_1H6"},
	
	{"Interface\\GLUES\\CREDITS\\Tauren1", 
	"Interface\\GLUES\\CREDITS\\Tauren2",
	"Interface\\GLUES\\CREDITS\\Tauren4",
	"Interface\\GLUES\\CREDITS\\Tauren5"},
	
	{"Interface\\GLUES\\CREDITS\\Taurencrest1", 
	"Interface\\GLUES\\CREDITS\\Taurencrest2",
	"Interface\\GLUES\\CREDITS\\Taurencrest3",
	"Interface\\GLUES\\CREDITS\\Taurencrest4"},
	
	{"Interface\\GLUES\\CREDITS\\Tempest_Keep1", 
	"Interface\\GLUES\\CREDITS\\Tempest_Keep2",
	"Interface\\GLUES\\CREDITS\\Tempest_Keep5",
	"Interface\\GLUES\\CREDITS\\Tempest_Keep6"},
	
	{"Interface\\GLUES\\CREDITS\\Tier4_Druid1", 
	"Interface\\GLUES\\CREDITS\\Tier4_Druid2",
	"Interface\\GLUES\\CREDITS\\Tier4_Druid4",
	"Interface\\GLUES\\CREDITS\\Tier4_Druid5"},
	
	{"Interface\\GLUES\\CREDITS\\Troll1", 
	"Interface\\GLUES\\CREDITS\\Troll2",
	"Interface\\GLUES\\CREDITS\\Troll4",
	"Interface\\GLUES\\CREDITS\\Troll5"},
	
	{"Interface\\GLUES\\CREDITS\\Uld_Hall1", 
	"Interface\\GLUES\\CREDITS\\Uld_Hall2",
	"Interface\\GLUES\\CREDITS\\Uld_Hall5",
	"Interface\\GLUES\\CREDITS\\Uld_Hall6"},
	
	{"Interface\\GLUES\\CREDITS\\undeadcrest1", 
	"Interface\\GLUES\\CREDITS\\undeadcrest2",
	"Interface\\GLUES\\CREDITS\\undeadcrest3",
	"Interface\\GLUES\\CREDITS\\undeadcrest4"},
	
	{"Interface\\GLUES\\CREDITS\\Vamp1", 
	"Interface\\GLUES\\CREDITS\\Vamp2",
	"Interface\\GLUES\\CREDITS\\Vamp5",
	"Interface\\GLUES\\CREDITS\\Vamp6"},
	
	{"Interface\\GLUES\\CREDITS\\VrykDoor1", 
	"Interface\\GLUES\\CREDITS\\VrykDoor2",
	"Interface\\GLUES\\CREDITS\\VrykDoor5",
	"Interface\\GLUES\\CREDITS\\VrykDoor6"},
	
	{"Interface\\GLUES\\CREDITS\\Wrathguard1", 
	"Interface\\GLUES\\CREDITS\\Wrathguard2",
	"Interface\\GLUES\\CREDITS\\Wrathguard4",
	"Interface\\GLUES\\CREDITS\\Wrathguard5"},
	
	{"Interface\\GLUES\\CREDITS\\ZulDrak2", 
	"Interface\\GLUES\\CREDITS\\ZulDrak3",
	"Interface\\GLUES\\CREDITS\\ZulDrak6",
	"Interface\\GLUES\\CREDITS\\ZulDrak7"},
	
	{"Interface\\GLUES\\CREDITS\\CATACLYSM\\CHIMERA011", 
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\CHIMERA012",
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\CHIMERA015",
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\CHIMERA016"},
	
	{"Interface\\GLUES\\CREDITS\\CATACLYSM\\FIRELANDS GORGE011", 
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\FIRELANDS GORGE012",
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\FIRELANDS GORGE015",
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\FIRELANDS GORGE016"},
	
	{"Interface\\GLUES\\CREDITS\\CATACLYSM\\GOBLIN_INN01A1", 
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\GOBLIN_INN01A2",
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\GOBLIN_INN01A5",
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\GOBLIN_INN01A6"},
	
	{"Interface\\GLUES\\CREDITS\\CATACLYSM\\GREYMANE_LIGHTHOUSE_0031", 
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\GREYMANE_LIGHTHOUSE_0032",
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\GREYMANE_LIGHTHOUSE_0035",
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\GREYMANE_LIGHTHOUSE_0036"},
	
	{"Interface\\GLUES\\CREDITS\\CATACLYSM\\LESSERELEMENTAL_FIRE_03B1", 
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\LESSERELEMENTAL_FIRE_03B2",
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\LESSERELEMENTAL_FIRE_03B5",
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\LESSERELEMENTAL_FIRE_03B6"},
	
	{"Interface\\GLUES\\CREDITS\\CATACLYSM\\TIER11_HUNTER011", 
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\TIER11_HUNTER012",
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\TIER11_HUNTER015",
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\TIER11_HUNTER016"},
	
	{"Interface\\GLUES\\CREDITS\\CATACLYSM\\TIER11_WARRIOR011", 
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\TIER11_WARRIOR012",
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\TIER11_WARRIOR015",
	"Interface\\GLUES\\CREDITS\\CATACLYSM\\TIER11_WARRIOR016"},
	
	{"Interface\\GLUES\\CREDITS\\Pandaria\\DruidChallenge1", 
	"Interface\\GLUES\\CREDITS\\Pandaria\\DruidChallenge2",
	"Interface\\GLUES\\CREDITS\\Pandaria\\DruidChallenge5",
	"Interface\\GLUES\\CREDITS\\Pandaria\\DruidChallenge6"},
	
	{"Interface\\GLUES\\CREDITS\\Pandaria\\Tier13_Priest011", 
	"Interface\\GLUES\\CREDITS\\Pandaria\\Tier13_Priest012",
	"Interface\\GLUES\\CREDITS\\Pandaria\\Tier13_Priest015",
	"Interface\\GLUES\\CREDITS\\Pandaria\\Tier13_Priest016"},
	
	{"Interface\\GLUES\\CREDITS\\Pandaria\\Tier14_Monk011", 
	"Interface\\GLUES\\CREDITS\\Pandaria\\Tier14_Monk012",
	"Interface\\GLUES\\CREDITS\\Pandaria\\Tier14_Monk015",
	"Interface\\GLUES\\CREDITS\\\Pandaria\\Tier14_Monk016"},
	
}
local BACKGROUND_STRINGS = {
	"bg-deathknight-blood",	"bg-deathknight-frost", "bg-deathknight-unholy", "bg-druid-balance", "bg-druid-bear", "bg-druid-cat", "bg-druid-restoration",
	"bg-hunter-beastmaster", "bg-hunter-marksman", "bg-hunter-survival", "bg-hunter-survival", "bg-mage-fire", "bg-mage-frost", "bg-monk-battledancer", 
	"bg-monk-brewmaster", "bg-monk-mistweaver", "bg-paladin-protection", "bg-paladin-retribution", "bg-priest-discipline", 
	"bg-priest-holy", "bg-priest-shadow", "bg-rogue-assassination", "bg-rogue-combat", "bg-rogue-subtlety", "bg-shaman-elemental", "bg-shaman-enhancement", 
	"bg-shaman-restoration", "bg-warlock-affliction", "bg-warlock-demonology", "bg-warlock-destruction", "bg-warrior-arms", "bg-warrior-fury", "bg-warrior-protection", "DeathKnightUnholy-TopLeft"	, "HunterSurvival-TopLeft", "PALADINHOLY-TOPLEFT", "PriestHoly-TopLeft", "PriestDiscipline-TopLeft", 
	"RogueSubtlety-TopLeft"
}
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
        
        local _, _, quality = GetItemInfo(link)
        -- If 'Keep all BOE' items is checked then automatically add them to the kept list. Requires quality 3 or higher (green)
        -- This is to help prevent all white items automatically included in which 
        if eVar.properties.KeepAllBOE and quality and quality >= 2 then            
            eVar.properties.keep[link] = true
        end
	end
	return OriginalToolTip(self, ...)
end
local function ResetAlphaOnAllButtons()
	for index = 1, MAX_ITEM_COUNT do
		local btn = _G["eSaithBagFilterLootFrameSellItem" .. index]
		if _G["eSaithBagFilterLootFrameSellItem" .. index] and _G["eSaithBagFilterLootFrameSellItem" .. index]:IsShown() then
			if eVar.properties.keep[_G["eSaithBagFilterLootFrameSellItem" .. index].link] or eVar.properties.keepTradeGoods[_G["eSaithBagFilterLootFrameSellItem" .. index].link] then
				_G["eSaithBagFilterLootFrameSellItem" .. index]:SetAlpha(ALPHA)
			else
				_G["eSaithBagFilterLootFrameSellItem" .. index]:SetAlpha(1)              
			end
		end
	end
end
local function AddLoot(link, quality)	local zone = GetRealZoneText()
	if eInstanceLoot[zone] == nil then eInstanceLoot[zone] = { } end
	eInstanceLoot[zone][link] = true   
	GameTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	GameTooltip:SetHyperlink(link)    
	GameTooltip:Show()   
	GameTooltip:Hide()    
end
local function ToggleGreenBOEItems()
	eVar.properties.EnableBOEGreen = eSaithBagFilterOptionsFrameOptions_BOEGreenItems:GetChecked()
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
local function KeepAllBOEOnEnter(self, motion)
    PrepreToolTip(self)
	GameTooltip:AddLine("Default all BOE of Uncommon (Green) quality or greater \nto be saved in characters kept list")
	GameTooltip:Show()
end
local function QuestCompleteOnEnter(self, motion)
    PrepreToolTip(self)
	GameTooltip:AddLine("Quickly obtains and complete quests.\nQuest rewards are chosen at random.")
	GameTooltip:Show()
end
local function CoordinatesOnEnter(self, motion)
    PrepreToolTip(self)
	GameTooltip:AddLine("Shows (x, y) coordinates under mini-map")
	GameTooltip:Show()
end
local function AutoSellGrayOnEnter(self, motion)
    PrepreToolTip(self)
	GameTooltip:AddLine("Auto sells all Poor (Green) items \nto the vendor upon opening their merchant window")
	GameTooltip:Show()
end
local function GreenBOEItemsOnEnter(self, motion)
    PrepreToolTip(self)
	GameTooltip:AddLine("Include Uncommon (Green) items in the BOE section")
	GameTooltip:Show()
end
local function AutoGreedGreenItemsOnEnter(self, motion)
    PrepreToolTip(self)
	GameTooltip:AddLine("The Need or Greed pop-up is disabled for BOP and BOE items,\nand is automatically auto-greeded.")
	GameTooltip:Show()
end
local function KeepTradeGoodsOnEnter(self, motion)
    PrepreToolTip(self)
	GameTooltip:AddLine("Trade good items will not be sold regardless if in kept list.")
	GameTooltip:Show()
end
local function iLevelSlidersOnEnter(self, motion)
    PrepreToolTip(self)
	GameTooltip:AddLine("Turns on item level sliders per rarity.")
	GameTooltip:Show()
end
local function FrameLootBackgroundOnEnter(self, motion)
    PrepreToolTip(self)
	GameTooltip:AddLine("Disables background for easier viewing.")
	GameTooltip:Show()
end
local function LootContainersOnEnter(self, motion)
    PrepreToolTip(self)
	GameTooltip:AddLine("Auto loot containers that do not have a cast time. \n(e.g. Unlocked lock boxes, clams, etc) Does not work on salvage items")
	GameTooltip:Show()
end
local function OptionsOnEnter(self, event, ...)
	PrepreToolTip(self)
	GameTooltip:AddLine("Options")
	GameTooltip:Show()
end
function eSaithBagFilter_SellButton_OnEnter(self, event, ...)
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
		if eVar.properties.BottomTab == 1 then
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
	local array = { "Filter By Zone", "Characters Log", "Options Tab" }
	PrepreToolTip(self)
	GameTooltip:AddLine(array[self:GetID()])
	GameTooltip:Show()
end

local function UpdateCoordinates(self, elapsed)
	if not eVar.properties.EnableCoordinates then return end
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
local function ToggleCoordinates(self, event, button)
	eVar.properties.EnableCoordinates = eSaithBagFilterOptionsFrameOptions_Coordinates:GetChecked()

	if eSaithBagFilterOptionsFrameOptions_Coordinates:GetChecked() then
		eSaithBagFilterCoordinates:Show()
	else
		eSaithBagFilterCoordinates:Hide()
	end
end
local function PassMin(ilevel, minlvl, required)
	return not required or ilevel >= minlvl
end
local function PassMax(ilevel, maxlvl, required)
	return not required or ilevel <= maxlvl
end
local function CreateItemButton(item, index, xoffset, yoffset)	
	local btn = _G["eSaithBagFilterLootFrameSellItem" .. index]
	btn:SetPoint("TOPLEFT", "eSaithBagFilterLootFrame", "TOPLEFT", 41 * xoffset - 27, -yoffset * 45 - 5)
	btn.texture = _G[btn:GetName() .. "Texture"]
	btn.texture:Show()
	btn.texture:SetTexture(item.text)
	btn.texture = _G[btn:GetName() .. "TextureBorder"]
	btn.texture:Show()
	btn.texture:SetColorTexture(eVar.properties.texture[3 * item.colorIndex], eVar.properties.texture[3 * item.colorIndex + 1], eVar.properties.texture[3 * item.colorIndex + 2], 1)
	btn:Show()
	btn.link = item.link
end
local function ChangeItemsPerRow(count)
	if count < 11 then count = 11 end
	if count > 20 then count = 20 end
	eVar.properties.MAX_ITEMS_PER_ROW = math.ceil(count)
	
	-- Change frame loot dependent on the number of items per row
	local width = 30 + count * 40
	local corners = {"TOPLEFT", 'TOPRIGHT', 'BOTTOMLEFT', 'BOTTOMRIGHT'}
	eSaithBagFilterLootFrame:SetSize(width, width * 5 / 6)
	for i = 1, 4 do
		_G['eSaithBagFilterLootFrameTexture'..corners[i]]:SetSize(eSaithBagFilterLootFrame:GetWidth()/2, eSaithBagFilterLootFrame:GetHeight()/2)
	end
end
local function ShowListedItems(count)

	-- Try to keep the lootframe square. Not too small or too large
	ChangeItemsPerRow(math.ceil(math.sqrt(count)) + 5)
	-- Hide old items prior to showing updated list
	for i = 1, MAX_ITEM_COUNT do
		_G["eSaithBagFilterLootFrameSellItem" .. i]:Hide()
	end
	MAX_ITEM_COUNT = count
	if eVar.properties.sell == nil then return end
	
	local MAX_ROW = eVar.properties.MAX_ITEMS_PER_ROW
	local yoffset = 0
	local xoffset = 1
	local list = eVar.properties.sell
	local color_found  -- finds the next item in the loot bag that is the current color in index
	local begin_height
	local boe = nil
	local ButtonIndex = 0
	local base = 155
	
	for _index, color in pairs(eVar.properties.colors) do
		color_found = false
		begin_height = yoffset
		for link, props in pairs(eVar.properties.sell) do			
			if tostring(list[link].colorIndex) == tostring(_index) then				
				if xoffset % (MAX_ROW + 1) == 0 then
					yoffset = yoffset + .85
					xoffset = 1
				end
				
				if eInstances.boe[link] and (list[link].colorIndex > 3  or (eVar.properties.EnableBOEGreen and list[link].colorIndex > 2)) then    
					if boe == nil then boe = { } end	
					boe[link] = eVar.properties.sell[link]
				else					
					ButtonIndex = ButtonIndex + 1
					CreateItemButton(list[link], ButtonIndex, xoffset, yoffset)
					xoffset = xoffset + 1
					color_found = true      
				end
			end
		end
		
		local texture = _G["eSaithBagFilterLootTextureTypeBackgroundColor"..eVar.properties.types[_index]]
		if color_found then -- Create background only for rarities that are listed
			yoffset = yoffset + 1
			texture:SetPoint("LEFT", "$parent", "LEFT", 8, 0)
			texture:SetPoint("RIGHT", "$parent", "RIGHT", -10, 0)
			texture:SetPoint("TOP", "$parent", "TOP", 0, -begin_height * 45 - 1)
			texture:SetHeight( (yoffset - begin_height) * 45 )
			texture:Show()            
		else
			texture:Hide()
		end  
		xoffset = 1
	end
		-- Append BOE items at the end
	local frameHeight = -begin_height * 45 + 5 - ((yoffset - begin_height) * 45 +15)
	begin_height = yoffset
	if boe ~= nil then
		zoffset = 1
		local fontstring = eSaithBagFilterLootFrameBOEFontString
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
		eSaithBagFilterLootFrameBOEFontString:Hide()
	end
end
local function SelectItems()
	eVar.properties.sell = { }
	local zone = eVar.properties.zone
	local zoneTable = eInstanceLoot[zone]
	if zoneTable == nil then return end
	
	local texture, locked, quality, lootable, link, ItemName, ilevel
	local count = 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			texture, _, locked, quality, _, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then
				ItemName, _, _, ilevel, _, _, _, _, _, _, vendorPrice = GetItemInfo(link)		
				if vendorPrice and vendorPrice > 0 and not locked and not lootable then
					-- Skip all items that cannot be sold to vendors					
					local _type = eVar.properties.types[quality + 1]					
					if _type ~= nil and _G["eSaithBagFilterCheckButton" .. _type]:GetChecked()						
					and PassMin(ilevel, eVar[_type].min, eVar[_type].minChecked)
					and PassMax(ilevel, eVar[_type].max, eVar[_type].maxChecked) 
					and (zoneTable[link] or zone == "ALL") then
						count = count + 1
						eVar.properties.sell[link] = { link = link, text = texture, colorIndex = quality + 1, itemName = ItemName }
						
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

local function LootContainers()
	eVar.properties.EnableAutoLoot = true
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
		eVar.properties.EnableAutoLoot = false
	end
end
local function SellListedItems(list)
	local total = 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, count, locked, quality, readable, lootable, link, isFiltered = GetContainerItemInfo(bag, slot)					
			if texture then 				
				if list[link] then 	
					local _, _, _, ilevel, _, class, _, _, _, _, vendorPrice = GetItemInfo(link)
					local _type = eVar.properties.types[quality + 1]	
					if PassMin(ilevel, eVar[_type].min, eVar[_type].minChecked) 
					and PassMax(ilevel, eVar[_type].max, eVar[_type].maxChecked)
					and not (eVar.properties.keep[link] or eVar.properties.keepTradeGoods[link]) then
						if not locked then UseContainerItem(bag, slot) end 	
						total = total + 1
                        UIErrorsFrame:Clear()
					end
				end					
			end
		end
	end	
	return total
end
local function ToggleAutoSellGray()
	eVar.properties.EnableAutoSellGrays = eSaithBagFilterOptionsFrameOptions_AutoSellGray:GetChecked()
end
local function SellByQuality(_type)
	eVar.properties.SellTypeList = {}
	local texture, locked, quality, lootable, link, vendorPrice, personalItem
	eVar.properties.SellTypeList = { }
	
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			texture, _, locked, quality, _, lootable, link = GetContainerItemInfo(bag, slot)
			if texture then
				_, _, _, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(link)
				personalItem = eVar.properties.keep[link] or eVar.properties.keepTradeGoods[link]
				if (personalItem == nil or not personalItem) and not (locked or lootable) and vendorPrice > 0 and quality < 5 then
					if eVar.properties.types[quality + 1] == _type then
						if eVar.properties.SellTypeList[link] == nil then eVar.properties.SellTypeList[link] = true end                        
					end
				end
			end
		end
	end
	eVar.properties.IsSellingGrays = true
	SellListedItems(eVar.properties.SellTypeList)
end
local function ToggleAutoGreedGreenItems()
	eVar.properties.EnableAutoGreedGreenItems = eSaithBagFilterOptionsFrameOptions_AutoGreedGreen:GetChecked()
end
local function ToggleKeepTradeGoods()
	eVar.properties.IsTradeGoodKept = eSaithBagFilterOptionsFrameCheckButton_TradeGoods:GetChecked()
	eVar.properties.keepTradeGoods = { } 
end
local function ToggleiLevelSliders()
	eVar.properties.EnableiLevelSliders = eSaithBagFilterOptionsFrameCheckButton_EnableiLevel:GetChecked()
	
	-- if disabling then uncheck each of the sliders
	if eVar.properties.EnableiLevelSliders then
		for index, _type in ipairs(eVar.properties.types) do
			_G["eSaithBagFilterSliderMax".._type]:Show()	
			_G["eSaithBagFilterSliderMin".._type]:Show()						
		end		
	else
		for index, _type in ipairs(eVar.properties.types) do
			_G["eSaithBagFilterSliderMax".._type.."CheckButton"]:SetChecked(false)
			_G["eSaithBagFilterSliderMin".._type.."CheckButton"]:SetChecked(false)		
			_G["eSaithBagFilterSliderMin".._type]:Hide()	
			_G["eSaithBagFilterSliderMax".._type]:Hide()			
			eVar[_type].minChecked = false
			eVar[_type].maxChecked = false
		end				
	end
	SelectItems()
end
local function ToggleOptionsFrame()
    -- Hide everything but options when it is open. 

	if eSaithBagFilterOptionsFrame:IsShown() then 
        eSaithBagFilterLootFrame:Show()
        eSaithBagFilter_BottomTabs:Show()        
        if MerchantFrame:IsShown() then eSaithBagFilterSellButton:Show() end
		eSaithBagFilterOptionsFrame:Hide()
	else
        eSaithBagFilter_BottomTabs:Hide()
		eSaithBagFilterLootFrame:Hide()
        eSaithBagFilterSellButton:Hide()
		eSaithBagFilterOptionsFrame:Show()
	end
end
local function ToggleFrameLootBackground()
	eVar.properties.EnableFrameLootBackground = eSaithBagFilterOptionsFrameCheckButton_EnableLootFrameBackground:GetChecked()
	local corners ={"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}
	
	for i = 1, 4 do
		local corner =  _G["eSaithBagFilterLootFrameTexture"..corners[i]]
		if eVar.properties.EnableFrameLootBackground then
			corner:Show()
		else
			corner:Hide()
		end
	end
end
local function ToggleKeepAllBOE()
    eVar.properties.KeepAllBOE = eSaithBagFilterOptionsFrameCheckButton_KeepAllBOE:GetChecked()
    local _, quality
    
    -- If checked, loop through all BOE items and all them to the saved list that has a quality of 2 (green) or higher.    
    if eVar.properties.KeepAllBOE then 
        for link, value in pairs(eInstances.boe) do           
            _, _, quality = GetItemInfo(link)         
            if quality ~= nil and quality >= 2 then      
                eVar.properties.keep[link] = true
            end
        end
    end
    SelectItems()
end
local function ToggleQuestComplete()
    eVar.properties.QuestComplete = eSaithBagFilterOptionsFrameCheckButton_QuestComplete:GetChecked()
end
local function eSaithBagFilterCheckBox_Click(self, button, down)
	local _type = string.match(self:GetName(), "eSaithBagFilterCheckButton(.*)")
	if eVar[_type] ~= nil then
		eVar[_type].checked = self:GetChecked()
	end
	SelectItems()
end

local function CreateLootFrameBackground(topleft, topright, bottomleft, bottomright)
	local frame = eSaithBagFilterLootFrame
	local bkAlpha = .7
	
	frame.texture = frame:CreateTexture("$parentTextureTOPLEFT", "ARTWORK")
	frame.texture:SetTexture(topleft)
	frame.texture:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 0, 0)
	frame.texture:SetSize(frame:GetWidth()/2, frame:GetHeight()/2)
	frame.texture:SetAlpha(bkAlpha)
	frame.texture:Show()
	
	frame.texture = frame:CreateTexture("$parentTextureTOPRIGHT", "ARTWORK")
	frame.texture:SetTexture(topright)
	frame.texture:SetPoint("TOPRIGHT", "$parent", "TOPRIGHT", 0, 0)
	frame.texture:SetSize(frame:GetWidth()/2, frame:GetHeight()/2)
	frame.texture:SetAlpha(bkAlpha)
	frame.texture:Show()
	
	frame.texture = frame:CreateTexture("$parentTextureBOTTOMLEFT", "ARTWORK")
	frame.texture:SetTexture(bottomleft)
	frame.texture:SetPoint("BOTTOMLEFT", "$parent", "BOTTOMLEFT", 0, 0)
	frame.texture:SetSize(frame:GetWidth()/2, frame:GetHeight()/2)
	frame.texture:SetAlpha(bkAlpha)
	frame.texture:Show()
	
	frame.texture = frame:CreateTexture("$parentTextureBOTTOMRIGHT", "ARTWORK")
	frame.texture:SetTexture(bottomright)
	frame.texture:SetPoint("BOTTOMRIGHT", "$parent", "BOTTOMRIGHT", 0, 0)
	frame.texture:SetSize(frame:GetWidth()/2, frame:GetHeight()/2)
	frame.texture:SetAlpha(bkAlpha)
	frame.texture:Show()

	frame.texture = frame:CreateTexture("$parentTextureBackground", "BACKGROUND")
	frame.texture:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble")	
	frame.texture:SetAllPoints()
	frame.texture:Show()
end

local function CreateMainButtons()
	local frame = CreateFrame("Frame", "$parentLootFrame", eSaithBagFilter)
	frame:SetPoint("TOPLEFT", "$parent", "TOPRIGHT", 0, 0)
	frame:SetSize(460, 375)
	
	local random = time() % 55 + 1									
	CreateLootFrameBackground(LOOT_IMAGES[random][1], LOOT_IMAGES[random][2], LOOT_IMAGES[random][3], LOOT_IMAGES[random][4])	
	frame:Show()

	local width = eSaithBagFilter:GetWidth()
	local fontstring, btn, min, max
	local rarity_spacing = 30
	local top_rarity_location = 80
	local _index = 1
	local prior_type = eSaithBagFilter
	local main_prior_color_type = eSaithBagFilter
	local loot_prior_color_type = eSaithBagFilterLootFrame
        
	-- Create main widgets on main page
	for index, _type in ipairs(eVar.properties.types) do
			-- Create Main checkboxes types
		btn = CreateFrame("CheckButton", "$parentCheckButton".._type, eSaithBagFilter, "UICheckButtonTemplate")
		btn:SetPoint("TOP", prior_type, "BOTTOM", 0, -rarity_spacing * 1.4)
		btn:SetSize(20, 20)
		btn:SetScript("OnClick", eSaithBagFilterCheckBox_Click)
		fontstring = btn:CreateFontString("eSaithBagFilterCheckButton".._type.."FontString", "ARTWORK", "GameFontNormal")
		fontstring:SetTextColor(eVar.properties.texture[3 * index], eVar.properties.texture[3 * index + 1], eVar.properties.texture[3 * index + 2])
		fontstring:SetText("Filter ".._type.." Items")
		fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
        btn:SetFontString(fontstring)
		btn:Show()
		prior_type = "$parentCheckButton".._type
		
		-- Create sliders for min/max ilevels
		max = CreateFrame("Frame", "$parentSliderMax".._type, eSaithBagFilter, "eSaithBagFilterSliderTemplate")
		max:SetPoint("LEFT", "$parentCheckButton".._type, "RIGHT", 135, -11)		
		_G[max:GetName()..'SliderTitle']:SetText("Max")
		max:Show()
		
		min = CreateFrame("Frame", "$parentSliderMin".._type, eSaithBagFilter, "eSaithBagFilterSliderTemplate")
		min:SetPoint("LEFT", "$parentCheckButton".._type, "RIGHT", 135, 19)		
		_G[min:GetName()..'SliderTitle']:SetText("Min")
		min:Show()
		
		--main frame types background colors
		local frame = CreateFrame("Frame", "$parentTypeBackgroundColor".._type, eSaithBagFilter)
		frame:SetPoint("LEFT", "$parent", "LEFT", 8, 0)
		frame:SetPoint("RIGHT", "$parent", "RIGHT", -10, 0)
		frame:SetPoint("TOP", main_prior_color_type, "BOTTOM", 0, -2)
		frame:SetHeight(rarity_spacing * 2)
		frame.texture = frame:CreateTexture("$parentTexture", "BACKGROUND")
		frame.texture:SetColorTexture(eVar.properties.texture[3 * _index], eVar.properties.texture[3 * _index + 1], eVar.properties.texture[3 * _index + 2], ALPHA)
		frame.texture:SetAllPoints()
		frame.texture:Show()
		frame:Show()
		main_prior_color_type = "$parentTypeBackgroundColor".._type
		
		--loot frame types background colors
		local texture = eSaithBagFilterLootFrame:CreateTexture("eSaithBagFilterLootTextureTypeBackgroundColor".._type, ARTWORK)
		texture:SetPoint("LEFT", "$parent", "LEFT", 8, 0)
		texture:SetPoint("RIGHT", "$parent", "RIGHT", -10, 0)
		texture:SetPoint("TOP", loot_prior_color_type, "BOTTOM", 0, -2)
		texture:SetHeight(rarity_spacing * 2)
		texture:SetColorTexture(eVar.properties.texture[3 * _index], eVar.properties.texture[3 * _index + 1], eVar.properties.texture[3 * _index + 2], ALPHA)
		texture:Hide()
		loot_prior_color_type = "eSaithBagFilterLootTextureTypeBackgroundColor".._type
		
		_index = _index + 1
		
	end		
	eSaithBagFilterCheckButtonPoor:ClearAllPoints()
	eSaithBagFilterCheckButtonPoor:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 10, -top_rarity_location)
	eSaithBagFilterTypeBackgroundColorPoor:SetPoint("TOP", "$parent", "TOP", 0, -top_rarity_location / 1.4)
	eSaithBagFilterLootTextureTypeBackgroundColorPoor:SetPoint("TOP", "$parent", "TOP", 0, -3)
	
	-- Options Frame
	local frame = CreateFrame("Frame", "$parentOptionsFrame", eSaithBagFilter)
	frame:SetPoint("TOP", "$parent", "TOP", 0, -55)
	frame:SetSize(eSaithBagFilter:GetWidth() *.965, eSaithBagFilter:GetHeight() * .83)
	frame:SetFrameLevel(10)
	frame.texture = frame:CreateTexture("$parentTexture", "BACKGROUND");
	frame.texture:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble")
	frame.texture:SetAllPoints()
	frame.texture:Show()	
	frame:Hide()
	
	-- Options button
	local btn = CreateFrame("Button", "$parentOptionsButton", eSaithBagFilter, "eSaithBagFilterItemButtonTemplate")
	btn:SetSize(25, 25)
	btn:SetPoint("TOPRIGHT", "$parent", "TOPRIGHT", -15, -30)
	btn:SetScript("OnClick", ToggleOptionsFrame)
	btn:SetScript("OnEnter", OptionsOnEnter)
	btn:SetScript("OnLeave", OnGameToolTipLeave)
	btn.texture = btn:CreateTexture("$parentTexture", "OVERLAY");
	btn.texture:SetTexture("Interface\\HELPFRAME\\HelpIcon-CharacterStuck")
	btn.texture:SetAlpha(.6)
	btn.texture:SetAllPoints()
	btn.texture:Show()
	btn:Show()
	
	-- Reset button
	local btn = CreateFrame("Button", "$parent_ResetButton", eSaithBagFilterOptionsFrame, "UIPanelButtonTemplate")
	btn:SetSize(100, 30)
	btn:SetPoint("BOTTOMRIGHT", "$parent", "BOTTOMRIGHT", -15, 15)
	btn:SetScript("OnClick", eSaithBagFilterResetButton_Click)
	fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText("|cffffffffReset Addon")
	fontstring:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
	fontstring:Show()
	btn:Show()

	-- Create as many buttons for as many items that could possibly sell
	for i = 1, MAX_BAG_SLOTS do
		local btn = CreateFrame("Button", "$parentSellItem" .. i, eSaithBagFilterLootFrame, "eSaithBagFilterItemButtonTemplate")
		btn:SetPoint("CENTER", "$parent", "CENTER", i, i)
		btn:SetSize(35, 35)
		btn.texture = btn:CreateTexture("$parentTexture", "OVERLAY");
		btn.texture:SetTexture("Interface\ICONS\INV_Misc_QuestionMark");
		btn.texture:SetSize(35, 35)
		btn.texture:SetAllPoints();
		btn.texture = btn:CreateTexture("$parentTextureBorder", "ARTWORK");
		btn.texture:SetColorTexture(1, 1, 1, 1)
		btn.texture:SetSize(10, 10)
		btn.texture:SetAllPoints()
		btn:SetScript("OnClick", ItemButton_OnPress)
		btn:SetScript("OnEnter", ItemButton_OnEnter)
		btn:SetScript("OnLeave", OnGameToolTipLeave)
		btn:Hide(); 
	end
    
	 -- BOE font string
	fontstring = eSaithBagFilterLootFrame:CreateFontString("$parentBOEFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText("|cff02DBDBBind On Equip Items:")
	
	-- Just create the fontstring for now. They will be used later on when player views save dungeons/raid listing 
	eSaithBagFilterLootFrame:CreateFontString("$parentInstanceInfoFontStringTitle", "ARTWORK", "GameFontNormal")
	eSaithBagFilterLootFrame:CreateFontString("$parentInstanceInfoFontStringFreshTitle", "ARTWORK", "GameFontNormal")
	eSaithBagFilterLootFrame:CreateFontString("$parentInstanceInfoFontStringFreshList", "ARTWORK", "GameFontNormal")
	eSaithBagFilterLootFrame:CreateFontString("$parentInstanceInfoFontStringSavedTitle", "ARTWORK", "GameFontNormal")
	eSaithBagFilterLootFrame:CreateFontString("$parentInstanceInfoFontStringSavedList", "ARTWORK", "GameFontNormal")
	
	-- Coordinates
	frame = CreateFrame("Frame", "eSaithBagFilterCoordinates", UIParent)
	frame:SetSize(100, 50)
	frame:SetPoint("TOP", "Minimap", "BOTTOM", 5, -5)
	frame:SetScript("OnUpdate", UpdateCoordinates)
	fontstring = frame:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText("|cff33ff33")
	fontstring:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
	fontstring:Show()
end	
local function CreateOptionButtons()
    local OptionsColor = "|cff2bc3e2"
	-- Loot containers
	local btn = CreateFrame("Button", "$parentLootButton", eSaithBagFilterOptionsFrame, "UIPanelButtonTemplate")
	btn:SetSize(125, 30)
	btn:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 14, 29)
	btn:SetScript("OnClick", LootContainers)
    btn:SetScript("OnEnter", LootContainersOnEnter)
    btn:SetScript("OnLeave", OnGameToolTipLeave)
	fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText("|cffffffffLoot Containers")
	fontstring:SetPoint("CENTER", "$parent", "CENTER", 0, 0)
	fontstring:Show()	
	btn:Show()
	
	 -- Coordinates
	local btn = CreateFrame("CheckButton", "$parentOptions_Coordinates", eSaithBagFilterOptionsFrame, "UICheckButtonTemplate")
	btn:SetPoint("TOPLEFT", "$parent", "TOPLEFT", 10, -15)
	btn:SetScript("OnClick", ToggleCoordinates)
    btn:SetScript("OnEnter", CoordinatesOnEnter)
    btn:SetScript("OnLeave", OnGameToolTipLeave)
	fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText(OptionsColor.."Coordinates|r")
	fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
	btn:SetFontString(fontstring)
	btn:SetChecked(eVar.properties.EnableCoordinates)
	ToggleCoordinates()
	btn:Show()
	
	-- Auto Sell Gray items checkbox
	local btn = CreateFrame("CheckButton", "$parentOptions_AutoSellGray", eSaithBagFilterOptionsFrame, "UICheckButtonTemplate")
	btn:SetPoint("LEFT", "$parentOptions_Coordinates", "RIGHT", 175, 0)
	btn:SetScript("OnClick", ToggleAutoSellGray)
    btn:SetScript("OnEnter", AutoSellGrayOnEnter)
    btn:SetScript("OnLeave", OnGameToolTipLeave)
	fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText(OptionsColor.."Auto-Sell Junk|r")
	fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
	btn:SetFontString(fontstring)
	btn:SetChecked(eVar.properties.EnableAutoSellGrays)
	btn:Show()
	ToggleAutoSellGray()
	
	-- BOE green items (Does user want to include these as well)
	local btn = CreateFrame("CheckButton", "$parentOptions_BOEGreenItems", eSaithBagFilterOptionsFrame, "UICheckButtonTemplate")
	btn:SetPoint("TOP", "$parentOptions_Coordinates", "TOP", 0, -25)
	btn:SetScript("OnClick", ToggleGreenBOEItems)
    btn:SetScript("OnEnter", GreenBOEItemsOnEnter)
    btn:SetScript("OnLeave", OnGameToolTipLeave)
	fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText(OptionsColor.."Include green BOEs|r")
	fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
	btn:SetFontString(fontstring)
	btn:SetChecked(eVar.properties.EnableBOEGreen)	
	btn:Show()
	ToggleGreenBOEItems()

	-- Auto greed on green items
	btn = CreateFrame("CheckButton", "$parentOptions_AutoGreedGreen", eSaithBagFilterOptionsFrame, "UICheckButtonTemplate")
	btn:SetPoint("TOP", "$parentOptions_AutoSellGray", "TOP", 0, -25)
	btn:SetScript("OnClick", ToggleAutoGreedGreenItems)
    btn:SetScript("OnEnter", AutoGreedGreenItemsOnEnter)
    btn:SetScript("OnLeave", OnGameToolTipLeave)
	fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText(OptionsColor.."Auto Greed greens|r")
	fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
	btn:SetFontString(fontstring)
	btn:SetChecked(eVar.properties.EnableAutoGreedGreenItems)
	btn:Show()
	ToggleAutoGreedGreenItems()
	
	-- Do not sell trade goods
	btn = CreateFrame("CheckButton", "$parentCheckButton_TradeGoods", eSaithBagFilterOptionsFrame, "UICheckButtonTemplate")
    btn:SetPoint("TOP", "$parentOptions_BOEGreenItems", "TOP", 0, -25)
	btn:SetScript("OnClick", ToggleKeepTradeGoods)
    btn:SetScript("OnEnter", KeepTradeGoodsOnEnter)
    btn:SetScript("OnLeave", OnGameToolTipLeave)	
	fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText(OptionsColor.."Keep Trade Goods|r")
	fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
	btn:SetFontString(fontstring)
	btn:SetChecked(eVar.properties.KeepTradeGoods)
	btn:Show()
	ToggleKeepTradeGoods()
	
	-- Enable iLevel sliders
	btn = CreateFrame("CheckButton", "$parentCheckButton_EnableiLevel", eSaithBagFilterOptionsFrame, "UICheckButtonTemplate")
	btn:SetPoint("TOP", "$parentOptions_AutoGreedGreen", "TOP", 0, -25)
	btn:SetScript("OnClick", ToggleiLevelSliders)
    btn:SetScript("OnEnter", iLevelSlidersOnEnter)
    btn:SetScript("OnLeave", OnGameToolTipLeave)
	fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText(OptionsColor.."Enable iLevel Sliders|r")
	fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
	btn:SetFontString(fontstring)
	btn:SetChecked(eVar.properties.EnableiLevelSliders)
	btn:Show()
	ToggleiLevelSliders()
	
	-- Disable loot frame background
	btn = CreateFrame("CheckButton", "$parentCheckButton_EnableLootFrameBackground", eSaithBagFilterOptionsFrame, "UICheckButtonTemplate")
	btn:SetPoint("TOP", "$parentCheckButton_TradeGoods", "TOP", 0, -25)
	btn:SetScript("OnClick", ToggleFrameLootBackground)
    btn:SetScript("OnEnter", FrameLootBackgroundOnEnter)
    btn:SetScript("OnLeave", OnGameToolTipLeave)
	btn:SetChecked(eVar.properties.EnableFrameLootBackground);
	fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText(OptionsColor.."Enable Loot Background|r")
	fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
	btn:SetFontString(fontstring)
	btn:SetChecked(eVar.properties.EnableFrameLootBackground)
	btn:Show()
	ToggleFrameLootBackground()
    
    -- Enable to keep all BOE regardless of quality. This auto defaults items to be in the players kept list
	btn = CreateFrame("CheckButton", "$parentCheckButton_KeepAllBOE", eSaithBagFilterOptionsFrame, "UICheckButtonTemplate")
	btn:SetPoint("TOP", "$parentCheckButton_EnableiLevel", "TOP", 0, -25)
	btn:SetScript("OnClick", ToggleKeepAllBOE)
    btn:SetScript("OnEnter", KeepAllBOEOnEnter)
	btn:SetScript("OnLeave", OnGameToolTipLeave)
	fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText(OptionsColor.."Keep all BOE|r")
	fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
	btn:SetFontString(fontstring)
    btn:SetChecked(eVar.properties.KeepAllBOE)
	btn:Show()
	--ToggleKeepAllBOE()
    
    --Quick Quest complete
	btn = CreateFrame("CheckButton", "$parentCheckButton_QuestComplete", eSaithBagFilterOptionsFrame, "UICheckButtonTemplate")
	btn:SetPoint("TOP", "$parentCheckButton_EnableLootFrameBackground", "TOP", 0, -25)
	btn:SetScript("OnClick", ToggleQuestComplete)
    btn:SetScript("OnEnter", QuestCompleteOnEnter)
	btn:SetScript("OnLeave", OnGameToolTipLeave)
	fontstring = btn:CreateFontString("$parentFontString", "ARTWORK", "GameFontNormal")
	fontstring:SetText(OptionsColor.."Quick Quest Complete|r")
	fontstring:SetPoint("LEFT", "$parent", "RIGHT", 0, 0)
	btn:SetFontString(fontstring)
    btn:SetChecked(eVar.properties.QuestComplete)
	btn:Show()
	ToggleQuestComplete()
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
				BottomTab = 1,
				zone = nil,
				types =
				{
					"Poor","Common","Uncommon","Rare","Epic"-- , "Legendary", "Artifact", "Heirloom", "WoW Token" },
				},
				colors =
				{
					"Gray","White","Green","Blue","Purple"-- , "Orange" , "Gold", "LightBlue", "Cyan"
				},
				texture = { 0, 0, .6, .6, .6, 1, 1, 1, 0, 1, 0, .2, .2, 1, 1, 0, 1, .8, .8, 0 },
				IsSelling = false,
				IsSellingGrays = false,
				IsTradeGoodKept = false,
				updateCount = 0,
				itemUpdateCount = 0,
				updateInterval = 0.5,
				maxTime = 0,
				keep = { },
				sell = { },
				SellTypeList = {},
				keepTradeGoods = { },
				EnableCoordinates = false,
				EnableAutoLoot = false,
				EnableAutoSellGrays = false,
				version = 1.34,
				EnableBOEGreen = false,
				EnableAutoGreedGreenItems = false,
				EnableiLevelSliders = false,
				MAX_ITEMS_PER_ROW = 14,
				SetSizeX = 400,
				SetSizeY = 375,
				EnableFrameLootBackground = true,			
                KeepAllBOE = false,
                QuestComplete = false
			}
		}
		for index, _type in pairs(eVar.properties.types) do
			if _type ~= properties then 
				eVar[_type] = { 
					checked = false,
					min = 0,
					max = 0,
					minChecked = false,
					maxChecked = false
				}
			end
		end
	end
	
	eSaithBagFilter:SetSize(eVar.properties.SetSizeX, eVar.properties.SetSizeY)
	 --TODO Any gear the character is current wearing when logging in should be immediately put in kept list each time the character logs in
	    --local slots = {
	    --    "HEADSLOT","NECKSLOT","SHOULDERSLOT","BACKSLOT","CHESTSLOT","SHIRTSLOT","TABARDSLOT","WRISTSLOT","HANDSSLOT",
	    --    "WAISTSLOT","LEGSSLOT","FEETSLOT","FINGER0SLOT","FINGER1SLOT","TRINKET0SLOT","TRINKET1SLOT","MAINHANDSLOT","SECONDARYHANDSLOT"
	    --}
        --
	    --local slotId, _texture, itemId, link
	    --for _index, item in pairs(slots) do
	    --    slotId = GetInventorySlotInfo(item)
	    --    itemId = GetInventoryItemID("player", slotId)
	    --    if itemId ~= nil then
	    --        _, link = GetItemInfo(itemId)
        --        print(link)
	    --        --eVar.properties.keep[link] = true
	    --    end
        --    
	    --end

end

local function ZoneMenuItemFunction(self, arg1, arg2, checked)
	eVar.properties.zone = self.arg1
	for index, _type in ipairs(eVar.properties.types) do
		local btn = _G["eSaithBagFilterCheckButton".._type]
		btn:SetChecked(true)
	end
	SelectItems()	
end
local function CreateZoneDropDownList()
	if eInstanceLoot["ALL"] == nil then eInstanceLoot["ALL"] = {} end			
	local i = 1
	for v, k in pairs(eInstanceLoot) do
		if k ~= nil then
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
local function UpdateAddon()
	local keep = {}
	if eVar ~= nil and eVar.properties ~= nil and eVar.properties.keep ~= nil then
		keep = eVar.properties.keep
	end
	eSaithBagFilterInstances = {}
	eSaithBagFilterResetButton_Click()
    print(STRINGS.ADDON_UPDATED..tostring(eVar.properties.version))
end

local function UpdateMinAndMax(self, value)
	if self == nil or value == nil or eVar == nil then return end
	local _type = self:GetName():match(".*FilterSlider...(.*)Slider.*") or self:GetName():match(".*FilterSlider...(.*)Down.*") or self:GetName():match(".*FilterSlider...(.*)Up.*")
	if self:GetName():find("Min") ~= nil then
		eVar[_type].min = value
	elseif self:GetName():find("Max") ~= nil then
		eVar[_type].max = value
	end
	SelectItems()
end
function eSaithBagFilter_OnEvent(self, event, arg1, arg2)
	if event == "ADDON_LOADED" and arg1 == "eSaithBagFilter" then
		self:UnregisterEvent("ADDON_LOADED")
		eVar = eSaithBagFilterVar or nil
		-- Check if an older version. If so do a soft reset
		local version = GetAddOnMetadata("eSaithBagFilter", "Version")    
		if eVar ~= nil and tostring(eVar.properties.version) ~= tostring(version) then    
			UpdateAddon() -- Creates Rarity Objects and then resaves the players kept list
		else
			CreateRarityObjects() -- no need to call it twice
		end
		
		CreateMainButtons()
		CreateOptionButtons()		
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
		if eVar.properties.EnableAutoSellGrays then SellByQuality("Poor") end
		if eVar.properties.BottomTab == 1 then eSaithBagFilterSellButton:Show() end
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
		if quality + 1 == 3 and eVar.properties.EnableAutoGreedGreenItems then   -- Quality 3 is Uncommon (green items) 
			if GroupLootContainer:IsShown() then
				RollOnLoot(StartLootRollID , 2);
			end
		end
		StartLootRollID = nil
     elseif (event == "QUEST_ACCEPTED" or event ==  "QUEST_DETAIL") and eVar.properties.QuestComplete then
        AcceptQuest()
    elseif event == "QUEST_PROGRESS" then       
        if eVar.properties.QuestComplete then
            CompleteQuest()
        end
    elseif event == "QUEST_COMPLETE" then
        if eVar.properties.QuestComplete then
            local reward
			local num = GetNumQuestRewards()
			if num <= 1 then reward = 1 else reward = math.random(num) end
			GetQuestReward(reward)
        end
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
    self:RegisterEvent("QUEST_DETAIL")
    self:RegisterEvent("QUEST_ACCEPTED")
    self:RegisterEvent("QUEST_PROGRESS")
    self:RegisterEvent("QUEST_COMPLETE")
end
function eSaithBagFilter_OnShow()
    PanelTemplates_SetTab(eSaithBagFilter_BottomTabs, eVar.properties.BottomTab)	
	if eVar.properties.BottomTab == 1 then SelectItems() end
end
function eSaithBagFilter_OnStopDrag(self, event, ...)
	self:StopMovingOrSizing()
end

function eSaithBagFilter_SellButton_Click(self, event, ...)
	if eVar.properties.sell == nil then return end
	eVar.properties.IsSelling = true;
	SellListedItems(eVar.properties.sell)
end
function eSaithBagFilter_SellButton_OnUpdate(self, elapsed)
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed

	-- Update for mass auto selling
	if (eVar.properties.IsSelling or eVar.properties.IsSellingGrays) and self.TimeSinceLastUpdate > eVar.properties.updateInterval then
		self.TimeSinceLastUpdate = 0
		eVar.properties.maxTime = eVar.properties.maxTime + 1

		if eVar.properties.IsSelling then
			if SellListedItems(eVar.properties.sell) == 0 or eVar.properties.maxTime > 60 then
				eVar.properties.IsSelling = false
				eVar.properties.sell = { }
				eVar.properties.maxTime = 0
				SelectItems()
			end		
		elseif eVar.properties.IsSellingGrays then
			if SellListedItems(eVar.properties.SellTypeList) == 0 or eVar.properties.maxTime > 60 then
				eVar.properties.IsSellingGrays = false
				eVar.properties.maxTime = 0
				eVar.properties.SellTypeList = { }
			end
		end
	end
	
	

	-- Update for auto gray loot selling
	if eVar.properties.EnableAutoLoot and self.TimeSinceLastUpdate > eVar.properties.updateInterval + 3 then
		self.TimeSinceLastUpdate = 0
		LootContainers();
	end

end
function eSaithBagFilter_SellButton_OnHide(self, event, ...)
	eVar.properties.IsSelling = false
end

function eSaithBagFilterResetButton_Click(self, event)
	eVar = nil
	eInstanceLoot = nil
	eInstances = nil
	CreateRarityObjects()       
end
function eSaithBagFilterSlider_CheckBoxClick(self, button, down)
	local _type = self:GetName():match(".*FilterSlider...(.*)Check")	
	if string.find(self:GetName(), "Min") ~= nil then
		eVar[_type].minChecked = self:GetChecked()
	elseif string.find(self:GetName(), "Max") ~= nil then
		eVar[_type].maxChecked = self:GetChecked()
	end
	SelectItems()
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

function PrepareTab()
	-- HIDE Tab 1
	for index, _type in ipairs(eVar.properties.types) do
		frame = _G["eSaithBagFilterCheckButton".._type]:Hide()
		frame = _G["eSaithBagFilterTypeBackgroundColor".._type]:Hide()
		frame = _G["eSaithBagFilterLootTextureTypeBackgroundColor".._type]:Hide()

		if eVar.properties.EnableiLevelSliders then
			frame = _G["eSaithBagFilterSliderMin".._type]:Hide()
			frame = _G["eSaithBagFilterSliderMax".._type]:Hide()
		end			
	end
	
	-- If BOE Loot string is shown, hide it
	eSaithBagFilterLootFrameBOEFontString:Hide() 
	
	-- Hide all loot
	for i = 1, MAX_ITEM_COUNT do
		_G["eSaithBagFilterLootFrameSellItem" .. i]:Hide()
	end
    
    -- Hide Options button
    eSaithBagFilterOptionsButton:Hide()
	
	eSaithBagFilterSellButton:Hide()
	
	eVar.properties.EnableFrameLootBackground = eSaithBagFilterOptionsFrameCheckButton_EnableLootFrameBackground:GetChecked()
	local corners ={"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}	
	for i = 1, 4 do
		local corner =  _G["eSaithBagFilterLootFrameTexture"..corners[i]]
		corner:Hide()		
	end
	
	-- Hide Tab 2
	eSaithBagFilterLootFrameInstanceInfoFontStringTitle:Hide()
	eSaithBagFilterLootFrameInstanceInfoFontStringFreshTitle:Hide()
	eSaithBagFilterLootFrameInstanceInfoFontStringFreshList:Hide()
	eSaithBagFilterLootFrameInstanceInfoFontStringSavedTitle:Hide()
	eSaithBagFilterLootFrameInstanceInfoFontStringSavedList:Hide()
	
end
function eSaithBagFilter_BottomTab_Click(self, event, ... )
	local frame
	PrepareTab()
	eVar.properties.BottomTab = self:GetID()
	
	if self:GetID() == 1 then 		
		-- Show Tab 1
		for index, _type in ipairs(eVar.properties.types) do
			frame = _G["eSaithBagFilterCheckButton".._type]:Show()
			frame = _G["eSaithBagFilterTypeBackgroundColor".._type]:Show()			
			if eVar.properties.EnableiLevelSliders then
				frame = _G["eSaithBagFilterSliderMin".._type]:Show()
				frame = _G["eSaithBagFilterSliderMax".._type]:Show()
			end
		end
		SelectItems()	
		ToggleFrameLootBackground()
		if MerchantFrame:IsShown() then eSaithBagFilterSellButton:Show() end
		eSaithBagFilterOptionsButton:Show()
        
	elseif self:GetID() == 2 then
		RequestRaidInfo()	
		eSaithBagFilterLootFrameInstanceInfoFontStringTitle:Show()
		eSaithBagFilterLootFrameInstanceInfoFontStringFreshTitle:Show()
		eSaithBagFilterLootFrameInstanceInfoFontStringFreshList:Show()
		eSaithBagFilterLootFrameInstanceInfoFontStringSavedTitle:Show()
		eSaithBagFilterLootFrameInstanceInfoFontStringSavedList:Show()
	end
end
function eSaithBagFilter_ShowCharacterInfo(self, event)
	if eVar.properties.LeftTab ~= 4 then
		RequestRaidInfo()
		
		eSaithBagFilterSellButton:Hide()
	end

	eVar.properties.LeftTab = 4
	eSaithBagFilterDropDown:Show()
	eSaithBagFilterSellButton:Hide()
end
function eSaithBagFilter_ShowOptions(self, event)
	
	eSaithBagFilterSellButton:Hide()
	
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

	local SortedPlayers = {}
	for key, value in pairs(eInstances.players) do table.insert(SortedPlayers, key)	end
	table.sort(SortedPlayers)
	
	for _, PlayerServerName in pairs(SortedPlayers) do
		local playerInfo = eInstances.players[PlayerServerName]
		
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
	local fontstring = eSaithBagFilterLootFrameInstanceInfoFontStringTitle
	fontstring:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE, THICKOUTLINE")
	fontstring:SetPoint("TOP", "$parent", "TOP", 0, -5)    
	fontstring:SetText("|cffbdf3ff".. self.arg1)
	fontstring:SetWidth(400)    
	fontstring:Show()
	
	fontstring = eSaithBagFilterLootFrameInstanceInfoFontStringFreshTitle
	fontstring:SetFont("Fonts\\FRIZQT__.TTF", 25, "OUTLINE, THICKOUTLINE")
	fontstring:SetPoint("TOP", eSaithBagFilterLootFrameInstanceInfoFontStringTitle, "BOTTOM", 0, -20)    
	fontstring:SetText("|cffbdf3ff Fresh Instance")
	fontstring:SetWidth(250)    
	fontstring:Show()

	fontstring = eSaithBagFilterLootFrameInstanceInfoFontStringFreshList
	fontstring:SetPoint("TOP", eSaithBagFilterLootFrameInstanceInfoFontStringFreshTitle, "BOTTOM", 0, 7)
	fontstring:SetFont("Fonts\\FRIZQT__.TTF", 13)
	fontstring:SetText(CleanText)
	fontstring:SetWidth(250)    
	fontstring:Show()

	fontstring = eSaithBagFilterLootFrameInstanceInfoFontStringSavedTitle
	fontstring:SetPoint("TOP", eSaithBagFilterLootFrameInstanceInfoFontStringFreshList, "BOTTOM", 0, -34)
	fontstring:SetFont("Fonts\\FRIZQT__.TTF", 23, "OUTLINE, THICKOUTLINE")
	fontstring:SetText("|cff719096 Saved Instance")
	fontstring:SetWidth(250)
	fontstring:Show()

	fontstring = eSaithBagFilterLootFrameInstanceInfoFontStringSavedList
	fontstring:SetPoint("TOP", eSaithBagFilterLootFrameInstanceInfoFontStringSavedTitle, "BOTTOM", 0, 7)
	fontstring:SetFont("Fonts\\FRIZQT__.TTF", 13)
	fontstring:SetText(SavedText)    
	fontstring:SetWidth(250)
	fontstring:Show()    

	if count > 15 then
		local extend = ((count - 15) / 100) * 5 + 1.0
		eSaithBagFilter:SetHeight(eSaithBagFilter:GetHeight() * extend + 300)
	end
end
function CreatePlayerInfoDropDownList()
	local i = 1;
	
	local SortedInstances = {}
	for key, value in pairs(eInstances) do table.insert(SortedInstances, key)	end
	table.sort(SortedInstances)
	
	for _, instance in pairs(SortedInstances) do        
		local TableOfNames = eInstances[instance]
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
	if eVar.properties.BottomTab == 1 then
		CreateZoneDropDownList()
	elseif eVar.properties.BottomTab == 2 then
		CreatePlayerInfoDropDownList()
	end
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

-- ReOrg Saved Instances 
	-- Allow player to add/remove desired saved instances
	-- Allow option to choose miniumum required raid level (ie, no need to show lvl 80s when you only want to show level 100s)

-- Replace strings with local global string
-- consider making all loot item buttons local globals
-- Instead of showing multiples of the same loot, count and condense with # showing how many
-- Consider adding transparency button if mouse is not over AddOn
-- consider sorting by ilevel
-- Add a "Never sell list" so that items never show up on list. Allow the list to be modified

-- Change from using "checkbuttons" for item buttons but rather regular buttons
--]]

--[[
	Player may disable loot frame background through the options panel
	Instances and player names are sorted alphabetically
	Fixed issue when one of the items is a pet would cause a popup error
    When opening options all other tabs, panels, buttons, etc that are not directly related to options is hidden. This should help reduce confusion of 
        which tab and information the player receives and then when attempting to navigate to another tab.
    Added "Quest Complete" which quickly obtains and completes quests. Excellent for leveling! Quest rewards are randomly chosen. 
    Added "Keep All BOE" checkbox. When checked every BOE of Uncommon quality (Green) or greater is immediately put in the kept list
    Prevents the "Item is busy" error from occurring when selling items
]]--

--[[


]]--