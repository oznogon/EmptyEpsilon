#include <i18n.h>
#include <optional>
#include "shipTemplate.h"
#include "spaceObjects/spaceObject.h"
#include "mesh.h"
#include "multiplayer_server.h"

#include "scriptInterface.h"

/// ShipTemplates define the base functionality, stats, models, and other details for ships created from them.
/// They create ShipTemplateBasedObjects, which typically belong to either the SpaceStation or SpaceShip subclasses.
/// SpaceShips in turn can belong to the CpuShip or PlayerSpaceship classes.
/// EmptyEpsilon loads scripts/shipTemplates.lua at launch, which lists files to load that are located in scripts/shiptemplates/.
/// ShipTemplates cannot be created while a scenario is running.
REGISTER_SCRIPT_CLASS(ShipTemplate)
{
    /// Sets the ship template's reference name.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setName);
    /// Sets the ship template's displayed name.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setLocaleName);
    /// Sets the class and subclass names for ships created from this template.
    /// Ship classes define certain traits, such as dockability.
    /// See also ShipTemplate:setExternalDockClasses() and ShipTemplate:setInternalDockClasses().
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setClass);
    /// Sets the description shown in the science databse for ships created from this template.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setDescription);
    /// Sets the type of ship created from this template.
    /// Optional. Defaults to "ship" (CpuShip).
    /// Valid values are "ship", "playership" (PlayerSpaceship), and "station" (SpaceStation).
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setType);
    /// Hides this template from GM creation features and the science database.
    /// Hidden templates provide backward compatibility to older scenario scripts.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, hidden);
    /// Sets the default combat AI state for CpuShips created from this template.
    /// AI state determines the AI's combat tactics and responses.
    /// It is distinct from orders, which determine the ship's active objectives and are defined by CpuShip:order...() functions.
    /// Valid AI states are:
    /// - "default" directly pursues enemies at beam range while making opportunistic missile attacks
    /// - "evasion" maintains distance from enemy weapons and evades attacks
    /// - "fighter" prefers strafing maneuvers to attack briefly at close range while passing
    /// - "missilevolley" prefers lining up missile attacks from long range
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setDefaultAI);
    /// Sets the 3D model data by name for ships created from this template.
    /// Model data is set in ModelData objects and loaded from the model_data.lua file.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setModel);
    /// Alias of ShipTemplate:setExternalDockClasses().
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setDockClasses);
    /// Defines a list of ship classes that can be externally docked to ships created from this template.
    /// External docking keeps the docked ship attached to the outside of the carrier.
    /// Example: setDockClasses("Starfighter") allows all small starfighter-type ships to dock to the outside of this ship.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setExternalDockClasses);
    /// Defines a list of ship classes that can be docked inside of ships created from this template.
    /// Internal docking hides the docked ship inside of the carrier.
    /// Example: setInternalDockClasses("Starfighter") allows all small starfighter-type ships to dock inside this ship.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setInternalDockClasses);
    /// Sets the amount of energy available for ships created from this template.
    /// Only player ships use energy, so setting this for other ship types has no effect.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setEnergyStorage);
    /// Sets the default number of repair crew for ships created from this template.
    /// Only player ships use repair crews, so setting this for other ship types has no effect.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setRepairCrewCount);
    /// Alias of ShipTemplate:setBeamWeapon().
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setBeam);
    /// Defines the traits of a beam weapon for ships created from this template.
    /// - index: Each beam weapon in this ShipTemplate must have a unique index.
    /// - arc: Sets the arc of its firing capability, in degrees.
    /// - direction: Sets the default center angle of the arc, relative to the ship's forward bearing.
    /// - range: Sets how far away the beam can fire.
    /// - cycle_time: Sets the base firing delay, in seconds. System damage and power can modify the effective cycle_time.
    /// - damage: Sets the base damage done by the beam to the target. System damage and power can modify the effective damage.
    /// To create a turreted beam, also add ShipTemplate:setBeamWeaponTurret(), and set the beam weapon's arc to be smaller than the turret's arc.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setBeamWeapon);
    /// Converts a beam weapon into a turret and defines its traits for ships created from this template.
    /// - index: Must match the index of an existing beam weapon.
    /// - arc: Sets the turret's maximum targeting angles, in degrees. The turret arc must be larger than the associated beam weapon's arc.
    /// - direction: Sets the default center angle of the turret arc, relative to the ship's forward bearing.
    /// - rotation_rate: Sets how many degrees per tick that the associated beam weapon's direction can rotate toward the target within the turret arc. System damage and power can modify a turret's rotation rate.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setBeamWeaponTurret);
    /// Sets the texture, by name, of the beam weapon with the matching index.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setBeamTexture);
    /// Sets how much of the ship's energy is drained each time the beam weapon with the given index is fired.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setBeamWeaponEnergyPerFire);
    /// Sets how much beam weapon system heat is generated each time the beam weapon with the given index is fired.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setBeamWeaponHeatPerFire);
    /// Sets the number of weapon tubes for ships created from this template, and the default delay for loading and unloading the tube, in seconds.
    /// Ships are limited to a maximum of 16 weapon tubes.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setTubes);
    /// Sets the delay, in seconds, for loading and unloading the tube with the given index.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setTubeLoadTime);
    /// Sets which weapon types the tube with the given index can load.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, weaponTubeAllowMissle);
    /// Sets which weapon types the tube with the given index can't load.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, weaponTubeDisallowMissle);
    /// Sets a weapon tube with the given index to allow loading only the given weapon type.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setWeaponTubeExclusiveFor);
    /// Sets the angle, relative to the ship's forward bearing, toward which the tube with the given index points.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setTubeDirection);
    /// Sets the size of the weapon launched from the tube.
    /// Optional. Defaults to "medium".
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setTubeSize);
    /// Sets the amount of default hull points for ships created from this template.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setHull);
    /// Sets the default shield points for ships created from this template.
    /// Each setShieldData() segments the shield, dividing the arc equally for each segment, up to a maximum of 8 segments.
    /// Ships with one shield segment have only "front" shield systems, and ships with two or more all have only "front" and "rear" shield systems.
    /// Example:
    /// setShieldData(400) -- one shield segment; hits from all angles degrade the sole shield value
    /// setShieldData(100, 80) -- two shield segments; the front shield has 100 points, the rear 80
    /// setShieldData(100, 50, 50, 50) -- four shield segments; the front shield has 100, rear and sides 50 each
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setShields);
    /// Sets the impulse speed, rotational speed, and impulse acceleration for ships created from this template.
    /// The optional fourth and fifth arguments set the reverse speed and reverse acceleration.
    /// If not explicitly set, the reverse speed and acceleration are equal to the forward speed and acceleration
    /// See also SpaceShip:setImpulseMaxSpeed(), SpaceShip:setRotationMaxSpeed(), SpaceShip:setAcceleration().
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setSpeed);
    /// Sets the combat maneuver capacity for ships created from this template.
    /// The boost value sets the forward maneuver capacity, and the strafe value sets the lateral maneuver capacity.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setCombatManeuver);
    /// Sets the warp speed of warp level 1 for ships created from this template.
    /// The typical warp speed value for a warp-capable ship is 1000.
    /// Setting any value also enables the "warpdrive" system and controls.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setWarpSpeed);
    /// Defines whether ships created from this template send energy to docked ships.
    /// Example: template:setSharesEnergyWithDocked(false)
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setSharesEnergyWithDocked);
    /// Defines whether ships created from this template repair docked ships.
    /// Example: template:setRepairDocked(false)
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setRepairDocked);
    /// Defines whether ships created from this template restock scan probes on docked ships.
    /// Example: template:setRestocksScanProbes(false)
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setRestocksScanProbes);
    /// Defines whether ships created from this template restore missiles on docked CpuShips.
    /// To restock player ships' weapons, use a comms script.
    /// Example template:setRestocksMissilesDocked(false)
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setRestocksMissilesDocked);
    /// Defines whether ships created from this template have a jump drive.
    /// Example: template:setJumpDrive(true)
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setJumpDrive);
    /// Sets the minimum and maximum jump distances for ships created from this template.
    /// Example: template:setJumpDriveRange(5000, 50000) -- sets the minimum jump to 5U and maximum to 50U
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setJumpDriveRange);
    /// Not implemented.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setCloaking);
    /// Sets the storage capacity of the given weapon type for ships created from this template.
    /// For valid values, see the EMissileWeapons type.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setWeaponStorage);
    /// Adds an empty room to a ship template.
    /// Rooms are displayed on the engineering and damcon screens.
    /// If a system room isn't accessible via other rooms connected by doors, repair crews on player ships might not be able to repair that system.
    /// Rooms are placed on an integer x/y grid. The minimum size for a room is 1x1.
    /// Example: template:addRoom(1, 2, 3, 4)
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, addRoom);
    /// Adds a room containing a ship system to a ship template.
    /// Rooms are displayed on the engineering and damcon screens.
    /// If a system doesn't have a room, or repair crews can't reach a system's room, the system might not be repairable on player ships.
    /// Rooms are placed on an integer x/y grid. The minimum size for a room is 1x1.
    /// For valid system values, see the ESystem type.
    /// Example: template:addRoomSystem(1, 2, 3, 4, "reactor")
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, addRoomSystem);
    /// Adds a door between rooms in a ship template.
    /// Rooms are displayed on the engineering and damcon screens.
    /// If a system room doesn't have a door connecting it to other rooms, repair crews on player ships might not be able to repair the system.
    /// The horizontal value defines whether the door is oriented horizontally (true) or vertically (false).
    /// Example: template:addDoor(2, 2, false)
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, addDoor);
    /// Sets the default radar trace image for ships created from this template.
    /// Valid values are filenames to PNG images relative to the resources/radar directory.
    /// Radar trace images should be white with a transparent background.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setRadarTrace);
    /// Sets the long-range radar range of ships created from this template.
    /// PlayerSpaceships use this range on the science and operations screens' radar.
    /// CpuShips use this range to detect potential targets.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setLongRangeRadarRange);
    /// Sets the short-range radar range of ships created from this template.
    /// PlayerSpaceships use this range on the helms, weapons, and single pilot screens' radar.
    /// This also defines the radar radius on the relay screen for friendly ships and stations.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setShortRangeRadarRange);
    /// Sets the sound file used for the impulse drive on ships created from this template.
    /// Valid values are filenames to WAV files relative to the resources directory.
    /// Use a looping sound file that tolerates being pitched up and down as the ship's impulse speed changes.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setImpulseSoundFile);
    /// Defines whether ships created from this template can scan other objects.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setCanScan);
    /// Defines whether ships created from this template can hack other objects.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setCanHack);
    /// Defines whether ships created from this template can dock with other objects.
    /// To allow ships created from this template to dock with other ships, it must be of a class defined by the carrier ship's setExternalDockClasses() or setInternalDockClasses().
    /// Setting this to false prevents ships created from this template from docking with anything, including stations.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setCanDock);
    /// Defines whether ships created from this template have combat maneuver controls.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setCanCombatManeuver);
    /// Defines whether ships created from this template can activate the self-destruct sequence.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setCanSelfDestruct);
    /// Defines whether ships created from this template can launch probes.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, setCanLaunchProbe);
    /// Returns an exact copy of the template with the given name.
    /// Use copy to create variations of a template under a different name.
    REGISTER_SCRIPT_CLASS_FUNCTION(ShipTemplate, copy);
}

