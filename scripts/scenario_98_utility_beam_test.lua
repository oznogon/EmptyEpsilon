-- Name: Utility beam test
-- Description: Test utility beam system functions
-- Type: Development

--- Scenario
-- @script scenario_98_utility_beam_test

require("utils.lua")

function checkBeamCapability(beam_emitter)
    local emitter_utility_beam = beam_emitter.components.utility_beam
    local emitter_utility_beam_effectiveness = math.max(beam_emitter:getSystemHealth("utilitybeam"), 0.0) * beam_emitter:getSystemPower("utilitybeam")
    local emitter_utility_beam_energy_use_per_delta = beam_emitter:getSystemPower("utilitybeam") * emitter_utility_beam.energy_use_per_second * global_delta
    local can_fire = true

    if emitter_utility_beam_effectiveness <= 0.0 or beam_emitter:getEnergy() < emitter_utility_beam_energy_use_per_delta then
        log("X Utility beam can't fire, no effect, health:", beam_emitter:getSystemHealth("utilitybeam"), " energy:", beam_emitter:getEnergy())
        emitter_utility_beam.is_firing = false
        can_fire = false
    end

    return can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta
end

function transferHomingMissile(beam_emitter, mode_name, sending_entity, receiving_entity, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta, threshold)
    threshold = threshold or 1.0
    if receiving_entity.components.missile_tubes.storage_homing < receiving_entity.components.missile_tubes.max_homing and sending_entity.components.missile_tubes.storage_homing > 0 then
        -- Initialize restocking tick counter if necessary
        if receiving_entity.amount_restocked == nil then receiving_entity.amount_restocked = 0 end

        -- Each tick counts down toward a successful transfer while generating heat and consuming energy
        local amount_restocked_per_tick = emitter_utility_beam.strength * 0.001 * emitter_utility_beam_effectiveness * global_delta
        receiving_entity.amount_restocked = receiving_entity.amount_restocked + amount_restocked_per_tick
        beam_emitter:setEnergy(beam_emitter:getEnergy() - emitter_utility_beam_energy_use_per_delta)
        beam_emitter:setSystemHeat("utilitybeam", beam_emitter:getSystemHeat("utilitybeam") + emitter_utility_beam.heat_add_rate_per_second * beam_emitter:getSystemPower("utilitybeam") * global_delta)
        beam_emitter:setCustomUtilityBeamModeProgress(mode_name, receiving_entity.amount_restocked)

        -- If the threshold is reached in this tick, fire the beam and send a missile over
        if receiving_entity.amount_restocked >= threshold then
            emitter_utility_beam.is_firing = true
            sending_entity.components.missile_tubes.storage_homing = sending_entity.components.missile_tubes.storage_homing - 1
            receiving_entity.components.missile_tubes.storage_homing = receiving_entity.components.missile_tubes.storage_homing + 1
            receiving_entity.amount_restocked = receiving_entity.amount_restocked - 1
            beam_emitter:setCustomUtilityBeamModeProgress(mode_name, 0)
            -- log("Sender transferred 1 homing missile to receiver. Sender:", sending_entity.components.missile_tubes.storage_homing, "receiver:", receiving_entity.components.missile_tubes.storage_homing)
        else
            emitter_utility_beam.is_firing = false
        end
    else
        emitter_utility_beam.is_firing = false
    end
end

