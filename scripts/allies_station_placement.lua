-- Allies and Enemies station placement.

local M = {}

function M.new(options)
    options = options or {}
    local api = {}
    local catalog = options.catalog
    local friendly = options.friendly
    local generic = options.generic
    local enemy = options.enemy

    local function szt()
        --Randomly choose station size template
        stationSizeRandom = random(1, 100)
        if stationSizeRandom <= 8 then
            sizeTemplate = "Huge Station" -- 8 percent huge
        elseif stationSizeRandom <= 24 then
            sizeTemplate = "Large Station" --16 percent large
        elseif stationSizeRandom <= 50 then
            sizeTemplate = "Medium Station" --26 percent medium
        else
            sizeTemplate = "Small Station" --50 percent small
        end
        return sizeTemplate
    end

    local function place(spec)
        if stationFaction ~= spec.faction then
            fb = gp --set faction boundary
        end
        stationFaction = spec.faction --set station faction
        local name
        if #spec.primary > 0 then
            si = math.random(1, #spec.primary) --station index
            name = spec.primary[si]
            table.remove(spec.primary, si) --remove station from placement list
        elseif #spec.fallback > 0 then
            si = math.random(1, #spec.fallback) --station index
            name = spec.fallback[si]
            table.remove(spec.fallback, si) --remove station from placement list
        else
            _G[spec.remaining] = false
        end
        if _G[spec.remaining] then
            sizeTemplate = szt()
            pStation =
                catalog:place(psx, psy, name, stationFaction, sizeTemplate)
            local strength
            if sizeTemplate == "Huge Station" then
                strength = 10
            elseif sizeTemplate == "Large Station" then
                strength = 5
            elseif sizeTemplate == "Medium Station" then
                strength = 3
            else
                strength = 1
            end
            pStation.strength = strength
            _G[spec.strength] = _G[spec.strength] + strength
            pStation:onDestruction(_G[spec.destroyed])
            table.insert(stationList, pStation) --save station in general station list
            table.insert(_G[spec.list], pStation) --save station in faction station list
        end
        return pStation
    end

    local human = {
        faction = "Human Navy",
        primary = friendly,
        fallback = generic,
        list = "humanStationList",
        strength = "humanStationStrength",
        destroyed = "humanStationDestroyed",
        remaining = "humanStationsRemain",
    }
    local kraylor = {
        faction = "Kraylor",
        primary = enemy,
        fallback = generic,
        list = "kraylorStationList",
        strength = "kraylorStationStrength",
        destroyed = "kraylorStationDestroyed",
        remaining = "kraylorStationsRemain",
    }
    local exuari = {
        faction = "Exuari",
        primary = enemy,
        fallback = generic,
        list = "exuariStationList",
        strength = "exuariStationStrength",
        destroyed = "exuariStationDestroyed",
        remaining = "exuariStationsRemain",
    }
    local arlenian = {
        faction = "Arlenians",
        primary = friendly,
        fallback = generic,
        list = "arlenianStationList",
        strength = "arlenianStationStrength",
        destroyed = "arlenianStationDestroyed",
        remaining = "arlenianStationsRemain",
    }
    local neutral = {
        faction = "Independent",
        primary = friendly,
        fallback = generic,
        list = "neutralStationList",
        strength = "neutralStationStrength",
        destroyed = "neutralStationDestroyed",
        remaining = "neutralStationsRemain",
    }

    function api.placeHuman()
        return place(human)
    end

    function api.placeKraylor()
        return place(kraylor)
    end

    function api.placeExuari()
        return place(exuari)
    end

    function api.placeArlenian()
        return place(arlenian)
    end

    function api.placeNeutral()
        return place(neutral)
    end

    return api
end

return M
