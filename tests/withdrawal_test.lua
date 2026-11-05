-- Skipping a missing ingredient must not skip the remaining available ones.
local A = ChromieCrafting
local savedRender, savedInventory = A.Render, A.SaveInventory
A.Render = function() end
A.SaveInventory = function() end
local contents, bags, cursor, clock, combat
local guild, visible, allowance, currentTab, locked, queried, splits, pickups
local oldTime, oldCombat = GetTime, InCombatLockdown
function GetTime() return clock end
function InCombatLockdown() return combat end
function GetItemCount(id) return bags[id] or 0 end
function GetContainerNumSlots(bag) return bag == -1 and 2 or (bag == 0 and 8 or 0) end
function GetContainerItemLink(bag, slot)
    local item = contents[bag] and contents[bag][slot]
    return item and ('item:' .. item.id)
end
function GetContainerItemInfo(bag, slot)
    local item = contents[bag] and contents[bag][slot]
    if item then return 'icon', item.count, locked end
end
function GetContainerNumFreeSlots() return 8, 0 end
function GetCursorInfo() if cursor then return 'item', cursor.id end end
function PickupContainerItem(bag, slot)
    if cursor then
        assert(not contents[bag][slot], 'ne jamais écraser un objet')
        contents[bag][slot] = cursor
        bags[cursor.id] = (bags[cursor.id] or 0) + cursor.count
        cursor = nil
    else
        cursor = contents[bag][slot]; contents[bag][slot] = nil
    end
end
function SplitContainerItem(bag, slot, amount)
    local item = contents[bag][slot]
    cursor = {id=item.id, count=amount}; item.count = item.count - amount
end
function GetCurrentGuildBankTab() return currentTab end
function GetGuildBankTabInfo() return 'Composants', 'icon', visible, true, allowance, allowance end
function QueryGuildBankTab(tab) queried = tab end
function GetGuildBankItemLink(tab, slot)
    local item = guild[slot]; return item and ('item:' .. item.id)
end
function GetGuildBankItemInfo(tab, slot)
    local item = guild[slot]; if item then return 'icon', item.count, locked end
end
function PickupGuildBankItem(tab, slot)
    pickups = pickups + 1; cursor = guild[slot]; guild[slot] = nil
end
function SplitGuildBankItem(tab, slot, amount)
    splits = splits + 1
    local item = guild[slot]; cursor = {id=item.id, count=amount}; item.count=item.count-amount
end
local function reset()
    contents, bags, cursor, clock, combat = {[-1]={{id=20,count=10}},[0]={}}, {}, nil, 100, false
    guild, visible, allowance, currentTab, locked = {{id=20,count=10}}, true, 5, 2, false
    queried, splits, pickups = nil, 0, 0
    A.bankOpen, A.guildBankOpen = true, false
    A.running, A.pending, A.withdrawal, A.viewing = false, nil, nil, nil
    A.open, A.native = true, false
    local r = {key='withdraw',known=true,name='Recette',reagents={
        {id=10,name='Essence absente',count=2}, {id=20,name='Minerai',count=2}}}
    A.byKey, A.selectedKey, A.queue = {withdraw=r}, 'withdraw', {{key='withdraw',count=2}}
end
reset(); A:Withdraw(false, 1)
assert(bags[20] == 2, 'un composant absent ne bloque pas les autres retraits')
A:ContinueWithdrawal()
assert(not A.withdrawal and A.status:find('Essence absente'), 'bilan explicite des composants manquants')
reset(); contents[-1][1].count=1; A:Withdraw(true)
A:ContinueWithdrawal()
assert(bags[20] == 1 and not A.withdrawal and A.status:find('Minerai'), 'stock partiel retiré et manque signalé')
print('PASS: retrait partiel malgré un ingrédient absent, recette et file')

