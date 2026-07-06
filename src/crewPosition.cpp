#include "crewPosition.h"

string crewPositionToString(CrewPosition value) {
    switch(value) {
    case CrewPosition::helmsOfficer: return "helms";
    case CrewPosition::weaponsOfficer: return "weapons";
    case CrewPosition::engineering: return "engineering";
    case CrewPosition::scienceOfficer: return "science";
    case CrewPosition::relayOfficer: return "relay";
    case CrewPosition::tacticalOfficer: return "tactical";
    case CrewPosition::engineeringPlus: return "engineering+";
    case CrewPosition::operationsOfficer: return "operations";
    case CrewPosition::singlePilot: return "singlepilot";
    case CrewPosition::beamWeaponsOfficer: return "beamweapons";
    case CrewPosition::missileWeaponsOfficer: return "missileweapons";
    case CrewPosition::damageControl: return "damagecontrol";
    case CrewPosition::powerManagement: return "powermanagement";
    case CrewPosition::databaseView: return "database";
    case CrewPosition::dockingBay: return "dockingbay";
    case CrewPosition::strategicMap: return "strategicmap";
    case CrewPosition::commsOnly: return "commsonly";
    case CrewPosition::shipLog: return "shiplog";
    case CrewPosition::radarOfficer: return "radarofficer";
    case CrewPosition::probeCamera: return "probecamera";
    case CrewPosition::targetAnalysis: return "targetanalysis";
    case CrewPosition::briefing: return "briefingofficer";
    case CrewPosition::droneOperations: return "droneoperations";
    default: return "none";
    }
}

std::optional<CrewPosition> tryParseCrewPosition(string value) {
    // 6/5-player crew
    if (value == "helms" || value == "helmsofficer")
        return CrewPosition::helmsOfficer;
    else if (value == "weapons" || value == "weaponsofficer")
        return CrewPosition::weaponsOfficer;
    else if (value == "engineering" || value == "engineeringsofficer")
        return CrewPosition::engineering;
    else if (value == "science" || value == "scienceofficer")
        return CrewPosition::scienceOfficer;
    else if (value == "relay" || value == "relayofficer")
        return CrewPosition::relayOfficer;

    // 4/3-player crew
    else if (value == "tactical" || value == "tacticalofficer")
        return CrewPosition::tacticalOfficer; // helms + weapons - shields
    else if (value == "engineering+" || value == "engineering+officer" || value == "engineeringadvanced" || value == "engineeringadvancedofficer" || value == "engineeringplus")
        return CrewPosition::engineeringPlus; // engineering + shields
    else if (value == "operations" || value == "operationsofficer")
        return CrewPosition::operationsOfficer; // science + comms

    // 1-player crew
    else if (value == "single" || value == "singlepilot")
        return CrewPosition::singlePilot;

    // Split weapons screens
    else if (value == "beamweapons" || value == "beamweaponsofficer")
        return CrewPosition::beamWeaponsOfficer;
    else if (value == "missileweapons" || value == "missileweaponsofficer")
        return CrewPosition::missileWeaponsOfficer;

    // Extras
    else if (value == "damagecontrol")
        return CrewPosition::damageControl;
    else if (value == "powermanagement")
        return CrewPosition::powerManagement;
    else if (value == "database" || value == "databaseview")
        return CrewPosition::databaseView;
    else if (value == "dockingbay")
        return CrewPosition::dockingBay;
    else if (value == "altrelay" || value == "strategicmap")
        return CrewPosition::strategicMap;
    else if (value == "commsonly")
        return CrewPosition::commsOnly;
    else if (value == "shiplog")
        return CrewPosition::shipLog;
    else if (value == "radarofficer" || value == "radar")
        return CrewPosition::radarOfficer;
    else if (value == "probecamera" || value == "probe")
        return CrewPosition::probeCamera;
    else if (value == "targetanalysis")
        return CrewPosition::targetAnalysis;
    else if (value == "briefingofficer" || value == "briefing")
        return CrewPosition::briefing;
    else if (value == "droneoperations" || value == "drone")
        return CrewPosition::droneOperations;
    else
        return {};
}
