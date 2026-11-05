local A = ChromieCrafting
local M = A.Model
local events = CreateFrame("Frame")
A.events = events
local nativeEvents = {"TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE", "TRADE_SKILL_CLOSE"}

local function linkID(link, kind)
    return link and tonumber(link:match(kind .. ":(%d+)"))
end

function A:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff55ccffChromie Crafting :|r " .. message)
end

function A:Initialize()
    ChromieCraftingDB = ChromieCraftingDB or {}
    self.db = ChromieCraftingDB
    self.db.queues = self.db.queues or {}
    self.options = {state = "all", sort = "skill", collapsed = {}}
    self.recipes, self.byKey = {}, {}
    self.queue = {}
    self.native = self.db.native or false
    self:InitializeAccount()
end

function A:SuppressNative()
    local frame = TradeSkillFrame
    if not frame or self.native then return end
    if not self.nativeRegistrations then
        self.nativeRegistrations = {}
        for _, event in ipairs(nativeEvents) do
            self.nativeRegistrations[event] = frame:IsEventRegistered(event)
            frame:UnregisterEvent(event)
        end
        frame:HookScript("OnShow", function() if not A.native then A:HideNative() end end)
    end
    self:HideNative()
end

function A:HideNative()
    if not TradeSkillFrame or not TradeSkillFrame:IsShown() then return end
    -- Blizzard's OnHide closes the profession API; only hide its visual panel.
    local onHide = TradeSkillFrame:GetScript("OnHide")
    TradeSkillFrame:SetScript("OnHide", nil)
    HideUIPanel(TradeSkillFrame)
    TradeSkillFrame:Hide()
    TradeSkillFrame:SetScript("OnHide", onHide)
end

function A:UseNative()
    if InCombatLockdown() then self:Print("Le changement de fenêtre est indisponible en combat."); return end
    self:Pause()
    self.native, self.db.native = true, true
    if self.frame then self.switching = true; self.frame:Hide(); self.switching = nil end
    if TradeSkillFrame then
        for event, registered in pairs(self.nativeRegistrations or {}) do
            if registered then TradeSkillFrame:RegisterEvent(event) end
        end
        self.nativeRegistrations = nil
        if self.open then
            if TradeSkillFrame_Show then TradeSkillFrame_Show() else ShowUIPanel(TradeSkillFrame) end
        end
    end
    self:Print("Fenêtre Blizzard activée. /ccraft pour revenir à la nouvelle interface.")
end

function A:ResetNativeFilters()
    if SetTradeSkillItemNameFilter then SetTradeSkillItemNameFilter("") end
    if SetTradeSkillItemLevelFilter then SetTradeSkillItemLevelFilter(0, 0) end
    if SetTradeSkillSubClassFilter then SetTradeSkillSubClassFilter(0, 1, 1) end
    if SetTradeSkillInvSlotFilter then SetTradeSkillInvSlotFilter(0, 1, 1) end
    if TradeSkillOnlyShowMakeable then TradeSkillOnlyShowMakeable(false) end
    if TradeSkillOnlyShowSkillUps then TradeSkillOnlyShowSkillUps(false) end
end

