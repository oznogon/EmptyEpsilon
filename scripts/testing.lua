--- Testing functions.
--
-- Non-terminating validation functions for use in scenarios or other scripts.
--
-- These functions must NOT terminate execution, must ALWAYS log "PASS" or "FAIL", and must ALWAYS return Boolean true if passed and false if failed. For terminate-on-failure assertions, use Lua's built-in `assert()`.

-- Test equality between two values and log the result. Use to verify that a variable or function returns the expected value.
-- Example:
-- player:setBeamWeaponTurret(0, 120, -30, 4) -- set a beam weapon turret with 120-degree arc
-- test_eq(player:getBeamWeaponTurretArc(0), 120, "Beam turret_arc via setBeamWeaponTurret") -- log PASS/return true if beam's turret arc is 120 degrees as expected, FAIL/false if not
function test_eq(actual, expected, name)
    if actual ~= expected then
        log("FAIL: " .. name .. " expected=" .. tostring(expected) .. " got=" .. tostring(actual))
        return false
    end

    log("PASS: " .. name .. " = " .. tostring(actual))

    return true
end
