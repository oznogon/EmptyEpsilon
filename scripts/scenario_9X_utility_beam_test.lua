-- Name: Utility Beam Test
-- Description: Test utility beam system functions
-- Type: Development

--- Scenario
-- @script scenario_98_utility_beam_test

require("utils.lua")

function getEmitterUtilityBeam(entity)
    local mounts = entity.components.mounts
    if mounts then
        for i = 1, #mounts do
            local m = mounts[i]
            if m and m.type == "utility" then
                return m
            end
        end
    end
    return nil
end

function getUtilityBeamHeatRate(entity)
    local utility_beam = getEmitterUtilityBeam(entity)
    if utility_beam then
        return utility_beam.heat_per_second
    end
    return 0.0
end

function checkBeamCapability(beam_emitter)
    local emitter_utility_beam = getEmitterUtilityBeam(beam_emitter)
    local emitter_utility_beam_effectiveness = math.max(
        beam_emitter:getSystemHealth("utilitybeam"),
        0.0
    ) * beam_emitter:getSystemPower("utilitybeam")
    local emitter_utility_beam_energy_use_per_delta = beam_emitter:getSystemPower(
        "utilitybeam"
    ) * emitter_utility_beam.energy_use_per_second * global_delta
    local can_fire = true

    if
        emitter_utility_beam_effectiveness <= 0.0
        or beam_emitter:getEnergy()
            < emitter_utility_beam_energy_use_per_delta
    then
        --log("X Utility beam can't fire, no effect, health:", beam_emitter:getSystemHealth("utilitybeam"), " energy:", beam_emitter:getEnergy())
        emitter_utility_beam.is_firing = false
        can_fire = false
    end

    return can_fire,
        emitter_utility_beam,
        emitter_utility_beam_effectiveness,
        emitter_utility_beam_energy_use_per_delta
end

function transferHomingMissile(
    beam_emitter,
    mode_name,
    sending_entity,
    receiving_entity,
    emitter_utility_beam,
    emitter_utility_beam_effectiveness,
    emitter_utility_beam_energy_use_per_delta,
    threshold
)
    threshold = threshold or 1.0
    if
        receiving_entity.components.missile_tubes.storage_homing
            < receiving_entity.components.missile_tubes.max_homing
        and sending_entity.components.missile_tubes.storage_homing > 0
    then
        -- Initialize restocking tick counter if necessary
        if receiving_entity.amount_restocked == nil then
            receiving_entity.amount_restocked = 0
        end

        -- Each tick counts down toward a successful transfer while generating heat and consuming energy
        local amount_restocked_per_tick = emitter_utility_beam.strength
            * 0.001
            * emitter_utility_beam_effectiveness
            * global_delta
        receiving_entity.amount_restocked = receiving_entity.amount_restocked
            + amount_restocked_per_tick
        beam_emitter:setEnergy(
            beam_emitter:getEnergy() - emitter_utility_beam_energy_use_per_delta
        )
        beam_emitter:setSystemHeat(
            "utilitybeam",
            beam_emitter:getSystemHeat("utilitybeam")
                + getUtilityBeamHeatRate(beam_emitter)
                    * beam_emitter:getSystemPower("utilitybeam")
                    * global_delta
        )
        beam_emitter:setCustomUtilityBeamModeProgress(
            mode_name,
            receiving_entity.amount_restocked
        )

        -- If the threshold is reached in this tick, fire the beam and send a missile over
        if receiving_entity.amount_restocked >= threshold then
            emitter_utility_beam.is_firing = true
            sending_entity.components.missile_tubes.storage_homing = sending_entity.components.missile_tubes.storage_homing
                - 1
            receiving_entity.components.missile_tubes.storage_homing = receiving_entity.components.missile_tubes.storage_homing
                + 1
            receiving_entity.amount_restocked = receiving_entity.amount_restocked
                - 1
            beam_emitter:setCustomUtilityBeamModeProgress(mode_name, 0)
            -- log("Sender transferred 1 homing missile to receiver. Sender:", sending_entity.components.missile_tubes.storage_homing, "receiver:", receiving_entity.components.missile_tubes.storage_homing)
        else
            emitter_utility_beam.is_firing = false
        end
    else
        emitter_utility_beam.is_firing = false
    end
end

function transferRepairCrew(
    beam_emitter,
    mode_name,
    sending_entity,
    receiving_entity,
    emitter_utility_beam,
    emitter_utility_beam_effectiveness,
    emitter_utility_beam_energy_use_per_delta,
    threshold
)
    threshold = threshold or 1.0
    if
        receiving_entity.components.internal_rooms
        and sending_entity:getRepairCrewCount() > 0
    then
        -- Initialize restocking tick counter if necessary
        if receiving_entity.transfer_progress == nil then
            receiving_entity.transfer_progress = 0
        end

        -- Each tick counts down toward a successful transfer while generating heat and consuming energy
        local transfer_progress_per_tick = emitter_utility_beam.strength
            * 0.001
            * emitter_utility_beam_effectiveness
            * global_delta
        receiving_entity.transfer_progress = receiving_entity.transfer_progress
            + transfer_progress_per_tick
        beam_emitter:setEnergy(
            beam_emitter:getEnergy() - emitter_utility_beam_energy_use_per_delta
        )
        beam_emitter:setSystemHeat(
            "utilitybeam",
            beam_emitter:getSystemHeat("utilitybeam")
                + getUtilityBeamHeatRate(beam_emitter)
                    * beam_emitter:getSystemPower("utilitybeam")
                    * global_delta
        )
        beam_emitter:setCustomUtilityBeamModeProgress(
            mode_name,
            receiving_entity.transfer_progress
        )

        -- If the threshold is reached in this tick, fire the beam and send a missile over
        if receiving_entity.transfer_progress >= threshold then
            emitter_utility_beam.is_firing = true
            sending_entity:setRepairCrewCount(
                sending_entity:getRepairCrewCount() - 1
            )
            receiving_entity:setRepairCrewCount(
                receiving_entity:getRepairCrewCount() + 1
            )
            receiving_entity.transfer_progress = receiving_entity.transfer_progress
                - 1
            beam_emitter:setCustomUtilityBeamModeProgress(mode_name, 0)
            -- log("Sender transferred 1 repair crew to receiver. Sender:", sending_entity:getRepairCrewCount(), "receiver:", receiving_entity:getRepairCrewCount())
        else
            emitter_utility_beam.is_firing = false
        end
    else
        emitter_utility_beam.is_firing = false
    end
