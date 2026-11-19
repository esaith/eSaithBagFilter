-- eSaith Bag Filter
-- Prices: Auction House values from TradeSkillMaster or Auctionator, when one is installed.

local ADDON_NAME, ns = ...

local TSM_PRICE_SOURCE = "dbmarket"

local function HasTSM()
	return TSM_API ~= nil and TSM_API.GetCustomPriceValue ~= nil and TSM_API.ToItemString ~= nil
end

local function HasAuctionator()
	return Auctionator ~= nil and Auctionator.API ~= nil and Auctionator.API.v1 ~= nil
end

--- Name of the addon providing Auction House prices, or nil.
function ns:GetPriceSourceName()
	if HasTSM() then return "TradeSkillMaster" end
	if HasAuctionator() then return "Auctionator" end
	return nil
end

--- Auction House value of an item in copper, or nil when unknown.
--- Other addons' APIs are called with pcall so a change on their side can't break selling.
function ns:GetAuctionValue(link, itemID)
	if HasTSM() and link then
		local ok, itemString = pcall(TSM_API.ToItemString, link)
		if ok and itemString then
			local priceOK, value = pcall(TSM_API.GetCustomPriceValue, TSM_PRICE_SOURCE, itemString)
			if priceOK and type(value) == "number" and value > 0 then return value end
		end
	end

	if HasAuctionator() then
		local api = Auctionator.API.v1
		if link and api.GetAuctionPriceByItemLink then
			local ok, value = pcall(api.GetAuctionPriceByItemLink, ADDON_NAME, link)
			if ok and type(value) == "number" and value > 0 then return value end
		end
		if itemID and api.GetAuctionPriceByItemID then
			local ok, value = pcall(api.GetAuctionPriceByItemID, ADDON_NAME, itemID)
			if ok and type(value) == "number" and value > 0 then return value end
		end
	end

	return nil
end
