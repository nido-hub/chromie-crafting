local A = ChromieCrafting
local M = A.Model
local MIN_WIDTH, MIN_HEIGHT = 980, 740
local RECIPE_ROW_HEIGHT = 24
local colors = {optimal = "ffff8040", medium = "ffffff00", easy = "ff40bf40", trivial = "ff909090", gray = "ff909090"}
local professionSpells = {2259, 2018, 2550, 7411, 4036, 3273, 45357, 25229, 2108, 2656, 3908}

local function itemIcon(recipe)
    return (recipe.itemID and GetItemIcon(recipe.itemID)) or recipe.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function professionIcon(profession)
    for _, id in ipairs(professionSpells) do
        local name, _, icon = GetSpellInfo(id)
        if name == profession then return icon end
    end
    local mining, _, icon = GetSpellInfo(2575)
    if profession == mining then return icon end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function textureTag(icon, size)
    return "|T" .. (icon or "Interface\\Icons\\INV_Misc_QuestionMark") .. ":" .. size .. ":" .. size .. ":0:0|t "
end

local function label(parent, text, x, y, width, template)
    local f = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    f:SetPoint("TOPLEFT", x, y)
    if width then f:SetWidth(width) end
    f:SetJustifyH("LEFT"); f:SetJustifyV("TOP"); f:SetText(text)
    return f
end

local function solid(parent, layer, r, g, b, alpha)
    local texture = parent:CreateTexture(nil, layer)
    texture:SetTexture(r, g, b, alpha)
    return texture
end

local function surface(parent, r, g, b, gold)
    local fill = solid(parent, "BACKGROUND", r, g, b, 1)
    fill:SetAllPoints(parent)
    local border = gold and {0.48, 0.36, 0.17} or {0.25, 0.22, 0.17}
    for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local edge = solid(parent, "BORDER", border[1], border[2], border[3], 1)
        if side == "TOP" or side == "BOTTOM" then
            edge:SetPoint(side .. "LEFT", parent, side .. "LEFT", 0, 0)
            edge:SetPoint(side .. "RIGHT", parent, side .. "RIGHT", 0, 0)
            edge:SetHeight(1)
        else
            edge:SetPoint("TOP" .. side, parent, "TOP" .. side, 0, 0)
            edge:SetPoint("BOTTOM" .. side, parent, "BOTTOM" .. side, 0, 0)
            edge:SetWidth(1)
        end
    end
    parent.surface = {fill=fill}
end

local function button(parent, text, x, y, width, callback, template)
    local b = CreateFrame("Button", nil, parent, template)
    surface(b, 0.14, 0.115, 0.075, true)
    local font = label(b, "", 0, 0)
    font:ClearAllPoints(); font:SetPoint("LEFT", b, "LEFT", 3, 0); font:SetPoint("RIGHT", b, "RIGHT", -3, 0)
    font:SetHeight(20); font:SetJustifyH("CENTER"); font:SetJustifyV("MIDDLE")
    b:SetFontString(font)
    b:SetNormalFontObject("GameFontHighlightSmall")
    b:SetHighlightFontObject("GameFontNormalSmall")
    b:SetDisabledFontObject("GameFontDisableSmall")
    local highlight = solid(b, "HIGHLIGHT", 0.8, 0.6, 0.22, 0.15)
    highlight:SetAllPoints(b)
    b:SetPoint("TOPLEFT", x, y); b:SetWidth(width); b:SetHeight(23); b:SetText(text)
    if callback then b:SetScript("OnClick", callback) end
    return b
end

local function enable(widget, condition)
    if condition then widget:Enable() else widget:Disable() end
end

local function edit(parent, x, y, width, numeric)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetPoint("TOPLEFT", x, y); box:SetWidth(width); box:SetHeight(24)
    box:SetFontObject("GameFontHighlightSmall"); box:SetTextInsets(6, 6, 0, 0)
    box:SetJustifyH(numeric and "CENTER" or "LEFT")
    surface(box, 0.035, 0.032, 0.026, true)
    box:SetAutoFocus(false); box:SetMaxLetters(numeric and 4 or 100)
    if numeric then box:SetNumeric(true) end
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

local function textScroll(parent, name, x, y, width, height)
    local scroll = CreateFrame("ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", x, y); scroll:SetWidth(width - 22); scroll:SetHeight(height)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(width - 26); child:SetHeight(height)
    scroll:SetScrollChild(child)
    -- Inline reagent icons extend above the first line; keep room inside the scroll clip.
    local text = label(child, "", 0, -16, width - 30)
    scroll.text, scroll.content = text, child
    local function setText(value)
        if text:GetText() ~= value then scroll:SetVerticalScroll(0) end
        text:SetText(value)
        child:SetHeight(math.max(scroll:GetHeight(), text:GetStringHeight() + 24))
    end
    scroll:SetScript("OnSizeChanged", function(self)
        child:SetWidth(self:GetWidth() - 4); text:SetWidth(self:GetWidth() - 8)
        setText(text:GetText())
    end)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * 30)))
    end)
    return setText, scroll
end

