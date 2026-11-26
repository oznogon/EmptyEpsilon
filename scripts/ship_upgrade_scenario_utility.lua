-- Declarative one-shot ship upgrades used by optional station missions.

local M = {}

local function each_beam(ship, callback)
    local index = 0
    while ship:getBeamWeaponRange(index) > 0 do
        callback(
            index,
            ship:getBeamWeaponArc(index),
            ship:getBeamWeaponDirection(index),
            ship:getBeamWeaponRange(index),
            ship:getBeamWeaponCycleTime(index),
            ship:getBeamWeaponDamage(index)
        )
        index = index + 1
    end
end

local operations = {
    beam_cycle = function(ship, value)
        each_beam(ship, function(index, arc, direction, range, cycle, damage)
            ship:setBeamWeapon(
                index,
                arc,
                direction,
                range,
                cycle * value,
                damage
            )
        end)
    end,
    beam_range = function(ship, value)
        each_beam(ship, function(index, arc, direction, range, cycle, damage)
            ship:setBeamWeapon(
                index,
                arc,
                direction,
                range * value,
                cycle,
                damage
            )
        end)
    end,
    beam_damage = function(ship, value)
        each_beam(ship, function(index, arc, direction, range, cycle, damage)
            ship:setBeamWeapon(
                index,
                arc,
                direction,
                range,
                cycle,
                damage * value
            )
        end)
    end,
    beam_heat = function(ship, value)
        each_beam(ship, function(index)
            ship:setBeamWeaponHeatPerFire(
                index,
                ship:getBeamWeaponHeatPerFire(index) * value
            )
        end)
    end,
    spin = function(ship, value)
        ship:setRotationMaxSpeed(ship:getRotationMaxSpeed() * value)
    end,
    impulse = function(ship, value)
        ship:setImpulseMaxSpeed(ship:getImpulseMaxSpeed() * value)
    end,
    hull = function(ship, value)
        ship:setHullMax(ship:getHullMax() * value)
        ship:setHull(ship:getHullMax())
    end,
    battery = function(ship, value)
        ship:setMaxEnergy(ship:getMaxEnergy() * value)
        ship:setEnergy(ship:getMaxEnergy())
    end,
    shields = function(ship, value)
        if ship:getShieldCount() == 1 then
            ship:setShieldsMax(ship:getShieldMax(0) * value)
        else
            ship:setShieldsMax(
                ship:getShieldMax(0) * value,
                ship:getShieldMax(1) * value
            )
        end
    end,
    missile_storage = function(ship, value)
        for _, missile_type in ipairs({
            "Homing",
            "Nuke",
            "Mine",
            "EMP",
            "HVLI",
        }) do
            ship:setWeaponStorageMax(
                missile_type,
                math.ceil(ship:getWeaponStorageMax(missile_type) * value)
            )
        end
    end,
    add_homing_tube = function(ship, value)
        local original = ship:getWeaponTubeCount()
        ship:setWeaponTubeCount(original + 1)
        ship:setWeaponTubeExclusiveFor(original, "Homing")
        ship:setWeaponStorageMax(
            "Homing",
            ship:getWeaponStorageMax("Homing") + value
        )
        ship:setWeaponStorage("Homing", ship:getWeaponStorage("Homing") + value)
    end,
}

function M.standardOrder()
    return {
        "shrinkBeamCycle",
        "increaseSpin",
        "addAuxTube",
        "coolBeam",
        "longerBeam",
        "damageBeam",
        "moreMissiles",
        "fasterImpulse",
        "strongerHull",
        "efficientBatteries",
        "strongerShields",
    }
end

