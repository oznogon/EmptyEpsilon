#include <algorithm>

#include <i18n.h>
#include "multiplayer_client.h"
#include "hangarView.h"
#include "playerInfo.h"
#include "spaceObjects/cpuShip.h"
#include "spaceObjects/playerSpaceship.h"

#include "gui/gui2_image.h"
#include "gui/gui2_scrolltext.h"

#include "screenComponents/rotatingModelView.h"

HangarViewComponent::HangarViewComponent(GuiContainer* owner)
: GuiElement(owner, "HANGAR_VIEW")
{
    item_list = new GuiListbox(
        this,
        "HANGAR_ITEM_LIST",
        [this](int index, string value)
        {
            int32_t id = std::stoul(value, nullptr, 10);

            if (game_server)
                selected_entry = game_server->getObjectById(id);
            else
                selected_entry = game_client->getObjectById(id);

            display();
        }
    );

    setAttribute("layout", "horizontal");

    item_list
        ->setMargins(20, 20, 20, 120)
        ->setSize(navigation_width, GuiElement::GuiSizeMax);

    display();
}

void HangarViewComponent::fillListBox()
{
    std::vector<string> docked_labels, docked_ids;

    if (game_server)
    {
        for (auto& object_id : my_spaceship->docked_object_ids)
        {
            P<ShipTemplateBasedObject> ship = game_server->getObjectById(object_id);
            if (ship)
            {
                string ship_label = ship->getTypeName() + " " + ship->getCallSign();
                docked_labels.push_back(ship_label);
                docked_ids.push_back(string(object_id));
            }
        }
    }
    else
    {
        for (auto& object_id : my_spaceship->docked_object_ids)
        {
            P<ShipTemplateBasedObject> ship = game_client->getObjectById(object_id);
            if (ship)
            {
                string ship_label = ship->getTypeName() + " " + ship->getCallSign();
                docked_labels.push_back(ship_label);
                docked_ids.push_back(string(object_id));
            }
        }
    }

    item_list->setOptions(docked_labels, docked_ids);
}

void HangarViewComponent::destroyContainers()
{
    if (keyvalue_left_container)
        keyvalue_container->destroy();
    if (keyvalue_right_container)
        keyvalue_container->destroy();
    if (keyvalue_container)
        keyvalue_container->destroy();
    if (controls_container)
        controls_container->destroy();
    if (selection_container)
        selection_container->destroy();
}

