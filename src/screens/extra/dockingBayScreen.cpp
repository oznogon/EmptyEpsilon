#include "dockingBayScreen.h"
#include "i18n.h"

#include "gui/gui2_button.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_togglebutton.h"
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
    if (!my_spaceship.hasComponent<DockingBay>()) return;

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
        ->setAttribute("margin", "0, 20, 0, 0");

    right_column = new GuiElement(layout, "DOCKING_BAY_RIGHT_COLUMN");
    right_column
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Left column: Docking bay berths
    (new GuiLabel(left_column, "DOCKING_BAY_BERTHS_LABEL", tr("Berths"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    docking_bay_berths = new GuiEntityInfoPanelGrid(left_column, "DOCKING_BAY_SHIPS", {},
        [this](int index)
        {
            selectBerth(index);
        }
    );
    docking_bay_berths
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Right column: Docked ship, cargo info
    (new GuiLabel(right_column, "DOCKING_BAY_INFO_LABEL", tr("Selected berth"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    docking_bay_info = new GuiElement(right_column, "DOCKING_BAY_INFO_PANEL");
    docking_bay_info
        ->setSize(GuiElement::GuiSizeMax, 200.0f)
        ->setAttribute("layout", "horizontal");
    docking_bay_info
        ->setAttribute("margin", "0, 0, 0, 10");

    // Is there a better placeholder than my_spaceship?
    top_row_info = new GuiEntityInfoPanel(docking_bay_info, "", sp::ecs::Entity(), [](sp::ecs::Entity entity) {});
    top_row_info
        ->setSize(GuiEntityInfoPanel::default_panel_size, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "0, 10, 0, 0");

    GuiElement* top_row_kvs_1 = new GuiElement(docking_bay_info, "");
    top_row_kvs_1
        ->setSize(200.0f, 200.0f)
        ->setAttribute("layout", "vertical");
    top_row_kvs_1
        ->setAttribute("margin", "0, 10, 0, 0");

    for (int i = MW_Homing; i < MW_Count; i++)
    {
        entity_missiles[i] = new GuiKeyValueDisplay(top_row_kvs_1, "", kv_split, getLocaleMissileWeaponName(static_cast<EMissileWeapons>(i)), "");
        entity_missiles[i]
            ->setSize(GuiElement::GuiSizeMax, kv_size);

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

    GuiElement* top_row_kvs_2 = new GuiElement(docking_bay_info, "");
    top_row_kvs_2
        ->setSize(200.0f, 200.0f)
        ->setAttribute("layout", "vertical");

    entity_energy = new GuiKeyValueDisplay(top_row_kvs_2, "", kv_split, tr("dockingbay", "Energy"), "");
    entity_energy
        ->setIcon("gui/icons/energy")
        ->setSize(GuiElement::GuiSizeMax, kv_size);
    entity_hull = new GuiKeyValueDisplay(top_row_kvs_2, "", kv_split, tr("dockingbay", "Hull"), "");
    entity_hull
        ->setIcon("gui/icons/hull")
        ->setSize(GuiElement::GuiSizeMax, kv_size);

    // Right column, bottom row
    (new GuiLabel(right_column, "DOCKING_BAY_BERTH_LABEL", tr("Berth operations"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    GuiElement* move_controls_row = new GuiElement(right_column, "DOCKING_BAY_MOVE_CONTROLS");
    move_controls_row
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("layout", "horizontal");
    move_controls_row
        ->setAttribute("margin", "0, 0, 0, 10");

    (new GuiLabel(move_controls_row, "", tr("dockingbay", "Move to: "), 30.0f))
        ->setSize(100.0f, 50.0f);

    target_berth = new GuiSelector(move_controls_row, "",
        [](int index, string value)
        {
        }
    );
    target_berth
        ->setSize(250.0f, GuiElement::GuiSizeMax);

    (new GuiButton(move_controls_row, "", tr("dockingbay", "Move"),
        [this]()
        {
            if (selected_entity && selected_entity != sp::ecs::Entity())
                DockingSystem::assignInternalEntityToBerth(selected_entity, target_berth->getSelectionValue().toInt());
        }
    ))->setSize(100.0f, 50.0f);

    scramble = new GuiToggleButton(move_controls_row, "DOCKING_BAY_SCRAMBLE", tr("dockingbay", "Scramble hangars"),
        [this](bool value)
        {
            if (!value)
            {
                scramble->setText(tr("dockingbay", "Scramble hangars"));
                if (!my_spaceship) return;

                if (auto bay = my_spaceship.getComponent<DockingBay>())
                {
                    // Undock all entities from hangar berths
                    for (auto& berth : bay->berths)
                    {
                        if (berth.docked_entity && berth.docked_entity != sp::ecs::Entity() && berth.type == DockingBay::BerthType::Hangar)
                            DockingSystem::requestUndock(berth.docked_entity);
                    }
                }
            }
            else
            {
                scramble->setText(tr("dockingbay", "Confirm scramble"));
            }
        }
    );
    scramble
        ->setStyle("button.dockingbay_scramble")
        ->setSize(220.0f, 50.0f);

    hangar_controls = new GuiElement(right_column, "DOCKING_BAY_HANGAR_CONTROLS");
    hangar_controls
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    (new GuiLabel(hangar_controls, "DOCKING_BAY_HANGAR_LABEL", tr("Hangar operations"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    GuiElement* undock_controls_row = new GuiElement(hangar_controls, "DOCKING_BAY_UNDOCK_CONTROLS");
    undock_controls_row
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("layout", "horizontal");

    (new GuiButton(undock_controls_row, "", tr("dockingbay", "Undock"),
        [this]()
        {
            if (selected_entity && selected_entity != sp::ecs::Entity())
                DockingSystem::requestUndock(selected_entity);
        }
    ))->setIcon("gui/icons/docking")
        ->setSize(150.0f, 50.0f);

    energy_controls = new GuiElement(right_column, "DOCKING_BAY_ENERGY_CONTROLS");
    energy_controls
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    (new GuiLabel(energy_controls, "DOCKING_BAY_ENERGY_LABEL", tr("Energy operations"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    thermal_controls = new GuiElement(right_column, "DOCKING_BAY_THERMAL_CONTROLS");
    thermal_controls
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    (new GuiLabel(thermal_controls, "DOCKING_BAY_THERMAL_LABEL", tr("Thermal operations"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    repair_controls = new GuiElement(right_column, "DOCKING_BAY_REPAIR_CONTROLS");
    repair_controls
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    (new GuiLabel(repair_controls, "DOCKING_BAY_REPAIR_LABEL", tr("Repair operations"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    missile_controls = new GuiElement(right_column, "DOCKING_BAY_MISSILE_CONTROLS");
    missile_controls
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    (new GuiLabel(missile_controls, "DOCKING_BAY_MISSILE_LABEL", tr("Missile operations"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    storage_controls = new GuiElement(right_column, "DOCKING_BAY_STORAGE_CONTROLS");
    storage_controls
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    (new GuiLabel(storage_controls, "DOCKING_BAY_STORAGE_LABEL", tr("Storage operations"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

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

    // Check for changes in the berths.
    bool list_changed = cached_berth_entities.size() != bay->berths.size();
    if (!list_changed)
    {
        for (size_t i = 0; i < bay->berths.size(); i++)
        {
            if (bay->berths[i].docked_entity != cached_berth_entities[i])
            {
                list_changed = true;
                break;
            }
        }
    }

    // Update the grid only when the list of ships changes.
    if (list_changed)
    {
        updateBerthsList();

        // Build cached list from berths
        cached_berth_entities.resize(bay->berths.size());
        for (size_t i = 0; i < bay->berths.size(); i++)
            cached_berth_entities[i] = bay->berths[i].docked_entity;

        // If selected berth index is now out of range, deselect it
        if (selected_berth_index >= static_cast<int>(bay->berths.size()))
        {
            selectBerth(-1);
        }
    }

    // Update berth labels every frame to ensure they're set after panels are created
    updateBerthsLabels();

    // Update the display if a berth is selected
    if (selected_berth_index >= 0) updateSelectedEntityDisplay();
}

void DockingBayScreen::selectBerth(int berth_index)
{
    auto bay = my_spaceship.getComponent<DockingBay>();
    if (!bay) return;

    // Validate index and update selection
    if (berth_index >= 0 && berth_index < static_cast<int>(bay->berths.size()))
    {
        selected_berth_index = berth_index;
        selected_entity = bay->berths[berth_index].docked_entity;
    }
    else
    {
        selected_berth_index = -1;
        selected_entity = sp::ecs::Entity();
    }

    // Update berth type operations
    switch (bay->berths[berth_index].type)
    {
        case DockingBay::BerthType::Hangar:
            hangar_controls->show();
            energy_controls->hide();
            thermal_controls->hide();
            missile_controls->hide();
            repair_controls->hide();
            storage_controls->hide();
            break;
        case DockingBay::BerthType::Energy:
            hangar_controls->hide();
            energy_controls->show();
            thermal_controls->hide();
            missile_controls->hide();
            repair_controls->hide();
            storage_controls->hide();
            break;
        case DockingBay::BerthType::Thermal:
            hangar_controls->hide();
            energy_controls->hide();
            thermal_controls->show();
            missile_controls->hide();
            repair_controls->hide();
            storage_controls->hide();
            break;
        case DockingBay::BerthType::Missiles:
            hangar_controls->hide();
            energy_controls->hide();
            thermal_controls->hide();
            missile_controls->show();
            repair_controls->hide();
            storage_controls->hide();
            break;
        case DockingBay::BerthType::Repair:
            hangar_controls->hide();
            energy_controls->hide();
            thermal_controls->hide();
            missile_controls->hide();
            repair_controls->show();
            storage_controls->hide();
            break;
        case DockingBay::BerthType::Storage:
            hangar_controls->hide();
            energy_controls->hide();
            thermal_controls->hide();
            missile_controls->hide();
            repair_controls->hide();
            storage_controls->show();
            break;
    }
    // Force immediate update of displays
    updateSelectedEntityDisplay();
}

void DockingBayScreen::updateBerthsList()
{
    if (!my_spaceship) return;

    auto bay = my_spaceship.getComponent<DockingBay>();
    if (!bay) return;

    // Build vector of entities docked at berths
    std::vector<sp::ecs::Entity> berths_entities(bay->berths.size());
    std::vector<string> berths_strings;

    for (size_t i = 0; i < bay->berths.size(); i++)
    {
        berths_entities[i] = bay->berths[i].docked_entity;
        berths_strings.push_back(static_cast<string>(static_cast<int>(i)));
    }

    // Set entities (this triggers rebuild of panels)
    docking_bay_berths->setEntities(berths_entities);
    target_berth->setOptions(berths_strings);
}

void DockingBayScreen::updateBerthsLabels()
{
    if (!my_spaceship) return;

    auto bay = my_spaceship.getComponent<DockingBay>();
    if (!bay) return;

    // Set custom labels on each panel
    for (size_t i = 0; i < bay->berths.size(); i++)
    {
        const auto& berth = bay->berths[i];

        // Number the panel and set berth type info
        const int idx = static_cast<int>(i);
        docking_bay_berths
            ->setCustomLabel(idx, 0, tr("Berth {i}").format({{"i", static_cast<string>(idx + 1)}}))
            ->setCustomIcon(idx, 1, bay->getTypeIcon(berth.type))
            ->setCustomLabel(idx, 2, bay->getTypeName(berth.type));

        target_berth->setEntryIcon(
            i,
            bay->getTypeIcon(berth.type)
        );

        if (berth.docked_entity == sp::ecs::Entity())
        {
            target_berth->setEntryName(
                i,
                tr("dockingbay", "{i} ({type})").format({
                    {"i" , static_cast<string>(static_cast<int>(i) + 1)},
                    {"type", bay->getTypeName(berth.type)}
                })
            );
        }
        else
        {
            target_berth->setEntryName(
                i,
                tr("dockingbay", "{i} -Occupied-").format({
                    {"i" , static_cast<string>(static_cast<int>(i) + 1)}
                })
            );
        }
    }
}

void DockingBayScreen::updateSelectedEntityDisplay()
{
    auto bay = my_spaceship.getComponent<DockingBay>();
    if (!bay) return;

    // Select the panel by index
    docking_bay_berths->selectPanelByIndex(selected_berth_index);

    // Validate berth index
    if (selected_berth_index < 0 || selected_berth_index >= static_cast<int>(bay->berths.size()))
    {
        selected_entity = sp::ecs::Entity();
        top_row_info
            ->setEntity(selected_entity)
            ->setCustomLabel(0, "")
            ->setCustomIcon(1, "")
            ->setCustomLabel(2, "");
        entity_energy->setValue("");
        entity_hull->setValue("");
        for (auto kv : entity_missiles) kv->setValue("");
        return;
    }

    // Update selected_entity from the berth
    selected_entity = bay->berths[selected_berth_index].docked_entity;

    const string type_icon = bay->getTypeIcon(bay->berths[selected_berth_index].type);
    const string type_name = bay->getTypeName(bay->berths[selected_berth_index].type);
    top_row_info
        ->setEntity(selected_entity)
        ->setCustomLabel(0, tr("Berth {i}").format({{"i", selected_berth_index + 1}}))
        ->setCustomIcon(1, type_icon)
        ->setCustomLabel(2, type_name);

    // Update reactor/energy display
    if (auto reactor = selected_entity.getComponent<Reactor>())
    {
        entity_energy
            ->setValue(static_cast<string>("{energy}/{max_energy}").format({
                {"energy", static_cast<int>(reactor->energy)},
                {"max_energy", static_cast<int>(reactor->max_energy)}
            }));
    }
    else entity_energy->setValue(tr("dockingbay", "No reactor"));

    // Update hull display
    if (auto hull = selected_entity.getComponent<Hull>())
    {
        if (hull->max > 0.0f)
        {
            entity_hull
                ->setValue(static_cast<string>("{hull}%").format({
                    {"hull", static_cast<int>((hull->current / hull->max) * 100.0f)}
                }));
        }
        else entity_hull->setValue("");
    }
    else entity_hull->setValue(tr("dockingbay", "N/A"));

    // Update missile displays
    if (auto tubes = selected_entity.getComponent<MissileTubes>())
    {
        for (int i = MW_Homing; i < MW_Count; i++)
            updateMissileDisplay(entity_missiles[i], tubes, static_cast<EMissileWeapons>(i));
    }
    else
        for (auto kv : entity_missiles) kv->setValue("-");
}

void DockingBayScreen::updateMissileDisplay(GuiKeyValueDisplay* display,
                                            MissileTubes* tubes,
                                            EMissileWeapons type)
{
    if (tubes->storage_max[type] > 0)
    {
        display
            ->setValue(static_cast<string>(tubes->storage[type]) + "/" +
                      static_cast<string>(tubes->storage_max[type]));
    }
    else display->setValue("-");
}
