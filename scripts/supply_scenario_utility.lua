-- Shared supply pickup handling, used in Rescue, Defenders or Pirates, and Iris Siege.

local M = {}

function M.supplyPickupProcess(self, player)
    if self.repairCrew ~= nil then
        player:setRepairCrewCount(player:getRepairCrewCount() + self.repairCrew)
    end
    if self.coolant ~= nil then
        player:setMaxCoolant(player:getMaxCoolant() + self.coolant)
    end
    if self.probes ~= nil then
        player:setScanProbeCount(
            math.min(
                player:getScanProbeCount() + self.probes,
                player:getMaxScanProbeCount()
            )
        )
    end
    if self.armor ~= nil then
        player:setHull(
            math.min(player:getHull() + self.armor, player:getHullMax())
        )
    end
    if player:hasJumpDrive() then
        if self.jump_charge ~= nil then
            player:setJumpDriveCharge(
                player:getJumpDriveCharge() + self.jump_charge
            )
        end
    end
end

return M
