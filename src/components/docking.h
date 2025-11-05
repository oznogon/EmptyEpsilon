#pragma once

#include <unordered_set>
#include <vector>
#include "i18n.h"
#include "io/dataBuffer.h"
#include "multiplayer.h"

enum class DockingStyle
{
    None,
    External,
    Internal,
};

// DockingBay component allows other entities to dock to this entity.
class DockingBay
{
public:
    static constexpr uint32_t ShareEnergy = 1 << 0;
    static constexpr uint32_t Repair = 1 << 1;
    static constexpr uint32_t ChargeShield = 1 << 2; // Increased shield recharge rate
    static constexpr uint32_t RestockProbes = 1 << 3;
    static constexpr uint32_t RestockMissiles = 1 << 4;  // Only for AI controlled ships. Players use the comms system.

    std::unordered_set<string> external_dock_classes;
    bool external_dock_classes_dirty = true;
    std::unordered_set<string> internal_dock_classes;
    bool internal_dock_classes_dirty = true;

    uint32_t flags = 0;

    enum class BerthType
    {
        Hangar,
        Energy,
        Missiles,
        Thermal,
        Repair,
        Storage
    };

    struct Berth
    {
        sp::ecs::Entity docked_entity;
        BerthType type = BerthType::Hangar;
        float move_time = 10.0f;
        float move_progress = 0.0f;
        float transfer_rate = 0.0f;
    };
    static constexpr int default_berth_count = 9;
    std::vector<Berth> berths;

    // Constructor to initialize default berths
    DockingBay()
    {
        berths.resize(default_berth_count);
        /*
                        {type = "hangar", move_time = 5.0, transfer_rate = 1.0},
                {type = "hangar", move_time = 5.0, transfer_rate = 1.0},
                {type = "energy", move_time = 5.0, transfer_rate = 1.0},
                {type = "missiles", move_time = 10.0, transfer_rate = 2.0},
                {type = "thermal", move_time = 10.0, transfer_rate = 2.0},
                {type = "repair", move_time = 15.0, transfer_rate = 1.5},
                {type = "storage", move_time = 15.0, transfer_rate = 1.5},
                {type = "storage", move_time = 20.0, transfer_rate = 0.5},
                {type = "storage", move_time = 10.0, transfer_rate = 1.0}
*/
        for (size_t i = 0; i < berths.size(); i++)
        {
            if (i < 2)
                berths[i].type = BerthType::Hangar;
            else if (i < 3)
                berths[i].type = BerthType::Energy;
            else if (i < 4)
                berths[i].type = BerthType::Missiles;
            else if (i < 5)
                berths[i].type = BerthType::Thermal;
            else if (i < 6)
                berths[i].type = BerthType::Repair;
            else
                berths[i].type = BerthType::Storage;
        }
    }

    string getTypeIcon(DockingBay::BerthType type)
    {
        string type_icon = "";

        switch (type)
        {
            case DockingBay::BerthType::Hangar:
                type_icon = "gui/icons/docking";
                break;
            case DockingBay::BerthType::Energy:
                type_icon = "gui/icons/energy";
                break;
            case DockingBay::BerthType::Missiles:
                type_icon = "gui/icons/system_missile";
                break;
            case DockingBay::BerthType::Thermal:
                type_icon = "gui/icons/status_overheat";
                break;
            case DockingBay::BerthType::Repair:
                type_icon = "gui/icons/status_damaged";
                break;
            case DockingBay::BerthType::Storage:
                type_icon = "gui/icons/hull";
                break;
        }

        return type_icon;
    }

    string getTypeName(DockingBay::BerthType type)
    {
        string type_name = tr("dockingbay", "Unknown type");

        switch (type)
        {
            case DockingBay::BerthType::Hangar:
                type_name = tr("dockingbay", "Hangar");
                break;
            case DockingBay::BerthType::Energy:
                type_name = tr("dockingbay", "Energy");
                break;
            case DockingBay::BerthType::Missiles:
                type_name = tr("dockingbay", "Missiles");
                break;
            case DockingBay::BerthType::Thermal:
                type_name = tr("dockingbay", "Thermal");
                break;
            case DockingBay::BerthType::Repair:
                type_name = tr("dockingbay", "Repair");
                break;
            case DockingBay::BerthType::Storage:
                type_name = tr("dockingbay", "Storage");
                break;
        }

        return type_name;
    }
};

// DockingPort component allows this entity to dock to other entities.
class DockingPort
{
public:
    string dock_class;
    string dock_subclass;

    enum class State {
        NotDocking = 0,
        Docking,
        Docked
    } state = State::NotDocking;
    
    sp::ecs::Entity target;
    glm::vec2 docked_offset;

    bool auto_reload_missiles = false;
    float auto_reload_missile_delay = 0.0f;
    float auto_reload_missile_time = 10.0f;

    DockingStyle canDockOn(DockingBay& bay) {
        if (bay.external_dock_classes.empty() && bay.internal_dock_classes.empty()) return DockingStyle::External;
        if (bay.external_dock_classes.find(dock_class) != bay.external_dock_classes.end()) return DockingStyle::External;
        if (bay.external_dock_classes.find(dock_subclass) != bay.external_dock_classes.end()) return DockingStyle::External;
        if (bay.internal_dock_classes.find(dock_class) != bay.internal_dock_classes.end()) return DockingStyle::Internal;
        if (bay.internal_dock_classes.find(dock_subclass) != bay.internal_dock_classes.end()) return DockingStyle::Internal;
        return DockingStyle::None;
    }
};