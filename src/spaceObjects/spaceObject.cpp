#include "spaceObject.h"
#include "factionInfo.h"
#include "gameGlobalInfo.h"
#include "preferenceManager.h"

#include <glm/ext/matrix_transform.hpp>

#include "scriptInterface.h"

/// SpaceObject is the base class for every object in the game universe.
/// All objects of SpaceObject subclasses can also access these core functions.
/// Each object has a position, rotation, and collision shape.
/// The Collisionable class is provided by SeriousProton.
REGISTER_SCRIPT_CLASS_NO_CREATE(SpaceObject)
{
    /// Sets this object's position on the map, in meters from the origin.
    /// Example: obj:setPosition(x, y)
    REGISTER_SCRIPT_CLASS_FUNCTION(Collisionable, setPosition);
    /// Returns this object's position on the map.
    /// Example: local x, y = obj:getPosition()
    REGISTER_SCRIPT_CLASS_FUNCTION(Collisionable, getPosition);
    /// Sets this object's absolute rotation, in degrees.
    /// Unlike SpaceObject:setHeading(), a value of 0 points to the right of the map.
    /// The value can also be unbounded; it can be negative, or greater than 360 degrees.
    /// SpaceObject:setHeading() and SpaceObject:setRotation() do not change the helm's target heading on PlayerSpaceships. To do that, use PlayerSpaceship:commandTargetRotation().
    /// Example: obj:setRotation(270)
    REGISTER_SCRIPT_CLASS_FUNCTION(Collisionable, setRotation);
    /// Returns this object's absolute rotation, in degrees.
    /// Example: local rotation = obj:getRotation()
    REGISTER_SCRIPT_CLASS_FUNCTION(Collisionable, getRotation);
    /// Sets this object's heading, in degrees ranging from 0 to 360.
    /// Unlike setRotation, a value of 0 points to the top of the map.
    /// Values that are negative or greater than 360 are are converted to values within that range.
    /// SpaceObject:setHeading() and SpaceObject:setRotation() do not change the helm's target heading on PlayerSpaceships. To do that, use PlayerSpaceship:commandTargetRotation().
    /// Example: obj:setHeading(0)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, setHeading);
    /// Returns this object's heading, in degrees ranging from 0 to 360.
    /// Example: local heading = obj:getHeading(0)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, getHeading);
    /// Returns this object's directional velocity within 2D space as an x/y vector.
    /// The values are relative x, y coordinates from the SpaceObject's current position (a 2D velocity vector).
    /// Example: local vx, vy = obj:getVelocity()
    REGISTER_SCRIPT_CLASS_FUNCTION(Collisionable, getVelocity);
    /// Returns this object's rotational velocity within 2D space, in degrees/second.
    /// Example: local angular_velocity = obj:getAngularVelocity()
    REGISTER_SCRIPT_CLASS_FUNCTION(Collisionable, getAngularVelocity);
    /// Sets the faction to which this object belongs, by faction name.
    /// Factions are defined by the FactionInfo class, and default factions are defined in scripts/factionInfo.lua.
    /// Requires a faction name string as input.
    /// Example: obj:setFaction("Human Navy")
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, setFaction);
    /// Returns the name of the faction to which this object belongs.
    /// Example: local faction = obj:getFaction()
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, getFaction);
    /// Returns the localized name of the faction to which this object belongs, for displaying to the players.
    /// Example: local faction = obj:getLocaleFaction()
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, getLocaleFaction);
    /// Returns the faction to which this object belongs, by the faction's index in the faction list.
    /// Use with SpaceObject:getFactionId() to ensure that two objects belong to the same faction.
    /// Example: local faction_id = obj:getFactionId()
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, setFactionId);
    /// Returns the faction list index for the faction to which this object belongs.
    /// Use with SpaceObject:setFactionId() to ensure that two objects belong to the same faction.
    /// Example: other:setFactionId(obj:getFactionId())
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, getFactionId);
    /// Returns the friend-or-foe status of the given faction relative to this object's faction.
    /// Requires a SpaceObject.
    /// Returns true if the parameter's faction is hostile to this object's.
    /// Example: local is_enemy = comms_source:isEnemy(comms_target)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, isEnemy);
    /// Returns the friend-or-foe status of the given faction relative to this object's faction.
    /// Requires a SpaceObject.
    /// Returns true if the parameter's faction is friendly to this object's.
    /// If an object is neither friendly nor enemy, it is neutral.
    /// Example: local is_friendly = comms_source:isFriendly(comms_target)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, isFriendly);
    /// Sets the communications script used when this object is hailed.
    /// Accepts the filename of a Lua script relative to the scripts/ directory as a string.
    /// If set to an empty string, comms with this object are disabled.
    /// In the script, comms_source (or player, deprecated) (PlayerSpaceship) and comms_target (SpaceObject) are available.
    /// See also SpaceObject:setCommsFunction().
    /// Examples:
    ///   obj:setCommsScript("")
    ///   obj:setCommsScript("comms_custom_script.lua")
    /// Defaults:
    ///   "comms_station.lua" (SpaceStation objects)
    ///   "comms_ship.lua" (CpuShip objects)
    /// For other object types, or when creating custom comms scripts, use setCommsMessage() at least once, and use addCommsReply() to let players respond.
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, setCommsScript);
    /// Defines a callback function to use when handling hails, in lieu of any current or default comms script.
    /// For a detailed example, see scenario_53_escape.lua.
    /// Requires a function to call back to when hailed.
    /// The globals comms_source (PlayerSpaceship) and comms_target (SpaceObject) are made available in the scenario script.
    /// (Note: They remain as globals. As usual, such globals are not accessible in required files.)
    /// See also SpaceObject:setCommsScript().
    /// Example: obj:setCommsFunction(commsStation)
    /// where commsStation is a function that calls setCommsMessage() at least once, and uses addCommsReply() to let players respond.
    /// Instead of using the globals, the callback can optionally take two equivalent parameters.
    /// Example: obj:setCommsFunction(function(comms_source, comms_target) ... end)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, setCommsFunction);
    /// Sets this object's callsign.
    /// EmptyEpsilon generates random callsigns for objects upon creation, and this function overrides that default.
    /// Example: obj:setCallSign("Epsilon")
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, setCallSign);
    /// Hails a PlayerSpaceship from this object.
    /// The PlayerSpaceship's comms station is notified and can accept or refuse the hail.
    /// If the PlayerSpaceship accepts the hail, display the given message.
    /// Returns true when the hail is accepted.
    /// Returns false if the hail is refused, or when the target player cannot be hailed right now, for example because it's already communicating with something else.
    /// This logs a message in the comms log. To avoid logging use SpaceObject:sendCommsMessageNoLog().
    /// Requires a target option and message, though the message can be an empty string.
    /// Example: obj:sendCommsMessage(player, "Prepare to die")
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, sendCommsMessage);
    /// As SpaceObject:sendCommsMessage(), but does not log a failed hail to the target ship's comms log.
    /// Example: obj:sendCommsMessageNoLog(player, "Prepare to die")
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, sendCommsMessageNoLog);
    /// As SpaceObject:sendCommsMessage(), but sends an empty string as the message.
    /// This calls the object's comms function.
    /// Example: obj:openCommsTo(player)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, openCommsTo);
    /// Returns this object's callsign.
    /// Example: local callsign = obj:getCallSign()
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, getCallSign);
    /// Returns whether any objects from a hostile faction are within a given radius of this object, in meters.
    /// Returns true if hostiles are in range.
    /// Example: obj:areEnemiesInRange(5000)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, areEnemiesInRange);
    /// Returns any objects within a specific radius of this object, in meters.
    /// Returns a list of all SpaceObjects within range.
    /// Example: for _, obj_in_range in ipairs(obj:getObjectsInRange(5000)) ...
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, getObjectsInRange);
    /// Returns this object's faction reputation points.
    /// Example: local reputation = obj:getReputationPoints();
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, getReputationPoints);
    /// Sets this object's faction reputation points to the given amount.
    /// Example: obj:setReputationPoints(1000)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, setReputationPoints);
    /// Deducts a given number of faction reputation points from this object.
    /// Returns true if there are enough points to deduct the specified amount, then does so.
    /// Returns false if there are not enough points, then does not deduct any.
    /// Example: local took_reputation = obj:takeReputationPoints(1000)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, takeReputationPoints);
    /// Adds a given number of faction reputation points to this object.
    /// Example: obj:addReputationPoints(1000)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, addReputationPoints);
    /// Returns the name of the map sector, such as "A4", where this object is located.
    /// Example: obj:getSectorName()
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, getSectorName);
    /// Deals a specific amount of a specific type of damage to this object.
    /// Requires a numeric value for the damage amount, and accepts an optional DamageInfo type.
    /// The optional DamageInfo parameter can be empty, which deals "energy" damage, or a string that indicates which type of damage to deal.
    /// Valid damage types are "energy", "kinetic", and "emp".
    /// If you specify a damage type, you can also optionally specify the location of the damage's
    /// origin, for instance, to damage a specific shield segment on a ship.
    /// SpaceObjects by default do not implement damage, instead leaving it to be overridden by specialized subclasses.
    /// Examples:
    ///              amount,  type,    x, y
    ///   obj:takeDamage(20, "emp", 1000, 0)
    ///   obj:takeDamage(20)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, takeDamage);
    /// Sets this object's description in unscanned and scanned states.
    /// The science screen displays these descriptions when targeting a scanned object.
    /// Requires two string values, one for the descriptions when unscanned and another for when it has been scanned.
    /// Example:
    ///   obj:setDescriptions("A refitted Atlantis X23...", "It's a trap!")
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, setDescriptions);
    /// As setDescriptions, but sets the same description for both unscanned and scanned states.
    /// Example: obj:setDescription("A refitted Atlantis X23 for more ...")
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, setDescription);
    /// Sets a description for a specific EScannedState.
    /// String equivalents for EScannedState are defined in the convert<EScannedState> function of
    /// src/spaceObjects/spaceObject.cpp:
    /// - "notscanned" or "not": The object has not been scanned.
    /// - "friendorfoeidentified": The object has been identified as hostile or friendly, but has not been scanned.
    /// - "simplescan" or "simple": The object has been scanned once under default server settings, displaying only basic information about the object.
    /// - "fullscan" or "full": The object is fully scanned.
    /// Example:
    ///   obj:setDescriptionForScanState("friendorfoeidentified", "A refitted...")
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, setDescriptionForScanState);
    /// Returns this object's description.
    /// Accepts an optional string-equivalent EScannedState, which determines which description to return.
    /// Defaults to returning the "fullscan" description.
    /// Examples:
    ///   obj:getDescription() -- returns the "fullscan" description
    ///   obj:getDescription("friendorfoeidentified") -- returns the "friendorfoeidentified" description
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, getDescription);
    /// Sets this object's radar signature, which creates noise on the science screen's raw radar signal ring, which contains red, green, and blue bands of waveform noise.
    /// Certain SpaceObject types might modify their signatures using this value as a baseline.
    /// Default values also depend on the SpaceObject type.
    /// Requires numeric values ranging from 0.0 to 1.0 for the gravitational, electrical, and biological radar bands, in that order.
    /// - Gravitational signatures amplify all bands, particularly the green and blue bands.
    /// - Electrical signatures amplify the red and blue bands.
    /// - Biological signatures amplify the red and green bands.
    /// Example: obj:setRadarSignatureInfo(0.0, 0.5, 1.0)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, setRadarSignatureInfo);
    /// Returns this object's gravitational radar signature value.
    /// Returns a numeric value between 0.0 and 1.0; larger and negative values are possible, but currently have no visual effect on the bands.
    /// Example: local grav_band = obj:getRadarSignatureGravity()
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, getRadarSignatureGravity);
    /// Returns this object's electical radar signature value.
    /// Returns a numeric value between 0.0 and 1.0; larger and negative values are possible, but currently have no visual effect on the bands.
    /// Example: local elec_band = obj:getRadarSignatureElectrical()
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, getRadarSignatureElectrical);
    /// Returns this object's biological radar signature value.
    /// Returns a numeric value between 0.0 and 1.0; larger and negative values are possible, but currently have no visual effect on the bands.
    /// Example: local bio_band = obj:getRadarSignatureBiological()
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, getRadarSignatureBiological);
    /// Sets this object's scanning complexity (number of bars in the scanning minigame) and depth (number of scanning minigames to complete until fully scanned), respectively.
    /// Setting this also clears the object's scanned state.
    /// Example: obj:setScanningParameters(2, 3)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, setScanningParameters);
    /// Returns the scanning complexity for the given object.
    /// Example: local scan_complexity = obj:scanningComplexity(obj)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, scanningComplexity);
    /// Returns the maximum scanning depth for the given object.
    /// Example: local scan_depth = obj:scanningChannelDepth(obj)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, scanningChannelDepth);
    /// Defines whether all factions consider this object as having been scanned.
    /// If false, all factions treat this object as unscanned.
    /// If true, all factions treat this object as fully scanned.
    /// Example: obj:setScanned(true)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, setScanned);
    /// [DEPRECATED]
    /// Returns whether this object has been scanned.
    /// Use SpaceObject:isScannedBy() or SpaceObject:isScannedByFaction() instead.
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, isScanned);
    /// Returns whether the given object has successfully scanned this object.
    /// Example: obj:isScannedBy(other)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, isScannedBy);
    /// Returns whether a given faction considers this object as having been scanned.
    /// Requires a faction name string value as defined by its FactionInfo, and a Boolean value.
    /// Example: obj:setScannedByFaction("Human Navy", false)
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, setScannedByFaction);
    /// Returns whether the given faction has successfully scanned this object.
    /// Requires a faction name string value as defined by its FactionInfo.
    /// Example: obj:isScannedByFaction("Human Navy")
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, isScannedByFaction);
    // Register a callback function that is called when this object is destroyed by any means.
    REGISTER_SCRIPT_CLASS_FUNCTION(SpaceObject, onDestroyed);
}

