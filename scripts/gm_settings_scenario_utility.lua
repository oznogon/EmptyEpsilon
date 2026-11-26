-- Shared configuration-driven Game Master setting menus, used in Planet Devourer, Liberation Day, The Omicron Plague, Defenders or Pirates, and Iris Siege.

local Settings = {}

local function localized_values(specs)
    return function()
        local values = {}
        for index, spec in ipairs(specs) do
            table.insert(values, {
                label = _("buttonGM", spec[1]),
                value = spec[2],
            })
        end
        return values
    end
end

function Settings.powerValues()
    return localized_values({
        { "Easy", 0.5 },
        { "Normal", 1 },
        { "Hard", 2 },
        { "Extreme", 3 },
        { "Quixotic", 5 },
    })()
end

function Settings.difficultyValues()
    return localized_values({
        { "Easy", 0.5 },
        { "Normal", 1 },
        { "Hard", 2 },
    })()
end

function Settings.reputationValues()
    return localized_values({
        { "Unknown", 0 },
        { "Nice", 20 },
        { "Hero", 50 },
        { "Major Hero", 100 },
        { "Super Hero", 200 },
    })()
end

function Settings.spawnMenu()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "+Spawn Ship(s)"), spawnGMShips)
end

function Settings.numeric(options)
    local menu
    menu = function()
        clearGMFunctions()
        addGMFunction(options.back_label(), options.back)
        for index, entry in ipairs(options.values()) do
            local label = string.format(
                _("buttonGM", options.format),
                entry.label,
                entry.value
            )
            if options.get() == entry.value then
                label = label .. "*"
            end
            addGMFunction(label, function()
                options.set(entry.value)
                menu()
            end)
        end
    end
    return menu
end

return Settings
