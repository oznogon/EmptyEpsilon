#include "shipTemplateBasedObject.h"

#include "scriptInterface.h"

#include "tween.h"
#include "i18n.h"

/// A ShipTemplateBasedObject (STBO) is an object created from a ShipTemplate.
/// This is the parent class of SpaceShip and SpaceStation objects, and can't be created by scripts on its own.
REGISTER_SCRIPT_SUBCLASS_NO_CREATE(ShipTemplateBasedObject, SpaceObject)
{
    /// Sets the template used to define this STBO's traits.
    /// Templates define the ship's class, weapons, hull and shield strength, 3D model, and more.
    /// See the ShipTemplate class for details.
    /// Examples:
    /// CpuShip():setTemplate("Phobos T3")
    /// PlayerSpaceship():setTemplate("Phobos M3P")
    /// SpaceStation():setTemplate("Large Station")
    /// WARNING: Using a string that is not a valid template name will crash the game!
    /// ShipTemplate string names are case-sensitive.
    /// See scripts/shipTemplates.lua and scripts/shiptemplates/ for the default templates.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setTemplate);
    /// [DEPRECATED]
    /// Use ShipTemplateBasedObject:setTemplate()
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setShipTemplate);
    /// Sets the STBO's classification name, such as "Starfighter" or "Cruiser".
    /// This overrides the class name provided in the ShipTemplate.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setTypeName);
    /// Gets the STBO's classification name.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getTypeName);
    /// Gets the STBO's hull points.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getHull);
    /// Gets the STBO's maximum limit of hull points.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getHullMax);
    /// Sets the STBO's hull points.
    /// Setting this to 0 does not destroy the STBO.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setHull);
    /// Sets the STBO's maximum limit of hull points.
    /// Note: Stations never repair hull damage, so this only affects their percentage displays.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setHullMax);
    /// Sets whether the STBO can be destroyed.
    /// Example: ship:setCanBeDestroyed(true)
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setCanBeDestroyed);
    /// Returns whether the STBO can be destroyed.
    /// Example: ship:getCanBeDestroyed()
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getCanBeDestroyed);
    /// Returns the STBO's given shield segment's points.
    /// Requires an integer shield segment index value.
    /// Example for a ship with two shield segments, front and rear:
    ///     ship:getShieldLevel(0) -- returns front shield points
    ///     ship:getShieldLevel(1) -- returns rear shield points
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getShieldLevel);
    /// Returns the STBO's number of shield segments.
    /// For example, a ship with 1 shield segment has a single shield covering all angles.
    /// A ship with 2 shield segments has separate shields covering the front and back.
    /// Example: ship:getShieldCount()
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getShieldCount);
    /// Returns the STBO's given shield segment's maximum points.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getShieldMax);
    /// Sets the STBO's shield points.
    /// Each number provided as a parameter sets the points for a corersponding shield segment.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setShields);
    /// Sets the STBO's maximum shield points.
    /// The number of parameters defines the number of shield segments, to a maximum of 8 segments.
    /// Setting a lower maximum value than the segment's current number of points reduces the points, but increasing the maximum value to a higher value than the current points does NOT automatically increase the current points.
    /// A seperate call to setShield is needed for that.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setShieldsMax);
    /// Sets the STBO's radar trace image.
    /// Valid values are filenames of PNG files relative to the resources/radar/ directory.
    /// Example: obj:setRadarTrace("arrow.png") -- sets the radar trace to resources/radar/arrow.png
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setRadarTrace);
    /// Sets the sound file for this object's impulse engines.
    /// Valid values are filenames of WAV files relative to the resources/ directory.
    /// Example: setImpulseSoundFile("sfx/engine.wav") -- sets the impulse sound to resources/sfx/engine.wav
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setImpulseSoundFile);
    /// Defines whether the STBO's shields are activated.
    /// Always returns true except for PlayerSpaceships, because only players can turn off shields.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getShieldsActive);
    /// Returns whether the STBO supplies energy to docked ships.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getSharesEnergyWithDocked);
    /// Defines whether the STBO supplies energy to docked ships.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setSharesEnergyWithDocked);
    /// Returns whether the STBO repairs docked ships.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getRepairDocked);
    /// Sets whether the STBO repairs docked ships.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setRepairDocked);
    /// Returns whether the STBO restocks scan probes for docked ships.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getRestocksScanProbes);
    /// Sets whether the STBO restocks scan probes for docked ships.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setRestocksScanProbes);
    /// Returns whether the STBO restocks missiles for docked ships.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getRestocksMissilesDocked);
    /// Sets whether the STBO restocks missiles for docked ships.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setRestocksMissilesDocked);
    /// Returns the STBO's long-range radar range. 
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getLongRangeRadarRange);
    /// Sets the STBO's long-range radar range.
    /// PlayerSpaceships use this range on the science and operations screens' radar.
    /// CpuShips use this range to detect potential targets.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setLongRangeRadarRange);
    /// Returns the STBO's short-range radar range.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getShortRangeRadarRange);
    /// Sets the STBO's short-range radar range.
    /// PlayerSpaceships use this range on the helms, weapons, and single pilot screens' radar.
    /// This also defines the radar radius on the relay screen for friendly ships and stations.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setShortRangeRadarRange);
    /// [DEPRECATED]
    /// Use ShipTemplateBasedObject:getShieldLevel() with an index value.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getFrontShield);
    /// [DEPRECATED]
    /// Use ShipTemplateBasedObject:setShieldsMax().
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getFrontShieldMax);
    /// [DEPRECATED]
    /// Use ShipTemplateBasedObject:setShieldLevel() with an index value.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setFrontShield);
    /// [DEPRECATED]
    /// Use ShipTemplateBasedObject:setShieldsMax().
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setFrontShieldMax);
    /// [DEPRECATED]
    /// Use ShipTemplateBasedObject:getShieldLevel() with an index value.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getRearShield);
    /// [DEPRECATED]
    /// Use ShipTemplateBasedObject:setShieldsMax().
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, getRearShieldMax);
    /// [DEPRECATED]
    /// Use ShipTemplateBasedObject:setShieldLevel() with an index value.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setRearShield);
    /// [DEPRECATED]
    /// Use ShipTemplateBasedObject:setShieldsMax().
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, setRearShieldMax);
    /// Defines a function to call when the STBO takes damage.
    /// Passes the object taking damage and the instigator SpaceObject (or nil) to the function.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, onTakingDamage);
    /// Defines a function to call when the STBO is destroyed by taking damage.
    /// Passes the object taking damage and the instigator SpaceObject that delivered the destroying damage (or nil) to the function.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplateBasedObject, onDestruction);
}

