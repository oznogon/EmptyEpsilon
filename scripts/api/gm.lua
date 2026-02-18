function getSpawnableGMObjects()
    local result = {}
    result[#result+1] = {function() return Artifact() end, _("create", "Artifact"), _("create", "Various"), "", "radar/blip.png"}
    result[#result+1] = {function() return WarpJammer() end, _("create", "Warp jammer"), _("create", "Various"), "", "radar/blip.png"}
    result[#result+1] = {function() return Mine() end, _("create", "Mine"), _("create", "Various"), "", "radar/blip.png"}
    result[#result+1] = {function() return SupplyDrop():setEnergy(500):setWeaponStorage('Nuke', 1):setWeaponStorage('Homing', 4):setWeaponStorage('Mine', 2):setWeaponStorage('EMP', 1) end, _("create", "Supply drop"), _("create", "Various"), "", "radar/blip.png"}
    result[#result+1] = {function() return ScanProbe() end, _("create", "Scan probe"), _("create", "Various"), "", "radar/probe.png"}
    result[#result+1] = {function() return Asteroid() end, _("create", "Asteroid"), _("create", "Various"), "", "radar/blip.png"}
    result[#result+1] = {function() return VisualAsteroid() end, _("create", "Visual asteroid"), _("create", "Various"), "", "radar/blip.png"}
    result[#result+1] = {function() return Planet() end, _("create", "Planet"), _("create", "Various"), "", "radar/blip.png"}
    result[#result+1] = {function() return BlackHole() end, _("create", "Black hole"), _("create", "Various"), "", "radar/blackHole.png"}
    result[#result+1] = {function() return Nebula() end, _("create", "Nebula"), _("create", "Various"), "", "Nebula1.png"}
    result[#result+1] = {function() return WormHole() end, _("create", "Worm hole"), _("create", "Various"), "", "radar/wormHole.png"}
    result[#result+1] = {function()
        local cam = createEntity()
        cam.components.transform = {}
        cam:setRotation(-90) -- Default yaw
        cam.components.cinematic_camera = {
            name = "Camera",
            pitch = 30,
            z_position = 200,
            field_of_view = 60
        }
        return cam
    end, _("create", "Camera"), _("create", "Various"), _("create", "Cinematic camera viewpoint"), "radar/blip.png"}

    for k, v in pairs(__ship_templates) do
        if not v.__hidden then
            if v.__type == "playership" then
                result[#result+1] = {__spawnPlayerShipFunc(v.typename.type_name), v.typename.localized, _("create", "Player ship"), v.__description, v.radar_trace.icon}
            elseif v.__type == "station" then
                result[#result+1] = {__spawnStationFunc(v.typename.type_name), v.typename.localized, _("create", "Station"), v.__description, v.radar_trace.icon}
            else
                result[#result+1] = {__spawnCpuShipFunc(v.typename.type_name), v.typename.localized, _("create", "CPU ship"), v.__description, v.radar_trace.icon}
            end
        end
    end

    return result
end

function __spawnStationFunc(key)
    return function() return SpaceStation():setTemplate(key):setRotation(random(0, 360)) end
end
function __spawnCpuShipFunc(key)
    return function() return CpuShip():setTemplate(key):setRotation(random(0, 360)):orderRoaming() end
end

function getEntityExportString(entity)
    if entity.components.player_control and entity.components.typename then
        -- Likely a player ship
        for k, v in pairs(__ship_templates) do
            if v.__type == "playership" and v.typename.type_name == entity.components.typename.type_name then
                return "PlayerSpaceship():setTemplate('" .. k .. "')" .. __exportShipChanges(entity, v)
            end
        end
    end
    if entity.components.ai_controller and entity.components.typename then
        -- Likely a CPU ship
        for k, v in pairs(__ship_templates) do
            if (v.__type == "ship" or v.__type == nil) and v.typename.type_name == entity.components.typename.type_name then
                return "CpuShip():setTemplate('" .. k .. "')" .. __exportShipChanges(entity, v)
            end
        end
    end
    if entity.components.typename and entity.components.physics and entity.components.physics.type == "static" then
        -- Likely a station
        for k, v in pairs(__ship_templates) do
            if v.__type == "station" and v.typename.type_name == entity.components.typename.type_name then
                return "SpaceStation():setTemplate('" .. k .. "')" .. __exportShipChanges(entity, v)
            end
        end
    end
    if entity.components.explode_on_touch and entity.components.physics and entity.components.physics.type == "sensor" then
        -- Likely an asteroid
        return "Asteroid()" .. __exportBasics(entity)
    end
    if entity.components.delayed_explode_on_touch and entity.components.physics and entity.components.physics.type == "sensor" then
        -- Likely an Mine
        return "Mine()" .. __exportBasics(entity)
    end
    if entity.components.radar_block and entity.components.nebula_renderer then
        -- Likely an Nebula
        return "Nebula()" .. __exportBasics(entity)
    end
    if entity.components.cinematic_camera then
        -- Camera entity
        local x, y = entity:getPosition()
        local yaw = entity:getRotation()
        local cam = entity.components.cinematic_camera
        return string.format([[local cam = createEntity()
cam.components.transform = {}
cam:setPosition(%.0f, %.0f)
cam:setRotation(%.1f)
cam.components.cinematic_camera = {
    name = "%s",
    pitch = %.1f,
    z_position = %.1f,
    field_of_view = %.1f
}]], x, y, yaw, cam.name, cam.pitch, cam.z_position, cam.field_of_view)
    end
    return ""
end

function __exportBasics(entity)
    local x, y = entity:getPosition()
    local extras = string.format(":setPosition(%.0f, %.0f)", x, y)
    local rotation = entity:getRotation()
    if rotation ~= 0 then
        extras = extras .. string.format(":setRotation(%.0f)", rotation)
    end
    local faction = entity:getFaction()
    if faction ~= nil and faction ~= "" then
        extras = extras .. ":setFaction('" .. faction .. "')"
    end
    return extras
end

function __exportShipChanges(entity, v)
    local extras = __exportBasics(entity)
    return extras
end