-- eSaith Bag Filter
-- Items: item info, loot history, keep rules and the vendor sell engine.

local _, ns = ...

local Q = Enum.ItemQuality
local ItemBind = Enum.ItemBind

ns.QUALITIES = { Q.Poor, Q.Common, Q.Uncommon, Q.Rare, Q.Epic }

function ns.QualityName(quality)
	return _G["ITEM_QUALITY" .. quality .. "_DESC"] or tostring(quality)
end

function ns.QualityColor(quality)
	if ColorManager and ColorManager.GetColorDataForItemQuality then
		local data = ColorManager.GetColorDataForItemQuality(quality)
		if data and data.color then return data.color end
	end
	local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
	return c and (c.color or CreateColor(c.r, c.g, c.b)) or HIGHLIGHT_FONT_COLOR
end

---------------------------------------------------------------------------
-- Item info cache
---------------------------------------------------------------------------

local itemCache = {}

--- Returns cached static info for an item, or nil if the client hasn't loaded it yet.
--- When nil, the item is requested and ITEM_INFO_READY fires once it arrives.
function ns:GetItemData(itemID)
	local data = itemCache[itemID]
	if data then return data end

	local name, _, quality, _, _, _, _, _, _, icon, sellPrice, classID, _, bindType = C_Item.GetItemInfo(itemID)
	if not name then
		C_Item.RequestLoadItemDataByID(itemID)
		return nil
	end

	data = {
		name = name,
		quality = quality,
		icon = icon,
		sellPrice = sellPrice or 0,
		classID = classID,
		bindType = bindType,
	}
	itemCache[itemID] = data
	return data
end

do
	local pending
	ns:RegisterEvent("GET_ITEM_INFO_RECEIVED", function()
		-- Batch the flood of events that comes in when many items load at once.
		if pending then return end
		pending = true
		C_Timer.After(0.25, function()
			pending = false
			ns:Fire("ITEM_INFO_READY")
		end)
	end)
end

---------------------------------------------------------------------------
-- Keep rules
---------------------------------------------------------------------------

local function IsBindOnEquip(bindType, isBound)
	if isBound then return false end
	return bindType == ItemBind.OnEquip or bindType == ItemBind.ToBnetAccountUntilEquipped
end

--- Returns a reason string when an item must not be sold, or nil if it's sellable.
--- `entry` is a bag entry from ns:GetBagItems() (or anything with the same fields).
function ns:GetKeepReason(entry)
	local opts = self.db.options

	if self.db.kept[entry.itemID] then
		return "On your keep list"
	end
	if entry.inEquipmentSet then
		return "Part of an equipment set"
	end

	local data = entry.data
	if opts.keepTradeGoods and data and data.classID == Enum.ItemClass.Tradegoods then
		return "Keep trade goods is on"
	end

	local boeColor = (entry.quality == Q.Uncommon and opts.keepGreenBoE and "green")
		or (entry.quality == Q.Rare and opts.keepBlueBoE and "blue")
		or (entry.quality == Q.Epic and opts.keepEpicBoE and "epic")
	if boeColor then
		-- Item info not loaded yet: we can't tell if it's BoE, so play it safe.
		if not data or IsBindOnEquip(data.bindType, entry.isBound) then
			return ("Keep %s BoE items is on"):format(boeColor)
		end
	end

	return nil
end

function ns:ToggleKept(itemID)
	self.db.kept[itemID] = not self.db.kept[itemID] or nil
	self:Fire("LOOT_CHANGED")
end

--- Everything currently equipped goes on the keep list so it can never be vendored by accident.
function ns:ProtectEquippedItems()
	for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local itemID = GetInventoryItemID("player", slot)
		if itemID then
			self.db.kept[itemID] = true
		end
	end
end

ns:RegisterEvent("PLAYER_LOGIN", function() ns:ProtectEquippedItems() end)
ns:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function() ns:ProtectEquippedItems() end)

---------------------------------------------------------------------------
-- Bag contents
---------------------------------------------------------------------------

