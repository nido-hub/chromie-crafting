local A = ChromieCrafting
local scale = A.frame:GetScale()
assert(A.frame.minWidth <= 740 and A.frame.minHeight <= 600, "la poignée permet une fenêtre compacte de 740 × 600")
for _, size in ipairs({{740,600}, {780,620}, {820,640}, {900,600}, {980,600}, {900,640}, {980,640}, {740,900}, {820,900}, {1400,1000}}) do
    A.frame:SetWidth(size[1]); A.frame:SetHeight(size[2])
    assert(A.frame:GetScale() == scale, "réduire conserve la taille du texte")
    assert(A.recipeVisibleRows >= 10 and A.queueVisibleRows >= 3, "listes compactes toujours utilisables")
    assert(A.queueRows[1].text:GetWidth() >= 90, "noms de la file lisibles avec les contrôles de quantité")
    local page = A.recipePage
    local craftY, withdrawY = A.craftButton.point[3], A.withdrawButton.point[3]
    assert(craftY >= withdrawY + A.withdrawButton:GetHeight() or
        A.craftButton:GetWidth()+A.addButton:GetWidth()+A.withdrawButton:GetWidth()+20 <= page:GetWidth(), "actions sans chevauchement")
    assert(A.output:GetWidth() >= 180, "résultat et stocks gardent une largeur lisible")
    assert(A.reagentScroll:GetHeight() >= 50, "composants accessibles par défilement même à hauteur minimum")
    assert(A.reagentScroll:GetHeight() - A.reagentScroll.point[3] <= page:GetHeight()-130, "composants au-dessus des commandes")
    if A.leftPanel:GetWidth() < 330 then
        assert(-A.sortDropdown.point[3] >= 76, "filtres empilés dans la colonne étroite")
        assert(-A.recipeList.point[3] >= 139, "recettes sous les filtres et les favoris")
        assert(A.recipeRows[1].text:GetWidth() >= 180, "noms de recettes encore lisibles")
    end
    if page:GetWidth() < 455 then
        assert(A.needsScroll:GetWidth() >= 250, "besoins sur toute la largeur en mode compact")
        assert(-A.needsTitle.point[3] >= 36+A.queueList:GetHeight()+24, "besoins sous la file et sa pagination")
        assert(-A.needsScroll.point[3]+A.needsScroll:GetHeight() <= A.queuePage:GetHeight()-90, "besoins au-dessus des actions")
        assert(A.withdrawQueueButton.point[3]+A.withdrawQueueButton:GetHeight() <= A.startButton.point[3], "retrait de la file sur une ligne distincte")
    end
end
A.frame:SetWidth(740); A.frame:SetHeight(600)
A.resizeGrip.scripts.OnMouseUp(A.resizeGrip,"LeftButton")
assert(A.db.size.width == 740 and A.db.size.height == 600, "taille compacte mémorisée")
A.frame=nil; A:CreateUI()
assert(A.frame:GetWidth()==740 and A.frame:GetHeight()==600, "taille compacte restaurée sans agrandir la fenêtre")
A.frame:SetWidth(980); A.frame:SetHeight(740)
assert(A.craftButton.point[3]==24 and A.needsScroll.point[2]>0, "disposition large rétablie après agrandissement")
print("PASS: fenêtre compacte, texte inchangé, actions séparées, listes défilantes et taille restaurée")