std::unordered_map<string, P<ShipTemplate> > ShipTemplate::templateMap;

ShipTemplate::ShipTemplate()
{
    if (game_server) { LOG(ERROR) << "ShipTemplate objects can not be created during a scenario."; destroy(); return; }

    type = Ship;
    class_name = tr("No class");
    sub_class_name = tr("No sub-class");
    shares_energy_with_docked = true;
    repair_docked = false;
    restocks_scan_probes = false;
    restocks_missiles_docked = false;
    energy_storage_amount = 1000;
    repair_crew_count = 3;
    weapon_tube_count = 0;
    for(int n=0; n<max_weapon_tubes; n++)
    {
        weapon_tube[n].load_time = 8.0;
        weapon_tube[n].type_allowed_mask = (1 << MW_Count) - 1;
        weapon_tube[n].direction = 0;
        weapon_tube[n].size = MS_Medium;
    }
    hull = 70;
    shield_count = 0;
    for(int n=0; n<max_shield_count; n++)
        shield_level[n] = 0.0;
    impulse_speed = 500.0;
    impulse_reverse_speed = 500.0;
    impulse_acceleration = 20.0;
    impulse_reverse_acceleration = 20.0;
    turn_speed = 10.0;
    combat_maneuver_boost_speed = 0.0f;
    combat_maneuver_strafe_speed = 0.0f;
    warp_speed = 0.0;
    has_jump_drive = false;
    jump_drive_min_distance = 5000.0;
    jump_drive_max_distance = 50000.0;
    has_cloaking = false;
    for(int n=0; n<MW_Count; n++)
        weapon_storage[n] = 0;
    long_range_radar_range = 30000.0f;
    short_range_radar_range = 5000.0f;
    radar_trace = "radar/arrow.png";
    impulse_sound_file = "sfx/engine.wav";
    default_ai_name = "default";
}

