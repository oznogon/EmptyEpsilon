-- Shared environment placement primitives for scenario scripts.

local M = {}

local valid_shapes = {
    circle = true,
    torus = true,
    ["bell torus"] = true,
    rectangle = true,
    ["central rectangle"] = true,
}

local function default_distance(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function default_vector(angle, length)
    local radians = angle * math.pi / 180
    return math.cos(radians) * length, math.sin(radians) * length
end

local function sample(shape, x, y, distance_1, distance_2, angle, opts)
    local random = opts.random
    local cx, cy
    if shape == "circle" then
        cx, cy = opts.vector(random(0, 360), random(0, distance_1), true)
    elseif shape == "torus" then
        cx, cy =
            opts.vector(random(0, 360), random(distance_1, distance_2), true)
    elseif shape == "bell torus" then
        local radius = 0
        for _, range in ipairs(distance_2) do
            radius = radius + random(range.lo, range.hi)
        end
        cx, cy = opts.vector(random(0, 360), radius, true)
    elseif shape == "central rectangle" then
        cx, cy =
            opts.vector(angle, random(-distance_1 / 2, distance_1 / 2), true)
        local px, py = opts.vector(
            angle + 90,
            random(-distance_2 / 2, distance_2 / 2),
            true
        )
        cx, cy = cx + px, cy + py
    elseif shape == "rectangle" then
        cx, cy = opts.vector(angle, random(0, distance_1), true)
        local px, py = opts.vector(
            angle + 90,
            random(-distance_2 / 2, distance_2 / 2),
            true
        )
        cx, cy = cx + px, cy + py
    else
        error("unsupported placement shape: " .. tostring(shape))
    end
    return cx + x, cy + y
end

local function is_clear(objects, cx, cy, buffer, placing_station, opts)
    for _, item in ipairs(objects) do
        if item.shape == "circle" then
            local ix, iy = item.obj:getPosition()
            local comparison_distance = item.dist
            if
                placing_station
                and opts.is_station
                and opts.is_station(item.obj)
            then
                comparison_distance = opts.station_clearance
            end
            if opts.distance(cx, cy, ix, iy) < comparison_distance + buffer then
                return false
            end
        elseif item.shape == "zone" then
            local probe = opts.artifact_factory()
            probe:setPosition(cx, cy)
            local inside = item.obj:isInside(probe)
            probe:destroy()
            if inside then
                return false
            end
        end
    end
    return true
end

-- Positional arguments mirror the legacy scenario helpers for migration
-- purposes.
function M.findClearSpot(
    objects,
    area_shape,
    area_point_x,
    area_point_y,
    area_distance,
    area_distance_2,
    area_angle,
    new_buffer,
    placing_station,
    options
)
    options = options or {}
    assert(type(objects) == "table", "findClearSpot expects an object list")
    assert(valid_shapes[area_shape], "findClearSpot received an invalid shape")
    assert(type(area_point_x) == "number", "area_point_x must be a number")
    assert(type(area_point_y) == "number", "area_point_y must be a number")
    assert(type(area_distance) == "number", "area_distance must be a number")
    assert(type(new_buffer) == "number", "new_buffer must be a number")

    local opts = {
        random = options.random or random or math.random,
        distance = options.distance or distance or default_distance,
        vector = options.vector or vectorFromAngle or default_vector,
        is_station = options.is_station or isObjectType,
        artifact_factory = options.artifact_factory or Artifact,
        station_clearance = options.station_clearance or 12000,
        max_attempts = options.max_attempts or max_repeat_loop or 100,
        diagnostic = options.diagnostic or distance_diagnostic or false,
    }

    local attempts = 0
    repeat
        attempts = attempts + 1
        local cx, cy = sample(
            area_shape,
            area_point_x,
            area_point_y,
            area_distance,
            area_distance_2,
            area_angle,
            opts
        )
        if opts.diagnostic then
            print("findClearSpot candidate", cx, cy, area_shape)
        end
        if is_clear(objects, cx, cy, new_buffer, placing_station, opts) then
            return cx, cy
        end
    until attempts > opts.max_attempts
    return nil
end

function M.asteroidSize(preset, random)
    random = random or _G.random or math.random
    if preset == "coarse" then
        local size = 0
        for _ = 1, 4 do
            size = size + random(2, 200)
        end
        return size
    end
    local size = random(1, 100) + random(1, 75) + random(1, 75)
    for _ = 1, 8 do
        size = size + random(1, 20)
    end
    return size
end

function M.createRandomAlongArc(
    object_type,
    amount,
    x,
    y,
    distance,
    start_arc,
    end_arc,
    randomize,
    options
)
    options = options or {}
    local random = options.random or _G.random or math.random
    amount = amount or 1
    randomize = randomize or 0
    local angle_offset = options.angle_offset or 0
    start_arc = (start_arc + angle_offset) % 360
    end_arc = (end_arc + angle_offset) % 360
    local arc_length = end_arc - start_arc
    if start_arc > end_arc then
        end_arc = end_arc + 360
        arc_length = arc_length + 360
    end

    local object_list = {}
    local function create(radial_point)
        local point_distance = distance + random(-randomize, randomize)
        local radians = radial_point * math.pi / 180
        local px = x + math.cos(radians) * point_distance
        local py = y + math.sin(radians) * point_distance
        local payload
        if options.prepare then
            payload = options.prepare(px, py, radial_point, point_distance)
            if payload == false then
                return
            end
        end
        local object
        if payload == nil then
            object = object_type()
        else
            object = object_type(payload)
        end
        if object == nil then
            return
        end
        object:setPosition(px, py)
        if options.on_create then
            options.on_create(object, payload, px, py)
        end
        table.insert(object_list, object)
    end

    if amount > arc_length then
        for index = 1, arc_length do
            create(start_arc + index)
        end
        for _ = 1, amount - arc_length do
            create(random(start_arc, end_arc))
        end
    else
        for _ = 1, amount do
            create(random(start_arc, end_arc))
        end
    end
    return object_list
end

function M.createRandomAlongArcNorth(
    object_type,
    amount,
    x,
    y,
    distance,
    start_arc,
    end_arc,
    randomize
)
    return M.createRandomAlongArc(
        object_type,
        amount,
        x,
        y,
        distance,
        start_arc,
        end_arc,
        randomize,
        { angle_offset = 270 }
    )
end

function M.createRandomAsteroidAlongArc(
    amount,
    x,
    y,
    distance,
    start_arc,
    end_arc,
    randomize,
    options
)
    options = options or {}
    local random = options.random or _G.random or math.random
    if options.pre_roll ~= false then
        M.asteroidSize(options.size_preset or "dense", random)
    end
    local factory = options.factory or Asteroid
    local far_enough = options.far_enough
    if far_enough == nil then
        far_enough = _G.farEnough or M.farEnough
    end
    local registry = options.registry
    if registry == nil then
        registry = _G.place_space
    end
    local shape = options.shape
    return M.createRandomAlongArc(
        function(size)
            return factory():setSize(size)
        end,
        amount,
        x,
        y,
        distance,
        start_arc,
        end_arc,
        randomize,
        {
            random = random,
            angle_offset = options.angle_offset or 0,
            prepare = function(px, py)
                local size =
                    M.asteroidSize(options.size_preset or "dense", random)
                if far_enough and not far_enough(px, py, size) then
                    return false
                end
                return size
            end,
            on_create = function(object, size)
                if registry then
                    local entry = { obj = object, dist = size }
                    if shape ~= nil then
                        entry.shape = shape
                    end
                    table.insert(registry, entry)
                end
                if options.on_create then
                    options.on_create(object, size)
                end
            end,
        }
    )
end

function M.createRandomAsteroidAlongArcNorth(
    amount,
    x,
    y,
    distance,
    start_arc,
    end_arc,
    randomize
)
    return M.createRandomAsteroidAlongArc(
        amount,
        x,
        y,
        distance,
        start_arc,
        end_arc,
        randomize,
        { angle_offset = 270 }
    )
end

function M.createRandomAsteroidAlongArcUnregistered(
    amount,
    x,
    y,
    distance,
    start_arc,
    end_arc,
    randomize
)
    return M.createRandomAsteroidAlongArc(
        amount,
        x,
        y,
        distance,
        start_arc,
        end_arc,
        randomize,
        { far_enough = false, registry = false }
    )
end

function M.randomAroundPoint(
    object_type,
    amount,
    min_distance,
    max_distance,
    x,
    y,
    options
)
    options = options or {}
    local random = options.random or _G.random or math.random
    local objects = {}
    for _ = 1, amount do
        local angle = random(0, 360)
        local radius = random(min_distance, max_distance)
        local radians = angle * math.pi / 180
        local px = x + math.cos(radians) * radius
        local py = y + math.sin(radians) * radius
        local payload
        if options.prepare then
            payload = options.prepare(px, py, angle, radius)
            if payload == false then
                goto continue
            end
        end
        local object
        if payload == nil then
            object = object_type()
        else
            object = object_type(payload)
        end
        object:setPosition(px, py)
        if options.on_create then
            options.on_create(object, payload, px, py)
        end
        table.insert(objects, object)
        ::continue::
    end
    return objects
end

function M.asteroidsAroundPoint(
    amount,
    min_distance,
    max_distance,
    x,
    y,
    options
)
    options = options or {}
    local random = options.random or _G.random or math.random
    local copies = options.copies or 1
    local physical_factory = options.physical_factory or Asteroid
    local visual_factory = options.visual_factory or VisualAsteroid
    local far_enough = options.far_enough
    if far_enough == nil then
        far_enough = _G.farEnough or M.farEnough
    end
    local registry = options.registry
    if registry == nil then
        registry = _G.place_space
    end
    local objects = {}
    for _ = 1, amount do
        for copy_index = 1, copies do
            local angle = random(0, 360)
            local radius = random(min_distance, max_distance)
            local radians = angle * math.pi / 180
            local px = x + math.cos(radians) * radius
            local py = y + math.sin(radians) * radius
            local size = M.asteroidSize(options.size_preset or "dense", random)
            if far_enough and not far_enough(px, py, size) then
                goto continue
            end
            local factory = copy_index == 1 and physical_factory
                or visual_factory
            local object = factory():setPosition(px, py):setSize(size)
            if registry and copy_index == 1 then
                local entry = { obj = object, dist = size }
                if options.shape ~= nil then
                    entry.shape = options.shape
                end
                table.insert(registry, entry)
            end
            table.insert(objects, object)
            ::continue::
        end
    end
    return objects
end

function M.asteroidsAroundPointCoarse(amount, min_distance, max_distance, x, y)
    return M.asteroidsAroundPoint(
        amount,
        min_distance,
        max_distance,
        x,
        y,
        { size_preset = "coarse", shape = "circle" }
    )
end

function M.asteroidsAroundPointDense(amount, min_distance, max_distance, x, y)
    return M.asteroidsAroundPoint(
        amount,
        min_distance,
        max_distance,
        x,
        y,
        { size_preset = "dense", shape = "circle" }
    )
end

function M.asteroidCluster(amount, min_distance, max_distance, x, y)
    return M.asteroidsAroundPoint(
        amount,
        min_distance,
        max_distance,
        x,
        y,
        { copies = 3, far_enough = false, registry = false }
    )
end

local function locate(...)
    return (_G.environmentObject or M.environmentObject)(...)
end

function M.placeStar(axis)
    if star_count > 0 then
        local radius = random(600, 1400)
        local eo_x, eo_y = locate(center_x, center_y, radius, axis)
        if eo_x ~= nil then
            local star = Planet()
                :setPosition(eo_x, eo_y)
                :setPlanetRadius(radius)
                :setDistanceFromMovementPlane(-radius * 0.5)
            star:setCallSign(tableRemoveRandom(star_list[1].name))
            star:setPlanetAtmosphereTexture(star_list[1].texture.atmosphere)
                :setPlanetAtmosphereColor(
                    random(0.8, 1),
                    random(0.8, 1),
                    random(0.8, 1)
                )
            table.insert(
                place_space,
                { obj = star, dist = radius, shape = "circle" }
            )
            star_count = star_count - 1
        end
    else
        M.placeAsteroid(axis)
    end
end

function M.placeBlackHole(axis)
    if black_hole_count > 0 then
        local eo_x, eo_y = locate(center_x, center_y, 6000, axis)
        if eo_x ~= nil then
            local bh = BlackHole():setPosition(eo_x, eo_y)
            table.insert(
                place_space,
                { obj = bh, dist = 6000, shape = "circle" }
            )
            black_hole_count = black_hole_count - 1
        end
    else
        M.placeAsteroid(axis)
    end
end

function M.placeProbe(axis)
    if #station_list < 1 then
        M.placeAsteroid(axis)
    else
        local eo_x, eo_y = locate(center_x, center_y, 200, axis)
        if eo_x ~= nil then
            local sp = ScanProbe():setPosition(eo_x, eo_y)
            local owner = station_list[math.random(1, #station_list)]
            sp:setLifetime(30 * 60):setOwner(owner):setTarget(eo_x, eo_y)
            table.insert(
                place_space,
                { obj = sp, dist = 200, shape = "circle" }
            )
        end
    end
end

function M.placeWormHole(axis)
    if worm_hole_count > 0 then
        local eo_x, eo_y = locate(center_x, center_y, 6000, axis)
        if eo_x ~= nil then
            local we_x, we_y = locate(center_x, center_y, 500)
            if we_x ~= nil then
                local count_repeat_loop = 0
                repeat
                    we_x, we_y = locate(center_x, center_y, 500)
                    count_repeat_loop = count_repeat_loop + 1
                    if we_x == nil then
                        break
                    end
                until distance(eo_x, eo_y, we_x, we_y) > 50000
                    or count_repeat_loop > max_repeat_loop
                if count_repeat_loop > max_repeat_loop then
                    print("repeated too many times while placing a wormhole")
                    print(
                        "eo_x:",
                        eo_x,
                        "eo_y:",
                        eo_y,
                        "we_x:",
                        we_x,
                        "we_y:",
                        we_y
                    )
                end
                if we_x ~= nil and eo_x ~= nil then
                    local wh = WormHole()
                        :setPosition(eo_x, eo_y)
                        :setTargetPosition(we_x, we_y)
                    table.insert(
                        place_space,
                        { obj = wh, dist = 6000, shape = "circle" }
                    )
                    table.insert(place_space, {
                        dist = 500,
                        ps_x = we_x,
                        ps_y = we_y,
                        shape = "circle",
                    })
                    worm_hole_count = worm_hole_count - 1
                end
            end
        end
    else
        M.placeAsteroid(axis)
    end
end

function M.placeSensorJammer(axis, factory)
    if sensor_jammer_count > 0 then
        local lo_range = 10000
        local hi_range = 30000
        local lo_impact = 10000
        local hi_impact = 20000
        local range_increment = (hi_range - lo_range) / 8
        local impact_increment = (hi_impact - lo_impact) / 4
        local mix = math.random(2, 10 - (4 - (2 * math.floor(difficulty)))) --2-6, 2-8, 2-10
        sensor_jammer_scan_complexity = 1
        sensor_jammer_scan_depth = 1
        if mix > 5 then
            sensor_jammer_scan_depth = math.min(math.random(mix - 4, mix), 8)
            sensor_jammer_scan_complexity =
                math.max(mix - sensor_jammer_scan_depth, 1)
        else
            sensor_jammer_scan_depth = math.random(1, mix)
            sensor_jammer_scan_complexity =
                math.max(mix - sensor_jammer_scan_depth, 1)
        end
        sensor_jammer_range = lo_range
            + (sensor_jammer_scan_depth * range_increment)
        sensor_jammer_impact = lo_impact
            + (sensor_jammer_scan_complexity * impact_increment)
        local eo_x, eo_y = locate(center_x, center_y, 200, axis)
        if eo_x ~= nil then
            local sj = (factory or _G.sensorJammer)(eo_x, eo_y)
            table.insert(
                place_space,
                { obj = sj, dist = 200, shape = "circle" }
            )
            sensor_jammer_count = sensor_jammer_count - 1
        end
    else
        M.placeAsteroid(axis)
    end
end

function M.placeNebula(axis)
    local eo_x, eo_y = locate(center_x, center_y, 3000, axis)
    if eo_x ~= nil then
        local neb = Nebula():setPosition(eo_x, eo_y)
        table.insert(place_space, { obj = neb, dist = 1500, shape = "circle" })
        if random(1, 100) < 77 then
            local n_angle = random(0, 360)
            local n_x, n_y = vectorFromAngle(n_angle, random(5000, 10000))
            local neb2 = Nebula():setPosition(eo_x + n_x, eo_y + n_y)
            if random(1, 100) < 37 then
                local n2_angle = (n_angle + random(120, 240)) % 360
                n_x, n_y = vectorFromAngle(n2_angle, random(5000, 10000))
                eo_x = eo_x + n_x
                eo_y = eo_y + n_y
                local neb3 = Nebula():setPosition(eo_x, eo_y)
                if random(1, 100) < 22 then
                    local n3_angle = (n2_angle + random(120, 240)) % 360
                    n_x, n_y = vectorFromAngle(n3_angle, random(5000, 10000))
                    local neb4 = Nebula():setPosition(eo_x + n_x, eo_y + n_y)
                end
            end
        end
    end
end

function M.placeMine(axis)
    local eo_x, eo_y = locate(center_x, center_y, 1000, axis)
    if eo_x ~= nil then
        local m = Mine():setPosition(eo_x, eo_y)
        table.insert(place_space, { obj = m, dist = 1000, shape = "circle" })
    end
end

function M.placeMineField(axis)
    if mine_field_count > 0 then
        local field_size = math.random(1, 3)
        local mine_circle = {
            { inner_count = 4, mid_count = 10, outer_count = 15 }, --1
            { inner_count = 9, mid_count = 15, outer_count = 20 }, --2
            { inner_count = 15, mid_count = 20, outer_count = 25 }, --3
        }
        local eo_x, eo_y =
            locate(center_x, center_y, 4000 + (field_size * 1500), axis)
        if eo_x ~= nil then
            local angle = random(0, 360)
            local mx = 0
            local my = 0
            for i = 1, mine_circle[field_size].inner_count do
                mx, my = vectorFromAngle(angle, field_size * 1000)
                Mine():setPosition(eo_x + mx, eo_y + my)
                angle = (angle + (360 / mine_circle[field_size].inner_count))
                    % 360
            end
            for i = 1, mine_circle[field_size].mid_count do
                mx, my = vectorFromAngle(angle, field_size * 1000 + 1200)
                Mine():setPosition(eo_x + mx, eo_y + my)
                angle = (angle + (360 / mine_circle[field_size].mid_count))
                    % 360
            end
            table.insert(place_space, {
                dist = 3000 + (field_size * 1000),
                ps_x = eo_x,
                ps_y = eo_y,
                shape = "circle",
            })
            mine_field_count = mine_field_count - 1
            if random(1, 100) < 30 + difficulty * 20 then
                local n_x, n_y =
                    vectorFromAngle(random(0, 360), random(50, 2000))
                Nebula():setPosition(eo_x + n_x, eo_y + n_y)
            end
        end
    else
        M.placeAsteroid(axis)
    end
end

function M.placeAsteroidField(axis)
    if asteroid_field_count > 0 then
        local field_size = random(2000, 8000)
        local eo_x, eo_y = locate(center_x, center_y, field_size + 400, axis)
        if eo_x ~= nil then
            M.asteroidsAroundPointCoarse(
                math.floor(field_size / random(50, 100)),
                100,
                field_size,
                eo_x,
                eo_y
            )
            asteroid_field_count = asteroid_field_count - 1
        end
    else
        M.placeAsteroid(axis)
    end
end

function M.placeTransport(axis, factory)
    local eo_x, eo_y = locate(center_x, center_y, 600, axis)
    if eo_x ~= nil then
        local ship, ship_size = (factory or _G.randomTransportType)()
        local faction_list = {
            "Human Navy",
            "Independent",
            "Kraylor",
            "Arlenians",
            "Exuari",
            "Ghosts",
            "Ktlitans",
            "TSN",
            "USN",
            "CUF",
        }
        ship:setPosition(eo_x, eo_y)
            :setFaction(faction_list[math.random(1, #faction_list)])
        ship:setCallSign(generateCallSign(nil, ship:getFaction()))
        table.insert(place_space, { obj = ship, dist = 600, shape = "circle" })
        table.insert(transport_list, ship)
    end
end

function M.placeAsteroid(axis)
    local asteroid_size = random(2, 200)
        + random(2, 200)
        + random(2, 200)
        + random(2, 200)
    local eo_x, eo_y = locate(center_x, center_y, asteroid_size, axis)
    if eo_x ~= nil then
        local ta = Asteroid():setPosition(eo_x, eo_y):setSize(asteroid_size)
        table.insert(
            place_space,
            { obj = ta, dist = asteroid_size, shape = "circle" }
        )
    end
end

function M.farEnough(o_x, o_y, obj_dist)
    local far_enough = true
    for _, item in ipairs(place_space) do
        if item.shape == "circle" then
            if distanceDiagnostic then
                print(
                    "Distance diagnostic 2: item.obj:",
                    item.obj,
                    item.obj:getCallSign(),
                    "o_x:",
                    o_x,
                    "o_y:",
                    o_y
                )
            end
            if item.obj ~= nil and item.obj:isValid() then
                if distance(item.obj, o_x, o_y) < (obj_dist + item.dist) then
                    far_enough = false
                    break
                end
            elseif item.ps_x ~= nil then
                if
                    distance(item.ps_x, item.ps_y, o_x, o_y)
                    < (obj_dist + item.dist)
                then
                    far_enough = false
                    break
                end
            end
        elseif item.shape == "rectangle" then
            if
                o_x > item.lo_x
                and o_x < item.hi_x
                and o_y > item.lo_y
                and o_y < item.hi_y
            then
                far_enough = false
                break
            end
        elseif item.shape == "toroid" then
            if item.obj ~= nil and item.obj:isValid() then
                local origin_dist = distance(item.obj, o_x, o_y)
                if
                    origin_dist > item.inner_orbit - obj_dist
                    and origin_dist < item.outer_orbit + obj_dist
                then
                    far_enough = false
                    break
                end
            end
        elseif item.shape == "zone" then
            local va = VisualAsteroid():setPosition(o_x, o_y)
            if item.zone:isInside(va) then
                far_enough = false
            end
            va:destroy()
            if far_enough then
                for i = 1, 30 do
                    local v_x, v_y = vectorFromAngleNorth(i * 12, obj_dist)
                    if item.zone:isInside(va) then
                        far_enough = false
                    end
                    va:destroy()
                    if not far_enough then
                        break
                    end
                end
            end
            if not far_enough then
                break
            end
        end
    end
    return far_enough
end

function M.environmentObject(ref_x, ref_y, dist, axis)
    if ref_x == nil or ref_y == nil or dist == nil then
        print(
            "function environmentObject expects ref_x, ref_y and dist to be provided"
        )
        return
    end
    if axis == nil then --circular environment object placement
        local inner_count_repeat_loop = 0
        local outer_count_repeat_loop = 0
        local outer_circle_buffer = 500
        repeat
            repeat
                radius = 0
                for i = 1, 10 do
                    radius = radius
                        + random(
                            500,
                            average_station_circle_distance / 10
                                + outer_circle_buffer
                        )
                end
                local o_x, o_y = vectorFromAngleNorth(random(0, 360), radius)
                ref_x = ref_x + o_x
                ref_y = ref_y + o_y
                inner_count_repeat_loop = inner_count_repeat_loop + 1
            until M.farEnough(ref_x, ref_y, dist)
                or inner_count_repeat_loop > max_repeat_loop
            if inner_count_repeat_loop > max_repeat_loop then
                outer_count_repeat_loop = outer_count_repeat_loop + 1
                outer_circle_buffer = outer_circle_buffer + 1000
                inner_count_repeat_loop = 0
            else
                break
            end
        until outer_count_repeat_loop > max_repeat_loop
        if outer_count_repeat_loop > max_repeat_loop then
            print(
                "repeated too many times when trying to get far enough away 1"
            )
            print("last ref_x:", ref_x, "last ref_y:", ref_y)
            far_enough_fail = true
            return nil
        else
            return ref_x, ref_y
        end
    else --linear environment object placement
        local count_repeat_loop = 0
        if base_point_x == nil then
            base_distance = average_station_circle_distance
            base_point_x, base_point_y =
                vectorFromAngleNorth(axis, base_distance)
        end
        repeat
            local par_x, par_y = vectorFromAngleNorth(axis, random(0, 40000))
            local perp_x, perp_y =
                vectorFromAngleNorth(axis + 90, random(0, 40000))
            local pos_x, pos_y = vectorFromAngleNorth(axis + 270, 20000)
            ref_x = ref_x + base_point_x + pos_x + par_x + perp_x
            ref_y = ref_y + base_point_y + pos_y + par_y + perp_y
            base_distance = base_distance + random(20, 200)
            if base_distance > average_station_circle_distance + 80000 then
                base_distance = average_station_circle_distance
            end
            base_point_x, base_point_y =
                vectorFromAngleNorth(axis, base_distance)
            count_repeat_loop = count_repeat_loop + 1
        until M.farEnough(ref_x, ref_y, dist)
            or count_repeat_loop > max_repeat_loop
        if count_repeat_loop > max_repeat_loop then
            print(
                "repeated too many times when trying to get far enough away 2"
            )
            print("last ref_x:", ref_x, "last ref_y:", ref_y)
            far_enough_fail = true
            return nil
        else
            return ref_x, ref_y
        end
    end
end

function M.moonCollisionCheck()
    if moon_barrier == nil then
        return
    end
    local moon_x, moon_y = moon_barrier:getPosition()
    collision_list =
        moon_barrier:getObjectsInRange(moon_barrier.moon_radius + 600)
    local obj_dist = 0
    local ship_distance = 0
    local obj_type_name = ""
    for _, obj in ipairs(collision_list) do
        if obj:isValid() then
            obj_dist = distance(obj, moon_barrier)
            if isObjectType(obj, "CpuShip") then
                obj_type_name = obj:getTypeName()
                if obj_type_name ~= nil then
                    ship_distance = shipTemplateDistance[obj:getTypeName()]
                    if ship_distance == nil then
                        ship_distance = 400
                        print(
                            "Table ship template distance did not have an entry for",
                            obj:getTypeName()
                        )
                    end
                else
                    ship_distance = 400
                end
                -- print("CPU ship object distance:",obj_dist,"ship distance:",ship_distance,"moon radius:",moon_barrier.moon_radius)
                if
                    obj_dist
                    <= moon_barrier.moon_radius + ship_distance + 200
                then
                    obj:takeDamage(100, "kinetic", moon_x, moon_y)
                end
            elseif isObjectType(obj, "PlayerSpaceship") then
                obj_type_name = obj:getTypeName()
                if obj_type_name ~= nil then
                    ship_distance = playerShipStats[obj:getTypeName()].distance
                    if ship_distance == nil then
                        ship_distance = 400
                        print(
                            "Player ship stats did not have a distance entry for",
                            obj:getTypeName()
                        )
                    end
                else
                    ship_distance = 400
                end
                -- print("Player ship object distance:",obj_dist,"ship distance:",ship_distance,"moon radius:",moon_barrier.moon_radius)
                if
                    obj_dist
                    <= moon_barrier.moon_radius + ship_distance + 200
                then
                    obj:takeDamage(100, "kinetic", moon_x, moon_y)
                end
            end
        end
    end
end

return M
