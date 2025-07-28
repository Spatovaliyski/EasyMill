-- EasyMill.lua
local EasyMill = {}

-- Data
EasyMill.millableItemIDs = {}
EasyMill.waitingForInfo = false
EasyMill.itemData = {}
EasyMill.wasOpenBeforeCombat = false
EasyMill.settingsWasOpenBeforeCombat = false

-- Initialize millable item IDs from MillTable
local function initializeMillableItems()
	EasyMill.millableItemIDs = {}
	if MillTable then
		for herbIDStr, _ in pairs(MillTable) do
			local herbID = tonumber(herbIDStr)
			if herbID then
				table.insert(EasyMill.millableItemIDs, herbID)
			end
		end
		-- Sort the IDs for consistent ordering
		table.sort(EasyMill.millableItemIDs)
	end
end

-- Minimap button data object
local EasyMillLDB = LibStub("LibDataBroker-1.1"):NewDataObject("EasyMill", {
	type = "data source",
	text = "EasyMill",
	icon = "Interface\\Icons\\Ability_miling",
	OnClick = function(self, btn)
		if btn == "LeftButton" then
			if InCombatLockdown() then
				print("EasyMill: Cannot open during combat")
				return
			end
			if EasyMillFrame:IsShown() then
				EasyMillFrame:Hide()
			else
				EasyMillFrame:Show()
				EasyMillUI:updateUI()
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

local function initializeItemData()
	initializeMillableItems() -- Call this first to populate the array

	for _, id in ipairs(EasyMill.millableItemIDs) do
		EasyMill.itemData[id] = { count = 0 }
	end
end

-- Initialize minimap icon
function EasyMill:InitializeMinimapIcon()
	initializeItemData()

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
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Leaving combat
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
			if MacroManager and MacroManager.initializeMacro then
				MacroManager:initializeMacro()
			end
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		-- Entering combat - hide frame if it's open
		if EasyMillFrame and EasyMillFrame:IsShown() then
			EasyMill.wasOpenBeforeCombat = true
			EasyMillFrame:Hide()
			print("EasyMill: Hidden during combat")
		else
			EasyMill.wasOpenBeforeCombat = false
		end

		-- Also hide settings frame if it's open
		if SettingsFrame and SettingsFrame.frame and SettingsFrame.frame:IsShown() then
			EasyMill.settingsWasOpenBeforeCombat = true
			SettingsFrame:hide()
		else
			EasyMill.settingsWasOpenBeforeCombat = false
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		-- Leaving combat - reopen frame if it was open before
		if EasyMill.wasOpenBeforeCombat and EasyMillFrame then
			EasyMillFrame:Show()
			EasyMillUI:updateUI()
			print("EasyMill: Reopened after combat")
			EasyMill.wasOpenBeforeCombat = false
		end

		-- Reopen settings frame if it was open before
		if EasyMill.settingsWasOpenBeforeCombat and SettingsFrame then
			SettingsFrame:show(EasyMillFrame)
			EasyMill.settingsWasOpenBeforeCombat = false
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
	if InCombatLockdown() then
		print("EasyMill: Cannot open during combat")
		return
	end
	if EasyMillFrame:IsShown() then
		EasyMillFrame:Hide()
	else
		EasyMillFrame:Show()
		EasyMillUI:updateUI()
	end
end

-- Variable to track last pressed herb
EasyMill.lastPressedHerb = nil

-- Function to set last pressed herb
function EasyMill:setLastPressedHerb(itemID)
	self.lastPressedHerb = itemID
end

BINDING_HEADER_EASYMILL = "EasyMill"
BINDING_NAME_EASYMILL_MILL_LAST = "Mill Last Herb"

-- Global function for keybind (required for WoW binding system)
function EasyMill_UpdateAndMill()
	-- Check if we have a last pressed herb
	if EasyMill.lastPressedHerb then
		-- Use MacroManager to execute the keybind macro
		if MacroManager then
			if not MacroManager:executeKeybindMacro() then
				print("EasyMill: Press a Mill button first to set up the macro.")
			end
		else
			print("EasyMill: MacroManager not found. Try reloading the addon.")
		end
	else
		print("EasyMill: No herb has been milled yet. Press a Mill button first to set the herb type.")
	end
end

-- Legacy function for compatibility
function EasyMill_MillLastHerb()
	EasyMill_UpdateAndMill()
end

-- Export the module
_G.EasyMill = EasyMill
