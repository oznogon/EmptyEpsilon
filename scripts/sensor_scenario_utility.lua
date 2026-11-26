-- Shared sensor jammer and long-range sensor helpers.

local M = {}

function M.sensorJammerPickupBasic(self, retriever)
    string.format("")
    local jammer_call_sign = self:getCallSign()
    sensor_jammer_list[jammer_call_sign] = nil
    if not self:isScannedBy(retriever) then
        retriever:setCanScan(false)
        retriever.scanner_dead = "scanner_dead"
        retriever:addCustomMessage(
            "Science",
            retriever.scanner_dead,
            _(
                "msgScience",
                "The unscanned artifact we just picked up has fried our scanners"
            )
        )
        retriever.scanner_dead_ops = "scanner_dead_ops"
        retriever:addCustomMessage(
            "Operations",
            retriever.scanner_dead_ops,
            _(
                "msgOperations",
                "The unscanned artifact we just picked up has fried our scanners"
            )
        )
    end
    may_explain_sensor_jammer = true
end

function M.queueProbeRespawn(probe, queue, instigator)
    queue = queue or {}
    local station_owner = probe:getOwner()
    local target_x, target_y = probe:getTarget()
    table.insert(queue, {
        time = getScenarioTime() + random(60, 240),
        owner = station_owner,
        instigator = instigator,
        x = target_x,
        y = target_y,
    })
    return queue
end

function M.sensorJammerBasic(x, y)
    artifact_number = artifact_number + math.random(1, 4)
    local random_suffix = string.char(math.random(65, 90))
    local jammer_call_sign =
        string.format("SJ%i%s", artifact_number, random_suffix)
    local scanned_description = string.format(
        _(
            "scienceDescription-artifact",
            "Source of emanations interfering with long range sensors. Range:%.1fu Impact:%.1fu"
        ),
        sensor_jammer_range / 1000,
        sensor_jammer_impact / 1000
    )
    local sensor_jammer = Artifact()
        :setPosition(x, y)
        :setScanningParameters(
            sensor_jammer_scan_complexity,
            sensor_jammer_scan_depth
        )
        :setRadarSignatureInfo(0.2, 0.4, 0.1)
        :setModel("SensorBuoyMKIII")
        :setDescriptions(
            _("scienceDescription-artifact", "Source of unusual emanations"),
            scanned_description
        )
        :setCallSign(jammer_call_sign)
    sensor_jammer:onPickUp(M.sensorJammerPickupBasic)
    sensor_jammer_list[jammer_call_sign] = sensor_jammer
    sensor_jammer.jam_range = sensor_jammer_range
    sensor_jammer.jam_impact = sensor_jammer_impact
    sensor_jammer.jam_impact_units = sensor_jammer_power_units
    return sensor_jammer
end

function M.sensorJammerPickupExtended(self, retriever)
    local jammer_call_sign = self:getCallSign()
    sensor_jammer_list[jammer_call_sign] = nil
    if not self:isScannedBy(retriever) then
        retriever:setCanScan(false)
        retriever.scanner_dead = "scanner_dead"
        retriever:addCustomMessage(
            "Science",
            retriever.scanner_dead,
            _(
                "damage-msgScience",
                "The unscanned artifact we just picked up has fried our scanners"
            )
        )
        retriever.scanner_dead_ops = "scanner_dead_ops"
        retriever:addCustomMessage(
            "Operations",
            retriever.scanner_dead_ops,
            _(
                "damage-msgOperations",
                "The unscanned artifact we just picked up has fried our scanners"
            )
        )
    end
end

