-- Name: Main Screen Camera Test
-- Description: Test scenario for main screen camera feature
-- Type: Development

function init()
    -- Create a player ship at the origin
    player = PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis")
    player:setPosition(0, 0)

    -- Create some visual references in the scene
    -- Station ahead
    SpaceStation():setTemplate("Small Station"):setFaction("Human Navy"):setPosition(5000, 0)

    -- Enemy ships to the left
    CpuShip():setTemplate("Adder MK5"):setFaction("Kraylor"):setPosition(-3000, 2000):orderIdle()
    CpuShip():setTemplate("Adder MK5"):setFaction("Kraylor"):setPosition(-3000, 2500):orderIdle()

    -- Friendly patrol to the right
    CpuShip():setTemplate("MT52 Hornet"):setFaction("Human Navy"):setPosition(3000, -2000):orderIdle()

    -- Create a main screen camera with a cinematic view
    -- Position it behind and above the station, looking back toward the origin
    main_cam = createEntity()
    main_cam.components.transform = {}
    main_cam:setPosition(6000, 0)
    main_cam:setRotation(180)  -- Looking back toward origin (yaw)
    main_cam.components.cinematic_camera = {
        name = "External View",  -- This name will appear on the main screen button!
        pitch = 35, -- Angled downward
        z_position = 800,  -- Elevated viewpoint
        field_of_view = 75
    }

    -- Assign this camera to the player's main screen
    player.components.player_control.main_screen_camera = main_cam

    -- Create a second camera (not assigned to main screen) for comparison
    other_cam = createEntity()
    other_cam.components.transform = {}
    other_cam:setPosition(0, 5000)
    other_cam:setRotation(-90)  -- Yaw
    other_cam.components.cinematic_camera = {
        name = "Top View (not main screen)",
        pitch = 80,
        z_position = 1000,
        field_of_view = 60
    }
end

function update(delta)
    -- No update logic needed for static cameras
end
