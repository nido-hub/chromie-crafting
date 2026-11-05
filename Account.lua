local A = ChromieCrafting

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

function A:InitializeAccount()
    ChromieCraftingAccountDB = ChromieCraftingAccountDB or {characters = {}}
    self.account = ChromieCraftingAccountDB
    self.account.characters = self.account.characters or {}
    local name = UnitName and UnitName("player") or "Personnage"
    self.realm = GetRealmName and GetRealmName() or "Royaume"
    self.characterKey = self.realm .. "." .. (name or "Personnage")
    self.account.characters[self.characterKey] = self.account.characters[self.characterKey] or {name=name, realm=self.realm, professions={}, bags={}, bank={}}
    self.character = self.account.characters[self.characterKey]
    for profession, saved in pairs(self.character.professions) do
        if self.db.queues[profession] then saved.queue = self.db.queues[profession] end
    end
    self.db.favorites = self.db.favorites or {}
end

local function scan(bags)
    local items = {}
    for _, bag in ipairs(bags) do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            local id = link and tonumber(link:match("item:(%d+)"))
            local _, count = GetContainerItemInfo(bag, slot)
            if id then items[id] = (items[id] or 0) + (count or 0) end
        end
    end
    return items
end

function A:SaveInventory()
    if not self.account then self:InitializeAccount() end
    if not GetContainerNumSlots then return end
    self.character.bags = scan({0,1,2,3,4})
    self.character.bagsUpdated = time()
    if self.bankOpen then
        self.character.bank = scan({-1,5,6,7,8,9,10,11})
        self.character.bankUpdated = time()
    end
end

function A:SaveProfession()
    if not self.account then self:InitializeAccount() end
    if self.viewing or (IsTradeSkillLinked and IsTradeSkillLinked()) or not self.profession then return end
    local recipes = copy(self.recipes)
    for _, recipe in ipairs(recipes) do
        recipe.index, recipe.available, recipe.cooldown = nil, nil, nil
    end
    self.character.professions[self.profession] = {recipes=recipes, rank=self.rank, maxRank=self.maxRank, updated=time and time() or 0, queue=self.queue}
    self.liveProfession = self.profession
end

function A:InventoryParts(id)
    local bags = GetItemCount(id, false) or 0
    local bank = math.max(0, (GetItemCount(id, true) or 0) - bags)
    local others = 0
    if self.db.includeAlts and type(id) == "number" then
        for key, character in pairs(self.account and self.account.characters or {}) do
            if key ~= self.characterKey and character.realm == self.realm then
                others = others + (character.bags[id] or 0)
                if self.db.includeBank then others = others + (character.bank[id] or 0) end
            end
        end
    end
    return bags, self.db.includeBank and bank or 0, others
end

function A:InventoryCount(id)
    local bags, bank, others = self:InventoryParts(id)
    return bags + bank + others
end

function A:PlannedCount(recipe)
    if not recipe.known then return 0 end
    local count
    for _, reagent in ipairs(recipe.reagents or {}) do
        if reagent.count > 0 then
            local available = math.floor(self:InventoryCount(reagent.id or reagent.name) / reagent.count)
            count = count and math.min(count, available) or available
        end
    end
    return count or (self.viewing and 0 or recipe.available or 0)
end

function A:IsFavorite(key)
    return self.db.favorites and self.db.favorites[self.profession] and self.db.favorites[self.profession][key]
end

function A:ToggleFavorite(key)
    if not key or not self.profession then return end
    self.db.favorites[self.profession] = self.db.favorites[self.profession] or {}
    local favorites = self.db.favorites[self.profession]
    favorites[key] = not favorites[key] or nil
    if self.Render then self:Render() end
end

function A:SelectCharacter(key, profession)
    if self.running or self.pending or self.withdrawal or InCombatLockdown() then return end
    self.viewing, self.viewedCharacter = true, key
    self.profession, self.selectedKey = profession, nil
    local character = self.account.characters[key]
    local saved = character and character.professions[profession]
    self.recipes, self.byKey = copy(saved and saved.recipes or {}), {}
    for _, recipe in ipairs(self.recipes) do self.byKey[recipe.key] = recipe end
    self.rank, self.maxRank = saved and saved.rank or 0, saved and saved.maxRank or 0
    if key == self.characterKey then
        self.db.queues[profession] = self.db.queues[profession] or {}
        self.queue = self.db.queues[profession]
    else
        self.queue = saved and saved.queue or {}
    end
    self.options.collapsed, self.recipeOffset, self.queueOffset = {}, 0, 0
    self.status = "Consultation mémorisée : ouvre ce métier sur ce personnage pour actualiser ses recettes."
    if self.Render then self:Render() end
end