end

function convertFaction(
    beam_emitter,
    mode_name,
    target_entity,
    emitter_utility_beam,
    emitter_utility_beam_effectiveness,
    emitter_utility_beam_energy_use_per_delta,
    threshold,
    new_faction
)
    -- Initialize threshold and default destination faction to the beam emitter's faction
    threshold = threshold or 1.0
    new_faction = new_faction or beam_emitter:getFaction()

    -- Change the target's faction only if the target entity's faction differs from the destination faction
    if target_entity:getFaction() ~= new_faction then
        -- Initialize progress tick counter if necessary
        if target_entity.faction_change_progress == nil then
            target_entity.faction_change_progress = 0
        end

        -- Each tick counts down toward a successful conversion while generating heat and consuming energy
        local change_progress_per_tick = emitter_utility_beam.strength
            * 0.001
            * emitter_utility_beam_effectiveness
            * global_delta
        target_entity.faction_change_progress = target_entity.faction_change_progress
            + change_progress_per_tick
        beam_emitter:setCustomUtilityBeamModeProgress(
            mode_name,
            target_entity.faction_change_progress
        )
        beam_emitter:setEnergy(
            beam_emitter:getEnergy() - emitter_utility_beam_energy_use_per_delta
        )
        beam_emitter:setSystemHeat(
            "utilitybeam",
            beam_emitter:getSystemHeat("utilitybeam")
                + getUtilityBeamHeatRate(beam_emitter)
                    * beam_emitter:getSystemPower("utilitybeam")
                    * global_delta
        )

        -- If the threshold is reached in this tick, fire the beam and convert the target's faction
        if target_entity.faction_change_progress >= threshold then
            emitter_utility_beam.is_firing = true
            target_entity:setFaction(new_faction)
            target_entity.faction_change_progress = 0
            beam_emitter:setCustomUtilityBeamModeProgress(mode_name, 0)
            -- log("Converted target faction")
        else
            emitter_utility_beam.is_firing = false
        end
    else
        emitter_utility_beam.is_firing = false
    end

    -- Potential changes: track progress for different factions in a table and convert only to the faction in the table with the largest value.
    -- Compete for conversion if multiple ships are tagging the same ship
end