function M.standardSpecs(two_tier)
    local function tiers(base, upgraded)
        if not two_tier then
            return { { goods = 1, value = base } }
        end
        return {
            { goods = 1, value = base },
            { goods = 2, value = upgraded },
        }
    end
    return {
        shrinkBeamCycle = {
            label = "Reduce beam cycle time",
            operation = "beam_cycle",
            requires = "beams",
            tiers = tiers(0.75, 0.60),
        },
        increaseSpin = {
            label = "Increase spin speed",
            operation = "spin",
            tiers = tiers(1.5, 1.8),
        },
        addAuxTube = {
            label = "Add missile tube",
            operation = "add_homing_tube",
            extra_cost = { luxury = 1 },
            tiers = tiers(2, 4),
        },
        coolBeam = {
            label = "Reduce beam heat",
            operation = "beam_heat",
            requires = "beams",
            tiers = tiers(0.5, 0.4),
        },
        longerBeam = {
            label = "Extend beam range",
            operation = "beam_range",
            requires = "beams",
            tiers = tiers(1.25, 1.4),
        },
        damageBeam = {
            label = "Increase beam damage",
            operation = "beam_damage",
            requires = "beams",
            tiers = tiers(1.2, 1.3),
        },
        moreMissiles = {
            label = "Increase missile storage capacity",
            operation = "missile_storage",
            requires = "missiles",
            tiers = tiers(1.25, 1.4),
        },
        fasterImpulse = {
            label = "Speed up impulse engines",
            operation = "impulse",
            tiers = tiers(1.25, 1.4),
        },
        strongerHull = {
            label = "Strengthen hull",
            operation = "hull",
            tiers = tiers(1.5, 1.8),
        },
        efficientBatteries = {
            label = "Increase battery efficiency",
            operation = "battery",
            tiers = tiers(1.25, 1.4),
        },
        strongerShields = {
            label = "Strengthen shields",
            operation = "shields",
            tiers = tiers(1.2, 1.4),
        },
    }
end

function M.new(config)
    config = config or {}
    local specs = config.specs or {}
    local api = {}

    local function eligible(ship, spec)
        if spec.requires == "beams" then
            return ship:getBeamWeaponRange(0) > 0
        elseif spec.requires == "missiles" then
            return ship:getWeaponTubeCount() > 0
        end
        return true
    end

    local function message(spec, kind, ship, target, tier, quantity)
        local character = target.comms_data.character or ""
        local good = target.comms_data.characterGood or ""
        if spec.messages and spec.messages[kind] then
            local value = spec.messages[kind]
            if type(value) == "function" then
                return value(ship, target, tier, quantity)
            end
            return value
        end
        if kind == "missing" then
            return string.format(
                _("upgrade-comms", "%s requires %s for the upgrade"),
                character,
                good
            )
        elseif kind == "unsupported" then
            return _(
                "upgrade-comms",
                "Your ship type does not support this upgrade."
            )
        end
        return string.format(
            _("upgrade-comms", "%s completed the %s upgrade."),
            character,
            spec.label
        )
    end

    function api:offer(id, source, target)
        local spec = specs[id]
        if spec == nil then
            return
        end
        source = source or comms_source
        target = target or comms_target
        if source[id .. "Upgrade"] ~= nil then
            return
        end
        addCommsReply(_("upgrade-comms", spec.label), function()
            if not eligible(source, spec) then
                setCommsMessage(message(spec, "unsupported", source, target))
                return
            end
            local free = config.free_when and config.free_when(source, target)
            local available = source.goods
                    and source.goods[target.comms_data.characterGood]
                or 0
            local selected = spec.tiers[1]
            if free then
                selected = spec.tiers[1]
            else
                for _, tier in ipairs(spec.tiers) do
                    if available >= tier.goods then
                        selected = tier
                    end
                end
                if available < selected.goods then
                    setCommsMessage(
                        message(spec, "missing", source, target, selected, 0)
                    )
                    return
                end
            end

            local quantity = free and 0 or selected.goods
            if not free then
                for good, amount in pairs(spec.extra_cost or {}) do
                    if (source.goods[good] or 0) < amount then
                        setCommsMessage(
                            message(
                                spec,
                                "missing",
                                source,
                                target,
                                selected,
                                0
                            )
                        )
                        return
                    end
                end
                source.goods[target.comms_data.characterGood] = available
                    - quantity
                for good, amount in pairs(spec.extra_cost or {}) do
                    source.goods[good] = source.goods[good] - amount
                    quantity = quantity + amount
                end
                source.cargo = source.cargo + quantity
            end
            source[id .. "Upgrade"] = "done"
            operations[spec.operation](source, selected.value, quantity)
            if config.on_complete then
                config.on_complete(source, id, quantity)
            end
            setCommsMessage(
                message(
                    spec,
                    free and "free" or "paid",
                    source,
                    target,
                    selected,
                    quantity
                )
            )
            if config.add_back then
                addCommsReply(_("Back"), commsStation)
            end
        end)
    end

    function api:offerAll(source, target)
        for _, id in ipairs(config.order or {}) do
            api:offer(id, source, target)
        end
    end

    return api
end

return M
