-- Structural UI smoke test; visual rendering still requires the WoW client.
local A = ChromieCrafting
local widgets = {}
local methods = {}
local function widget(name, parent)
    local w = {name=name,parent=parent,scripts={},shown=true,text="",enabled=true,width=100,height=20,scroll=0}
    setmetatable(w, {__index=methods})
    if name then _G[name]=w end
    widgets[#widgets+1]=w
    return w
end
function methods:SetScript(event, fn) self.scripts[event]=fn end
function methods:GetScript(event) return self.scripts[event] end
function methods:HookScript(event, fn) local old=self.scripts[event]; self.scripts[event]=function(...) if old then old(...) end; fn(...) end end
function methods:CreateFontString(name) return widget(name,self) end
function methods:CreateTexture(name) return widget(name,self) end
function methods:SetText(text) self.text=tostring(text or "") end
function methods:GetText() return self.text end
function methods:SetWidth(n)
    if self.width==n then return end
    self.width=n
    if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,self.width,self.height) end
end
function methods:GetWidth() return self.width end
function methods:SetHeight(n)
    if self.height==n then return end
    self.height=n
    if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,self.width,self.height) end
end
function methods:GetHeight() return self.height end
function methods:GetStringHeight() return 40 end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:Enable() assert(self.kind~="EditBox", "EditBox:Enable indisponible en 3.3.5a"); self.enabled=true end
function methods:Disable() assert(self.kind~="EditBox", "EditBox:Disable indisponible en 3.3.5a"); self.enabled=false end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:GetName() return self.name end
function methods:SetAttribute(key,value) self.attributes=self.attributes or {}; self.attributes[key]=value end
function methods:GetAttribute(key) return self.attributes and self.attributes[key] end
function methods:HasFocus() return self.focused end
function methods:SetFocus() self.focused=true; if self.scripts.OnEditFocusGained then self.scripts.OnEditFocusGained(self) end end
function methods:ClearFocus()
    if not self.focused then return end
    self.focused=false
    if self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end
end
function methods:GetPoint() return "CENTER",UIParent,"CENTER",0,0 end
function methods:GetVerticalScroll() return self.scroll end
function methods:GetVerticalScrollRange() return 100 end
function methods:SetVerticalScroll(v) self.scroll=v end
function methods:SetResizable(value) self.resizable=value end
function methods:SetMinResize(w,h) self.minWidth,self.minHeight=w,h end
function methods:SetMaxResize(w,h) self.maxWidth,self.maxHeight=w,h end
function methods:StartSizing(point) self.sizing=point end
function methods:StopMovingOrSizing() self.sizing=nil end
function methods:SetPoint(...) self.point={...} end
function methods:SetBackdrop(value) self.backdrop=value end
function methods:SetFontObject(value) self.font=value end
function methods:SetFontString(value) self.fontString=value end
function methods:SetTextInsets(...) self.insets={...} end
function methods:SetTexture(value, g, b, alpha)
    self.texture=value
    if type(value)=="number" then self.color={value,g,b,alpha} end
end
function methods:SetScale(value) self.scale=value end
function methods:GetScale() return self.scale or 1 end
for _, name in ipairs({"ClearAllPoints","SetAllPoints","SetSpacing","SetBackdropColor","SetBackdropBorderColor","SetMovable","EnableMouse","EnableKeyboard","RegisterForDrag","StartMoving","SetFrameStrata","SetClampedToScreen","SetJustifyH","SetJustifyV","SetTextColor","SetAutoFocus","SetNumeric","SetMaxLetters","SetMultiLine","SetHighlightTexture","SetNormalTexture","SetPushedTexture","SetTexCoord","EnableMouseWheel","SetScrollChild","RegisterForClicks","SetAlpha","SetOwner","SetHyperlink","AddLine","SetNormalFontObject","SetHighlightFontObject","SetDisabledFontObject"}) do methods[name]=function() end end
function CreateFrame(kind, name, parent, template)
    local w=widget(name,parent)
    w.kind=kind
    w.template=template
    if template == "UICheckButtonTemplate" and name then widget(name.."Text",w) end
    return w