PVector<SpaceObject> space_object_list;

SpaceObject::SpaceObject(float collision_range, string multiplayer_name, float multiplayer_significant_range)
: Collisionable(collision_range), MultiplayerObject(multiplayer_name)
{
    object_radius = collision_range;
    space_object_list.push_back(this);
    faction_id = 0;

    scanning_complexity_value = 0;
    scanning_depth_value = 0;

    registerMemberReplication(&callsign);
    registerMemberReplication(&faction_id);
    registerMemberReplication(&scanned_by_faction);
    registerMemberReplication(&object_description.not_scanned);
    registerMemberReplication(&object_description.friend_of_foe_identified);
    registerMemberReplication(&object_description.simple_scan);
    registerMemberReplication(&object_description.full_scan);
    registerMemberReplication(&radar_signature.gravity);
    registerMemberReplication(&radar_signature.electrical);
    registerMemberReplication(&radar_signature.biological);
    registerMemberReplication(&scanning_complexity_value);
    registerMemberReplication(&scanning_depth_value);
    registerCollisionableReplication(multiplayer_significant_range);
}

//due to a suspected compiler bug this deconstructor needs to be explicitly defined
SpaceObject::~SpaceObject()
{
}

void SpaceObject::draw3D()
{
    model_info.render(getPosition(), getRotation(), getModelMatrix());
}

