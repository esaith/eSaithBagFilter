-- eSaith Bag Filter
-- Lockouts: records raid & dungeon saves for every character you log in on.

local _, ns = ...

local function PlayerKey()
	return ("%s (%s)"):format(UnitName("player"), GetRealmName())
end

--- "The Stonevault" sorts under S; keys keep the pre-2.0 format so old data still lines up.
local function InstanceKey(name, difficultyName)
	name = name:gsub("^The ", "")
	return ("%s - %s"):format(name, difficultyName or "")
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

local function RecordLockouts()
	local db = ns.lockoutDB
	local numSaved = GetNumSavedInstances()
	local maxLevel = GetMaxLevelForPlayerExpansion and GetMaxLevelForPlayerExpansion() or 80

	-- Skip alts that have never been saved anywhere and aren't max level yet.
	local key = PlayerKey()
	if numSaved == 0 and UnitLevel("player") < maxLevel and not db.players[key] then
		return
	end

	local _, classFile = UnitClass("player")
	local player = db.players[key]
	if not player then
		player = { shown = true }
		db.players[key] = player
	end
	player.name = UnitName("player")
	player.realm = GetRealmName()
	player.class = classFile

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
ns:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isInitialLogin)
	if isInitialLogin then
		C_Timer.After(5, RequestRaidInfo)
	end
end)

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
