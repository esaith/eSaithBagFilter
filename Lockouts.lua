-- eSaith Bag Filter
-- Lockouts: raid & dungeon saves, Mythic+ keystones and Great Vault progress
-- for every character you log in on.

local _, ns = ...

local WEEK = 7 * 24 * 60 * 60

local function PlayerKey()
	return ("%s (%s)"):format(UnitName("player"), GetRealmName())
end

--- "The Stonevault" sorts under S; keys keep the pre-2.0 format so old data still lines up.
local function InstanceKey(name, difficultyName)
	name = name:gsub("^The ", "")
	return ("%s - %s"):format(name, difficultyName or "")
end

local function SecondsUntilWeeklyReset()
	return C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset()
		or 0
end

--- Timestamp of the most recent weekly reset.
function ns.GetLastWeeklyReset()
	return time() + SecondsUntilWeeklyReset() - WEEK
end

--- Characters are tracked once they reach max level or get saved somewhere.
local function ShouldTrack(numSaved)
	if ns.lockoutDB.players[PlayerKey()] then return true end
	local maxLevel = GetMaxLevelForPlayerExpansion and GetMaxLevelForPlayerExpansion() or 80
	return (numSaved or 0) > 0 or UnitLevel("player") >= maxLevel
end

local function GetCurrentPlayer()
	local key = PlayerKey()
	local player = ns.lockoutDB.players[key]
	if not player then
		player = { shown = true }
		ns.lockoutDB.players[key] = player
	end
	local _, classFile = UnitClass("player")
	player.name = UnitName("player")
	player.realm = GetRealmName()
	player.class = classFile
	player.lastSeen = time()
	return player, key
end

local function PruneExpired()
	local now = time()
	for instance, chars in pairs(ns.lockoutDB.lockouts) do
		for player, resetAt in pairs(chars) do
			if resetAt <= now then chars[player] = nil end
		end
		if next(chars) == nil then ns.lockoutDB.lockouts[instance] = nil end
	end
end

---------------------------------------------------------------------------
-- Raid & dungeon saves
---------------------------------------------------------------------------

local function RecordLockouts()
	local db = ns.lockoutDB
	local numSaved = GetNumSavedInstances()
	if not ShouldTrack(numSaved) then return end

	local _, key = GetCurrentPlayer()

	-- Rebuild this character's saves from scratch so finished/reset lockouts disappear.
	for _, chars in pairs(db.lockouts) do
		chars[key] = nil
	end

	local now = time()
	for i = 1, numSaved do
		local name, _, reset, _, locked, extended, _, _, _, difficultyName = GetSavedInstanceInfo(i)
		if name and (locked or extended) and reset and reset > 0 then
			local instance = InstanceKey(name, difficultyName)
			db.lockouts[instance] = db.lockouts[instance] or {}
			db.lockouts[instance][key] = now + reset
			if db.shownInstances[instance] == nil then
				db.shownInstances[instance] = true
			end
		end
	end

	PruneExpired()
	ns:Fire("LOCKOUTS_CHANGED")
end

ns:RegisterEvent("UPDATE_INSTANCE_INFO", RecordLockouts)

---------------------------------------------------------------------------
-- Keystone & Great Vault
---------------------------------------------------------------------------

local thresholdTypes = Enum.WeeklyRewardChestThresholdType or {}
ns.VAULT_ROWS = {
	{ key = "raid", type = thresholdTypes.Raid or 3 },
	{ key = "dungeons", type = thresholdTypes.Activities or 1 },
	{ key = "world", type = thresholdTypes.World or 6 },
}

local function ReadVault()
	if not C_WeeklyRewards or not C_WeeklyRewards.GetActivities then return nil end
	local vault = {}
	for _, row in ipairs(ns.VAULT_ROWS) do
		local unlocked, slots = 0, 0
		for _, activity in ipairs(C_WeeklyRewards.GetActivities(row.type) or {}) do
			slots = slots + 1
			if not ns.IsSecret(activity.progress) and activity.progress >= activity.threshold then
				unlocked = unlocked + 1
			end
		end
		if slots > 0 then vault[row.key] = unlocked end
	end
	return vault
end

local function ReadKeystone()
	if not C_MythicPlus or not C_MythicPlus.GetOwnedKeystoneChallengeMapID then return nil end
	local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
	local level = C_MythicPlus.GetOwnedKeystoneLevel()
	if mapID and level and level > 0 then
		return { mapID = mapID, level = level }
	end
	return nil
end

local function Signature(weekly)
	local key = weekly.keystone and (weekly.keystone.mapID .. ":" .. weekly.keystone.level) or "-"
	local vault = weekly.vault or {}
	return ("%s|%s|%s|%s|%s"):format(key, vault.raid or "-", vault.dungeons or "-", vault.world or "-",
		tostring(weekly.canClaim))
end

local function RecordWeekly()
	if not ShouldTrack() then return end
	local player = GetCurrentPlayer()

	local weekly = {
		resetAt = time() + SecondsUntilWeeklyReset(),
		keystone = ReadKeystone(),
		vault = ReadVault(),
		canClaim = C_WeeklyRewards and C_WeeklyRewards.HasAvailableRewards and C_WeeklyRewards.HasAvailableRewards()
			or false,
	}

	-- Bag updates call this a lot; only redraw when something actually changed.
	local changed = not player.weekly or Signature(player.weekly) ~= Signature(weekly)
	player.weekly = weekly
	if changed then ns:Fire("LOCKOUTS_CHANGED") end
