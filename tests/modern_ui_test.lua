local A=ChromieCrafting
assert(A.frame.surface and A.frame.surface.fill.color[4]==1, "fond opaque indépendant des textures Blizzard et des packs de textures")
assert(A.leftPanel.surface.fill.color[4]==1 and A.detailPanel.surface.fill.color[4]==1, "panneaux de lecture opaques")
assert(A.headerIcon and A.skillTrack and A.skillFill, "portrait du métier et barre de compétence")
A.rank=115; A.maxRank=150; A:Render()
assert(math.abs(A.skillFill:GetWidth() - (A.skillTrack:GetWidth()-4)*115/150)<0.01, "progression correspondant au niveau réel")
local selected=A.selectedKey
A:ShowDetailPage("queue")
assert(A.queuePage:IsShown() and not A.recipePage:IsShown(), "file accessible sans encombrer la fiche recette")
A:ShowDetailPage("recipe")
assert(A.recipePage:IsShown() and not A.queuePage:IsShown() and A.selectedKey==selected, "retour à la recette sans perdre la sélection")
local shown=0
for _,tab in ipairs(A.professionTabs) do
    if tab:IsShown() then
        shown=shown+1
        assert(tab.icon and tab:GetWidth()==44 and tab:GetHeight()==44, "onglets de métiers en icônes")
    end
end
assert(shown>0)
local listWidth=A.recipeList:GetWidth()
A.frame:SetWidth(1280); A.frame:SetHeight(950)
assert(A.recipeList:GetWidth()>listWidth, "liste élargie avec la fenêtre")
assert(A.detailPanel:GetWidth()+A.detailPanel.point[2]+78<=A.frame:GetWidth()+1, "panneau et rail de métiers contenus dans la fenêtre")
assert(A.queueList:GetHeight()+36+90<=A.queuePage:GetHeight(), "file et boutons ne se chevauchent pas")
local queues,favorites=A.db.queues,A.db.favorites
A.db.skinVersion=nil; A.db.size={width=9999,height=9999}; A.db.position={point="TOPLEFT",relativePoint="TOPLEFT",x=-999,y=999}
A.frame=nil; A:CreateUI()
assert(A.frame:GetWidth()==980 and A.frame:GetHeight()==740 and A.frame.point[1]=="CENTER", "premier chargement : ancienne géométrie remplacée par une fenêtre compacte centrée")
assert(A.db.queues==queues and A.db.favorites==favorites, "migration visuelle sans effacer les données utilisateur")
A.db.size={width=1200,height=860}; A.frame=nil; A:CreateUI()
assert(A.frame:GetWidth()==1200 and A.frame:GetHeight()==860, "tailles personnalisées conservées après la migration unique")
print("PASS: fond opaque, panneaux, progression, onglets à icônes, pages recette/file et géométrie")
