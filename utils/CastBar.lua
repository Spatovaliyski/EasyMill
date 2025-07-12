-- CastBar.lua
local CastBar = {}

CastBar.currentCastBar = nil -- Currently active cast bar
CastBar.currentItemID = nil -- Currently milling item ID
CastBar.castEventFrame = nil
CastBar.updateFrame = nil

-- Create cast bar for an item frame
function CastBar:createCastBar(parentFrame)
	if parentFrame.castBar then
		return
	end

	local bar = CreateFrame("StatusBar", nil, parentFrame)
	bar:SetSize(175, 3)
	bar:SetPoint("BOTTOM", parentFrame, "TOP", 0, 2)
	bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	bar:SetStatusBarColor(0.2, 0.6, 1, 1) -- Blue
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	bar:Hide()

	-- Background
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
	bg:SetVertexColor(0.2, 0.2, 0.2, 0.8)

	parentFrame.castBar = bar
end

-- Show cast bar for specific item
function CastBar:showCastBar(parentFrame, itemID)
	local bar = parentFrame.castBar

	if not bar then
		return
	end

	-- Hide any currently active cast bar
	if self.currentCastBar and self.currentCastBar ~= bar then
		self.currentCastBar:Hide()
	end

	-- Set this as the current active cast bar
	self.currentCastBar = bar
	self.currentItemID = itemID

	bar:SetStatusBarColor(0.2, 0.6, 1, 1) -- Blue
	bar:SetValue(0)
	bar:Show()
end

-- Hide cast bar for specific item
function CastBar:hideCastBar(parentFrame, itemID)
	if parentFrame and parentFrame.castBar then
		parentFrame.castBar:Hide()
	end

	-- Clear current if this was the active one
	if self.currentCastBar == parentFrame.castBar then
		self.currentCastBar = nil
		self.currentItemID = nil
	end
end

-- Setup improved cast detection
function CastBar:setupCastEvents()
	if self.castEventFrame then
		return
	end

	-- Event frame for cast start/stop detection
	self.castEventFrame = CreateFrame("Frame")
	self.castEventFrame:RegisterEvent("UNIT_SPELLCAST_START")
	self.castEventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self.castEventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
	self.castEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

	-- Update frame for progress monitoring
	self.updateFrame = CreateFrame("Frame")

	self.castEventFrame:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
		if unit ~= "player" then
			return
		end

		local spellName = GetSpellInfo(spellID)
		if spellName == "Milling" then
			if event == "UNIT_SPELLCAST_START" then
				-- Only start monitoring if we have an active cast bar
				if CastBar.currentCastBar and CastBar.currentItemID then
					CastBar:startProgressMonitoring()
				end
			elseif event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
				CastBar:stopProgressMonitoring()
				-- Show red flash on current cast bar
				if CastBar.currentCastBar then
					CastBar.currentCastBar:SetStatusBarColor(1, 0.2, 0.2, 1) -- Red
					C_Timer.After(0.6, function()
						if CastBar.currentCastBar then
							CastBar.currentCastBar:Hide()
							CastBar.currentCastBar = nil
							CastBar.currentItemID = nil
						end
					end)
				end
			elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
				CastBar:stopProgressMonitoring()
				-- Show green completion on current cast bar
				if CastBar.currentCastBar then
					CastBar.currentCastBar:SetStatusBarColor(0.2, 1, 0.2, 1) -- Green
					CastBar.currentCastBar:SetValue(1)
					C_Timer.After(0.6, function()
						if CastBar.currentCastBar then
							CastBar.currentCastBar:Hide()
							CastBar.currentCastBar = nil
							CastBar.currentItemID = nil
						end
					end)
				end
			end
		end
	end)
end

-- Start progress monitoring for specific item
function CastBar:startProgressMonitoring()
	if not self.updateFrame or not self.currentCastBar then
		return
	end

	self.updateFrame:SetScript("OnUpdate", function(self, elapsed)
		local name, text, texture, startTime, endTime = UnitCastingInfo("player")

		if name and name == "Milling" and CastBar.currentCastBar then
			local currentTime = GetTime() * 1000
			local progress = math.max(0, math.min((currentTime - startTime) / (endTime - startTime), 1))
			CastBar.currentCastBar:SetValue(progress)
		else
			-- No longer casting, stop monitoring
			CastBar:stopProgressMonitoring()
		end
	end)
end

-- Stop progress monitoring
function CastBar:stopProgressMonitoring()
	if self.updateFrame then
		self.updateFrame:SetScript("OnUpdate", nil)
	end
end

-- Set the active milling frame and start cast bar
function CastBar:startMilling(frame, itemID)
	-- Immediately show the cast bar for this specific herb
	self:showCastBar(frame, itemID)
end

-- Export the module
_G.CastBar = CastBar
