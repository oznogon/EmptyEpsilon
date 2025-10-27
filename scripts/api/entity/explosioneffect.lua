--- An ExplosionEffect is a visual explosion used by nukes, ship destruction, and other similar events.
--- This is a cosmetic effect and does not deal damage on its own.
--- See also SmallExplosionEffect for smaller fiery explosions without impact shockwave or sparks, ElectricExplosionEffect for EMP missile effects, and KineticExplosionEffect for kinetic impacts.
--- Example: explosion = ExplosionEffect():setPosition(500,5000):setSize(20):setOnRadar(true)
function ExplosionEffect()
    local e = createEntity()
    e.components = {
        transform = {},
        explosion_effect = {size=1.0, radar=false, type="large_thermal"},
        sfx = {sound="sfx/explosion.wav"},
    }
    return e
end

--- A SmallExplosionEffect is a visual explosion used by homing missiles and other similar events.
--- Unlike ExplosionEffect, this explosion lacks an impact shockwave or sparks.
--- This is a cosmetic effect and does not deal damage on its own.
--- Example: small_explosion = SmallExplosionEffect():setPosition(500,5000):setSize(20):setOnRadar(true)
function SmallExplosionEffect()
    local e = createEntity()
    e.components = {
        transform = {},
        explosion_effect = {size=1.0, radar=false, type="small_thermal"},
        sfx = {sound="sfx/explosion.wav"},
    }
    return e
end

--- An ElectricExplosionEffect is a visual electrical explosion used by EMP missiles.
--- This is a cosmetic effect and does not deal damage on its own.
--- See also the ExplosionEffect class for conventional explosion effects.
--- Example: elec_explosion = ElectricExplosionEffect():setPosition(500,5000):setSize(20):setOnRadar(true)
function ElectricExplosionEffect()
    local e = createEntity()
    e.components = {
        transform = {},
        explosion_effect = {size=1.0, radar=false, type="electric"},
        sfx = {sound="sfx/emp_explosion.wav"},
    }
    return e
end

--- A KineticExplosionEffect is a visual kinetic impact used by HVLI missiles.
--- This is a cosmetic effect and does not deal damage on its own.
--- See also the ExplosionEffect class for conventional explosion effects.
--- Example: kinetic_explosion = KineticExplosionEffect():setPosition(500,5000):setSize(20):setOnRadar(true)
function KineticExplosionEffect()
    local e = createEntity()
    e.components = {
        transform = {},
        explosion_effect = {size=1.0, radar=false, type="kinetic"},
        sfx = {sound="sfx/explosion.wav"}, -- TODO: Kinetic impact sound
    }
    return e
end

local Entity = getLuaEntityFunctionTable()
-- Defines whether to draw the ExplosionEffect on short-range radar.
-- Defaults to false.
-- Example: explosion:setOnRadar(true)
function Entity:setOnRadar(is_on_radar)
    if self.components.explosion_effect then self.components.explosion_effect.radar = is_on_radar end
    return self
end
