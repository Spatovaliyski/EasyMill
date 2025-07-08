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
    self.frame:SetSize(900, 600)  -- Wide frame to accommodate 6 items per row
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
    self.frame.title:SetText("Auto Miller")

    self:createScrollFrame()
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
    header:SetPoint("TOPLEFT", 20, yOffset)
    header:SetText(name)
    header:SetTextColor(1, 0.82, 0)  -- Gold color
    
    table.insert(buttons, header)
    return header
end

-- Create a compact item box
function EasyMillUI:createItemBox(id, data, xPos, yPos)
    local itemWidth = 160
    local itemHeight = 80
    
    local item = CreateFrame("Frame", nil, self.scrollChild)
    item:SetSize(itemWidth, itemHeight)
    item:SetPoint("TOPLEFT", xPos, yPos)

    -- Background
    local bg = item:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    local icon = item:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("TOPLEFT", 5, -5)
    icon:SetTexture(data.icon or 134400)
    icon:SetDesaturated(data.count < 5)

    local name = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 5, 0)
    name:SetPoint("TOPRIGHT", item, "TOPRIGHT", -5, -5)
    name:SetJustifyH("LEFT")
    name:SetText((data.name or ("ItemID: " .. id)) .. " (" .. data.count .. ")")

    local profitText = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    profitText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 5, -15)
    profitText:SetPoint("TOPRIGHT", item, "TOPRIGHT", -5, -20)
    profitText:SetJustifyH("LEFT")

    local profit, millingPrice, herbPrice = EasyMill:getProfit(id)
    if profit then
        local stacks = math.floor(data.count / 5)
        local totalProfit = profit * stacks

        local absProfit = math.abs(totalProfit)
        local gold = math.floor(absProfit / 10000)
        local silver = math.floor((absProfit % 10000) / 100)
        local copper = absProfit % 100

        if totalProfit >= 0 then
            -- Profit: use WoW gold/silver/copper colors
            local goldText = gold > 0 and string.format("|cffffd700%dg|r", gold) or ""
            local silverText = silver > 0 and string.format("|cffc7c7cf%ds|r", silver) or ""
            local copperText = copper > 0 and string.format("|cffeda55f%dc|r", copper) or ""
            
            local parts = {}
            if gold > 0 then table.insert(parts, goldText) end
            if silver > 0 then table.insert(parts, silverText) end
            if copper > 0 then table.insert(parts, copperText) end
            
            local moneyText = table.concat(parts, " ")
            if moneyText == "" then moneyText = "|cffc7c7cf0s|r" end
            
            profitText:SetText("+" .. moneyText)
        else
            -- Loss: all red
            profitText:SetText(string.format("|cffff0000-%dg %ds %dc|r", gold, silver, copper))
        end
    else
        profitText:SetText("|cffffff00No data|r")
    end

    if data.count >= 5 then
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
    end

    table.insert(buttons, item)
end

-- Update the UI
function EasyMillUI:updateUI()
    EasyMill:scanBags()
    self:clearButtons()

    -- Organize items by expansion using existing data
    local expansions = {
        {name = "Vanilla", items = {}},
        {name = "TBC", items = {}},
        {name = "Wrath", items = {}},
        {name = "Cata", items = {}}
    }
    
    -- Sort ALL items into expansions (not just those with count > 0)
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
    local itemWidth = 160
    local itemHeight = 80
    local itemsPerRow = 5
    local itemSpacing = 5
    
    for _, expansion in ipairs(expansions) do
        if #expansion.items > 0 then
            -- Create expansion header
            self:createExpansionHeader(expansion.name, currentY)
            currentY = currentY - 35
            
            -- Create items in grid layout (6 per row)
            local itemIndex = 0
            for _, item in ipairs(expansion.items) do
                local row = math.floor(itemIndex / itemsPerRow)
                local col = itemIndex % itemsPerRow
                
                local xPos = 16 + (col * (itemWidth + itemSpacing))
                local yPos = currentY - (row * (itemHeight + itemSpacing))
                
                self:createItemBox(item.id, item.data, xPos, yPos)
                itemIndex = itemIndex + 1
            end
            
            -- Calculate how many rows were used and move currentY accordingly
            local rowsUsed = math.ceil(#expansion.items / itemsPerRow)
            currentY = currentY - (rowsUsed * (itemHeight + itemSpacing)) - 20
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