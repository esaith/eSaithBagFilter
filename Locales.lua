-- eSaith Bag Filter
-- Locales: every string the player sees goes through L["..."].
--
-- The English text is the key, so any string a translation doesn't cover simply shows in English.
-- To add a language, add a block for its locale code below, for example:
--
-- if locale == "deDE" then
--     L["Sell Items"] = "Gegenstände verkaufen"
--     L["Keep green BoE items"] = "Grüne BoE-Gegenstände behalten"
-- end
--
-- Strings containing %s / %d are format strings: keep the placeholders in the translation.

local _, ns = ...

local L = setmetatable({}, {
	__index = function(_, key) return key end,
})
ns.L = L

local locale = GetLocale()

if locale == "enUS" or locale == "enGB" then
	return -- English is the default
end

-- Translations go here.
