-- Prefab: reusable component bundles for entities.
--
-- A prefab is a named component definition that can inherit from another
-- prefab through `parent`. Spawning a prefab flattens its ancestor chain into
-- a single component table, so prefabs themselves never exist in the ECS.

Prefab = {}
Prefab.__index = Prefab
Prefab.registry = {}
Prefab.remove = setmetatable({}, {
    __tostring = function()
        return "Prefab.remove"
    end,
})

setmetatable(Prefab, {
    __call = function(_, name, parent, definition)
        return Prefab.new(name, parent, definition)
    end,
})

local function isArray(value)
    if type(value) ~= "table" then
        return false
    end
    if #value == 0 then
        return false
    end
    for key in pairs(value) do
        if type(key) ~= "number" then
            return false
        end
    end
    return true
end

-- Merges src into dst. Nested maps merge field by field, while arrays and
-- scalar values replace the inherited value entirely.
local function merge(dst, src)
    for key, value in pairs(src) do
        if value == Prefab.remove then
            dst[key] = nil
        elseif
            type(value) == "table"
            and type(dst[key]) == "table"
            and not isArray(value)
        then
            merge(dst[key], value)
        else
            dst[key] = table.deepcopy(value)
        end
    end
end

-- Creates and registers a prefab.
--
-- definition.components holds static component data.
-- definition.generate(ctx) may return per-spawn component data, evaluated
-- after the static data of the same level and sharing ctx across the chain.
-- definition.on_spawn(entity, ctx) runs after all components are applied.
-- definition.abstract prevents spawning this prefab directly.
function Prefab.new(name, parent, definition)
    if type(name) ~= "string" or name == "" then
        error("Prefab name must be a non-empty string")
    end

    if type(parent) == "string" then
        local resolved = Prefab.registry[parent]
        if not resolved then
            error(("Unknown parent prefab '%s' for '%s'"):format(parent, name))
        end
        parent = resolved
    end
    if parent ~= nil and getmetatable(parent) ~= Prefab then
        error(("Invalid parent for prefab '%s'"):format(name))
    end

    definition = definition or {}
    local prefab = setmetatable({
        name = name,
        parent = parent,
        components = definition.components or {},
        generate = definition.generate,
        on_spawn = definition.on_spawn,
        abstract = definition.abstract or false,
    }, Prefab)

    Prefab.registry[name] = prefab
    return prefab
end

function Prefab:getChain()
    local chain = {}
    local current = self
    while current do
        table.insert(chain, 1, current)
        current = current.parent
    end
    return chain
end

function Prefab:isA(other)
    local other_name = other
    if getmetatable(other) == Prefab then
        other_name = other.name
    end

    local current = self
    while current do
        if current.name == other_name then
            return true
        end
        current = current.parent
    end
    return false
end

function Prefab:spawn(overrides)
    if self.abstract then
        error(
            ("Prefab '%s' is abstract and cannot be spawned"):format(self.name)
        )
    end

    local chain = self:getChain()
    local context = {}
    local components = {}

    for _, level in ipairs(chain) do
        merge(components, level.components)
        if level.generate then
            local generated = level.generate(context)
            if generated then
                merge(components, generated)
            end
        end
    end
    if overrides then
        merge(components, overrides)
    end

    local entity = createEntity()
    entity.components = components
    entity.components.prefab = { name = self.name }

    for _, level in ipairs(chain) do
        if level.on_spawn then
            level.on_spawn(entity, context)
        end
    end

    return entity
end

--- Returns the component data defined by a ModelData entry.
--- Use this from a prefab's generate() function to apply a 3D model and its
--- collider details at spawn time.
--- @tparam string model_name ModelData name.
--- @treturn table Component data.
function prefabModelComponents(model_name)
    local components = {}
    for key, value in pairs(__model_data[model_name]) do
        if string.sub(key, 1, 2) ~= "__" then
            components[key] = table.deepcopy(value)
        end
    end
    return components
end

--- Spawns a registered prefab by name.
--- Example: entity = spawnPrefab("Asteroid")
--- @type global
--- @tparam string name Prefab name.
--- @tparam table overrides Optional component overrides.
--- @treturn entity The spawned entity.
function spawnPrefab(name, overrides)
    local prefab = Prefab.registry[name]
    if not prefab then
        error(("Unknown prefab '%s'"):format(tostring(name)))
    end
    return prefab:spawn(overrides)
end

local Entity = getLuaEntityFunctionTable()

--- Returns the name of the prefab this entity was spawned from.
--- Returns nil when the entity was not created from a prefab.
--- Example: name = entity:getPrefabName() -- "Asteroid"
--- @treturn string|nil The prefab name.
function Entity:getPrefabName()
    local prefab = self.components.prefab
    if prefab then
        return prefab.name
    end
    return nil
end

--- Returns whether this entity was spawned from the given prefab or one of
--- its descendants.
--- Example: entity:isPrefab("SpaceObject")
--- @tparam string name Prefab name.
--- @treturn boolean True when the entity is an instance of the prefab.
function Entity:isPrefab(name)
    local prefab_name = self:getPrefabName()
    if prefab_name == nil then
        return false
    end

    local prefab = Prefab.registry[prefab_name]
    if prefab then
        return prefab:isA(name)
    end
    return prefab_name == name
end