void HangarViewComponent::display()
{
    destroyContainers();

    /*
    +---------------------------------------+    +----------------------------------------+ 
    | (  SHIP  )  3d-model-view  ( undock ) |    | 3D-MODEL 3d-model 3d-model  ( undock ) |
    | (  ship  )  3d-model-view  ( energy ) |    | 3D-MODEL 3d-model 3d-model  ( energy ) |
    | (  ship  )  3d-model-view  ( repair ) |    | 3D-MODEL 3d-model 3d-model  ( repair ) |
    | (  ship  )  3d-model-view  ( weapon ) |    |                             ( weapon ) |
    | (  ship  )  3d-model-view  ( probes ) |    | 3d-model 3d-model 3d-model  ( probes ) |
    | (  ship  )                            | OR | 3d-model 3d-model 3d-model             |
    | (  ship  )  === k: v === === k: v === |    | 3d-model 3d-model 3d-model  == k: v == |
    | (  ship  )  === k: v === === k: v === |    |                             == k: v == |
    | (  ship  )  === k: v === === k: v === |    | 3d-model 3d-model 3d-model  == k: v == |
    | (  ship  )  === k: v === === k: v === |    | 3d-model 3d-model 3d-model  == k: v == |
    | (  ship  )  === k: v === === k: v === |    | 3d-model 3d-model 3d-model  == k: v == |
    +---------------------------------------+    +----------------------------------------+
    */

    selection_container = new GuiElement(this, "SELECTION_CONTAINER");
    selection_container
        ->setMargins(20)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    controls_container = new GuiElement(selection_container, "DETAILS_CONTAINER");
    controls_container
        ->setMargins(0)
        ->setSize(GuiElement::GuiSizeMax, 400)
        ->setAttribute("layout", "horizontal");

    keyvalue_container = new GuiElement(selection_container, "KEY_VALUE_CONTAINER");
    keyvalue_container
        ->setMargins(0)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");

    keyvalue_left_container = new GuiElement(keyvalue_container, "KEY_VALUE_LEFT_CONTAINER");
    keyvalue_left_container
        ->setMargins(0, 0, 10, 0)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    keyvalue_right_container = new GuiElement(keyvalue_container, "KEY_VALUE_RIGHT_CONTAINER");
    keyvalue_right_container
        ->setMargins(10, 0, 0, 0)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    if (!selected_entry)
        return;

    P<SpaceShip> selected_entry_spaceship = selected_entry;
    P<CpuShip> selected_entry_cpuship = selected_entry_spaceship;
    P<PlayerSpaceship> selected_entry_player = selected_entry_spaceship;

    // Details container (horizontal)
    // Model view
    selected_entry_model = new GuiRotatingModelView(
        controls_container,
        "HANGAR_VIEW_MODEL",
        selected_entry->ship_template->model_data
    );
    selected_entry_model
        ->setRotationRate(0.0f)
        ->rotateTo(90.0f)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Key/value container (vertical)
    // Key/value list
    selected_entry_dockstyle = new GuiKeyValueDisplay(
        keyvalue_left_container,
        "HANGAR_VIEW_SHIP_DOCKSTYLE",
        keyvalue_left_divider,
        tr("hangar_view", "Docked"),
        "-"
    );
    selected_entry_dockstyle
        ->setIcon("gui/icons/docking")
        ->setSize(GuiElement::GuiSizeMax, 40);

    if (selected_entry->getDockedStyle() == DockStyle::Internal)
        selected_entry_dockstyle->setValue(tr("hangar_view", "In hangar"));
    else
        selected_entry_dockstyle->setValue(tr("hangar_view", "At airlock"));

    launch_button = new GuiButton(
        selected_entry_dockstyle,
        "HANGAR_VIEW_LAUNCH_BUTTON",
        "LAUNCH",
        [selected_entry_cpuship, selected_entry_player, this]() {
            if (selected_entry_cpuship)
            {
                // Launch CpuShips to escort this ship by default.
                selected_entry_cpuship->orderDefendTarget(my_spaceship);
            }
            else if (selected_entry_player)
            {
                // Force players to undock.
                selected_entry_player->commandUndock();
            }
        }
    );
    launch_button
        ->setTextSize(20)
        ->setPosition(0, 6, sp::Alignment::TopRight)
        ->setSize(80, 28);

    // - Hull
    selected_entry_hull = new GuiKeyValueDisplay(
        keyvalue_left_container,
        "HANGAR_VIEW_SHIP_HULL",
        keyvalue_left_divider,
        tr("hangar_view", "Hull"),
        "-%"
    );
    selected_entry_hull
        ->setIcon("gui/icons/hull")
        ->setSize(GuiElement::GuiSizeMax, 40);

    // - Shields
    selected_entry_front_shield = new GuiKeyValueDisplay(
        keyvalue_left_container,
        "HANGAR_VIEW_SHIP_FRONT_SHIELD",
        keyvalue_left_divider,
        tr("hangar_view", "Front shields"),
        "-%"
    );
    selected_entry_front_shield
        ->setIcon("gui/icons/shields-fore")
        ->setSize(GuiElement::GuiSizeMax, 40);

    selected_entry_rear_shield = new GuiKeyValueDisplay(
        keyvalue_left_container,
        "HANGAR_VIEW_SHIP_REAR_SHIELD",
        keyvalue_left_divider,
        tr("hangar_view", "Rear shields"),
        "-%"
    );
    selected_entry_rear_shield
        ->setIcon("gui/icons/shields-aft")
        ->setSize(GuiElement::GuiSizeMax, 40);

    if (selected_entry_spaceship)
    {
        // - Systems status
        for (unsigned int n = 0; n < SYS_COUNT; n++)
        {
            selected_entry_systems[n] = new GuiKeyValueDisplay(
                keyvalue_right_container,
                "HANGAR_VIEW_SHIP_SYSTEM_" + getSystemName(ESystem(n)),
                keyvalue_right_divider,
                tr("hangar_view", "{system_name} system")
                    .format({{"system_name", getSystemName(ESystem(n))}}),
                "%"
            );
            selected_entry_systems[n]
                ->setSize(GuiElement::GuiSizeMax, 40)
                ->setVisible(false);
        }

        selected_entry_systems[SYS_Reactor]
            ->setIcon("gui/icons/system_reactor", sp::Alignment::CenterRight, 0.0f);
        selected_entry_systems[SYS_BeamWeapons]
            ->setIcon("gui/icons/system_beam", sp::Alignment::CenterRight, 0.0f);
        selected_entry_systems[SYS_MissileSystem]
            ->setIcon("gui/icons/system_missile", sp::Alignment::CenterRight, 0.0f);
        selected_entry_systems[SYS_Maneuver]
            ->setIcon("gui/icons/system_maneuver", sp::Alignment::CenterRight, 0.0f);
        selected_entry_systems[SYS_Impulse]
            ->setIcon("gui/icons/system_impulse", sp::Alignment::CenterRight, 0.0f);
        selected_entry_systems[SYS_Warp]
            ->setIcon("gui/icons/system_warpdrive", sp::Alignment::CenterRight, 0.0f);
        selected_entry_systems[SYS_JumpDrive]
            ->setIcon("gui/icons/system_jumpdrive", sp::Alignment::CenterRight, 0.0f);
        selected_entry_systems[SYS_FrontShield]
            ->setIcon("gui/icons/shields-fore", sp::Alignment::CenterRight, 0.0f);
        selected_entry_systems[SYS_RearShield]
            ->setIcon("gui/icons/shields-aft", sp::Alignment::CenterRight, 0.0f);

        // - Weapons storage
        for (unsigned int n = 0; n < MW_Count; n++)
        {
            selected_entry_weapons[n] = new GuiKeyValueDisplay(
                keyvalue_left_container,
                "HANGAR_VIEW_SHIP_WEAPON_" + getMissileWeaponName(EMissileWeapons(n)),
                keyvalue_left_divider,
                getLocaleMissileWeaponName(EMissileWeapons(n)),
                "-/-"
            );
            selected_entry_weapons[n]
                ->setSize(GuiElement::GuiSizeMax, 40)
                ->setVisible(false);
        }

        selected_entry_weapons[MW_Homing]->setIcon("gui/icons/weapon-homing.png");
        selected_entry_weapons[MW_Mine]->setIcon("gui/icons/weapon-mine.png");
        selected_entry_weapons[MW_EMP]->setIcon("gui/icons/weapon-emp.png");
        selected_entry_weapons[MW_Nuke]->setIcon("gui/icons/weapon-nuke.png");
        selected_entry_weapons[MW_HVLI]->setIcon("gui/icons/weapon-hvli.png");

        if (selected_entry_player)
        {
            // - Energy
            selected_entry_energy = new GuiKeyValueDisplay(
                keyvalue_left_container,
                "HANGAR_VIEW_SHIP_ENERGY",
                keyvalue_left_divider,
                tr("hangar_view", "Energy"),
                "-" // selected_entry->energy_level;
            );
            selected_entry_energy
                ->setIcon("gui/icons/energy")
                ->setSize(GuiElement::GuiSizeMax, 40);

            // - Repair crew
            selected_entry_repair_crew = new GuiKeyValueDisplay(
                keyvalue_left_container,
                "HANGAR_VIEW_REPAIR_CREWS",
                keyvalue_left_divider,
                tr("hangar_view", "Repair crews"),
                "-" // selected_entry->getRepairCrewCount();
            );
            selected_entry_repair_crew
                ->setIcon("gui/icons/system_health")
                ->setSize(GuiElement::GuiSizeMax, 40);

            // - Scan probes
            selected_entry_scan_probes = new GuiKeyValueDisplay(
                keyvalue_left_container,
                "HANGAR_VIEW_SCAN_PROBES",
                keyvalue_left_divider,
                tr("hangar_view", "Scan probes"),
                "-" // selected_entry->scan_probe_stock;
            );
            selected_entry_scan_probes
                ->setIcon("gui/icons/probe")
                ->setSize(GuiElement::GuiSizeMax, 40);
        }
    }
}

