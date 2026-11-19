-- eSaith Bag Filter
-- Core: namespace, saved variables, migrations, events and slash commands.

local ADDON_NAME, ns = ...
local L = ns.L

ns.name = ADDON_NAME
ns.title = "eSaith Bag Filter"
ns.version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"
ns.icon = "Interface\\Icons\\Ability_BossFelOrcs_Necromancer_Orange"

local DB_VERSION = 2

---------------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------------

--- Midnight (12.x) hides some values from addons ("secret values").
--- Any value we get from the client that might be secret goes through this.
function ns.IsSecret(value)
	return issecretvalue ~= nil and issecretvalue(value) or false
end

function ns.Print(fmt, ...)
	local msg = select("#", ...) > 0 and fmt:format(...) or fmt
	print(("|cff2bc3e2%s|r: %s"):format(ns.title, msg))
end

local function CopyDefaults(src, dst)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then dst[k] = {} end
			CopyDefaults(v, dst[k])
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
	return dst
end

--- Number of bag slots to scan: backpack, 4 bags and the reagent bag.
ns.LAST_BAG = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS

--- Iterate every occupied bag slot: for bag, slot, info in ns.IterateBags() do
function ns.IterateBags()
	return coroutine.wrap(function()
		for bag = 0, ns.LAST_BAG do
			for slot = 1, C_Container.GetContainerNumSlots(bag) do
				local info = C_Container.GetContainerItemInfo(bag, slot)
				if info and info.itemID and not ns.IsSecret(info.itemID) then
					coroutine.yield(bag, slot, info)
				end
			end
		end
	end)
end

---------------------------------------------------------------------------
-- Saved variables
---------------------------------------------------------------------------

local DEFAULTS = {
	version = DB_VERSION,
	options = {
		autoSellJunk = false,
		keepGreenBoE = false,
		keepBlueBoE = false,
		keepEpicBoE = false,
		keepTradeGoods = false,
		keepUpgrades = false,
		keepUncollected = false,
		confirmSales = true,
		autoRepair = false,
		repairWithGuildFunds = true,
		keepAuctionValue = false,
		auctionMultiplier = 5,
		markBagItems = true,
		uiScale = 1,
		quickLoot = true,
		autoGreedGreens = false,
		saveLootBetweenSessions = true,
		autoQuest = false,
		showCoordinates = false,
		openWithVendor = false,
		showMinimapButton = true,
	},
	filters = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true },
	showHidden = false,
	kept = {},   -- [itemID] = true: never sold
	hidden = {}, -- [itemID] = true: never sold and not listed
	window = { width = 760, height = 520 },
	minimap = { angle = 225 },
	runs = {}, -- recent dungeon/raid/delve runs, newest first (see Runs.lua)
}

-- Per-character: whether this character uses its own copy of the options.
local CHARACTER_DEFAULTS = {
	useCharacterSettings = false,
	options = {},
}

local LOCKOUT_DEFAULTS = {
	version = DB_VERSION,
	players = {},        -- ["Name (Realm)"] = { name, realm, class, shown }
	shownInstances = {}, -- ["Instance - Difficulty"] = true/false
	lockouts = {},       -- ["Instance - Difficulty"] = { ["Name (Realm)"] = resetTimestamp }
	currencyInfo = {},   -- [currencyID] = { name, icon }
}

-- Pre-2.0 options used different names.
local LEGACY_OPTIONS = {
	enableAutoSellGrays = "autoSellJunk",
	keepUncommonBOEItems = "keepGreenBoE",
	keepRareBOEItems = "keepBlueBoE",
	keepTradeGoods = "keepTradeGoods",
	quickLoot = "quickLoot",
	enableAutoGreedGreenItems = "autoGreedGreens",
	saveLootBetweenSessions = "saveLootBetweenSessions",
	questComplete = "autoQuest",
	coordinatesEnabled = "showCoordinates",
}

local function MigrateSettings(old)
	if type(old) ~= "table" or (old.version or 0) >= DB_VERSION then
		return old
	end

	local new = { version = DB_VERSION, options = {}, kept = {}, window = {} }

	if type(old.options) == "table" then
		for oldKey, newKey in pairs(LEGACY_OPTIONS) do
			if old.options[oldKey] ~= nil then
				new.options[newKey] = old.options[oldKey] and true or false
			end
		end
	end

	if type(old.items) == "table" and type(old.items.kept) == "table" then
		for itemID, kept in pairs(old.items.kept) do
			if kept then new.kept[itemID] = true end
		end
	end

	return new
end

local RESERVED_LEGACY_KEYS = { players = true, instances = true, boe = true, hiddenInstances = true }

local function MigrateLockouts(old)
	if type(old) ~= "table" or (old.version or 0) >= DB_VERSION then
		return old
	end

	local new = { version = DB_VERSION, players = {}, shownInstances = {}, lockouts = {} }

	if type(old.players) == "table" then
		for key, info in pairs(old.players) do
			new.players[key] = { name = info.name, realm = info.server, shown = info.shown == true }
		end
	end

	if type(old.instances) == "table" then
		for instance, shown in pairs(old.instances) do
			new.shownInstances[instance] = shown and true or false
		end
	end

	for instance, chars in pairs(old) do
		if not RESERVED_LEGACY_KEYS[instance] and type(chars) == "table" then
			new.lockouts[instance] = {}
			for player, data in pairs(chars) do
				if type(data) == "table" and data.time then
					new.lockouts[instance][player] = data.time
				end
			end
		end
	end

	return new
end

