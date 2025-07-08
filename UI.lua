-- EasyMill - UI Part
local EasyMillUI = {}

-- UI Elements
local buttons = {}

-- Expansion categorization based on item level ranges
local function getExpansionForItem(itemID)
    -- Vanilla herbs (item IDs mostly under 15000)
    if itemID <= 13467 then
        return "Vanilla"
    -- TBC herbs (22xxx range)
    elseif itemID >= 22785 and itemID <= 22793 then
        return "TBC"
    -- Wrath herbs (36xxx-39xxx range)
    elseif itemID >= 36901 and itemID <= 39970 then
        return "Wrath"
    -- Cata herbs (52xxx range)
    elseif itemID >= 52983 and itemID <= 52988 then
        return "Cata"
    else
        return "Unknown"
    end
end

-- Create main frame
function EasyMillUI:createMainFrame()
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
    self.frame.title:SetText("EasyMill")

    self:createScrollFrame()
    self:createNoticeText()
    self:createTestDataDropdown()
end

-- Create scroll frame
function EasyMillUI:createScrollFrame()
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
        if not self.scrollIsAnimating then return end
        
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

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)    local w,h = scrollFrame:GetSize()
    scrollChild:SetSize(w,h)
    scrollFrame:SetScrollChild(scrollChild)

    scrollFrame:SetScrollChild(scrollChild)

    self.scrollFrame = scrollFrame
    self.scrollChild = scrollChild
end

-- Clear all buttons
function EasyMillUI:clearButtons()
    for _, b in ipairs(buttons) do
        b:Hide()
    end
    table.wipe(buttons)
end

-- Create expansion header
function EasyMillUI:createExpansionHeader(name, yOffset)
    local header = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    header:SetPoint("TOPLEFT", 16, yOffset)
    header:SetText(name)
    header:SetTextColor(1, 0.82, 0)  -- Gold color
    
    table.insert(buttons, header)
    return header
end

-- Create a compact item box
function EasyMillUI:createItemBox(id, data, xPos, yPos)
    local itemWidth = 175
    local itemHeight = 80
    
    local item = CreateFrame("Frame", nil, self.scrollChild)
    item:SetSize(itemWidth, itemHeight)
    item:SetPoint("TOPLEFT", xPos, yPos)

    -- Background
    local bg = item:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    -- Make icon clickable for tooltip
    local iconButton = CreateFrame("Button", nil, item)
    iconButton:SetSize(32, 32)
    iconButton:SetPoint("TOPLEFT", 5, -5)
    iconButton:EnableMouse(true)

    local icon = iconButton:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(data.icon or 134400)
    icon:SetDesaturated(data.count < 5)

    -- Tooltip functionality
    iconButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if data.link then
            GameTooltip:SetHyperlink(data.link)
        else
            GameTooltip:SetItemByID(id)
        end
        GameTooltip:Show()
    end)

    iconButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    local name = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("TOPLEFT", iconButton, "TOPRIGHT", 5, 0)
    name:SetPoint("TOPRIGHT", item, "TOPRIGHT", -5, -5)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    name:SetMaxLines(1)
    name:SetText(data.name or ("ItemID: " .. id))

    local countText = iconButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countText:SetPoint("BOTTOMRIGHT", iconButton, "BOTTOMRIGHT", -1, 1)
    countText:SetJustifyH("RIGHT")
    countText:SetText(tostring(data.count))
    countText:SetTextColor(1, 0.82, 0)
    countText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

    local profitText = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    profitText:SetPoint("TOPLEFT", iconButton, "TOPRIGHT", 5, -15)
    profitText:SetPoint("TOPRIGHT", item, "TOPRIGHT", -5, -15)
    profitText:SetJustifyH("LEFT")
    profitText:SetWordWrap(false)
    profitText:SetMaxLines(1)

    if Auctionator and Auctionator.API.v1.GetAuctionPriceByItemLink then 
        local profit, millingPrice, herbPrice = EasyMill:getProfit(id)
        if profit then
            local stacks = data.count > 0 and math.floor(data.count / 5) or 1
            local totalProfit = profit * stacks

            local absProfit = math.abs(totalProfit)
            local gold = math.floor(absProfit / 10000)
            local silver = math.floor((absProfit % 10000) / 100)
            local copper = absProfit % 100

            if totalProfit >= 0 then
                -- Profit: use WoW gold/silver/copper colors or gray if no herbs
                local colorPrefix = data.count > 0 and "" or "|cff808080"
                local colorSuffix = data.count > 0 and "" or "|r"
                
                local goldText = gold > 0 and string.format("%s|cffffd700%dg|r%s", colorPrefix, gold, colorSuffix) or ""
                local silverText = silver > 0 and string.format("%s|cffc7c7cf%ds|r%s", colorPrefix, silver, colorSuffix) or ""
                local copperText = copper > 0 and string.format("%s|cffeda55f%dc|r%s", colorPrefix, copper, colorSuffix) or ""
                
                if data.count == 0 then
                    goldText = gold > 0 and string.format("|cff808080%dg|r", gold) or ""
                    silverText = silver > 0 and string.format("|cff808080%ds|r", silver) or ""
                    copperText = copper > 0 and string.format("|cff808080%dc|r", copper) or ""
                end
                
                local parts = {}
                if gold > 0 then table.insert(parts, goldText) end
                if silver > 0 then table.insert(parts, silverText) end
                if copper > 0 then table.insert(parts, copperText) end
                
                local moneyText = table.concat(parts, " ")
                if moneyText == "" then 
                    moneyText = data.count > 0 and "|cffc7c7cf0s|r" or "|cff8080800s|r"
                end
                
                profitText:SetText("+" .. moneyText)
            else
                -- Loss: all red or gray if no herbs
                if data.count > 0 then
                    profitText:SetText(string.format("|cffff0000-%dg %ds %dc|r", gold, silver, copper))
                else
                    profitText:SetText(string.format("|cff808080-%dg %ds %dc|r", gold, silver, copper))
                end
            end
        else
            profitText:SetText("|cffffff00No data|r")
        end
    else
        profitText:SetText("")
    end

    -- Only show Mill button if we have enough herbs AND not in test mode
    if data.count >= 5 and not self.testMode then
        local btn = CreateFrame("Button", nil, item, "SecureActionButtonTemplate")
        btn:SetSize(70, 20)
        btn:SetPoint("BOTTOMRIGHT", -5, 5)

        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", string.format("/cast Milling\n/use item:%d", id))

        local ntex = btn:CreateTexture()
        ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
        ntex:SetTexCoord(0, 0.625, 0, 0.6875)
        ntex:SetAllPoints()
        btn:SetNormalTexture(ntex)

        local htex = btn:CreateTexture()
        htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
        htex:SetTexCoord(0, 0.625, 0, 0.6875)
        htex:SetAllPoints()
        btn:SetHighlightTexture(htex)

        local ptex = btn:CreateTexture()
        ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
        ptex:SetTexCoord(0, 0.625, 0, 0.6875)
        ptex:SetAllPoints()
        btn:SetPushedTexture(ptex)

        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("CENTER", 0, 0)
        text:SetText("Mill")
        text:SetTextColor(1, 1, 1)
    end

    table.insert(buttons, item)