void ShipTemplate::setBeamTexture(int index, string texture)

{
    if (index >= 0 && index < max_beam_weapons)
    {
        beams[index].setBeamTexture(texture);
    }
}

void ShipTemplate::setTubes(int amount, float load_time)
{
    weapon_tube_count = std::min(max_weapon_tubes, amount);
    for(int n=0; n<max_weapon_tubes; n++)
        weapon_tube[n].load_time = load_time;
}

void ShipTemplate::setTubeLoadTime(int index, float load_time)
{
    if (index < 0 || index >= max_weapon_tubes)
        return;
    weapon_tube[index].load_time = load_time;
}

void ShipTemplate::weaponTubeAllowMissle(int index, EMissileWeapons type)
{
    if (index < 0 || index >= max_weapon_tubes)
        return;
    weapon_tube[index].type_allowed_mask |= (1 << type);
}

void ShipTemplate::weaponTubeDisallowMissle(int index, EMissileWeapons type)
{
    if (index < 0 || index >= max_weapon_tubes)
        return;
    weapon_tube[index].type_allowed_mask &=~(1 << type);
}

void ShipTemplate::setWeaponTubeExclusiveFor(int index, EMissileWeapons type)
{
    if (index < 0 || index >= max_weapon_tubes)
        return;
    weapon_tube[index].type_allowed_mask = (1 << type);
}

