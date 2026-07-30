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
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.name = name
        __missile_weapon_data[name] = self
    end
    return self
end

--- Sets the locale (translated) name for factions and missile weapon data.
--- For factions: the name as presented in the user interface.
--- For missile weapon data: the translatable display name for the missile type.
--- Wrap the string in the _() function to make it available for translation.
--- Example: faction:setLocaleName(_("USN"))
--- Example: mwd:setLocaleName(_("Homing"))
function Entity:setLocaleName(name)
    if self.components.faction_info then
        self.components.faction_info.locale_name = name
    end
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.locale_name = name
    end
    return self
end

--- For factions, sets this faction's longform description as shown in its ScienceDatabase child entry.
--- Wrap the string in the _() function to make it available for translation.
--- For other entities, this works as setDescriptions, but sets the same description for both unscanned and scanned states.
--- For ship templates, see ShipTemplate:setDescription().
--- Examples:
--- faction:setDescription(_("The United Stellar Navy, or USN...")) -- sets a translatable description for this faction
--- Example: obj:setDescription("A refitted Atlantis X23 for more ...")
function Entity:setDescription(description)
    if self.components.faction_info then
        self.components.faction_info.description = description
    else
        self.components.science_description = {
            not_scanned = description,
            friend_or_foe_identified = description,
            simple_scan = description,
            full_scan = description,
        }
    end
    return self
end

--- Sets this entity's radius.
--- Default sizes vary by entity type. Asteroids default to random values between 110 and 130. Explosions default to 1.0.
--- If the entity has an AvoidObject component, this also sets that radius to 2x the given value.
--- Examples: obj:setSize(150) -- sets the entity's size to 150
---           explosion:setSize(1000) -- sets the explosion radius to 1U
function Entity:setSize(radius)
    local comp = self.components
    if comp.physics then
        comp.physics.size = radius
    end
    if comp.mesh_render then
        comp.mesh_render.scale = radius
    end
    if comp.avoid_object then
        comp.avoid_object.range = radius * 2
    end
    if comp.explosion_effect then
        comp.explosion_effect.size = radius
    end
    if comp.explode_on_touch then
        comp.explode_on_touch.blast_range = radius
    end
    if comp.radar_trace then
        comp.radar_trace.radius = radius
    end
    return self
end

--- Returns this entity's radius.
--- If the entity has a Physics component, this returns that value.
--- If not, this returns the radius of its 3D mesh, or 100 by default.
--- Example: obj:getSize()
function Entity:getSize()
    local comp = self.components
    if comp.physics then
        return comp.physics.size
    end
    if comp.mesh_render then
        return comp.mesh_render.scale
    end
    return 100.0
end

--- Sets this ship's energy level.
--- Valid values are any greater than 0 and less than the energy capacity (getMaxEnergy()).
--- Invalid values are ignored.
--- CPU ships don't consume energy. Setting this value has no effect on their behavior or functionality.
--- For player ships, see setEnergyLevel().
--- Example: ship:setEnergy(1000) -- sets the ship's energy to 1000 if its capacity is 1000 or more
--- Sets the amount of energy recharged upon pickup when a player ship collides with this SupplyDrop.
--- Example: supply_drop:setEnergy(500)
function Entity:setEnergy(amount)
    if self.components.reactor then
        self.components.reactor.energy = amount
    end
    if self.components.pickup then
        self.components.pickup.give_energy = amount
    end
    return self
end

--- Sets the speed of ScanProbes and missiles.
--- For ScanProbes: sets the travel speed (default 1000, 1U/second).
--- For missiles: sets the missile's travel speed in units per second.
--- Examples:
---   probe:setSpeed(2000)
---   mwd:setSpeed(200)
function Entity:setSpeed(speed)
    if self.components.move_to then
        self.components.move_to.speed = speed
    end
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.speed = speed
    end
    return self
end