ShipTemplateBasedObject::ShipTemplateBasedObject(float collision_range, string multiplayer_name, float multiplayer_significant_range)
: SpaceObject(collision_range, multiplayer_name, multiplayer_significant_range)
{
    setCollisionPhysics(true, true);

    shield_count = 0;
    for(int n=0; n<max_shield_count; n++)
    {
        shield_level[n] = 0.0;
        shield_max[n] = 0.0;
        shield_hit_effect[n] = 0.0;
    }
    hull_strength = hull_max = 100.0;

    long_range_radar_range = 30000.0f;
    short_range_radar_range = 5000.0f;

    registerMemberReplication(&template_name);
    registerMemberReplication(&type_name);
    registerMemberReplication(&shield_count);
    for(int n=0; n<max_shield_count; n++)
    {
        registerMemberReplication(&shield_level[n], 0.5);
        registerMemberReplication(&shield_max[n]);
        registerMemberReplication(&shield_hit_effect[n], 0.5);
    }
    registerMemberReplication(&radar_trace);
    registerMemberReplication(&impulse_sound_file);
    registerMemberReplication(&hull_strength, 0.5);
    registerMemberReplication(&hull_max);
    registerMemberReplication(&long_range_radar_range, 0.5);
    registerMemberReplication(&short_range_radar_range, 0.5);

    callsign = "[" + string(getMultiplayerId()) + "]";

    can_be_destroyed = true;
    registerMemberReplication(&can_be_destroyed);
}