void ShipTemplate::setTubeDirection(int index, float direction)
{
    if (index < 0 || index >= max_weapon_tubes)
        return;
    weapon_tube[index].direction = direction;
}

void ShipTemplate::setTubeSize(int index, EMissileSizes size)
{
    if (index < 0 || index >= max_weapon_tubes)
        return;
    weapon_tube[index].size = size;
}

void ShipTemplate::setType(TemplateType type)
{
    if (radar_trace == "radar/arrow.png" && type == Station)
    {
        radar_trace = "radar/blip.png";
    }
    if (type == Station)
        repair_docked = true;
    this->type = type;
}

void ShipTemplate::setName(string name)
{
    if (templateMap.find(name) != templateMap.end())
    {
        LOG(ERROR) << "Duplicate ship template definition: " << name;
    }

    templateMap[name] = this;
    if (name.startswith("Player "))
        name = name.substr(7);
    this->name = name;
    if (this->locale_name == "")
        this->locale_name = name;
}

void ShipTemplate::setLocaleName(string name)
{
    this->locale_name = name;
}

void ShipTemplate::setClass(string class_name, string sub_class_name)
{
    this->class_name = class_name;
    this->sub_class_name = sub_class_name;
}

void ShipTemplate::setBeam(int index, float arc, float direction, float range, float cycle_time, float damage)
{
    setBeamWeapon(index, arc, direction, range, cycle_time, damage);
}

