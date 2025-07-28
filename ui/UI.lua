-- UI.lua - Main UI coordinator and initialization
local EasyMillUI = {}

-- Initialize UI when loaded
function EasyMillUI:initialize()
	-- Create main frame
	MainFrame:create()

	-- Create notice text
	NoticeText:createNotice(MainFrame.frame)

	-- Create test data dropdown
	local dropdown = TestData:createDropdown(MainFrame.frame)

	-- Create settings button (where auto-loot checkbox used to be)
	MainFrame:createSettingsButton(dropdown)

	-- Setup cast events
	CastBar:setupCastEvents()
end

-- Show the main frame
function EasyMillUI:showFrame()
	MainFrame.frame:Show()
	self:updateUI()
end

-- Update the UI
function EasyMillUI:updateUI()
	if ItemDisplay then
		ItemDisplay:updateUI()
	end
end

-- Initialize UI when addon loads
local function onLoad()
	EasyMillUI:initialize()
end

-- Wait for addon to load
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("ADDON_LOADED")
loadFrame:SetScript("OnEvent", function(self, event, addonName)
	if addonName == "EasyMill" then
		onLoad()
		loadFrame:UnregisterEvent("ADDON_LOADED")
	end
end)

-- Export the module
_G.EasyMillUI = EasyMillUI
