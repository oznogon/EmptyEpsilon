-- Camera API Library
-- Provides helper functions for creating and controlling cinematic cameras

--- Create a new camera entity at the specified position
-- @param x X coordinate
-- @param y Y coordinate
-- @param z Z elevation (height above game plane)
-- @return Camera entity
function createCamera(x, y, z)
    local cam = createEntity()
    cam.components.transform = {}
    cam:setPosition(x or 0, y or 0)
    cam.components.cinematic_camera = {
        name = "Camera",
        pitch = 30,
        z_position = z or 200,
        field_of_view = 60
    }
    cam:setRotation(-90)
    return cam
end

--- Set camera position
-- @param camera Camera entity
-- @param x X coordinate
-- @param y Y coordinate
-- @param z Z elevation (optional, only updates if provided)
function setCameraPosition(camera, x, y, z)
    if not camera or not camera.components.cinematic_camera then
        return
    end
    camera:setPosition(x, y)
    if z ~= nil and camera.components.cinematic_camera then
        camera.components.cinematic_camera.z_position = z
    end
end

--- Set camera yaw (horizontal rotation)
-- @param camera Camera entity
-- @param yaw Yaw angle in degrees (-180 to 180)
function setCameraYaw(camera, yaw)
    if camera then
        camera:setRotation(yaw)
    end
end

--- Set camera pitch (vertical angle)
-- @param camera Camera entity
-- @param pitch Pitch angle in degrees (-90 to 90)
function setCameraPitch(camera, pitch)
    if camera and camera.components.cinematic_camera then
        camera.components.cinematic_camera.pitch = pitch
    end
end

--- Point camera at a target entity or position
-- @param camera Camera entity
-- @param target Entity to look at, or table {x=X, y=Y}
function pointCameraAt(camera, target)
    if not camera or not camera.components.cinematic_camera then
        return
    end

    local cam_x, cam_y = camera:getPosition()
    local target_x, target_y

    if type(target) == "table" and target.x and target.y then
        target_x, target_y = target.x, target.y
    elseif target and target.getPosition then
        target_x, target_y = target:getPosition()
    else
        return
    end

    local dx = target_x - cam_x
    local dy = target_y - cam_y
    local yaw = math.deg(math.atan2(dy, dx))

    camera:setRotation(yaw)
end

--- Set camera field of view
-- @param camera Camera entity
-- @param fov Field of view in degrees (30 to 140)
function setCameraFoV(camera, fov)
    if camera and camera.components.cinematic_camera then
        camera.components.cinematic_camera.field_of_view = math.max(30, math.min(140, fov))
    end
end

--- Assign camera to player ship's main screen
-- @param camera Camera entity
-- @param player_ship Player ship entity
function assignCameraToPlayer(camera, player_ship)
    if not camera or not player_ship then
        return
    end
    if not camera.components.cinematic_camera then
        return
    end
    if not player_ship.components.player_control then
        return
    end

    player_ship.components.player_control.main_screen_camera = camera
end

--- Fly camera smoothly to a target position and orientation
-- @param camera Camera entity
-- @param x Target X coordinate
-- @param y Target Y coordinate
-- @param z Target Z elevation
-- @param yaw Target yaw angle
-- @param pitch Target pitch angle
-- @param roll Target roll angle (currently unused)
-- @param duration Time in seconds for the movement
function flyCameraTo(camera, x, y, z, yaw, pitch, roll, duration)
    if not camera or not camera.components.cinematic_camera then
        return
    end

    duration = duration or 2.0
    local start_time = gameGlobalInfo:getElapsedTime()
    local start_x, start_y = camera:getPosition()
    local start_z = camera.components.cinematic_camera.z_position
    local start_yaw = camera:getRotation()
    local start_pitch = camera.components.cinematic_camera.pitch

    -- Create update thread
    local thread = function(delta)
        local elapsed = gameGlobalInfo:getElapsedTime() - start_time
        local t = math.min(elapsed / duration, 1.0)

        -- Smooth easing (ease in-out)
        t = t * t * (3.0 - 2.0 * t)

        -- Interpolate position
        local current_x = start_x + (x - start_x) * t
        local current_y = start_y + (y - start_y) * t
        local current_z = start_z + (z - start_z) * t

        -- Interpolate angles (handle wraparound for yaw)
        local yaw_diff = ((yaw - start_yaw + 180) % 360) - 180
        local current_yaw = start_yaw + yaw_diff * t
        local current_pitch = start_pitch + (pitch - start_pitch) * t

        setCameraPosition(camera, current_x, current_y, current_z)
        setCameraYaw(camera, current_yaw)
        setCameraPitch(camera, current_pitch)

        -- Continue until duration reached
        if t >= 1.0 then
            return true  -- Thread complete
        end
        return false
    end

    -- Add to script threads
    table.insert(gameGlobalInfo.script_threads, sp.script.CoroutinePtr(thread))