function init()
    global_delta = 0.0
    ECS = false

    if createEntity then
        ECS = true
    end

    player_ship = PlayerSpaceship()
        :setFaction("Human Navy")
        :setTemplate("Atlantis")
        :setUtilityBeam(180, 5000, 1, 1000)
        :setRotation(-90)
        :setCallSign("player")
        :setHull(1)
        :setCanBeDestroyed(false)
    player_ship:setWeaponStorage("Homing", 5):setWeaponStorageMax("Homing", 5)

    player_ship_2 = PlayerSpaceship()
        :setFaction("Kraylor")
        :setTemplate("Atlantis")
        :setUtilityBeam(180, 5000, 1, 1000)
        :setRotation(-90)
        :setCallSign("player 2")
        :setHull(1)
        :setCanBeDestroyed(false)
    player_ship_2
        :setWeaponStorage("Homing", 5)
        :setWeaponStorageMax("Homing", 5)
        :setPosition(0, -1000)

    resupply_ship = CpuShip()
        :setTemplate("Atlantis")
        :setPosition(0, 500)
        :setRotation(0)
        :setFaction("Human Navy")
        :setCallSign("resupply")
        :orderIdle()
    resupply_ship
        :setWeaponStorage("Homing", 0)
        :setWeaponStorageMax("Homing", 5)
        :setScanned(true)

    target_ship = CpuShip()
        :setTemplate("Adder MK5")
        :setPosition(500, 0)
        :setRotation(0)
        :setFaction("Human Navy")
        :setCallSign("target")
        :orderRoaming()
        :setScanned(true)

    SpaceStation()
        :setPosition(1000, 1000)
        :setTemplate("Small Station")
        :setFaction("Human Navy")
        :setRotation(random(0, 360))

    function MineableAsteroid()
        e = Asteroid()
        e.can_be_mined = true
        return e
    end

    MineableAsteroid():setPosition(-600, 0):setSize(100)
    MineableAsteroid():setPosition(-600, 250):setSize(100)
    Asteroid():setPosition(-600, -250):setSize(100)

    local utility_beam = getEmitterUtilityBeam(player_ship)
    incremental_effect = 0

    if utility_beam then
        player_ship
            :addCustomUtilityBeamMode(
                -- name, energy_per_sec, heat_per_sec, requires_target,
                "Pull",
                5.0,
                0.02,
                true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)

                    if not can_fire then
                        return
                    end

                    local drag_distance, position_x, position_y, target_position_x, target_position_y, norm =
                        tractorBeamSetup(
                            beam_emitter,
                            beam_target,
                            emitter_utility_beam_energy_use_per_delta,
                            getUtilityBeamHeatRate(beam_emitter),
                            emitter_utility_beam_effectiveness,
                            distance,
                            angle_diff
                        )

                    if drag_distance <= 0 then
                        emitter_utility_beam.is_firing = false
                        return
                    end
                    emitter_utility_beam.is_firing = true

                    -- Pull mode: move target toward emitter
                    local destination = { x = position_x, y = position_y }

                    if distance <= 1.1 * global_delta / drag_distance then
                        if
                            beam_emitter.components.docking_bay
                            and beam_target.components.docking_port
                        then
                            if beam_target:getDockingState() < 1 then
                                -- If dockable and within docking range, dock
                                commandDock(beam_target, beam_emitter)
                                return
                            else
                                -- Already docking, so leave it alone
                                return
                            end
                        end
                    end

                    tractorBeamMove(
                        beam_emitter,
                        beam_target,
                        target_position_x,
                        target_position_y,
                        destination,
                        drag_distance
                    )
                    -- end callback
                end
            )
            :addCustomUtilityBeamMode(
                -- name, energy_per_sec, heat_per_sec, requires_target,
                "Push",
                5.0,
                0.02,
                true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)

                    if not can_fire then
                        return
                    end

                    local drag_distance, position_x, position_y, target_position_x, target_position_y, norm =
                        tractorBeamSetup(
                            beam_emitter,
                            beam_target,
                            emitter_utility_beam_energy_use_per_delta,
                            getUtilityBeamHeatRate(beam_emitter),
                            emitter_utility_beam_effectiveness,
                            distance,
                            angle_diff
                        )

                    if drag_distance <= 0 then
                        emitter_utility_beam.is_firing = false
                        return
                    end
                    emitter_utility_beam.is_firing = true

                    -- Push mode: move target away from emitter
                    local destination = {
                        x = position_x
                            + norm.x * emitter_utility_beam.range * 1.2,
                        y = position_y
                            + norm.y * emitter_utility_beam.range * 1.2,
                    }

                    tractorBeamMove(
                        beam_emitter,
                        beam_target,
                        target_position_x,
                        target_position_y,
                        destination,
                        drag_distance
                    )
                    -- end callback
                end
            )
            :addCustomUtilityBeamMode(
                -- name, energy_per_sec, heat_per_sec, requires_target,
                "Hold",
                5.0,
                0.02,
                true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)

                    if not can_fire then
                        return
                    end

                    -- Hold mode: move target to coordinates at the same relative angle and relative distance from the emitter that the target had when the beam was first activated
                    -- On first activation or if the target has changed, record the relative offset of the target from the emitter
                    if
                        beam_emitter.hold_target ~= beam_target
                        or beam_emitter.hold_rel_x == nil
                    then
                        local emitter_x, emitter_y = beam_emitter:getPosition()
                        local target_x, target_y = beam_target:getPosition()
                        beam_emitter.hold_rel_x = target_x - emitter_x
                        beam_emitter.hold_rel_y = target_y - emitter_y
                        beam_emitter.hold_target = beam_target
                    end

                    local drag_distance, position_x, position_y, target_position_x, target_position_y, norm =
                        tractorBeamSetup(
                            beam_emitter,
                            beam_target,
                            emitter_utility_beam_energy_use_per_delta,
                            getUtilityBeamHeatRate(beam_emitter),
                            emitter_utility_beam_effectiveness,
                            distance,
                            angle_diff
                        )

                    if drag_distance <= 0 then
                        emitter_utility_beam.is_firing = false
                        return
                    end
                    emitter_utility_beam.is_firing = true

                    local destination = {
                        x = position_x + beam_emitter.hold_rel_x,
                        y = position_y + beam_emitter.hold_rel_y,
                    }

                    tractorBeamMove(
                        beam_emitter,
                        beam_target,
                        target_position_x,
                        target_position_y,
                        destination,
                        drag_distance
                    )
                    -- end callback
                end
            )
            :addCustomUtilityBeamMode(
                -- name, energy_per_sec, heat_per_sec, requires_target,
                "Reposition",
                5.0,
                0.02,
                true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)

                    if not can_fire then
                        return
                    end

                    local drag_distance, position_x, position_y, target_position_x, target_position_y, norm =
                        tractorBeamSetup(
                            beam_emitter,
                            beam_target,
                            emitter_utility_beam_energy_use_per_delta,
                            getUtilityBeamHeatRate(beam_emitter),
                            emitter_utility_beam_effectiveness,
                            distance,
                            angle_diff
                        )

                    if drag_distance <= 0 then
                        emitter_utility_beam.is_firing = false
                        return
                    end
                    emitter_utility_beam.is_firing = true

                    local tractor_heading = utility_beam.bearing
                        + beam_emitter:getHeading()
                    while tractor_heading > 360.0 do
                        tractor_heading = tractor_heading - 360.0
                    end
                    while tractor_heading < 0.0 do
                        tractor_heading = tractor_heading + 360.0
                    end
                    local tractor_vector_x, tractor_vector_y = vectorFromAngle(
                        tractor_heading,
                        utility_beam.range,
                        true
                    )

                    -- Push mode: move target away from emitter
                    local destination = {
                        x = position_x + tractor_vector_x,
                        y = position_y + tractor_vector_y,
                    }

                    tractorBeamMove(
                        beam_emitter,
                        beam_target,
                        target_position_x,
                        target_position_y,
                        destination,
                        drag_distance
                    )
                end
            )
            :addCustomUtilityBeamMode(
                --    name, energy_per_sec, heat_per_sec, requires_target,
                "Energize",
                5.0,
                0.02,
                true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)

                    if can_fire and beam_target.components.reactor then
                        emitter_utility_beam.is_firing = true
                        beam_target:setEnergy(
                            beam_target:getEnergy()
                                + emitter_utility_beam.energy_use_per_second
                                    * global_delta
                        )
                        beam_emitter:setSystemHeat(
                            "utilitybeam",
                            beam_emitter:getSystemHeat("utilitybeam")
                                + getUtilityBeamHeatRate(beam_emitter)
                                    * global_delta
                        )
                    else
                        emitter_utility_beam.is_firing = false
                    end
                end
            )
            :addCustomUtilityBeamMode(
                --         name, energy_per_sec, heat_per_sec, requires_target,
                "Siphon energy",
                5.0,
                0.05,
                true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    if not beam_emitter.components.reactor then
                        return
                    end

                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)
                    local drain_amount = getUtilityBeamHeatRate(beam_emitter)
                        * 100
                        * global_delta

                    if can_fire and beam_target:getEnergy() > drain_amount then
                        -- log("beam_target:getEnergy():", beam_target:getEnergy(), "beam_target:getMaxEnergy():", beam_target:getMaxEnergy())
                        emitter_utility_beam.is_firing = true
                        beam_target:setEnergy(
                            beam_target:getEnergy() - drain_amount
                        )
                        beam_emitter:setEnergy(
                            beam_emitter:getEnergy() + drain_amount
                        )
                        beam_emitter:setSystemHeat(
                            "utilitybeam",
                            beam_emitter:getSystemHeat("utilitybeam")
                                + getUtilityBeamHeatRate(beam_emitter)
                                    * global_delta
                        )
                    else
                        emitter_utility_beam.is_firing = false
                    end
                end
            )
            :addCustomUtilityBeamMode(
                --         name, energy_per_sec, heat_per_sec, requires_target,
                "Give missile",
                5.0,
                0.05,
                true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)

                    if
                        can_fire
                        and beam_target.components.mounts
                        and beam_emitter.components.mounts
                        and beam_target:isFriendly(beam_emitter)
                    then
                        transferHomingMissile(
                            beam_emitter,
                            "Give missile",
                            beam_emitter,
                            beam_target,
                            emitter_utility_beam,
                            emitter_utility_beam_effectiveness,
                            emitter_utility_beam_energy_use_per_delta
                        )
                    end

                    if emitter_utility_beam.is_firing == true then
                        -- log("Player giving missile to target")
                    end
                end
            )
            :addCustomUtilityBeamMode(
                --         name, energy_per_sec, heat_per_sec, requires_target,
                "Take missile",
                5.0,
                0.05,
                true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)

                    if
                        can_fire
                        and beam_target.components.mounts
                        and beam_emitter.components.mounts
                    then
                        transferHomingMissile(
                            beam_emitter,
                            "Take missile",
                            beam_target,
                            beam_emitter,
                            emitter_utility_beam,
                            emitter_utility_beam_effectiveness,
                            emitter_utility_beam_energy_use_per_delta
                        )
                    end

                    if emitter_utility_beam.is_firing == true then
                        -- log("Player taking missile from target")
                    end
                end
            )
            :addCustomUtilityBeamMode(
                --         name, energy_per_sec, heat_per_sec, requires_target,
                "Mine asteroid",
                12.5,
                0.25,
                true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)

                    if
                        can_fire
                        and isObjectType(beam_target, "Asteroid") == true
                        and beam_target.can_be_mined == true
                    then
                        log("Inside mine asteroid - isObjectType Asteroid is true")
                        -- Beam strength = amount mined per 10 seconds
                        local amount_mined_per_tick = emitter_utility_beam.strength
                            * 0.01
                            * emitter_utility_beam_effectiveness
                            * global_delta
                        local hull = beam_emitter.components.hull

                        if hull then
                            log("- Hull component check passed. hull.current = " .. hull.current .. " hull.max = " .. hull.max)

                            if hull.current < hull.max then
                                beam_emitter:setEnergy(
                                    beam_emitter:getEnergy()
                                        - emitter_utility_beam_energy_use_per_delta
                                )
                                beam_emitter:setSystemHeat(
                                    "utilitybeam",
                                    beam_emitter:getSystemHeat("utilitybeam")
                                        + getUtilityBeamHeatRate(beam_emitter)
                                            * beam_emitter:getSystemPower(
                                                "utilitybeam"
                                            )
                                            * global_delta
                                )
                                emitter_utility_beam.is_firing = true

                                local asteroid_size = beam_target:getSize()

                                if amount_mined_per_tick > asteroid_size then
                                    incremental_effect = incremental_effect
                                        + asteroid_size
                                    log("- amount_mined: " .. incremental_effect .. " and asteroid destroyed")
                                    beam_target:destroy()
                                else
                                    incremental_effect = incremental_effect
                                        + amount_mined_per_tick
                                    log("- amount_mined: " .. incremental_effect .. ", asteroid_size: " .. asteroid_size)
                                    beam_target:setSize(
                                        asteroid_size - amount_mined_per_tick
                                    )
                                end

                                if incremental_effect > 1 then
                                    incremental_effect = incremental_effect - 1
                                    hull.current = hull.current + 0.1
                                    log("- amount_mined: " .. incremental_effect .. " after repairing hull")
                                end
                            else
                                log("- Hull component capacity check failed. hull.current = " .. hull.current .. " hull.max = " .. hull.max)
                                emitter_utility_beam.is_firing = false
                            end
                        else
                            log("- Hull component presence check failed.")
                            emitter_utility_beam.is_firing = false
                        end
                    else
                        log("Inside mine asteroid - isObjectType Asteroid is false")
                        emitter_utility_beam.is_firing = false
                    end
                end
                -- Improvements: Track affected asteroids for progress bar
            )
            --[[ transferPlayersToShip is buggy
            :addCustomUtilityBeamMode(
                "Take over weapons", 1.0, 1.0, true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if can_fire then
                        beam_emitter:transferPlayersAtPositionToShip("weapons", beam_target)
                    end
                end
            )
            ]]
            --
            :addCustomUtilityBeamMode(
                "Send repair crew",
                1.0,
                1.0,
                true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)

                    if can_fire and beam_target.components.internal_rooms then
                        transferRepairCrew(
                            beam_emitter,
                            "Send repair crew",
                            beam_emitter,
                            beam_target,
                            emitter_utility_beam,
                            emitter_utility_beam_effectiveness,
                            emitter_utility_beam_energy_use_per_delta
                        )
                    end

                    --[[ if emitter_utility_beam.is_firing == true then
                        log("Player sending repair crew to target")
                    end ]]
                end
            )
            :addCustomUtilityBeamMode(
                "Receive repair crew",
                1.0,
                1.0,
                true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)

                    if can_fire and beam_target:getRepairCrewCount() > 0 then
                        transferRepairCrew(
                            beam_emitter,
                            "Receive repair crew",
                            beam_target,
                            beam_emitter,
                            emitter_utility_beam,
                            emitter_utility_beam_effectiveness,
                            emitter_utility_beam_energy_use_per_delta
                        )
                    end

                    if emitter_utility_beam.is_firing == true then
                        log("Player receiving repair crew from target")
                    end
                end
            )
            :addCustomUtilityBeamMode(
                "Capture (player)",
                1.0,
                1.0,
                true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)

                    if can_fire then
                        convertFaction(
                            beam_emitter,
                            "Capture (player)",
                            beam_target,
                            emitter_utility_beam,
                            emitter_utility_beam_effectiveness,
                            emitter_utility_beam_energy_use_per_delta
                        )
                    end
                end
            )
            :addCustomUtilityBeamMode(
                "Capture (Kraylor)",
                1.0,
                1.0,
                true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)

                    if can_fire then
                        convertFaction(
                            beam_emitter,
                            "Capture (Kraylor)",
                            beam_target,
                            emitter_utility_beam,
                            emitter_utility_beam_effectiveness,
                            emitter_utility_beam_energy_use_per_delta,
                            1.0,
                            "Kraylor"
                        )
                    end
                end
            )
            :addCustomUtilityBeamMode(
                "Disrupt homing",
                1.0,
                1.0,
                true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)

                    if not can_fire then
                        return
                    end
                    if beam_target.components.missile_homing == nil then
                        return
                    end

                    beam_target.components.missile_homing.target_angle = beam_target.components.missile_homing.target_angle
                        + 180 * emitter_utility_beam_effectiveness

                    beam_emitter:setEnergy(
                        beam_emitter:getEnergy()
                            - emitter_utility_beam_energy_use_per_delta
                    )

                    beam_emitter:setSystemHeat(
                        "utilitybeam",
                        beam_emitter:getSystemHeat("utilitybeam")
                            + getUtilityBeamHeatRate(beam_emitter)
                                * beam_emitter:getSystemPower("utilitybeam")
                                * global_delta
                    )

                    emitter_utility_beam.is_firing = true
                end
            )
            :addCustomUtilityBeamMode(
                "Disrupt radar",
                1.0,
                0.001,
                false,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)

                    if can_fire then
                        beam_emitter:setEnergy(
                            beam_emitter:getEnergy()
                                - emitter_utility_beam_energy_use_per_delta
                        )
                        beam_emitter:setSystemHeat(
                            "utilitybeam",
                            beam_emitter:getSystemHeat("utilitybeam")
                                + getUtilityBeamHeatRate(beam_emitter)
                                    * beam_emitter:getSystemPower("utilitybeam")
                                    * global_delta
                        )
                        -- log("Generating radar disruption")

                        if emitter_utility_beam_effectiveness > 0.0 then
                            emitter_utility_beam.is_firing = true
                            beam_target.components.warp_jammer = nil
                            beam_target.components = {
                                radar_trace = {
                                    icon = "radar/blip.png",
                                    radius = 120.0,
                                    rotate = false,
                                    color_by_faction = true,
                                },
                                radar_block = {
                                    range = 1000
                                        * emitter_utility_beam_effectiveness,
                                    behind = true,
                                },
                            }
                        end
                    else
                        beam_target.components.radar_trace = nil
                        beam_target.components.radar_block = nil
                        beam_target.components.warp_jammer = nil -- Avoid carrying over Interdict component
                    end
                end
            )
            :addCustomUtilityBeamMode(
                "Interdict",
                1.0,
                0.001,
                false,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)

                    if can_fire then
                        beam_emitter:setEnergy(
                            beam_emitter:getEnergy()
                                - emitter_utility_beam_energy_use_per_delta
                        )
                        beam_emitter:setSystemHeat(
                            "utilitybeam",
                            beam_emitter:getSystemHeat("utilitybeam")
                                + getUtilityBeamHeatRate(beam_emitter)
                                    * beam_emitter:getSystemPower("utilitybeam")
                                    * global_delta
                        )
                        -- log("Generating warp/jump disruption")

                        if emitter_utility_beam_effectiveness > 0.0 then
                            emitter_utility_beam.is_firing = true
                            beam_target.components.radar_block = nil
                            beam_target.components = {
                                radar_trace = {
                                    icon = "radar/blip.png",
                                    radius = 120.0,
                                    rotate = false,
                                    color_by_faction = true,
                                },
                                warp_jammer = {
                                    range = 1000
                                        * emitter_utility_beam_effectiveness,
                                },
                            }
                        end
                    else
                        beam_target.components.radar_trace = nil
                        beam_target.components.warp_jammer = nil
                        beam_target.components.radar_block = nil -- Avoid carrying over Disrupt radar component
                    end
                end
            )
            :addCustomUtilityBeamMode(
                "Harmonize freq.",
                1.0,
                1.0,
                true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)
                    local target_shields = beam_target.components.shields
                    local emitter_beam_weapons =
                        beam_emitter.components.mounts
                    if can_fire and target_shields and emitter_beam_weapons then
                        -- Initialize harmonization progress counter if necessary
                        if beam_target.harmonize_progress == nil then
                            beam_target.harmonize_progress = 0
                        end

                        -- Each tick counts toward the harmonization threshold while generating heat and consuming energy
                        local harmonize_progress_per_tick = emitter_utility_beam.strength
                            * 0.001
                            * emitter_utility_beam_effectiveness
                            * global_delta
                        beam_target.harmonize_progress = beam_target.harmonize_progress
                            + harmonize_progress_per_tick
                        beam_emitter:setEnergy(
                            beam_emitter:getEnergy()
                                - emitter_utility_beam_energy_use_per_delta
                        )
                        beam_emitter:setSystemHeat(
                            "utilitybeam",
                            beam_emitter:getSystemHeat("utilitybeam")
                                + getUtilityBeamHeatRate(beam_emitter)
                                    * beam_emitter:getSystemPower("utilitybeam")
                                    * global_delta
                        )
                        beam_emitter:setCustomUtilityBeamModeProgress(
                            "Harmonize freq.",
                            beam_target.harmonize_progress
                        )

                        -- If the threshold is reached in this tick, step the beam frequency toward the optimal
                        if beam_target.harmonize_progress >= 1.0 then
                            emitter_utility_beam.is_firing = true
                            -- Find the beam frequency that deals maximum damage to the target's shield frequency
                            local best_freq = 0
                            local best_factor =
                                beamVsShieldFrequencyDamageFactor(
                                    0,
                                    target_shields.frequency
                                )
                            for freq = 1, 20 do
                                local factor =
                                    beamVsShieldFrequencyDamageFactor(
                                        freq,
                                        target_shields.frequency
                                    )
                                if factor > best_factor then
                                    best_factor = factor
                                    best_freq = freq
                                end
                            end
                            -- Step one frequency toward the optimal, wrapping around to find the shortest path
                            local freq_range = 21 -- 0..20 inclusive
                            local current_freq = emitter_beam_weapons.frequency
                            local steps_up = (
                                best_freq
                                - current_freq
                                + freq_range
                            ) % freq_range
                            local steps_down = (
                                current_freq
                                - best_freq
                                + freq_range
                            ) % freq_range
                            if steps_up <= steps_down then
                                emitter_beam_weapons.frequency = (
                                    current_freq + 1
                                )
                                    % freq_range
                            else
                                emitter_beam_weapons.frequency = (
                                    current_freq
                                    - 1
                                    + freq_range
                                )
                                    % freq_range
                            end
                            beam_target.harmonize_progress = 0
                            beam_emitter:setCustomUtilityBeamModeProgress(
                                "Harmonize freq.",
                                0
                            )
                        else
                            emitter_utility_beam.is_firing = false
                        end
                    else
                        emitter_utility_beam.is_firing = false
                    end
                end, -- Callback while active
                -- Start deactivation callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    -- Reset all entities' harmonize progress and clear the progress bar
                    if beam_target.harmonize_progress ~= nil then
                        beam_target.harmonize_progress = nil
                    end
                    beam_emitter:setCustomUtilityBeamModeProgress(
                        "Harmonize freq.",
                        0
                    )
                end -- Deactivation callback
            )
            :addCustomUtilityBeamMode(
                "Jump tow",
                1.0,
                1.0,
                true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)
                    local jd = beam_emitter.components.jump_drive

                    if can_fire and jd and jd.delay > 0 then
                        -- Jump countdown is active: track this target with its relative position
                        if beam_emitter.jump_tow_targets == nil then
                            beam_emitter.jump_tow_targets = {}
                        end
                        local emitter_x, emitter_y = beam_emitter:getPosition()
                        local target_x, target_y = beam_target:getPosition()
                        local rel_x = target_x - emitter_x
                        local rel_y = target_y - emitter_y
                        -- Update existing entry or insert new one
                        local found = false
                        for _, data in ipairs(beam_emitter.jump_tow_targets) do
                            if data.entity == beam_target then
                                data.rel_x = rel_x
                                data.rel_y = rel_y
                                found = true
                                break
                            end
                        end
                        if not found then
                            table.insert(beam_emitter.jump_tow_targets, {
                                entity = beam_target,
                                rel_x = rel_x,
                                rel_y = rel_y,
                            })
                        end
                        beam_emitter:setEnergy(
                            beam_emitter:getEnergy()
                                - emitter_utility_beam_energy_use_per_delta
                        )
                        beam_emitter:setSystemHeat(
                            "utilitybeam",
                            beam_emitter:getSystemHeat("utilitybeam")
                                + getUtilityBeamHeatRate(beam_emitter)
                                    * beam_emitter:getSystemPower("utilitybeam")
                                    * global_delta
                        )
                        emitter_utility_beam.is_firing = true
                    else
                        emitter_utility_beam.is_firing = false
                    end
                end
            )
            :addCustomUtilityBeamMode(
                "Scan",
                1.0,
                1.0,
                true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)
                    local faction_name = beam_emitter:getFaction()
                    if
                        can_fire
                        and faction_name
                        and not beam_target:isFullyScannedBy(beam_emitter)
                    then
                        -- Initialize scan progress counter if necessary
                        if beam_target.scan_progress == nil then
                            beam_target.scan_progress = 0
                        end

                        -- Each tick counts toward the scan threshold while generating heat and consuming energy
                        local scan_progress_per_tick = emitter_utility_beam.strength
                            * 0.001
                            * emitter_utility_beam_effectiveness
                            * global_delta
                        beam_target.scan_progress = beam_target.scan_progress
                            + scan_progress_per_tick
                        beam_emitter:setEnergy(
                            beam_emitter:getEnergy()
                                - emitter_utility_beam_energy_use_per_delta
                        )
                        beam_emitter:setSystemHeat(
                            "utilitybeam",
                            beam_emitter:getSystemHeat("utilitybeam")
                                + getUtilityBeamHeatRate(beam_emitter)
                                    * beam_emitter:getSystemPower("utilitybeam")
                                    * global_delta
                        )
                        beam_emitter:setCustomUtilityBeamModeProgress(
                            "Scan",
                            beam_target.scan_progress
                        )

                        -- If the threshold is reached in this tick, advance the scan state
                        if beam_target.scan_progress >= 1.0 then
                            emitter_utility_beam.is_firing = true
                            if beam_target:isScannedBy(beam_emitter) then
                                beam_target:setScanStateByFaction(
                                    faction_name,
                                    "full"
                                )
                            else
                                beam_target:setScanStateByFaction(
                                    faction_name,
                                    "simple"
                                )
                            end
                            beam_target.scan_progress = 0
                            beam_emitter:setCustomUtilityBeamModeProgress(
                                "Scan",
                                0
                            )
                            print(
                                "This is the custom beam mode Scan "
                                        .. beam_emitter:getCallSign()
                                        .. " changes the scanned status of "
                                        .. beam_target:getCallSign()
                                    or "unknown entity"
                            )
                            if
                                beam_target:isFullyScannedBy(beam_emitter)
                                == true
                            then
                                print(
                                    "beam_target:isFullyScannedBy(beam_emitter): true"
                                )
                            end
                        else
                            emitter_utility_beam.is_firing = false
                        end
                    else
                        emitter_utility_beam.is_firing = false
                    end
                end
            )
            :addCustomUtilityBeamMode(
                "Repair",
                1.0,
                1.0,
                true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta =
                        checkBeamCapability(beam_emitter)
                    local hull = beam_target.components.hull

                    if can_fire and hull then
                        if hull.current < hull.max then
                            beam_emitter:setEnergy(
                                beam_emitter:getEnergy()
                                    - emitter_utility_beam_energy_use_per_delta
                            )
                            beam_emitter:setSystemHeat(
                                "utilitybeam",
                                beam_emitter:getSystemHeat("utilitybeam")
                                    + getUtilityBeamHeatRate(beam_emitter)
                                        * beam_emitter:getSystemPower(
                                            "utilitybeam"
                                        )
                                        * global_delta
                            )
                            emitter_utility_beam.is_firing = true

                            hull.current =
                                math.min(hull.max, hull.current + 0.1)
                            -- log("- Hull repaired. hull.current = " .. hull.current .. " hull.max = " .. hull.max)
                        else
                            -- log("- Hull component capacity check failed. hull.current = " .. hull.current .. " hull.max = " .. hull.max)
                            emitter_utility_beam.is_firing = false
                        end
                    else
                        -- log("- Hull component presence check failed.")
                        emitter_utility_beam.is_firing = false
                    end
                end
            )
    -- getPlayerShip(-1):addCustomUtilityBeamMode("wango", 1.0, 1.0, function(beam_emitter, beam_target, distance, angle_diff) print("This is the custom beam mode wango " .. beam_emitter:getCallSign() .. " zaps " .. beam_target:getCallSign() or "unknown entity") end)
    else
        log("Error: Player ship does not have a 'utility_beam' component.")
    end

    addGMFunction(_("buttonGM", "Random asteroid field"), function()
        cleanup()
        for n = 1, 1000 do
            Asteroid()
                :setPosition(random(-50000, 50000), random(-50000, 50000))
                :setSize(random(100, 500))
            VisualAsteroid()
                :setPosition(random(-50000, 50000), random(-50000, 50000))
                :setSize(random(100, 500))
        end
    end)
    addGMFunction(_("buttonGM", "Random nebula field"), function()
        cleanup()
        for n = 1, 50 do
            Nebula():setPosition(random(-50000, 50000), random(-50000, 50000))
        end
    end)
    addGMFunction(_("buttonGM", "Delete unselected"), function()
        local gm_selection = getGMSelection()
        for idx, obj in ipairs(getAllObjects()) do
            local found = false
            for idx2, obj2 in ipairs(gm_selection) do
                if obj == obj2 then
                    found = true
                end
            end
            if not found then
                obj:destroy()
            end
        end
    end)
