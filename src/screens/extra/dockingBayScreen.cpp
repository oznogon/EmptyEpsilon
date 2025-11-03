#include "dockingBayScreen.h"
#include "i18n.h"

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
: GuiOverlay(owner, "DOCKING_BAY_SCREEN", colorConfig.background)
{
    const float kv_size = 40.0f;
    const float kv_split = 0.5f;

    // Layout elements
    GuiElement* layout = new GuiElement(this, "DOCKING_BAY_LAYOUT");
    layout
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");
    layout->setAttribute("padding", "20");

    left_column = new GuiElement(layout, "DOCKING_BAY_LEFT_COLUMN");
    left_column
        ->setSize(200.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    left_column
        ->setAttribute("margin", "0, 10, 0, 0");

    right_column = new GuiElement(layout, "DOCKING_BAY_RIGHT_COLUMN");
    right_column
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Left column: Docking bay controls
    docking_bay_controls = new GuiListbox(left_column, "DOCKING_BAY_CONTROLS",
        [](int index, string value)
        {
            LOG(Info, "docking_bay_controls index ", index, ", value ", value);
        }
    );
    docking_bay_controls->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->hide();

    docking_bay_ships = new GuiEntityInfoPanelGrid(left_column, "DOCKING_BAY_SHIPS", entities,
    [this](sp::ecs::Entity entity)
    {
        LOG(Info, "docking_bay_ships ", entity.toString());
        if (entity)
        {
            // DockingSystem::requestUndock(entity);
            docking_bay_info->show();
            top_row_info->setEntity(entity);
        }
    }
    );
    docking_bay_ships
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

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
        ->setSize(200.0f, GuiElement::GuiSizeMax)
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
        ->setSize(GuiElement::GuiSizeMax, kv_size);
    entity_nuke = new GuiKeyValueDisplay(top_row_kvs_2, "", kv_split, getLocaleMissileWeaponName(MW_Nuke), "");
    entity_nuke
        ->setIcon("gui/icons/weapon-nuke")
        ->setSize(GuiElement::GuiSizeMax, kv_size);
    entity_emp = new GuiKeyValueDisplay(top_row_kvs_2, "", kv_split, getLocaleMissileWeaponName(MW_EMP), "");
    entity_emp
        ->setIcon("gui/icons/weapon-emp")
        ->setSize(GuiElement::GuiSizeMax, kv_size);
    entity_hvli = new GuiKeyValueDisplay(top_row_kvs_2, "", kv_split, getLocaleMissileWeaponName(MW_HVLI), "");
    entity_hvli
        ->setIcon("gui/icons/weapon-hvli")
        ->setSize(GuiElement::GuiSizeMax, kv_size);
    entity_mine = new GuiKeyValueDisplay(top_row_kvs_2, "", kv_split, getLocaleMissileWeaponName(MW_Mine), "");
    entity_mine
        ->setIcon("gui/icons/weapon-mine")
        ->setSize(GuiElement::GuiSizeMax, kv_size);

    // Custom ship functions
    /*
    (new GuiCustomShipFunctions(this, CrewPosition::dockingBay, "DOCKING_BAY_CSF"))
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax);
    */
}

void DockingBayScreen::onDraw(sp::RenderTarget& target)
{
}

void DockingBayScreen::onUpdate()
{
    if (!my_spaceship) return;

    if (auto bay = my_spaceship.getComponent<DockingBay>())
    {
        auto docked_entities = bay->docked_entities;

        docking_bay_ships->children.clear();

        if (!docked_entities.empty())
        {
            std::vector<string> docked_entities_str;

            for (auto docked_entity: docked_entities)
            {
                docked_entities_str.emplace_back(docked_entity.toString());
                if (docking_bay_info->isVisible() && docked_entity == top_row_info->getEntity())
                {
                    auto reactor = docked_entity.getComponent<Reactor>();
                    if (reactor)
                    {
                        entity_energy->setValue(static_cast<string>("{energy}/{max_energy}").format({
                            {"energy", static_cast<int>(reactor->energy)},
                            {"max_energy", static_cast<int>(reactor->max_energy)}
                        }));
                    }

                    auto hull = docked_entity.getComponent<Hull>();
                    if (hull)
                    {
                        entity_hull->setValue(static_cast<string>("{hull}%").format({
                            {"hull", static_cast<int>((hull->current / hull->max) * 100.0f)}
                        }));
                    }

                    auto tubes = docked_entity.getComponent<MissileTubes>();
                    if (tubes->storage_max[MW_Homing] > 0)
                    {
                        entity_homing
                            ->setValue(static_cast<string>(tubes->storage[MW_Homing]) + "/" + static_cast<string>(tubes->storage_max[MW_Homing]))
                            ->show();
                    }
                    else entity_homing->hide();

                    if (tubes->storage_max[MW_Nuke] > 0)
                    {
                        entity_nuke
                            ->setValue(static_cast<string>(tubes->storage[MW_Nuke]) + "/" + static_cast<string>(tubes->storage_max[MW_Nuke]))
                            ->show();
                    }
                    else entity_nuke->hide();

                    if (tubes->storage_max[MW_EMP] > 0)
                    {
                        entity_emp
                            ->setValue(static_cast<string>(tubes->storage[MW_EMP]) + "/" + static_cast<string>(tubes->storage_max[MW_EMP]))
                            ->show();
                    }
                    else entity_emp->hide();

                    if (tubes->storage_max[MW_HVLI] > 0)
                    {
                        entity_hvli
                            ->setValue(static_cast<string>(tubes->storage[MW_HVLI]) + "/" + static_cast<string>(tubes->storage_max[MW_HVLI]))
                            ->show();
                    }
                    else entity_hvli->hide();

                    if (tubes->storage_max[MW_Mine] > 0)
                    {
                        entity_mine
                            ->setValue(static_cast<string>(tubes->storage[MW_Mine]) + "/" + static_cast<string>(tubes->storage_max[MW_Mine]))
                            ->show();
                    }
                    else entity_mine->hide();
                }
            }

            docking_bay_ships->setEntities(docked_entities);
        }
        else
        {
            docking_bay_ships->setEntities({});
        }
    }
}
