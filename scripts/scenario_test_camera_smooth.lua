-- Name: Camera Smoothing Test
-- Description: Test scenario for camera smoothing with moving cameras
-- Type: Development

function init()
    -- Create a player ship at the origin
    player = PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis")
    player:setPosition(0, 0)

    -- Create a static camera looking at origin from the right
    cam_static = createEntity()
    cam_static.components.transform = {}
    cam_static:setPosition(5000, 0)
    cam_static.components.cinematic_camera = {
        name = "Static Right",
        yaw = 180,
        pitch = 45,
        z_position = 500,
        field_of_view = 60
    }

    -- Create a static camera looking at origin from above
    cam_top = createEntity()
    cam_top.components.transform = {}
    cam_top:setPosition(0, 3000)
    cam_top.components.cinematic_camera = {
        name = "Static Top",
        yaw = -90,
        pitch = 80,
        z_position = 800,
        field_of_view = 50
    }

    -- Create an orbiting camera
    cam_orbit = createEntity()
    cam_orbit.components.transform = {}
    cam_orbit:setPosition(4000, 0)
    cam_orbit.components.cinematic_camera = {
        name = "Orbiting",
        yaw = 180,
        pitch = 30,
        z_position = 300,
        field_of_view = 70
    }

    -- Create a camera attached to the player (chase cam)
    cam_chase = createEntity()
    cam_chase.components.transform = {}
    cam_chase:setPosition(0, -500)  -- Will be updated to follow player
    cam_chase.components.cinematic_camera = {
        name = "Chase Cam",
        yaw = 0,
        pitch = 20,
        z_position = 200,
        field_of_view = 80,
        assigned_entity = player,  -- Assign to player ship
        use_velocity_fov_scaling = true,
        base_fov_for_velocity = 80,
        fov_velocity_range = 15
    }

    -- Store orbit state
    orbit_angle = 0
end

function update(delta)
    -- Update orbiting camera position
    orbit_angle = orbit_angle + delta * 20  -- 20 degrees per second
    if orbit_angle >= 360 then
        orbit_angle = orbit_angle - 360
    end

    local orbit_radius = 4000
    local x = math.cos(math.rad(orbit_angle)) * orbit_radius
    local y = math.sin(math.rad(orbit_angle)) * orbit_radius

    cam_orbit:setPosition(x, y)

    -- Update orbit camera to look at origin
    local angle_to_origin = math.deg(math.atan2(-y, -x))
    cam_orbit.components.cinematic_camera.yaw = angle_to_origin

    -- Update chase camera position to follow player (offset behind)
    local px, py = player:getPosition()
    local player_heading = player:getHeading()

    -- Position camera 500 units behind the player
    local offset_distance = 500
    local offset_x = -math.sin(math.rad(player_heading)) * offset_distance
    local offset_y = math.cos(math.rad(player_heading)) * offset_distance

    cam_chase:setPosition(px + offset_x, py + offset_y)
    cam_chase.components.cinematic_camera.yaw = player_heading - 90
end
