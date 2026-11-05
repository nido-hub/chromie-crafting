local A=ChromieCrafting
assert(A.OpenDashboard, "tableau de bord du compte absent")
A.db.size={width=1100,height=820}; A.frame=nil
A.running=false; A.pending=nil; A.withdrawal=nil; A.viewing=nil
A.options.search=""; A.options.favoritesOnly=false
function GetSpellName(index) return ({"Alchimie","Cuisine"})[index] end
A:OpenDashboard()
assert(A.frame:IsShown() and A.professionTabs and #A.professionTabs>=2, "fenêtre unique avec onglets des métiers")
local alt="Royaume.Artisan"
A.account.characters[alt]={name="Artisan",realm=A.realm,bags={},bank={},professions={Couture={rank=450,maxRank=450,updated=1,recipes={{key="s777",name="Tissu",category="Étoffes",known=true,reagents={{id=10,count=2}}}},queue={}}}}
A:SelectCharacter(alt,"Couture")
assert(A.characterDropdown and A.detailTitle and not A.craftButton.enabled, "personnage consulté visible sans fabrication")
assert(A.favoriteButton and A.withdrawButton and A.withdrawQueueButton, "favoris et retraits accessibles")
A.selectedKey="s777"; A:Render()
A.favoriteButton.scripts.OnClick()
assert(A:IsFavorite("s777"), "bouton favori de la recette sélectionnée")
assert(not A.withdrawButton.enabled and not A.withdrawQueueButton.enabled, "aucun retrait pour un autre personnage")
A.queue={{key="s777",name="Tissu",count=7}}; A:Render()
local cachedField=A.queueRows[1].quantity
cachedField:SetFocus(); cachedField:SetText("1"); cachedField:ClearFocus()
assert(A.queue[1].count==7, "file d'un autre personnage en lecture seule")
local tabs=0
for _,tab in ipairs(A.professionTabs) do if tab:IsShown() then tabs=tabs+1 end end
assert(tabs>=3, "les métiers découverts des autres personnages ont un onglet")
print("PASS: tableau de bord du compte, onglets, personnages, favoris et actions sûres")
local previousRead=A.ReadCatalog
local catalogRead=false
A.ReadCatalog=function() catalogRead=true; return {} end
A.profession="Alchimie"; A.viewing=true; A.catalog={}
A:OnEvent("TRADE_SKILL_SHOW")
assert(catalogRead and not A.viewing, "ouvrir un métier consulté recharge son catalogue natif")
A.ReadCatalog=previousRead
A.withdrawal={needs={}}
local queueLength=#A.queue
local queueCount=A.queue[1] and A.queue[1].count
A.quantity:SetText("1")
A.selectedKey="s101"
A.addButton.scripts.OnClick()
assert(#A.queue==queueLength and (A.queue[1] and A.queue[1].count)==queueCount, "aucune modification de file pendant un retrait")
A:Stop()
assert(not A.withdrawal, "Arrêter annule aussi le retrait bancaire")
print("PASS: retour au métier actif et arrêt des retraits")
local originalCount=GetItemCount
function GetItemCount(id, includeBank) return includeBank and 100 or 1 end
local bagRecipe=A:RecipeAt(2)
assert(bagRecipe.available==0 and bagRecipe.reagents[1].owned==1, "fabrication : stocks des sacs, jamais les compteurs natifs incluant la banque")
GetItemCount=originalCount
