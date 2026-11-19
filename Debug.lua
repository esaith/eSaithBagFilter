-- eSaith Bag Filter
-- Debug: /efilter debug prints what the addon sees, to check features against the live game.

local _, ns = ...
local L = ns.L

local function Line(label, value)
	print(("  |cff9d9d9d%s:|r %s"):format(label, tostring(value)))
end

local function Bool(value)
	return value and "|cff4ce64cyes|r" or "|cffff6060no|r"
end

local function PrintItem(link)
	local itemID = C_Item.GetItemInfoInstant(link)
	print(" ")
	ns.Print(L["Item under the cursor: %s"], link)
	if not itemID then return end

	local data = ns:GetItemData(itemID)
	Line("itemID", itemID)
	if data then
		Line("quality / classID / bindType", ("%s / %s / %s"):format(tostring(data.quality), tostring(data.classID),
			tostring(data.bindType)))
		Line(L["vendor price"], GetMoneyString(data.sellPrice, true))
	else
		Line(L["item info"], L["not loaded yet, hover again in a moment"])
	end

	local level = C_Item.GetDetailedItemLevelInfo(link)
	local _, equipped = GetAverageItemLevel()
	Line(L["item level / your equipped"], ("%s / %.1f"):format(tostring(level), equipped or 0))

	if C_TransmogCollection then
		local appearanceID = C_TransmogCollection.GetItemInfo(link)
		Line(L["appearance ID / collected"], ("%s / %s"):format(tostring(appearanceID),
			appearanceID and Bool(C_TransmogCollection.PlayerHasTransmogByItemInfo(link)) or "-"))
	end

	local auction = ns:GetAuctionValue(link, itemID)
	Line(L["Auction House value"], auction and GetMoneyString(auction, true) or "-")

	local bagItem = ns:GetBagItems()[itemID]
	if bagItem then
		Line(L["in bags / looted in"], ("%d / %s"):format(bagItem.count, (function()
			local zones = {}
			for zone, list in pairs(ns.lootDB) do
				if list[itemID] then table.insert(zones, zone) end
			end
			return #zones > 0 and table.concat(zones, ", ") or "-"
		end)()))
		Line(L["keep reason"], ns:GetKeepReason(bagItem) or "-")
	end
end

function ns:PrintDebugInfo()
	local version, build, _, interface = GetBuildInfo()
	ns.Print(L["Debug info"])
	Line(L["addon / client / interface"], ("%s / %s (%s) / %s"):format(ns.version, version, build, interface))
	Line(L["zone"], tostring(ns.GetCurrentZone()))
	local inInstance, instanceType = IsInInstance()
	Line(L["in instance"], ("%s (%s)"):format(Bool(inInstance), tostring(instanceType)))
	Line(L["at a vendor / selling"], ("%s / %s"):format(Bool(ns.atMerchant), Bool(ns:IsSelling())))
	Line(L["price source"], ns:GetPriceSourceName() or "-")
	Line(L["settings"], ns.charDB.useCharacterSettings and L["this character"] or L["account-wide"])

	local zones, kept, hidden = 0, 0, 0
	for _ in pairs(ns.lootDB) do zones = zones + 1 end
	for _ in pairs(ns.db.kept) do kept = kept + 1 end
	for _ in pairs(ns.db.hidden) do hidden = hidden + 1 end
	Line(L["loot zones / kept / hidden"], ("%d / %d / %d"):format(zones, kept, hidden))

	if C_MythicPlus and C_MythicPlus.GetOwnedKeystoneChallengeMapID then
		Line(L["keystone (map / level)"], ("%s / %s"):format(tostring(C_MythicPlus.GetOwnedKeystoneChallengeMapID()),
			tostring(C_MythicPlus.GetOwnedKeystoneLevel())))
	end

	if C_WeeklyRewards and C_WeeklyRewards.GetActivities then
		for _, row in ipairs(ns.VAULT_ROWS) do
			local parts = {}
			for _, activity in ipairs(C_WeeklyRewards.GetActivities(row.type) or {}) do
				table.insert(parts, ("%s/%s"):format(tostring(activity.progress), tostring(activity.threshold)))
			end
			Line(("vault %s (type %d)"):format(row.key, row.type), #parts > 0 and table.concat(parts, "  ") or L["no activities"])
		end
		Line(L["vault rewards waiting"], Bool(C_WeeklyRewards.HasAvailableRewards and C_WeeklyRewards.HasAvailableRewards()))
	end

	local run = ns:GetCurrentRun()
	Line(L["current run"], run and ("%s (%s)"):format(run.zone, run.difficulty or "") or "-")

	local _, link = GameTooltip:GetItem()
	if link then PrintItem(link) end
end