local function dropdown(parent, name, x, y, width, choices, current, changed)
    local drop = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    drop:SetPoint("TOPLEFT", x, y); UIDropDownMenu_SetWidth(drop, width)
    UIDropDownMenu_Initialize(drop, function()
        for _, choice in ipairs(choices) do
            local value, text = choice[1], choice[2]
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = text, current() == value
            info.func = function()
                UIDropDownMenu_SetText(drop, text); CloseDropDownMenus(); changed(value)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    for _, choice in ipairs(choices) do if choice[1] == current() then UIDropDownMenu_SetText(drop, choice[2]) end end
    return drop
end

function A:QueueChanged()
    if self.running or self.pending or self.withdrawal then return end
    self:Render()
end

function A:SaveWindowGeometry()
    local point, _, relativePoint, x, y = self.frame:GetPoint()
    self.db.position = {point=point, relativePoint=relativePoint, x=x, y=y}
    self.db.size = {width=self.frame:GetWidth(), height=self.frame:GetHeight()}
end

function A:RequestClose()
    if not self.frame or not self.frame:IsShown() then return end
    if InCombatLockdown() then
        self.hideAfterCombat = true
        self.status = "Fermeture demandée : la fenêtre sera fermée à la sortie du combat."
        self.statusText:SetText(self.status)
        return
    end
    if self.hideAfterCombat then self.status = "Fenêtre fermée après le combat." end
    self.hideAfterCombat = nil
    self.frame:Hide()
end

function A:LayoutUI()
    local width, height = self.frame:GetWidth(), self.frame:GetHeight()
    local bodyHeight = height - 174
    local leftWidth = 350 + (width - MIN_WIDTH)*0.35
    local rightX = leftWidth + 28
    local rightWidth = width - 78 - rightX
    local pageWidth, pageHeight = rightWidth - 32, bodyHeight - 62
    local queueWidth = pageWidth/2 - 8
    self.content:SetWidth(width - 24); self.content:SetHeight(bodyHeight)
    self.leftPanel:SetWidth(leftWidth); self.leftPanel:SetHeight(bodyHeight)
    self.recipeVisibleRows = math.floor((bodyHeight - 150)/RECIPE_ROW_HEIGHT)
    self.queueVisibleRows = math.floor((pageHeight - 135)/25)
    self.title:SetWidth(width - 300); self.subtitle:SetWidth(width - 300)
    self.skillTrack:SetWidth(width - 310)
    self.search:SetWidth(leftWidth - 24)
    self.searchLabel:SetWidth(leftWidth - 24)
    self.favoritesFilter:ClearAllPoints(); self.favoritesFilter:SetPoint("TOPRIGHT", self.leftPanel, "TOPRIGHT", -12, -76)
    self.recipeList:SetWidth(leftWidth - 16); self.recipeList:SetHeight(self.recipeVisibleRows*RECIPE_ROW_HEIGHT)
    for _, row in ipairs(self.recipeRows) do
        row:SetWidth(leftWidth - 16); row.text:SetWidth(leftWidth - 91)
        row.amount:ClearAllPoints(); row.amount:SetPoint("TOPRIGHT", -5, -4)
    end
    self.detailPanel:ClearAllPoints(); self.detailPanel:SetPoint("TOPLEFT", rightX, 0)
    self.detailPanel:SetWidth(rightWidth); self.detailPanel:SetHeight(bodyHeight)
    self.recipePage:SetWidth(pageWidth); self.recipePage:SetHeight(pageHeight)
    self.queuePage:SetWidth(pageWidth); self.queuePage:SetHeight(pageHeight)
    self.detailTitle:SetWidth(pageWidth - 104)
    self.descriptionScroll:SetWidth(pageWidth - 22)
    self.reagentScroll:SetWidth(pageWidth - 22); self.reagentScroll:SetHeight(pageHeight - 328)
    self.reagentTitle:SetWidth(pageWidth)
    self.output:SetWidth(pageWidth - 265)
    self.queueList:SetWidth(queueWidth); self.queueList:SetHeight(self.queueVisibleRows*25)
    self.queueCount:SetWidth(queueWidth - 76)
    for _, row in ipairs(self.queueRows) do
        row:SetWidth(queueWidth); row.text:SetWidth(queueWidth - 146)
    end
    local needsX = pageWidth/2 + 8
    self.needsTitle:ClearAllPoints(); self.needsTitle:SetPoint("TOPLEFT", needsX, -8)
    self.needsScroll:ClearAllPoints(); self.needsScroll:SetPoint("TOPLEFT", needsX, -36)
    self.needsScroll:SetWidth(pageWidth/2 - 30); self.needsScroll:SetHeight(self.queueVisibleRows*25)
    self.queueHelp:SetWidth(pageWidth)
    self.statusText:SetWidth(width - 100)
    self.recipeCount:SetWidth(leftWidth - 104)
    self:ShowDetailPage(self.detailPage or "recipe")
    if self.professionTabs then self:RenderNavigation() end
end

function A:ShowDetailPage(page)
    if InCombatLockdown() then return end
    self.detailPage = page
    if page == "queue" then self.recipePage:Hide(); self.queuePage:Show()
    else self.queuePage:Hide(); self.recipePage:Show() end
    self.recipePageButton.surface.fill:SetTexture(page == "recipe" and 0.28 or 0.12, 0.18, 0.075, 1)
    self.queuePageButton.surface.fill:SetTexture(page == "queue" and 0.28 or 0.12, 0.18, 0.075, 1)
end

function A:CreateUI()
    if self.frame then return end
    local frame = CreateFrame("Frame", "ChromieCraftingFrame", UIParent)
    self.frame = frame
    local scale = math.min(1, (UIParent:GetWidth() - 80)/MIN_WIDTH, (UIParent:GetHeight() - 48)/MIN_HEIGHT)
    local maxWidth, maxHeight = (UIParent:GetWidth() - 24)/scale, (UIParent:GetHeight() - 24)/scale
    if self.db.skinVersion ~= 1 then
        self.db.position, self.db.size = nil, nil
        self.db.skinVersion = 1
    end
    local size = self.db.size or {}
    frame:SetScale(scale)
    frame:SetWidth(math.max(MIN_WIDTH, math.min(maxWidth, tonumber(size.width) or MIN_WIDTH)))
    frame:SetHeight(math.max(MIN_HEIGHT, math.min(maxHeight, tonumber(size.height) or MIN_HEIGHT)))
    frame:SetResizable(true); frame:SetMinResize(MIN_WIDTH, MIN_HEIGHT); frame:SetMaxResize(maxWidth, maxHeight)
    local p = self.db.position
    if p then frame:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y) else frame:SetPoint("CENTER") end
    -- Solid textures also work when a client texture pack makes tooltip backgrounds transparent.
    surface(frame, 0.055, 0.047, 0.034, true)
    local header = solid(frame, "BACKGROUND", 0.11, 0.085, 0.045, 1)
    header:SetPoint("TOPLEFT", 2, -2); header:SetPoint("TOPRIGHT", -2, -2); header:SetHeight(66)
    frame:SetFrameStrata("HIGH"); frame:SetClampedToScreen(true)
    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self)
        if InCombatLockdown() then return end
        self:StopMovingOrSizing()
        A:SaveWindowGeometry()
    end)
    frame:Hide()
    frame:SetScript("OnHide", function()
        if A.escapeFrame then A.escapeFrame:Hide() end
        if A.switching then return end
        if A.withdrawal then A:FinishWithdrawal("Retrait arrêté : fenêtre fermée.") end
        A:Stop()
        if A.open then A.open = false; CloseTradeSkill() end
    end)
    -- Escape hides an unprotected proxy, never the ancestor of secure profession tabs.
    local escape = CreateFrame("Frame", "ChromieCraftingEscapeFrame", UIParent)
    self.escapeFrame = escape
    escape:SetWidth(1); escape:SetHeight(1); escape:SetPoint("CENTER")
    escape:Hide()
    escape:SetScript("OnHide", function() A:RequestClose() end)
    frame:SetScript("OnShow", function() escape:Show() end)
    UISpecialFrames[#UISpecialFrames + 1] = "ChromieCraftingEscapeFrame"
    local close = button(frame, "X", 0, 0, 26, function() A:RequestClose() end)
    self.closeButton = close
    close:ClearAllPoints(); close:SetPoint("TOPRIGHT", -8, -8)
    local native = button(frame, "Fenêtre Blizzard", 0, 0, 125, function() A:UseNative() end)
    native:ClearAllPoints(); native:SetPoint("TOPRIGHT", -43, -8)
    self.headerIcon = frame:CreateTexture(nil, "ARTWORK")
    self.headerIcon:SetPoint("TOPLEFT", 16, -12); self.headerIcon:SetWidth(44); self.headerIcon:SetHeight(44)
    self.title = label(frame, "Chromie Crafting", 76, -12, 600, "GameFontNormalLarge")
    self.subtitle = label(frame, "", 76, -34, 600)
    self.skillTrack = CreateFrame("Frame", nil, frame)
    self.skillTrack:SetPoint("TOPLEFT", 76, -51); self.skillTrack:SetWidth(670); self.skillTrack:SetHeight(9)
    surface(self.skillTrack, 0.025, 0.022, 0.018, true)
    self.skillFill = solid(self.skillTrack, "ARTWORK", 0.75, 0.38, 0.06, 1)
    self.skillFill:SetPoint("TOPLEFT", 2, -2); self.skillFill:SetHeight(5)
    self:CreateNavigation()

    local root = frame
    local frame = CreateFrame("Frame", nil, root)
    self.content = frame
    frame:SetPoint("TOPLEFT", 12, -132)
    frame:SetWidth(root:GetWidth() - 24); frame:SetHeight(root:GetHeight() - 174)
    self.leftPanel = CreateFrame("Frame", nil, frame)
    self.leftPanel:SetPoint("TOPLEFT", 0, 0)
    surface(self.leftPanel, 0.075, 0.066, 0.049, true)
    local left = self.leftPanel

    self.search = edit(left, 12, -20, 326)
    self.search:SetScript("OnTextChanged", function(self)
        A.options.search = self:GetText(); A.recipeOffset = 0; A:Render()
    end)
    self.search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    self.search:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Rechercher une recette ou une catégorie"); GameTooltip:Show()
    end)
    self.search:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.searchLabel = label(left, "Rechercher une recette", 12, -5, 326)
    dropdown(left, "ChromieCraftingState", -6, -47, 135,
        {{"all","Toutes les recettes"},{"known","Connues"},{"unknown","À apprendre"}},
        function() return A.options.state end,
        function(value) A.options.state=value; A.recipeOffset=0; A:Render() end)
    dropdown(left, "ChromieCraftingSort", 157, -47, 135,
        {{"skill","Compétence"},{"name","Nom"},{"available","Planifiables"}},
        function() return A.options.sort end,
        function(value) A.options.sort=value; A.recipeOffset=0; A:Render() end)
    local craftable = CreateFrame("CheckButton", "ChromieCraftingMakeable", left, "UICheckButtonTemplate")
    craftable:SetPoint("TOPLEFT", 8, -76); craftable:SetWidth(24); craftable:SetHeight(24)
    _G[craftable:GetName() .. "Text"]:SetText("Planifiables")
    craftable:SetScript("OnClick", function(self) A.options.craftable=self:GetChecked() and true or false; A.recipeOffset=0; A:Render() end)
    self.favoritesFilter = button(left, "Favoris", 240, -76, 85, function()
        A.options.favoritesOnly = not A.options.favoritesOnly; A.recipeOffset=0; A:Render()
    end)

    local list = CreateFrame("Frame", nil, left)
    self.recipeList = list
    list:SetPoint("TOPLEFT", 8, -110); list:SetWidth(334); list:SetHeight(408)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta) A:ScrollRecipes(-delta * 3) end)
    self.recipeRows = {}
    for i = 1, math.floor((maxHeight - 324)/RECIPE_ROW_HEIGHT) do
        local row = CreateFrame("Button", nil, list)
        self.recipeRows[i] = row
        row:SetPoint("TOPLEFT", 0, -(i-1)*RECIPE_ROW_HEIGHT); row:SetWidth(334); row:SetHeight(RECIPE_ROW_HEIGHT)
        row.background = solid(row, "BACKGROUND", 0.1, 0.085, 0.055, 1); row.background:SetAllPoints(row)
        row.selection = solid(row, "BORDER", 0.38, 0.28, 0.08, 0.8); row.selection:SetAllPoints(row); row.selection:Hide()
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.star = button(row, "", 0, 0, 22, function() if row.data and not row.data.header then A:ToggleFavorite(row.data.key) end end)
        row.star:SetHeight(21)
        row.text = label(row, "", 26, -4, 343)
        row.text:SetHeight(20)
        row.amount = label(row, "", 370, -4, 45)
        row:SetScript("OnClick", function(self)
            local r = self.data
            if not r then return end
            if r.header then A.options.collapsed[r.category] = not A.options.collapsed[r.category]
            else A.selectedKey = r.key end
            A:Render()
        end)
        row:SetScript("OnEnter", function(self)
            local r = self.data
            if not r or r.header then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if r.spellID then GameTooltip:SetHyperlink("spell:" .. r.spellID)
            elseif r.itemLink then GameTooltip:SetHyperlink(r.itemLink)
            else GameTooltip:SetText(r.name) end
            GameTooltip:AddLine(r.known and "Connue — opérations planifiables selon les stocks sélectionnés, pas nécessairement fabricables maintenant" or "À apprendre — catalogue AtlasLoot, disponibilité serveur à vérifier", 0.4, 0.8, 1, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    local recipePrevious = button(left, "<", 20, -668, 35, function() A:ScrollRecipes(-A.recipeVisibleRows) end)
    recipePrevious:ClearAllPoints(); recipePrevious:SetPoint("TOPLEFT", list, "BOTTOMLEFT", 0, -9)
    local recipeNext = button(left, ">", 402, -668, 35, function() A:ScrollRecipes(A.recipeVisibleRows) end)
    recipeNext:ClearAllPoints(); recipeNext:SetPoint("TOPRIGHT", list, "BOTTOMRIGHT", -3, -9)
    self.recipeCount = label(left, "", 65, -674, 330)
    self.recipeCount:ClearAllPoints(); self.recipeCount:SetPoint("TOPLEFT", recipePrevious, "TOPRIGHT", 10, -6)

    local details = CreateFrame("Frame", nil, frame)
    self.detailPanel = details
    details:SetPoint("TOPLEFT", 378, 0); details:SetWidth(524); details:SetHeight(566)
    surface(details, 0.09, 0.078, 0.057, true)
    self.recipePageButton = button(details, "Recette", 16, -12, 110, function() A:ShowDetailPage("recipe") end)
    self.queuePageButton = button(details, "File de fabrication", 134, -12, 180, function() A:ShowDetailPage("queue") end)
    self.recipePage = CreateFrame("Frame", nil, details)
    self.recipePage:SetPoint("TOPLEFT", 16, -48); self.recipePage:SetWidth(492); self.recipePage:SetHeight(504)
    self.queuePage = CreateFrame("Frame", nil, details)
    self.queuePage:SetPoint("TOPLEFT", 16, -48); self.queuePage:SetWidth(492); self.queuePage:SetHeight(504)
    local details = self.recipePage
    self.resultIcon = CreateFrame("Button", nil, details)
    self.resultIcon:SetPoint("TOPLEFT", 0, -4); self.resultIcon:SetWidth(52); self.resultIcon:SetHeight(52)
    surface(self.resultIcon, 0.12, 0.1, 0.06, true)
    self.resultIcon.icon = self.resultIcon:CreateTexture(nil, "ARTWORK")
    self.resultIcon.icon:SetAllPoints(self.resultIcon)
    self.resultIcon:SetScript("OnEnter", function(self)
        local r = A.byKey[A.selectedKey]
        if not r then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if r.itemLink then GameTooltip:SetHyperlink(r.itemLink)
        elseif r.itemID then GameTooltip:SetHyperlink("item:" .. r.itemID)
        elseif r.spellID then GameTooltip:SetHyperlink("spell:" .. r.spellID)
        else GameTooltip:SetText(r.name) end
        GameTooltip:Show()
    end)
    self.resultIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.detailTitle = label(details, "Choisis une recette", 64, -12, 388, "GameFontNormalLarge")
    self.detailTitle:SetHeight(44)
    self.setDescription, self.descriptionScroll = textScroll(details, "ChromieCraftingDescription", 0, -70, 492, 92)
    self.reagentTitle = label(details, "Composants", 0, -174, 492, "GameFontNormal")
    self.campfireButton = button(details, "Créer un feu de camp", 0, 0, 160, nil, "SecureActionButtonTemplate")
    self.campfireButton:ClearAllPoints(); self.campfireButton:SetPoint("TOPRIGHT", 0, -168)
    self.setReagents, self.reagentScroll = textScroll(details, "ChromieCraftingReagents", 0, -198, 492, 174)
    self.reagentScroll.text:SetSpacing(8)
    local quantityLabel = label(details, "Opérations :", 0, 0)
    quantityLabel:ClearAllPoints(); quantityLabel:SetPoint("BOTTOMLEFT", 0, 76)
    self.quantity = edit(details, 85, -250, 55, true); self.quantity:SetText("1")
    self.quantity:ClearAllPoints(); self.quantity:SetPoint("BOTTOMLEFT", 85, 68)
    self.quantity:SetScript("OnTextChanged", function() A:RenderDetails() end)
    self.quantity:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    self.maxButton = button(details, "Maximum", 155, -250, 95, function()
        local r = A.byKey[A.selectedKey]
        A.quantity:SetText(tostring(math.min(9999, math.max(1, r and r.available or 1)))); A:RenderDetails()
    end)
    self.maxButton:ClearAllPoints(); self.maxButton:SetPoint("BOTTOMLEFT", 150, 68)
    self.output = label(details, "", 265, -248, 325)
    self.output:ClearAllPoints(); self.output:SetPoint("BOTTOMLEFT", 265, 65)
    self.output:SetHeight(34)
    self.craftButton = button(details, "Fabriquer", 0, -285, 140, function() A:CraftSelected(A.quantity:GetText()) end)
    self.craftButton:ClearAllPoints(); self.craftButton:SetPoint("BOTTOMLEFT", 0, 24); self.craftButton:SetWidth(130); self.craftButton:SetHeight(30)
    self.craftButton.surface.fill:SetTexture(0.32, 0.045, 0.025, 1)
    self.addButton = button(details, "Ajouter à la file", 155, -285, 150, function()
        if A.viewing or A.running or A.pending or A.withdrawal then return end
        if not M.Add(A.queue, A.byKey[A.selectedKey], A.quantity:GetText()) then
            A.status = "Choisis une recette connue et une quantité entière de 1 à 9999."
        else A.status = "Recette ajoutée à la file." end
        A:Render()
    end)
    self.addButton:ClearAllPoints(); self.addButton:SetPoint("BOTTOMLEFT", 140, 24); self.addButton:SetWidth(135); self.addButton:SetHeight(30)
    self.withdrawButton = button(details, "Retirer composants", 0, 0, 180, function() A:Withdraw(false, A.quantity:GetText()) end)
    self.withdrawButton:ClearAllPoints(); self.withdrawButton:SetPoint("BOTTOMRIGHT", 0, 24); self.withdrawButton:SetHeight(30)
    self.favoriteButton = button(details, "*", 0, 0, 30, function() A:ToggleFavorite(A.selectedKey) end)
    self.favoriteButton:ClearAllPoints(); self.favoriteButton:SetPoint("TOPRIGHT", 0, -10); self.favoriteButton:SetHeight(30)
    self.favoriteButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Ajouter ou retirer des favoris"); GameTooltip:Show()
    end)
    self.favoriteButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local details = self.queuePage
    label(details, "File de fabrication", 0, -8, 230, "GameFontNormal")
    self.needsTitle = label(details, "Besoins cumulés", 254, -8, 230, "GameFontNormal")
    self.queueRows = {}
    local queueList = CreateFrame("Frame", nil, details)
    self.queueList = queueList
    queueList:SetPoint("TOPLEFT", 0, -36); queueList:SetWidth(238); queueList:SetHeight(350)
    queueList:EnableMouseWheel(true)
    queueList:SetScript("OnMouseWheel", function(_, delta)
        A.queueOffset = math.max(0, math.min(math.max(0, #A.queue - A.queueVisibleRows), (A.queueOffset or 0) - delta))
        A:Render()
    end)
    for i = 1, math.floor((maxHeight - 371)/25) do
        local row = CreateFrame("Frame", nil, queueList)
        self.queueRows[i] = row
        row:SetPoint("TOPLEFT", 0, -(i-1)*25); row:SetWidth(292); row:SetHeight(25)
        row.text = label(row, "", 0, -5, 148)
        row.text:SetHeight(20)
        row.quantity = edit(row, 148, 0, 52, true)
        row.quantity:ClearAllPoints(); row.quantity:SetPoint("TOPRIGHT", -82, 0)
        row.quantity:SetScript("OnEditFocusGained", function(self) self.entry = row.entry end)
        local function commit(box)
            local entry = box.entry or row.entry
            if not entry then return end
            local count = M.Quantity(box:GetText())
            if not A.viewing and not A.running and not A.pending and not A.withdrawal and count then entry.count = count end
            box.entry = nil
            if not A.rendering then A:Render() end
        end
        row.quantity:SetScript("OnEnterPressed", function(self) commit(self); self:ClearFocus() end)
        row.quantity:SetScript("OnEditFocusLost", commit)
        local function move(direction)
            if A.viewing or A.running or A.pending or A.withdrawal then return end
            local target = row.index + direction
            if target >= 1 and target <= #A.queue then
                A.queue[row.index], A.queue[target] = A.queue[target], A.queue[row.index]
                A:Render()
            end
        end
        row.up = button(row, "^", 203, 0, 23, function() move(-1) end)
        row.up:ClearAllPoints(); row.up:SetPoint("TOPRIGHT", -50, 0)
        row.down = button(row, "v", 228, 0, 23, function() move(1) end)
        row.down:ClearAllPoints(); row.down:SetPoint("TOPRIGHT", -25, 0)
        row.remove = button(row, "x", 253, 0, 23, function()
            if A.viewing or A.running or A.pending or A.withdrawal then return end
            table.remove(A.queue, row.index); A:Render()
        end)
        row.remove:ClearAllPoints(); row.remove:SetPoint("TOPRIGHT", 0, 0)
    end
    self.setNeeds, self.needsScroll = textScroll(details, "ChromieCraftingNeeds", 254, -36, 238, 350)
    local queuePrevious = button(details, "<", 0, -532, 28, function() A.queueOffset=math.max(0,(A.queueOffset or 0)-A.queueVisibleRows); A:Render() end)
    queuePrevious:ClearAllPoints(); queuePrevious:SetPoint("TOPLEFT", queueList, "BOTTOMLEFT", 0, 0)
    local queueNext = button(details, ">", 263, -532, 28, function() A.queueOffset=math.min(math.max(0,#A.queue-A.queueVisibleRows),(A.queueOffset or 0)+A.queueVisibleRows); A:Render() end)
    queueNext:ClearAllPoints(); queueNext:SetPoint("TOPRIGHT", queueList, "BOTTOMRIGHT", 0, 0)
    self.queueCount = label(details, "", 35, -538, 225)
    self.queueCount:ClearAllPoints(); self.queueCount:SetPoint("TOPLEFT", queuePrevious, "TOPRIGHT", 7, -6)
    self.startButton = button(details, "Lancer la file", 0, -566, 125, function() A:StartQueue() end)
    self.startButton:ClearAllPoints(); self.startButton:SetPoint("BOTTOMLEFT", 0, 22); self.startButton:SetWidth(110)
    self.startButton.surface.fill:SetTexture(0.32, 0.045, 0.025, 1)
    self.stopButton = button(details, "Arrêter", 133, -566, 80, function() A:Stop() end)
    self.stopButton:ClearAllPoints(); self.stopButton:SetPoint("BOTTOMLEFT", 118, 22); self.stopButton:SetWidth(65)
    self.clearButton = button(details, "Vider", 221, -566, 70, function()
        if A.viewing or A.running or A.pending or A.withdrawal then return end
        for i = #A.queue, 1, -1 do table.remove(A.queue, i) end
        A.status = "File vidée."; A:Render()
    end)
    self.clearButton:ClearAllPoints(); self.clearButton:SetPoint("BOTTOMLEFT", 191, 22); self.clearButton:SetWidth(60)
    self.withdrawQueueButton = button(details, "Retirer pour la file", 315, -566, 155, function() A:Withdraw(true) end)
    self.withdrawQueueButton:ClearAllPoints(); self.withdrawQueueButton:SetPoint("BOTTOMRIGHT", 0, 22); self.withdrawQueueButton:SetWidth(180)
    self.queueHelp = label(details, "Quantités = opérations, pas objets produits.\nModifier la quantité d'une ligne puis Entrée.", 315, -556, 285)
    self.queueHelp:SetHeight(20)
    self.queueHelp:ClearAllPoints(); self.queueHelp:SetPoint("BOTTOMLEFT", 0, 57)
    self.queueHelp:SetText("Retrait : banque personnelle ou onglet de banque de guilde ouvert.")
    self.statusText = label(root, "", 0, 0, 600)
    self.statusText:SetHeight(30)
    self.statusText:ClearAllPoints(); self.statusText:SetPoint("BOTTOMLEFT", 22, 5)
    local grip = CreateFrame("Button", nil, root)
    self.resizeGrip = grip
    grip:SetPoint("BOTTOMRIGHT", -3, 3); grip:SetWidth(18); grip:SetHeight(18)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetScript("OnMouseDown", function(_, mouseButton) if mouseButton == "LeftButton" and not InCombatLockdown() then root:StartSizing("BOTTOMRIGHT") end end)
    grip:SetScript("OnMouseUp", function() if not InCombatLockdown() then root:StopMovingOrSizing(); A:SaveWindowGeometry() end end)
    root:SetScript("OnSizeChanged", function() A:LayoutUI(); A:Render() end)
    self:LayoutUI()
end

function A:ScrollRecipes(delta)
    self.recipeOffset = math.max(0, math.min(math.max(0, #(self.visibleRecipes or {}) - self.recipeVisibleRows), (self.recipeOffset or 0) + delta))
    self:Render()
end

function A:RenderDetails()
    if not self.frame then return end
    local r = self.byKey[self.selectedKey]
    local quantity = M.Quantity(self.quantity:GetText())
    local busy = self.running or self.pending or self.withdrawal
    local writable = self.open and not self.viewing and not self.linkedView and not IsTradeSkillLinked() and not self.native
    if not InCombatLockdown() then
        local fire = GetSpellInfo(818)
        local cooking = writable and self.profession == GetSpellInfo(2550)
        self.campfireButton:SetAttribute("type", cooking and "spell" or nil)
        self.campfireButton:SetAttribute("spell", cooking and fire or nil)
        if cooking then self.campfireButton:Show() else self.campfireButton:Hide() end
        enable(self.campfireButton, cooking and fire and IsSpellKnown(818) and not busy)
    end
    local actionable = writable and r and r.known and not r.ambiguous and quantity and not busy
    enable(self.addButton, actionable)
    enable(self.craftButton, actionable and (r.available or 0) >= 1 and (r.cooldown or 0) == 0)
    enable(self.maxButton, r and r.known and (r.available or 0) > 0)
    enable(self.favoriteButton, r ~= nil)
    self.favoriteButton:SetText(r and self:IsFavorite(r.key) and "|cffffd166*|r" or "|cff909080*|r")
    enable(self.withdrawButton, self:CanWithdraw() and r and r.known and not r.ambiguous and quantity and not busy)
    if not r then
        self.resultIcon:Hide()
        self.detailTitle:SetText("Choisis une recette")
        self.setDescription("Sélectionne une recette dans la liste de gauche.\nLes onglets à droite permettent de changer de métier ; la file dispose de son propre panneau.")
        self.setReagents(""); self.output:SetText("")
        return
    end
    self.resultIcon.icon:SetTexture(itemIcon(r)); self.resultIcon:Show()
    self.detailTitle:SetText(r.name)
    local lines = {r.category .. " — " .. (r.known and "|cff66dd88Connue|r" or "|cff66bbffÀ apprendre|r")}
    if r.source and r.source ~= "" then lines[#lines+1] = "Obtention (AtlasLoot) : " .. r.source end
    if not r.known then
        lines[#lines+1] = "Catalogue indicatif : niveau requis et composants inconnus du client. Disponibilité ChromieCraft à vérifier."
    else
        if r.requiresTarget then lines[#lines+1] = "Cible manuelle requise : un enchantement à la fois, puis relance. Aucun objet n'est ciblé automatiquement." end
        if (r.cooldown or 0) > 0 then lines[#lines+1] = "Recharge : " .. math.ceil(r.cooldown) .. " s" end
        if r.ambiguous then lines[#lines+1] = "Identifiant ambigu : fabrication désactivée par sécurité." end
        if not self.viewing and GetTradeSkillDescription and r.index then
            local text = GetTradeSkillDescription(r.index)
            if text and text ~= "" then lines[#lines+1] = text end
        end
        if not self.viewing and r.index then
            if self.open and not self.native and not InCombatLockdown() and GetTradeSkillSelectionIndex() ~= r.index then SelectTradeSkill(r.index) end
            local tools = {GetTradeSkillTools(r.index)}
            for i=1,#tools,2 do
                if tools[i] then lines[#lines+1] = "Outil : " .. tools[i] .. (tools[i+1] and " (présent)" or " |cffff6666(manque)|r") end
            end
        end
    end
    self.setDescription(table.concat(lines, "\n"))
    local reagents = {}
    for _, reagent in ipairs(r.reagents or {}) do
        local need = reagent.count * (quantity or 1)
        local id = reagent.id or reagent.name or ""
        local bags, bank, others = self:InventoryParts(id)
        local owned = bags + bank + others
        local color = owned >= need and "|cff66dd88" or "|cffff7777"
        reagents[#reagents+1] = textureTag(reagent.icon or (reagent.id and GetItemIcon(reagent.id)), 32) .. color .. (reagent.name or "Objet non chargé") .. "  " .. owned .. " / " .. need .. "|r\n     |cffaaa08dSacs : " .. bags .. "   Banque : " .. bank .. "   Autres : " .. others .. "|r"
    end
    self.setReagents(#reagents > 0 and table.concat(reagents, "\n") or (r.known and "Aucun composant." or "Apprends la recette pour afficher ses composants."))
    if r.known then
        local min = (r.minimum or 1) * (quantity or 1)
        local max = (r.maximum or 1) * (quantity or 1)
        self.output:SetText("Produit : " .. min .. (max ~= min and ("–" .. max) or "") .. " objet(s)\nSacs : " .. (self.viewing and "—" or (r.available or 0)) .. " • Planifiable : " .. self:PlannedCount(r))
    else self.output:SetText("") end
end

function A:Render()
    if not self.frame or self.rendering then return end
    self.rendering = true
    self.title:SetText((self.profession or "Métiers du compte") .. "  " .. (self.rank or 0) .. "/" .. (self.maxRank or 0) .. "  |cffb6a68a— Chromie Crafting|r")
    self.subtitle:SetText(self.viewing and "Consultation mémorisée • ouvre ce métier pour fabriquer" or ((self.linkedView or IsTradeSkillLinked()) and "Métier lié : consultation uniquement." or "Atelier du compte • fabrication avec les composants des sacs"))
    self.headerIcon:SetTexture(professionIcon(self.profession))
    self.skillFill:SetWidth(math.max(0.01, (self.skillTrack:GetWidth()-4)*math.min(1, (self.rank or 0)/math.max(1,self.maxRank or 1))))
    self.queuePageButton:SetText("File de fabrication (" .. #self.queue .. ")")
    self:RenderNavigation()
    for _, recipe in ipairs(self.recipes) do recipe.planned = self:PlannedCount(recipe) end
    self.options.favorites = self.db.favorites[self.profession] or {}
    self.favoritesFilter:SetText(self.options.favoritesOnly and "* Favoris" or "Favoris")
    self.visibleRecipes = M.Rows(self.recipes, self.options)
    local rows = self.visibleRecipes
    self.recipeOffset = math.max(0, math.min(self.recipeOffset or 0, math.max(0, #rows - self.recipeVisibleRows)))
    for i, row in ipairs(self.recipeRows) do
        local r = i <= self.recipeVisibleRows and rows[i + self.recipeOffset]
        row.data = r
        if not r then row:Hide()
        else
            row:Show()
            if r.key and r.key == self.selectedKey then row.selection:Show() else row.selection:Hide() end
            if r.header then
                row.background:SetTexture(0.18, 0.135, 0.065, 1)
                row.star:Hide()
                row.text:ClearAllPoints(); row.text:SetPoint("TOPLEFT", 4, -4)
                row.text:SetText("|cffffd166" .. (self.options.collapsed[r.category] and "+ " or "– ") .. r.category .. " (" .. r.count .. ")|r")
                row.amount:SetText("")
            else
                row.background:SetTexture(i%2 == 0 and 0.09 or 0.075, 0.066, 0.049, 1)
                row.star:Show(); row.star:SetText(self:IsFavorite(r.key) and "*" or "+")
                row.text:ClearAllPoints(); row.text:SetPoint("TOPLEFT", 26, -4)
                local color = r.known and (colors[r.difficulty] or "ffffffff") or "ff669dcc"
                row.text:SetText(textureTag(itemIcon(r), 18) .. "|c" .. color .. r.name .. "|r")
                row.amount:SetText(r.known and ("[" .. (r.planned or 0) .. "]") or "?")
            end
        end
    end
    self.recipeCount:SetText(#rows == 0 and "Aucune recette trouvée" or ((self.recipeOffset+1) .. "–" .. math.min(#rows,self.recipeOffset+self.recipeVisibleRows) .. " / " .. #rows .. " lignes"))
    local busy = self.running or self.pending or self.withdrawal
    self.queueOffset = math.max(0, math.min(self.queueOffset or 0, math.max(0,#self.queue - self.queueVisibleRows)))
    for i, row in ipairs(self.queueRows) do
        local index = self.queueOffset + i
        local entry = i <= self.queueVisibleRows and self.queue[index]
        if row.entry ~= entry and row.quantity:HasFocus() then row.quantity:ClearFocus() end
        row.entry, row.index = entry, index
        if not entry then row:Hide()
        else
            row:Show()
            row.text:SetText((self.pending and self.pending.key == entry.key and "|cffffd166> " or "") .. (entry.name or entry.key) .. "|r")
            if not row.quantity:HasFocus() then row.quantity:SetText(tostring(entry.count)) end
            local editable = not busy and not self.viewing
            row.quantity:EnableMouse(editable); row.quantity:EnableKeyboard(editable)
            if not editable then row.quantity:ClearFocus() end
            enable(row.up, editable and index > 1)
            enable(row.down, editable and index < #self.queue); enable(row.remove, editable)
        end
    end
    local count = 0
    for _, entry in ipairs(self.queue) do count = count + entry.count end
    self.queueCount:SetText(#self.queue .. " recettes • " .. count .. " opérations")
    local needs = M.Needs(self.queue, self.byKey, function(id) return self:InventoryCount(id) end)
    local lines, missing = {}, 0
    for _, item in ipairs(needs) do
        missing = missing + item.missing
        lines[#lines+1] = textureTag(GetItemIcon(item.id or item.name), 20) .. (item.missing > 0 and "|cffff7777" or "|cff66dd88") .. item.name .. "|r\n  " .. item.owned .. "/" .. item.required .. (item.missing > 0 and (" — manque " .. item.missing) or " — OK")
    end
    for _, entry in ipairs(self.queue) do
        if not self.byKey[entry.key] or not self.byKey[entry.key].known then
            lines[#lines+1] = "|cffff7777Recette indisponible : " .. (entry.name or entry.key) .. ". Besoins non calculables.|r"
        end
    end
    self.setNeeds(#lines > 0 and table.concat(lines, "\n\n") or "Ajoute des recettes à la file pour voir leurs besoins cumulés.")
    enable(self.startButton, self.open and not self.viewing and not self.linkedView and #self.queue > 0 and not busy and not IsTradeSkillLinked() and not self.native)
    enable(self.withdrawQueueButton, self:CanWithdraw() and #self.queue > 0 and not busy)
    enable(self.stopButton, busy)
    enable(self.clearButton, #self.queue > 0 and not busy and not self.viewing)
    self.statusText:SetText(self.status or "Prêt. La fabrication ne démarre qu'après ton clic.")
    self:RenderDetails()
    self.rendering = nil
end

function A:LearnedProfessions()
    local learned, names = {}, {}
    for _, id in ipairs(professionSpells) do
        local name = GetSpellInfo(id)
        if name then names[name] = id end
    end
    if not GetNumSpellTabs then return learned end
    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, count = GetSpellTabInfo(tab)
        for index = offset + 1, offset + count do
            local name = GetSpellName(index, BOOKTYPE_SPELL or "spell")
            if names[name] then learned[name] = names[name]; names[name] = nil end
        end
    end
    return learned
end

function A:ProfessionNames()
    local set, result = self:LearnedProfessions(), {}
    for _, character in pairs(self.account.characters) do
        if character.realm == self.realm then
            for name in pairs(character.professions) do set[name] = set[name] or true end
        end
    end
    for name in pairs(set) do result[#result + 1] = name end
    table.sort(result)
    return result
end

function A:CreateNavigation()
    self.professionTabs = {}
    for i = 1, #professionSpells + 1 do
        local tab = CreateFrame("Button", nil, self.frame, "SecureActionButtonTemplate")
        surface(tab, 0.15, 0.12, 0.075, true)
        tab:SetWidth(44); tab:SetHeight(44); tab:RegisterForClicks("LeftButtonUp")
        tab:SetPoint("TOPRIGHT", -12, -136 - (i-1)*46)
        tab.icon = tab:CreateTexture(nil, "ARTWORK")
        tab.icon:SetPoint("TOPLEFT", 4, -4); tab.icon:SetPoint("BOTTOMRIGHT", -4, 4)
        tab.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local highlight = solid(tab, "HIGHLIGHT", 1, 0.8, 0.3, 0.25); highlight:SetAllPoints(tab)
        tab:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText(self.profession or "Métier")
            GameTooltip:AddLine("Changer de métier • choisir le personnage dans la liste en haut", 0.8, 0.75, 0.6, true); GameTooltip:Show()
        end)
        tab:SetScript("OnLeave", function() GameTooltip:Hide() end)
        tab:SetScript("PreClick", function()
            if InCombatLockdown() or A.running or A.pending or A.withdrawal then return end
            if tab:GetAttribute("type") == "spell" then
                A.switchingProfession = true
                A.native, A.db.native = false, false
                A:SuppressNative()
            end
        end)
        tab:SetScript("PostClick", function()
            A.switchingProfession = nil
            if InCombatLockdown() or A.running or A.pending or A.withdrawal then return end
            if tab:GetAttribute("type") ~= "spell" then
                local key = A.viewedCharacter or A.characterKey
                if not A.account.characters[key].professions[tab.profession] then
                    for candidate, character in pairs(A.account.characters) do
                        if character.realm == A.realm and character.professions[tab.profession] then key = candidate; break end
                    end
                end
                A:SelectCharacter(key, tab.profession)
            end
        end)
        self.professionTabs[i] = tab
    end
    self.characterDropdown = dropdown(self.frame, "ChromieCraftingCharacter", 0, -76, 205, {}, function() end, function() end)
    UIDropDownMenu_Initialize(self.characterDropdown, function()
        local keys = {}
        for key, character in pairs(A.account.characters) do
            if character.realm == A.realm and (character.professions[A.profession] or key == A.characterKey) then keys[#keys+1]=key end
        end
        table.sort(keys)
        for _, key in ipairs(keys) do
            local character = A.account.characters[key]
            local info = UIDropDownMenu_CreateInfo()
            info.text = character.name .. (key == A.characterKey and " (connecté)" or "")
            info.checked = key == (A.viewedCharacter or A.characterKey)
            info.func = function()
                CloseDropDownMenus()
                if A.profession then
                    if key == A.characterKey and A.open and A.liveProfession == A.profession then
                        A.viewing, A.viewedCharacter = nil, nil
                        A.profession = nil
                        A:RefreshRecipes()
                    else A:SelectCharacter(key, A.profession) end
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    local function option(name, text, x, field)
        local check = CreateFrame("CheckButton", name, A.frame, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", x, -77); check:SetWidth(24); check:SetHeight(24)
        _G[name .. "Text"]:SetText(text); check:SetChecked(A.db[field])
        check:SetScript("OnClick", function(self) A.db[field] = self:GetChecked() and true or false; A.recipeOffset=0; A:Render() end)
        return check
    end
    self.bankOption = option("ChromieCraftingIncludeBank", "Inclure la banque", 245, "includeBank")
    self.altsOption = option("ChromieCraftingIncludeAlts", "Inclure les autres personnages", 430, "includeAlts")
    self.stockTimestamp = label(self.frame, "", 22, -111, 880)
end

function A:RenderNavigation()
    if not self.professionTabs then return end
    local character = self.account.characters[self.viewedCharacter or self.characterKey]
    UIDropDownMenu_SetText(self.characterDropdown, (character and character.name or "Personnage") .. (self.viewing and " · mémorisé" or " · connecté"))
    local saved = character and character.professions[self.profession]
    local formatDate = date or os and os.date
    self.stockTimestamp:SetText("Recettes : " .. (saved and formatDate and formatDate("%d/%m %H:%M", saved.updated) or "à scanner") .. " • Stocks mémorisés : dernière connexion / visite de banque. Retrait ou transfert requis avant fabrication.")
    if InCombatLockdown() then return end
    local names, learned = self:ProfessionNames(), self:LearnedProfessions()
    local selectedCharacter = self.viewedCharacter or self.characterKey
    for i, tab in ipairs(self.professionTabs) do
        local name = names[i]
        if name then
            tab.profession = name
            tab.icon:SetTexture(professionIcon(name))
            tab.surface.fill:SetTexture(self.profession == name and 0.8 or 0.15, self.profession == name and 0.6 or 0.12, self.profession == name and 0.2 or 0.075, 1)
            local own = selectedCharacter == self.characterKey and learned[name]
            tab:SetAttribute("type", own and "spell" or nil)
            tab:SetAttribute("spell", own and name or nil)
            enable(tab, not self.running and not self.pending and not self.withdrawal)
            tab:Show()
        else tab:Hide() end
    end
end

function A:OpenDashboard()
    if InCombatLockdown() or self.running or self.pending or self.withdrawal then self:Print("Termine l'action en cours avant d'ouvrir les métiers."); return end
    self.native, self.db.native = false, false
    self:SuppressNative()
    self:CreateUI()
    self.frame:Show()
    if (not self.viewing or self.viewedCharacter == self.characterKey) and self:ResumeProfession() then return end
    local names = self:ProfessionNames()
    if not self.profession and names[1] then self:SelectCharacter(self.characterKey, names[1])
    else self:Render() end
    if #names == 0 then self.status="Ouvre les métiers de tes personnages pour les mémoriser."; self:Render() end
end

function A:ToggleProfessionMenu()
    if InCombatLockdown() then self:Print("Le lanceur des métiers est indisponible en combat."); return end
    if self.professionMenu and self.professionMenu:IsShown() then self.professionMenu:Hide(); return end
    if self.running or self.pending or self.withdrawal then self:Print("Termine ou arrête l'action avant de changer de métier."); return end
    local learned, names = {}, {}
    for _, id in ipairs(professionSpells) do
        local name = GetSpellInfo(id)
        if name then names[name] = true end
    end
    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, count = GetSpellTabInfo(tab)
        for index = offset + 1, offset + count do
            local name = GetSpellName(index, BOOKTYPE_SPELL or "spell")
            if names[name] then learned[#learned + 1] = name; names[name] = nil end
        end
    end
    if #learned == 0 then self:Print("Aucun métier de fabrication trouvé dans ton grimoire."); return end
    if not self.professionMenu then
        local menu = CreateFrame("Frame", "ChromieCraftingProfessionMenu", UIParent)
        self.professionMenu, self.professionButtons = menu, {}
        menu:SetWidth(230); menu:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -8)
        menu:SetFrameStrata("DIALOG"); menu:SetClampedToScreen(true); menu:EnableMouse(true)
        menu:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=16, insets={left=4,right=4,top=4,bottom=4}})
        menu:SetBackdropColor(0.035, 0.045, 0.06, 0.98)
        label(menu, "Chromie Crafting", 12, -13, 185, "GameFontNormal")
        local close = CreateFrame("Button", nil, menu, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", 0, 0)
        UISpecialFrames[#UISpecialFrames + 1] = "ChromieCraftingProfessionMenu"
    end
    for i, name in ipairs(learned) do
        local b = self.professionButtons[i]
        if not b then
            -- Profession spells still use a secure click, never an insecure cast callback.
            b = CreateFrame("Button", nil, self.professionMenu, "UIPanelButtonTemplate,SecureActionButtonTemplate")
            self.professionButtons[i] = b
            b:SetPoint("TOPLEFT", 12, -38 - (i-1)*27); b:SetWidth(206); b:SetHeight(23)
            b:RegisterForClicks("LeftButtonUp")
            b:SetAttribute("type", "spell")
            b:SetScript("PreClick", function()
                if InCombatLockdown() then return end
                A.native, A.db.native = false, false
                A:SuppressNative()
            end)
            b:SetScript("PostClick", function() if not InCombatLockdown() then A.professionMenu:Hide() end end)
        end
        b:SetText(name); b:SetAttribute("spell", name); b:Show()
    end
    for i = #learned + 1, #self.professionButtons do self.professionButtons[i]:Hide() end
    self.professionMenu:SetHeight(48 + #learned*27)
    self.professionMenu:Show()
end

function A:UpdateMinimapButtonPosition()
    local angle = math.rad(tonumber(self.db.minimapAngle) or 315)
    local radius = Minimap:GetWidth()/2 + 10
    self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle)*radius, math.sin(angle)*radius)
end

function A:CreateMinimapButton()
    if self.minimapButton then return end
    local b = CreateFrame("Button", "ChromieCraftingMinimapButton", Minimap)
    self.minimapButton = b
    b:SetWidth(32); b:SetHeight(32); b:SetFrameStrata("MEDIUM")
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp"); b:RegisterForDrag("LeftButton")
    local icon = b:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20); icon:SetHeight(20); icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\Trade_BlackSmithing"); icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetWidth(53); border:SetHeight(53); border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    b:SetScript("OnClick", function(_, mouseButton) if mouseButton == "RightButton" then A:ToggleProfessionMenu() else A:OpenDashboard() end end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText("Chromie Crafting")
        GameTooltip:AddLine("Clic : métiers du compte • clic droit : lanceur rapide", 1, 1, 1)
        GameTooltip:AddLine("Glisser : déplacer le bouton", 0.8, 0.8, 0.8); GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local function updateDrag()
        local x, y = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        local cx, cy = Minimap:GetCenter()
        A.db.minimapAngle = math.deg(math.atan2(y/scale-cy, x/scale-cx))
        A:UpdateMinimapButtonPosition()
    end
    b:SetScript("OnDragStart", function(self) GameTooltip:Hide(); self:SetScript("OnUpdate", updateDrag) end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil); updateDrag() end)
    self:UpdateMinimapButtonPosition()
end
