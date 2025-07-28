local SettingsFrame = {}

local function initializeSettings()
	if not EasyMillDB then
		EasyMillDB = {}
	end

	if EasyMillDB.showPigments == nil then
		EasyMillDB.showPigments = true
	end
end

function SettingsFrame:create(parentFrame)
	if self.frame then
		return self.frame
	end

	initializeSettings()

	self.frame = CreateFrame("Frame", "EasyMillSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
	self.frame:SetSize(400, 350)
	self.frame:SetFrameStrata("HIGH")
	self.frame:SetFrameLevel(110)
	self.frame:Hide()
	tinsert(UISpecialFrames, "EasyMillSettingsFrame")

	if parentFrame then
		self.frame:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", 10, 0)
	else
		self.frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
	end

	self.frame.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.frame.title:SetPoint("CENTER", self.frame.TitleBg, "CENTER")
	self.frame.title:SetText("EasyMill Settings")

	self:createSettingsContent()

	return self.frame
end

-- Create settings content
function SettingsFrame:createSettingsContent()
	local yOffset = -50
	local leftMargin = 20

	-- Auto-loot option
	local autoLootLabel = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	autoLootLabel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", leftMargin, yOffset)
	autoLootLabel:SetText("Auto-Loot:")
	autoLootLabel:SetTextColor(1, 0.82, 0) -- Gold color

	local autoLootCheckbox = CreateFrame("CheckButton", "EasyMillAutoLootCheckbox", self.frame, "UICheckButtonTemplate")
	autoLootCheckbox:SetPoint("LEFT", autoLootLabel, "RIGHT", 10, 0)
	autoLootCheckbox:SetSize(24, 24)

	-- Set checkbox to current autoloot setting
	local currentAutoloot = GetCVar("autoLootDefault")
	autoLootCheckbox:SetChecked(currentAutoloot == "1")

	autoLootCheckbox:SetScript("OnClick", function(self)
		if self:GetChecked() then
			SetCVar("autoLootDefault", "1")
		else
			SetCVar("autoLootDefault", "0")
		end
	end)

	-- Auto-loot description
	local autoLootDesc = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	autoLootDesc:SetPoint("TOPLEFT", autoLootLabel, "BOTTOMLEFT", 0, -5)
	autoLootDesc:SetWidth(350)
	autoLootDesc:SetJustifyH("LEFT")
	autoLootDesc:SetText(
		"Controls your character's auto-loot behavior. When enabled, you automatically loot items without clicking."
	)
	autoLootDesc:SetTextColor(0.7, 0.7, 0.7)

	yOffset = yOffset - 70

	-- Show pigments option
	local pigmentLabel = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	pigmentLabel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", leftMargin, yOffset)
	pigmentLabel:SetText("Display Pigment Information:")
	pigmentLabel:SetTextColor(1, 0.82, 0) -- Gold color

	local pigmentCheckbox = CreateFrame("CheckButton", "EasyMillPigmentCheckbox", self.frame, "UICheckButtonTemplate")
	pigmentCheckbox:SetPoint("LEFT", pigmentLabel, "RIGHT", 10, 0)
	pigmentCheckbox:SetSize(24, 24)
	pigmentCheckbox:SetChecked(EasyMillDB.showPigments)

	pigmentCheckbox:SetScript("OnClick", function(self)
		EasyMillDB.showPigments = self:GetChecked()
		if ItemDisplay and ItemDisplay.updateUI then
			ItemDisplay:updateUI()
		end
	end)

	-- Pigment description
	local pigmentDesc = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	pigmentDesc:SetPoint("TOPLEFT", pigmentLabel, "BOTTOMLEFT", 0, -5)
	pigmentDesc:SetWidth(350)
	pigmentDesc:SetJustifyH("LEFT")
	pigmentDesc:SetText("Shows which pigments each herb produces when milled, displayed below the herb information.")
	pigmentDesc:SetTextColor(0.7, 0.7, 0.7)

	yOffset = yOffset - 70

	-- macro section
	local macroLabel = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	macroLabel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", leftMargin, yOffset)
	macroLabel:SetText("Mill Last Pressed Herb macro:")
	macroLabel:SetTextColor(1, 0.82, 0) -- Gold color

	-- macro setup instructions
	local macroInstructions = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	macroInstructions:SetPoint("TOPLEFT", macroLabel, "BOTTOMLEFT", 0, -10)
	macroInstructions:SetWidth(350)
	macroInstructions:SetJustifyH("LEFT")
	macroInstructions:SetText(
		'The macro is Auto-set by the addon. To use it, simply go to your Macros menu and find "EasyMill_LastHerb", which you can drag to your action bar.\n\n'
			.. "It will mill the last herb you pressed a Mill button for, allowing you to quickly mill the same herb repeatedly.\n\n"
			.. "Or drag the icon below directly to your action bar:"
	)
	macroInstructions:SetTextColor(1, 1, 1)

	if MacroManager and MacroManager.createDragButton then
		local success, result = pcall(function()
			local button = MacroManager:createDragButton(self.frame, macroInstructions)
			if button then
				button:SetShown(true)
			end
			return button
		end)
	end

	self.autoLootCheckbox = autoLootCheckbox
	self.pigmentCheckbox = pigmentCheckbox
	self.macroInstructions = macroInstructions
end

-- Show settings frame
function SettingsFrame:show(parentFrame)
	if not self.frame then
		self:create(parentFrame)
	end

	-- Update position relative to parent frame
	if parentFrame then
		self.frame:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", 10, 0)
	end

	-- Update checkbox states
	if self.autoLootCheckbox then
		local currentAutoloot = GetCVar("autoLootDefault")
		self.autoLootCheckbox:SetChecked(currentAutoloot == "1")
	end
	if self.pigmentCheckbox then
		self.pigmentCheckbox:SetChecked(EasyMillDB.showPigments)
	end

	self.frame:Show()

	if MacroManager and MacroManager.createDragButton and self.macroInstructions then
		MacroManager:createDragButton(self.frame, self.macroInstructions)
	end
end

-- Hide settings frame
function SettingsFrame:hide()
	if self.frame then
		self.frame:Hide()
	end
end

function SettingsFrame:toggle(parentFrame)
	if InCombatLockdown() then
		return
	end
	if self.frame and self.frame:IsShown() then
		self:hide()
	else
		self:show(parentFrame)
	end
end

_G.SettingsFrame = SettingsFrame
