-- The game APIs are the external boundary; model/catalog/controller run unchanged.
local A = ChromieCrafting
local spells = {[2259] = "Alchimie", [7411] = "Enchantement", [2018] = "Forge", [4036] = "Ingénierie", [3273] = "Secourisme", [45357] = "Calligraphie", [25229] = "Joaillerie", [2108] = "Travail du cuir", [2575] = "Minage", [2656] = "Fonte", [3908] = "Couture", [2550] = "Cuisine", [101] = "Potion A", [102] = "Potion B", [103] = "Inconnue"}
function GetSpellInfo(id) return spells[id], "", "icon", 0, false, 0, 1500 end
function GetItemInfo(id) return "Objet " .. id, "item:" .. id end
function LoadAddOn() return true end
AtlasLoot_Data = {
    AlchemyPotion1 = {{1,"s101","501","=q1=Potion A","=ds=Maître"}, {2,"s103","503","=q1=Inconnue","=ds=Vendeur"}},
    AlchemyPotion2 = {{1,"s103","503","=q1=Inconnue","=ds=Réputation"}},
    Cooking1 = {{1,"s999","999","Nourriture",""}},
}
assert(io.open(ADDON_ROOT .. "/Catalog.lua"), "Catalog.lua absent")
dofile(ADDON_ROOT .. "/Catalog.lua")
local catalog = A:ReadCatalog("Alchimie")
assert(catalog[101].category == "Potions" and catalog[103].source:find("Vendeur"), "catégorie et provenance")
assert(catalog[103].source:find("Réputation") and not catalog[999], "fusion des sources, métier isolé")

SlashCmdList = {}; UISpecialFrames = {}; UIParent = {}
local eventFrame
function CreateFrame()
    local f = {scripts = {}, events = {}}
    function f:RegisterEvent(e) self.events[e] = true end
    function f:SetScript(e, fn) self.scripts[e] = fn end
    function f:GetScript(e) return self.scripts[e] end
    eventFrame = f
    return f
