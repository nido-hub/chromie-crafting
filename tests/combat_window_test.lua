local A=ChromieCrafting
assert(A.RequestClose, "fermeture différée en combat absente")
local oldCombat=InCombatLockdown
local combat=false
function InCombatLockdown() return combat end
local frame=A.frame
local hide=frame.Hide
function frame:Hide() assert(not combat,"tentative de masquer un ancêtre protégé en combat"); hide(self) end
function frame:StartMoving() assert(not combat,"déplacement protégé en combat"); self.moving=true end
function frame:StartSizing() assert(not combat,"redimensionnement protégé en combat"); self.sizing=true end
function frame:StopMovingOrSizing() assert(not combat,"arrêt de déplacement protégé en combat"); self.moving,self.sizing=nil,nil end
for _,name in ipairs(UISpecialFrames) do assert(name~="ChromieCraftingFrame", "Échap ne doit pas masquer directement la fenêtre protégée") end
assert(A.escapeFrame and A.closeButton, "Échap et croix passent par la fermeture différée")
frame:Show(); combat=true
A.closeButton.scripts.OnClick()
assert(frame:IsShown() and A.hideAfterCombat, "croix en combat : fermeture en attente")
A.escapeFrame.scripts.OnHide()
assert(frame:IsShown() and A.hideAfterCombat, "Échap en combat : aucune opération interdite")
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
frame:Show(); A.closeButton.scripts.OnClick()
assert(not frame:IsShown(), "fermeture immédiate hors combat")
InCombatLockdown=oldCombat
print("PASS: croix, Échap, métier fermé, bascule, déplacement et redimensionnement en combat")
