local Entity = getLuaEntityFunctionTable()

-- Functions that have multiple implementations as a result of the old object code are here and interact with multiple components.

--- Sets this faction's internal string name, used to reference this faction regardless of EmptyEpsilon's language setting.
--- If no locale name is defined, this sets the locale name to the same value.
--- Example: faction:setName("USN")
--- Sets this ScienceDatabase entry's displayed name.
--- Example: entry:setName("Species")
function Entity:setName(name)
    if self.components.faction_info then
        self.components.faction_info.name = name
        __faction_info[name] = self
    end
    if self.components.science_database then
        self.components.science_database.name = name
    end
    return self
end

--- Sets this faction's longform description as shown in its Factions ScienceDatabase child entry.
--- Wrap the string in the _() function to make it available for translation.
--- Example: faction:setDescription(_("The United Stellar Navy, or USN...")) -- sets a translatable description for this faction
--- As setDescriptions, but sets the same description for both unscanned and scanned states.
--- Example: obj:setDescription("A refitted Atlantis X23 for more ...")
function Entity:setDescription(description)
    if self.components.faction_info then
        self.components.faction_info.description = description
    else
        self.components.science_description = {not_scanned=description, friend_or_foe_identified=description, simple_scan=description, full_scan=description}
    end
    return self
end

--- Sets this entity's radius.
--- Default sizes vary by entity type. Asteroids default to random values between 110 and 130. Explosions default to 1.0.
--- If the entity as an AvoidObject component, this also sets that radius to 2x the given value.
--- Examples: obj:setSize(150) -- sets the entity's size to 150
---           explosion:setSize(1000) -- sets the explosion radius to 1U
function Entity:setSize(radius)
    local comp = self.components
    if comp.physics then comp.physics.size=radius end
    if comp.mesh_render then comp.mesh_render.scale=radius end
    if comp.avoid_object then comp.avoid_object.range=radius*2 end
    if comp.explosion_effect then comp.explosion_effect.size=radius end
    if comp.explode_on_touch then comp.explode_on_touch.blast_range=radius end
    return self
end

--- Returns this entity's radius.
--- If the entity has a Physics component, this returns that value.
--- If not, this returns the radius of its 3D mesh, or 100 by default.
--- Example: obj:getSize()
function Entity:getSize()
    local comp = self.components
    if comp.physics then return comp.physics.size end
    if comp.mesh_render then return comp.mesh_render.scale end
    return 100.0
end

--- Sets this SpaceShip's energy level.
--- Valid values are any greater than 0 and less than the energy capacity (getMaxEnergy()).
--- Invalid values are ignored.
--- CpuShips don't consume energy. Setting this value has no effect on their behavior or functionality.
--- For PlayerSpaceships, see PlayerSpaceship:setEnergyLevel().
--- Example: ship:setEnergy(1000) -- sets the ship's energy to 1000 if its capacity is 1000 or more
--- Sets the amount of energy recharged upon pickup when a PlayerSpaceship collides with this SupplyDrop.
--- Example: supply_drop:setEnergy(500)
function Entity:setEnergy(amount)
    if self.components.reactor then self.components.reactor.energy = amount end
    if self.components.pickup then self.components.pickup.give_energy = amount end
    return self
end

--- Returns this SpaceShip's weapons target.
--- For a CpuShip, this can differ from its orders target.
--- Example: target = ship:getTarget()
--- Returns this ScanProbe's target coordinates.
--- Example: targetX,targetY = probe:getTarget()
function Entity:getTarget()
    if self.components.weapons_target then
        return self.components.weapons_target.entity
    end
    if self.components.move_to then
        local target = self.components.move_to.target
        return target[1], target[2]
    end
    return nil
end

--- Returns this ScanProbe's owner SpaceObject.
--- Example: probe:getOwner()
function Entity:getOwner()
    if self.components.delayed_explode_on_touch then
        return self.components.delayed_explode_on_touch.owner
    end
    if self.components.allow_radar_link then
        return self.components.allow_radar_link.owner
    end
    return self
end

--- Sets this ScanProbe's target coordinates.
--- If the probe has reached its target, ScanProbe:setTarget() moves it again toward the new target coordinates.
--- Example: probe:setTarget(1000,5000)
--- Sets the BeamEffect's target SpaceObject.
--- Requires a 3D x/y/z vector positional offset relative to the object's origin point.
--- Example: beamfx:setTarget(target,0,0,0)
function Entity:setTarget(a, b, c, d)
    if self.components.allow_radar_link then -- Scan probe, order it to move the the target.
        self.components.move_to = {target={a, b}}
    end
    if self.components.beam_effect then
        self.components.beam_effect.target = a
        self.components.beam_effect.target_offset = {b, c, d}
    end
    return self
end

--- Returns this entity's weapons radar target.
--- Example: target = ship:getWeaponsTarget()
function Entity:getWeaponsTarget()
    if self.components.weapons_target then
        return self.components.weapons_target.entity
    end
    return nil
end

--- Sets this entity's weapons radar target.
--- Only sets the target if the entity is valid and not own ship.
--- To clear the target, use clearWeaponsTarget().
--- Example: ship:setWeaponsTarget(enemy)
function Entity:setWeaponsTarget(target)
    if target and target:isValid() and target ~= self then
        self.components.weapons_target = {entity = target}
    end
    return self