end
UIParent = widget("UIParent"); UIParent.width=1920; UIParent.height=1080
GameTooltip = widget("GameTooltip")
function GetScreenWidth() return 1920 end
function GetScreenHeight() return 1080 end
function UIDropDownMenu_SetWidth() end
function UIDropDownMenu_Initialize(w,fn) w.initialize=fn end
function UIDropDownMenu_SetText(w,text) w.text=text end
function UIDropDownMenu_CreateInfo() return {} end
function UIDropDownMenu_AddButton() end
function CloseDropDownMenus() end
function GetItemIcon(id) return "item-icon-"..tostring(id) end
assert(io.open(ADDON_ROOT .. "/UI.lua"), "UI.lua absent : fenêtre non implémentée")
dofile(ADDON_ROOT .. "/UI.lua")
A.native=false; A.open=true; A.pending=nil; A.running=false
A:RefreshRecipes()
A:CreateUI()
A:Render()
assert(A.frame and A.recipeRows[1].data.header, "fenêtre et catégories")
A.recipeRows[1].scripts.OnClick(A.recipeRows[1])
assert(A.options.collapsed.Potions, "catégorie repliable")
A.recipeRows[1].scripts.OnClick(A.recipeRows[1])
local knownRow
for _,row in ipairs(A.recipeRows) do if row.data and row.data.known then knownRow=row; break end end
assert(knownRow)
knownRow.scripts.OnClick(knownRow)
assert(A.selectedKey and A.craftButton.enabled and A.addButton.enabled)
assert(A.search.surface and A.search.font and A.search.insets[1]>=4, "champs complets avec police et marges explicites")
assert(A.queueRows[1].quantity:GetWidth()>=48, "quatre chiffres et marges tiennent dans le champ de file")
assert(A.resultIcon.icon.texture=="item-icon-501", "icône de l'objet produit sélectionné")
assert(A.reagentScroll.text:GetText():find("|Ticon:",1,true), "icône de chaque ingrédient")
assert(A.reagentScroll.text.point[3] <= -8, "marge supérieure : la première icône de 20 px n'est pas coupée")
A.reagentScroll:SetVerticalScroll(40)
A:RenderDetails()
assert(A.reagentScroll:GetVerticalScroll()==40, "rafraîchissement identique : défilement conservé")
A.quantity:SetText("2"); A:RenderDetails()
assert(A.reagentScroll:GetVerticalScroll()==0, "composants modifiés : première ligne à nouveau visible")
assert(knownRow.text:GetText():find("|Titem-icon-501:",1,true), "résultat visible dans la liste des recettes")
A.quantity:SetText("2")
local before=A.queue[1].count
A.addButton.scripts.OnClick()
assert(A.queue[1].count == before+2, "ajout depuis l'interface")
local field=A.queueRows[1].quantity
field:SetFocus(); field:SetText("12"); A:Render()
assert(field:GetText()=="12", "actualisation des sacs préserve la quantité en cours de saisie")
field:ClearFocus()
assert(A.queue[1].count==12, "quantité saisie validée sur la bonne entrée")
A.selectedKey="s103"; A:Render()
assert(not A.craftButton.enabled and not A.addButton.enabled, "inconnue : actions désactivées")
A.options.search="rien ne correspond"; A:Render()
assert(not A.recipeRows[1]:IsShown(), "recherche sans résultat")
assert(A.frame.resizable and A.resizeGrip, "fenêtre redimensionnable avec poignée")
local savedRecipes,savedByKey,savedQueue=A.recipes,A.byKey,A.queue
A.recipes,A.byKey,A.queue={},{},{}
for i=1,60 do
    local r={key="resize"..i,name="Recette "..i,category="Potions",known=true,difficulty="easy",order=i,available=1,icon="icon",reagents={}}
    A.recipes[i]=r; A.byKey[r.key]=r
    if i<=35 then A.queue[i]={key=r.key,name=r.name,count=1} end
end
A.options.search=""; A.selectedKey="resize1"
A.recipeOffset=39; A.queueOffset=28; A:Render()
assert(A.recipeRows[17]:IsShown() and not A.recipeRows[18]:IsShown(), "pool de recettes limité à la hauteur initiale")
assert(A.queueRows[14]:IsShown() and not A.queueRows[15]:IsShown(), "pool de file limité à la hauteur initiale")
local scale=A.frame:GetScale()
A.frame:SetWidth(1400); A.frame:SetHeight(1000)
A.frame.scripts.OnSizeChanged(A.frame,1400,1000)
assert(A.recipeVisibleRows>17 and A.queueVisibleRows>14, "agrandir montre davantage de recettes et d'entrées de file")
assert(A.recipeRows[28]:IsShown() and A.recipeRows[28].data.key=="resize60", "recettes supplémentaires affichées et défilement recalé sur la dernière recette")
assert(A.queueRows[25]:IsShown() and A.queueRows[25].entry.key=="resize35", "file supplémentaire affichée et défilement recalé")
assert(A.search:GetWidth()>326 and A.detailPanel:GetWidth()>524, "colonnes et champs suivent la largeur")
assert(A.reagentScroll.text:GetWidth()==A.recipePage:GetWidth()-30, "largeur du contenu défilant recalculée après agrandissement")
assert(A.frame:GetScale()==scale, "redimensionner ne grossit pas le texte")
A.resizeGrip.scripts.OnMouseDown(A.resizeGrip,"LeftButton")
assert(A.frame.sizing=="BOTTOMRIGHT")
A.resizeGrip.scripts.OnMouseUp(A.resizeGrip,"LeftButton")
assert(not A.frame.sizing and A.db.size.width==1400 and A.db.size.height==1000, "taille mémorisée après glissement")
A.frame:SetWidth(980); A.frame:SetHeight(740)
A.frame.scripts.OnSizeChanged(A.frame,980,740)
assert(A.recipeVisibleRows==17 and A.queueVisibleRows==14, "retour à la taille minimum sans débordement des listes")
assert(not A.recipeRows[18]:IsShown() and not A.queueRows[15]:IsShown(), "lignes excédentaires masquées après réduction")
A.recipes,A.byKey,A.queue=savedRecipes,savedByKey,savedQueue
A.selectedKey=nil; A.recipeOffset=0; A.queueOffset=0; A:Render()
print("PASS: fenêtre, catégories repliables, sélection, ajout, inconnues, recherche vide")
