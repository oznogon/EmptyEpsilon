-- Configurable repair-crew mortality and coolant tracking for scenarios.

local M = {}

local default_notifications = {
    { position = "Engineering", suffix = "" },
    { position = "Engineering+", suffix = "Plus" },
    { position = "DamageControl", suffix = "Dmg" },
}

local default_system_consequences = {
    {
        name = "probe",
        capability = "getCanLaunchProbe",
        set = "setCanLaunchProbe",
        id = "probe_launch_damage_message",
        text = "The probe launch system has been damaged",
    },
    {
        name = "hack",
        capability = "getCanHack",
        set = "setCanHack",
        id = "hack_damage_message",
        text = "The hacking system has been damaged",
    },
    {
        name = "scan",
        capability = "getCanScan",
        set = "setCanScan",
        id = "scan_damage_message",
        text = "The scanners have been damaged",
    },
    {
        name = "combat_maneuver",
        capability = "getCanCombatManeuver",
        set = "setCanCombatManeuver",
        id = "combat_maneuver_damage_message",
        text = "Combat maneuver has been damaged",
    },
    {
        name = "self_destruct",
        capability = "getCanSelfDestruct",
        set = "setCanSelfDestruct",
        id = "self_destruct_damage_message",
        text = "The self destruct system has been damaged",
    },
}