local function InitializeDatabase()
	eSaithBagFilterVar = CopyDefaults(DEFAULTS, MigrateSettings(eSaithBagFilterVar) or {})
	eSaithBagFilterInstances = CopyDefaults(LOCKOUT_DEFAULTS, MigrateLockouts(eSaithBagFilterInstances) or {})

	eSaithBagFilterCharVar = CopyDefaults(CHARACTER_DEFAULTS, eSaithBagFilterCharVar or {})

	ns.db = eSaithBagFilterVar
	ns.lockoutDB = eSaithBagFilterInstances
	ns.charDB = eSaithBagFilterCharVar
	ns:UpdateActiveOptions()

	-- Loot history: { [zoneName] = { [itemID] = true } }
	local loot = eSaithBagFilterInstanceLoot
	if type(loot) ~= "table" or not ns.opts.saveLootBetweenSessions then
		loot = {}
	end
	loot.All = nil -- older versions stored a duplicate "All" bucket; it is now computed
	eSaithBagFilterInstanceLoot = loot
	ns.lootDB = loot
end

--- ns.opts is the options table in use: the account-wide one, or this character's own copy.
function ns:UpdateActiveOptions()
	if self.charDB.useCharacterSettings then
		CopyDefaults(DEFAULTS.options, self.charDB.options)
		self.opts = self.charDB.options
	else
		self.opts = self.db.options
	end
end

function ns:SetUseCharacterSettings(enabled)
	if enabled and next(self.charDB.options) == nil then
		-- Start from the current account-wide settings.
		for key, value in pairs(self.db.options) do
			self.charDB.options[key] = value
		end
	end
	self.charDB.useCharacterSettings = enabled and true or false
	self:UpdateActiveOptions()
	self:Fire("SETTINGS_CHANGED")
end

--- Gold made from sales through the addon since you logged in.
ns.session = { soldCount = 0, soldMoney = 0 }

function ns:ResetEverything()
	eSaithBagFilterVar = nil
	eSaithBagFilterInstances = nil
	eSaithBagFilterInstanceLoot = nil
	eSaithBagFilterCharVar = nil
	InitializeDatabase()
	ns:ProtectEquippedItems()
	ns:Fire("SETTINGS_CHANGED")
	ns:Fire("LOOT_CHANGED")
	ns:Fire("LOCKOUTS_CHANGED")
	ns.Print(L["All settings and history have been reset."])
end

---------------------------------------------------------------------------
-- Tiny internal message bus so data code never has to know about the UI
---------------------------------------------------------------------------

local listeners = {}

function ns:On(message, fn)
	listeners[message] = listeners[message] or {}
	table.insert(listeners[message], fn)
end

function ns:Fire(message, ...)
	for _, fn in ipairs(listeners[message] or {}) do
		fn(...)
	end
end

---------------------------------------------------------------------------
-- Event dispatch
---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
local handlers = {}

--- Register a handler for a game event. Several modules may listen to one event.
function ns:RegisterEvent(event, fn)
	if not handlers[event] then
		handlers[event] = {}
		eventFrame:RegisterEvent(event)
	end
	table.insert(handlers[event], fn)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	for _, fn in ipairs(handlers[event]) do
		fn(event, ...)
	end
end)

ns:RegisterEvent("ADDON_LOADED", function(_, name)
	if name ~= ADDON_NAME then return end
	InitializeDatabase()
	ns:Fire("INITIALIZED")
end)

ns:RegisterEvent("PLAYER_LOGOUT", function()
	if not ns.opts.saveLootBetweenSessions then
		eSaithBagFilterInstanceLoot = {}
	end
end)

---------------------------------------------------------------------------
-- Slash commands & addon compartment
---------------------------------------------------------------------------

SLASH_ESAITHBAGFILTER1 = "/efilter"
SLASH_ESAITHBAGFILTER2 = "/esbf"

SlashCmdList.ESAITHBAGFILTER = function(msg)
	local command = (msg or ""):match("^(%S*)"):lower()

	if command == "center" then
		ns:ResetWindowPosition()
		ns:ShowWindow()
	elseif command == "reset" then
		ns:ConfirmReset()
	elseif command == "lockouts" then
		ns:ShowWindow("lockouts")
	elseif command == "settings" or command == "options" then
		ns:ShowWindow("settings")
	elseif command == "debug" then
		ns:PrintDebugInfo()
	elseif command == "minimap" then
		ns.opts.showMinimapButton = not ns.opts.showMinimapButton
		ns:Fire("SETTINGS_CHANGED")
	elseif command == "help" then
		ns.Print(L["Commands:"])
		print("  /efilter - " .. L["toggle the window"])
		print("  /efilter lockouts - " .. L["show lockouts, keystones and the Great Vault"])
		print("  /efilter settings - " .. L["show settings"])
		print("  /efilter minimap - " .. L["show or hide the minimap button"])
		print("  /efilter center - " .. L["move the window back to the center"])
		print("  /efilter debug - " .. L["print diagnostic info (hover an item first to include it)"])
		print("  /efilter reset - " .. L["erase all settings and history"])
	else
		ns:ToggleWindow()
	end
end

function eSaithBagFilter_OnAddonCompartmentClick()
	ns:ToggleWindow()
end

function eSaithBagFilter_OnAddonCompartmentEnter(_, button)
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	GameTooltip:SetText(ns.title)
	GameTooltip:AddLine(L["Click to open. Type /efilter help for commands."], 1, 1, 1, true)
	GameTooltip:Show()
end

function eSaithBagFilter_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end
