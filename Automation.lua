-- eSaith Bag Filter
-- Automation: quick loot, auto-greed, quest helper, container opener and coordinates.

local _, ns = ...

local function Option(name)
	return ns.db and ns.db.options[name]
end

---------------------------------------------------------------------------
-- Quick loot
---------------------------------------------------------------------------

ns:RegisterEvent("LOOT_READY", function()
	if not Option("quickLoot") then return end
	-- Loot from the last slot backwards so indices don't shift under us.
	for i = GetNumLootItems(), 1, -1 do
		local locked = select(6, GetLootSlotInfo(i))
		if not locked then
			LootSlot(i)
		end
	end
end)

---------------------------------------------------------------------------
-- Auto-greed green items in group loot
---------------------------------------------------------------------------

local GREED = 2

ns:RegisterEvent("START_LOOT_ROLL", function(_, rollID)
	if not Option("autoGreedGreens") or ns.IsSecret(rollID) then return end

	local _, _, _, quality, bindOnPickUp, _, canGreed = GetLootRollItemInfo(rollID)
	if ns.IsSecret(quality) then return end

	if quality == Enum.ItemQuality.Uncommon and canGreed and not bindOnPickUp then
		RollOnLoot(rollID, GREED)
	end
end)

---------------------------------------------------------------------------
-- Quest helper: accepts, turns in, and picks the reward when there's no choice.
-- Hold Shift while talking to the NPC to handle the quest yourself.
---------------------------------------------------------------------------

local function QuestHelperActive()
	return Option("autoQuest") and not IsShiftKeyDown()
end

ns:RegisterEvent("QUEST_DETAIL", function()
	if QuestHelperActive() then AcceptQuest() end
end)

ns:RegisterEvent("QUEST_PROGRESS", function()
	if QuestHelperActive() and IsQuestCompletable() then CompleteQuest() end
end)

ns:RegisterEvent("QUEST_COMPLETE", function()
	if QuestHelperActive() and GetNumQuestChoices() <= 1 then
		GetQuestReward(1)
	end
end)

---------------------------------------------------------------------------
-- Open containers (clams, unlocked lockboxes, bags of loot...)
---------------------------------------------------------------------------

local openTicker
local tried
local lootOpenTicks = 0

function ns:IsOpeningContainers()
	return openTicker ~= nil
end

function ns:StopOpeningContainers(reason)
	if openTicker then
		openTicker:Cancel()
		openTicker = nil
		if reason then ns.Print(reason) end
		ns:Fire("CONTAINERS_CHANGED", false)
	end
end

function ns:CountContainers()
	local count = 0
	for _, _, info in ns.IterateBags() do
		if info.hasLoot and not info.isLocked then count = count + 1 end
	end
	return count
end

function ns:OpenContainers()
	if openTicker then return end
	if ns.atMerchant then
		ns.Print("Close the vendor window first so nothing gets sold by accident.")
		return
	end

	tried, lootOpenTicks = {}, 0
	openTicker = C_Timer.NewTicker(0.6, function()
		if InCombatLockdown() then
			ns:StopOpeningContainers("Stopped opening containers: you entered combat.")
			return
		end
		if ns.atMerchant then
			ns:StopOpeningContainers("Stopped opening containers: a vendor window opened.")
			return
		end

		-- Wait for the previous container's loot window to empty.
		if GetNumLootItems() > 0 then
			lootOpenTicks = lootOpenTicks + 1
			if lootOpenTicks > 5 then
				ns:StopOpeningContainers("Stopped opening containers: your bags may be full.")
			end
			return
		end
		lootOpenTicks = 0

		for bag, slot, info in ns.IterateBags() do
			local key = bag * 1000 + slot
			if info.hasLoot and not info.isLocked and not tried[key] then
				tried[key] = true
				C_Container.UseContainerItem(bag, slot)
				return
			end
		end

		ns:StopOpeningContainers("Finished opening containers.")
	end)
	ns:Fire("CONTAINERS_CHANGED", true)
end

---------------------------------------------------------------------------
-- Coordinates under the minimap
---------------------------------------------------------------------------

local coords

local function UpdateCoordinates()
	local mapID = C_Map.GetBestMapForUnit("player")
	local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
	local x, y
	if pos then x, y = pos:GetXY() end

	if x and y and not ns.IsSecret(x) and (x > 0 or y > 0) then
		coords.text:SetFormattedText("%.1f, %.1f", x * 100, y * 100)
	else
		coords.text:SetText("")
	end
end

function ns:UpdateCoordinatesVisibility()
	if Option("showCoordinates") then
		if not coords then
			coords = CreateFrame("Frame", "eSaithBagFilterCoordinates", Minimap)
			coords:SetSize(100, 16)
			coords:SetPoint("TOP", Minimap, "BOTTOM", 0, -18)
			coords.text = coords:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			coords.text:SetPoint("CENTER")
			coords.text:SetTextColor(0.6, 0.98, 0.6)
			coords.elapsed = 0
			coords:SetScript("OnUpdate", function(self, elapsed)
				self.elapsed = self.elapsed + elapsed
				if self.elapsed >= 0.2 then
					self.elapsed = 0
					UpdateCoordinates()
				end
			end)
		end
		coords:Show()
	elseif coords then
		coords:Hide()
	end
end

ns:RegisterEvent("PLAYER_LOGIN", function() ns:UpdateCoordinatesVisibility() end)
ns:On("SETTINGS_CHANGED", function() ns:UpdateCoordinatesVisibility() end)
