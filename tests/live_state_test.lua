-- Native makeable counts can stay cached at zero until the profession is reopened.
local A = ChromieCrafting
local line, nativeCount, bagCount, linked = 'Cuisine', 0, 6, false
function GetTradeSkillLine() return line, 100, 150 end
function GetNumTradeSkills() return 1 end
function GetTradeSkillInfo() return 'Repas', 'easy', nativeCount, true end
function GetTradeSkillRecipeLink() return linked and 'enchant:909' or 'enchant:101' end
function GetTradeSkillItemLink() return 'item:501' end
function GetTradeSkillIcon() return 'icon' end
function GetTradeSkillNumMade() return 1, 1 end
function GetTradeSkillNumReagents() return 1 end
function GetTradeSkillReagentInfo() return 'Viande', 'icon', 2, bagCount end
function GetTradeSkillReagentItemLink() return 'item:20' end
function GetTradeSkillCooldown() return 0 end
function GetTradeSkillTools() return 'Feu de cuisine', true end
function GetItemCount(id) return id==20 and bagCount or 0 end
function IsTradeSkillLinked() return linked end
function IsSpellKnown() return true end
function InCombatLockdown() return false end
A.running, A.pending, A.withdrawal, A.native = false, nil, nil, false
A.open, A.viewing, A.viewedCharacter = true, nil, nil
A.profession, A.catalog = line, {}
assert(A:RecipeAt(1).available==3, 'le compteur natif périmé à zéro ne bloque pas les composants présents')
bagCount=0; nativeCount=99
assert(A:RecipeAt(1).available==0, 'un compteur natif positif ne permet pas de fabriquer sans composants')
bagCount=6; nativeCount=0
A:RefreshRecipes(); A.selectedKey='s101'; A:Render()
assert(A.craftButton.enabled, 'cuisine fabricable sans changer de métier malgré le compteur natif figé')

-- Returning to one's own profession must leave the snapshot/read-only state.
A:SelectCharacter(A.characterKey, 'Cuisine')
assert(not A.viewing and A.open and A.byKey.s101.available==3, 'son métier déjà ouvert reste actif après sélection du personnage')
A.selectedKey='s101'
A.open=false; A.viewing=true; A.viewedCharacter=A.characterKey
A:OpenDashboard()
assert(A.open and not A.viewing and A.craftButton.enabled, 'réouverture du tableau de bord réconcilie le métier natif sans switch')
A.viewing=true; A.viewedCharacter=A.characterKey
SlashCmdList.CHROMIECRAFTING('')
assert(not A.viewing and A.craftButton.enabled, '/ccraft quitte la consultation mémorisée pour le métier natif')

