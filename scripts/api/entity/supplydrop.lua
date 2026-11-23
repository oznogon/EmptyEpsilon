local supplyDropPrefab = Prefab("SupplyDrop", SpaceObjectPrefab, {
    components = {
        physics = { type = "Sensor" },
        radar_trace = {
            color = { 100, 200, 255 },
            icon = "radar/blip.png",
            radius = 120.0,
            rotate = false,
            color_by_faction = true,
        },
        pickup = {},
        docking_port = {
            dock_class = _("class", "Cargo"),
        },
    },
    generate = function(ctx)
        return prefabModelComponents("ammo_box")
    end,
})

--- A SupplyDrop is a collectible item picked up on collision with a friendly ship.
--- On pickup, the SupplyDrop can restock the colliding ship's weapons. Define SupplyDrop stocks and capacity with setWeaponStorage(), which doesn't have any defined maximum.
--- If the ship has the Reactor component, the collected SupplyDrop can also recharge the ship's energy. Define SupplyDrop energy storage with setEnergy(), which doesn't have any defined maximum.
--- A SupplyDrop can also trigger a scripting function upon pickup. Define SupplyDrop callback with onPickUp().
--- For a more generic entity type with similar collision properties, see Artifact.
--- Example: SupplyDrop():setEnergy(500):setWeaponStorage("Homing", 6)
--- @type creation
function SupplyDrop()
    return supplyDropPrefab:spawn()
end