end

--- Shake camera for dramatic effect
-- @param camera Camera entity
-- @param intensity Shake intensity (typical range: 0.1 to 5.0)
-- @param duration Shake duration in seconds
function shakeCamera(camera, intensity, duration)
    if not camera or not camera.components.cinematic_camera then
        return
    end

    intensity = intensity or 1.0
    duration = duration or 0.5
    local start_time = gameGlobalInfo:getElapsedTime()
    local original_yaw = camera:getRotation()
    local original_pitch = camera.components.cinematic_camera.pitch
    local original_x, original_y = camera:getPosition()
    local original_z = camera.components.cinematic_camera.z_position

    local thread = function(delta)
        local elapsed = gameGlobalInfo:getElapsedTime() - start_time
        local t = elapsed / duration

        if t >= 1.0 then
            -- Restore original position/orientation
            setCameraPosition(camera, original_x, original_y, original_z)
            setCameraYaw(camera, original_yaw)
            setCameraPitch(camera, original_pitch)
            return true
        end

        -- Decay shake over time
        local decay = 1.0 - t
        local shake_amount = intensity * decay

        -- Random offsets
        local offset_x = (math.random() - 0.5) * shake_amount * 50
        local offset_y = (math.random() - 0.5) * shake_amount * 50
        local offset_z = (math.random() - 0.5) * shake_amount * 20
        local offset_yaw = (math.random() - 0.5) * shake_amount * 2
        local offset_pitch = (math.random() - 0.5) * shake_amount * 2

        setCameraPosition(camera, original_x + offset_x, original_y + offset_y, original_z + offset_z)
        setCameraYaw(camera, original_yaw + offset_yaw)
        setCameraPitch(camera, original_pitch + offset_pitch)

        return false
    end

    table.insert(gameGlobalInfo.script_threads, sp.script.CoroutinePtr(thread))
end

--- Make camera chase a target entity from behind
-- @param camera Camera entity
-- @param target Entity to chase
-- @param distance Distance to maintain behind target
function cameraChaseTarget(camera, target, distance)
    if not camera or not camera.components.cinematic_camera then
        return
    end
    if not target then
        return
    end

    distance = distance or 500

    -- Assign entity so camera follows automatically
    camera.components.cinematic_camera.assigned_entity = target

    local thread = function(delta)
        if not target or not target:isValid() then
            camera.components.cinematic_camera.assigned_entity = nil
            return true
        end

        -- Get target position and rotation
        local target_x, target_y = target:getPosition()
        local target_rotation = target:getRotation()

        -- Position camera behind target
        local angle_rad = math.rad(target_rotation + 180)  -- Opposite direction
        local cam_x = target_x + math.cos(angle_rad) * distance
        local cam_y = target_y + math.sin(angle_rad) * distance

        setCameraPosition(camera, cam_x, cam_y)
        pointCameraAt(camera, target)

        return false  -- Continue indefinitely
    end

    table.insert(gameGlobalInfo.script_threads, sp.script.CoroutinePtr(thread))
end