void ShipTemplate::setBeamWeapon(int index, float arc, float direction, float range, float cycle_time, float damage)
{
    if (index < 0 || index > max_beam_weapons)
        return;
    beams[index].setDirection(direction);
    beams[index].setArc(arc);
    beams[index].setRange(range);
    beams[index].setCycleTime(cycle_time);
    beams[index].setDamage(damage);
}

void ShipTemplate::setBeamWeaponTurret(int index, float arc, float direction, float rotation_rate)
{
    if (index < 0 || index > max_beam_weapons)
        return;
    beams[index].setTurretArc(arc);
    beams[index].setTurretDirection(direction);
    beams[index].setTurretRotationRate(rotation_rate);
}

glm::ivec2 ShipTemplate::interiorSize()
{
    glm::ivec2 min_pos(1000, 1000);
    glm::ivec2 max_pos(0, 0);
    for(unsigned int n=0; n<rooms.size(); n++)
    {
        min_pos.x = std::min(min_pos.x, rooms[n].position.x);
        min_pos.y = std::min(min_pos.y, rooms[n].position.y);
        max_pos.x = std::max(max_pos.x, rooms[n].position.x + rooms[n].size.x);
        max_pos.y = std::max(max_pos.y, rooms[n].position.y + rooms[n].size.y);
    }
    if (min_pos != glm::ivec2(1, 1))
    {
        glm::ivec2 offset = glm::ivec2(1, 1) - min_pos;
        for(unsigned int n=0; n<rooms.size(); n++)
            rooms[n].position += offset;
        for(unsigned int n=0; n<doors.size(); n++)
            doors[n].position += offset;
        max_pos += offset;
    }
    max_pos += glm::ivec2(1, 1);
    return max_pos;
}

ESystem ShipTemplate::getSystemAtRoom(glm::ivec2 position)
{
    for(unsigned int n=0; n<rooms.size(); n++)
    {
        if (rooms[n].position.x <= position.x && rooms[n].position.x + rooms[n].size.x > position.x && rooms[n].position.y <= position.y && rooms[n].position.y + rooms[n].size.y > position.y)
            return rooms[n].system;
    }
    return SYS_None;
}

void ShipTemplate::setCollisionData(P<SpaceObject> object)
{
    model_data->setCollisionData(object);
}

void ShipTemplate::setShields(const std::vector<float>& values)
{
    shield_count = std::min(max_shield_count, int(values.size()));
    for(int n=0; n<shield_count; n++)
    {
        shield_level[n] = values[n];
    }
}


P<ShipTemplate> ShipTemplate::getTemplate(string name)
{
    if (templateMap.find(name) == templateMap.end())
    {
        LOG(ERROR) << "Failed to find ship template: " << name;
        return nullptr;
    }
    return templateMap[name];
}

std::vector<string> ShipTemplate::getAllTemplateNames()
{
    std::vector<string> ret;
    for(std::unordered_map<string, P<ShipTemplate> >::iterator i = templateMap.begin(); i != templateMap.end(); i++)
        ret.push_back(i->first);
    return ret;
}

std::vector<string> ShipTemplate::getTemplateNameList(TemplateType type)
{
    std::vector<string> ret;
    for(std::unordered_map<string, P<ShipTemplate> >::iterator i = templateMap.begin(); i != templateMap.end(); i++)
        if (i->second->getType() == type)
            ret.push_back(i->first);
    return ret;
}