function A:RecipeAt(index, category)
    local name, kind, available = GetTradeSkillInfo(index)
    if not name or kind == "header" or kind == "subheader" then return end
    local recipeLink = GetTradeSkillRecipeLink(index)
    local spellID = linkID(recipeLink, "enchant") or linkID(recipeLink, "spell")
    local itemLink = GetTradeSkillItemLink(index)
    local itemID = linkID(itemLink, "item")
    local minimum, maximum = GetTradeSkillNumMade(index)
    local r = {
        key = spellID and ("s" .. spellID) or ("n:" .. name .. ":" .. (itemID or "")),
        spellID = spellID, name = name, category = category or "Divers", known = true,
        available = math.abs(available or 0), difficulty = kind, index = index, order = index,
        icon = GetTradeSkillIcon(index), itemLink = itemLink, itemID = itemID,
        recipeLink = recipeLink, minimum = minimum or 1, maximum = maximum or 1,
        reagents = {}, cooldown = GetTradeSkillCooldown(index) or 0,
    }
    local enchanting = GetSpellInfo(7411)
    r.requiresTarget = self.profession == enchanting and not itemID
    for j = 1, GetTradeSkillNumReagents(index) do
        local reagentName, icon, count, owned = GetTradeSkillReagentInfo(index, j)
        local link = GetTradeSkillReagentItemLink(index, j)
        local id = linkID(link, "item")
        owned = (id or reagentName) and GetItemCount(id or reagentName, false) or 0
        r.reagents[#r.reagents + 1] = {id = id, name = reagentName, icon = icon, count = count or 0, owned = owned or 0, link = link}
        if count and count > 0 then r.available = math.min(r.available, math.floor((owned or 0) / count)) end
    end
    return r
end

function A:RefreshRecipes()
    if not self.open or self.reading or self.viewing then return end
    self.reading = true
    local profession, rank, maxRank = GetTradeSkillLine()
    if not profession or profession == "UNKNOWN" then self.reading = nil; return end
    if self.profession ~= profession then
        self:Pause()
        self.profession, self.selectedKey = profession, nil
        self.db.queues[profession] = self.db.queues[profession] or {}
        self.queue = self.db.queues[profession]
        self.catalog = self:ReadCatalog(profession)
        self.options.collapsed = {}
        self.recipeOffset, self.queueOffset = 0, 0
    end
    self.rank, self.maxRank = rank, maxRank
    -- Expand once per scan so hidden native headers never hide learned recipes.
    if ExpandTradeSkillSubClass then
        for i = GetNumTradeSkills(), 1, -1 do
            local _, kind, _, expanded = GetTradeSkillInfo(i)
            if (kind == "header" or kind == "subheader") and not expanded then ExpandTradeSkillSubClass(i) end
        end
    end
    local recipes, byKey, category = {}, {}, "Divers"
    for i = 1, GetNumTradeSkills() do
        local name, kind = GetTradeSkillInfo(i)
        if kind == "header" or kind == "subheader" then
            category = name
        else
            local r = self:RecipeAt(i, category)
            if r then
                local extra = r.spellID and self.catalog[r.spellID]
                if extra then r.category, r.source = extra.category, extra.source end
                if byKey[r.key] then r.ambiguous = true; byKey[r.key].ambiguous = true end
                recipes[#recipes + 1], byKey[r.key] = r, r
            end
        end
    end
    local unknown = {}
    for _, r in pairs(self.catalog) do
        if not byKey[r.key] then unknown[#unknown + 1] = r end
    end
    table.sort(unknown, function(a, b)
        if a.category ~= b.category then return a.category < b.category end
        return a.key < b.key
    end)
    for _, r in ipairs(unknown) do recipes[#recipes + 1] = r; byKey[r.key] = r end
    self.recipes, self.byKey = recipes, byKey
    self:SaveProfession()
    self.reading = nil
    self.dirty = nil
    if self.Render then self:Render() end
end

function A:Resolve(key)
    local found
    for i = 1, GetNumTradeSkills() do
        local r = self:RecipeAt(i)
        if r and r.key == key then
            if found then return nil, "Recette ambiguë : fabrication annulée." end
            found = r
        end
    end
    return found, "Recette introuvable dans le métier ouvert."
end

function A:Pause(message)
    self.running = false
    if StopTradeSkillRepeat then StopTradeSkillRepeat() end
    if message then self.status = message end
end

function A:Stop()
    if self.withdrawal then self:FinishWithdrawal("Retrait arrêté ; les composants déjà retirés restent dans les sacs."); return end
    self:Pause("Fabrication arrêtée ; les quantités restantes sont conservées.")
    if self.pending then
        if SpellIsTargeting() and SpellStopTargeting then SpellStopTargeting() end
        SpellStopCasting()
    end
    if self.Render then self:Render() end
end

function A:StartQueue()
    if self.pending or self.running or self.withdrawal or self.viewing then return end
    self.jobs = self.queue
    self.running = true
    self:NextCraft()
end

function A:CraftSelected(count)
    if self.pending or self.running or self.withdrawal or self.viewing then return end
    local r = self.byKey[self.selectedKey]
    local jobs = {}
    if not M.Add(jobs, r, count) then self.status = "Choisis une recette connue et une quantité entière de 1 à 9999."; self:Render(); return end
    self.jobs, self.running = jobs, true
    self:NextCraft()
end

function A:NextCraft()
    if not self.running or self.pending then return end
    local entry = self.jobs and self.jobs[1]
    local reason
    if self.viewing or self.withdrawal or not self.open or self.native then reason = "Ouvre ton métier pour fabriquer."
    elseif IsTradeSkillLinked() then reason = "Métier lié : consultation seulement."
    elseif InCombatLockdown() then reason = "Fabrication suspendue en combat."
    elseif not entry then reason = "Fabrication terminée."
    elseif UnitCastingInfo("player") or UnitChannelInfo("player") or SpellIsTargeting() then reason = "Termine ton action en cours avant de lancer la file." end
    if reason then self:Pause(reason); self:Render(); return end
    local r, errorText = self:Resolve(entry.key)
    if not r then reason = errorText
    elseif r.cooldown > 0 then reason = "Recette en recharge : " .. r.name
    elseif r.available < 1 then reason = "Composants manquants : " .. r.name
    else
        SelectTradeSkill(r.index)
        local tools = {GetTradeSkillTools(r.index)}
        for i = 1, #tools, 2 do
            if tools[i] and not tools[i + 1] then reason = "Outil requis : " .. tools[i]; break end
        end
        for _, reagent in ipairs(r.reagents) do
            if reagent.owned < reagent.count then reason = "Composant manquant : " .. (reagent.name or "inconnu"); break end
        end
    end
    if reason then self:Pause(reason); self:Render(); return end
    local count = r.requiresTarget and 1 or math.min(entry.count, r.available)
    self.pending = {key = r.key, spellID = r.spellID, name = r.name, target = r.requiresTarget, deadline = GetTime() + 120, jobs = self.jobs, remaining = count}
    self.status = (r.requiresTarget and "Choisis la cible de l'enchantement : " or "Fabrication : ") .. r.name .. " (" .. entry.count .. " restantes)"
    -- Repeats must be requested at the user's click, never from OnUpdate.
    DoTradeSkill(r.index, count)
    self:Render()
end

function A:MatchesPending(unit, name, lineID, spellID)
    local p = self.pending
    if not p or unit ~= "player" then return false end
    if lineID and lineID ~= 0 and p.lastLineID == lineID then return false end
    if p.lineID and lineID and p.lineID ~= lineID then return false end
    if p.spellID and spellID and spellID ~= 0 then return p.spellID == spellID end
    return name == p.name
end

function A:Tick(elapsed)
    if self.withdrawal then self:ContinueWithdrawal() end
    -- Nearby fires can change without a bag or trade-skill event on 3.3.5a.
    if self.open and not self.viewing and not self.native and not InCombatLockdown()
        and self.profession == GetSpellInfo(2550) and GetTime() >= (self.nextCookingRefresh or 0) then
        self.nextCookingRefresh = GetTime() + 1
        self.dirty = true
    end
    if self.pending and not self.pending.timedOut and GetTime() > self.pending.deadline then
        -- Keep the operation identifiable: a manual enchant can succeed much later.
        self.pending.timedOut = true
        self:Pause("Confirmation en attente : choisis la cible ou annule l'action. Si elle reste bloquée, vérifie les quantités puis /reload.")
        self:Render()
    end
    if self.dirty and self.open then self:RefreshRecipes() end
end

function A:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == "ChromieCrafting" then self:Initialize() end
        if addon == "Blizzard_TradeSkillUI" and self.db then self:SuppressNative() end
        return
    end
    if not self.db then return end
    if event == "PLAYER_LOGIN" then
        self:InitializeAccount()
        self:SaveInventory()
        self:CreateMinimapButton()
    elseif event == "TRADE_SKILL_SHOW" then
        if self.native or InCombatLockdown() then return end
        self.viewing, self.viewedCharacter = nil, nil
        self.profession = nil
        self.open = true
        self:SuppressNative()
        self:ResetNativeFilters()
        self:CreateUI()
        self.frame:Show()
        self:RefreshRecipes()
    elseif event == "TRADE_SKILL_CLOSE" then
        self.open = false
        self:Pause()
        -- Keep an in-flight confirmation so a late success cannot duplicate work.
        if self.frame and not self.switchingProfession and not self.viewing then self:RequestClose() end
    elseif event == "BANKFRAME_OPENED" then
        self.bankOpen = true
        self:SaveInventory()
        if self.Render then self:Render() end
    elseif event == "BANKFRAME_CLOSED" then
        self.bankOpen = false
        if self.withdrawal and not self.withdrawal.guildTab then self:FinishWithdrawal("Retrait arrêté : banque fermée.") end
        if self.Render then self:Render() end
    elseif event == "GUILDBANKFRAME_OPENED" then
        self.guildBankOpen = true
        if self.Render then self:Render() end
    elseif event == "GUILDBANKFRAME_CLOSED" then
        self.guildBankOpen = false
        if self.withdrawal and self.withdrawal.guildTab then self:FinishWithdrawal("Retrait arrêté : banque de guilde fermée. Vérifie le curseur.") end
        if self.Render then self:Render() end
    elseif event == "GUILDBANKBAGSLOTS_CHANGED" then
        if self.withdrawal and self.withdrawal.guildTab then
            self.withdrawal.querying = nil
            self:ContinueWithdrawal()
        end
    elseif event == "PLAYERBANKSLOTS_CHANGED" then
        if self.bankOpen then self:SaveInventory() end
    elseif event == "TRADE_SKILL_UPDATE" or event == "BAG_UPDATE" or event == "GET_ITEM_INFO_RECEIVED" then
        if event == "BAG_UPDATE" then
            self:SaveInventory()
            if self.withdrawal then self:ContinueWithdrawal() end
            if self.viewing and self.Render then self:Render() end
        end
        if self.open and not self.reading then self.dirty = true end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if self.withdrawal then self:FinishWithdrawal("Retrait arrêté : combat.") end
        if self.running then self:Stop() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if self.frame then self.frame:StopMovingOrSizing() end
        if self.hideAfterCombat then self:RequestClose() end
        if self.Render then self:Render() end
    elseif event == "UNIT_SPELLCAST_SENT" then
        local unit, name, _, _, lineID = ...
        if self:MatchesPending(unit, name) then self.pending.lineID = lineID end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, name, _, lineID, spellID = ...
        if self:MatchesPending(unit, name, lineID, spellID) then
            local pending = self.pending
            M.Complete(pending.jobs, pending.key)
            pending.remaining = pending.remaining - 1
            pending.lastLineID, pending.lineID = lineID or pending.lineID, nil
            if pending.target or pending.remaining == 0 or not self.running then
                self.pending = nil
                if pending.target then
                    self:Pause("Enchantement terminé. Relance la fabrication pour choisir une nouvelle cible.")
                elseif self.running then
                    self:Pause(#pending.jobs > 0 and "Lot terminé. Un nouveau clic est nécessaire pour poursuivre." or "Fabrication terminée.")
                end
            else
                pending.deadline = GetTime() + 120
            end
            self.dirty = true
            self:Render()
        end
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        local unit, name, _, lineID, spellID = ...
        if self:MatchesPending(unit, name, lineID, spellID) then
            self.pending = nil
            self:Pause("Fabrication interrompue ; relance la file quand tu es prêt.")
            self:Render()
        end
    elseif event == "UI_ERROR_MESSAGE" and self.pending then
        local message = ...
        self.status = tostring(message)
        -- Errors need not belong to our cast; never consume or retry a job here.
        if self.Render then self:Render() end
    end
end

for _, event in ipairs({"ADDON_LOADED", "PLAYER_LOGIN", "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE", "TRADE_SKILL_UPDATE", "BAG_UPDATE", "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "GUILDBANKFRAME_OPENED", "GUILDBANKFRAME_CLOSED", "GUILDBANKBAGSLOTS_CHANGED", "PLAYERBANKSLOTS_CHANGED", "GET_ITEM_INFO_RECEIVED", "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UI_ERROR_MESSAGE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED"}) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, ...) A:OnEvent(event, ...) end)
events:SetScript("OnUpdate", function(_, elapsed)
    A.elapsed = (A.elapsed or 0) + elapsed
    if A.elapsed >= 0.15 then A.elapsed = 0; A:Tick(elapsed) end
end)

SLASH_CHROMIECRAFTING1 = "/ccraft"
SLASH_CHROMIECRAFTING2 = "/metiers"
SlashCmdList.CHROMIECRAFTING = function(message)
    if not A.db then return end
    if InCombatLockdown() then A:Print("La fenêtre des métiers est indisponible en combat."); return end
    if message == "blizzard" then A:UseNative(); return end
    A.native, A.db.native = false, false
    A:SuppressNative()
    if GetTradeSkillLine() and GetTradeSkillLine() ~= "UNKNOWN" then
        A.open = true
        A:ResetNativeFilters(); A:CreateUI(); A.frame:Show(); A:RefreshRecipes()
    else A:OpenDashboard() end
end
