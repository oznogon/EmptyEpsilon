-- Shared player-ship baseline state used by scenario setup and health tracking.

local M = {}

local default_systems = {
    "reactor",
    "beamweapons",
    "missilesystem",
    "maneuver",
    "impulse",
    "warp",
    "jumpdrive",
    "frontshield",
    "rearshield",
}

function M.defaultSystems()
    local systems = {}
    for _, system in ipairs(default_systems) do
        table.insert(systems, system)
    end
    return systems
end

function M.customizeCrowImpulse(ship)
    if ship:getImpulseMaxSpeed() == 45 then
        ship:setImpulseMaxSpeed(90)
    end
end

function M.customizeStingrayEmp(ship)
    ship:setBeamWeapon(0, 20, 0, 1200, 6, 8)
        :setBeamWeaponDamageType(0, "emp")
        :setBeamWeaponArcColor(0, 0, 0, 0.5, 0, 0, 1.0)
    ship:setBeamWeapon(1, 30, 0, 1000, 6, 8)
end

function M.customizeCrow(ship)
    M.customizeCrowImpulse(ship)
    if ship:getBeamWeaponCycleTime(0) == 6 then
        local index = 0
        repeat
            local arc = ship:getBeamWeaponArc(index)
            local direction = ship:getBeamWeaponDirection(index)
            local range = ship:getBeamWeaponRange(index)
            local damage = ship:getBeamWeaponDamage(index)
            ship:setBeamWeapon(index, arc, direction, range, 5, damage)
            index = index + 1
        until ship:getBeamWeaponRange(index) < 1
    end
end