string getSystemName(ESystem system)
{
    switch(system)
    {
    case SYS_Reactor: return "Reactor";
    case SYS_BeamWeapons: return "Beam Weapons";
    case SYS_MissileSystem: return "Missile System";
    case SYS_Maneuver: return "Maneuvering";
    case SYS_Impulse: return "Impulse Engines";
    case SYS_Warp: return "Warp Drive";
    case SYS_JumpDrive: return "Jump Drive";
    case SYS_FrontShield: return "Front Shield Generator";
    case SYS_RearShield: return "Rear Shield Generator";
    default:
        return "UNKNOWN";
    }
}

string getLocaleSystemName(ESystem system)
{
    switch(system)
    {
    case SYS_Reactor: return tr("system", "Reactor");
    case SYS_BeamWeapons: return tr("system", "Beam Weapons");
    case SYS_MissileSystem: return tr("system", "Missile System");
    case SYS_Maneuver: return tr("system", "Maneuvering");
    case SYS_Impulse: return tr("system", "Impulse Engines");
    case SYS_Warp: return tr("system", "Warp Drive");
    case SYS_JumpDrive: return tr("system", "Jump Drive");
    case SYS_FrontShield: return tr("system", "Front Shield Generator");
    case SYS_RearShield: return tr("system", "Rear Shield Generator");
    default:
        return "UNKNOWN";
    }
}

void ShipTemplate::setDescription(string description)
{
    this->description = description;
}

void ShipTemplate::setModel(string model_name)
{
    this->model_data = ModelData::getModel(model_name);
}

void ShipTemplate::setDefaultAI(string default_ai_name)
{
    this->default_ai_name = default_ai_name;
}

void ShipTemplate::setDockClasses(const std::vector<string>& classes)
{
    external_dock_classes = std::unordered_set<string>(classes.begin(), classes.end());
}

void ShipTemplate::setExternalDockClasses(const std::vector<string>& classes)
{
    external_dock_classes = std::unordered_set<string>(classes.begin(), classes.end());
}

void ShipTemplate::setInternalDockClasses(const std::vector<string>& classes)
{
    internal_dock_classes = std::unordered_set<string>(classes.begin(), classes.end());
}

void ShipTemplate::setSpeed(float impulse, float turn, float acceleration, std::optional<float> reverse_speed, std::optional<float> reverse_acceleration)
{
    impulse_speed = impulse;
    turn_speed = turn;
    impulse_acceleration = acceleration;

    impulse_reverse_speed = reverse_speed.value_or(impulse);
    impulse_reverse_acceleration = reverse_acceleration.value_or(acceleration);
}

void ShipTemplate::setCombatManeuver(float boost, float strafe)
{
    combat_maneuver_boost_speed = boost;
    combat_maneuver_strafe_speed = strafe;
}

void ShipTemplate::setWarpSpeed(float warp)
{
    warp_speed = warp;
}

void ShipTemplate::setSharesEnergyWithDocked(bool enabled)
{
    shares_energy_with_docked = enabled;
}

void ShipTemplate::setRepairDocked(bool enabled)
{
    repair_docked = enabled;
}

void ShipTemplate::setRestocksScanProbes(bool enabled)
{
    restocks_scan_probes = enabled;
}

void ShipTemplate::setRestocksMissilesDocked(bool enabled)
{
    restocks_missiles_docked = enabled;
}

void ShipTemplate::setJumpDrive(bool enabled)
{
    has_jump_drive = enabled;
}

void ShipTemplate::setCloaking(bool enabled)
{
    has_cloaking = enabled;
}

void ShipTemplate::setWeaponStorage(EMissileWeapons weapon, int amount)
{
    if (weapon != MW_None)
    {
        weapon_storage[weapon] = amount;
    }
}

void ShipTemplate::addRoom(glm::ivec2 position, glm::ivec2 size)
{
    rooms.push_back(ShipRoomTemplate(position, size, SYS_None));
}

