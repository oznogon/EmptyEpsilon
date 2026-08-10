-- Name: Collision Avoidance Test
-- Description: Validates that AI ships reactively steer around each other when on head-on and perpendicular crossing paths, rather than ramming.
-- Type: Development

-- Thresholds (in units). Ships are starfighters, so radii are on the order of
-- tens of units; these thresholds leave a generous margin for a clean pass.
collision_threshold = 200
pass_threshold = 250

-- Two setups, tracked independently:
--   headon:  two ships flying straight at each other's start position.
--   cross:   two ships on perpendicular lanes that meet at a single point.
headon = {}
cross = {}

function spawn(x, y, rotation, tx, ty, name, table_ref)
    local s = CpuShip()
        :setTemplate("Adder MK5")
        :setFaction("Human Navy")
        :setPosition(x, y)
        :setRotation(rotation)
        :setCallSign(name)
        :setScanned(true)
        :orderFlyTowards(tx, ty)
    table.insert(table_ref, s)
    return s
end

function init()
    -- Speed up the headless test.
    setGameSpeed(4)

    -- Head-on pair on the x-axis, each ordered to the other's start point.
    -- Both spawn already facing their flight direction so they close at full
    -- speed immediately.
    spawn(-2500, 0, 0,   2500, 0, "HeadA", headon)
    spawn( 2500, 0, 180, -2500, 0, "HeadB", headon)

    -- Perpendicular crossing pair: horizontal lane y=2000 vs vertical lane x=2000.
    -- Their paths intersect exactly at (2000, 2000).
    spawn(-2500, 2000, 0,   2500, 2000, "CrossA", cross)
    spawn( 2000, -2500, 90, 2000, 2500, "CrossB", cross)

    headon.min_dist = 1e9
    cross.min_dist = 1e9
    headon.near_misses = 0
    cross.near_misses = 0
    headon.hull_events = 0
    cross.hull_events = 0

    timer = 0
    elapsed = 0
    log_interval = 3
    test_duration = 75

    print("=== Collision Avoidance Test ===")
    print("Head-on: HeadA(-2500,0)->(2500,0), HeadB(2500,0)->(-2500,0)  [meet near origin]")
    print("Cross:   CrossA y=2000 lane, CrossB x=2000 lane  [paths cross at (2000,2000)]")
    print(string.format("PASS if closest approach stays above %d units.", pass_threshold))
end

function update(delta)
    elapsed = elapsed + delta
    timer = timer + delta

    local function track(group, i, j)
        local x1, y1 = group[i]:getPosition()
        local x2, y2 = group[j]:getPosition()
        local d = distance(x1, y1, x2, y2)
        if d < group.min_dist then group.min_dist = d end
        if d < collision_threshold then group.near_misses = group.near_misses + 1 end
    end

    track(headon, 1, 2)
    track(cross, 1, 2)

    -- Hull loss is a definitive collision signal when collision damage is on.
    for _, group in ipairs({headon, cross}) do
        for _, s in ipairs(group) do
            if s:getHull() < s:getHullMax() then
                if not group[1].hull_checked then group.hull_checked = true end
            end
        end
    end

    if timer > log_interval then
        timer = 0
        local hax, hay = headon[1]:getPosition()
        local hbx, hby = headon[2]:getPosition()
        local cax, cay = cross[1]:getPosition()
        local cbx, cby = cross[2]:getPosition()
        print(string.format(
            "[t=%4.0fs] HeadA(%6.0f,%6.0f) HeadB(%6.0f,%6.0f) headon_dist=%6.0f | CrossA(%6.0f,%6.0f) CrossB(%6.0f,%6.0f) cross_dist=%6.0f",
            elapsed, hax, hay, hbx, hby, distance(hax, hay, hbx, hby),
            cax, cay, cbx, cby, distance(cax, cay, cbx, cby)
        ))
        print(string.format(
            "    running minima: headon=%.0f  cross=%.0f",
            headon.min_dist, cross.min_dist
        ))
    end

    if elapsed >= test_duration then
        local hd = headon.min_dist
        local cd = cross.min_dist
        local ok = hd >= pass_threshold and cd >= pass_threshold
        print("=== Collision Avoidance Test Summary ===")
        print(string.format("Head-on closest approach: %.0f units", hd))
        print(string.format("Cross  closest approach: %.0f units", cd))
        print(string.format("Near-miss events (<%d units): headon=%d cross=%d",
            collision_threshold, headon.near_misses, cross.near_misses))
        if ok then
            print("=== PASS: All AI ships avoided each other ===")
        else
            print("=== FAIL: Ships came too close (possible collision) ===")
        end
        shutdownGame()
    end
end
