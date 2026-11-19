-- luacheck configuration: https://luacheck.readthedocs.io
-- Run locally with `luacheck .`; GitHub runs it on every push (.github/workflows/lint.yml).
--
-- When you use a new WoW API, add it to read_globals below. Anything not listed is reported as an
-- undefined global, which is how typos like `GetMoneyStirng` get caught before you load the game.

std = "lua51"
max_line_length = false
exclude_files = { "Libs/", ".luacheckrc" }

ignore = {
	"212", -- unused argument: WoW callbacks often receive arguments we don't need
	"42.", -- shadowing a local (e.g. reusing `ok, value` in sibling blocks)
	"43.", -- shadowing an upvalue
}

-- Globals this addon defines or writes to.
globals = {
	-- saved variables
	"eSaithBagFilterVar",
	"eSaithBagFilterInstances",
	"eSaithBagFilterInstanceLoot",
	"eSaithBagFilterCharVar",
	-- slash command and addon compartment
	"SLASH_ESAITHBAGFILTER1",
	"SLASH_ESAITHBAGFILTER2",
	"SlashCmdList",
	"eSaithBagFilter_OnAddonCompartmentClick",
	"eSaithBagFilter_OnAddonCompartmentEnter",
	"eSaithBagFilter_OnAddonCompartmentLeave",
	-- Blizzard tables we add entries to
	"StaticPopupDialogs",
	"UISpecialFrames",
}

-- WoW API used by the addon (read only).
read_globals = {
	-- Lua extensions in the WoW client
	"strtrim", "tContains", "time", "tinsert", "wipe", "issecretvalue",

	-- C_ namespaces
	"C_AddOns", "C_ChallengeMode", "C_ClassColor", "C_Container", "C_CurrencyInfo", "C_DateAndTime",
	"C_Item", "C_Map", "C_MythicPlus", "C_PlayerInteractionManager", "C_Timer", "C_TransmogCollection",
	"C_WeeklyRewards",

	-- functions
	"AcceptQuest", "BreakUpLargeNumbers", "BuybackItem", "CanGuildBankRepair", "CanMerchantRepair", "Clamp",
	"CompleteQuest", "CreateColor", "CreateFrame", "GetAverageItemLevel", "GetBuildInfo", "GetBuybackItemInfo",
	"GetBuybackItemLink", "GetCursorPosition", "GetGuildBankWithdrawMoney", "GetInstanceInfo",
	"GetInventoryItemID", "GetLocale", "GetLootRollItemInfo", "GetLootSlotInfo", "GetMaxLevelForPlayerExpansion",
	"GetMoney", "GetMoneyString", "GetNumBuybackItems", "GetNumLootItems", "GetNumQuestChoices",
	"GetNumSavedInstances", "GetQuestReward", "GetRealmName", "GetRealZoneText", "GetRepairAllCost",
	"GetSavedInstanceInfo", "GetTime", "HandleModifiedItemClick", "InCombatLockdown", "IsInGuild", "IsInInstance",
	"IsQuestCompletable", "IsShiftKeyDown", "LootSlot", "PlaySound", "RepairAllItems", "RequestRaidInfo",
	"RollOnLoot", "SetItemButtonCount", "SetItemButtonDesaturated", "SetItemButtonQuality",
	"SetItemButtonTexture", "StaticPopup_Show", "UnitClass", "UnitLevel", "UnitName",
	"PanelTemplates_DeselectTab", "PanelTemplates_SelectTab", "PanelTemplates_SetNumTabs", "PanelTemplates_SetTab",
	"GameTooltip_AddBlankLineToTooltip", "GameTooltip_AddColoredLine", "GameTooltip_AddErrorLine",
	"GameTooltip_AddHighlightLine", "GameTooltip_AddInstructionLine", "GameTooltip_AddNormalLine",
	"GameTooltip_Hide", "GameTooltip_SetTitle",

	-- frames and objects
	"ColorManager", "ContainerFrameCombinedBags", "Enum", "GameTooltip", "ItemLocation", "MailFrame",
	"MenuUtil", "MerchantFrame", "Minimap", "TradeFrame", "UIParent",

	-- constants and global strings
	"CANCEL", "COPPER_PER_GOLD", "HIGHLIGHT_FONT_COLOR", "INVSLOT_FIRST_EQUIPPED", "INVSLOT_LAST_EQUIPPED",
	"ITEM_QUALITY_COLORS", "NO", "NORMAL_FONT_COLOR", "NUM_BAG_SLOTS", "NUM_CONTAINER_FRAMES",
	"NUM_TOTAL_EQUIPPED_BAG_SLOTS", "REMOVE", "SETTINGS", "SOUNDKIT", "YES",

	-- optional addons we integrate with
	"Auctionator", "Baganator", "TSM_API",
}