void ShipTemplate::addRoomSystem(glm::ivec2 position, glm::ivec2 size, ESystem system)
{
    rooms.push_back(ShipRoomTemplate(position, size, system));
}

void ShipTemplate::addDoor(glm::ivec2 position, bool horizontal)
{
    doors.push_back(ShipDoorTemplate(position, horizontal));
}

void ShipTemplate::setRadarTrace(string trace)
{
    radar_trace = "radar/" + trace;
}

void ShipTemplate::setLongRangeRadarRange(float range)
{
    range = std::max(range, 100.0f);
    long_range_radar_range = range;
    short_range_radar_range = std::min(short_range_radar_range, range);
}

void ShipTemplate::setShortRangeRadarRange(float range)
{
    range = std::max(range, 100.0f);
    short_range_radar_range = range;
    long_range_radar_range = std::max(long_range_radar_range, range);
}

void ShipTemplate::setImpulseSoundFile(string sound)
{
    impulse_sound_file = sound;
}

P<ShipTemplate> ShipTemplate::copy(string new_name)
{
    P<ShipTemplate> result = new ShipTemplate();
    result->setName(new_name);

    result->description = description;
    result->class_name = class_name;
    result->sub_class_name = sub_class_name;
    result->type = type;
    result->model_data = model_data;

    result->external_dock_classes = external_dock_classes;
    result->internal_dock_classes = internal_dock_classes;
    result->energy_storage_amount = energy_storage_amount;
    result->repair_crew_count = repair_crew_count;

    result->can_scan = can_scan;
    result->can_hack = can_hack;
    result->can_dock = can_dock;
    result->can_combat_maneuver = can_combat_maneuver;
    result->can_self_destruct = can_self_destruct;
    result->can_launch_probe = can_launch_probe;

    result->default_ai_name = default_ai_name;
    for(int n=0; n<max_beam_weapons; n++)
        result->beams[n] = beams[n];
    result->weapon_tube_count = weapon_tube_count;
    for(int n=0; n<max_beam_weapons; n++)
        result->weapon_tube[n] = weapon_tube[n];
    result->hull = hull;
    result->shield_count = shield_count;
    for(int n=0; n<max_shield_count; n++)
        result->shield_level[n] = shield_level[n];
    result->impulse_speed = impulse_speed;
    result->impulse_reverse_speed = impulse_reverse_speed;
    result->turn_speed = turn_speed;
    result->warp_speed = warp_speed;
    result->impulse_acceleration = impulse_acceleration;
    result->impulse_reverse_acceleration = impulse_reverse_acceleration;
    result->combat_maneuver_boost_speed = combat_maneuver_boost_speed;
    result->combat_maneuver_strafe_speed = combat_maneuver_strafe_speed;
    result->shares_energy_with_docked = shares_energy_with_docked;
    result->repair_docked = repair_docked;
    result->restocks_scan_probes = restocks_scan_probes;
    result->restocks_missiles_docked = restocks_missiles_docked;
    result->has_jump_drive = has_jump_drive;
    result->has_cloaking = has_cloaking;
    for(int n=0; n<MW_Count; n++)
        result->weapon_storage[n] = weapon_storage[n];
    result->radar_trace = radar_trace;

    result->rooms = rooms;
    result->doors = doors;

    return result;
}

void ShipTemplate::setEnergyStorage(float energy_amount)
{
    this->energy_storage_amount = energy_amount;
}

void ShipTemplate::setRepairCrewCount(int amount)
{
    this->repair_crew_count = amount;
}

string ShipTemplate::getName()
{
    return this->name;
}

string ShipTemplate::getLocaleName()
{
    return this->locale_name;
}

string ShipTemplate::getDescription()
{
    return this->description;
}

string ShipTemplate::getClass()
{
    return this->class_name;
}

string ShipTemplate::getSubClass()
{
    return this->sub_class_name;
}

ShipTemplate::TemplateType ShipTemplate::getType()
{
    return type;
}

#include "shipTemplate.hpp"
