-- Parameterized grid traversal for scenario station layouts, used in
-- Carrier and Fighters, Allies and Enemies, Escape, Defender Hunter,
-- Borderline Fever, and Capture the Flag.

local M = {}

function M.new(config)
    config = config or {}
    local min = config.min or 1
    local max = config.max or 500
    local grid = config.grid or {}
    local api = {}

    local function traverse(lx, ly, skip, mode, value)
        if grid[lx] == nil then
            grid[lx] = {}
        end
        local visited = {}
        for x = min, max do
            visited[x] = {}
        end
        local output = {}
        visited[lx][ly] = true

        local visit
        local walk

        visit = function(x, y, direction)
            if grid[x] == nil then
                grid[x] = {}
            end
            if visited[x][y] then
                return
            end
            visited[x][y] = true
            local occupant = grid[x][y]
            if occupant == nil then
                table.insert(output, { x, y })
                return
            end
            local recurse = mode == "all"
                or (mode == "current" and occupant == value)
                or (mode == "faction" and occupant >= value)
            if recurse then
                walk(x, y, direction)
            end
        end

        walk = function(x, y, opposite)
            if opposite ~= 3 and x - 1 >= min then
                visit(x - 1, y, 1)
            end
            if opposite ~= 4 and y - 1 >= min then
                visit(x, y - 1, 2)
            end
            if opposite ~= 1 and x + 1 <= max then
                visit(x + 1, y, 3)
            end
            if opposite ~= 2 and y + 1 <= max then
                visit(x, y + 1, 4)
            end
        end

        walk(lx, ly, skip or 0)
        return output
    end

    function api:all(x, y)
        return traverse(x, y, 0, "all")
    end

    function api:current(x, y, group)
        return traverse(x, y, 0, "current", group)
    end

    function api:faction(x, y, first_faction_position)
        return traverse(x, y, 0, "faction", first_faction_position)
    end

    function api:setGrid(value)
        grid = value
    end

    return api
end

return M
