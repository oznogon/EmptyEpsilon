-- Helper function for creating tutorial sequences
function startTutorial()
    player = PlayerSpaceship()
        :setFaction("Human Navy")
        :setTemplate("Phobos M3P")

    tutorial_setPlayerShip(player)
    setDefaultSkybox("simulation")
    tutorial_showMessage(_([[Welcome to the EmptyEpsilon tutorial.

This tutorial covers basic gameplay to get you started quickly. For more in-depth tutorials and strategies for each role, run each of those roles' tutorials.

Press Next to continue.]]), true)

    tutorial_onNext(function()
        tutorial_list_index = 1
        startSequence(tutorial_list[tutorial_list_index])
    end)
end

function startSequence(sequence)
    current_sequence = sequence
    current_index = 1
    runNextSequenceStep()
end

function runNextSequenceStep()
    local data = current_sequence[current_index]
    current_index = current_index + 1

    if data == nil then
        tutorial_list_index = tutorial_list_index + 1
        if tutorial_list[tutorial_list_index] ~= nil then
            startSequence(tutorial_list[tutorial_list_index])
        else
            tutorial_finish()
        end
    elseif data["message"] ~= nil then
        tutorial_showMessage(data["message"], data["finish_check_function"] == nil)

        if data["finish_check_function"] == nil then
            update = nil
            tutorial_onNext(runNextSequenceStep)
        else
            update = function(delta)
                if data["finish_check_function"]() then
                    runNextSequenceStep()
                end
            end
            tutorial_onNext(nil)
        end
    elseif data["run_function"] ~= nil then
        local has_next_step = current_index <= #current_sequence
        data["run_function"]()

        if has_next_step then
            runNextSequenceStep()
        end
    end
end

function createSequence()
    return {}
end

function addToSequence(sequence, data, data2)
    if type(data) == "string" then
        if data2 == nil then
            table.insert(sequence, {message = data})
        else
            table.insert(sequence, {message = data, finish_check_function = data2})
        end
    elseif type(data) == "function" then
        table.insert(sequence, {run_function = data})
    end
end

function resetPlayerShip()
    player
        :setJumpDrive(false)
        :setWarpDrive(false)
        :setImpulseMaxSpeed(1)
        :setRotationMaxSpeed(1)
        :setPosition(0, 0)
        :setRotation(0)
        :setWeaponStorageMax("homing", 0)
        :setWeaponStorageMax("nuke", 0)
        :setWeaponStorageMax("mine", 0)
        :setWeaponStorageMax("emp", 0)
        :setWeaponStorageMax("hvli", 0)
        :commandImpulse(0)
        :commandWarp(0)
        :commandTargetRotation(0)
        :commandSetShields(false)

    for idx, system in ipairs({
        "reactor",
        "beamweapons",
        "missilesystem",
        "maneuver",
        "impulse",
        "warp",
        "jumpdrive",
        "frontshield",
        "rearshield"
    }) do
        player
            :setSystemHealth(system, 1.0)
            :setSystemHeat(system, 0.0)
            :setSystemPower(system, 1.0)
            :setSystemCoolant(system, 0.0)
            :commandSetSystemPowerRequest(system, 1.0)
            :commandSetSystemCoolantRequest(system, 0.0)
    end
end
