-- AutoLoot.lua - Auto-loot checkbox functionality
local AutoLoot = {}

AutoLoot.checkbox = nil

-- Create autoloot checkbox
function AutoLoot:createCheckbox(parentFrame, dropdown)
	local autolootCheckbox =
		CreateFrame("CheckButton", "EasyMillAutolootCheckbox", parentFrame, "InterfaceOptionsCheckButtonTemplate")
	autolootCheckbox:SetPoint("RIGHT", dropdown, "LEFT", -62, 2)
	autolootCheckbox:SetSize(24, 24)

	local autolootLabel = autolootCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	autolootLabel:SetPoint("LEFT", autolootCheckbox, "RIGHT", 0, 1)
	autolootLabel:SetText("Auto-loot")
	autolootLabel:SetTextColor(1, 1, 1)

	-- Set checkbox to current autoloot setting
	self:updateCheckboxState(autolootCheckbox)

	autolootCheckbox:SetScript("OnClick", function(self)
		-- Directly set the autoloot cvar based on checkbox state
		if self:GetChecked() then
			SetCVar("autoLootDefault", "1")
		else
			SetCVar("autoLootDefault", "0")
		end
	end)

	-- Tooltip for checkbox
	autolootCheckbox:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Toggle auto-loot setting")
		GameTooltip:AddLine("Controls your character's auto-loot behavior", 1, 1, 1)
		GameTooltip:Show()
	end)

	autolootCheckbox:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	self.checkbox = autolootCheckbox
	return autolootCheckbox
end

-- Update checkbox state based on current CVar
function AutoLoot:updateCheckboxState(checkbox)
	local checkboxToUpdate = checkbox or self.checkbox
	if checkboxToUpdate then
		local currentAutoloot = GetCVar("autoLootDefault")
		checkboxToUpdate:SetChecked(currentAutoloot == "1")
	end
end

-- Export the module
_G.AutoLoot = AutoLoot
