-- eSaith Bag Filter
-- Runs: what each dungeon, raid or delve run earned (gold looted plus the vendor value of items).

local _, ns = ...

local MAX_RUNS = 20
local REENTER_GRACE = 15 * 60 -- re-entering within 15 minutes (e.g. after a wipe) continues the same run

local current
local lastMoney

local RUN_INSTANCE_TYPES = { party = true, raid = true, scenario = true }

local function GetInstanceRunInfo()
	local inInstance, instanceType = IsInInstance()
	if not inInstance or not RUN_INSTANCE_TYPES[instanceType] then return nil end
	local name, _, _, difficultyName = GetInstanceInfo()
	if not name or name == "" or ns.IsSecret(name) then return nil end
	return name, difficultyName
end

local function EndCurrentRun()
	if current then
		current.ended = time()
		current = nil
	end
end

local function UpdateRun()
	local name, difficulty = GetInstanceRunInfo()
	if not name then
		EndCurrentRun()
		ns:Fire("RUNS_CHANGED")
		return
	end

	if current and current.zone == name and current.difficulty == difficulty then return end
	EndCurrentRun()

	local runs = ns.db.runs
	local latest = runs[1]
	local lastActive = latest and (latest.ended or latest.lastActive or latest.started) or 0
	if latest and latest.zone == name and latest.difficulty == difficulty and time() - lastActive < REENTER_GRACE then
		latest.ended = nil
		current = latest
	else
		current = { zone = name, difficulty = difficulty, started = time(), money = 0, itemValue = 0, items = 0 }
		table.insert(runs, 1, current)
		while #runs > MAX_RUNS do table.remove(runs) end
	end
	current.lastActive = time()
	ns:Fire("RUNS_CHANGED")
end

ns:RegisterEvent("PLAYER_ENTERING_WORLD", function()
	lastMoney = GetMoney()
	UpdateRun()
end)
ns:RegisterEvent("ZONE_CHANGED_NEW_AREA", UpdateRun)

ns:RegisterEvent("PLAYER_MONEY", function()
	local money = GetMoney()
	local delta = money - (lastMoney or money)
	lastMoney = money
	if current and delta > 0 and not ns.IsAtNonLootWindow() then
		current.money = current.money + delta
		current.lastActive = time()
		ns:Fire("RUNS_CHANGED")
	end
end)

ns:On("ITEMS_GAINED", function(itemID, count)
	if not current then return end
	local data = ns:GetItemData(itemID)
	current.itemValue = current.itemValue + (data and data.sellPrice or 0) * count
	current.items = current.items + count
	current.lastActive = time()
	ns:Fire("RUNS_CHANGED")
end)

--- Most recent first. The first entry may be the run you're in right now.
function ns:GetRuns()
	return self.db.runs
end

function ns:GetCurrentRun()
	return current
end

function ns:ClearRuns()
	wipe(self.db.runs)
	current = nil
	UpdateRun()
end
