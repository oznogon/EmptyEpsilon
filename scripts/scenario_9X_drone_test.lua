-- Name: Drone Controller Test
-- Description: A minimal test scenario for the drone controller feature.
---
--- A Saipan player ship spawns with the DroneController component enabled.
--- Three drones spawn nearby, each with the AllowDroneLink component
--- set to allow control by the player ship.
---
--- Use the Drone Operations crew screen to link to and control the drones.
-- Type: Development

function init()
    player = PlayerSpaceship()
        :setFaction("Human Navy")
        :setTemplate("Saipan")
        :setPosition(0, 0)

    player.components.drone_controller = {
        control_range = 10000.0,
        energy_drain_per_sec = 0.0,
    }

    local drone_templates = { "Atlantis", "Phobos T3", "MT52 Hornet" }
    for i = 1, 3 do
        local angle = math.rad((i - 1) * 120)
        local x = math.cos(angle) * 1000
        local y = math.sin(angle) * 1000
        local drone = CpuShip()
            :setTemplate(drone_templates[i])
            :setFaction("Human Navy")
            :setPosition(x, y)
            :setScanned(true)
            :orderIdle()
        drone.components.allow_drone_link = { owner = player }
    end
end

function update(delta) end