end

--- Clears this entity's weapons radar target.
--- Example: ship:clearWeaponsTarget()
function Entity:clearWeaponsTarget()
    self.components.weapons_target = nil
    return self
end

--- Returns this entity's Science/Operations radar selection target.
--- This is the entity selected on the Science/Operations radar, separate from active scanning.
--- Example: target = ship:getScienceTarget()
function Entity:getScienceTarget()
    if self.components.science_target then
        return self.components.science_target.entity
    end
    return nil
end

--- Sets this entity's Science/Operations radar selection target.
--- This is the entity selected on the Science/Operations radar, separate from active scanning.
--- Only sets the target if the entity is valid and not own ship.
--- To clear the target, use clearScienceTarget().
--- Example: ship:setScienceTarget(unknown_object)
function Entity:setScienceTarget(target)
    if target and target:isValid() and target ~= self then
        self.components.science_target = {entity = target}
    end
    return self
end

--- Clears this entity's Science/Operations radar selection target.
--- Example: ship:clearScienceTarget()
function Entity:clearScienceTarget()
    self.components.science_target = nil
    return self
end

--- Returns the target of this entity's active science scan.
--- This is the entity currently being scanned, separate from radar selection.
--- Example: target = ship:getScienceScannerTarget()
function Entity:getScienceScannerTarget()
    if self.components.science_scanner then
        return self.components.science_scanner.target
    end
    return nil
end

--- Sets the target of this entity's active science scan.
--- This is the entity currently being scanned, separate from radar selection.
--- Only sets the target if the entity is valid and not own ship.
--- To clear the target, use clearScienceScannerTarget().
--- Example: ship:setScienceScannerTarget(target_obj)
function Entity:setScienceScannerTarget(target)
    if self.components.science_scanner then
        if target and target:isValid() and target ~= self then
            self.components.science_scanner.target = target
        end
    end
    return self
end

--- Clears the target of this entity's active science scan.
--- Example: ship:clearScienceScannerTarget()
function Entity:clearScienceScannerTarget()
    if self.components.science_scanner then
        self.components.science_scanner.target = nil
    end
    return self
end

--- Returns this PlayerSpaceship's relay radar selection target.
--- This is the entity selected on the Relay/Strategic Map radar.
--- This is separate from active comms or hacking operations.
--- Example: target = ship:getRelayTarget()
function Entity:getRelayTarget()
    if self.components.relay_target then
        return self.components.relay_target.entity
    end
    return nil
end

--- Sets this PlayerSpaceship's relay radar selection target.
--- This is the entity selected on the Relay/Strategic Map radar.
--- This is separate from active comms or hacking operations.
--- Only sets the target if the entity is valid and not own ship.
--- To clear the target, use clearRelayTarget().
--- Example: ship:setRelayTarget(station)
function Entity:setRelayTarget(target)
    if target and target:isValid() and target ~= self then
        self.components.relay_target = {entity = target}
    end
    return self
end

--- Clears this PlayerSpaceship's relay radar selection target.
--- Example: ship:clearRelayTarget()
function Entity:clearRelayTarget()
    self.components.relay_target = nil
    return self
end

--- Returns this PlayerSpaceship's active hacking target.
--- This is the entity currently being hacked.
--- Example: target = ship:getHackTarget()
function Entity:getHackTarget()
    if self.components.hacking_device then
        return self.components.hacking_device.target
    end
    return nil
end

--- Sets this PlayerSpaceship's active hacking target.
--- This is the entity currently being hacked.
--- Only sets the target if the entity is valid and not own ship.
--- To clear the target, use clearHackTarget().
--- Example: ship:setHackTarget(station)
function Entity:setHackTarget(target)
    if self.components.hacking_device then
        if target and target:isValid() and target ~= self then
            self.components.hacking_device.target = target
        end
    end
    return self
end

--- Clears this PlayerSpaceship's active hacking target.
--- Example: ship:clearHackTarget()
function Entity:clearHackTarget()
    if self.components.hacking_device then
        self.components.hacking_device.target = nil
    end
    return self
end

--- Returns this PlayerSpaceship's active comms target.
--- This is the entity with an active comms channel open.
--- Example: target = ship:getCommsTarget()
function Entity:getCommsTarget()
    if self.components.comms_transmitter then
        return self.components.comms_transmitter.target
    end
    return nil
end

--- Sets this PlayerSpaceship's active comms target.
--- This is the entity with an active comms channel open.
--- Only sets the target if the entity is valid and not own ship.
--- To clear the target, use clearCommsTarget().
--- Example: ship:setCommsTarget(station)
function Entity:setCommsTarget(target)
    if self.components.comms_transmitter then
        if target and target:isValid() and target ~= self then
            self.components.comms_transmitter.target = target
        end
    end
    return self
end

--- Clears this PlayerSpaceship's active comms target.
--- Example: ship:clearCommsTarget()
function Entity:clearCommsTarget()
    if self.components.comms_transmitter then
        self.components.comms_transmitter.target = nil
    end
    return self
end
