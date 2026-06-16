
--- A Nebula is a piece of space terrain with a 5U radius that blocks long-range radar, but not short-range radar.
--- This hides any entities inside of a Nebula, as well as entities on the other side of its radar "shadow", from any ship outside of it.
--- Likewise, a ship fully inside of a nebula has effectively no long-range radar functionality.
--- In 3D space, a Nebula resembles a dense cloud of colorful gases.
--- Example: nebula = Nebula():setPosition(1000,2000)
--- @type creation
function Nebula()
    local radius = 5000.0
    local e = createEntity()
    e.components.radar_signature = {gravitational=0, electrical=0.8, thermal=-1.0}
    e.components.transform = {rotation=random(0, 360)}
    e.components.radar_trace = {icon="Nebula" .. irandom(1, 3) .. ".png", min_size=0, max_size = 2048, radius=radius*1.5}
    e.components.radar_block = {range=radius, behind=true}
    e.components.never_radar_blocked = {}
    local skybox_name = "purple"
    local fog_color_r = 0.08
    local fog_color_g = 0.03
    local fog_color_b = 0.10
    local render_info = {radius=radius, skybox=skybox_name, skybox_fade_distance=2000, fog_color_r=fog_color_r, fog_color_g=fog_color_g, fog_color_b=fog_color_b}
    local cloud_count = 900
    for n=1,cloud_count do
        local size = random(256, 2048)
        -- Density-weighted distribution: more clouds near the center, fewer at the edges
        local r = random(0, 1)
        local dist = math.sqrt(r) * (radius - size * 0.75)
        local angle = random(0, 360)
        local ox = math.cos(angle / 180 * math.pi) * dist
        local oy = math.sin(angle / 180 * math.pi) * dist
        render_info[n] = {size=size, texture="Nebula" .. irandom(1, 3) .. ".png", offset={ox, oy}}
    end
    e.components.nebula_renderer = render_info
    return e
end