end

function cleanup()
    -- Clean up the current play field. Find all objects and destroy everything that is not a player.
    -- If it is a player, position him in the center of the scenario.
    for idx, obj in ipairs(getAllObjects()) do
        if isObjectType(obj, "PlayerSpaceship") then
            obj:setPosition(random(-100, 100), random(-100, 100))
        else
            obj:destroy()
        end
    end
end

function update(delta)
    -- No victory condition
    global_delta = delta

    -- Jump tow: detect when a tracked emitter completes a jump and transport towed entities
    if player_ship ~= nil and player_ship:isValid() then
        local jd = player_ship.components.jump_drive
        if jd then
            local prev = player_ship.jump_tow_prev_just_jumped or 0
            local curr = jd.just_jumped
            -- A successful jump sets just_jumped to 2.0; an aborted jump sets it to at most ~1.1.
            -- Detect the transition to a successful jump (threshold 1.9 avoids ambiguity after
            -- one frame of delta has been subtracted from the initial 2.0 value).
            if
                curr > prev
                and curr >= 1.9
                and player_ship.jump_tow_targets ~= nil
            then
                local emitter_x, emitter_y = player_ship:getPosition()
                for _, data in ipairs(player_ship.jump_tow_targets) do
                    if data.entity ~= nil and data.entity:isValid() then
                        data.entity:setPosition(
                            emitter_x + data.rel_x,
                            emitter_y + data.rel_y
                        )
                    end
                end
                player_ship.jump_tow_targets = nil
            elseif jd.delay == 0 and curr <= 0 then
                -- No jump armed or in effect; discard any stale tracking data
                player_ship.jump_tow_targets = nil
            end
            player_ship.jump_tow_prev_just_jumped = curr
        end
    end