void SpaceObject::drawOnRadar(sp::RenderTarget& renderer, glm::vec2 position, float scale, float rotation, bool longRange)
{
}

void SpaceObject::drawOnGMRadar(sp::RenderTarget& renderer, glm::vec2 position, float scale, float rotation, bool longRange)
{
}

void SpaceObject::destroy()
{
    on_destroyed.call<void>(P<SpaceObject>(this));
    MultiplayerObject::destroy();
}

bool SpaceObject::canBeTargetedBy(P<SpaceObject> other)
{
    return false;
}

bool SpaceObject::canBeSelectedBy(P<SpaceObject> other)
{
    if (getDescriptionFor(other).length() > 0)
        return true;
    if (canBeScannedBy(other))
        return true;
    if (canBeTargetedBy(other))
        return true;
    return false;
}

bool SpaceObject::canBeScannedBy(P<SpaceObject> other)
{
    if (getScannedStateFor(other) == SS_FullScan)
        return false;
    if (scanning_complexity_value > 0)
        return true;
    if (scanning_depth_value > 0)
        return true;
    return false;
}

bool SpaceObject::canBeHackedBy(P<SpaceObject> other)
{
    return false;
}

std::vector<std::pair<ESystem, float> > SpaceObject::getHackingTargets()
{
    return std::vector<std::pair<ESystem, float> >();
}

