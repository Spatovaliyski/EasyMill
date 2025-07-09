-- CastBar.lua - Cast bar functionality
local CastBar = {}

CastBar.lastMilledFrame = nil
CastBar.castEventFrame = nil

-- Create cast bar for an item frame
function CastBar:createCastBar(parentFrame)
	if parentFrame.castBar then
		return
	end

	local bar = CreateFrame("StatusBar", nil, parentFrame)
	bar:SetSize(175, 3) -- Match item width, very thin height
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

-- Show cast bar and start monitoring
function CastBar:showCastBar(parentFrame)
	local bar = parentFrame.castBar
	if not bar then
		return
	end

	-- Clear any existing OnUpdate script to prevent conflicts
	bar:SetScript("OnUpdate", nil)

	bar:SetStatusBarColor(0.2, 0.6, 1, 1) -- Blue
	bar:SetValue(0)
	bar:Show()

	-- Start monitoring actual cast progress with OnUpdate only
	bar:SetScript("OnUpdate", function(self, elapsed)
		local name, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo("player")

		if name and name == "Milling" then
			-- Calculate real progress
			local currentTime = GetTime() * 1000
			local progress = (currentTime - startTime) / (endTime - startTime)
			progress = math.max(0, math.min(progress, 1))

			self:SetValue(progress)
		else
			-- Cast finished successfully - stop monitoring and show green flash
			self:SetScript("OnUpdate", nil)
			self:SetStatusBarColor(0.2, 1, 0.2, 1) -- Green
			self:SetValue(1)

			C_Timer.After(0.6, function()
				if self then
					self:Hide()
				end
			end)
		end
	end)
end

-- Setup cast events
function CastBar:setupCastEvents()
	if self.castEventFrame then
		return
	end

	self.castEventFrame = CreateFrame("Frame")
	self.castEventFrame:RegisterEvent("UNIT_SPELLCAST_START")
	self.castEventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self.castEventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")

	self.castEventFrame:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
		if unit ~= "player" then
			return
		end

		local spellName = GetSpellInfo(spellID)
		if spellName == "Milling" then
			if event == "UNIT_SPELLCAST_START" then
				if CastBar.lastMilledFrame and CastBar.lastMilledFrame.castBar then
					CastBar:showCastBar(CastBar.lastMilledFrame)
				end
			elseif event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
				if CastBar.lastMilledFrame and CastBar.lastMilledFrame.castBar then
					local bar = CastBar.lastMilledFrame.castBar
					bar:SetScript("OnUpdate", nil)

					-- Red flash for cancelled/failed cast
					bar:SetStatusBarColor(1, 0.2, 0.2, 1) -- Red
					bar:SetValue(bar:GetValue())

					C_Timer.After(0.6, function()
						if bar then
							bar:Hide()
						end
					end)
				end
			end
		end
	end)
end

-- Set the last milled frame for cast bar tracking
function CastBar:setLastMilledFrame(frame)
	self.lastMilledFrame = frame
end

-- Export the module
_G.CastBar = CastBar
