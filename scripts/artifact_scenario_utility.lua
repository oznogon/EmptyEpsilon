-- Artifact generation utility from Borderline Fever.

local Artifacts = {}

local CONSOLES = {
    Engineering = { suffix = "", message_suffix = "" },
    ["Engineering+"] = { suffix = "_plus", message_suffix = "_plus" },
    DamageControl = { suffix = "_dmg", message_suffix = "_dmg" },
    Helms = { suffix = "", message_suffix = "" },
    Tactical = { suffix = "_tac", message_suffix = "_tac" },
    Weapons = { suffix = "", message_suffix = "" },
    Science = { suffix = "", message_suffix = "" },
    Operations = { suffix = "_ops", message_suffix = "_ops" },
    Relay = { suffix = "", message_suffix = "" },
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, item in pairs(value) do
        copy[key] = deepCopy(item)
    end
    return copy
end

local function isPositive(self, p, config)
    local scan_bonus = 0
    if self:isScannedByFaction(p:getFaction()) then
        scan_bonus = config.difficulty * 5
    end
    return random(1, 100)
        < config.positive_chance
            - (config.difficulty * config.difficulty_interval)
            + scan_bonus
end

local function messageKey(console, key)
    return key .. CONSOLES[console].message_suffix
end

local function sendMessage(p, console, key, text)
    if p:hasPlayerAtPosition(console) then
        local field = messageKey(console, key)
        p[field] = field
        p:addCustomMessage(console, p[field], text)
    end
end

local function sendArtifactMessage(p, console, key, text, spec, ...)
    if p:hasPlayerAtPosition(console) then
        local context = "artifactEffect-msg"
            .. string.gsub(console, "Engineering", "Engineer")
        sendMessage(
            p,
            console,
            key,
            string.format(_(context, text), spec.scan_desc, ...)
        )
    end
end

local function notify(p, consoles, key, text, spec, ...)
    for console_index, console in ipairs(consoles) do
        sendArtifactMessage(p, console, key, text, spec, ...)
    end
end

local ENGINEERING_CONSOLES = { "Engineering", "Engineering+", "DamageControl" }
local HELM_CONSOLES = { "Helms", "Tactical" }
local WEAPON_CONSOLES = { "Weapons", "Tactical" }
local SENSOR_CONSOLES = { "Science", "Operations" }
local PROBE_CONSOLES = { "Relay", "Operations" }

local BUTTONS = {
    cm_boost = {
        consoles = { "Helms", "Tactical" },
        label = "C.M. Boost",
        active_message = "Combat maneuver boost (forward direction) ability increased",
        activate = function(p)
            local stats = playerShipStats[p:getTypeName()]
            p:setCombatManeuver(stats.cm_boost + 200, stats.cm_strafe)
        end,
        expire = function(p)
            local stats = playerShipStats[p:getTypeName()]
            p:setCombatManeuver(stats.cm_boost - 200, stats.cm_strafe)
        end,
    },
    cm_strafe = {
        consoles = { "Helms", "Tactical" },
        label = "C.M. Strafe",
        active_message = "Combat maneuver strafe (sideways direction) ability increased",
        activate = function(p)
            local stats = playerShipStats[p:getTypeName()]
            p:setCombatManeuver(stats.cm_boost, stats.cm_strafe + 200)
        end,
        expire = function(p)
            local stats = playerShipStats[p:getTypeName()]
            p:setCombatManeuver(stats.cm_boost, stats.cm_strafe - 200)
        end,
    },
    beam_damage = {
        consoles = { "Weapons", "Tactical" },
        label = "Beam Damage",
        active_message = "Damage applied by beam weapons increased",
        activate = function(p)
            local bi = 0
            repeat
                p:setBeamWeapon(
                    bi,
                    p:getBeamWeaponArc(bi),
                    p:getBeamWeaponDirection(bi),
                    p:getBeamWeaponRange(bi),
                    p:getBeamWeaponCycleTime(bi),
                    p:getBeamWeaponDamage(bi) * 1.1
                )
                bi = bi + 1
            until p:getBeamWeaponRange(bi) < 1
        end,
    },
    beam_cycle = {
        consoles = { "Weapons", "Tactical" },
        label = "Beam Cycle",
        active_message = "The time it takes to cycle the beams between firing has been reduced",
        activate = function(p)
            local bi = 0
            repeat
                p:setBeamWeapon(
                    bi,
                    p:getBeamWeaponArc(bi),
                    p:getBeamWeaponDirection(bi),
                    p:getBeamWeaponRange(bi),
                    p:getBeamWeaponCycleTime(bi) * 0.9,
                    p:getBeamWeaponDamage(bi)
                )
                bi = bi + 1
            until p:getBeamWeaponRange(bi) < 1
        end,
    },
    impulse = {
        consoles = { "Helms", "Tactical" },
        label = "Impulse Speed",
        active_message = "The maximum impulse speed has been increased",
        activate = function(p)
            p:setImpulseMaxSpeed(p:getImpulseMaxSpeed() * 1.1)
        end,
    },
    warp = {
        consoles = { "Helms", "Tactical" },
        label = "Warp Speed",
        active_message = "The maximum warp speed has been increased",
        activate = function(p)
            p:setWarpSpeed(p:getWarpSpeed() * 1.1)
        end,
    },
    jump = {
        consoles = { "Helms", "Tactical" },
        label = "Jump Range",
        active_message = "The maximum jump range has been increased",
        activate = function(p)
            if p.max_jump_range == nil then
                p.max_jump_range = 50000
                p.min_jump_range = 5000
            end
            p:setJumpDriveRange(p.min_jump_range, p.max_jump_range * 1.1)
            p.max_jump_range = p.max_jump_range * 1.1
        end,
    },
    shield = {
        consoles = { "Weapons", "Tactical" },
        label = "Shield Capacity",
        active_message = "The maximum shield strength has been increased",
        activate = function(p)
            if p:getShieldCount() > 1 then
                p:setShieldsMax(
                    p:getShieldMax(0) * 1.1,
                    p:getShieldMax(1) * 1.1
                )
            else
                p:setShieldsMax(p:getShieldMax(0) * 1.1)
            end
        end,
    },
    maneuver = {
        consoles = { "Helms", "Tactical" },
        label = "Spin Speed",
        active_message = "The maximum spin speed has been increased",
        activate = function(p)
            p:setRotationMaxSpeed(p:getRotationMaxSpeed() * 1.1)
        end,
    },
    battery = {
        consoles = { "Engineering", "Engineering+", "DamageControl" },
        label = "Battery Capacity",
        active_message = "The maximum battery capacity has been increased",
        activate = function(p)
            p:setMaxEnergy(p:getMaxEnergy() * 1.1)
        end,
    },
}

local function buttonField(name, console)
    return "activate_" .. name .. "_button" .. CONSOLES[console].suffix
end

local function removeButton(p, name, console)
    local field = buttonField(name, console)
    if p[field] ~= nil then
        p:removeCustom(p[field])
        p[field] = nil
    end
end

local function removeButtons(p, name)
    for console_index, console in ipairs(BUTTONS[name].consoles) do
        removeButton(p, name, console)
    end
end

function Artifacts.addButton(
    p,
    name,
    console,
    activate,
    message_console,
    active_message
)
    local spec = BUTTONS[name]
    if not p:hasPlayerAtPosition(console) then
        return
    end
    local field = buttonField(name, console)
    if p[field] ~= nil then
        return
    end
    p[field] = field
    p:addCustomButton(
        console,
        p[field],
        _("upgrade-button" .. console, spec.label),
        function()
            string.format("") --global context for serious proton
            if p[name .. "_count"] > 0 then
                p[name .. "_active"] = true
                (activate or spec.activate)(p)
                p[name .. "_timer"] = 300
                p[name .. "_count"] = p[name .. "_count"] - 1
                sendMessage(
                    p,
                    console,
                    name .. "_activated_message",
                    _(
                        "upgrade-msg" .. (message_console or console),
                        active_message or spec.active_message
                    )
                )
            end
            removeButtons(p, name)
        end
    )
end

local COOLANT_CONSOLES = { "Engineering", "Engineering+", "DamageControl" }
local COOLANT_SYSTEMS = {
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

local function coolantButtonField(console)
    return "coolant_pump_fix_buttons" .. CONSOLES[console].suffix
end

local function addCoolantPumpButton(p, console, system)
    if not p:hasPlayerAtPosition(console) then
        return
    end
    local field = coolantButtonField(console)
    if p[field][system] ~= nil then
        return
    end
    p[field][system] = string.format("%s%s", field, system)
    p:addCustomButton(
        console,
        p[field][system],
        string.format(_("coolant-button" .. console, "%s C. Pump"), system),
        function()
            string.format("") --global context for serious proton
            if p.coolant_pump_part_count > 0 then
                p:setSystemCoolantRate(system, p.normal_coolant_rate[system])
                p.coolant_pump_part_count = p.coolant_pump_part_count - 1
                sendMessage(
                    p,
                    console,
                    "coolant_pump_fixed_message",
                    string.format(
                        _(
                            "coolant-msg" .. console,
                            "The %s coolant pump has been repaired"
                        ),
                        system
                    )
                )
            end
            Artifacts.refreshCoolantPumpButtons(p)
        end
    )
end

function Artifacts.refreshCoolantPumpButtons(p)
    for _, system in ipairs(COOLANT_SYSTEMS) do
        for console_index, console in ipairs(COOLANT_CONSOLES) do
            local field = coolantButtonField(console)
            if p[field] ~= nil and p[field][system] ~= nil then
                p:removeCustom(p[field][system])
            end
        end
        if
            p.normal_coolant_rate ~= nil
            and p.normal_coolant_rate[system]
                < p:getSystemCoolantRate(system)
        then
            for console_index, console in ipairs(COOLANT_CONSOLES) do
                addCoolantPumpButton(p, console, system)
            end
        end
    end
end

local function standardSystemHealth(config, spec, p, self)
    local system = spec.system
    local prefix = spec.message_prefix
    local max_health = p:getSystemHealthMax(system)
    local health = p:getSystemHealth(system)
    if isPositive(self, p, config) then
        if max_health < 1 then
            p:setSystemHealthMax(system, math.min(1, max_health + 0.05))
            notify(
                p,
                ENGINEERING_CONSOLES,
                "artifact_improved_max_" .. prefix .. "_health_message",
                "The %s retrieved has improved the "
                    .. spec.label
                    .. " system maximum health",
                spec
            )
        elseif health < 1 then
            p:setSystemHealth(system, math.min(1, health + 0.05))
            notify(
                p,
                ENGINEERING_CONSOLES,
                "artifact_improved_" .. prefix .. "_health_message",
                "The %s retrieved has improved the "
                    .. spec.label
                    .. " system health",
                spec
            )
        else
            notify(
                p,
                ENGINEERING_CONSOLES,
                "artifact_" .. prefix .. "_health_message",
                "The %s retrieved has had no impact on an already healthy "
                    .. spec.label
                    .. " system",
                spec
            )
        end
    elseif isPositive(self, p, config) then
        p:setSystemHealth(system, math.max(-1, health - 0.05))
        notify(
            p,
            ENGINEERING_CONSOLES,
            "artifact_damaged_" .. prefix .. "_health_message",
            "The %s retrieved has damaged the "
                .. spec.label
                .. " system health",
            spec
        )
    else
        p:setSystemHealthMax(system, math.max(-1, max_health - 0.05))
        notify(
            p,
            ENGINEERING_CONSOLES,
            "artifact_damaged_max_" .. prefix .. "_health_message",
            "The %s retrieved has damaged the "
                .. spec.label
                .. " system maximum health",
            spec
        )
    end
end

local function shieldHealth(config, spec, p, self)
    if p:getShieldCount() > 1 then
        local max_front = p:getSystemHealthMax("frontshield")
        local health_front = p:getSystemHealth("frontshield")
        local max_rear = p:getSystemHealthMax("rearshield")
        local health_rear = p:getSystemHealth("rearshield")
        if isPositive(self, p, config) then
            if max_front < 1 then
                p:setSystemHealthMax(
                    "frontshield",
                    math.min(1, max_front + 0.05)
                )
                notify(
                    p,
                    ENGINEERING_CONSOLES,
                    "artifact_improved_max_front_shield_health_message",
                    "The %s retrieved has improved the front shield system maximum health",
                    spec
                )
            elseif max_rear < 1 then
                p:setSystemHealthMax("rearshield", math.min(1, max_rear + 0.05))
                notify(
                    p,
                    ENGINEERING_CONSOLES,
                    "artifact_improved_max_rear_shield_health_message",
                    "The %s retrieved has improved the rear shield system maximum health",
                    spec
                )
            elseif health_front < 1 then
                p:setSystemHealth(
                    "frontshield",
                    math.min(1, health_front + 0.05)
                )
                notify(
                    p,
                    ENGINEERING_CONSOLES,
                    "artifact_improved_front_shield_health_message",
                    "The %s retrieved has improved the front shield system health",
                    spec
                )
            elseif health_rear < 1 then
                p:setSystemHealth("rearshield", math.min(1, health_rear + 0.05))
                notify(
                    p,
                    ENGINEERING_CONSOLES,
                    "artifact_improved_rear_shield_health_message",
                    "The %s retrieved has improved the rear shield system health",
                    spec
                )
            else
                notify(
                    p,
                    ENGINEERING_CONSOLES,
                    "artifact_shield_health_message",
                    "The %s retrieved has had no impact on an already healthy shield system",
                    spec
                )
            end
        else
            if
                random(1, 100)
                < config.positive_chance
                    - (config.difficulty * config.difficulty_interval)
            then
                if random(1, 100) <= 50 then
                    p:setSystemHealth(
                        "frontshield",
                        math.max(-1, health_front - 0.05)
                    )
                    notify(
                        p,
                        ENGINEERING_CONSOLES,
                        "artifact_damaged_front_shield_health_message",
                        "The %s retrieved has damaged the front shield system health",
                        spec
                    )
                else
                    p:setSystemHealth(
                        "rearshield",
                        math.max(-1, health_front - 0.05)
                    )
                    notify(
                        p,
                        ENGINEERING_CONSOLES,
                        "artifact_damaged_rear_shield_health_message",
                        "The %s retrieved has damaged the rear shield system health",
                        spec
                    )
                end
            else
                if random(1, 100) <= 50 then
                    p:setSystemHealthMax(
                        "frontshield",
                        math.max(-1, max_front - 0.05)
                    )
                    notify(
                        p,
                        ENGINEERING_CONSOLES,
                        "artifact_damaged_max_front_shield_health_message",
                        "The %s retrieved has damaged the front shield system maximum health",
                        spec
                    )
                else
                    p:setSystemHealthMax(
                        "rearshield",
                        math.max(-1, max_front - 0.05)
                    )
                    notify(
                        p,
                        ENGINEERING_CONSOLES,
                        "artifact_damaged_max_rear_shield_health_message",
                        "The %s retrieved has damaged the rear shield system maximum health",
                        spec
                    )
                end
            end
        end
    else
        standardSystemHealth(config, {
            system = "frontshield",
            message_prefix = "shield",
            label = "shield",
            scan_desc = spec.scan_desc,
        }, p, self)
    end
end

local function boolEffect(config, spec, p, self)
    local enabled = p[spec.getter](p)
    local prefix = spec.message_prefix
    if isPositive(self, p, config) then
        if not enabled then
            p[spec.setter](p, true)
            notify(
                p,
                spec.consoles,
                "artifact_enabled_" .. prefix .. "_message",
                spec.enabled_text,
                spec
            )
        else
            notify(
                p,
                spec.consoles,
                "artifact_" .. prefix .. "_message",
                spec.no_effect_text,
                spec
            )
        end
    elseif enabled then
        p[spec.setter](p, false)
        notify(
            p,
            spec.consoles,
            "artifact_disabled_" .. prefix .. "_message",
            spec.disabled_text,
            spec
        )
    else
        notify(
            p,
            spec.consoles,
            "artifact_" .. prefix .. "_message",
            spec.no_effect_text,
            spec
        )
    end
end

local function chargeEffect(config, spec, p, self)
    local name = spec.name
    local prefix = spec.message_prefix
    local consoles = spec.consoles
    if isPositive(self, p, config) then
        if spec.current(p) < spec.maximum(p) then
            spec.restock(p)
            notify(
                p,
                consoles,
                "artifact_restocked_" .. prefix .. "_message",
                spec.restock_text,
                spec,
                spec.stock_name(p)
            )
        else
            notify(
                p,
                consoles,
                "artifact_" .. prefix .. "_message",
                spec.no_effect_text,
                spec
            )
        end
    elseif spec.current(p) > 0 then
        spec.deplete(p)
        notify(
            p,
            consoles,
            "artifact_depleted_" .. prefix .. "_message",
            spec.deplete_text,
            spec,
            spec.stock_name(p)
        )
    else
        notify(
            p,
            consoles,
            "artifact_" .. prefix .. "_message",
            spec.no_effect_text,
            spec
        )
    end
end

local function timedEffect(config, spec, p, self)
    local name = spec.name
    local prefix = spec.message_prefix
    local consoles = spec.consoles
    if spec.available ~= nil and not spec.available(p) then
        notify(p, consoles, spec.missing_message, spec.missing_text, spec)
        return
    end
    if p[name .. "_count"] == nil then
        p[name .. "_count"] = 0
    end
    if isPositive(self, p, config) then
        p[name .. "_count"] = p[name .. "_count"] + 1
        if p[name .. "_active"] == nil then
            p[name .. "_active"] = false
        end
        if not p[name .. "_active"] then
            for console_index, console in ipairs(BUTTONS[name].consoles) do
                Artifacts.addButton(p, name, console)
            end
        end
    elseif p[name .. "_count"] > 0 then
        p[name .. "_count"] = p[name .. "_count"] - 1
        if p[name .. "_count"] < 1 then
            removeButtons(p, name)
        end
        notify(
            p,
            consoles,
            "lost_" .. prefix .. "_message",
            "The %s retrieved disabled a %s previously retrieved",
            spec,
            spec.scan_desc
        )
    else
        spec.reduce(p, config)
        notify(
            p,
            consoles,
            "reduced_" .. prefix .. "_message",
            spec.reduced_text,
            spec
        )
    end
end

local EFFECTS = {
    healthBeam = function(config, spec, p, self)
        standardSystemHealth(config, {
            system = "beamweapons",
            message_prefix = "beam",
            label = "beam",
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    healthMissile = function(config, spec, p, self)
        standardSystemHealth(config, {
            system = "missilesystem",
            message_prefix = "missile",
            label = "missile",
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    healthImpulse = function(config, spec, p, self)
        standardSystemHealth(config, {
            system = "impulse",
            message_prefix = "impulse",
            label = "impulse",
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    healthWarp = function(config, spec, p, self)
        if p:hasSystem("warp") then
            standardSystemHealth(config, {
                system = "warp",
                message_prefix = "warp",
                label = "warp",
                scan_desc = spec.scan_desc,
            }, p, self)
        end
    end,
    healthJump = function(config, spec, p, self)
        if p:hasSystem("jumpdrive") then
            standardSystemHealth(config, {
                system = "jumpdrive",
                message_prefix = "jump",
                label = "jump",
                scan_desc = spec.scan_desc,
            }, p, self)
        end
    end,
    healthShield = function(config, spec, p, self)
        shieldHealth(config, spec, p, self)
    end,
    healthSpin = function(config, spec, p, self)
        standardSystemHealth(config, {
            system = "maneuver",
            message_prefix = "maneuver",
            label = "maneuver",
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    healthReactor = function(config, spec, p, self)
        standardSystemHealth(config, {
            system = "reactor",
            message_prefix = "reactor",
            label = "reactor",
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    boolScan = function(config, spec, p, self)
        boolEffect(config, {
            getter = "getCanScan",
            setter = "setCanScan",
            message_prefix = "scan",
            enabled_text = "The %s retrieved has enabled the scanners",
            no_effect_text = "The %s retrieved does not effect the scanners",
            disabled_text = "The %s retrieved has disabled the scanners",
            consoles = SENSOR_CONSOLES,
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    boolCombat = function(config, spec, p, self)
        boolEffect(config, {
            getter = "getCanCombatManeuver",
            setter = "setCanCombatManeuver",
            message_prefix = "cm",
            enabled_text = "The %s retrieved has enabled combat maneuver",
            no_effect_text = "The %s retrieved does not effect combat maneuver",
            disabled_text = "The %s retrieved has disabled combat maneuver",
            consoles = HELM_CONSOLES,
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    boolProbe = function(config, spec, p, self)
        boolEffect(config, {
            getter = "getCanLaunchProbe",
            setter = "setCanLaunchProbe",
            message_prefix = "probe",
            enabled_text = "The %s retrieved has enabled probe launch",
            no_effect_text = "The %s retrieved does not effect probe launch",
            disabled_text = "The %s retrieved has disabled probe launch",
            consoles = PROBE_CONSOLES,
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    boolHack = function(config, spec, p, self)
        boolEffect(config, {
            getter = "getCanHack",
            setter = "setCanHack",
            message_prefix = "hack",
            enabled_text = "The %s retrieved has enabled hacking",
            no_effect_text = "The %s retrieved does not effect hacking",
            disabled_text = "The %s retrieved has disabled hacking",
            consoles = PROBE_CONSOLES,
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    changeScan = function(config, spec, p, self)
        local current_range = p:getLongRangeRadarRange()
        if isPositive(self, p, config) then
            p:setLongRangeRadarRange(current_range * 1.1)
            notify(
                p,
                SENSOR_CONSOLES,
                "artifact_increase_sensor_range_message",
                "The %s retrieved has increased our sensor range",
                spec
            )
        else
            p:setLongRangeRadarRange(current_range * 0.9)
            notify(
                p,
                SENSOR_CONSOLES,
                "artifact_decrease_sensor_range_message",
                "The %s retrieved has decreased our sensor range",
                spec
            )
        end
    end,
    changeCoolant = function(config, spec, p, self)
        local current_coolant = p:getMaxCoolant()
        if isPositive(self, p, config) then
            p:setMaxCoolant(current_coolant * 1.1)
            notify(
                p,
                ENGINEERING_CONSOLES,
                "artifact_increase_coolant_message",
                "The %s retrieved has increased our coolant",
                spec
            )
        else
            p:setMaxCoolant(current_coolant * 0.9)
            notify(
                p,
                ENGINEERING_CONSOLES,
                "artifact_decrease_coolant_message",
                "The %s retrieved has decreased our coolant: incompatible, corrosive reaction",
                spec
            )
        end
    end,
    changeRepair = function(config, spec, p, self)
        local current_repair_crew_count = p:getRepairCrewCount()
        if isPositive(self, p, config) then
            p:setRepairCrewCount(current_repair_crew_count + 1)
            notify(
                p,
                ENGINEERING_CONSOLES,
                "artifact_increase_repair_crew_message",
                "The %s retrieved has increased the number of repair crew",
                spec
            )
        elseif current_repair_crew_count > 0 then
            p:setRepairCrewCount(current_repair_crew_count - 1)
            notify(
                p,
                ENGINEERING_CONSOLES,
                "artifact_decrease_repair_crew_message",
                "The %s retrieved has decreased the number of repair crew: assassination malware",
                spec
            )
        else
            notify(
                p,
                ENGINEERING_CONSOLES,
                "artifact_repair_crew_message",
                "The %s retrieved has had no effect on the number of repair crew: malfunction",
                spec
            )
        end
    end,
    changeHull = function(config, spec, p, self)
        local current_hull = p:getHull()
        if isPositive(self, p, config) then
            p:setHull(current_hull * 1.1)
            for console_index, console in ipairs(ENGINEERING_CONSOLES) do
                if p:hasPlayerAtPosition(console) then
                    local key = "artifact_increase_hull_message"
                    local field = messageKey(console, key)
                    p[field] = field
                    p:addCustomMessage(
                        console,
                        p[field],
                        string.format(
                            _(
                                "artifactEffect-msg"
                                    .. string.gsub(
                                        console,
                                        "Engineering",
                                        "Engineer"
                                    ),
                                "The %s retrieved has repaired some hull damage"
                            ),
                            spec.scan_desc
                        )
                    )
                end
            end
        else
            p:setHull(current_hull * 0.9)
            notify(
                p,
                ENGINEERING_CONSOLES,
                "artifact_decrease_hull_message",
                "The %s retrieved has damaged the hull: poor integration",
                spec
            )
        end
    end,
    changeShield = function(config, spec, p, self)
        if isPositive(self, p, config) then
            if p:getShieldCount() > 1 then
                p:setShields(
                    p:getShieldLevel(0) * 1.1,
                    p:getShieldLevel(1) * 1.1
                )
            else
                p:setShields(p:getShieldLevel(0) * 1.1)
            end
            notify(
                p,
                ENGINEERING_CONSOLES,
                "artifact_increase_shield_message",
                "The %s retrieved has added charge to the shields",
                spec
            )
        else
            if p:getShieldCount() > 1 then
                p:setShields(
                    p:getShieldLevel(0) * 0.9,
                    p:getShieldLevel(1) * 0.9
                )
            else
                p:setShields(p:getShieldLevel(0) * 0.9)
            end
            notify(
                p,
                ENGINEERING_CONSOLES,
                "artifact_decrease_shield_message",
                "The %s retrieved has reduced shield charge: corroded couplings",
                spec
            )
        end
    end,
    changePower = function(config, spec, p, self)
        local current_energy = p:getEnergy()
        if isPositive(self, p, config) then
            p:setEnergy(current_energy + p:getMaxEnergy() * 0.1)
            notify(
                p,
                ENGINEERING_CONSOLES,
                "artifact_increase_energy_message",
                "The %s retrieved has added energy to our reserves",
                spec
            )
        else
            p:setEnergy(current_energy - p:getMaxEnergy() * 0.1)
            notify(
                p,
                ENGINEERING_CONSOLES,
                "artifact_decrease_energy_message",
                "The %s retrieved has drained some energy: incompatibility",
                spec
            )
        end
    end,
    combatBoost = function(config, spec, p, self)
        timedEffect(config, {
            name = "cm_boost",
            message_prefix = "cm_boost",
            consoles = HELM_CONSOLES,
            available = function(ship)
                return config.player_ship_stats[ship:getTypeName()].cm_boost
                    ~= nil
            end,
            missing_message = "cm_boost_message",
            missing_text = "The %s retrieved has had no effect on combat maneuver",
            reduced_text = "The %s retrieved reduced the combat maneuver boost (forward direction) ability",
            reduce = function(p, config)
                p:setCombatManeuver(
                    config.player_ship_stats[p:getTypeName()].cm_boost - 100,
                    config.player_ship_stats[p:getTypeName()].cm_strafe
                )
            end,
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    combatStrafe = function(config, spec, p, self)
        timedEffect(config, {
            name = "cm_strafe",
            message_prefix = "cm_strafe",
            consoles = HELM_CONSOLES,
            available = function(ship)
                return config.player_ship_stats[ship:getTypeName()].cm_strafe
                    ~= nil
            end,
            missing_message = "cm_strafe_message",
            missing_text = "The %s retrieved has had no effect on combat maneuver",
            reduced_text = "The %s retrieved reduced the combat maneuver strafe (sideways direction) ability",
            reduce = function(p, config)
                p:setCombatManeuver(
                    config.player_ship_stats[p:getTypeName()].cm_boost,
                    config.player_ship_stats[p:getTypeName()].cm_strafe - 100
                )
            end,
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    probeStock = function(config, spec, p, self)
        chargeEffect(config, {
            name = "probes",
            message_prefix = "probes",
            consoles = PROBE_CONSOLES,
            current = function(ship)
                return ship:getScanProbeCount()
            end,
            maximum = function(ship)
                return ship:getMaxScanProbeCount()
            end,
            restock = function(ship)
                ship:setScanProbeCount(ship:getMaxScanProbeCount())
            end,
            deplete = function(ship)
                ship:setScanProbeCount(math.floor(ship:getScanProbeCount() / 2))
            end,
            stock_name = function()
                return nil
            end,
            restock_text = "The %s retrieved has restocked your probes",
            no_effect_text = "The %s retrieved does not effect probe stock",
            deplete_text = "The %s retrieved has depleted probe stock",
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    beamDamage = function(config, spec, p, self)
        timedEffect(config, {
            name = "beam_damage",
            message_prefix = "beam_damage",
            consoles = WEAPON_CONSOLES,
            available = function(ship)
                return ship:hasSystem("beamweapons")
            end,
            missing_message = "beam_message",
            missing_text = "The %s retrieved has had no effect on your non-existent beam weapon system",
            reduced_text = "The %s retrieved reduced beam damage",
            reduce = function(p, config)
                local bi = 0
                repeat
                    p:setBeamWeapon(
                        bi,
                        p:getBeamWeaponArc(bi),
                        p:getBeamWeaponDirection(bi),
                        p:getBeamWeaponRange(bi),
                        p:getBeamWeaponCycleTime(bi),
                        p:getBeamWeaponDamage(bi) * 0.9
                    )
                    bi = bi + 1
                until p:getBeamWeaponRange(bi) < 1
            end,
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    beamCycle = function(config, spec, p, self)
        timedEffect(config, {
            name = "beam_cycle",
            message_prefix = "beam_cycle",
            consoles = WEAPON_CONSOLES,
            available = function(ship)
                return ship:hasSystem("beamweapons")
            end,
            missing_message = "beam_message",
            missing_text = "The %s retrieved has had no effect on your non-existent beam weapon system",
            reduced_text = "The %s retrieved slowed beam cycle time",
            reduce = function(p, config)
                local bi = 0
                repeat
                    p:setBeamWeapon(
                        bi,
                        p:getBeamWeaponArc(bi),
                        p:getBeamWeaponDirection(bi),
                        p:getBeamWeaponRange(bi),
                        p:getBeamWeaponCycleTime(bi) * 1.1,
                        p:getBeamWeaponDamage(bi)
                    )
                    bi = bi + 1
                until p:getBeamWeaponRange(bi) < 1
            end,
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    missileStock = function(config, spec, p, self)
        chargeEffect(config, {
            name = "missiles",
            message_prefix = "missiles",
            consoles = WEAPON_CONSOLES,
            current = function(ship)
                local shortage = -1
                spec.shortage_type = nil
                for _, missile_type in ipairs({
                    "Nuke",
                    "EMP",
                    "Mine",
                    "Homing",
                    "HVLI",
                }) do
                    local maximum = ship:getWeaponStorageMax(missile_type)
                    if
                        maximum > 0
                        and maximum
                                - ship:getWeaponStorage(missile_type)
                            > shortage
                    then
                        shortage = maximum - ship:getWeaponStorage(missile_type)
                        spec.shortage_type = missile_type
                    end
                end
                return shortage
            end,
            maximum = function()
                return math.huge
            end,
            stock_name = function(ship)
                local amount = 0
                local stock_type = ""
                for _, missile_type in ipairs({
                    "Nuke",
                    "EMP",
                    "Mine",
                    "Homing",
                    "HVLI",
                }) do
                    if ship:getWeaponStorage(missile_type) > amount then
                        amount = ship:getWeaponStorage(missile_type)
                        stock_type = missile_type
                    end
                end
                spec.plentiful_type = stock_type
                return stock_type
            end,
            restock = function(ship)
                ship:setWeaponStorage(
                    spec.shortage_type,
                    ship:getWeaponStorageMax(spec.shortage_type)
                )
            end,
            deplete = function(ship)
                ship:setWeaponStorage(
                    spec.plentiful_type,
                    math.floor(ship:getWeaponStorage(spec.plentiful_type) / 2)
                )
            end,
            restock_text = "The %s retrieved has restocked your %ss",
            no_effect_text = "The %s retrieved does not effect missile stocks",
            deplete_text = "The %s retrieved has depleted your stock of %ss",
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    impulseSpeed = function(config, spec, p, self)
        timedEffect(config, {
            name = "impulse",
            message_prefix = "impulse",
            consoles = HELM_CONSOLES,
            reduced_text = "The %s retrieved slowed maximum impulse speed",
            reduce = function(p, config)
                p:setImpulseMaxSpeed(p:getImpulseMaxSpeed() * 0.9)
            end,
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    warpSpeed = function(config, spec, p, self)
        timedEffect(config, {
            name = "warp",
            message_prefix = "warp",
            consoles = HELM_CONSOLES,
            available = function(ship)
                return ship:hasSystem("warp")
            end,
            missing_message = "warp_message",
            missing_text = "The %s retrieved had no effect on your non-existent warp system",
            reduced_text = "The %s retrieved slowed maximum warp speed",
            reduce = function(p, config)
                p:setWarpSpeed(p:getWarpSpeed() * 0.9)
            end,
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    jumpRange = function(config, spec, p, self)
        timedEffect(config, {
            name = "jump",
            message_prefix = "jump",
            consoles = HELM_CONSOLES,
            available = function(ship)
                return ship:hasSystem("jumpdrive")
            end,
            missing_message = "jump_message",
            missing_text = "The %s retrieved had no effect on your non-existent jump system",
            reduced_text = "The %s retrieved reduced maximum jump range",
            reduce = function(p, config)
                if p.max_jump_range == nil then
                    p.max_jump_range = 50000
                    p.min_jump_range = 5000
                end
                p:setJumpDriveRange(p.max_jump_range * 0.9)
                p.max_jump_range = p.max_jump_range * 0.9
            end,
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    shieldMax = function(config, spec, p, self)
        timedEffect(config, {
            name = "shield",
            message_prefix = "shield",
            consoles = WEAPON_CONSOLES,
            available = function(ship)
                return ship:hasSystem("frontshield")
            end,
            missing_message = "shield_message",
            missing_text = "The %s retrieved had no effect on your non-existent shield system",
            reduced_text = "The %s retrieved reduced maximum shield strength",
            reduce = function(p, config)
                if p:getShieldCount() > 1 then
                    p:setShieldsMax(
                        p:getShieldMax(0) * 0.9,
                        p:getShieldMax(1) * 0.9
                    )
                else
                    p:setShieldsMax(p:getShieldMax(0) * 0.9)
                end
            end,
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    spinSpeed = function(config, spec, p, self)
        timedEffect(config, {
            name = "maneuver",
            message_prefix = "maneuver",
            consoles = HELM_CONSOLES,
            reduced_text = "The %s retrieved reduced maximum spin speed",
            reduce = function(p, config)
                p:setRotationMaxSpeed(p:getRotationMaxSpeed() * 0.9)
            end,
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    batteryMax = function(config, spec, p, self)
        timedEffect(config, {
            name = "battery",
            message_prefix = "battery",
            consoles = ENGINEERING_CONSOLES,
            reduced_text = "The %s retrieved reduced maximum battery capacity",
            reduce = function(p, config)
                p:setMaxEnergy(p:getMaxEnergy() * 0.9)
            end,
            scan_desc = spec.scan_desc,
        }, p, self)
    end,
    cargo = function(config, spec, p, self)
        local wreck_good =
            config.common_goods[math.random(1, #config.common_goods)]
        spec.scan_desc = string.format(
            _("scienceDescription-artifact", "Cargo (type: %s)"),
            wreck_good
        )
        string.format("") --serious proton needs global context
        if isPositive(self, p, config) then
            if p.cargo > 0 then
                p.cargo = p.cargo - 1
                if p.goods == nil then
                    p.goods = {}
                end
                if p.goods[wreck_good] == nil then
                    p.goods[wreck_good] = 0
                end
                p.goods[wreck_good] = p.goods[wreck_good] + 1
                for console_index, console in ipairs(PROBE_CONSOLES) do
                    if p:hasPlayerAtPosition(console) then
                        sendMessage(
                            p,
                            console,
                            "good_added",
                            string.format(
                                _(
                                    "inventory-msg"
                                        .. string.gsub(
                                            console,
                                            "Operations",
                                            "Ops"
                                        ),
                                    "One %s added to ship inventory"
                                ),
                                wreck_good
                            )
                        )
                    end
                end
            else
                for console_index, console in ipairs(PROBE_CONSOLES) do
                    if p:hasPlayerAtPosition(console) then
                        sendMessage(
                            p,
                            console,
                            "no_cargo_space",
                            _(
                                "inventory-msg"
                                    .. string.gsub(console, "Operations", "Ops"),
                                "No cargo space available. Cargo wasted"
                            )
                        )
                    end
                end
            end
        else
            self:explode()
            p:setHull(p:getHull() - random(1, 3))
            for console_index, console in ipairs(PROBE_CONSOLES) do
                if p:hasPlayerAtPosition(console) then
                    sendMessage(
                        p,
                        console,
                        "cargo_sabotage",
                        _(
                            "sabotage-msg"
                                .. string.gsub(console, "Operations", "Ops"),
                            "Booby trapped cargo container. Fortunately automated safety protocols transported the cargo container off the ship before too much damage was taken"
                        )
                    )
                end
            end
        end
    end,
    coolantPump = function(config, spec, p, self)
        if isPositive(self, p, config) then
            if p.coolant_pump_part_count == nil then
                p.coolant_pump_part_count = 0
            end
            p.coolant_pump_part_count = p.coolant_pump_part_count + 1
            notify(
                p,
                COOLANT_CONSOLES,
                "artifact_provided_coolant_pump_parts_message",
                "The %s retrieved provided spare coolant pump parts that may be used to repair a damaged coolant pump",
                spec
            )
            for console_index, console in ipairs(COOLANT_CONSOLES) do
                local field = coolantButtonField(console)
                if p[field] == nil then
                    p[field] = {}
                end
            end
            Artifacts.refreshCoolantPumpButtons(p)
        else
            notify(
                p,
                COOLANT_CONSOLES,
                "artifact_incompatible_message",
                "The %s retrieved contains no compatible or salvageable parts for your coolant pump system",
                spec
            )
        end
    end,
}

local function createArtifact(config, spec, x, y)
    local artifact = Artifact():setPosition(x, y)
    artifact:setScanningParameters(math.random(1, 2), math.random(1, 3))
    artifact:setRadarTraceScale(0.5)
    local color_scheme = math.random(1, 3)
    if color_scheme == 1 then
        artifact:setRadarTraceColor(0, 255, 0)
        artifact:setModel("ammo_box")
    elseif color_scheme == 2 then
        artifact:setRadarTraceColor(255, 200, 100)
        artifact:setModel("artifact1")
    else
        artifact:setModel("artifact2")
    end
    artifact:setDescriptions(spec.desc, spec.scan_desc)
    artifact:onPickup(function(self, p)
        string.format("") --global context for serious proton
        EFFECTS[spec.effect](config, spec, p, self)
    end)
    return artifact
end

function Artifacts.new(definitions, options)
    local config = deepCopy(options or {})
    local artifacts = {}
    for index, definition in ipairs(definitions) do
        local spec = deepCopy(definition)
        artifacts[index] = {
            desc = spec.desc,
            scan_desc = spec.scan_desc,
            func = function(x, y)
                return createArtifact(config, spec, x, y)
            end,
        }
    end
    return artifacts
end

return Artifacts
