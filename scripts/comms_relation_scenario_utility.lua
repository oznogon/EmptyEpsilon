-- Communications relationship checks utility from Early Evaluation Exercise, Delta Quadrant Patrol Duty, Close the Gaps, Deliver Ambassador Gremus, Carrier and Fighters, Scurvy Scavenger, Unwanted Visitors, Allies and Enemies, Escape, Defender Hunter, Fermi 500, Capture the Flag, and Chaos of War.

local Relation = {}

function Relation.new(options)
    options = options or {}
    local source = options.source
        or function()
            return comms_source
        end
    local target = options.target
        or function()
            return comms_target
        end

    local function isAllowedTo(state)
        local comms_source = source()
        local comms_target = target()
        if options.diagnostic then
            options.diagnostic("is allowed to")
        end
        if state == "friend" and comms_source:isFriendly(comms_target) then
            return true
        end
        if state == "neutral" and not comms_source:isEnemy(comms_target) then
            return true
        end
        if options.rules then
            return options.rules(state, comms_source, comms_target)
        end
        return false
    end

    local function friendStatus()
        local comms_source = source()
        local comms_target = target()
        if options.diagnostic then
            options.diagnostic("get friend status")
        end
        if comms_source:isFriendly(comms_target) then
            return "friend"
        end
        return "neutral"
    end

    return {
        isAllowedTo = isAllowedTo,
        friendStatus = friendStatus,
    }
end

return Relation