function M.new(config)
    config = config or {}
    local api = { timer = config.timer }
    local random = config.random or _G.random or math.random
    local notifications = config.notifications or default_notifications
    local consequences = config.consequences or default_system_consequences
    local player_limit = config.player_limit or 32
    local field_style = config.field_style or "camel"

    local function field(prefix, name)
        if field_style == "snake" then
            return prefix .. "_" .. name
        end
        return prefix .. name:sub(1, 1):upper() .. name:sub(2)
    end

    local function notify(ship, id, text, context)
        context = context or "repairCrew-msgEngineer"
        local group = context:match("^(.-)-msg") or context
        for notification_index, entry in ipairs(notifications) do
            if ship:hasPlayerAtPosition(entry.position) then
                local position_context
                if entry.position == "Engineering+" then
                    position_context = group .. "-msgEngineer+"
                elseif entry.position == "DamageControl" then
                    position_context = group .. "-msgDamageControl"
                else
                    position_context = group .. "-msgEngineer"
                end
                ship:addCustomMessage(
                    entry.position,
                    id .. entry.suffix,
                    _(position_context, text)
                )
            end
        end
    end

    local function snapshot(ship)
        local shield = ship:getShieldCount() > 1
                and (ship:getSystemHealth("frontshield") + ship:getSystemHealth(
                    "rearshield"
                )) / 2
            or ship:getSystemHealth("frontshield")
        ship[field("prev", "shield")] = shield
        ship[field("prev", "reactor")] = ship:getSystemHealth("reactor")
        ship[field("prev", "maneuver")] = ship:getSystemHealth("maneuver")
        ship[field("prev", "impulse")] = ship:getSystemHealth("impulse")
        if ship:getBeamWeaponRange(0) > 0 then
            ship[field("prev", "beam")] = ship:getSystemHealth("beamweapons")
        end
        if ship:getWeaponTubeCount() > 0 then
            ship[field("prev", "missile")] =
                ship:getSystemHealth("missilesystem")
        end
        if ship:hasWarpDrive() then
            ship[field("prev", "warp")] = ship:getSystemHealth("warp")
        end
        if ship:hasJumpDrive() then
            ship[field("prev", "jump")] = ship:getSystemHealth("jumpdrive")
        end
    end

    local function lose_crew(ship)
        ship:setRepairCrewCount(ship:getRepairCrewCount() - 1)
        notify(
            ship,
            "repairCrewFatality",
            "One of your repair crew has perished"
        )
    end

    local function lose_coolant(ship)
        local current = ship:getMaxCoolant()
        local ranges = current >= 10 and (config.loss_high or { 0.25, 0.5 })
            or (config.loss_low or { 0.15, 0.35 })
        local lost = current * random(ranges[1], ranges[2])
        ship:setMaxCoolant(current - lost)
        ship.reclaimable_coolant = math.min(
            20,
            (ship.reclaimable_coolant or 0) + lost * random(0.8, 1)
        )
        notify(
            ship,
            "coolantLoss",
            "Damage has caused a loss of coolant",
            "coolant-msgEngineer"
        )
    end

    local function damage_system(ship, consequence)
        ship[consequence.set](ship, false)
        notify(ship, consequence.id, consequence.text, "damage-msgEngineer")
    end

    function api:reset(ship)
        snapshot(ship)
    end

    function api:fate(ship, fatality_chance)
        if math.random() >= fatality_chance then
            return
        end
        local mode = config.consequence_mode or "weighted"
        if ship.initialCoolant == nil or mode == "crew_only" then
            lose_crew(ship)
            return
        end
        if mode == "binary" then
            if random(1, 100) < 50 then
                lose_crew(ship)
            else
                lose_coolant(ship)
            end
            return
        end

        local available = {}
        for _, consequence in ipairs(consequences) do
            if ship[consequence.capability](ship) then
                table.insert(available, consequence)
            end
        end
        local choice = math.random(1, 2 + #available)
        if choice == 1 then
            lose_crew(ship)
        elseif choice == 2 then
            lose_coolant(ship)
        else
            damage_system(ship, available[choice - 2])
        end
    end

    function api:update(delta, timer)
        if timer ~= nil then
            api.timer = timer
        end
        if api.timer == nil then
            api.timer = config.interval and config.interval() or 8
        end
        api.timer = api.timer - delta
        if api.timer >= 0 then
            return api.timer
        end

        for index = 1, player_limit do
            local ship = config.player and config.player(index)
                or getPlayerShip(index)
            if ship ~= nil and ship:isValid() then
                if ship:getRepairCrewCount() > 0 then
                    local chance = 0
                    local shield = ship:getShieldCount() > 1
                            and (ship:getSystemHealth("frontshield") + ship:getSystemHealth(
                                "rearshield"
                            )) / 2
                        or ship:getSystemHealth("frontshield")
                    chance = chance + ship[field("prev", "shield")] - shield
                    ship[field("prev", "shield")] = shield
                    chance = chance
                        + ship[field("prev", "reactor")]
                        - ship:getSystemHealth("reactor")
                    ship[field("prev", "reactor")] =
                        ship:getSystemHealth("reactor")
                    chance = chance
                        + ship[field("prev", "maneuver")]
                        - ship:getSystemHealth("maneuver")
                    ship[field("prev", "maneuver")] =
                        ship:getSystemHealth("maneuver")
                    chance = chance
                        + ship[field("prev", "impulse")]
                        - ship:getSystemHealth("impulse")
                    ship[field("prev", "impulse")] =
                        ship:getSystemHealth("impulse")
                    if ship:getBeamWeaponRange(0) > 0 then
                        chance = chance
                            + ship[field("prev", "beam")]
                            - ship:getSystemHealth("beamweapons")
                        ship[field("prev", "beam")] =
                            ship:getSystemHealth("beamweapons")
                    end
                    if ship:getWeaponTubeCount() > 0 then
                        chance = chance
                            + ship[field("prev", "missile")]
                            - ship:getSystemHealth("missilesystem")
                        ship[field("prev", "missile")] =
                            ship:getSystemHealth("missilesystem")
                    end
                    if ship:hasWarpDrive() then
                        chance = chance
                            + ship[field("prev", "warp")]
                            - ship:getSystemHealth("warp")
                        ship[field("prev", "warp")] =
                            ship:getSystemHealth("warp")
                    end
                    if ship:hasJumpDrive() then
                        chance = chance
                            + ship[field("prev", "jump")]
                            - ship:getSystemHealth("jumpdrive")
                        ship[field("prev", "jump")] =
                            ship:getSystemHealth("jumpdrive")
                    end
                    if ship:getRepairCrewCount() == 1 then
                        chance = chance / (config.last_crew_divisor or 2)
                    end
                    if chance > 0 then
                        api:fate(ship, chance)
                    end
                else
                    local recovery = config.recovery and config.recovery() or 4
                    if random(1, 100) <= recovery then
                        ship:setRepairCrewCount(1)
                        notify(
                            ship,
                            "repairCrewRecovery",
                            "Medical team has revived one of your repair crew"
                        )
                        api:reset(ship)
                    end
                end

                if ship.initialCoolant ~= nil then
                    local current = ship:getMaxCoolant()
                    local threshold = config.coolant_threshold or 20
                    if
                        current < threshold
                        and random(1, 100)
                            <= (config.coolant_recovery_chance or 4)
                    then
                        local reclaimed = 0
                        local fraction = config.reclaim_fraction or { 0.1, 0.5 }
                        if (ship.reclaimable_coolant or 0) > 0 then
                            reclaimed = ship.reclaimable_coolant
                                * random(fraction[1], fraction[2])
                            ship:setMaxCoolant(
                                math.min(threshold, current + reclaimed)
                            )
                            ship.reclaimable_coolant = ship.reclaimable_coolant
                                - reclaimed
                        end
                        if math.floor(reclaimed) > 0 then
                            notify(
                                ship,
                                "coolant_recovery",
                                "Automated systems have recovered some coolant",
                                "coolant-msgEngineer"
                            )
                        end
                        api:reset(ship)
                    end
                end
            end
        end
        api.timer = delta + (config.interval and config.interval() or 8)
        return api.timer
    end

    return api
end

function M.resetCallback(status)
    return function(ship)
        status:reset(ship)
    end
end

function M.fateCallback(status)
    return function(ship, fatality_chance)
        status:fate(ship, fatality_chance)
    end
end

return M
