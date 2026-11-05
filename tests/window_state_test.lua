-- Simulate a fresh UI construction with saved dimensions and another display size.
local A = ChromieCrafting
A.frame=nil
A.db.size={width=1400,height=1000}
A:CreateUI()
assert(A.frame:GetWidth()==1400 and A.frame:GetHeight()==1000, "taille sauvegardée restaurée à l'ouverture")
assert(A.recipeVisibleRows==28 and A.queueVisibleRows==25)

local width,height=UIParent:GetWidth(),UIParent:GetHeight()
UIParent:SetWidth(900); UIParent:SetHeight(600)
A.frame=nil
A.db.size={width=99999,height=99999}
A:CreateUI()
local scale=A.frame:GetScale()
assert(A.frame:GetWidth()*scale<=876.001 and A.frame:GetHeight()*scale<=576.001, "ancienne taille limitée au nouvel écran")
assert(A.frame:GetWidth()>=980 and A.frame:GetHeight()>=740, "surface minimum conservée sans écraser les champs")
UIParent:SetWidth(width); UIParent:SetHeight(height)
print("PASS: dimensions sauvegardées, changement de résolution, petit écran")
