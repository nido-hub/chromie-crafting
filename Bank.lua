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
    if not self.bankOpen or self.viewing or IsTradeSkillLinked() or InCombatLockdown() then
        self:FinishWithdrawal("Ouvre ta banque et ton métier sur le personnage connecté pour retirer les composants."); return
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
    self.status = "Retrait des composants en cours ; attente de confirmation de chaque transfert."
    if self.Render then self:Render() end
    self:ContinueWithdrawal()
end

function A:ContinueWithdrawal()
    local operation = self.withdrawal
    if not operation then return end
    if not self.bankOpen or InCombatLockdown() then self:FinishWithdrawal("Retrait arrêté : banque fermée ou combat."); return end
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
            for _, bag in ipairs({-1,5,6,7,8,9,10,11}) do
                for slot = 1, GetContainerNumSlots(bag) do
                    if itemID(bag, slot) == need.id then
                        local _, count, locked = GetContainerItemInfo(bag, slot)
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
                        operation.waiting, operation.deadline = true, GetTime() + 5
                        if amount < count then SplitContainerItem(bag, slot, amount) else PickupContainerItem(bag, slot) end
                        local kind, cursorID = GetCursorInfo()
                        if kind ~= "item" or cursorID ~= need.id then self:FinishWithdrawal("Retrait non effectué : vérifie le curseur et tes sacs."); return end
                        PickupContainerItem(targetBag, targetSlot)
                        if GetCursorInfo() then
                            -- The source slot is either empty or the remainder of this same stack.
                            PickupContainerItem(bag, slot)
                            self:FinishWithdrawal("Transfert refusé : vérifie le curseur et l'espace dans tes sacs.")
                        end
                        return
                    end
                end
            end
            self:FinishWithdrawal("Retrait partiel : composant absent de ta banque — " .. need.name .. "."); return
        end
    end
    self:FinishWithdrawal("Composants retirés. Clique sur Fabriquer ou Lancer la file pour continuer.")
end
