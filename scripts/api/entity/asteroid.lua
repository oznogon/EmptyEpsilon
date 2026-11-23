local visualAsteroidPrefab = Prefab("VisualAsteroid", SpaceObjectPrefab, {
    generate = function(ctx)
        ctx.size = random(110, 130)
        ctx.model = irandom(1, 10)
        local z = random(300, 800)
        if random(0, 100) < 50 then
            z = -z
        end

        return {
            transform = { rotation = random(0, 360) },
            radar_signature = { gravitational = 0.05 },
            mesh_render = {
                mesh = "Astroid_" .. ctx.model .. ".model",
                mesh_offset = { 0, 0, z },
                texture = "Astroid_" .. ctx.model .. "_d.png",
                specular_texture = "Astroid_" .. ctx.model .. "_s.png",
                normal_texture = "Astroid_" .. ctx.model .. "_n.png",
                scale = ctx.size,
            },
            spin = { rate = random(0.1, 0.8) },
        }
    end,
})

local asteroidPrefab = Prefab("Asteroid", visualAsteroidPrefab, {
    generate = function(ctx)
        return {
            -- Partial component override. Arrays replace the inherited value,
            -- so this keeps the parent's model and textures while moving the
            -- asteroid into the movement plane.
            mesh_render = {
                mesh_offset = { 0, 0, random(-50, 50) },
            },
            physics = {
                type = "Sensor",
                size = ctx.size,
            },
            radar_trace = {
                icon = "radar/blip.png",
                radius = ctx.size,
                min_size = 4.0,
                color = { 255, 200, 100, 255 },
                rotate = false,
            },
            avoid_object = { range = ctx.size * 2 },
            explode_on_touch = {
                damage_at_center = 35,
                damage_at_edge = 35,
                blast_range = ctx.size,
            },
            hull = {
                current = 1,
                max = 1,
            },
        }
    end,
})

--- An Asteroid is an inert piece of space terrain.
--- Upon colliding with another entity, it deals damage and is destroyed.
--- It has a default rotation speed, random z-offset, and model. AI-controlled entities attempt to avoid hitting them.
--- To create a customizable collidable object, use an Artifact or SupplyDrop.
--- For a purely decorative asteroid positioned outside of the movement plane, use a VisualAsteroid.
--- Example: asteroid = Asteroid():setSize(150):setPosition(1000,2000)
--- @type creation
function Asteroid(overrides)
    return asteroidPrefab:spawn(overrides)
end

--- A VisualAsteroid is a cosmetic asteroid rendered above or below the movement plane.
--- Unlike Asteroid, it has no collision, physics, or radar trace, and does not interact with other entities.
--- Use VisualAsteroids to add depth to asteroid fields without affecting gameplay.
--- Example: visual_asteroid = VisualAsteroid():setPosition(1000,2000)
--- @type creation
function VisualAsteroid(overrides)
    return visualAsteroidPrefab:spawn(overrides)
end