function M.sensorJammerExtended(x, y)
    artifact_counter = artifact_counter + 1
    artifact_number = artifact_number + math.random(1, 4)
    local random_suffix = string.char(math.random(65, 90))
    local jammer_call_sign =
        string.format("SJ%i%s", artifact_number, random_suffix)
    local scanned_description = string.format(
        _(
            "scienceDescription-artifact",
            "Source of emanations interfering with long range sensors. Range:%.1fu Impact:%.1fu"
        ),
        sensor_jammer_range / 1000,
        sensor_jammer_impact / 1000
    )
    local sensor_jammer = Artifact()
        :setPosition(x, y)
        :setScanningParameters(
            sensor_jammer_scan_complexity,
            sensor_jammer_scan_depth
        )
        :setRadarSignatureInfo(0.2, 0.4, 0.1)
        :setModel("SensorBuoyMKIII")
        :setDescriptions(
            _("scienceDescription-artifact", "Source of unusual emanations"),
            scanned_description
        )
        :setCallSign(jammer_call_sign)
    if sj_diagnostic then
        print(
            jammer_call_sign,
            sensor_jammer:getSectorName(),
            string.format(
                "Range:%.1fu Impact:%.1fu",
                sensor_jammer_range / 1000,
                sensor_jammer_impact / 1000
            ),
            "complexity:",
            sensor_jammer_scan_complexity,
            "depth:",
            sensor_jammer_scan_depth
        )
    end
    sensor_jammer:onPickUp(M.sensorJammerPickupExtended)
    sensor_jammer_list[jammer_call_sign] = sensor_jammer
    sensor_jammer.jam_range = sensor_jammer_range
    sensor_jammer.jam_impact = sensor_jammer_impact
    sensor_jammer.jam_impact_units = sensor_jammer_power_units
    return sensor_jammer
end

