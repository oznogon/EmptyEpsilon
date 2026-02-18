-- Name: Camera Entity Test
-- Description: Test scenario for camera entities
-- Type: Development

function init()
    -- Create a player ship
    player = PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis")
    player:setPosition(0, 0)

    -- Create a static camera at (5000, 0)
    local cam1 = createEntity()
    -- Initialize Transform component first by setting position
    cam1.components.transform = {}
    cam1:setPosition(5000, 0)
    cam1.components.cinematic_camera = {
        name = "Static Cam 1",
        pitch = 30,
        z_position = 500,
        field_of_view = 60
    }
    cam1:setRotation(-90)

    -- Create another camera at (-5000, 0) with different angle
    local cam2 = createEntity()
    cam2.components.transform = {}
    cam2:setPosition(-5000, 0)
    cam2.components.cinematic_camera = {
        name = "Static Cam 2",
        pitch = 45,
        z_position = 300,
        field_of_view = 70
    }
    cam2:setRotation(90)

    -- Create a camera above the origin
    local cam3 = createEntity()
    cam3.components.transform = {}
    cam3:setPosition(0, 3000)
    cam3.components.cinematic_camera = {
        name = "Top Cam",
        pitch = 80,
        z_position = 800,
        field_of_view = 50
    }
    cam3:setRotation(-90)
end

function update(delta)
    -- No update logic needed for static cameras
end
