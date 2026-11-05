local path = ADDON_ROOT .. "/Model.lua"
local file = io.open(path)
assert(file, "Model.lua absent : modèle de métiers non implémenté")
file:close()
dofile(path)
local M = ChromieCrafting.Model
local recipes = {
    { key = "s1", name = "Potion faible", category = "Potions", difficulty = "gray", order = 1, known = true, available = 4, reagents = {{id = 10, name = "Herbe", count = 2}} },
    { key = "s2", name = "Flacon puissant", category = "Flacons", difficulty = "optimal", order = 2, known = true, available = 1, reagents = {{id = 10, name = "Herbe", count = 3}, {id = 11, name = "Fiole", count = 1}} },
    { key = "s3", name = "Potion forte", category = "Potions", difficulty = "medium", order = 3, known = true, available = 0, reagents = {} },
    { key = "s4", name = "Potion inconnue", category = "Potions", known = false, order = 4 },
}
local rows = M.Rows(recipes, {state = "all", sort = "skill"})
assert(rows[1].header and rows[1].category == "Potions", "ordre des catégories conservé")
assert(rows[2].key == "s3" and rows[3].key == "s1" and rows[4].key == "s4", "compétence dans chaque catégorie, inconnues après")
rows = M.Rows(recipes, {state = "unknown", search = "INCONNUE"})
assert(#rows == 2 and rows[2].key == "s4", "recherche et filtre inconnues")
rows = M.Rows(recipes, {craftable = true})
assert(#rows == 4, "uniquement les deux recettes fabricables et leurs groupes")
rows = M.Rows(recipes, {collapsed = {Potions = true}})
assert(#rows == 3 and rows[2].category == "Flacons", "repli de catégorie")
assert(M.Quantity("0") == nil and M.Quantity("-3") == nil and M.Quantity("abc") == nil)
assert(M.Quantity("2.5") == nil and M.Quantity("inf") == nil and M.Quantity("10000") == nil)
assert(M.Quantity("12") == 12)
local q = {}
assert(M.Add(q, recipes[1], 2))
assert(M.Add(q, recipes[1], 1) and #q == 1 and q[1].count == 3, "fusion des doublons")
assert(not M.Add(q, recipes[4], 1), "inconnue jamais fabricable")
assert(not M.Add(q, recipes[2], 0) and #q == 1)
M.Add(q, recipes[2], 2)
local byKey = {}; for _, r in ipairs(recipes) do byKey[r.key] = r end
local needs = M.Needs(q, byKey, function(id) return id == 10 and 7 or 0 end)
assert(#needs == 2 and needs[2].id == 10 and needs[2].required == 12 and needs[2].missing == 5, "besoins cumulés sans double compter les sacs")
assert(needs[1].id == 11 and needs[1].required == 2 and needs[1].missing == 2)
assert(not M.Complete(q, "s9") and q[1].count == 3, "autre sort sans effet")
assert(M.Complete(q, "s1") and q[1].count == 2)
M.Complete(q, "s1"); M.Complete(q, "s1")
assert(#q == 1 and q[1].key == "s2" and q[1].count == 2, "retire seulement après succès confirmé")
print("PASS: catégories, filtres, quantités, file, besoins, succès")