reset(); A.bankOpen=false; A:OnEvent('GUILDBANKFRAME_OPENED')
assert(A.guildBankOpen, 'ouverture banque de guilde suivie')
A:Withdraw(false, 2)
assert(A.withdrawal and queried==2 and not bags[20], 'attendre la réponse serveur de l’onglet ouvert')
A:OnEvent('GUILDBANKBAGSLOTS_CHANGED')
assert(bags[20]==4 and splits==1 and pickups==0 and not cursor, 'retrait BDG exact sans pile entière')
A:ContinueWithdrawal()
assert(not A.withdrawal and not A.pending and not A.running, 'aucune fabrication automatique en BDG')
reset(); A.bankOpen=false; A.guildBankOpen=true; allowance=0
A:Withdraw(false, 1); A:OnEvent('GUILDBANKBAGSLOTS_CHANGED')
assert(not bags[20] and splits==0 and pickups==0, 'quota épuisé : aucun retrait')
reset(); A.bankOpen=false; A.guildBankOpen=true; visible=false
A:Withdraw(false, 1); A:OnEvent('GUILDBANKBAGSLOTS_CHANGED')
assert(not bags[20] and splits==0, 'onglet invisible : aucun retrait')
reset(); A.bankOpen=false; A.guildBankOpen=true; allowance=-1; guild[1].count=2
A:Withdraw(false, 1); A:OnEvent('GUILDBANKBAGSLOTS_CHANGED')
assert(bags[20]==2 and pickups==1, 'droits illimités et pile exacte acceptés')
reset(); A.bankOpen=false; A.guildBankOpen=true; locked=true
A:Withdraw(false, 1); A:OnEvent('GUILDBANKBAGSLOTS_CHANGED')
assert(not bags[20] and not cursor, 'objet BDG verrouillé préservé')
reset(); A.bankOpen=false; A.guildBankOpen=true
A:Withdraw(false, 1); currentTab=3; A:OnEvent('GUILDBANKBAGSLOTS_CHANGED')
assert(not bags[20] and not A.withdrawal, 'changer d’onglet arrête le retrait')
reset(); A.bankOpen=false; A.guildBankOpen=true
A:Withdraw(false, 1); A:OnEvent('GUILDBANKFRAME_CLOSED')
assert(not A.guildBankOpen and not A.withdrawal and not bags[20], 'fermeture BDG annule le retrait')
reset(); A.bankOpen=false; A.guildBankOpen=true
A:Withdraw(false, 1); clock=106; A:ContinueWithdrawal()
assert(not A.withdrawal and not bags[20], 'absence de réponse BDG : pas de transfert')
reset(); A.bankOpen=false; A.guildBankOpen=true
A:Withdraw(false, 1); combat=true; A:OnEvent('GUILDBANKBAGSLOTS_CHANGED')
assert(not A.withdrawal and not bags[20], 'combat : aucun transfert BDG')
reset(); A.bankOpen=false; A.guildBankOpen=true
local split=SplitGuildBankItem
local pendingCursor
function SplitGuildBankItem(tab, slot, amount)
    split(tab, slot, amount); pendingCursor, cursor=cursor,nil
end
A:Withdraw(false, 1); A:OnEvent('GUILDBANKBAGSLOTS_CHANGED')
assert(A.withdrawal and not bags[20] and splits==1, 'prise BDG asynchrone : attendre le curseur')
A:ContinueWithdrawal()
assert(splits==1 and not bags[20], 'pas de seconde prise pendant l’attente du curseur')
cursor, pendingCursor=pendingCursor,nil; A:ContinueWithdrawal(); A:ContinueWithdrawal()
assert(bags[20]==2 and not A.withdrawal and not cursor, 'curseur BDG reçu plus tard : placement confirmé une seule fois')
SplitGuildBankItem=split
A.guildBankOpen, A.bankOpen, A.withdrawal = false, false, nil
A.Render, A.SaveInventory = savedRender, savedInventory
GetTime, InCombatLockdown = oldTime, oldCombat
print('PASS: banque de guilde, chargement, quantités, permissions, quotas, verrous, délai et fermeture')
