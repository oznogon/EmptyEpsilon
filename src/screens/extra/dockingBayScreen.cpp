#include "dockingBayScreen.h"
#include "i18n.h"

#include "gui/gui2_button.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_listbox.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/entityInfoPanel.h"

#include "components/docking.h"
#include "components/hull.h"
#include "components/missiletubes.h"
#include "components/name.h"
#include "components/reactor.h"
#include "systems/docking.h"

DockingBayScreen::DockingBayScreen(GuiContainer* owner)
: GuiOverlay(owner, "DOCKING_BAY_SCREEN", colorConfig.background),
  selected_entity()
{
    // Layout elements
    GuiElement* layout = new GuiElement(this, "DOCKING_BAY_LAYOUT");
    layout
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");
    layout->setAttribute("padding", "20");

    left_column = new GuiElement(layout, "DOCKING_BAY_LEFT_COLUMN");
    left_column
        ->setSize(240.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    left_column
        ->setAttribute("margin", "0, 10, 0, 0");

    right_column = new GuiElement(layout, "DOCKING_BAY_RIGHT_COLUMN");
    right_column
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Left column: Docking bay ships
    docking_bay_ships = new GuiEntityInfoPanelGrid(left_column, "DOCKING_BAY_SHIPS", {},
        [this](sp::ecs::Entity entity)
        {
            selectEntity(entity);
        }
    );
    docking_bay_ships
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    docking_bay_scramble = new GuiButton(left_column, "DOCKING_BAY_SCRAMBLE", tr("dockingbay", "Scramble"),
        []()
        {
            if (!my_spaceship) return;

            if (auto bay = my_spaceship.getComponent<DockingBay>())
            {
                while (!bay->docked_entities.empty())
                    for (auto entity : bay->docked_entities) DockingSystem::requestUndock(entity);
            }
        }
    );
    docking_bay_scramble
        ->setStyle("button.dockingbay_scramble")
        ->setSize(GuiElement::GuiSizeMax, 50.0f);

    // Right column: Docked ship, cargo info
    docking_bay_info = new GuiElement(right_column, "DOCKING_BAY_INFO_PANEL");
    docking_bay_info
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    // Right column, top row
    GuiElement* top_row = new GuiElement(docking_bay_info, "");
    top_row
        ->setSize(GuiElement::GuiSizeMax, 200.0f)
        ->setAttribute("layout", "horizontal");

    // Is there a better placeholder than my_spaceship?
    top_row_info = new GuiEntityInfoPanel(top_row, "", my_spaceship, [](sp::ecs::Entity entity) {});
    top_row_info
        ->setSize(GuiEntityInfoPanel::default_panel_size, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "10, 0");

    GuiElement* top_row_kvs_1 = new GuiElement(top_row, "");
    top_row_kvs_1
        ->setSize(200.0f, 200.0f)
        ->setAttribute("layout", "vertical");
    top_row_kvs_1
        ->setAttribute("margin", "10, 0");

    entity_energy = new GuiKeyValueDisplay(top_row_kvs_1, "", kv_split, tr("dockingbay", "Energy"), "");
    entity_energy
        ->setIcon("gui/icons/energy")
        ->setSize(GuiElement::GuiSizeMax, kv_size);
    entity_hull = new GuiKeyValueDisplay(top_row_kvs_1, "", kv_split, tr("dockingbay", "Hull"), "");
    entity_hull
        ->setIcon("gui/icons/hull")
        ->setSize(GuiElement::GuiSizeMax, kv_size);

    GuiElement* top_row_kvs_2 = new GuiElement(top_row, "");
    top_row_kvs_2
        ->setSize(200.0f, 200.0f)
        ->setAttribute("layout", "vertical");
    top_row_kvs_2
        ->setAttribute("margin", "10, 0");

    for (int i = MW_Homing; i < MW_Count; i++)
    {
        entity_missiles[i] = new GuiKeyValueDisplay(top_row_kvs_2, "", kv_split, getLocaleMissileWeaponName(static_cast<EMissileWeapons>(i)), "");
        entity_missiles[i]
            ->setSize(GuiElement::GuiSizeMax, kv_size)
            ->hide();

        switch (static_cast<EMissileWeapons>(i))
        {
            case MW_Homing:
                entity_missiles[i]->setIcon("gui/icons/weapon-homing");
                break;
            case MW_Nuke:
                entity_missiles[i]->setIcon("gui/icons/weapon-nuke");
                break;
            case MW_EMP:
                entity_missiles[i]->setIcon("gui/icons/weapon-emp");
                break;
            case MW_HVLI:
                entity_missiles[i]->setIcon("gui/icons/weapon-hvli");
                break;
            case MW_Mine:
                entity_missiles[i]->setIcon("gui/icons/weapon-mine");
                break;
            default:
                break;
        }
    }

    // Right column, bottom row
    GuiElement* bottom_row = new GuiElement(right_column, "");
    bottom_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");

    berths = new GuiListbox(bottom_row, "",
        [this](int index, string value)
        {
            LOG(Debug, "index: ", index, " value: ", value);
            if (selected_entity != sp::ecs::Entity())
                DockingSystem::assignInternalEntityToBerth(selected_entity, value.toInt());
        }
    );
    berths
        ->setSize(500.0f, GuiElement::GuiSizeMax);

    // Custom ship functions
    /*
    (new GuiCustomShipFunctions(this, CrewPosition::dockingBay, "DOCKING_BAY_CSF"))
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax);
    */
}

void DockingBayScreen::onUpdate()
{
    if (!my_spaceship) return;

    auto bay = my_spaceship.getComponent<DockingBay>();
    if (!bay) return;

    // Initialize berths if empty (using default configuration)
    if (bay->berths.empty())
    {
        bay->berths.resize(DockingBay::default_berth_count);
        for (size_t i = 0; i < bay->berths.size(); i++)
        {
            // Set up default berth types based on position
            if (i < 3)
                bay->berths[i].type = DockingBay::BerthType::Launcher;
            else if (i < 5)
                bay->berths[i].type = DockingBay::BerthType::Energy;
            else if (i < 7)
                bay->berths[i].type = DockingBay::BerthType::Missiles;
            else
                bay->berths[i].type = DockingBay::BerthType::Storage;
        }
    }

    // Check for changes in the docked entities list.
    bool list_changed = false;
    if (bay->docked_entities_dirty ||
        bay->docked_entities.size() != cached_docked_entities.size())
    {
        list_changed = true;
    }
    else
    {
        for (size_t i = 0; i < bay->docked_entities.size(); i++)
        {
            if (bay->docked_entities[i] != cached_docked_entities[i])
            {
                list_changed = true;
                break;
            }
        }
    }

    // Update the grid only when the list of ships changes.
    if (list_changed)
    {
        updateDockedEntitiesList();
        cached_docked_entities = bay->docked_entities;

        // If selected entity is no longer docked, deselect it.
        if (selected_entity)
        {
            bool still_docked = false;
            for (auto entity : bay->docked_entities)
            {
                if (entity == selected_entity)
                {
                    still_docked = true;
                    break;
                }
            }

            if (!still_docked) selectEntity(sp::ecs::Entity());
        }
    }

    // Update the display only if an entity is selected.
    if (selected_entity) updateSelectedEntityDisplay();

    // Update berths listbox.
    std::vector<string> berths_keys;
    std::vector<string> berths_values;

    for (size_t i = 0; i < bay->berths.size(); i++)
    {
        const auto& berth = bay->berths[i];

        // Create berth type label.
        string type_label;
        switch (berth.type)
        {
            case DockingBay::BerthType::Launcher:
                type_label = tr("dockingbay", "Launcher");
                break;
            case DockingBay::BerthType::Energy:
                type_label = tr("dockingbay", "Energy");
                break;
            case DockingBay::BerthType::Missiles:
                type_label = tr("dockingbay", "Missiles");
                break;
            case DockingBay::BerthType::Thermal:
                type_label = tr("dockingbay", "Thermal");
                break;
            case DockingBay::BerthType::Repair:
                type_label = tr("dockingbay", "Repair");
                break;
            case DockingBay::BerthType::Storage:
                type_label = tr("dockingbay", "Storage");
                break;
        }

        // Format: "Berth 1 (Type): Occupant or Empty"
        string value = static_cast<string>(static_cast<int>(i));
        string callsign = tr("dockingbay", "Unknown");
        if (berth.docked_entity == sp::ecs::Entity())
            callsign = tr("dockingbay", "Empty");
        else if (auto callsign_component = berth.docked_entity.getComponent<CallSign>())
            callsign = callsign_component->callsign;
        string key = tr("Berth {index} ({type}): {callsign}").format({
            {"index", static_cast<int>(i + 1)},
            {"type", type_label},
            {"callsign", callsign}
        });

        berths_keys.push_back(key);
        berths_values.push_back(value);
    }

    berths->setOptions(berths_keys, berths_values);
}

void DockingBayScreen::selectEntity(sp::ecs::Entity entity)
{
    if (!entity)
    {
        docking_bay_info->hide();
        selected_entity = sp::ecs::Entity();
        return;
    }

    selected_entity = entity;
    docking_bay_info->show();
    top_row_info->setEntity(entity);

    // Force immediate update of displays
    updateSelectedEntityDisplay();
}

void DockingBayScreen::updateDockedEntitiesList()
{
    if (!my_spaceship) return;

    auto bay = my_spaceship.getComponent<DockingBay>();
    if (!bay) return;

    docking_bay_ships->setEntities(bay->docked_entities);
}

void DockingBayScreen::updateSelectedEntityDisplay()
{
    if (!selected_entity)
    {
        docking_bay_info->hide();
        selected_entity = sp::ecs::Entity();
        return;
    }

    docking_bay_ships->selectEntityPanel(selected_entity);

    // Update reactor/energy display
    if (auto reactor = selected_entity.getComponent<Reactor>())
    {
        entity_energy
            ->setValue(static_cast<string>("{energy}/{max_energy}").format({
                {"energy", static_cast<int>(reactor->energy)},
                {"max_energy", static_cast<int>(reactor->max_energy)}
            }))
            ->show();
    }
    else entity_energy->hide();

    // Update hull display
    if (auto hull = selected_entity.getComponent<Hull>())
    {
        if (hull->max > 0.0f)
        {
            entity_hull
                ->setValue(static_cast<string>("{hull}%").format({
                    {"hull", static_cast<int>((hull->current / hull->max) * 100.0f)}
                }))
                ->show();
        }
        else entity_hull->hide();
    }
    else entity_hull->hide();

    // Update missile displays
    if (auto tubes = selected_entity.getComponent<MissileTubes>())
    {
        for (int i = MW_Homing; i < MW_Count; i++)
            updateMissileDisplay(entity_missiles[i], tubes, static_cast<EMissileWeapons>(i));
    }
    else
        for (auto kv : entity_missiles) kv->hide();
}

void DockingBayScreen::updateMissileDisplay(GuiKeyValueDisplay* display,
                                            MissileTubes* tubes,
                                            EMissileWeapons type)
{
    if (tubes->storage_max[type] > 0)
    {
        display
            ->setValue(static_cast<string>(tubes->storage[type]) + "/" +
                      static_cast<string>(tubes->storage_max[type]))
            ->show();
    }
    else display->hide();
}
