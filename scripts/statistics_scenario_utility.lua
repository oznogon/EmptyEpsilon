-- Shared final-statistics message composition, used in Rescue,
-- Defenders or Pirates, and Iris Siege.

local Stats = {}

function Stats.appendDeployed(message, count)
    if count > 1 then
        return string.format(
            _("msgMainscreen", "%s\nDeployed %s player ships."),
            message,
            count
        )
    end
    return string.format(
        _("msgMainscreen", "%s\nDeployed one player ship."),
        message
    )
end

function Stats.appendDuration(message, format)
    return string.format(
        _("msgMainscreen", format),
        message,
        formatTime(getScenarioTime())
    )
end

function Stats.appendSettings(message, format, ...)
    local values = {}
    for index, name in ipairs({ ... }) do
        values[index] = getScenarioSetting(name)
    end
    return string.format(
        _("msgMainscreen", format),
        message,
        table.unpack(values)
    )
end

return Stats
