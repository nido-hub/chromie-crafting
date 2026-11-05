local A = ChromieCrafting
local professions = {
    {2259, "Alchemy"}, {2018, "Smithing", "Armorsmith", "Weaponsmith", "Axesmith", "Hammersmith", "Swordsmith"},
    {2550, "Cooking"}, {7411, "Enchanting"}, {4036, "Engineering", "Gnomish", "Goblin"},
    {3273, "FirstAid"}, {45357, "Inscription"}, {25229, "Jewel"},
    {2108, "Leather", "Dragonscale", "Elemental", "Tribal"}, {2656, "Mining"}, {2575, "Mining"}, {3908, "Tailoring"},
}
-- Longest prefixes first: do not mistake item enhancements for generic items.
local categories = {
    {"AlchemyBattleElixir", "Élixirs de bataille"}, {"AlchemyGuardianElixir", "Élixirs du gardien"},
    {"AlchemyPotion", "Potions"}, {"AlchemyFlask", "Flacons"}, {"AlchemyTransmute", "Transmutations"},
    {"SmithingArmor", "Armures"}, {"SmithingWeapon", "Armes"}, {"SmithingEnhancement", "Améliorations"},
    {"EnchantingBoots", "Bottes"}, {"EnchantingBracer", "Brassards"}, {"EnchantingChest", "Torse"},
    {"EnchantingCloak", "Capes"}, {"EnchantingGloves", "Gants"}, {"EnchantingRing", "Anneaux"},
    {"EnchantingShield", "Boucliers"}, {"Enchanting2HWeapon", "Armes à deux mains"},
    {"EnchantingWeapon", "Armes"}, {"EnchantingStaff", "Bâtonnets"},
    {"EngineeringAmmo", "Munitions"}, {"EngineeringArmor", "Armures"},
    {"EngineeringExplosives", "Explosifs"}, {"EngineeringItemEnhancements", "Améliorations"},
    {"EngineeringReagents", "Composants"}, {"EngineeringWeapon", "Armes"},
    {"Inscription_OffHand", "Objets tenus en main gauche"}, {"Inscription_Reagents", "Encres et composants"},
    {"Inscription_Scrolls", "Parchemins"},
    {"JewelRed", "Gemmes rouges"}, {"JewelBlue", "Gemmes bleues"}, {"JewelYellow", "Gemmes jaunes"},
    {"JewelGreen", "Gemmes vertes"}, {"JewelOrange", "Gemmes orange"}, {"JewelPurple", "Gemmes violettes"},
    {"JewelMeta", "Méta-gemmes"}, {"JewelPrismatic", "Gemmes prismatiques"}, {"JewelDragonsEye", "Œils de dragon"},
    {"JewelTrinket", "Bijoux"}, {"JewelRing", "Anneaux"}, {"JewelNeck", "Colliers"},
    {"LeatherLeatherArmor", "Armures en cuir"}, {"LeatherMailArmor", "Armures en mailles"},
    {"LeatherCloaks", "Capes"}, {"LeatherItemEnhancement", "Renforts"},
    {"LeatherQuiversPouches", "Carquois et gibernes"}, {"LeatherDrumsBagsMisc", "Tambours et sacs"},
    {"LeatherLeather", "Cuirs"}, {"TailoringArmor", "Armures en tissu"},
    {"TailoringBags", "Sacs"}, {"TailoringItemEnhancement", "Améliorations"},
    {"TailoringMisc", "Tissus et divers"}, {"Cooking", "Cuisine"}, {"FirstAid", "Bandages et soins"},
    {"Mining", "Fonte"}, {"Armorsmith", "Spécialisation armures"}, {"Weaponsmith", "Spécialisation armes"},
    {"Axesmith", "Spécialisation haches"}, {"Hammersmith", "Spécialisation masses"},
    {"Swordsmith", "Spécialisation épées"}, {"Gnomish", "Ingénierie gnome"}, {"Goblin", "Ingénierie gobeline"},
    {"Dragonscale", "Écailles de dragon"}, {"Elemental", "Travail élémentaire"}, {"Tribal", "Travail tribal"},
}
local glyphClasses = {
    DeathKnight = "Chevalier de la mort", Druid = "Druide", Hunter = "Chasseur", Mage = "Mage",
    Paladin = "Paladin", Priest = "Prêtre", Rogue = "Voleur", Shaman = "Chaman", Warlock = "Démoniste", Warrior = "Guerrier",
}

function A:CleanText(text)
    return (tostring(text or ""):gsub("=q%d=", ""):gsub("=ds=", ""):gsub("=ec%d=", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local function categoryFor(key)
    for _, entry in ipairs(categories) do
        if key:sub(1, #entry[1]) == entry[1] then return entry[2] end
    end
    local class, size = key:match("^Inscription_(%a+)(Major)%d")
    if not class then class, size = key:match("^Inscription_(%a+)(Minor)%d") end
    if class then return "Glyphes — " .. (glyphClasses[class] or class) .. (size == "Major" and " (majeurs)" or " (mineurs)") end
    return "Divers"
end

function A:ReadCatalog(profession)
    if not self.catalogLoaded then
        self.catalogLoaded = LoadAddOn("AtlasLoot_Crafting") and true or false
    end
    local prefixes
    for _, entry in ipairs(professions) do
        if GetSpellInfo(entry[1]) == profession then prefixes = entry; break end
    end
    local result = {}
    if not prefixes or not AtlasLoot_Data then return result end
    local keys = {}
    for key, data in pairs(AtlasLoot_Data) do
        if type(key) == "string" and type(data) == "table" then
            for i = 2, #prefixes do
                if key:sub(1, #prefixes[i]) == prefixes[i] then keys[#keys + 1] = key; break end
            end
        end
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
        for _, entry in ipairs(AtlasLoot_Data[key]) do
            local spellID = type(entry[2]) == "string" and tonumber(entry[2]:match("^s(%d+)$"))
            if spellID then
                local source = self:CleanText(entry[5])
                if not result[spellID] then
                    local name, _, icon = GetSpellInfo(spellID)
                    result[spellID] = {
                        key = "s" .. spellID, spellID = spellID, itemID = tonumber(entry[3]),
                        name = name or self:CleanText(entry[4]), icon = icon,
                        category = categoryFor(key), source = source,
                        known = false, available = 0,
                    }
                elseif source ~= "" and not string.find(result[spellID].source, source, 1, true) then
                    result[spellID].source = result[spellID].source .. " / " .. source
                end
            end
        end
    end
    return result
end
