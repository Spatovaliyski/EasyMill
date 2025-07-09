-- ItemDisplay.lua - Item box creation and display logic
local ItemDisplay = {}

-- UI Elements
local buttons = {}

-- Expansion categorization based on item level ranges
local function getExpansionForItem(itemID)
    -- Vanilla herbs (item IDs mostly under 15000)
    if itemID <= 13467 then
        return "Vanilla"
    -- TBC herbs (22xxx range)
    elseif itemID >= 22785 and itemID <= 22793 then
        return "The Burning Crusade"
    -- Wrath herbs (36xxx-39xxx range)
    elseif itemID >= 36901 and itemID <= 39970 then
        return "Wrath of the Lich King"
    -- Cata herbs (52xxx range)
    elseif itemID >= 52983 and itemID <= 52988 then
        return "Cataclysm"
    -- MoP herbs (72xxx-79xxx range) 
    elseif itemID >= 72234 and itemID <= 79011 then
    else
        return "Unknown"
    end
end

-- Clear all buttons
function ItemDisplay:clearButtons()
    for _, b in ipairs(buttons) do
        b:Hide()
    end
    table.wipe(buttons)
end

-- Create expansion header
function ItemDisplay:createExpansionHeader(name, yOffset)
    local header = MainFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    header:SetPoint("TOPLEFT", 16, yOffset)
    header:SetText(name)
    header:SetTextColor(1, 0.82, 0)  -- Gold color
    
    table.insert(buttons, header)
    return header
end

-- Create a compact item box
function ItemDisplay:createItemBox(id, data, xPos, yPos)
    local itemWidth = 175
    local itemHeight = 80
    
    local item = CreateFrame("Frame", nil, MainFrame.scrollChild)
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
    if data.count >= 5 and not (TestData and TestData.testMode) then
        local btn = CreateFrame("Button", nil, item, "SecureActionButtonTemplate")
        btn:SetSize(70, 20)
        btn:SetPoint("BOTTOMRIGHT", -5, 5)

        btn:SetAttribute("type", "macro")
        local macroText = string.format("/cast Milling\n/use item:%d", id)
        btn:SetAttribute("macrotext", macroText)

        btn:SetScript("PostClick", function(self, button)
            if button == "LeftButton" and CastBar then
                CastBar:setLastMilledFrame(item)
            end
        end)

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
        htex:SetAllPoints()
        btn:SetPushedTexture(ptex)

        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("CENTER", 0, 0)
        text:SetText("Mill")
        text:SetTextColor(1, 1, 1)
    end

    table.insert(buttons, item)
    
    -- Create cast bar for this item
    if CastBar then
        CastBar:createCastBar(item)
    end
end

-- Update the UI
function ItemDisplay:updateUI()
    -- Only scan bags if we're not in test mode
    if not (TestData and TestData.testMode) then
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

-- Export the module
_G.ItemDisplay = ItemDisplay
