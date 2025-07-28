-- UI.lua - Main UI coordinator and initialization
local EasyMillUI = {}

-- Initialize UI when loaded
function EasyMillUI:initialize()
	MainFrame:create()
	NoticeText:createNotice(MainFrame.frame)
	local dropdown = TestData:createDropdown(MainFrame.frame)

	MainFrame:createSettingsButton(dropdown)
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