--- Aggregates bag contents by itemID.
--- Returns { [itemID] = { itemID, link, icon, quality, count, bag, slot, isBound, hasNoValue, ... } }
function ns:GetBagItems()
	local result = {}
	for bag, slot, info in ns.IterateBags() do
		local entry = result[info.itemID]
		if not entry then
			local inSet = C_Container.GetContainerItemEquipmentSetInfo
				and C_Container.GetContainerItemEquipmentSetInfo(bag, slot)
			entry = {
				itemID = info.itemID,
				link = info.hyperlink,
				icon = info.iconFileID,
				quality = info.quality or Q.Common,
				count = 0,
				bag = bag,
				slot = slot,
				isBound = info.isBound,
				hasNoValue = info.hasNoValue,
				hasLoot = info.hasLoot,
				inEquipmentSet = inSet or false,
				data = self:GetItemData(info.itemID),
			}
			result[info.itemID] = entry
		end
		entry.count = entry.count + (info.stackCount or 1)
	end
	return result
end

---------------------------------------------------------------------------
-- Loot history
--
-- Midnight made loot chat messages unreadable inside instances, so instead of
-- parsing chat we compare bag snapshots: anything that shows up in your bags
-- while you aren't at a vendor/bank/mailbox/etc. counts as loot for the zone.
---------------------------------------------------------------------------

local snapshot
local primed = false

local NON_LOOT_INTERACTIONS = {}
do
	local types = Enum.PlayerInteractionType or {}
	for _, name in ipairs({ "Merchant", "Banker", "AccountBanker", "GuildBanker", "MailInfo", "Auctioneer",
		"TradePartner", "VoidStorageBanker", "ItemUpgrade", "Scrapping" }) do
		if types[name] then table.insert(NON_LOOT_INTERACTIONS, types[name]) end
	end
end

local function IsAtNonLootWindow()
	local manager = C_PlayerInteractionManager
	if manager and manager.IsInteractingWithNpcOfType then
		for _, interaction in ipairs(NON_LOOT_INTERACTIONS) do
			if manager.IsInteractingWithNpcOfType(interaction) then return true end
		end
	end
	return (MailFrame and MailFrame:IsShown()) or (TradeFrame and TradeFrame:IsShown()) or false
end

local function TakeSnapshot()
	local counts = {}
	for _, _, info in ns.IterateBags() do
		counts[info.itemID] = (counts[info.itemID] or 0) + (info.stackCount or 1)
	end
	return counts
end

local function CurrentZone()
	local zone = GetRealZoneText()
	if not zone or zone == "" or ns.IsSecret(zone) then
		return nil
	end
	return zone
end

function ns:RecordLoot(itemID, zone)
	zone = zone or CurrentZone()
	if not zone then return end
	self.lootDB[zone] = self.lootDB[zone] or {}
	self.lootDB[zone][itemID] = true
end

ns:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReloadingUi)
	if isInitialLogin or isReloadingUi then
		-- Bags finish loading a moment after login; wait before taking the baseline.
		C_Timer.After(3, function()
			snapshot = TakeSnapshot()
			primed = true
			ns:PruneLootHistory()
		end)
	end
end)

ns:RegisterEvent("BAG_UPDATE_DELAYED", function()
	if not primed then return end

	local current = TakeSnapshot()
	if not IsAtNonLootWindow() then
		local zone = CurrentZone()
		local gained = false
		for itemID, count in pairs(current) do
			if count > (snapshot[itemID] or 0) then
				ns:RecordLoot(itemID, zone)
				gained = true
			end
		end
		if gained then ns:Fire("LOOT_CHANGED") end
	end
	snapshot = current
end)

--- Zones with loot that is still in your bags, sorted alphabetically.
function ns:GetLootZones()
	local bagItems = self:GetBagItems()
	local zones = {}
	for zone, list in pairs(self.lootDB) do
		for itemID in pairs(list) do
			if bagItems[itemID] then
				table.insert(zones, zone)
				break
			end
		end
	end
	table.sort(zones)
	return zones
end

--- Drops history entries for items that are no longer in your bags.
function ns:PruneLootHistory()
	local bagItems = self:GetBagItems()
	for zone, list in pairs(self.lootDB) do
		for itemID in pairs(list) do
			if not bagItems[itemID] then list[itemID] = nil end
		end
		if next(list) == nil then self.lootDB[zone] = nil end
	end