void SpaceObject::hackFinished(P<SpaceObject> source, string target)
{
}

EScannedState SpaceObject::getScannedStateFor(P<SpaceObject> other)
{
    if (!other)
    {
        return SS_NotScanned;
    }
    return getScannedStateForFaction(other->getFactionId());
}

void SpaceObject::setScannedStateFor(P<SpaceObject> other, EScannedState state)
{
    if (!other)
    {
        LOG(ERROR) << "setScannedStateFor called with no other";
        return;
    }
    setScannedStateForFaction(other->getFactionId(), state);
}

EScannedState SpaceObject::getScannedStateForFaction(int faction_id)
{
    if (int(scanned_by_faction.size()) <= faction_id)
        return SS_NotScanned;
    return scanned_by_faction[faction_id];
}

void SpaceObject::setScannedStateForFaction(int faction_id, EScannedState state)
{
    while (int(scanned_by_faction.size()) <= faction_id)
        scanned_by_faction.push_back(SS_NotScanned);
    scanned_by_faction[faction_id] = state;
}

bool SpaceObject::isScanned()
{
    LOG(WARNING) << "Depricated \"isScanned\" function called, use isScannedBy or isScannedByFaction.";
    for(unsigned int faction_id = 0; faction_id < scanned_by_faction.size(); faction_id++)
    {
        if (scanned_by_faction[faction_id] > SS_FriendOrFoeIdentified)
            return true;
    }
    return false;
}

