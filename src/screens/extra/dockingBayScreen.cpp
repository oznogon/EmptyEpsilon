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
        ->setSize(250.0f, GuiElement::GuiSizeMax)
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

    GuiElement* top_row = new GuiElement(docking_bay_info, "");
    top_row
        ->setSize(GuiElement::GuiSizeMax, 200.0f)
        ->setAttribute("layout", "horizontal");
    GuiElement* bottom_row = new GuiElement(docking_bay_info, "");
    bottom_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");

    // Top row; is there a better placeholder than my_spaceship?
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

    entity_homing = new GuiKeyValueDisplay(top_row_kvs_2, "", kv_split, getLocaleMissileWeaponName(MW_Homing), "");
    entity_homing
        ->setIcon("gui/icons/weapon-homing")
        ->setSize(GuiElement::GuiSizeMax, kv_size)
        ->hide();
    entity_nuke = new GuiKeyValueDisplay(top_row_kvs_2, "", kv_split, getLocaleMissileWeaponName(MW_Nuke), "");
    entity_nuke
        ->setIcon("gui/icons/weapon-nuke")
        ->setSize(GuiElement::GuiSizeMax, kv_size)
        ->hide();
    entity_emp = new GuiKeyValueDisplay(top_row_kvs_2, "", kv_split, getLocaleMissileWeaponName(MW_EMP), "");
    entity_emp
        ->setIcon("gui/icons/weapon-emp")
        ->setSize(GuiElement::GuiSizeMax, kv_size)
        ->hide();
    entity_hvli = new GuiKeyValueDisplay(top_row_kvs_2, "", kv_split, getLocaleMissileWeaponName(MW_HVLI), "");
    entity_hvli
        ->setIcon("gui/icons/weapon-hvli")
        ->setSize(GuiElement::GuiSizeMax, kv_size)
        ->hide();
    entity_mine = new GuiKeyValueDisplay(top_row_kvs_2, "", kv_split, getLocaleMissileWeaponName(MW_Mine), "");
    entity_mine
        ->setIcon("gui/icons/weapon-mine")
        ->setSize(GuiElement::GuiSizeMax, kv_size)
        ->hide();

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

    // GuiEntityInfoPanelGrid will handle this efficiently now
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
        updateMissileDisplay(entity_homing, tubes, MW_Homing);
        updateMissileDisplay(entity_nuke, tubes, MW_Nuke);
        updateMissileDisplay(entity_emp, tubes, MW_EMP);
        updateMissileDisplay(entity_hvli, tubes, MW_HVLI);
        updateMissileDisplay(entity_mine, tubes, MW_Mine);
    }
    else
    {
        entity_homing->hide();
        entity_nuke->hide();
        entity_emp->hide();
        entity_hvli->hide();
        entity_mine->hide();
    }
}

void DockingBayScreen::updateMissileDisplay(GuiKeyValueDisplay* display,
                                            MissileTubes* tubes,
                                            EMissileWeapons type)
{
    // LOG(Info, "In updateMissileDisplay");
    if (tubes->storage_max[type] > 0)
    {
        display
            ->setValue(static_cast<string>(tubes->storage[type]) + "/" +
                      static_cast<string>(tubes->storage_max[type]))
            ->show();
    }
    else display->hide();
}
