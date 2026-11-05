local A = ChromieCrafting
Minimap = CreateFrame("Frame", "Minimap", UIParent)
function Minimap:GetCenter() return 100,100 end
function Minimap:GetEffectiveScale() return 1 end
function GetCursorPosition() return 200,100 end
local names = {[2259]="Alchimie", [2550]="Cuisine"}
function GetSpellInfo(id) return names[id] end
function GetNumSpellTabs() return 1 end
function GetSpellTabInfo() return "Général",nil,0,3 end
function GetSpellName(index) return ({"Alchimie","Cuisine","Boule de feu"})[index] end
local combat=false
function InCombatLockdown() return combat end
A:OnEvent("PLAYER_LOGIN")
assert(A.minimapButton, "bouton minimap créé à la connexion sans ouvrir de métier")
local original=A.minimapButton
A:OnEvent("PLAYER_LOGIN")
assert(A.minimapButton==original, "pas de bouton en double")
original.scripts.OnClick(original,"RightButton")
assert(A.professionMenu:IsShown() and #A.professionButtons==2, "lanceur limité aux métiers appris")
assert(A.professionButtons[1]:GetAttribute("type")=="spell" and A.professionButtons[1]:GetAttribute("spell")=="Alchimie", "ouverture par bouton de sort sécurisé, pas de craft")
A.native=true; A.db.native=true
A.professionButtons[1].scripts.PreClick()
assert(not A.native and not A.db.native, "le lanceur réactive l'interface de l'addon")
A.professionButtons[1].scripts.PostClick()
assert(not A.professionMenu:IsShown())
combat=true
original.scripts.OnClick(original,"RightButton")
assert(not A.professionMenu:IsShown(), "pas de modification du lanceur sécurisé en combat")
combat=false
A.running=true
original.scripts.OnClick(original,"RightButton")
assert(not A.professionMenu:IsShown(), "pas de changement de métier pendant la fabrication")
A.running=false
function GetSpellName() return "Boule de feu" end
original.scripts.OnClick(original,"RightButton")
assert(not A.professionMenu:IsShown(), "aucun métier appris : message plutôt qu'un lanceur vide")
original.scripts.OnDragStart(original)
original.scripts.OnUpdate(original)
original.scripts.OnDragStop(original)
assert(type(A.db.minimapAngle)=="number" and original.scripts.OnUpdate==nil, "déplacement mémorisé et suivi arrêté")
print("PASS: minimap à la connexion, métiers appris, lancement sécurisé, combat, déplacement")
