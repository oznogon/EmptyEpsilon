local Entity = getLuaEntityFunctionTable()
----- MissileWeaponData API -----

--- A MissileWeaponData object stores weapon data properties for a missile type.
---
--- Missile weapon data is loaded from scripts/missileWeaponData.lua upon launching a scenario,
--- and accessed by using the getMissileWeaponData() global function.
---
--- Example:
--- mwd = MissileWeaponData():setName("Homing"):setLocaleName(_("Homing"))
--- mwd:setOrder(0):setSpeed(200):setTurnrate(10):setLifetime(27)
--- mwd:setColor(255, 0, 0, 255):setHomingRange(1200)
--- mwd:setFireSound("sfx/homing_fire.wav"):setRadarTrace("radar/blip.png")
--- mwd:setDamageAtCenter(35):setDamageAtEdge(5):setBlastRange(30)
--- mwd:setExplosionSfx("sfx/explosion.wav")
--- mwd:setRadarSignature(0.0, 0.1, 0.2)
__missile_weapon_data = {}
function MissileWeaponData()
    local fi = createEntity()
    fi.components.missile_weapon_data = {}
    return fi
end
function getMissileWeaponData(name)
    return __missile_weapon_data[name]
end

--- Sets the display order for this missile type in selection menus.
--- Lower numbers appear first.
--- Example: mwd:setOrder(0)
function Entity:setOrder(n)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.order = n
    end
    return self
end
--- Sets the icon path for this missile type in the weapon selection UI.
--- The path is relative to the resources/ directory.
--- Example: mwd:setIcon("gui/icons/weapon-homing.png")
function Entity:setIcon(icon_path)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.icon = icon_path
    end
    return self
end

--- Sets the missile's turn rate in degrees per second.
--- Example: mwd:setTurnrate(10)
function Entity:setTurnrate(v)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.turnrate = v
    end
    return self
end
--- Sets the range at which the missile begins homing toward its target.
--- Example: mwd:setHomingRange(1200)
function Entity:setHomingRange(v)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.homing_range = v
    end
    return self
end
--- Sets the sound effect played when the missile is fired.
--- Example: mwd:setFireSound("sfx/homing_fire.wav")
function Entity:setFireSound(s)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.fire_sound = s
    end
    return self
end
--- Sets the damage dealt at the center of the blast.
--- Example: mwd:setDamageAtCenter(35)
function Entity:setDamageAtCenter(v)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.damage_at_center = v
    end
    return self
end
--- Sets the damage dealt at the edge of the blast.
--- Example: mwd:setDamageAtEdge(5)
function Entity:setDamageAtEdge(v)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.damage_at_edge = v
    end
    return self
end
--- Sets the blast radius in units.
--- Example: mwd:setBlastRange(30)
function Entity:setBlastRange(v)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.blast_range = v
    end
    return self
end
--- Sets the explosion sound effect played on detonation.
--- Example: mwd:setExplosionSfx("sfx/explosion.wav")
function Entity:setExplosionSfx(s)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.explosion_sfx = s
    end
    return self
end
--- Sets the radar signature (electrical, thermal, gravitational).
--- Values are floats, typically in the 0.0–1.0 range.
--- Example: mwd:setRadarSignature(0.0, 0.1, 0.2)
function Entity:setRadarSignature(electrical, thermal, gravitational)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.radar_electrical = electrical
        self.components.missile_weapon_data.radar_thermal = thermal
        self.components.missile_weapon_data.radar_gravitational = gravitational
    end
    return self
end
--- Sets whether the missile explodes when its lifetime expires instead of despawning.
--- Example: mwd:setExplodesOnTimeout(true)
function Entity:setExplodesOnTimeout(bool)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.explodes_on_timeout = bool
    end
    return self
end
--- Sets whether the missile has a delayed explosion after impact.
--- Example: mwd:setIsDelayedExplode(true)
function Entity:setIsDelayedExplode(bool)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.is_delayed_explode = bool
    end
    return self
end
--- Sets the number of missiles fired per volley.
--- Example: mwd:setFireCount(5)
function Entity:setFireCount(n)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.fire_count = n
    end
    return self
end
--- Sets the damage type string ("Kinetic" or "EMP").
--- Example: mwd:setDamageType("EMP")
function Entity:setDamageType(s)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.damage_type = s
    end
    return self
end
--- Sets the delay in seconds before the missile begins avoiding objects.
--- Example: mwd:setAvoidObjectDelay(10)
function Entity:setAvoidObjectDelay(n)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.avoid_object_delay = n
    end
    return self
end
--- Sets whether the missile uses circle collision detection.
--- Example: mwd:setCircleCollision(true)
function Entity:setCircleCollision(bool)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.circle_collision = bool
    end
    return self
end
--- Sets whether the missile has no lifetime limit on spawned missiles.
--- Example: mwd:setNoLifetimeOnMissile(true)
function Entity:setNoLifetimeOnMissile(bool)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.no_lifetime_on_missile = bool
    end
    return self
end
--- Sets whether this missile type appears on player crew screens.
--- If true (default), the missile type is visible on crew screens.
--- If false, the missile type is hidden from crew screens and only
--- accessible via scripting and GM screens.
--- Example: mwd:setPlayer(false)
function Entity:setPlayer(bool)
    if self.components.missile_weapon_data then
        self.components.missile_weapon_data.player = bool
    end
    return self
end