function M.updatePlayerLongRangeSensorsBasic(delta, p)
    local free_sensor_boost = false
    local sensor_boost_present = false
    local sensor_boost_amount = 0
    if p.station_sensor_boost == nil then
        local station_pool = {}
        for i, station in ipairs(inner_stations) do
            if station ~= nil and station:isValid() then
                table.insert(station_pool, station)
            end
        end
        for i, sensor_station in ipairs(station_pool) do
            if sensor_station:isValid() and p:isDocked(sensor_station) then
                if sensor_station.comms_data.sensor_boost ~= nil then
                    sensor_boost_present = true
                    if sensor_station.comms_data.sensor_boost.cost < 1 then
                        free_sensor_boost = true
                        p.station_sensor_boost =
                            sensor_station.comms_data.sensor_boost.value
                        break
                    end
                    sensor_boost_amount =
                        sensor_station.comms_data.sensor_boost.value
                end
            end
        end
    end
    local base_range = p.normal_long_range_radar
    if p.station_sensor_boost ~= nil then
        base_range = base_range + p.station_sensor_boost
    end
    if not p:getDockedWith() then
        base_range = p.normal_long_range_radar
        p.station_sensor_boost = nil
    end
    if
        p.power_sensor_interval ~= nil
        and p.power_sensor_interval > 0
        and p:getEnergyLevel() > p:getEnergyLevelMax() * 0.05
    then
        if p.power_sensor_state == nil then
            p.power_sensor_state = "disabled"
        end
        if p.power_sensor_state == "disabled" then
            p.power_sensor_state = "standby"
            updatePowerSensorButtons(p)
        elseif p.power_sensor_state == "enabled" then
            base_range = base_range
                + (1000 * p.power_sensor_interval * p.power_sensor_level)
            local power_decrement = delta * p.power_sensor_level * 2
            p:setEnergyLevel(p:getEnergyLevel() - power_decrement)
        end
    else
        if p.power_sensor_state ~= nil then
            p.power_sensor_state = "disabled"
            updatePowerSensorButtons(p)
        end
    end
    local impact_range =
        math.max(base_range * sensor_impact, p:getShortRangeRadarRange())
    local sensor_jammer_impact = 0
    for jammer_name, sensor_jammer in pairs(sensor_jammer_list) do
        if sensor_jammer ~= nil and sensor_jammer:isValid() then
            if distance_diagnostic then
                print(
                    "distance_diagnostic 13: p, sensor_jammer: update player long range sensors, sensor jammer:",
                    p:getCallSign(),
                    jammer_name
                )
            end
            local jammer_distance = distance(p, sensor_jammer)
            if jammer_distance < sensor_jammer.jam_range then
                if sensor_jammer.jam_impact_units then
                    sensor_jammer_impact = math.max(
                        sensor_jammer_impact,
                        sensor_jammer.jam_impact
                            * (1 - (jammer_distance / sensor_jammer.jam_range))
                    )
                else
                    sensor_jammer_impact = math.max(
                        sensor_jammer_impact,
                        impact_range
                            * sensor_jammer.jam_impact
                            / 100000
                            * (1 - (jammer_distance / sensor_jammer.jam_range))
                    )
                end
            end
        else
            sensor_jammer_list[jammer_name] = nil
        end
    end
    impact_range = math.max(
        p:getShortRangeRadarRange(),
        impact_range - sensor_jammer_impact
    )
    local probe_scan_boost_impact = 0
    if boost_probe_list ~= nil then
        for boost_probe_index, boost_probe in ipairs(boost_probe_list) do
            if boost_probe ~= nil and boost_probe:isValid() then
                if distance_diagnostic then
                    local bp_x, bp_y = boost_probe:getPosition()
                    print(
                        "distance_diagnostic 14: boost_probe, p: update player long range sensors, boost probe:",
                        bp_x,
                        bp_y,
                        p:getCallSign()
                    )
                end
                local boost_probe_distance = distance(boost_probe, p)
                if boost_probe_distance < boost_probe.range * 1000 then
                    if boost_probe_distance < boost_probe.range * 1000 / 2 then
                        probe_scan_boost_impact = math.max(
                            probe_scan_boost_impact,
                            boost_probe.boost * 1000
                        )
                    else
                        local best_boost = boost_probe.boost * 1000
                        local adjusted_range = boost_probe.range * 1000
                        local half_adjusted_range = adjusted_range / 2
                        local raw_scan_gradient = boost_probe_distance
                            / half_adjusted_range
                        local scan_gradient = 2 - raw_scan_gradient
                        probe_scan_boost_impact = math.max(
                            probe_scan_boost_impact,
                            best_boost * scan_gradient
                        )
                    end
                end
            else
                boost_probe_list[boost_probe_index] =
                    boost_probe_list[#boost_probe_list]
                boost_probe_list[#boost_probe_list] = nil
                break
            end
        end
    end
    impact_range = math.max(
        p:getShortRangeRadarRange(),
        impact_range + probe_scan_boost_impact
    )
    p:setLongRangeRadarRange(impact_range)
end

function M.updatePlayerLongRangeSensorsExtended(p)
    if p.normal_long_range_radar == nil then
        p.normal_long_range_radar = p:getLongRangeRadarRange()
    end
    local base_range = p.normal_long_range_radar
    local impact_range =
        math.max(base_range * sensor_impact, p:getShortRangeRadarRange())
    local sensor_jammer_impact = 0
    if jammer_count == nil then
        jammer_count = 0
    end
    local previous_jammer_count = jammer_count
    jammer_count = 0
    if sensor_jammer_diagnostic then
        local out = "Jammers: name, distance, range, impact, calculated impact"
    end
    for jammer_name, sensor_jammer in pairs(sensor_jammer_list) do
        if sensor_jammer ~= nil and sensor_jammer:isValid() then
            local jammer_distance = distance(p, sensor_jammer)
            if jammer_distance < sensor_jammer.jam_range then
                jammer_count = jammer_count + 1
                if sensor_jammer.jam_impact_units then
                    sensor_jammer_impact = math.max(
                        sensor_jammer_impact,
                        sensor_jammer.jam_impact
                            * (1 - (jammer_distance / sensor_jammer.jam_range))
                    )
                else
                    sensor_jammer_impact = math.max(
                        sensor_jammer_impact,
                        impact_range
                            * sensor_jammer.jam_impact
                            / 100000
                            * (1 - (jammer_distance / sensor_jammer.jam_range))
                    )
                end
                if sensor_jammer_diagnostic then
                    out = string.format(
                        "%s\n%s, %.1f, %.1f, %.1f, %.1f",
                        out,
                        jammer_name,
                        jammer_distance,
                        sensor_jammer.jam_range,
                        sensor_jammer.jam_impact,
                        sensor_jammer_impact
                    )
                end
            end
        else
            sensor_jammer_list[jammer_name] = nil
        end
    end
    impact_range = math.max(
        p:getShortRangeRadarRange(),
        impact_range - sensor_jammer_impact
    )
    p:setLongRangeRadarRange(impact_range)
    if sensor_jammer_diagnostic then
        if jammer_count ~= previous_jammer_count then
            print(out)
            print(
                "Selected jammer impact:",
                sensor_jammer_impact,
                "Applied:",
                impact_range,
                "Normal:",
                p.normal_long_range_radar
            )
        end
    end
end

return M