function transferRepairCrew(beam_emitter, mode_name, sending_entity, receiving_entity, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta, threshold)
    threshold = threshold or 1.0
    if receiving_entity.components.internal_rooms and sending_entity:getRepairCrewCount() > 0 then
        -- Initialize restocking tick counter if necessary
        if receiving_entity.transfer_progress == nil then receiving_entity.transfer_progress = 0 end

        -- Each tick counts down toward a successful transfer while generating heat and consuming energy
        local transfer_progress_per_tick = emitter_utility_beam.strength * 0.001 * emitter_utility_beam_effectiveness * global_delta
        receiving_entity.transfer_progress = receiving_entity.transfer_progress + transfer_progress_per_tick
        beam_emitter:setEnergy(beam_emitter:getEnergy() - emitter_utility_beam_energy_use_per_delta)
        beam_emitter:setSystemHeat("utilitybeam", beam_emitter:getSystemHeat("utilitybeam") + emitter_utility_beam.heat_add_rate_per_second * beam_emitter:getSystemPower("utilitybeam") * global_delta)
        beam_emitter:setCustomUtilityBeamModeProgress(mode_name, receiving_entity.transfer_progress)

        -- If the threshold is reached in this tick, fire the beam and send a missile over
        if receiving_entity.transfer_progress >= threshold then
            emitter_utility_beam.is_firing = true
            sending_entity:setRepairCrewCount(sending_entity:getRepairCrewCount() - 1)
            receiving_entity:setRepairCrewCount(receiving_entity:getRepairCrewCount() + 1)
            receiving_entity.transfer_progress = receiving_entity.transfer_progress - 1
            beam_emitter:setCustomUtilityBeamModeProgress(mode_name, 0)
            -- log("Sender transferred 1 repair crew to receiver. Sender:", sending_entity:getRepairCrewCount(), "receiver:", receiving_entity:getRepairCrewCount())
        else
            emitter_utility_beam.is_firing = false
        end
    else
        emitter_utility_beam.is_firing = false
    end
end

