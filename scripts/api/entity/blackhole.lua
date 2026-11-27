local function defaultWormHoleTeleport(target_coordinates, is_single_use, entity)
    -- A target of {0,0} means this wormhole has no destination yet.
    if target_coordinates == nil then
        return
    end
    if target_coordinates[1] == 0 and target_coordinates[2] == 0 then
        return
    end
    if entity == nil or not entity:isValid() then
        return
    end
    entity:setPosition(target_coordinates[1], target_coordinates[2])
end

local function wormHoleSingularity(self, entity)
    self:teleport(entity)
end

local blackHolePrefab = Prefab("BlackHole", SpaceObjectPrefab, {
    components = {
        never_radar_blocked = {},
        gravity = { range = 5000, damage = true },
        avoid_object = { range = 7000 },
        radar_signature = { gravitational = 0.9 },
        radar_trace = {
            icon = "radar/blackHole.png",
            min_size = 0,
            max_size = 2048,
            radius = 5000,
        },
        billboard_render = { texture = "blackHole3d.png", size = 5000 },
    },
})

local wormHolePrefab = Prefab("WormHole", SpaceObjectPrefab, {
    components = {
        never_radar_blocked = {},
        gravity = { range = 2500, damage = false, on_singularity = wormHoleSingularity },
        teleporter = {
            target_coordinates = { 0, 0 },
            on_teleportation = defaultWormHoleTeleport,
            teleport_on_collision = false,
            is_single_use = false,
        },
        avoid_object = { range = 2500 * 1.2 },
        radar_signature = { gravitational = 0.9 },
        radar_trace = {
            icon = "radar/wormHole.png",
            min_size = 0,
            max_size = 2048,
            radius = 2500,
        },
        billboard_render = { texture = "wormHole3d.png", size = 5000 },
    },
})

--- A BlackHole is a piece of space terrain that pulls all nearby entities within a 5U radius, including otherwise immobile entities like stations, toward its center.
--- An entity capable of taking damage is dealt an increasing amount of damage as it approaches the BlackHole's center.
--- Upon reaching the center, any entity is instantly destroyed even if it's otherwise incapable of taking damage.
--- AI behaviors avoid BlackHoles by a 2U margin.
--- In 3D space, a BlackHole resembles a black sphere with blue horizon.
--- Example: black_hole = BlackHole():setPosition(1000,2000)
--- @type creation
function BlackHole()
    return blackHolePrefab:spawn()
end

--- A WormHole is a piece of space terrain that pulls all nearby entities within a 2.5U radius, including otherwise immobile entities like stations, toward its center.
--- Any entity that reaches its center is teleported to another point in space by its Teleporter component.
--- AI behaviors avoid WormHoles by a 0.5U margin.
--- Example: wormhole = WormHole():setPosition(1000,1000):setTargetPosition(10000,10000)
--- @type creation
function WormHole()
    return wormHolePrefab:spawn()
end

local Entity = getLuaEntityFunctionTable()
--- Sets the target teleportation coordinates for entities that pass through the center of this wormhole.
--- Avoid the default value of {0,0}, which should be treated as no destination.
--- Example: wormhole:setTargetPosition(10000,10000)
function Entity:setTargetPosition(x, y)
    if self.components.teleporter then
        self.components.teleporter.target_coordinates = { x, y }
    end
    return self
end
--- Returns the target teleportation coordinates for entities that pass through the center of this wormhole.
--- The default value of {0,0} should be treated as no destination.
--- Example: wormhole:getTargetPosition()
function Entity:getTargetPosition()
    if self.components.teleporter then
        return self.components.teleporter.target_coordinates
    end
    return nil
end
--- Defines a function to call when this WormHole teleports an entity.
--- Passes the WormHole object and the teleported entity.
--- Example:
--- -- Outputs teleportation details to the console window and logging file
--- wormhole:onTeleportation(function(this_wormhole,teleported_object) print(teleported_object:getCallSign() .. " teleported to " .. this_wormhole:getTargetPosition()) end)
function Entity:onTeleportation(callback)
    if self.components.teleporter then
        self.components.teleporter.on_teleportation = function(target_coordinates, is_single_use, teleported_object)
            defaultWormHoleTeleport(target_coordinates, is_single_use, teleported_object)
            if callback then
                callback(self, teleported_object)
            end
        end
    end
    return self
end
