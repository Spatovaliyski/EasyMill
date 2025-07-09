-- MainFrame.lua - Main frame creation and management
local MainFrame = {}

-- Create main frame
function MainFrame:create()
	self.frame = CreateFrame("Frame", "EasyMillFrame", UIParent, "BasicFrameTemplateWithInset")
	self.frame:SetSize(952, 600)
	self.frame:SetPoint("CENTER")
	self.frame:SetMovable(true)
	self.frame:EnableMouse(true)
	self.frame:RegisterForDrag("LeftButton")
	self.frame:SetScript("OnDragStart", self.frame.StartMoving)
	self.frame:SetScript("OnDragStop", self.frame.StopMovingOrSizing)
	self.frame:SetFrameStrata("HIGH")
	self.frame:SetFrameLevel(100)
	self.frame:Hide()
	tinsert(UISpecialFrames, "EasyMillFrame")

	self.frame.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.frame.title:SetPoint("CENTER", self.frame.TitleBg, "CENTER")
	self.frame.title:SetText("EasyMill " .. GetAddOnMetadata("EasyMill", "Version"))

	-- Create scroll frame
	self:createScrollFrame()

	return self.frame
end

-- Create scroll frame
function MainFrame:createScrollFrame()
	local inset = CreateFrame("Frame", nil, self.frame, "InsetFrameTemplate3")
	inset:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 8, -28)
	inset:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -10, 26)

	local scrollFrame = CreateFrame("ScrollFrame", "EasyMillScrollFrame", inset, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", inset, "TOPLEFT", 3, -3)
	scrollFrame:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -27, 3)

	scrollFrame.targetScrollValue = 0
	scrollFrame.scrollDuration = 0.15
	scrollFrame.scrollElapsed = 0
	scrollFrame.scrollStartValue = 0
	scrollFrame.scrollIsAnimating = false

	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript("OnMouseWheel", function(self, delta)
		local scrollAmount = 25
		local targetValue = self.scrollIsAnimating and self.targetScrollValue or self:GetVerticalScroll()

		if delta < 0 then
			targetValue = targetValue + scrollAmount
		else
			targetValue = targetValue - scrollAmount
		end

		targetValue = math.max(0, math.min(targetValue, self:GetVerticalScrollRange()))

		self.scrollStartValue = self:GetVerticalScroll()
		self.targetScrollValue = targetValue
		self.scrollElapsed = 0
		self.scrollIsAnimating = true
	end)

	scrollFrame:SetScript("OnUpdate", function(self, elapsed)
		if not self.scrollIsAnimating then
			return
		end

		self.scrollElapsed = self.scrollElapsed + elapsed
		local progress = math.min(self.scrollElapsed / self.scrollDuration, 1)
		local smoothedProgress = 1 - (1 - progress) * (1 - progress)

		local newPosition = self.scrollStartValue + (self.targetScrollValue - self.scrollStartValue) * smoothedProgress
		self:SetVerticalScroll(newPosition)

		if progress >= 1 then
			self.scrollIsAnimating = false
		end
	end)

	scrollFrame.ScrollBar:ClearAllPoints()
	scrollFrame.ScrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 7, -16)
	scrollFrame.ScrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 7, 16)

	local scrollUpButton = _G[scrollFrame:GetName() .. "ScrollBarScrollUpButton"]
	if scrollUpButton then
		scrollUpButton:ClearAllPoints()
		scrollUpButton:SetPoint("BOTTOM", scrollFrame.ScrollBar, "TOP", 1, -1)
	end

	local scrollDownButton = _G[scrollFrame:GetName() .. "ScrollBarScrollDownButton"]
	if scrollDownButton then
		scrollDownButton:ClearAllPoints()
		scrollDownButton:SetPoint("TOP", scrollFrame.ScrollBar, "BOTTOM", 1, -1)
	end

	local thumb = _G[scrollFrame:GetName() .. "ScrollBarThumbTexture"]
	if thumb then
		thumb:SetWidth(18)
		thumb:ClearAllPoints()
		thumb:SetPoint("RIGHT", scrollFrame.ScrollBar, "RIGHT", 1.8, 0)
	end

	local bg = scrollFrame:CreateTexture(nil, "BACKGROUND", nil, -6)
	bg:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
	bg:SetTexCoord(0, 0.45, 0.1640625, 1)
	bg:SetPoint("TOPLEFT", scrollFrame.ScrollBar, -5, 16)
	bg:SetPoint("BOTTOMRIGHT", scrollFrame.ScrollBar, 5, -16)

	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	local w, h = scrollFrame:GetSize()
	scrollChild:SetSize(w, h)
	scrollFrame:SetScrollChild(scrollChild)

	self.scrollFrame = scrollFrame
	self.scrollChild = scrollChild
end

-- Function to update autoloot checkbox state
function MainFrame:updateAutolootCheckbox()
	if AutoLoot and AutoLoot.updateCheckboxState then
		AutoLoot:updateCheckboxState()
	end
end

-- Show the main frame and update checkbox
function MainFrame:showFrame()
	self.frame:Show()
	self:updateAutolootCheckbox()
	if ItemDisplay then
		ItemDisplay:updateUI()
	end
end

-- Export the module
_G.MainFrame = MainFrame