function M.applyShipProfile(ship, options)
    local ship_type = ship:getTypeName()
    local profile = options.profiles[ship_type]
    if profile == nil and options.stats and options.stats(ship_type) ~= nil then
        profile = { stats = true, radar = true, names = true }
    end
    profile = profile or options.fallback
    local name_key = profile.names == true and ship_type or profile.names
    local names = name_key and options.name_pools()[name_key]
    if names ~= nil and #names > 0 then
        local name
        if options.name_selection == "swap" then
            name = tableRemoveRandom(names)
        else
            local index = math.random(1, #names)
            name = names[index]
            table.remove(names, index)
        end
        if name ~= nil then
            ship:setCallSign(name)
        end
    end
    if profile.customize then
        profile.customize(ship)
    end
    local stats = profile.stats and options.stats and options.stats(ship_type)
    ship[options.score_field] = stats and stats.strength or profile.score
    ship[options.cargo_field] = stats and stats.cargo or profile.cargo
    if stats and profile.radar then
        ship:setLongRangeRadarRange(stats.long_range_radar)
        ship:setShortRangeRadarRange(stats.short_range_radar)
    end
    if profile.coolant_field and profile.auto_coolant ~= nil then
        ship[profile.coolant_field] = profile.auto_coolant
    end
    if profile.warp then
        ship:setWarpDrive(true)
        if profile.warp_speed then
            ship:setWarpSpeed(profile.warp_speed)
        end
    end
    if profile.jump then
        ship:setJumpDrive(true)
        ship:setJumpDriveRange(profile.jump[1], profile.jump[2])
    end
end

function M.coolantGiven(ship)
    if ship:hasPlayerAtPosition("Engineering") then
        if ship.get_coolant_button ~= nil then
            ship:removeCustom(ship.get_coolant_button)
            ship.get_coolant_button = nil
        end
    end
    if ship:hasPlayerAtPosition("Engineering+") then
        if ship.get_coolant_button_plus ~= nil then
            ship:removeCustom(ship.get_coolant_button_plus)
            ship.get_coolant_button_plus = nil
        end
    end
    ship.coolant_trigger = true
end

function M.closestPlayerTo(obj, limit)
    if obj == nil or not obj:isValid() then
        return nil
    end
    local closest_distance = 9999999
    local closest_player = nil
    for index = 1, limit or 8 do
        local ship = getPlayerShip(index)
        if ship ~= nil and ship:isValid() then
            local current_distance = distance(ship, obj)
            if current_distance < closest_distance then
                closest_player = ship
                closest_distance = current_distance
            end
        end
    end
    return closest_player
end

function M.addCommandLogButton(ship, show_log)
    ship.command_log_button_rel = "command_log_button_rel"
    ship:addCustomButton(
        "Relay",
        ship.command_log_button_rel,
        _("buttonRelay", "Command Log"),
        function()
            string.format("")
            show_log(ship, "Relay")
        end,
        7
    )
    ship.command_log_button_ops = "command_log_button_ops"
    ship:addCustomButton(
        "Operations",
        ship.command_log_button_ops,
        _("buttonOperations", "Command Log"),
        function()
            string.format("")
            show_log(ship, "Operations")
        end,
        7
    )
end

function M.updatePlayerTubeSizeBanner(ship)
    if ship.tube_size ~= nil then
        local tube_size_banner = string.format(
            _("-tabWeapons&Tactical", "%s tubes: %s"),
            ship:getCallSign(),
            ship.tube_size
        )
        if #ship.tube_size == 1 then
            tube_size_banner = string.format(
                _("-tabWeapons&Tactical", "%s tube: %s"),
                ship:getCallSign(),
                ship.tube_size
            )
        end
        ship.tube_sizes_wea = "tube_sizes_wea"
        ship:addCustomInfo("Weapons", ship.tube_sizes_wea, tube_size_banner, 1)
        ship.tube_sizes_tac = "tube_sizes_tac"
        ship:addCustomInfo("Tactical", ship.tube_sizes_tac, tube_size_banner, 1)
    end
end

function M.updateNameBanner(ship)
    local name_banner = string.format(
        _("tabHelms-id", "%s %s in %s"),
        ship:getFaction(),
        ship:getCallSign(),
        ship:getSectorName()
    )
    ship.name_banner_hlm = "name_banner_hlm"
    ship:addCustomInfo("Helms", ship.name_banner_hlm, name_banner, 1)
    ship.name_banner_tac = "name_banner_tac"
    ship:addCustomInfo("Tactical", ship.name_banner_tac, name_banner, 1)
end

function M.updateTubeBanner(ship)
    if ship.tube_size ~= nil then
        local tube_size_banner =
            string.format("%s tubes: %s", ship:getCallSign(), ship.tube_size)
        if #ship.tube_size == 1 then
            local tube_size_banner =
                string.format("%s tube: %s", ship:getCallSign(), ship.tube_size)
        end
        ship.tube_size_banner_wea = "tube_size_banner_wea"
        ship:addCustomInfo(
            "Weapons",
            ship.tube_size_banner_wea,
            tube_size_banner,
            2
        )
        ship.tube_size_banner_tac = "tube_size_banner_tac"
        ship:addCustomInfo(
            "Tactical",
            ship.tube_size_banner_tac,
            tube_size_banner,
            2
        )
    end
end

function M.resetHealth(ship, options)
    options = options or {}
    local snake_case = options.snake_case or false
    local function set(prefix, name, value)
        if snake_case then
            ship[prefix .. "_" .. name] = value
        else
            ship[prefix .. name:sub(1, 1):upper() .. name:sub(2)] = value
        end
    end
    local function set_healthy(name)
        if options.initialize_healthy then
            local field = "healthy" .. name:sub(1, 1):upper() .. name:sub(2)
            if ship[field] == nil then
                ship[field] = 1.0
            end
        end
    end
    local shield = ship:getShieldCount() > 1
            and (ship:getSystemHealth("frontshield") + ship:getSystemHealth(
                "rearshield"
            )) / 2
        or ship:getSystemHealth("frontshield")
    set("prev", "shield", shield)
    set("prev", "reactor", ship:getSystemHealth("reactor"))
    set("prev", "maneuver", ship:getSystemHealth("maneuver"))
    set("prev", "impulse", ship:getSystemHealth("impulse"))
    if ship:getBeamWeaponRange(0) > 0 then
        set_healthy("beam")
        set("prev", "beam", ship:getSystemHealth("beamweapons"))
    end
    if ship:getWeaponTubeCount() > 0 then
        set_healthy("missile")
        set("prev", "missile", ship:getSystemHealth("missilesystem"))
    end
    if ship:hasWarpDrive() then
        set_healthy("warp")
        set("prev", "warp", ship:getSystemHealth("warp"))
    end
    if ship:hasJumpDrive() then
        set_healthy("jump")
        set("prev", "jump", ship:getSystemHealth("jumpdrive"))
    end
end

function M.resetHealthCallback(options)
    return function(ship)
        M.resetHealth(ship, options)
    end
end

function M.applyDefaults(ship, options)
    if ship == nil then
        return
    end
    options = options or {}
    if options.position then
        ship:setPosition(options.position[1], options.position[2])
    end
    ship.shipScore = options.score or 24
    ship.maxCargo = options.cargo or 5
    ship.cargo = ship.maxCargo
    ship.tractor = options.tractor or false
    ship.tractor_target_lock = false
    ship.mining = options.mining or false
    ship.goods = {}
    if options.faction then
        ship:setFaction(options.faction)
    end
    if options.command_log then
        ship.command_log = {}
    end
    if options.probe_type_list and ship.probe_type_list == nil then
        ship.probe_type_list = { { name = "standard", count = -1 } }
    end
    if options.reputation and ship:getReputationPoints() == 0 then
        ship:setReputationPoints(options.reputation)
    end
end

function M.recordDeployments(players, deployed_players, options)
    options = options or {}
    for _, ship in ipairs(players) do
        local recorded = false
        local existing_deployment
        for _, deployment in ipairs(deployed_players) do
            if deployment.p == ship then
                recorded = true
                existing_deployment = deployment
                break
            end
        end
        if recorded and options.on_existing then
            options.on_existing(ship, existing_deployment)
        end
        if options.prepare then
            options.prepare(ship)
        end
        if not recorded then
            local deployment = {
                p = ship,
                name = ship:getCallSign(),
                count = 1,
            }
            if options.include_template then
                deployment.template = ship:getTypeName()
            end
            table.insert(deployed_players, deployment)
            if options.on_record then
                options.on_record(ship, deployment)
            end
        end
        if options.after then
            options.after(ship)
        end
    end
    return deployed_players
end

function M.resetBaseline(ship, options)
    options = options or {}
    ship[options.max_crew_field or "maxRepairCrew"] = ship:getRepairCrewCount()

    local fields = {
        shield = "Shield",
        reactor = "Reactor",
        maneuver = "Maneuver",
        impulse = "Impulse",
        beam = "Beam",
        missile = "Missile",
        warp = "Warp",
        jump = "Jump",
    }
    if options.snake_case then
        fields = {
            shield = "shield",
            reactor = "reactor",
            maneuver = "maneuver",
            impulse = "impulse",
            beam = "beam",
            missile = "missile",
            warp = "warp",
            jump = "jump",
        }
    end

    local function reset(name)
        if options.snake_case then
            ship["healthy_" .. fields[name]] = 1.0
            ship["prev_" .. fields[name]] = 1.0
        else
            ship["healthy" .. fields[name]] = 1.0
            ship["prev" .. fields[name]] = 1.0
        end
    end

    reset("shield")
    reset("reactor")
    reset("maneuver")
    reset("impulse")
    if ship:getBeamWeaponRange(0) > (options.beam_range_threshold or 0) then
        reset("beam")
    end

    local tube_count = ship:getWeaponTubeCount()
    if tube_count > 0 then
        reset("missile")
        if options.tube_size ~= false then
            local size_letter = {
                small = "S",
                medium = "M",
                large = "L",
            }
            if options.localize_tube_size then
                size_letter = {
                    small = _("tubeSize-tabWeapons", "S"),
                    medium = _("tubeSize-tabWeapons", "M"),
                    large = _("tubeSize-tabWeapons", "L"),
                }
            end
            ship.tube_size = ""
            for index = 1, tube_count do
                ship.tube_size = ship.tube_size
                    .. size_letter[ship:getTubeSize(index - 1)]
            end
        end
    end
    if ship:hasWarpDrive() then
        reset("warp")
    end
    if ship:hasJumpDrive() then
        reset("jump")
    end

    if options.initial_coolant ~= false then
        ship.initialCoolant = ship:getMaxCoolant()
    end
    if options.coolant_rates ~= false then
        ship.normal_coolant_rate = {}
        ship.normal_power_rate = {}
        for _, system in ipairs(options.systems or default_systems) do
            ship.normal_coolant_rate[system] = ship:getSystemCoolantRate(system)
            ship.normal_power_rate[system] = ship:getSystemPowerRate(system)
        end
    end
end

return M
