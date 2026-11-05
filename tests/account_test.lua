-- Removing snapshot isolation, realm filtering or bag-only crafting breaks these checks.
local A = ChromieCrafting
function UnitName() return "Main" end
function GetRealmName() return "Chromie" end
function time() return 1000 end
assert(A.InitializeAccount, "sauvegarde des métiers et stocks du compte absente")
A:InitializeAccount()
local me=A.characterKey
local bags,bank=3,7
function GetItemCount(id, includeBank) return bags+(includeBank and bank or 0) end
A.account.characters["Chromie.Alt"]={name="Alt",realm="Chromie",bags={[10]=5},bank={[10]=11},professions={}}
A.account.characters["Other.Alt"]={name="Alt",realm="Other",bags={[10]=999},bank={},professions={}}
A.db.includeBank=false; A.db.includeAlts=false
assert(A:InventoryCount(10)==3, "sacs seuls par défaut")
A.db.includeBank=true
assert(A:InventoryCount(10)==10, "banque du personnage ajoutée une seule fois")
A.db.includeAlts=true
assert(A:InventoryCount(10)==26, "stocks du compte sur le même royaume uniquement")
A.db.includeBank=false
assert(A:InventoryCount(10)==8, "banques des autres exclues si banque décochée")
local r={key="s101",name="Potion",known=true,category="Potions",index=9,available=99,reagents={{id=10,name="Herbe",count=2}},difficulty="easy",order=1}
assert(A:PlannedCount(r)==4, "quantité planifiable distincte de la quantité native")
A.recipes={r}; A.byKey={s101=r}; A.profession="Alchimie"; A.rank=100; A.maxRank=150
A.queue={{key="s101",name="Potion",count=7}}; A.db.queues.Alchimie=A.queue
A:SaveProfession()
assert(A.character.professions.Alchimie.queue[1] and A.character.professions.Alchimie.queue[1].count==7, "file actuelle visible dans les données du compte")
A.Model.Complete(A.queue,"s101")
assert(A.character.professions.Alchimie.queue[1].count==6, "succès de craft répercuté dans la file mémorisée")
r.name="Changed"
assert(A.account.characters[me].professions.Alchimie.recipes[1].name=="Potion", "copie indépendante des recettes")
assert(not A.account.characters[me].professions.Alchimie.recipes[1].index, "indices natifs jamais persistés")
A:ToggleFavorite("s101")
assert(A:IsFavorite("s101"), "favoris persistants par métier")
A.options.favoritesOnly=true; A.options.favorites=A.db.favorites.Alchimie
assert(#A.Model.Rows({r},{favoritesOnly=true,favorites={}})==0, "filtre favoris")
assert(#A.Model.Rows({r},A.options)==2, "favori conservé dans sa catégorie")
A:SelectCharacter("Chromie.Alt", "Alchimie")
assert(A.viewing and #A.recipes==0, "métier non scanné ne réutilise jamais les recettes du personnage précédent")
local called=false; local oldResolve=A.Resolve
A.Resolve=function() called=true end
A.running=true; A.jobs={{key="s101",count=1}}; A.open=true
A:NextCraft()
assert(not called and not A.running, "aucun craft avec un personnage consulté")
A.Resolve=oldResolve
print("PASS: compte, royaume, options de stocks, favoris, snapshots isolés et lecture seule")

-- Bank transfer fixture: actual container contents change only after the API call.
assert(A.Withdraw, "retrait bancaire absent")
local slots={[-1]={{id=10,count=10}},[0]={{id=10,count=3},false}}
local cursor,locked,full=false,false,false
function GetContainerNumSlots(bag) return slots[bag] and #slots[bag] or 0 end
function GetContainerItemID(bag,slot) local s=slots[bag] and slots[bag][slot]; return s and s.id end
function GetContainerItemLink(bag,slot) local id=GetContainerItemID(bag,slot); return id and "item:"..id end
function GetContainerItemInfo(bag,slot) local s=slots[bag] and slots[bag][slot]; if s then return "icon",s.count,locked end end
function GetContainerNumFreeSlots(bag) return full and 0 or (bag==0 and 1 or 0),0 end
function CursorHasItem() return cursor~=false end
function GetCursorInfo() if cursor then return "item",cursor.id end end
function SplitContainerItem(bag,slot,count)
 local s=slots[bag][slot]; assert(count<=s.count); cursor={id=s.id,count=count}; s.count=s.count-count
end
function PickupContainerItem(bag,slot)
 if cursor then assert(not slots[bag][slot], "pas d'échange destructif"); slots[bag][slot]=cursor; bags=bags+cursor.count; bank=bank-cursor.count; cursor=false
 else local s=slots[bag][slot]; cursor=s; slots[bag][slot]=false end
end
function GetItemFamily() return 0 end
A.viewing=nil; A.running=false; A.pending=nil; A.bankOpen=true; A.options.favoritesOnly=false
A.recipes={r}; A.byKey={s101=r}; A.selectedKey="s101"
bags=3; bank=10
A:Withdraw(false,4)
assert(bags==8 and bank==5 and not cursor, "retrait exact du manque, pas de pile entière ni de craft")
A:OnEvent("BAG_UPDATE",0)
assert(not A.withdrawal, "confirmation du transfert")
bags=3; bank=10; slots[0][2]=false; slots[-1][1].count=10
full=true; A:Withdraw(false,4)
assert(bags==3 and bank==10 and not cursor and not A.withdrawal, "sacs pleins : aucun objet pris au curseur")
full=false; locked=true; A:Withdraw(false,4)
assert(bags==3 and not cursor, "objet verrouillé : aucun retrait")
locked=false; A.bankOpen=false; A:Withdraw(false,4)
assert(bags==3 and not cursor, "banque fermée : aucun retrait")
A.bankOpen=true; cursor={id=123,count=1}; A:Withdraw(false,4)
assert(cursor.id==123 and bags==3, "curseur occupé préservé")
cursor=false
A.queue={{key="s101",count=2},{key="s101",count=2}}
A:Withdraw(true)
assert(bags==8 and bank==5, "file : besoins partagés additionnés, sacs soustraits une seule fois")
A:OnEvent("BAG_UPDATE",0)
assert(not A.withdrawal and not A.pending and not A.running, "fin du retrait de file sans fabrication")
-- A delayed server count must never trigger a duplicate withdrawal.
slots[0][3]=false
local pickup=PickupContainerItem
local placements=0
function PickupContainerItem(bag,slot)
    local previousBags,previousBank=bags,bank
    pickup(bag,slot)
    if bag>=0 and bag<=4 then placements=placements+1; bags,bank=previousBags,previousBank end
end
local clock=GetTime
local tick=100
function GetTime() return tick end
A:Withdraw(false,6)
assert(A.withdrawal and placements==1 and bags==8, "transfert en attente de confirmation serveur")
A:Tick(0.15)
assert(placements==1 and A.withdrawal, "pas de double transfert pendant l'attente")
tick=106; A:Tick(0.15)
assert(not A.withdrawal and placements==1, "confirmation absente : arrêt sans nouvelle tentative")
PickupContainerItem=pickup; GetTime=clock
bags,bank=12,1
A.withdrawal={needs={}}; A:OnEvent("BANKFRAME_CLOSED")
assert(not A.withdrawal and not A.bankOpen, "fermeture de banque annule l'opération")
A.bankOpen=false
print("PASS: retrait bancaire exact, file, confirmation différée, délai, sacs pleins, verrous, fermeture et curseur")