void SpaceObject::setScanned(bool scanned)
{
    for(unsigned int faction_id = 0; faction_id < factionInfo.size(); faction_id++)
    {
        if (!scanned)
            setScannedStateForFaction(faction_id, SS_NotScanned);
        else
            setScannedStateForFaction(faction_id, SS_FullScan);
    }
}

void SpaceObject::setScannedByFaction(string faction_name, bool scanned)
{
    if (!scanned)
        setScannedStateForFaction(FactionInfo::findFactionId(faction_name), SS_NotScanned);
    else
        setScannedStateForFaction(FactionInfo::findFactionId(faction_name), SS_FullScan);
}

bool SpaceObject::isScannedBy(P<SpaceObject> obj)
{
    return getScannedStateFor(obj) > SS_FriendOrFoeIdentified;
}

bool SpaceObject::isScannedByFaction(string faction)
{
    int faction_id = FactionInfo::findFactionId(faction);
    return getScannedStateForFaction(faction_id) > SS_FriendOrFoeIdentified;
}

void SpaceObject::scannedBy(P<SpaceObject> other)
{
    setScannedStateFor(other, SS_FullScan);
}

void SpaceObject::setScanningParameters(int complexity, int depth)
{
    scanning_complexity_value = std::min(4, std::max(0, complexity));
    scanning_depth_value = std::max(0, depth);

    scanned_by_faction.clear();
}

bool SpaceObject::isEnemy(P<SpaceObject> obj)
{
    if (obj)
    {
        return FactionInfo::getState(faction_id, obj->faction_id) == FVF_Enemy;
    } else {
        return false;
    }
}

bool SpaceObject::isFriendly(P<SpaceObject> obj)
{
    if (obj)
    {
        return FactionInfo::getState(faction_id, obj->faction_id) == FVF_Friendly;
    } else {
        return false;
    }
}

void SpaceObject::damageArea(glm::vec2 position, float blast_range, float min_damage, float max_damage, DamageInfo info, float min_range)
{
    PVector<Collisionable> hitList = CollisionManager::queryArea(position - glm::vec2(blast_range, blast_range), position + glm::vec2(blast_range, blast_range));
    foreach(Collisionable, c, hitList)
    {
        P<SpaceObject> obj = c;
        if (obj)
        {
            float dist = glm::length(position - obj->getPosition()) - obj->getRadius() - min_range;
            if (dist < 0) dist = 0;
            if (dist < blast_range - min_range)
            {
                obj->takeDamage(max_damage - (max_damage - min_damage) * dist / (blast_range - min_range), info);
            }
        }
    }
}

bool SpaceObject::areEnemiesInRange(float range)
{
    PVector<Collisionable> hitList = CollisionManager::queryArea(getPosition() - glm::vec2(range, range), getPosition() + glm::vec2(range, range));
    foreach(Collisionable, c, hitList)
    {
        P<SpaceObject> obj = c;
        if (obj && isEnemy(obj))
        {
            auto r = range + obj->getRadius();
            if (glm::length2(getPosition() - obj->getPosition()) < r*r)
                return true;
        }
    }
    return false;
}

PVector<SpaceObject> SpaceObject::getObjectsInRange(float range)
{
    PVector<SpaceObject> ret;
    PVector<Collisionable> hitList = CollisionManager::queryArea(getPosition() - glm::vec2(range, range), getPosition() + glm::vec2(range, range));
    foreach(Collisionable, c, hitList)
    {
        P<SpaceObject> obj = c;
        auto r = range + obj->getRadius();
        if (obj && glm::length2(getPosition() - obj->getPosition()) < r*r)
        {
            ret.push_back(obj);
        }
    }
    return ret;
}

