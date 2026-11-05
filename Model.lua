ChromieCrafting = { Model = {} }
local M = ChromieCrafting.Model
local difficulty = { optimal = 1, medium = 2, easy = 3, trivial = 4, gray = 4 }

function M.Quantity(value)
    local n = tonumber(value)
    if n and n >= 1 and n <= 9999 and n == math.floor(n) then return n end
end

function M.Rows(recipes, options)
    options = options or {}
    local groups, order, rows = {}, {}, {}
    local search = string.lower(options.search or "")
    for _, r in ipairs(recipes) do
        local matches = string.find(string.lower(r.name .. " " .. r.category), search, 1, true)
        local state = options.state or "all"
        if matches and (state == "all" or (state == "known" and r.known) or (state == "unknown" and not r.known))
            and (not options.favoritesOnly or (options.favorites and options.favorites[r.key]))
            and (not options.craftable or (r.known and (r.planned or r.available or 0) > 0)) then
            if not groups[r.category] then groups[r.category] = {}; order[#order + 1] = r.category end
            local group = groups[r.category]
            group[#group + 1] = r
        end
    end
    for _, category in ipairs(order) do
        local group = groups[category]
        table.sort(group, function(a, b)
            if a.known ~= b.known then return a.known end
            if options.sort == "name" then
                if a.name ~= b.name then return a.name < b.name end
            elseif options.sort == "available" and (a.planned or a.available or 0) ~= (b.planned or b.available or 0) then
                return (a.planned or a.available or 0) > (b.planned or b.available or 0)
            else
                local da, db = difficulty[a.difficulty] or 5, difficulty[b.difficulty] or 5
                if da ~= db then return da < db end
                if a.known and a.order ~= b.order then return a.order < b.order end
                if not a.known and a.name ~= b.name then return a.name < b.name end
            end
            return a.key < b.key
        end)
        rows[#rows + 1] = { header = true, category = category, count = #group }
        if not (options.collapsed and options.collapsed[category]) then
            for _, r in ipairs(group) do rows[#rows + 1] = r end
        end
    end
    return rows
end

function M.Add(queue, recipe, count)
    count = M.Quantity(count)
    if not count or not recipe or not recipe.known then return false end
    for _, entry in ipairs(queue) do
        if entry.key == recipe.key then
            if not M.Quantity(entry.count + count) then return false end
            entry.count = entry.count + count
            return true
        end
    end
    queue[#queue + 1] = { key = recipe.key, name = recipe.name, count = count }
    return true
end

function M.Complete(queue, key)
    if not queue[1] or queue[1].key ~= key then return false end
    queue[1].count = queue[1].count - 1
    if queue[1].count <= 0 then table.remove(queue, 1) end
    return true
end

function M.Needs(queue, byKey, inventory)
    local items, result = {}, {}
    for _, entry in ipairs(queue) do
        local r = byKey[entry.key]
        for _, reagent in ipairs(r and r.reagents or {}) do
            local key = reagent.id or reagent.name
            if key then
                if not items[key] then
                    items[key] = { id = reagent.id, name = reagent.name or ("Objet " .. key), required = 0 }
                    result[#result + 1] = items[key]
                end
                items[key].required = items[key].required + reagent.count * entry.count
            end
        end
    end
    for _, item in ipairs(result) do
        item.owned = inventory(item.id or item.name) or 0
        item.missing = math.max(0, item.required - item.owned)
    end
    table.sort(result, function(a, b) return a.name < b.name end)
    return result
end
