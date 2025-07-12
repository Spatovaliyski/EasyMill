-- TestData.lua - Test data dropdown and functionality
local TestData = {}

TestData.testMode = false

-- Create test data dropdown
function TestData:createDropdown(parentFrame)
	local dropdown = CreateFrame("Frame", "EasyMillTestDropdown", parentFrame, "UIDropDownMenuTemplate")
	dropdown:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 10, -2)

	UIDropDownMenu_SetWidth(dropdown, 80)
	UIDropDownMenu_SetText(dropdown, "Test Data")

	local function OnClick(self)
		local testAmount = self.value

		if testAmount == 0 then
			TestData.testMode = false
			EasyMill:scanBags()
		else
			TestData.testMode = true
			for id, data in pairs(EasyMill.itemData) do
				data.count = testAmount
			end
		end

		UIDropDownMenu_SetSelectedValue(dropdown, testAmount)
		if ItemDisplay then
			ItemDisplay:updateUI()
		end
	end

	local function initialize(self, level)
		local info = UIDropDownMenu_CreateInfo()

		-- Reset option
		info.text = "Stop testing"
		info.value = 0
		info.func = OnClick
		info.checked = nil
		UIDropDownMenu_AddButton(info)

		local testValues = { 100, 250, 500, 2500 }
		for _, amount in ipairs(testValues) do
			info = UIDropDownMenu_CreateInfo()
			info.text = string.format("x%d herbs", amount)
			info.value = amount
			info.func = OnClick
			info.checked = nil
			UIDropDownMenu_AddButton(info)
		end
	end

	UIDropDownMenu_Initialize(dropdown, initialize)

	self.dropdown = dropdown
	return dropdown
end

-- Export the module
_G.TestData = TestData