void SpaceObject::setReputationPoints(float amount)
{
    if (gameGlobalInfo->reputation_points.size() < faction_id)
        return;
    gameGlobalInfo->reputation_points[faction_id] = amount;
}

int SpaceObject::getReputationPoints()
{
    if (gameGlobalInfo->reputation_points.size() < faction_id)
        return 0;
    return gameGlobalInfo->reputation_points[faction_id];
}

bool SpaceObject::takeReputationPoints(float amount)
{
    if (gameGlobalInfo->reputation_points.size() < faction_id)
        return false;
     if (gameGlobalInfo->reputation_points[faction_id] < amount)
        return false;
    gameGlobalInfo->reputation_points[faction_id] -= amount;
    return true;
}

void SpaceObject::removeReputationPoints(float amount)
{
    addReputationPoints(-amount);
}

void SpaceObject::addReputationPoints(float amount)
{
    if (gameGlobalInfo->reputation_points.size() < faction_id)
        return;
    gameGlobalInfo->reputation_points[faction_id] += amount;
    if (gameGlobalInfo->reputation_points[faction_id] < 0.0f)
        gameGlobalInfo->reputation_points[faction_id] = 0.0f;
}

void SpaceObject::setCommsScript(string script_name)
{
    this->comms_script_name = script_name;
    if (script_name != "")
        i18n::load("locale/" + script_name.replace(".lua", "." + PreferencesManager::get("language", "en") + ".po"));
    this->comms_script_callback.clear();
}

string SpaceObject::getSectorName()
{
    return ::getSectorName(getPosition());
}

bool SpaceObject::openCommsTo(P<PlayerSpaceship> target)
{
    return sendCommsMessage(target, "");
}

bool SpaceObject::sendCommsMessage(P<PlayerSpaceship> target, string message)
{
    if (!target)
        return false;

    bool result = target->hailByObject(this, message);
    if (!result && message != "")
    {
        target->addToShipLogBy(message, this);
    }
    return result;
}

bool SpaceObject::sendCommsMessageNoLog(P<PlayerSpaceship> target, string message)
{
    if (!target)
        return false;

    return target->hailByObject(this, message);
}

glm::mat4 SpaceObject::getModelMatrix() const
{
    auto position = getPosition();
    auto rotation = getRotation();
    auto model_matrix = glm::translate(glm::identity<glm::mat4>(), glm::vec3{ position.x, position.y, 0.f });
    return glm::rotate(model_matrix, glm::radians(rotation), glm::vec3{ 0.f, 0.f, 1.f });
}

template<> void convert<EDamageType>::param(lua_State* L, int& idx, EDamageType& dt)
{
    string str = string(luaL_checkstring(L, idx++)).lower();
    if (str == "energy")
        dt = DT_Energy;
    else if (str == "kinetic")
        dt = DT_Kinetic;
    else if (str == "emp")
        dt = DT_EMP;
}

// Define a script conversion function for the DamageInfo structure.
template<> void convert<DamageInfo>::param(lua_State* L, int& idx, DamageInfo& di)
{
    if (!lua_isstring(L, idx))
        return;
    string str = string(luaL_checkstring(L, idx++)).lower();
    if (str == "energy")
        di.type = DT_Energy;
    else if (str == "kinetic")
        di.type = DT_Kinetic;
    else if (str == "emp")
        di.type = DT_EMP;

    if (!lua_isnumber(L, idx))
        return;

    di.location.x = luaL_checknumber(L, idx++);
    di.location.y = luaL_checknumber(L, idx++);

    if (lua_isnil(L, idx))
        idx++;
    else if (!lua_isnumber(L, idx))
        return;
    else
        di.frequency = luaL_checkinteger(L, idx++);

    if (!lua_isstring(L, idx))
        return;

    convert<ESystem>::param(L, idx, di.system_target);
}

template<> void convert<EScannedState>::param(lua_State* L, int& idx, EScannedState& ss)
{
    ss = SS_NotScanned;
    if (!lua_isstring(L, idx))
        return;
    string str = string(luaL_checkstring(L, idx++)).lower();
    if (str == "notscanned" || str == "not")
        ss = SS_NotScanned;
    else if (str == "friendorfoeidentified")
        ss = SS_FriendOrFoeIdentified;
    else if (str == "simple" || str == "simplescan")
        ss = SS_SimpleScan;
    else if (str == "full" || str == "fullscan")
        ss = SS_FullScan;
}