end

function ns:ClearLootHistory()
	wipe(self.lootDB)
	self:Fire("LOOT_CHANGED")
end

--- Items looted in `zone` (or anywhere, when zone is nil) that are still in your bags
--- and can be sold to a vendor. Kept items are included and flagged with keepReason.
function ns:GetLootedItems(zone)
	local bagItems = self:GetBagItems()
	local result = {}

	local function consider(itemID)
		local entry = bagItems[itemID]
		if entry and not entry.hasNoValue and not entry.hasLoot and not result[itemID] then
			entry.keepReason = self:GetKeepReason(entry)
			result[itemID] = entry
		end
	end

	if zone then
		for itemID in pairs(self.lootDB[zone] or {}) do consider(itemID) end
	else
		for _, list in pairs(self.lootDB) do
			for itemID in pairs(list) do consider(itemID) end
		end
	end

	return result
end

---------------------------------------------------------------------------
-- Selling
---------------------------------------------------------------------------

local SELL_INTERVAL = 0.2
local SELL_PER_TICK = 8
local MAX_TICKS = 150

ns.atMerchant = false
local sellTicker
local sold = { count = 0, money = 0 }

local function StopSelling(showSummary)
	if sellTicker then
		sellTicker:Cancel()
		sellTicker = nil
	end
	if showSummary and sold.count > 0 then
		ns.Print("Sold %d item%s for %s.", sold.count, sold.count == 1 and "" or "s", GetMoneyString(sold.money, true))
	end
	sold.count, sold.money = 0, 0
	ns:PruneLootHistory()
	ns:Fire("LOOT_CHANGED")
	ns:Fire("SELLING_CHANGED", false)
end

function ns:IsSelling()
	return sellTicker ~= nil
end

--- Sells every bag item whose itemID is in `itemIDs` (a set), skipping anything the keep rules protect.
--- Runs over several frames so the server can keep up.
function ns:SellItems(itemIDs)
	if not self.atMerchant or sellTicker or not next(itemIDs) then return end

	local ticks = 0
	sellTicker = C_Timer.NewTicker(SELL_INTERVAL, function()
		ticks = ticks + 1
		if not ns.atMerchant or ticks > MAX_TICKS then
			StopSelling(true)
			return
		end

		local soldThisTick, waiting = 0, false
		for bag, slot, info in ns.IterateBags() do
			if itemIDs[info.itemID] and not info.hasNoValue then
				local entry = {
					itemID = info.itemID,
					quality = info.quality,
					isBound = info.isBound,
					data = ns:GetItemData(info.itemID),
					inEquipmentSet = C_Container.GetContainerItemEquipmentSetInfo
						and C_Container.GetContainerItemEquipmentSetInfo(bag, slot) or false,
				}
				if not ns:GetKeepReason(entry) then
					if info.isLocked or soldThisTick >= SELL_PER_TICK then
						waiting = true
					elseif ns.atMerchant then -- re-check: using an item away from a vendor would equip/use it
						C_Container.UseContainerItem(bag, slot)
						soldThisTick = soldThisTick + 1
						sold.count = sold.count + 1
						sold.money = sold.money + (entry.data and entry.data.sellPrice or 0) * (info.stackCount or 1)
					end
				end
			end
		end

		if soldThisTick == 0 and not waiting then
			StopSelling(true)
		end
	end)
	self:Fire("SELLING_CHANGED", true)
end

function ns:SellJunk()
	local junk = {}
	for _, _, info in ns.IterateBags() do
		if info.quality == Q.Poor and not info.hasNoValue then
			junk[info.itemID] = true
		end
	end
	self:SellItems(junk)
end

ns:RegisterEvent("MERCHANT_SHOW", function()
	ns.atMerchant = true
	ns:Fire("MERCHANT_CHANGED", true)
	if ns.db.options.autoSellJunk then
		ns:SellJunk()
	end
end)

ns:RegisterEvent("MERCHANT_CLOSED", function()
	ns.atMerchant = false
	if sellTicker then StopSelling(true) end
	ns:Fire("MERCHANT_CHANGED", false)
end)