void ShipTemplateBasedObject::drawShieldsOnRadar(sp::RenderTarget& renderer, glm::vec2 position, float scale, float rotation, float sprite_scale, bool show_levels)
{
    if (!getShieldsActive())
        return;
    if (shield_count == 1)
    {
        glm::u8vec4 color = glm::u8vec4(255, 255, 255, 64);
        if (show_levels)
        {
            float level = shield_level[0] / shield_max[0];
            color = Tween<glm::u8vec4>::linear(level, 1.0f, 0.0f, glm::u8vec4(128, 128, 255, 128), glm::u8vec4(255, 0, 0, 64));
        }
        if (shield_hit_effect[0] > 0.0f)
        {
            color = Tween<glm::u8vec4>::linear(shield_hit_effect[0], 0.0f, 1.0f, color, glm::u8vec4(255, 0, 0, 128));
        }
        renderer.drawSprite("shield_circle.png", position, sprite_scale * 0.25f * 1.5f * 256.0f, color);
    }else if (shield_count > 1) {
        float direction = getRotation()-rotation;
        float arc = 360.0f / float(shield_count);

        for(int n=0; n<shield_count; n++)
        {
            glm::u8vec4 color = glm::u8vec4(255, 255, 255, 64);
            if (show_levels)
            {
                float level = shield_level[n] / shield_max[n];
                color = Tween<glm::u8vec4>::linear(level, 1.0f, 0.0f, glm::u8vec4(128, 128, 255, 128), glm::u8vec4(255, 0, 0, 64));
            }
            if (shield_hit_effect[n] > 0.0f)
            {
                color = Tween<glm::u8vec4>::linear(shield_hit_effect[n], 0.0f, 1.0f, color, glm::u8vec4(255, 0, 0, 128));
            }

            glm::vec2 delta_a = vec2FromAngle(direction - arc / 2.0f);
            glm::vec2 delta_b = vec2FromAngle(direction);
            glm::vec2 delta_c = vec2FromAngle(direction + arc / 2.0f);
            
            auto p0 = position + delta_b * sprite_scale * 32.0f * 0.05f;
            renderer.drawTexturedQuad("shield_circle.png",
                p0,
                p0 + delta_a * sprite_scale * 32.0f * 1.5f,
                p0 + delta_b * sprite_scale * 32.0f * 1.5f,
                p0 + delta_c * sprite_scale * 32.0f * 1.5f,
                glm::vec2(0.5, 0.5),
                glm::vec2(0.5, 0.5) + delta_a * 0.5f,
                glm::vec2(0.5, 0.5) + delta_b * 0.5f,
                glm::vec2(0.5, 0.5) + delta_c * 0.5f,
                color);
            direction += arc;
        }
    }
}

void ShipTemplateBasedObject::draw3DTransparent()
{
    if (shield_count < 1)
        return;

    float angle = 0.0;
    float arc = 360.0f / shield_count;
    const auto model_matrix = getModelMatrix();
    for(int n = 0; n<shield_count; n++)
    {
        if (shield_hit_effect[n] > 0)
        {
            if (shield_count > 1)
            {
                model_info.renderShield(model_matrix, (shield_level[n] / shield_max[n]) * shield_hit_effect[n], angle);
            }else{
                model_info.renderShield(model_matrix, (shield_level[n] / shield_max[n]) * shield_hit_effect[n]);
            }
        }
        angle += arc;
    }
}

void ShipTemplateBasedObject::update(float delta)
{
    // All ShipTemplateBasedObjects should have a valid template.
    // If this object lacks a template, or has an inconsistent template...
    if (!ship_template || ship_template->getName() != template_name)
    {
        // Attempt to align the object's template to its reported template name.
        ship_template = ShipTemplate::getTemplate(template_name);

        // If the template still doesn't exist, destroy the object.
        if (!ship_template)
        {
            LOG(ERROR) << "ShipTemplateBasedObject with ID " << string(getMultiplayerId()) << " lacked a template, so it was destroyed.";
            destroy();
            return;
        }

        // If it does exist, set up its collider and model.
        ship_template->setCollisionData(this);
        model_info.setData(ship_template->model_data);
    }

    for(int n=0; n<shield_count; n++)
    {
        if (shield_level[n] < shield_max[n])
        {
            shield_level[n] = std::min(shield_max[n], shield_level[n] + delta * getShieldRechargeRate(n));
        }
        if (shield_hit_effect[n] > 0)
        {
            shield_hit_effect[n] -= delta;
        }
    }
}

std::unordered_map<string, string> ShipTemplateBasedObject::getGMInfo()
{
    std::unordered_map<string, string> ret;
    ret[trMark("gm_info", "CallSign")] = callsign;
    ret[trMark("gm_info", "Type")] = type_name;
    ret[trMark("gm_info", "Hull")] = string(hull_strength) + "/" + string(hull_max);
    for(int n=0; n<shield_count; n++)
    {
        // Note, translators: this is a compromise.
        // Because of the deferred translation the variable parameter can't be forwarded, so it'll always be a suffix.
        ret[trMark("gm_info", "Shield") + string(n + 1)] = string(shield_level[n]) + "/" + string(shield_max[n]);
    }
    return ret;
}

bool ShipTemplateBasedObject::hasShield()
{
    for(int n=0; n<shield_count; n++)
    {
        if (shield_level[n] < shield_max[n] / 50)
            return false;
    }
    return true;
}