end

-- Create test data dropdown
function EasyMillUI:createTestDataDropdown()
    local dropdown = CreateFrame("Frame", "EasyMillTestDropdown", self.frame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 10, -2)
    
    UIDropDownMenu_SetWidth(dropdown, 80)
    UIDropDownMenu_SetText(dropdown, "Test Data")
    
    self.testMode = false
    
    local function OnClick(self)
        local testAmount = self.value
        
        if testAmount == 0 then
            EasyMillUI.testMode = false
            EasyMill:scanBags()
        else
            EasyMillUI.testMode = true
            for id, data in pairs(EasyMill.itemData) do
                data.count = testAmount
            end
        end
        
        UIDropDownMenu_SetSelectedValue(dropdown, testAmount)
        EasyMillUI:updateUI()
    end
    
    local function initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        -- Reset option
        info.text = "Reset"
        info.value = 0
        info.func = OnClick
        info.checked = nil
        UIDropDownMenu_AddButton(info)
        
        local testValues = {100, 250, 500, 2500}
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
end

-- Auctionator notice text
function EasyMillUI:createNoticeText()
    local noticeFrame = CreateFrame("Frame", nil, self.frame)
    noticeFrame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 10, 8)
    noticeFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -120, 8)
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
end

-- Update the UI
function EasyMillUI:updateUI()
    -- Only scan bags if we're not in test mode
    if not self.testMode then
        EasyMill:scanBags()
    end
    
    self:clearButtons()

    -- Organize items by expansion using existing data
    local expansions = {
        {name = "Vanilla", items = {}},
        {name = "TBC", items = {}},
        {name = "Wrath", items = {}},
        {name = "Cata", items = {}}
    }
    
    -- Include ALL herbs, not just ones in bags
    for _, id in ipairs(EasyMill.millableItemIDs) do
        local data = EasyMill.itemData[id]
        if data then
            local expansion = getExpansionForItem(id)
            for _, exp in ipairs(expansions) do
                if exp.name == expansion then
                    table.insert(exp.items, {id = id, data = data})
                    break
                end
            end
        end
    end

    local currentY = -10
    local itemWidth = 175
    local itemHeight = 80
    local itemsPerRow = 5
    local itemSpacing = 3
    
    for _, expansion in ipairs(expansions) do
        if #expansion.items > 0 then
            self:createExpansionHeader(expansion.name, currentY)
            currentY = currentY - 25
            
            local itemIndex = 0
            for _, item in ipairs(expansion.items) do
                local row = math.floor(itemIndex / itemsPerRow)
                local col = itemIndex % itemsPerRow
                
                local xPos = 10 + (col * (itemWidth + itemSpacing))
                local yPos = currentY - (row * (itemHeight + itemSpacing))
                
                self:createItemBox(item.id, item.data, xPos, yPos)
                itemIndex = itemIndex + 1
            end
            
            -- Calculate how many rows were used and move currentY accordingly
            local rowsUsed = math.ceil(#expansion.items / itemsPerRow)
            currentY = currentY - (rowsUsed * (itemHeight + itemSpacing)) - 15
        end
    end
end

-- Initialize UI when loaded
local function onLoad()
    EasyMillUI:createMainFrame()
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