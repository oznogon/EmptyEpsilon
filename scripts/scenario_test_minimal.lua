-- Name: Minimal Camera Test
-- Description: Minimal test for camera feature
-- Type: Development

function init()
    -- Create a player ship at the origin
    player = PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis")
    player:setPosition(0, 0)

    -- Create a simple camera WITHOUT assigning it to main screen
    cam = createEntity()
    cam.components.transform = {}
    cam:setPosition(1000, 0)
    cam.components.cinematic_camera = {
        name = "Test Camera",
        yaw = 180,
        pitch = 30,
        z_position = 500,
        field_of_view = 60
    }
end

function update(delta)
end