-- Banking does not need an active TradeSkill API: our own saved reagent list is sufficient.
A.byKey.s101.reagents[#A.byKey.s101.reagents+1]={id=10,name='Essence absente',count=2}
A:SaveProfession()
line='UNKNOWN'; A.open=false
A:SelectCharacter(A.characterKey, 'Cuisine'); A.selectedKey='s101'
A.bankOpen=false; A:OnEvent('GUILDBANKFRAME_OPENED'); A:Render()
assert(A.withdrawButton.enabled, 'retrait BDG proposé pour son métier mémorisé même si le métier natif est fermé')
assert(not A.craftButton.enabled, 'le retrait mémorisé ne permet jamais un craft avec le métier fermé')
local query
local sourceCount, cursor, slots = 10, nil, {}
function GetCurrentGuildBankTab() return 2 end
function QueryGuildBankTab(tab) query=tab end
function GetGuildBankTabInfo() return 'Composants','icon',true,true,-1,-1 end
function GetGuildBankItemLink(tab,slot) if slot==1 and sourceCount>0 then return 'item:20' end end
function GetGuildBankItemInfo(tab,slot) if slot==1 then return 'icon',sourceCount,false end end
function SplitGuildBankItem(tab,slot,count) sourceCount=sourceCount-count; cursor={id=20,count=count} end
function GetCursorInfo() if cursor then return 'item',cursor.id end end
function GetContainerNumSlots(bag) return bag==0 and 8 or 0 end
function GetContainerNumFreeSlots() return 8,0 end
function GetContainerItemLink(bag,slot) local s=slots[slot]; return s and ('item:'..s.id) end
function GetContainerItemInfo(bag,slot) local s=slots[slot]; if s then return 'icon',s.count,false end end
function PickupContainerItem(bag,slot)
    assert(bag==0 and not slots[slot] and cursor, 'placer uniquement dans une case vide')
    slots[slot]=cursor; bagCount=bagCount+cursor.count; cursor=nil
end
bagCount=0
A:Withdraw(false, '2')
assert(A.withdrawal and query==2, 'le clic BDG démarre réellement le retrait depuis ses recettes mémorisées')
A:OnEvent('GUILDBANKBAGSLOTS_CHANGED'); A:OnEvent('BAG_UPDATE',0)
assert(bagCount==4 and sourceCount==6 and not cursor and not A.withdrawal,
    'BDG depuis une recette mémorisée : transfert confirmé même avec un autre composant absent')
assert(A.status:find('Essence absente') and not A.pending, 'bilan des manques sans fabrication automatique')
A.queue={{key='s101',count=1}}; A:Render()
assert(A.withdrawQueueButton.enabled, 'retrait de file BDG également disponible sans métier natif')
A.bankOpen=true; A.guildBankOpen=false; A:Render()
assert(A.withdrawButton.enabled, 'retrait partiel personnel disponible sans switch de métier')
A:SelectCharacter('Other.Alt', 'Cuisine'); A:Render()
assert(not A.withdrawButton.enabled and not A.withdrawQueueButton.enabled, 'stocks des autres personnages toujours en lecture seule')
line='Cuisine'; linked=true; A.open=true; A.viewing=nil; A.profession=nil
A:RefreshRecipes(); A.selectedKey='s909'
A:OnEvent('TRADE_SKILL_CLOSE'); linked=false; line='UNKNOWN'
A:OpenDashboard(); A:Render()
assert(not A.withdrawButton.enabled, 'fermer un métier lié ne transforme pas ses recettes en recettes du personnage connecté')
query=nil; A:Withdraw(false,'1')
assert(not A.withdrawal and not query, 'le contrôleur refuse aussi les anciennes recettes liées')
line='Cuisine'; linked=true; A.open=false; A.native=true; A.byKey={}; A.recipes={}
SlashCmdList.CHROMIECRAFTING('')
assert(A.open and A.byKey.s909 and not A.native, 'retour Blizzard vers /ccraft conserve la consultation du métier lié')
A.selectedKey='s909'; A:Render()
assert(not A.craftButton.enabled and not A.withdrawButton.enabled, 'métier lié consultable mais jamais exploitable')
linked=false; line='UNKNOWN'
A:SelectCharacter(A.characterKey,'Cuisine'); A.selectedKey='s101'; A:Render()
assert(A.withdrawButton.enabled and not A.byKey.s909, 'revenir à ses recettes mémorisées restaure le retrait sans recopier le métier lié')
local messages, oldPrint = {}, A.Print
function A:Print(message) messages[#messages+1]=message end
function GetAddOnMetadata() return '0.4.1' end
A.guildBankOpen=true
SlashCmdList.CHROMIECRAFTING('debug')
assert(#messages>=4 and table.concat(messages,'\n'):find('0.4.1',1,true)
    and table.concat(messages,'\n'):find('UNKNOWN',1,true), 'diagnostic disponible même sans métier natif ouvert')
assert(A.viewing and not A.open and not A.withdrawal and bagCount==4, 'diagnostic sans ouvrir de métier ni déplacer de composants')
A.Print=oldPrint
print('PASS: compteur natif périmé, cuisine sans switch, reprise du métier, retraits personnels et BDG depuis ses recettes mémorisées')