function convertFaction(beam_emitter, mode_name, target_entity, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta, threshold, new_faction)
    -- Initialize threshold and default destination faction to the beam emitter's faction
    threshold = threshold or 1.0
    new_faction = new_faction or beam_emitter:getFaction()

    -- Change the target's faction only if the target entity's faction differs from the destination faction
    if target_entity:getFaction() ~= new_faction then
        -- Initialize progress tick counter if necessary
        if target_entity.faction_change_progress == nil then target_entity.faction_change_progress = 0 end

        -- Each tick counts down toward a successful conversion while generating heat and consuming energy
        local change_progress_per_tick = emitter_utility_beam.strength * 0.001 * emitter_utility_beam_effectiveness * global_delta
        target_entity.faction_change_progress = target_entity.faction_change_progress + change_progress_per_tick
        beam_emitter:setCustomUtilityBeamModeProgress(mode_name, target_entity.faction_change_progress)
        beam_emitter:setEnergy(beam_emitter:getEnergy() - emitter_utility_beam_energy_use_per_delta)
        beam_emitter:setSystemHeat("utilitybeam", beam_emitter:getSystemHeat("utilitybeam") + emitter_utility_beam.heat_add_rate_per_second * beam_emitter:getSystemPower("utilitybeam") * global_delta)

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

    player_ship = PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis"):setUtilityBeam(180,5000,1,1000):setRotation(-90):setCallSign("player"):setHull(1):setCanBeDestroyed(false)
    player_ship:setWeaponStorage("Homing", 5):setWeaponStorageMax("Homing", 5)

    player_ship_2 = PlayerSpaceship():setFaction("Kraylor"):setTemplate("Atlantis"):setUtilityBeam(180,5000,1,1000):setRotation(-90):setCallSign("player 2"):setHull(1):setCanBeDestroyed(false)
    player_ship_2:setWeaponStorage("Homing", 5):setWeaponStorageMax("Homing", 5):setPosition(0,-1000)

    resupply_ship = CpuShip():setTemplate("Atlantis"):setPosition(0, 500):setRotation(0):setFaction("Human Navy"):setCallSign("resupply"):orderIdle()
    resupply_ship:setWeaponStorage("Homing", 0):setWeaponStorageMax("Homing", 5):setScanned(true)

    target_ship = CpuShip():setTemplate("Adder MK5"):setPosition(500, 0):setRotation(0):setFaction("Human Navy"):setCallSign("target"):orderRoaming():setScanned(true)

    SpaceStation():setPosition(1000, 1000):setTemplate('Small Station'):setFaction("Human Navy"):setRotation(random(0, 360))
    Asteroid():setPosition(-600, 0):setSize(100)
    Asteroid():setPosition(-600, 100):setSize(100)
    Asteroid():setPosition(-600, -100):setSize(100)

    local utility_beam = player_ship.components.utility_beam
    incremental_effect = 0

    if utility_beam then
        player_ship
            :addCustomUtilityBeamMode(
                -- name, energy_per_sec, heat_per_sec, requires_target,
                 "Pull",            5.0,         0.02,            true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if not can_fire then return end

                    local drag_distance,
                          position_x, position_y,
                          target_position_x, target_position_y,
                          norm = tractorBeamSetup(beam_emitter, beam_target, emitter_utility_beam_energy_use_per_delta, emitter_utility_beam.heat_add_rate_per_second, emitter_utility_beam_effectiveness, distance, angle_diff)

                    if drag_distance <= 0 then
                        emitter_utility_beam.is_firing = false
                        return
                    end
                    emitter_utility_beam.is_firing = true

                    -- Pull mode: move target toward emitter
                    local destination = {x = position_x, y = position_y}

                    if distance <= 1.1 * global_delta / drag_distance then
                        if beam_emitter.components.docking_bay and beam_target.components.docking_port then
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

                    tractorBeamMove(beam_emitter, beam_target, target_position_x, target_position_y, destination, drag_distance)
                -- end callback
                end
            )
            :addCustomUtilityBeamMode(
                -- name, energy_per_sec, heat_per_sec, requires_target,
                 "Push",            5.0,         0.02,            true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if not can_fire then return end

                    local drag_distance,
                          position_x, position_y,
                          target_position_x, target_position_y,
                          norm = tractorBeamSetup(beam_emitter, beam_target, emitter_utility_beam_energy_use_per_delta, emitter_utility_beam.heat_add_rate_per_second, emitter_utility_beam_effectiveness, distance, angle_diff)

                    if drag_distance <= 0 then
                        emitter_utility_beam.is_firing = false
                        return
                    end
                    emitter_utility_beam.is_firing = true

                    -- Push mode: move target away from emitter
                    local destination = {
                        x = position_x + norm.x * emitter_utility_beam.range * 1.2,
                        y = position_y + norm.y * emitter_utility_beam.range * 1.2
                    }

                    tractorBeamMove(beam_emitter, beam_target, target_position_x, target_position_y, destination, drag_distance)
                -- end callback
                end
            )
            :addCustomUtilityBeamMode(
                -- name, energy_per_sec, heat_per_sec, requires_target,
           "Reposition",            5.0,         0.02,            true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if not can_fire then return end

                    local drag_distance,
                          position_x, position_y,
                          target_position_x, target_position_y,
                          norm = tractorBeamSetup(beam_emitter, beam_target, emitter_utility_beam_energy_use_per_delta, emitter_utility_beam.heat_add_rate_per_second, emitter_utility_beam_effectiveness, distance, angle_diff)

                    if drag_distance <= 0 then
                        emitter_utility_beam.is_firing = false
                        return
                    end
                    emitter_utility_beam.is_firing = true

                    local tractor_heading = utility_beam.bearing + beam_emitter:getHeading()
                    while tractor_heading > 360.0 do tractor_heading = tractor_heading - 360.0 end
                    while tractor_heading < 0.0 do tractor_heading = tractor_heading + 360.0 end
                    local tractor_vector_x, tractor_vector_y = vectorFromAngle(tractor_heading, utility_beam.range, true);

                    -- Push mode: move target away from emitter
                    local destination = {
                        x = position_x + tractor_vector_x,
                        y = position_y + tractor_vector_y
                    }

                    tractorBeamMove(beam_emitter, beam_target, target_position_x, target_position_y, destination, drag_distance)
                end
            )
            :addCustomUtilityBeamMode(
                --    name, energy_per_sec, heat_per_sec, requires_target,
                "Energize",            5.0,         0.02,            true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if can_fire and beam_target.components.reactor then
                        emitter_utility_beam.is_firing = true
                        beam_target:setEnergy(beam_target:getEnergy() + emitter_utility_beam.energy_use_per_second * global_delta)
                        beam_emitter:setSystemHeat("utilitybeam", beam_emitter:getSystemHeat("utilitybeam") + emitter_utility_beam.heat_add_rate_per_second * global_delta)
                    else
                        emitter_utility_beam.is_firing = false
                    end
                end
            )
            :addCustomUtilityBeamMode(
                --         name, energy_per_sec, heat_per_sec, requires_target,
                "Siphon energy",            5.0,         0.05,            true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    if not beam_emitter.components.reactor then return end

                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)
                    local drain_amount = emitter_utility_beam.heat_add_rate_per_second * 100 * global_delta

                    if can_fire and beam_target:getEnergy() > drain_amount then
                        -- log("beam_target:getEnergy():", beam_target:getEnergy(), "beam_target:getMaxEnergy():", beam_target:getMaxEnergy())
                        emitter_utility_beam.is_firing = true
                        beam_target:setEnergy(beam_target:getEnergy() - drain_amount)
                        beam_emitter:setEnergy(beam_emitter:getEnergy() + drain_amount)
                        beam_emitter:setSystemHeat("utilitybeam", beam_emitter:getSystemHeat("utilitybeam") + emitter_utility_beam.heat_add_rate_per_second * global_delta)
                    else
                        emitter_utility_beam.is_firing = false
                    end
                end
            )
            :addCustomUtilityBeamMode(
                --         name, energy_per_sec, heat_per_sec, requires_target,
                 "Give missile",            5.0,         0.05,            true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if can_fire and beam_target.components.missile_tubes and beam_emitter.components.missile_tubes and beam_target:isFriendly(beam_emitter) then
                        transferHomingMissile(beam_emitter, "Give missile", beam_emitter, beam_target, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta)
                    end

                    if emitter_utility_beam.is_firing == true then
                        -- log("Player giving missile to target")
                    end
                end
            )
            :addCustomUtilityBeamMode(
                --         name, energy_per_sec, heat_per_sec, requires_target,
                 "Take missile",            5.0,         0.05,            true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if can_fire and beam_target.components.missile_tubes and beam_emitter.components.missile_tubes then
                        transferHomingMissile(beam_emitter, "Take missile", beam_target, beam_emitter, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta)
                    end

                    if emitter_utility_beam.is_firing == true then
                        -- log("Player taking missile from target")
                    end
                end
            )
            :addCustomUtilityBeamMode(
                --         name, energy_per_sec, heat_per_sec, requires_target,
                "Mine asteroid",           12.5,         0.25,            true,
                -- callback
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if can_fire and isObjectType(beam_target, "Asteroid") == true then
                        -- log("Inside mine asteroid - isObjectType Asteroid is true")
                        -- Beam strength = amount mined per 10 seconds
                        local amount_mined_per_tick = emitter_utility_beam.strength * 0.01 * emitter_utility_beam_effectiveness * global_delta
                        local hull = beam_emitter.components.hull

                        if hull then
                            -- log("- Hull component check passed. hull.current = " .. hull.current .. " hull.max = " .. hull.max)

                            if hull.current < hull.max then
                                beam_emitter:setEnergy(beam_emitter:getEnergy() - emitter_utility_beam_energy_use_per_delta)
                                beam_emitter:setSystemHeat("utilitybeam", beam_emitter:getSystemHeat("utilitybeam") + emitter_utility_beam.heat_add_rate_per_second * beam_emitter:getSystemPower("utilitybeam") * global_delta)
                                emitter_utility_beam.is_firing = true

                                local asteroid_size = beam_target:getSize()

                                if amount_mined_per_tick > asteroid_size then
                                    incremental_effect = incremental_effect + asteroid_size
                                    -- log("- amount_mined: " .. incremental_effect .. " and asteroid destroyed")
                                    beam_target:destroy()
                                else
                                    incremental_effect = incremental_effect + amount_mined_per_tick
                                    -- log("- amount_mined: " .. incremental_effect .. ", asteroid_size: " .. asteroid_size)
                                    beam_target:setSize(asteroid_size - amount_mined_per_tick)
                                end

                                if incremental_effect > 1 then
                                    incremental_effect = incremental_effect - 1
                                    hull.current = hull.current + 0.1
                                    -- log("- amount_mined: " .. incremental_effect .. " after repairing hull")
                                end
                            else
                                -- log("- Hull component capacity check failed. hull.current = " .. hull.current .. " hull.max = " .. hull.max)
                                emitter_utility_beam.is_firing = false
                            end
                        else
                            -- log("- Hull component presence check failed.")
                            emitter_utility_beam.is_firing = false
                        end
                    else
                        -- log("Inside mine asteroid - isObjectType Asteroid is false")
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
            ]]--
            :addCustomUtilityBeamMode(
                "Send repair crew", 1.0, 1.0, true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if can_fire and beam_target.components.internal_rooms then
                        transferRepairCrew(beam_emitter, "Send repair crew", beam_emitter, beam_target, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta)
                    end

                    --[[ if emitter_utility_beam.is_firing == true then
                        log("Player sending repair crew to target")
                    end ]]
                end
            )
            :addCustomUtilityBeamMode(
                "Receive repair crew", 1.0, 1.0, true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if can_fire and beam_target:getRepairCrewCount() > 0 then
                        transferRepairCrew(beam_emitter, "Receive repair crew", beam_target, beam_emitter, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta)
                    end

                    if emitter_utility_beam.is_firing == true then
                        log("Player receiving repair crew from target")
                    end
                end
            )
            :addCustomUtilityBeamMode(
                "Capture (player)", 1.0, 1.0, true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if can_fire then
                        convertFaction(beam_emitter, "Capture (player)", beam_target, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta)
                    end
                end
            )
            :addCustomUtilityBeamMode(
                "Capture (Kraylor)", 1.0, 1.0, true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if can_fire then
                        convertFaction(beam_emitter, "Capture (Kraylor)", beam_target, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta, 1.0, "Kraylor")
                    end
                end
            )
            --[[ Requires scripting changes to expose missile components
            :addCustomUtilityBeamMode(
                "Disrupt homing", 1.0, 1.0, true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    print("This is the custom beam mode Disrupt homing: " .. beam_emitter:getCallSign() .. " disrupts the homing capabilities of a missile at " .. beam_target.getPosition())
                end
            )
            --]]
            :addCustomUtilityBeamMode(
                "Disrupt radar", 1.0, 0.001, false,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if can_fire then
                        beam_emitter:setEnergy(beam_emitter:getEnergy() - emitter_utility_beam_energy_use_per_delta)
                        beam_emitter:setSystemHeat("utilitybeam", beam_emitter:getSystemHeat("utilitybeam") + emitter_utility_beam.heat_add_rate_per_second * beam_emitter:getSystemPower("utilitybeam") * global_delta)
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
                                    range = 1000 * emitter_utility_beam_effectiveness,
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
                "Interdict", 1.0, 0.001, false,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if can_fire then
                        beam_emitter:setEnergy(beam_emitter:getEnergy() - emitter_utility_beam_energy_use_per_delta)
                        beam_emitter:setSystemHeat("utilitybeam", beam_emitter:getSystemHeat("utilitybeam") + emitter_utility_beam.heat_add_rate_per_second * beam_emitter:getSystemPower("utilitybeam") * global_delta)
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
                                    range = 1000 * emitter_utility_beam_effectiveness,
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
                "Harmonize freq.", 1.0, 1.0, true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if can_fire then
                        print("This is the custom beam mode Harmonize freq.: " .. beam_emitter:getCallSign() .. " forcefully harmonizes the shield frequencies of " .. beam_target:getCallSign() or "unknown entity" .. " to maximize its beam damage")
                    end
                end
            )
            :addCustomUtilityBeamMode(
                "Jump tow", 1.0, 1.0, true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if can_fire then
                        print("This is the custom beam mode Jump tow: " .. beam_emitter:getCallSign() .. " teleports " .. beam_target:getCallSign() or "unknown entity" .. " to a relative position at its jump destination")
                    end
                end
            )
            :addCustomUtilityBeamMode(
                "Scan", 1.0, 1.0, true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)

                    if can_fire then
                        print("This is the custom beam mode Scan " .. beam_emitter:getCallSign() .. " changes the scanned status of " .. beam_target:getCallSign() or "unknown entity")
                    end
                end
            )
            :addCustomUtilityBeamMode(
                "Repair", 1.0, 1.0, true,
                function(beam_emitter, beam_target, distance, angle_diff)
                    local can_fire, emitter_utility_beam, emitter_utility_beam_effectiveness, emitter_utility_beam_energy_use_per_delta = checkBeamCapability(beam_emitter)
                    local hull = beam_emitter.components.hull

                    if can_fire and hull then
                        if hull.current < hull.max then
                            beam_emitter:setEnergy(beam_emitter:getEnergy() - emitter_utility_beam_energy_use_per_delta)
                            beam_emitter:setSystemHeat("utilitybeam", beam_emitter:getSystemHeat("utilitybeam") + emitter_utility_beam.heat_add_rate_per_second * beam_emitter:getSystemPower("utilitybeam") * global_delta)
                            emitter_utility_beam.is_firing = true

                            hull.current = math.min(hull.max, hull.current + 0.1)
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

    addGMFunction(
        _("buttonGM", "Random asteroid field"),
        function()
            cleanup()
            for n = 1, 1000 do
                Asteroid():setPosition(random(-50000, 50000), random(-50000, 50000)):setSize(random(100, 500))
                VisualAsteroid():setPosition(random(-50000, 50000), random(-50000, 50000)):setSize(random(100, 500))
            end
        end
    )
    addGMFunction(
        _("buttonGM", "Random nebula field"),
        function()
            cleanup()
            for n = 1, 50 do
                Nebula():setPosition(random(-50000, 50000), random(-50000, 50000))
            end
        end
    )
    addGMFunction(
        _("buttonGM", "Delete unselected"),
        function()
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
        end
    )
end

-- TODO: Replace this with the utils.lua version once it incorporates missile types (#2733)
function isObjectType(obj,typ,qualifier)
    if obj ~= nil and obj:isValid() then
        if typ ~= nil then
            if ECS then
                if typ == "SpaceStation" then
                    return obj.components.docking_bay and obj.components.physics and obj.components.physics.type == "static"
                elseif typ == "PlayerSpaceship" then
                    return obj.components.player_control
                elseif typ == "ScanProbe" then
                    return obj.components.allow_radar_link
                elseif typ == "CpuShip" then
                    return obj.ai_controller
                elseif typ == "Asteroid" then
                    return obj.components.mesh_render and string.sub(obj.components.mesh_render.mesh, 1, 7) == "Astroid"
                elseif typ == "Nebula" then
                    return obj.components.nebula_renderer
                elseif typ == "Planet" then
                    return obj.components.planet_render
                elseif typ == "SupplyDrop" then
                    return obj.components.pickup and obj.components.radar_trace.icon == "radar/blip.png" and obj.components.radar_trace.color_by_faction
                elseif typ == "BlackHole" then
                    return obj.components.gravity and obj.components.billboard_render.texture == "blackHole3d.png"
                elseif typ == "WarpJammer" then
                    return obj.components.warp_jammer
                elseif typ == "Mine" then
                    return obj.components.delayed_explode_on_touch and obj.components.constant_particle_emitter
                elseif typ == "EMPMissile" then
                    return obj.components.radar_trace.icon == "radar/missile.png" and obj.components.explode_on_touch.damage_type == "emp"
                elseif typ == "Nuke" then
                    return obj.components.radar_trace.icon == "radar/missile.png" and obj.components.explosion_sfx == "sfx/nuke_explosion.wav"
                elseif typ == "Zone" then
                    return obj.components.zone
                else
                    if qualifier == "MovingMissile" then
                        if typ == "HomingMissile" or typ == "HVLI" or typ == "Nuke" or typ == "EMPMissile" then
                            return obj.components.radar_trace.icon == "radar/missile.png"
                        else
                            return false
                        end
                    elseif qualifier == "SplashMissile" then
                        if typ == "Nuke" or typ == "EMPMissile" then
                            if obj.components.radar_trace.icon == "radar/missile.png" then
                                if typ == "Nuke" then
                                    return obj.components.explosion_sfx == "sfx/nuke_explosion.wav"
                                else    --EMP
                                    return obj.components.explode_on_touch.damage_type == "emp"
                                end
                            else
                                return false
                            end
                        else
                            return false
                        end
                    else
                        return false
                    end
                end
            else
                return obj.typeName == typ
            end
        else
            return false
        end
    else
        return false
    end
end

function cleanup()
    -- Clean up the current play field. Find all objects and destroy everything that is not a player.
    -- If it is a player, position him in the center of the scenario.
    for idx, obj in ipairs(getAllObjects()) do
        if isObjectType(obj,"PlayerSpaceship") then
            obj:setPosition(random(-100, 100), random(-100, 100))
        else
            obj:destroy()
        end
    end
end

function update(delta)
    -- No victory condition
    global_delta = delta
end

function tractorBeamSetup(beam_emitter, beam_target, energy_per_delta, heat_per_sec, emitter_utility_beam_effectiveness, distance, angle_diff)
    local utility_beam = beam_emitter.components.utility_beam

    -- Don't bother if physics are static.
    -- TODO Check for redundancy with distance and angle_diff params
    local target_physics = beam_target.components.physics
    local hit_location = {x = 0, y = 0}
    if target_physics and target_physics.type == "static" then
        return 0, position_x, position_y, target_position_x, target_position_y, hit_location
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
    local norm = {x = dx / len, y = dy / len}
    local reactor = beam_emitter.components.reactor
    local coolant = beam_emitter.components.coolant

    -- If emitter has a reactor, consume energy
    -- If we don't have enough energy, don't do anything
    if reactor then
        if beam_emitter:getEnergy() < energy_per_delta then
            return 0, position_x, position_y, target_position_x, target_position_y, {x = 0, y = 0}
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
        beam_emitter:setSystemHeat("utilitybeam", beam_emitter:getSystemHeat("utilitybeam") + heat_per_sec * global_delta)
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
                    hit_location.x = hit_location.x - norm.x * target_physics.size -- TODO fix size calc
                    hit_location.y = hit_location.y - norm.y * target_physics.size
                end
            end

            -- Calculate shield angle
            local function vec2ToAngle(vec)
                return math.deg(math.atan2(vec.y, vec.x))
            end
            local function angleDifference(a, b)
                local diff = a - b
                while diff < -180 do diff = diff + 360 end
                while diff >  180 do diff = diff - 360 end
                return diff
            end
            local shield_angle = angleDifference(beam_target:getRotation(), vec2ToAngle({x = hit_location.x - target_position_x, y = hit_location.y - target_position_y}))
            while shield_angle < 0 do shield_angle = shield_angle + 360 end
            local shield_arc = 360.0 / beam_target:getShieldCount()
            shield_index = (math.floor((shield_angle + shield_arc / 2.0) / shield_arc) % beam_target:getShieldCount()) + 1
        end

        target_mass = target_mass + (beam_target:getShieldLevel(shield_index) or 0)
    end

    local target_force = 0
    if impulse then
        target_force = (beam_target:getSystemHealth("impulse") or 1) * (beam_target:getAcceleration() or 0)
    elseif missile then
        target_force = missile.speed or 0
    end

    if hull and hull.current > 0 then
        target_mass = target_mass + hull.current * 5.0
    end

    -- Drag calculations
    local drag_capability = utility_beam.strength * emitter_utility_beam_effectiveness
    -- log("drag_capability: " .. drag_capability)
    target_force = target_mass
    local effective_drag_capability = math.max(0.1, (drag_capability - target_force == 0 and 0 or (drag_capability - target_force) / drag_capability))
    local drag_distance = math.min(distance, effective_drag_capability * drag_capability) * global_delta

    return drag_distance, position_x, position_y, target_position_x, target_position_y, norm
end

function tractorBeamMove(beam_emitter, beam_target, target_position_x, target_position_y, destination, drag_distance)
    -- Move the tractored object to the destination
    local dx = target_position_x - destination.x
    local dy = target_position_y - destination.y

    if math.abs(dx) > 0.01 or math.abs(dy) > 0.01 then
        local len = math.sqrt(dx ^ 2 + dy ^ 2)

        if len > 0 then
            local move = {x = drag_distance * (dx / len), y = drag_distance * (dy / len)}
            beam_target:setPosition(target_position_x - move.x, target_position_y - move.y)
        end
    end
end
