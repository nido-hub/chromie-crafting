-- Exercise the installed AtlasLoot tables, not a rewritten miniature database.
local path = ADDON_ROOT .. "/../AtlasLoot_Crafting/crafting.lua"
local file = io.open(path)
if not file then print("SKIP: catalogue AtlasLoot non installé"); return end
file:close()
local locale = setmetatable({}, {__index=function(_, key) return key end})
function LibStub() return {GetLocale=function() return locale end} end
function AtlasLoot_GetLocaleLibBabble() return locale end
local professions = {
    {2259,"Alchimie"}, {2018,"Forge"}, {2550,"Cuisine"}, {7411,"Enchantement"},
    {4036,"Ingénierie"}, {3273,"Secourisme"}, {45357,"Calligraphie"},
    {25229,"Joaillerie"}, {2108,"Travail du cuir"}, {2656,"Fonte"}, {3908,"Couture"},
}
function GetSpellInfo(id)
    for _, p in ipairs(professions) do if id==p[1] then return p[2],"Apprenti","icon" end end
    return "Sort "..id,"Apprenti","icon"
end
AtlasLoot_Data = {}
dofile(path)
local total=0
for _, p in ipairs(professions) do
    local data=ChromieCrafting:ReadCatalog(p[2])
    local count=0
    for id,r in pairs(data) do
        count=count+1
        assert(r.key=="s"..id and r.name~="" and r.category~="" and not r.known)
        assert(not r.name:find("=q%d="), "qualité AtlasLoot non décodée")
    end
    assert(count > 10, "catalogue vide ou tronqué : " .. p[2])
    total=total+count
end
local alchemy=ChromieCrafting:ReadCatalog("Alchimie")
assert(alchemy[53838].category=="Potions" and alchemy[53838].source=="Trainer")
assert(ChromieCrafting:ReadCatalog("Couture")[56005].category=="Sacs")
assert(ChromieCrafting:ReadCatalog("Calligraphie")[56943].category:find("Glyphes"))
print("PASS: catalogue AtlasLoot réel, 11 métiers, "..total.." recettes")
