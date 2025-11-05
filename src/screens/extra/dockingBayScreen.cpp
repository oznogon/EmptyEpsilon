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
        ->setAttribute("margin", "0, 10, 0, 0");

    right_column = new GuiElement(layout, "DOCKING_BAY_RIGHT_COLUMN");
    right_column
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Left column: Docking bay ships
    docking_bay_berths = new GuiEntityInfoPanelGrid(left_column, "DOCKING_BAY_SHIPS", {},
        [this](int index)
        {
            selectBerth(index);
        }
    );
    docking_bay_berths
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    docking_bay_scramble = new GuiButton(left_column, "DOCKING_BAY_SCRAMBLE", tr("dockingbay", "Scramble"),
        []()
        {
            if (!my_spaceship) return;

            if (auto bay = my_spaceship.getComponent<DockingBay>())
            {
                // Undock all entities from berths
                for (auto& berth : bay->berths)
                {
                    if (berth.docked_entity)
                        DockingSystem::requestUndock(berth.docked_entity);
                }
            }
        }
    );
    docking_bay_scramble
        ->setStyle("button.dockingbay_scramble")
        ->setSize(GuiElement::GuiSizeMax, 50.0f);

    // Right column: Docked ship, cargo info
    docking_bay_info = new GuiElement(right_column, "DOCKING_BAY_INFO_PANEL");
    docking_bay_info
        ->setSize(GuiElement::GuiSizeMax, 200.0f)
        ->setAttribute("layout", "horizontal");

    // Is there a better placeholder than my_spaceship?
    top_row_info = new GuiEntityInfoPanel(docking_bay_info, "", sp::ecs::Entity(), [](sp::ecs::Entity entity) {});
    top_row_info
        ->setSize(GuiEntityInfoPanel::default_panel_size, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "10, 0");

    GuiElement* top_row_kvs_1 = new GuiElement(docking_bay_info, "");
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

    GuiElement* top_row_kvs_2 = new GuiElement(docking_bay_info, "");
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
    for (size_t i = 0; i < bay->berths.size(); i++)
        berths_entities[i] = bay->berths[i].docked_entity;

    // Set entities (this triggers rebuild of panels)
    docking_bay_berths->setEntities(berths_entities);
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
        const string type_icon = bay->getTypeIcon(berth.type);
        const string type_name = bay->getTypeName(berth.type);

        // Number the panel and set berth type info
        const int idx = static_cast<int>(i);
        docking_bay_berths
            ->setCustomLabel(idx, 0, tr("Berth {i}").format({{"i", static_cast<string>(idx + 1)}}))
            ->setCustomIcon(idx, 1, type_icon)
            ->setCustomLabel(idx, 2, type_name);
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
        entity_energy->hide();
        entity_hull->hide();
        for (auto kv : entity_missiles) kv->hide();
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
