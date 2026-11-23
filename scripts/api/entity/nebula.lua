local nebulaPrefab = Prefab("Nebula", SpaceObjectPrefab, {
    components = {
        radar_signature = {
            gravitational = 0.0,
            electrical = 0.8,
            thermal = -1.0,
        },
        radar_trace = {
            min_size = 0,
            max_size = 2048,
            radius = 5000.0 * 1.5,
            color = { 255, 255, 255, 128 },
        },
        radar_block = {
            range = 5000.0,
            behind = true,
        },
        never_radar_blocked = {},
        nebula_renderer = {
            radius = 5000.0,
            skybox = "purple",
            skybox_fade_distance = 2000,
            fog_color = { 0.08, 0.03, 0.10 },
            cloud_density = 1.0,
            visibility_distance = 5000.0,
        },
    },
    generate = function(ctx)
        return {
            transform = { rotation = random(0, 360) },
            radar_trace = { icon = "Nebula" .. irandom(1, 3) .. ".png" },
            nebula_renderer = { seed = irandom(1, 2147483647) },
        }
    end,
})

--- A Nebula is a piece of space terrain with a 5U radius that blocks long-range radar, but not short-range radar.
--- This hides any entities inside of a Nebula, as well as entities on the other side of its radar "shadow", from any ship outside of it.
--- Likewise, a ship fully inside of a nebula has effectively no long-range radar functionality.
--- In 3D space, a Nebula resembles a dense cloud of colorful gases.
--- Cloud positions and textures are generated deterministically from a randomization seed,
--- replicated across the network as just the seed, and generated locally on each client.
--- Explicit cloud overrides (via script or GM Tweaks) replicate the full cloud data instead.
--- Example: nebula = Nebula():setPosition(1000,2000)
--- @type creation
function Nebula()
    return nebulaPrefab:spawn()
end