end

function tractorBeamSetup(
    beam_emitter,
    beam_target,
    energy_per_delta,
    heat_per_sec,
    emitter_utility_beam_effectiveness,
    distance,
    angle_diff
)
    local utility_beam = getEmitterUtilityBeam(beam_emitter)

    -- Don't bother if physics are static.
    -- TODO Check for redundancy with distance and angle_diff params
    local target_physics = beam_target.components.physics
    local hit_location = { x = 0, y = 0 }
    if target_physics and target_physics.type == "static" then
        return 0,
            position_x,
            position_y,
            target_position_x,
            target_position_y,
            hit_location
    end

    -- Get positions and other relevant components
    local position_x, position_y = beam_emitter:getPosition()
    local target_position_x, target_position_y = beam_target:getPosition()
    local shields = beam_target.components.shields
    local hull = beam_target.components.hull
    local impulse = beam_target.components.impulse_engine
    local missile = beam_target.components.missile_flight
    local target_mass = 1.0
    local dx = target_position_x - position_x
    local dy = target_position_y - position_y
    local len = math.sqrt(dx ^ 2 + dy ^ 2)
    local norm = { x = dx / len, y = dy / len }
    local reactor = beam_emitter.components.reactor
    local coolant = beam_emitter.components.coolant

    -- If emitter has a reactor, consume energy
    -- If we don't have enough energy, don't do anything
    if reactor then
        if beam_emitter:getEnergy() < energy_per_delta then
            return 0,
                position_x,
                position_y,
                target_position_x,
                target_position_y,
                { x = 0, y = 0 }
        end

        -- log("Consuming energy " .. energy_per_delta)
        local new_energy = beam_emitter:getEnergy() - energy_per_delta

        if new_energy < 0 then
            new_energy = 0
        end

        beam_emitter:setEnergy(new_energy)
    end

    -- If emitter uses coolant, generate heat
    if coolant then
        -- log("Adding utility beam system heat " .. heat_per_sec * global_delta)
        beam_emitter:setSystemHeat(
            "utilitybeam",
            beam_emitter:getSystemHeat("utilitybeam")
                + heat_per_sec * global_delta
        )
    end

    -- Calculate shield effectiveness against tractor and add to mass
    if shields and shields.active then
        local shield_index = 1
        if beam_target:getShieldCount() > 1 then
            if target_physics then
                -- Identify the hit location for shield determination
                hit_location.x = target_position_x
                hit_location.y = target_position_y

                if len > 0 then
                    hit_location.x = hit_location.x
                        - norm.x * target_physics.size -- TODO fix size calc
                    hit_location.y = hit_location.y
                        - norm.y * target_physics.size
                end
            end

            -- Calculate shield angle
            local function vec2ToAngle(vec)
                return math.deg(math.atan2(vec.y, vec.x))
            end
            local function angleDifference(a, b)
                local diff = a - b
                while diff < -180 do
                    diff = diff + 360
                end
                while diff > 180 do
                    diff = diff - 360
                end
                return diff
            end
            local shield_angle = angleDifference(
                beam_target:getRotation(),
                vec2ToAngle({
                    x = hit_location.x - target_position_x,
                    y = hit_location.y - target_position_y,
                })
            )
            while shield_angle < 0 do
                shield_angle = shield_angle + 360
            end
            local shield_arc = 360.0 / beam_target:getShieldCount()
            shield_index = (
                math.floor((shield_angle + shield_arc / 2.0) / shield_arc)
                % beam_target:getShieldCount()
            ) + 1
        end

        target_mass = target_mass
            + (beam_target:getShieldLevel(shield_index) or 0)
    end

    local target_force = 0
    if impulse then
        target_force = (beam_target:getSystemHealth("impulse") or 1)
            * (beam_target:getAcceleration() or 0)
    elseif missile then
        target_force = missile.speed or 0
    end

    if hull and hull.current > 0 then
        target_mass = target_mass + hull.current * 5.0
    end

    -- Drag calculations
    local drag_capability = utility_beam.strength
        * emitter_utility_beam_effectiveness
    -- log("drag_capability: " .. drag_capability)
    target_force = target_mass
    local effective_drag_capability = math.max(
        0.1,
        (
            drag_capability - target_force == 0 and 0
            or (drag_capability - target_force) / drag_capability
        )
    )
    local drag_distance = math.min(
        distance,
        effective_drag_capability * drag_capability
    ) * global_delta

    return drag_distance,
        position_x,
        position_y,
        target_position_x,
        target_position_y,
        norm
end

function tractorBeamMove(
    beam_emitter,
    beam_target,
    target_position_x,
    target_position_y,
    destination,
    drag_distance
)
    -- Move the tractored object to the destination
    local dx = target_position_x - destination.x
    local dy = target_position_y - destination.y

    if math.abs(dx) > 0.01 or math.abs(dy) > 0.01 then
        local len = math.sqrt(dx ^ 2 + dy ^ 2)

        if len > 0 then
            local move = {
                x = drag_distance * (dx / len),
                y = drag_distance * (dy / len),
            }
            beam_target:setPosition(
                target_position_x - move.x,
                target_position_y - move.y
            )
        end
    end
end
