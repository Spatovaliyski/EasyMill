-- NoticeText.lua - Auctionator notice and link functionality
local NoticeText = {}

-- Create Auctionator notice text
function NoticeText:createNotice(parentFrame)
	local noticeFrame = CreateFrame("Frame", nil, parentFrame)
	noticeFrame:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 10, 8)
	noticeFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -120, 8)
	noticeFrame:SetHeight(16)

	local noticeText = noticeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	noticeText:SetPoint("LEFT", noticeFrame, "LEFT", 0, 0)
	noticeText:SetJustifyH("LEFT")
	noticeText:SetText("|cffffd700Notice:|r |cffffffffThe potential profit data is taken by using|r ")

	-- Create clickable Auctionator link
	local linkButton = CreateFrame("Button", nil, noticeFrame)
	linkButton:SetSize(63, 16)
	linkButton:SetPoint("LEFT", noticeText, "RIGHT", 0, 0)

	local linkText = linkButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	linkText:SetAllPoints()
	linkText:SetJustifyH("LEFT")
	linkText:SetText("|cff00ccffAuctionator|r")

	linkButton:SetScript("OnClick", function()
		local editBox = ChatEdit_ChooseBoxForSend()
		if editBox then
			editBox:Show()
			editBox:SetText("https://www.curseforge.com/wow/addons/auctionator")
			editBox:HighlightText()
			print("|cff00ccffEasyMill:|r Auctionator download link copied to chat. Press Ctrl+C to copy it.")
		end
	end)

	linkButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Click to copy Auctionator download link")
		GameTooltip:AddLine("https://www.curseforge.com/wow/addons/auctionator", 1, 1, 1)
		GameTooltip:Show()
		linkText:SetText("|cff66ddffAuctionator|r")
	end)

	linkButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		linkText:SetText("|cff00ccffAuctionator|r")
	end)

	local remainingText = noticeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	remainingText:SetPoint("LEFT", linkButton, "RIGHT", 0, 0)
	remainingText:SetJustifyH("LEFT")
	remainingText:SetText("|cffffffff. It's suggested to scan regularly to keep the data up-to-date.|r")

	return noticeFrame
end

-- Export the module
_G.NoticeText = NoticeText