end
DEFAULT_CHAT_FRAME = {AddMessage = function() end}
local now, linked, available, cooldown, tools = 1, false, 8, 0, true
local records = {
    {name = "Potions", kind = "header"},
    {name = "Potion A", kind = "optimal", spell = 101, item = 501},
    {name = "Potion B", kind = "easy", spell = 102, item = 502},
}
function GetTime() return now end
function GetTradeSkillLine() return "Alchimie", 100, 150 end
function GetNumTradeSkills() return #records end
function GetTradeSkillInfo(i) local r=records[i]; return r.name, r.kind, available, true end
function GetTradeSkillRecipeLink(i) return "enchant:" .. records[i].spell end
function GetTradeSkillItemLink(i) return "item:" .. records[i].item end
function GetTradeSkillIcon() return "icon" end
function GetTradeSkillNumMade() return 1, 1 end
function GetTradeSkillNumReagents() return 1 end
function GetTradeSkillReagentInfo() return "Herbe", "icon", 2, 16 end
function GetTradeSkillReagentItemLink() return "item:10" end
function GetTradeSkillCooldown() return cooldown end
function GetTradeSkillTools() return "Fiole", tools end
function GetTradeSkillDescription() return "Description" end
function IsTradeSkillLinked() return linked end
function GetItemCount() return 16 end
function InCombatLockdown() return false end
function SpellIsTargeting() return false end
function UnitCastingInfo() end
function UnitChannelInfo() end
function SelectTradeSkill() end
local calls, stopped = {}, 0
function DoTradeSkill(i, count) calls[#calls+1] = {index=i,count=count} end
function StopTradeSkillRepeat() stopped=stopped+1 end
function SpellStopCasting() end
function CloseTradeSkill() end
assert(io.open(ADDON_ROOT .. "/Core.lua"), "Core.lua absent")
dofile(ADDON_ROOT .. "/Core.lua")
dofile(ADDON_ROOT .. "/Account.lua")
dofile(ADDON_ROOT .. "/Bank.lua")
A.Render = function() end
A:Initialize()
A.open = true
A:RefreshRecipes()
assert(A.byKey.s101.known and not A.byKey.s103.known and #A.recipes == 3, "catalogue comparé aux sorts appris")
assert(A.Model.Add(A.queue, A.byKey.s101, 2))
-- Indices changeants : le craft doit retrouver le sort, pas utiliser l'ancien index.
records[2], records[3] = records[3], records[2]
A:StartQueue()
assert(#calls == 1 and calls[1].index == 3 and calls[1].count == 2, "identifiant stable et répétition native lancée au clic")
A:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Potion B", "", 1, 102)
assert(A.queue[1].count == 2, "succès d'un autre sort ignoré")
A:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Potion A", "", 2, 101)
assert(A.queue[1].count == 1 and #calls == 1, "succès confirmé, attente de mise à jour des sacs")
now = now + 1; A:Tick(1)
assert(#calls == 1 and A.pending, "aucun appel protégé depuis le minuteur ; le lot reste suivi")
A:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Potion A", "", 2, 101)
assert(A.queue[1].count == 1, "confirmation dupliquée ignorée dans un lot")
A:OnEvent("UNIT_SPELLCAST_INTERRUPTED", "player", "Potion A", "", 3, 101)
assert(not A.running and A.queue[1].count == 1, "interruption conserve le travail restant")
available = 0; A:StartQueue()
assert(#calls == 1 and not A.running, "pas de composants : pas de craft")
available = 8; cooldown = 10; A:StartQueue()
assert(#calls == 1 and not A.running, "recharge : pas de craft")
cooldown = 0; tools = false; A:StartQueue()
assert(#calls == 1 and not A.running, "outil manquant : pas de craft")
tools = true; linked = true; A:StartQueue()
assert(#calls == 1 and not A.running, "métier lié : lecture seule")
linked = false; A:StartQueue()
assert(#calls == 2)
A:OnEvent("TRADE_SKILL_CLOSE")
assert(not A.running and A.queue[1].count == 1, "fermeture arrête sans perdre la file")
A:OnEvent("UNIT_SPELLCAST_FAILED", "player", "Potion A", "", 4, 101)
A.open = true
records[2].name, records[3].name = "Même nom", "Même nom"
A:RefreshRecipes(); A:StartQueue()
A:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Même nom", "", 5, 102)
assert(A.queue[1].count == 1, "homonymes différenciés par identifiant de sort")
A:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Même nom", "", 6, 101)
assert(#A.queue == 0)
A:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Même nom", "", 6, 101)
assert(#A.queue == 0, "succès répété sans double décompte")
now=now+1; A:Tick(1)
assert(not A.running)
records[2].name, records[3].name = "Potion B", "Potion A"
A:RefreshRecipes()
A.Model.Add(A.queue, A.byKey.s102, 3)
A.selectedKey = "s101"
A:CraftSelected(2)
A:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Potion A", "", 7, 101)
assert(A.jobs[1].count == 1 and A.queue[1].count == 3, "fabrication directe ne modifie pas la file préparée")
now=now+1; A:Tick(1)
now=now+121; A:Tick(121)
assert(A.pending and not A.running and A.jobs[1].count == 1, "absence de confirmation : suivi conservé sans répétition ni retrait")
A:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Potion A", "", 8, 101)
assert(#A.jobs == 0 and A.queue[1].count == 3, "succès tardif décompté sans relancer")
A:CraftSelected(1)
A.pending.target = true
local targeting = true
function SpellIsTargeting() return targeting end
now=now+121; A:Tick(121)
assert(A.pending and not A.running, "enchantement en attente : suivi conservé au-delà du délai")
targeting = false
A:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Potion A", "", 9, 101)
assert(#A.jobs == 0 and not A.pending and not A.running, "enchantement tardif compté une seule fois")
-- Deux succès distincts du lot, puis clic requis pour la recette suivante.
A.queue = {}; A.Model.Add(A.queue, A.byKey.s101, 2); A.Model.Add(A.queue, A.byKey.s102, 1)
local before = #calls
A:StartQueue()
A:OnEvent("UNIT_SPELLCAST_SENT", "player", "Potion A", "", "player", 10)
A:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Potion A", "", 10, 101)
A:OnEvent("UNIT_SPELLCAST_SENT", "player", "Potion A", "", "player", 11)
A:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Potion A", "", 11, 101)
now=now+1; A:Tick(1)
assert(#calls == before+1 and not A.running and not A.pending and #A.queue == 1 and A.queue[1].key == "s102", "lot terminé : pas de changement automatique de recette")
A:StartQueue()
assert(#calls == before+2, "le clic suivant lance la prochaine recette")
A:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Potion B", "", 12, 102)
available=2; A.selectedKey="s101"; A:CraftSelected(5)
assert(calls[#calls].count == 2, "lot limité aux composants disponibles")
A:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Potion A", "", 13, 101)
A:Stop()
A:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Potion A", "", 14, 101)
assert(not A.pending and not A.running and A.jobs[1].count == 3, "arrêt du lot : succès tardif décompté sans répétition")
available=8
local resolve = A.Resolve
function A:Resolve(key) local r, err=resolve(self,key); if r then r.requiresTarget=true end; return r,err end
A:CraftSelected(3)
assert(calls[#calls].count == 1, "enchantement manuel : une seule cible par clic")
A:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Potion A", "", 15, 101)
assert(not A.pending and not A.running and A.jobs[1].count == 2, "enchantement : pas de répétition automatique")
A.Resolve=resolve
-- Restore the fixture expected by the UI smoke test.
A.queue = {}; A.db.queues.Alchimie=A.queue
A.Model.Add(A.queue, A.byKey.s101, 1)
local nativeRefreshed=false
TradeSkillFrame = CreateFrame()
function ShowUIPanel() end
function TradeSkillFrame_Show() nativeRefreshed=true end
A:UseNative()
assert(nativeRefreshed, "retour Blizzard : sélection et détails rafraîchis via son entrée normale")
TradeSkillFrame=nil
A.native, A.db.native = false, false
print("PASS: catalogue, identité, file, succès, interruption, composants, recharge, outils, métier lié")
