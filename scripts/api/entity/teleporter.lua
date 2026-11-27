local function defaultTeleport(target_coordinates, is_single_use, entity)
    if entity == nil or not entity:isValid() then
        return
    end
    if target_coordinates == nil then
        return
    end
    if target_coordinates[1] == 0 and target_coordinates[2] == 0 then
        return
    end
    entity:setPosition(target_coordinates[1], target_coordinates[2])
end

local teleporterPrefab = Prefab("Teleporter", SpaceObjectPrefab, {
    components = {
        teleporter = {
            target_coordinates = { 0, 0 },
            on_teleportation = defaultTeleport,
            teleport_on_collision = true,
            is_single_use = false,
        },
        physics = { type = "sensor", size = 100 },
    },
})

--- A Teleporter moves entities to a target when they collide with it or when triggered by a script.
--- If it also has a Zone component, entities are teleported when they enter the zone instead of on Physics collision.
--- The default on_teleportation callback moves the entity to target_coordinates.
--- Example: teleporter = Teleporter():setPosition(1000,1000):setTeleporterTarget(5000,5000)
--- @type creation
function Teleporter()
    return teleporterPrefab:spawn()
end

local Entity = getLuaEntityFunctionTable()

--- Sets this Teleporter's destination coordinates.
--- Example: teleporter:setTeleporterTarget(10000,10000)
function Entity:setTeleporterTarget(x, y)
    if self.components.teleporter then
        self.components.teleporter.target_coordinates = { x, y }
    end
    return self
end

--- Returns this Teleporter's destination coordinates.
--- Example: x,y = teleporter:getTeleporterTarget()
function Entity:getTeleporterTarget()
    local teleporter = self.components.teleporter
    if teleporter and teleporter.target_coordinates then
        return teleporter.target_coordinates[1], teleporter.target_coordinates[2]
    end
    return nil
end

--- Sets whether this Teleporter triggers when another entity collides with it.
--- The Teleporter must have a Physics component for collision triggering.
--- If this entity also has a Zone component, this controls whether entering the zone triggers.
--- Example: teleporter:setTeleportOnCollision(false)
function Entity:setTeleportOnCollision(enabled)
    if self.components.teleporter then
        self.components.teleporter.teleport_on_collision = enabled
    end
    return self
end

--- Sets whether this Teleporter removes itself after triggering.
--- Example: teleporter:setTeleporterSingleUse(true)
function Entity:setTeleporterSingleUse(enabled)
    if self.components.teleporter then
        self.components.teleporter.is_single_use = enabled
    end
    return self
end

--- Sets this Teleporter's callback.
--- The callback receives target_coordinates, is_single_use, and the entity to teleport.
--- Example: teleporter:setTeleportCallback(function(target, single_use, entity) entity:setPosition(target[1], target[2]) end)
function Entity:setTeleportCallback(callback)
    if self.components.teleporter then
        self.components.teleporter.on_teleportation = callback
    end
    return self
end

--- Triggers this Teleporter's on_teleportation callback for the given entity.
--- Example: teleporter:teleport(ship)
function Entity:teleport(entity)
    local components = self.components
    local teleporter = components.teleporter
    if teleporter == nil then
        return self
    end

    local target_coordinates = teleporter.target_coordinates
    local is_single_use = teleporter.is_single_use
    if teleporter.on_teleportation then
        teleporter.on_teleportation(target_coordinates, is_single_use, entity)
    elseif entity and entity:isValid() and target_coordinates then
        entity:setPosition(target_coordinates[1], target_coordinates[2])
    end
    if is_single_use then
        components.teleporter = nil
    end
    return self
end
