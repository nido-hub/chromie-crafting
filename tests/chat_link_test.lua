-- Catch wrong links (item/index instead of recipe), lost selection, and header clicks.
local A=ChromieCrafting
local oldShift,oldInsert=IsShiftKeyDown,ChatEdit_InsertLink
local shift,inserted=false,nil
function IsShiftKeyDown() return shift end
function ChatEdit_InsertLink(link) inserted=link; return true end
local row=A.recipeRows[1]
local data,selected=row.data,A.selectedKey
row.data={key='chat-test',name='Recette',recipeLink='|cffffd000|Henchant:101|h[Recette]|h|r',itemLink='item:501'}
shift=true
row.scripts.OnClick(row,'LeftButton')
assert(inserted=='|cffffd000|Henchant:101|h[Recette]|h|r', 'Maj-clic insère le lien de recette, pas le résultat')
assert(A.selectedKey==selected, 'partager ne change pas la sélection')
inserted=nil; row.data={key='saved',name='Mémorisée',spellID=102}
local oldSpellLink=GetSpellLink
function GetSpellLink(id) assert(id==102); return 'spell:102' end
row.scripts.OnClick(row,'LeftButton')
assert(inserted=='spell:102', 'ancienne recette mémorisée sans recipeLink : lien de sort')
GetSpellLink=oldSpellLink
inserted=nil; row.data={key='no-link',name='Sans lien'}
row.scripts.OnClick(row,'LeftButton')
assert(not inserted, 'aucun lien inventé pour une recette sans identifiant')
row.data={header=true,category='Chat',count=1}
local collapsed=A.options.collapsed.Chat
row.scripts.OnClick(row,'LeftButton')
assert(not inserted and A.options.collapsed.Chat~=collapsed, 'Maj-clic sur une catégorie conserve le repli')
A.options.collapsed.Chat=collapsed
shift=false; row.data=data
local originalCollapsed=data.header and A.options.collapsed[data.category]
row.scripts.OnClick(row,'LeftButton')
assert(not inserted, 'clic normal : aucun partage')
if data.header then A.options.collapsed[data.category]=originalCollapsed end
A.selectedKey=selected
IsShiftKeyDown,ChatEdit_InsertLink=oldShift,oldInsert
print('PASS: Maj-clic partage recette et sort mémorisé ; catégories et clic normal préservés')