--- Make camera orbit around a target entity
-- @param camera Camera entity
-- @param target Entity to orbit
-- @param distance Orbit radius
-- @param period Time in seconds for one complete orbit
function cameraOrbitTarget(camera, target, distance, period)
    if not camera or not camera.components.cinematic_camera then
        return
    end
    if not target then
        return
    end

    distance = distance or 1000
    period = period or 30.0
    local start_time = gameGlobalInfo:getElapsedTime()

    local thread = function(delta)
        if not target or not target:isValid() then
            return true
        end

        local elapsed = gameGlobalInfo:getElapsedTime() - start_time
        local angle = (elapsed / period) * 360.0
        local angle_rad = math.rad(angle)

        local target_x, target_y = target:getPosition()
        local cam_x = target_x + math.cos(angle_rad) * distance
        local cam_y = target_y + math.sin(angle_rad) * distance

        setCameraPosition(camera, cam_x, cam_y)
        pointCameraAt(camera, target)

        return false  -- Continue indefinitely
    end

    table.insert(gameGlobalInfo.script_threads, sp.script.CoroutinePtr(thread))
end

--- Perform a fly-by of a target entity
-- @param camera Camera entity
-- @param target Entity to fly by
-- @param distance Distance from target during fly-by
-- @param angle Approach angle in degrees (0 = from right, 90 = from below, etc.)
function cameraTargetFlyBy(camera, target, distance, angle)
    if not camera or not camera.components.cinematic_camera then
        return
    end
    if not target then
        return
    end

    distance = distance or 1000
    angle = angle or 0
    local duration = 5.0  -- Fly-by takes 5 seconds

    local target_x, target_y = target:getPosition()
    local angle_rad = math.rad(angle)

    -- Start position: far from target on approach vector
    local start_distance = distance * 3
    local start_x = target_x + math.cos(angle_rad + math.pi) * start_distance
    local start_y = target_y + math.sin(angle_rad + math.pi) * start_distance

    -- End position: far from target on exit vector
    local end_distance = distance * 3
    local end_x = target_x + math.cos(angle_rad) * end_distance
    local end_y = target_y + math.sin(angle_rad) * end_distance

    -- Set initial position
    setCameraPosition(camera, start_x, start_y)
    pointCameraAt(camera, target)

    local start_time = gameGlobalInfo:getElapsedTime()

    local thread = function(delta)
        if not target or not target:isValid() then
            return true
        end

        local elapsed = gameGlobalInfo:getElapsedTime() - start_time
        local t = math.min(elapsed / duration, 1.0)

        -- Update target position (in case it moved)
        target_x, target_y = target:getPosition()

        -- Smooth easing
        local ease_t = t * t * (3.0 - 2.0 * t)

        -- Interpolate position
        local current_x = start_x + (end_x - start_x) * ease_t
        local current_y = start_y + (end_y - start_y) * ease_t

        setCameraPosition(camera, current_x, current_y)
        pointCameraAt(camera, target)

        if t >= 1.0 then
            return true
        end
        return false
    end

    table.insert(gameGlobalInfo.script_threads, sp.script.CoroutinePtr(thread))
end

--- Enable FoV scaling based on assigned entity velocity
-- @param camera Camera entity
-- @param base_fov Base field of view
-- @param fov_range FoV adjustment range (+/- degrees from base)
function enableVelocityFoVScaling(camera, base_fov, fov_range)
    if not camera or not camera.components.cinematic_camera then
        return
    end

    base_fov = base_fov or 60
    fov_range = fov_range or 10

    camera.components.cinematic_camera.use_velocity_fov_scaling = true
    camera.components.cinematic_camera.base_fov_for_velocity = base_fov
    camera.components.cinematic_camera.fov_velocity_range = fov_range
end

--- Disable FoV scaling based on velocity
-- @param camera Camera entity
function disableVelocityFoVScaling(camera)
    if camera and camera.components.cinematic_camera then
        camera.components.cinematic_camera.use_velocity_fov_scaling = false
    end
end
