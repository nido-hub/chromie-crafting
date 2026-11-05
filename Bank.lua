local A = ChromieCrafting
local M = A.Model

local function itemID(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    return link and tonumber(link:match("item:(%d+)"))
end

function A:FinishWithdrawal(message)
    self.withdrawal = nil
    self.status = message
    if self.Render then self:Render() end
end

function A:Withdraw(queue, quantity)
    if self.withdrawal or self.running or self.pending then return end
    if not (self.bankOpen or self.guildBankOpen) or not self.open or self.native or self.viewing or IsTradeSkillLinked() or InCombatLockdown() then
        self:FinishWithdrawal("Ouvre une banque et ton métier sur le personnage connecté pour retirer les composants."); return
    end
    if GetCursorInfo() then self:FinishWithdrawal("Libère le curseur avant de retirer les composants."); return end
    local jobs = self.queue
    if not queue then
        jobs = {}
        if not M.Add(jobs, self.byKey[self.selectedKey], quantity) then return end
    end
    for _, entry in ipairs(jobs) do
        local recipe = self.byKey[entry.key]
        if not recipe or not recipe.known then self:FinishWithdrawal("Recette indisponible : retrait annulé."); return end
        for _, reagent in ipairs(recipe.reagents or {}) do
            if not reagent.id then self:FinishWithdrawal("Composant non chargé : réessaie après actualisation."); return end
        end
    end
    self.withdrawal = {needs=M.Needs(jobs, self.byKey, function(id) return GetItemCount(id, false) end)}
    if self.guildBankOpen then
        local operation = self.withdrawal
        operation.guildTab = GetCurrentGuildBankTab()
        operation.querying, operation.deadline = true, GetTime() + 5
        QueryGuildBankTab(operation.guildTab)
    end
    self.status = "Retrait des composants en cours ; attente de confirmation de chaque transfert."
    if self.Render then self:Render() end
    self:ContinueWithdrawal()
end

local function placeCursor(self, operation)
    local kind, id = GetCursorInfo()
    if not kind then
        if GetTime() > operation.deadline then self:FinishWithdrawal("Retrait non confirmé : vérifie le curseur et tes sacs avant de réessayer.") end
        return
    end
    if kind ~= "item" or id ~= operation.id then
        self:FinishWithdrawal("Retrait arrêté : curseur modifié. Vérifie l'objet tenu et tes sacs."); return
    end
    if not GetContainerItemLink(operation.targetBag, operation.targetSlot) then
        operation.picking, operation.waiting = nil, true
        operation.deadline = GetTime() + 5
        PickupContainerItem(operation.targetBag, operation.targetSlot)
        if not GetCursorInfo() then return end
    end
    -- Return only to the original stack; never swap with an unrelated item.
    local link = operation.guildTab and GetGuildBankItemLink(operation.source, operation.slot)
        or (not operation.guildTab and GetContainerItemLink(operation.source, operation.slot))
    if not link or tonumber(link:match("item:(%d+)")) == operation.id then
        if operation.guildTab then PickupGuildBankItem(operation.source, operation.slot)
        else PickupContainerItem(operation.source, operation.slot) end
    end
    self:FinishWithdrawal("Transfert refusé : vérifie le curseur et l'espace dans tes sacs.")
end

function A:ContinueWithdrawal()
    local operation = self.withdrawal
    if not operation then return end
    if (operation.guildTab and (not self.guildBankOpen or GetCurrentGuildBankTab() ~= operation.guildTab))
        or (not operation.guildTab and not self.bankOpen) or InCombatLockdown() then
        self:FinishWithdrawal("Retrait arrêté : banque fermée, onglet changé ou combat. Vérifie le curseur."); return
    end
    if operation.querying then
        if GetTime() > operation.deadline then self:FinishWithdrawal("Onglet de guilde non chargé : réessaie après actualisation.") end
        return
    end
    if operation.picking then placeCursor(self, operation); return end
    if GetCursorInfo() then self:FinishWithdrawal("Retrait arrêté : curseur occupé. Aucun objet n'est supprimé."); return end
    if operation.waiting then
        if (GetItemCount(operation.id, false) or 0) < operation.expected then
            if GetTime() > operation.deadline then self:FinishWithdrawal("Transfert non confirmé : vérifie tes sacs avant de réessayer.") end
            return
        end
        operation.waiting = nil
    end
    for _, need in ipairs(operation.needs) do
        local missing = need.required - (GetItemCount(need.id, false) or 0)
        if missing > 0 then
            local sources = operation.guildTab and {operation.guildTab} or {-1,5,6,7,8,9,10,11}
            for _, bag in ipairs(sources) do
                local allowed = true
                if operation.guildTab then
                    local _, _, viewable, _, limit, remaining = GetGuildBankTabInfo(bag)
                    allowed = viewable and limit and limit ~= 0 and remaining and remaining ~= 0
                end
                for slot = 1, (allowed and (operation.guildTab and 98 or GetContainerNumSlots(bag)) or 0) do
                    local id
                    if operation.guildTab then
                        local link = GetGuildBankItemLink(bag, slot)
                        id = link and tonumber(link:match("item:(%d+)"))
                    else id = itemID(bag, slot) end
                    if id == need.id then
                        local texture, count, locked
                        if operation.guildTab then texture, count, locked = GetGuildBankItemInfo(bag, slot)
                        else texture, count, locked = GetContainerItemInfo(bag, slot) end
                        if locked then self:FinishWithdrawal("Retrait arrêté : composant verrouillé, réessaie dans un instant."); return end
                        -- Use an empty general bag slot: never swap or overwrite another item.
                        local targetBag, targetSlot
                        for destination = 0, 4 do
                            local free, family = GetContainerNumFreeSlots(destination)
                            if free > 0 and family == 0 then
                                for index = 1, GetContainerNumSlots(destination) do
                                    if not GetContainerItemLink(destination, index) then targetBag, targetSlot = destination, index; break end
                                end
                            end
                            if targetBag then break end
                        end
                        if not targetBag then self:FinishWithdrawal("Retrait arrêté : libère une case dans un sac général."); return end
                        local amount = math.min(missing, count or 0)
                        if amount < 1 then self:FinishWithdrawal("Stock bancaire en cours d'actualisation : réessaie."); return end
                        operation.id, operation.expected = need.id, (GetItemCount(need.id, false) or 0) + amount
                        operation.picking, operation.deadline = true, GetTime() + 5
                        operation.source, operation.slot = bag, slot
                        operation.targetBag, operation.targetSlot = targetBag, targetSlot
                        if operation.guildTab then
                            if amount < count then SplitGuildBankItem(bag, slot, amount) else PickupGuildBankItem(bag, slot) end
                        elseif amount < count then SplitContainerItem(bag, slot, amount)
                        else PickupContainerItem(bag, slot) end
                        placeCursor(self, operation)
                        return
                    end
                end
            end
        end
    end
    local missing = {}
    for _, need in ipairs(operation.needs) do
        local amount = need.required - (GetItemCount(need.id, false) or 0)
        if amount > 0 then missing[#missing + 1] = need.name .. " × " .. amount end
    end
    if #missing > 0 then
        self:FinishWithdrawal("Retrait partiel terminé. Composants encore manquants : " .. table.concat(missing, ", ") .. "."); return
    end
    self:FinishWithdrawal("Composants retirés. Clique sur Fabriquer ou Lancer la file pour continuer.")
end