void HangarViewComponent::onDraw(sp::RenderTarget& window)
{
    if (selected_entry)
    {
        int32_t id = item_list->getSelectionValue().toInt();

        if (selected_entry->getMultiplayerId() != item_list->getSelectionValue().toInt())
        {
            // selected_entry doesn't match selected item's ID, so it's
            // no longer docked. If multiple ships are docked, the list
            // automatically selects the next ship down if one exists, so either
            // update the view with the new selection or wipe the view.
            if (item_list->getSelectionValue().toInt() > 0) {
                if (game_server)
                    selected_entry = game_server->getObjectById(id);
                else
                    selected_entry = game_client->getObjectById(id);
                display();
            }
            else
            {
                item_list->setSelectionIndex(-1);
                selected_entry = nullptr;
                display();
                return;
            }
        }

        P<SpaceShip> selected_entry_spaceship = selected_entry;
        P<PlayerSpaceship> selected_entry_player = selected_entry_spaceship;

        // - Hull
        selected_entry_hull->setValue(
            string(100.0f * selected_entry->hull_strength / selected_entry->hull_max, 0)
            + "%"
        );
        // - Shield segments
        selected_entry_front_shield->setValue(
            string(selected_entry->getShieldPercentage(0))
            + "%"
        );
        selected_entry_rear_shield->setValue(
            string(selected_entry->getShieldPercentage(1))
            + "%"
        );

        if (selected_entry_spaceship)
        {
            selected_entry_front_shield->setVisible(selected_entry_spaceship->hasSystem(SYS_FrontShield));
            selected_entry_rear_shield->setVisible(selected_entry_spaceship->hasSystem(SYS_RearShield));

            // - Systems damage
            //   Copied from damcon
            for (unsigned int n = 0; n < SYS_COUNT; n++)
            {
                selected_entry_systems[n]->setVisible(selected_entry_spaceship->hasSystem(ESystem(n)));
                selected_entry_systems[n]->setValue(
                    string(int(selected_entry_spaceship->systems[n].health * 100))
                    + "%"
                );

                if (selected_entry_spaceship->systems[n].health < 0)
                    selected_entry_systems[n]->setColor(glm::u8vec4(255, 0, 0, 255));
                else if (selected_entry_spaceship->systems[n].health_max < 1.0f)
                    selected_entry_systems[n]->setColor(glm::u8vec4(255, 255, 0, 255));
                else
                    selected_entry_systems[n]->setColor(glm::u8vec4(255, 255, 255, 255));
            }

            // - Weapons storage
            for (unsigned int n = 0; n < MW_Count; n++)
            {
                if (selected_entry_spaceship->weapon_storage_max[n] > 0)
                {
                    selected_entry_weapons[n]->setVisible(true);
                    selected_entry_weapons[n]->setValue(
                        string(selected_entry_spaceship->weapon_storage[n])
                        + "/"
                        + string(selected_entry_spaceship->weapon_storage_max[n])
                    );
                }
                else
                {
                    selected_entry_weapons[n]->setVisible(false);
                }
            }

            if (selected_entry_player)
            {
                // - Energy
                selected_entry_energy->setValue(string(selected_entry_player->energy_level, 0));
                // - Repair crew
                selected_entry_repair_crew->setValue(string(selected_entry_player->getRepairCrewCount()));
                // - Scan probes
                selected_entry_scan_probes->setValue(
                    string(selected_entry_player->getScanProbeCount())
                    + "/"
                    + string(selected_entry_player->getMaxScanProbeCount())
                );
            }
        }
    }
    else
    {
        // There's no selected STBO; destroying the containers might be overkill.
        destroyContainers();
    }

    fillListBox();
}