--- Sets the remaining lifetime of ScanProbes and missiles.
--- For ScanProbes: lifetime in seconds (default 600).
--- For missiles: lifetime in seconds before it despawns.
--- Examples:
---   probe:setLifetime(60 * 5) -- 5 minutes
---   mwd:setLifetime(27)
function Entity:setLifetime(lifetime)
    if self.components.lifetime then
        self.components.lifetime.lifetime = lifetime
    end
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.lifetime = lifetime
    end
    return self
end

--- Sets the radar trace image for entities and missiles.
--- For ship entities: prepends "radar/" to the filename. Valid values are filenames relative to the resources/radar directory.
--- For missiles: sets the raw radar trace image path.
--- Examples:
---   entity:setRadarTrace("arrow.png") -- resources/radar/arrow.png
---   mwd:setRadarTrace("radar/blip.png")
function Entity:setRadarTrace(filename)
    if self.components.radar_trace then
        self.components.radar_trace.icon = "radar/" .. filename
    end
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.radar_trace = filename
    end
    return self
end

--- Sets the color of Zones and missiles.
--- For Zones: sets both outline and fill color. Values are unsigned bytes (0-255).
--- For missiles: sets the RGBA color of the missile's trail and model.
--- Examples:
---   zone:setColor(255,140,0)
---   mwd:setColor(255, 0, 0, 255)
function Entity:setColor(r, g, b, a)
    local alpha = a ~= nil and a or 255
    if self.components.zone then
        self.components.zone.color = { r, g, b, alpha }
        self.components.zone.fill_color = { r, g, b, 64 }
    end
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.color = { r, g, b, alpha }
    end
    return self
end

--- Returns this ship's weapons target.
--- For a CPU ship, this can differ from its orders target.
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

--- Returns the entity targeted by this entity's weapons (beam/missile).
--- Returns nil if no weapons target is set.
--- Example: target = ship:getWeaponsTarget()
function Entity:getWeaponsTarget()
    if self.components.weapons_target then
        return self.components.weapons_target.entity
    end
    return nil
end

--- Returns the entity this entity is scanning.
--- Returns nil if no scan target is set.
--- Example: target = ship:getScanTarget()
function Entity:getScanTarget()
    if self.components.science_scanner then
        return self.components.science_scanner.target
    end
    return nil
end

--- Returns the entity this entity is communicating with.
--- Returns nil if no comms target is set.
--- Example: target = ship:getCommsTarget()
function Entity:getCommsTarget()
    if self.components.comms_transmitter then
        return self.components.comms_transmitter.target
    end
    return nil
end

--- Returns the entity targeted by this entity's beam weapons.
--- Returns nil if no beam weapon target is set.
--- Example: target = ship:getBeamWeaponTarget()
function Entity:getBeamWeaponTarget()
    if self.components.beam_weapon_target then
        return self.components.beam_weapon_target.entity
    end
    return nil
end

--- Returns the entity targeted by this entity's missile weapons.
--- Returns nil if no missile weapon target is set.
--- Example: target = ship:getMissileWeaponTarget()
function Entity:getMissileWeaponTarget()
    if self.components.missile_weapon_target then
        return self.components.missile_weapon_target.entity
    end
    return nil
end

--- Returns the entity targeted for hacking.
--- Returns nil if no hack target is set.
--- Example: target = ship:getHackTarget()
function Entity:getHackTarget()
    if self.components.hack_target then
        return self.components.hack_target.entity
    end
    return nil
end

--- Returns this ScanProbe's owner entity.
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
--- If the probe has reached its target, setTarget() moves it again toward the new target coordinates.
--- Example: probe:setTarget(1000,5000)
--- Sets the BeamEffect's target entity.
--- Requires a 3D x/y/z vector positional offset relative to the object's origin point.
--- Example: beamfx:setTarget(target,0,0,0)
function Entity:setTarget(a, b, c, d)
    if self.components.allow_radar_link then -- Scan probe, order it to move the the target.
        self.components.move_to = { target = { a, b } }
    end
    if self.components.beam_effect then
        self.components.beam_effect.target = a
        self.components.beam_effect.target_offset = { b, c, d }
    end
    return self
end
