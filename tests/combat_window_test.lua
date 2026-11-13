local A=ChromieCrafting
assert(A.RequestClose, "fermeture différée en combat absente")
local oldCombat=InCombatLockdown
local combat=false
function InCombatLockdown() return combat end
local frame=A.frame
local hide=frame.Hide
function frame:Hide() assert(not combat or self:IsTestSecureContext(),"tentative de masquer un ancêtre protégé en combat"); hide(self) end
function frame:StartMoving() assert(not combat,"déplacement protégé en combat"); self.moving=true end
function frame:StartSizing() assert(not combat,"redimensionnement protégé en combat"); self.sizing=true end
function frame:StopMovingOrSizing() assert(not combat,"arrêt de déplacement protégé en combat"); self.moving,self.sizing=nil,nil end
for _,name in ipairs(UISpecialFrames) do assert(name~="ChromieCraftingFrame", "Échap ne doit pas masquer directement la fenêtre protégée") end
assert(A.closeButton, "bouton de fermeture absent")
local oldClose,oldRepeat=CloseTradeSkill,StopTradeSkillRepeat
local closed,stopped=0,0
function CloseTradeSkill() closed=closed+1 end
function StopTradeSkillRepeat() stopped=stopped+1 end
A.open=true; A.running=true
frame:Show(); combat=true
A.closeButton:Click()
assert(not frame:IsShown() and not A.hideAfterCombat, "croix : fermeture immédiate en combat")
assert(closed==1 and stopped>0 and not A.open and not A.running, "fermer arrête le craft et ferme le métier natif")
assert(not frame.binding, "fermeture : Échap libéré même en combat")
combat=false; frame:Show(); combat=true
A:RequestClose()
assert(A.hideAfterCombat, "fermeture API en attente")
assert(frame.binding and frame.binding.key=='ESCAPE', "Échap lié à la fermeture sécurisée")
_G[frame.binding.name]:Click(frame.binding.button)
assert(not frame:IsShown() and not frame.binding and not A.hideAfterCombat, "Échap : fermeture immédiate et attente annulée")
combat=false; frame:Show(); A:OnEvent('PLAYER_REGEN_ENABLED')
assert(frame:IsShown(), "aucune fermeture périmée après réouverture")
combat=false; frame:Show(); combat=true
frame.scripts.OnDragStart(frame)
A.resizeGrip.scripts.OnMouseDown(A.resizeGrip,"LeftButton")
A.resizeGrip.scripts.OnMouseUp()
assert(not frame.moving and not frame.sizing, "déplacement et taille bloqués en combat")
A.open=true; A.viewing=nil; A:OnEvent("TRADE_SKILL_CLOSE")
assert(frame:IsShown() and A.hideAfterCombat and not A.open, "fermeture du métier en combat différée")
local native=A.native
A:UseNative()
assert(A.native==native, "bascule vers Blizzard bloquée en combat")
combat=false; A:OnEvent("PLAYER_REGEN_ENABLED")
assert(not frame:IsShown() and not A.hideAfterCombat, "fermeture appliquée dès la sortie de combat")
frame:Show(); A.closeButton:Click()
assert(not frame:IsShown(), "fermeture immédiate hors combat")
local page=A.recipePage
local pageShow,pageHide=page.Show,page.Hide
function page:Show() assert(not combat, 'afficher un ancêtre du bouton feu en combat'); pageShow(self) end
function page:Hide() assert(not combat, 'masquer un ancêtre du bouton feu en combat'); pageHide(self) end
combat=false; A:ShowDetailPage('recipe')
combat=true; A:ShowDetailPage('queue')
assert(A.detailPage=='recipe' and page:IsShown(), 'changement de page bloqué en combat')
combat=false; A:ShowDetailPage('queue')
assert(A.detailPage=='queue' and not page:IsShown(), 'changement de page disponible hors combat')
A:ShowDetailPage('recipe')
page.Show,page.Hide=pageShow,pageHide
InCombatLockdown=oldCombat
CloseTradeSkill,StopTradeSkillRepeat=oldClose,oldRepeat
frame.Hide=hide
print("PASS: fermeture immédiate par croix et Échap sécurisés en combat ; protections et fermeture API différée")
