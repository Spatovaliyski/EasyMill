local MacroManager = {}

local function sortHerbStacks(herbID)
	if not herbID then
		return {}
	end

	local stacks = {}
	for bagID = 0, 4 do
		for slotID = 1, C_Container.GetContainerNumSlots(bagID) do
			local itemID = C_Container.GetContainerItemID(bagID, slotID)
			if itemID == herbID then
				local itemInfo = C_Container.GetContainerItemInfo(bagID, slotID)
				if itemInfo then
					table.insert(stacks, {
						bagID = bagID,
						slotID = slotID,
						count = itemInfo.stackCount,
					})
				end
			end
		end
	end

	table.sort(stacks, function(a, b)
		return a.count > b.count
	end)

	return stacks
end

function MacroManager:createKeybindMacro(herbID)
	local stacks = sortHerbStacks(herbID)
	local macroLines = { "/cast Milling" }

	for _, stack in ipairs(stacks) do
		if stack.count >= 5 then
			table.insert(macroLines, string.format("/use %d %d", stack.bagID, stack.slotID))
		end
	end

	if #macroLines == 1 then
		table.insert(macroLines, string.format("/use item:%d", herbID))
	end

	local macroText = table.concat(macroLines, "\n")

	local herbIcon = "INV_Misc_Herb_07"
	if EasyMill and EasyMill.itemData and EasyMill.itemData[herbID] and EasyMill.itemData[herbID].icon then
		local iconTexture = EasyMill.itemData[herbID].icon
		if iconTexture then
			if type(iconTexture) == "number" then
				herbIcon = iconTexture
			elseif type(iconTexture) == "string" then
				herbIcon = iconTexture:match("([^\\]+)$") or iconTexture
			end
		end
	end

	local macroName = "EasyMill_LastHerb"
	local macroIndex = GetMacroIndexByName(macroName)

	if macroIndex == 0 then
		CreateMacro(macroName, herbIcon, macroText, nil)
	else
		EditMacro(macroIndex, macroName, herbIcon, macroText)
	end

	self:updateDragButton(herbID)
end

function MacroManager:executeKeybindMacro()
	local macroName = "EasyMill_LastHerb"
	local macroIndex = GetMacroIndexByName(macroName)

	if macroIndex == 0 then
		return false
	end

	RunMacro(macroName)
	return true
end

function MacroManager:hasKeybindMacro()
	local macroName = "EasyMill_LastHerb"
	return GetMacroIndexByName(macroName) > 0
end

function MacroManager:initializeMacro()
	local macroName = "EasyMill_LastHerb"
	local macroIndex = GetMacroIndexByName(macroName)

	if macroIndex == 0 then
		CreateMacro(
			macroName,
			"Interface\\Icons\\Ability_miling",
			"/cast Milling\n-- Press a Mill button to set up this macro",
			nil
		)
	end
end

function MacroManager:getHerbIcon(herbID)
	if EasyMill and EasyMill.itemData and EasyMill.itemData[herbID] and EasyMill.itemData[herbID].icon then
		return EasyMill.itemData[herbID].icon
	end
	return "INV_Misc_Herb_07"
end

function MacroManager:createDragButton(parentFrame, anchorElement)
	if self.dragButton then
		if parentFrame then
			if self.dragButton:GetParent() ~= parentFrame then
				self.dragButton:SetParent(parentFrame)
			end
			self.dragButton:ClearAllPoints()
			if anchorElement then
				self.dragButton:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 20, 20)
			else
				self.dragButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 8, -8)
			end
			self.dragButton:SetShown(true)
		end
		return self.dragButton
	end

	local parent = parentFrame or EasyMillFrame
	if not parent then
		return nil
	end

	local buttonName = "EasyMillDragButton_" .. tostring(math.random(1000, 9999))
	local button = CreateFrame("Button", buttonName, parent, "SecureActionButtonTemplate")
	button:SetSize(36, 36)

	if anchorElement then
		button:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
	else
		button:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
	end

	local bg = button:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetTexture("Interface\\Buttons\\UI-Quickslot2")
	bg:SetTexCoord(0.2, 0.8, 0.2, 0.8)

	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetAllPoints()
	border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
	border:SetTexCoord(0.2, 0.8, 0.2, 0.8)
	border:SetAlpha(0.5)
	button.border = border

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
	icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
	icon:SetTexture("Interface\\Icons\\Ability_miling")
	button.icon = icon

	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	highlight:SetBlendMode("ADD")
	button.highlight = highlight

	button:SetAttribute("type", "macro")
	button:SetAttribute("macro", "EasyMill_LastHerb")

	-- Visual feedback on hover
	button:SetScript("OnEnter", function(self)
		self.border:SetAlpha(0.3)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("EasyMill Last Herb Macro")
		GameTooltip:AddLine("Drag this to your action bar", 1, 1, 1)
		GameTooltip:AddLine("Or bind a key in Key Bindings", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("Click to execute macro", 0.8, 0.8, 0.8)
		if self.herbName then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Last herb: " .. self.herbName, 0, 1, 0)
		end
		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function(self)
		self.border:SetAlpha(0)
		GameTooltip:Hide()
	end)

	button:SetScript("OnClick", function(self, buttonType)
		if buttonType == "LeftButton" and not self.isDragging then
			MacroManager:executeKeybindMacro()
		end
	end)

	button:SetScript("OnMouseDown", function(self, buttonType)
		if buttonType == "LeftButton" then
			self.isDragging = false
			self.startTime = GetTime()
		end
	end)

	button:SetScript("OnMouseUp", function(self, buttonType)
		if buttonType == "LeftButton" then
			self.isDragging = false
		end
	end)

	button:RegisterForDrag("LeftButton")
	button:SetScript("OnDragStart", function(self)
		self.isDragging = true
		local macroName = "EasyMill_LastHerb"
		local macroIndex = GetMacroIndexByName(macroName)
		if macroIndex > 0 then
			PickupMacro(macroIndex)
		end
	end)

	button:SetShown(true)

	self.dragButton = button
	return button
end

function MacroManager:updateDragButton(herbID)
	if not self.dragButton then
		self:createDragButton()
	end

	if not self.dragButton then
		return
	end

	local herbIcon = self:getHerbIcon(herbID)
	if herbIcon and self.dragButton.icon then
		if type(herbIcon) == "number" then
			self.dragButton.icon:SetTexture(herbIcon)
		else
			self.dragButton.icon:SetTexture("Interface\\Icons\\" .. herbIcon)
		end
	end

	if herbID then
		self.dragButton.herbName = C_Item.GetItemNameByID(herbID) or "Unknown Herb"
	end

	self.dragButton:SetAttribute("macro", "EasyMill_LastHerb")
	self.dragButton:SetShown(true)
end

function MacroManager:toggleDragButton(show)
	if self.dragButton then
		self.dragButton:SetShown(show)
	end
end

_G.MacroManager = MacroManager
