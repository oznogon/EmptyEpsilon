-- Shared heading and vector utility functions, also used directly in Surf's Up,
-- Deliver Ambassador Gremus, Liberation Day, Locust Swarm, Doomed Outpost,
-- Shoreline, and The Omicron Plague.

local Heading = {}

function Heading.north(vector_from_angle, options)
    options = options or {}
    return function(angle, distance)
        if options.diagnostic then
            options.diagnostic("top of vector from angle north")
        end
        angle = (angle + 270) % 360
        local x, y = vector_from_angle(angle, distance)
        if options.diagnostic then
            options.diagnostic("bottom (ish) of vector from angle north")
        end
        return x, y
    end
end

return Heading