end

ns:RegisterEvent("WEEKLY_REWARDS_UPDATE", RecordWeekly)
ns:RegisterEvent("CHALLENGE_MODE_COMPLETED", function() C_Timer.After(2, RecordWeekly) end)
ns:RegisterEvent("BAG_UPDATE_DELAYED", RecordWeekly) -- picks up new or downgraded keystones

ns:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isInitialLogin)
	if isInitialLogin then
		C_Timer.After(5, function()
			RequestRaidInfo()
			if C_MythicPlus and C_MythicPlus.RequestMapInfo then C_MythicPlus.RequestMapInfo() end
			RecordWeekly()
		end)
	end
end)

--- This week's keystone/vault info for a character. After a weekly reset the saved data is out of
--- date, so this returns an empty week (with canClaim set if they had vault rewards waiting).
function ns:GetWeekly(playerKey)
	local player = self.lockoutDB.players[playerKey]
	local weekly = player and player.weekly
	if not weekly then return nil end

	if weekly.resetAt and weekly.resetAt <= time() then
		local hadRewards = weekly.canClaim
		for _, unlocked in pairs(weekly.vault or {}) do
			if unlocked > 0 then hadRewards = true end
		end
		return { vault = { raid = 0, dungeons = 0, world = 0 }, canClaim = hadRewards, stale = true }
	end
	return weekly
end

---------------------------------------------------------------------------
-- Currencies: whatever each character tracks on their backpack (crests, etc.)
---------------------------------------------------------------------------

local MAX_BACKPACK_CURRENCIES = 20

local function RecordCurrencies()
	if not ShouldTrack() or not C_CurrencyInfo or not C_CurrencyInfo.GetBackpackCurrencyInfo then return end
	local player = GetCurrentPlayer()
	local known = ns.lockoutDB.currencyInfo

	local currencies, signature = {}, {}
	for index = 1, MAX_BACKPACK_CURRENCIES do
		local backpack = C_CurrencyInfo.GetBackpackCurrencyInfo(index)
		if not backpack then break end
		local id = backpack.currencyTypesID
		if id and not ns.IsSecret(id) then
			local info = C_CurrencyInfo.GetCurrencyInfo(id)
			local quantity = info and info.quantity or backpack.quantity or 0
			currencies[id] = { quantity = quantity, max = info and info.maxQuantity or 0 }
			known[id] = { name = backpack.name, icon = backpack.iconFileID }
			table.insert(signature, id .. "=" .. quantity)
		end
	end

	local newSignature = table.concat(signature, ",")
	if player.currencySignature ~= newSignature then
		player.currencies = currencies
		player.currencySignature = newSignature
		ns:Fire("LOCKOUTS_CHANGED")
	end
end

ns:RegisterEvent("CURRENCY_DISPLAY_UPDATE", RecordCurrencies)
ns:RegisterEvent("PLAYER_LOGIN", function() C_Timer.After(6, RecordCurrencies) end)

--- Currency IDs tracked by any of the given characters, sorted by name.
function ns:GetTrackedCurrencies(players)
	local seen, list = {}, {}
	for _, player in ipairs(players) do
		for id in pairs(player.info.currencies or {}) do
			if not seen[id] and self.lockoutDB.currencyInfo[id] then
				seen[id] = true
				table.insert(list, id)
			end
		end
	end
	table.sort(list, function(a, b)
		return (self.lockoutDB.currencyInfo[a].name or "") < (self.lockoutDB.currencyInfo[b].name or "")
	end)
	return list
end

---------------------------------------------------------------------------
-- Queries for the UI
---------------------------------------------------------------------------

--- Forgets a character entirely (for deleted or renamed characters).
function ns:RemovePlayer(playerKey)
	self.lockoutDB.players[playerKey] = nil
	for _, chars in pairs(self.lockoutDB.lockouts) do
		chars[playerKey] = nil
	end
	PruneExpired()
	self:Fire("LOCKOUTS_CHANGED")
end

--- Characters to show, sorted by name.
function ns:GetLockoutPlayers(includeHidden)
	local list = {}
	for key, info in pairs(self.lockoutDB.players) do
		if includeHidden or info.shown then
			table.insert(list, { key = key, info = info })
		end
	end
	table.sort(list, function(a, b) return a.key < b.key end)
	return list
end

--- Instances that someone is currently saved to, sorted by name.
function ns:GetLockoutInstances(includeHidden)
	PruneExpired()
	local list = {}
	for instance in pairs(self.lockoutDB.lockouts) do
		if includeHidden or self.lockoutDB.shownInstances[instance] ~= false then
			table.insert(list, instance)
		end
	end
	table.sort(list)
	return list
end

--- Seconds until `player` is unsaved from `instance`, or nil.
function ns:GetLockoutTimeLeft(instance, player)
	local resetAt = self.lockoutDB.lockouts[instance] and self.lockoutDB.lockouts[instance][player]
	if resetAt then
		local left = resetAt - time()
		if left > 0 then return left end
	end
	return nil
end