void ShipTemplateBasedObject::takeDamage(float damage_amount, DamageInfo info)
{
    if (shield_count > 0 && getShieldsActive())
    {
        float angle = angleDifference(getRotation(), vec2ToAngle(info.location - getPosition()));
        if (angle < 0)
            angle += 360.0f;
        float arc = 360.0f / float(shield_count);
        int shield_index = int((angle + arc / 2.0f) / arc);
        shield_index %= shield_count;

        float shield_damage = damage_amount * getShieldDamageFactor(info, shield_index);
        damage_amount -= shield_level[shield_index];
        shield_level[shield_index] -= shield_damage;
        if (shield_level[shield_index] < 0)
        {
            shield_level[shield_index] = 0.0;
        } else {
            shield_hit_effect[shield_index] = 1.0;
        }
        if (damage_amount < 0.0f)
        {
            damage_amount = 0.0;
        }
    }

    if (info.type != DT_EMP && damage_amount > 0.0f)
    {
        takeHullDamage(damage_amount, info);
    }

    if (hull_strength > 0)
    {
        if (on_taking_damage.isSet())
        {
            if (info.instigator)
            {
                on_taking_damage.call<void>(P<ShipTemplateBasedObject>(this), P<SpaceObject>(info.instigator));
            } else {
                on_taking_damage.call<void>(P<ShipTemplateBasedObject>(this));
            }
        }
    }
}

void ShipTemplateBasedObject::takeHullDamage(float damage_amount, DamageInfo& info)
{
    hull_strength -= damage_amount;
    if (hull_strength <= 0.0f && !can_be_destroyed)
    {
        hull_strength = 1;
    }
    if (hull_strength <= 0.0f)
    {
        destroyedByDamage(info);
        if (on_destruction.isSet())
        {
            if (info.instigator)
            {
                on_destruction.call<void>(P<ShipTemplateBasedObject>(this), P<SpaceObject>(info.instigator));
            } else {
                on_destruction.call<void>(P<ShipTemplateBasedObject>(this));
            }
        }
        destroy();
    }
}

float ShipTemplateBasedObject::getShieldDamageFactor(DamageInfo& info, int shield_index)
{
    return 1.0f;
}

float ShipTemplateBasedObject::getShieldRechargeRate(int shield_index)
{
    return 0.3;
}

void ShipTemplateBasedObject::setTemplate(string template_name)
{
    P<ShipTemplate> new_ship_template = ShipTemplate::getTemplate(template_name);
    this->template_name = template_name;
    ship_template = new_ship_template;
    type_name = template_name;

    hull_strength = hull_max = ship_template->hull;
    shield_count = ship_template->shield_count;
    for(int n=0; n<shield_count; n++)
        shield_level[n] = shield_max[n] = ship_template->shield_level[n];

    // Set the ship's radar ranges.
    long_range_radar_range = ship_template->long_range_radar_range;
    short_range_radar_range = ship_template->short_range_radar_range;

    radar_trace = ship_template->radar_trace;
    impulse_sound_file = ship_template->impulse_sound_file;

    shares_energy_with_docked = ship_template->shares_energy_with_docked;
    repair_docked = ship_template->repair_docked;

    ship_template->setCollisionData(this);
    model_info.setData(ship_template->model_data);

    //Call the virtual applyTemplateValues function so subclasses can get extra values from the ship templates.
    applyTemplateValues();
}

void ShipTemplateBasedObject::setShields(const std::vector<float>& amounts)
{
    for(int n=0; n<std::min(int(amounts.size()), shield_count); n++)
    {
        shield_level[n] = amounts[n];
    }
}

void ShipTemplateBasedObject::setShieldsMax(const std::vector<float>& amounts)
{
    shield_count = std::min(max_shield_count, int(amounts.size()));
    for(int n=0; n<shield_count; n++)
    {
        shield_max[n] = amounts[n];
        shield_level[n] = std::min(shield_level[n], shield_max[n]);
    }
}

ESystem ShipTemplateBasedObject::getShieldSystemForShieldIndex(int index)
{
    if (shield_count < 2)
        return SYS_FrontShield;
    float angle = index * 360.0f / shield_count;
    if (std::abs(angleDifference(angle, 0.0f)) < 90)
        return SYS_FrontShield;
    return SYS_RearShield;
}

void ShipTemplateBasedObject::onTakingDamage(ScriptSimpleCallback callback)
{
    this->on_taking_damage = callback;
}

void ShipTemplateBasedObject::onDestruction(ScriptSimpleCallback callback)
{
    this->on_destruction = callback;
}

string ShipTemplateBasedObject::getShieldDataString()
{
    string data = "";
    for(int n=0; n<shield_count; n++)
    {
        if (n > 0)
            data += ":";
        data += string(int(shield_level[n]));
    }
    return data;
}
