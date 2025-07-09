-- EasyMill.lua
local EasyMill = {}

-- Data
EasyMill.millableItemIDs = {
	-- Vanilla
	2447,
	765,
	785,
	2450,
	2452,
	2453,
	3355,
	3356,
	3357,
	3358,
	3369,
	3818,
	3820,
	3821,
	4625,
	8831,
	8836,
	8838,
	8839,
	8845,
	8846,
	13463,
	13464,
	13465,
	13466,
	13467,
	-- TBC
	22785,
	22786,
	22787,
	22789,
	22790,
	22791,
	22792,
	22793,
	-- Wrath
	36901,
	36903,
	36904,
	36905,
	36906,
	36907,
	37921,
	-- Cata
	52983,
	52984,
	52985,
	52986,
	52987,
	52988,
}

EasyMill.waitingForInfo = false
EasyMill.itemData = {}

-- Minimap button data object
local EasyMillLDB = LibStub("LibDataBroker-1.1"):NewDataObject("EasyMill", {
	type = "data source",
	text = "EasyMill",
	icon = "Interface\\Icons\\Ability_miling",
	OnClick = function(self, btn)
		if btn == "LeftButton" then
			if EasyMillFrame:IsShown() then
				EasyMillFrame:Hide()
			else
				EasyMillUI:showFrame()
			end
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:AddLine("EasyMill")
		tooltip:AddLine("|cffffff00Left-click:|r Toggle EasyMill window")
		tooltip:AddLine("|cffffff00Drag:|r Move this button")
	end,
})

-- Initialize item data
for _, id in ipairs(EasyMill.millableItemIDs) do
	EasyMill.itemData[id] = { count = 0 }
end

-- Initialize minimap icon
function EasyMill:InitializeMinimapIcon()
	if LibStub("LibDBIcon-1.0", true) then
		LibStub("LibDBIcon-1.0"):Register("EasyMill", EasyMillLDB, {})
	end
end

-- Price functions
function EasyMill:GetAuctionatorPrice(itemLink)
	if Auctionator and Auctionator.API.v1.GetAuctionPriceByItemLink then
		return Auctionator.API.v1.GetAuctionPriceByItemLink("EasyMill", itemLink) or 0
	end
	return 0
end

function EasyMill:GetMillResults(itemID)
	return MillTable[tostring(itemID)]
end

function EasyMill:GetMillAuctionPrice(itemID)
	local millResults = self:GetMillResults(itemID)

	if millResults == nil then
		return nil
	end

	local price = 0

	for reagentKey, allDrops in pairs(millResults) do
		local reagentPrice = Auctionator.Database:GetPrice(reagentKey)

		if reagentPrice == nil then
			return nil
		end

		for quantity, probability in ipairs(allDrops) do
			price = price + reagentPrice * quantity * probability
		end
	end

	return price
end

function EasyMill:getProfit(itemID)
	local entry = self.itemData[itemID]
	if not entry or not entry.link then
		return nil
	end

	local herbPrice = self:GetAuctionatorPrice(entry.link) or 0
	local millingPrice = self:GetMillAuctionPrice(itemID) or 0

	if millingPrice == 0 then
		return nil -- no milling price data yet
	end

	return millingPrice - (herbPrice * 5), millingPrice, herbPrice * 5
end

-- Bag scanning
function EasyMill:scanBags()
	-- reset counts
	for id in pairs(self.itemData) do
		self.itemData[id].count = 0
		self.itemData[id].link = nil
		self.itemData[id].name = nil
		self.itemData[id].icon = nil
	end

	local itemsToQuery = {}

	for bag = 0, NUM_BAG_SLOTS do
		local slots = C_Container.GetContainerNumSlots(bag)
		for slot = 1, slots do
			local itemID = C_Container.GetContainerItemID(bag, slot)
			if itemID and self.itemData[itemID] then
				local info = C_Container.GetContainerItemInfo(bag, slot)
				if info then
					local count = info.stackCount or 0
					local link = info.hyperlink
					local entry = self.itemData[itemID]
					entry.count = entry.count + count
					if not entry.link and link then
						entry.link = link
					end
				end
			end
		end
	end

	for id, entry in pairs(self.itemData) do
		if not entry.name then
			local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(id)
			if name then
				entry.name = name
				entry.icon = icon
				if not entry.link then
					entry.link = ("item:%d"):format(id)
				end
			else
				table.insert(itemsToQuery, id)
			end
		end
	end

	if #itemsToQuery > 0 and not self.waitingForInfo then
		self.waitingForInfo = true
	end
end

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "BAG_UPDATE_DELAYED" then
		if EasyMillFrame and EasyMillFrame:IsShown() then
			EasyMillUI:updateUI()
		end
	elseif event == "GET_ITEM_INFO_RECEIVED" then
		EasyMill.waitingForInfo = false
		if EasyMillFrame and EasyMillFrame:IsShown() then
			EasyMillUI:updateUI()
		end
	elseif event == "ADDON_LOADED" then
		local addonName = ...
		if addonName == "EasyMill" then
			EasyMill:InitializeMinimapIcon()
		end
	end
end)

-- Cast bar frame
local castInfo = {
	active = false,
	targetFrame = nil,
	spellName = GetSpellInfo(51005), -- Milling
}

-- Slash command
SLASH_EASYMILL1 = "/mill"
SlashCmdList["EASYMILL"] = function(msg)
	if EasyMillFrame:IsShown() then
		EasyMillFrame:Hide()
	else
		EasyMillUI:showFrame()
	end
end

-- Export the module
_G.EasyMill = EasyMill
