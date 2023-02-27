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
    P<ShipTemplateBasedObject> docked_object = nullptr;

    for (auto& object_id : my_spaceship->docked_object_ids)
    {
        if (game_server)
            docked_object = game_server->getObjectById(object_id);
        else
            docked_object = game_client->getObjectById(object_id);

        if (docked_object)
        {
            docked_labels.push_back(
                docked_object->getTypeName()
                + " "
                + docked_object->getCallSign()
            );
            docked_ids.push_back(string(object_id));
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

    selection_container = new GuiElement(this, "HANGAR_VIEW_SELECTION_CONTAINER");
    selection_container
        ->setMargins(20)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    controls_container = new GuiElement(selection_container, "HANGAR_VIEW_CONTROLS_CONTAINER");
    controls_container
        ->setMargins(0)
        ->setSize(GuiElement::GuiSizeMax, 300)
        ->setAttribute("layout", "horizontal");

    keyvalue_container = new GuiElement(selection_container, "HANGAR_VIEW_KEY_VALUE_CONTAINER");
    keyvalue_container
        ->setMargins(0)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");

    keyvalue_left_container = new GuiElement(keyvalue_container, "HANGAR_VIEW_KEY_VALUE_LEFT_CONTAINER");
    keyvalue_left_container
        ->setMargins(0, 0, 10, 0)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    keyvalue_right_container = new GuiElement(keyvalue_container, "HANGAR_VIEW_KEY_VALUE_RIGHT_CONTAINER");
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
                // Launch CpuShips to escort this ship by default.
                selected_entry_cpuship->orderDefendTarget(my_spaceship);
            else if (selected_entry_player)
                // Force players to undock.
                selected_entry_player->commandUndock();
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
        ->setVisible(false)
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
        ->setVisible(false)
        ->setSize(GuiElement::GuiSizeMax, 40);

    if (selected_entry_spaceship)
    {
        // - Systems status
        for (unsigned int n = 0; n < SYS_COUNT; n++)
        {
            string icon_name;

            switch (ESystem(n))
            {
            case SYS_Reactor:
                icon_name = "gui/icons/system_reactor";
                break;
            case SYS_BeamWeapons:
                icon_name = "gui/icons/system_beam";
                break;
            case SYS_MissileSystem:
                icon_name = "gui/icons/system_missile";
                break;
            case SYS_Maneuver:
                icon_name = "gui/icons/system_maneuver";
                break;
            case SYS_Impulse:
                icon_name = "gui/icons/system_impulse";
                break;
            case SYS_Warp:
                icon_name = "gui/icons/system_warpdrive";
                break;
            case SYS_JumpDrive:
                icon_name = "gui/icons/system_jumpdrive";
                break;
            case SYS_FrontShield:
                icon_name = "gui/icons/shields-fore";
                break;
            case SYS_RearShield:
                icon_name = "gui/icons/shields-aft";
                break;
            default:
                icon_name = "";
            }

            selected_entry_systems[n] = new GuiKeyValueDisplay(
                keyvalue_right_container,
                "HANGAR_VIEW_SHIP_SYSTEM_" + getSystemName(ESystem(n)),
                keyvalue_right_divider,
                tr("hangar_view", "{system_name} system")
                    .format({{"system_name", getSystemName(ESystem(n))}}),
                "%"
            );
            selected_entry_systems[n]
                ->setIcon(
                    icon_name,
                    sp::Alignment::CenterRight,
                    0.0f
                )
                ->setSize(GuiElement::GuiSizeMax, 40)
                ->setVisible(false);
        }

        // - Weapons storage
        for (unsigned int n = 0; n < MW_Count; n++)
        {
            string icon_name;

            switch (EMissileWeapons(n))
            {
            case MW_Homing:
                icon_name = "gui/icons/weapon-homing.png";
                break;
            case MW_Mine:
                icon_name = "gui/icons/weapon-mine.png";
                break;
            case MW_EMP:
                icon_name = "gui/icons/weapon-emp.png";
                break;
            case MW_Nuke:
                icon_name = "gui/icons/weapon-nuke.png";
                break;
            case MW_HVLI:
                icon_name = "gui/icons/weapon-hvli.png";
                break;
            default:
                icon_name = "";
            }

            selected_entry_weapons[n] = new GuiKeyValueDisplay(
                keyvalue_left_container,
                "HANGAR_VIEW_SHIP_WEAPON_" + getMissileWeaponName(EMissileWeapons(n)),
                keyvalue_left_divider,
                getLocaleMissileWeaponName(EMissileWeapons(n)),
                "-/-"
            );
            selected_entry_weapons[n]
                ->setIcon(icon_name)
                ->setSize(GuiElement::GuiSizeMax, 40)
                ->setVisible(false);
        }

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
        // If the list changes, the selected_entry state doesn't, so check and
        // if necessary update the entry to match the list's current selection.
        int32_t id = item_list->getSelectionValue().toInt();

        if (selected_entry->getMultiplayerId() != item_list->getSelectionValue().toInt())
        {
            // If selected_entry doesn't match selected item's ID, it's no
            // longer docked. If another ship is docked, the list automatically
            // selects the next ship down if one exists, so either update the
            // view with the new selection, or wipe the view.
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

        // Update object traits
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
            // - Shield segments (cont.)
            //   Only SpaceShips have separate systems, so if shield systems
            //   have been removed, remove their k/v entries.
            selected_entry_front_shield
                ->setVisible(selected_entry_spaceship->hasSystem(SYS_FrontShield));
            selected_entry_rear_shield
                ->setVisible(selected_entry_spaceship->hasSystem(SYS_RearShield));

            // - Systems damage (Copied from damcon)
            for (unsigned int n = 0; n < SYS_COUNT; n++)
            {
                if (selected_entry_spaceship->hasSystem(ESystem(n)))
                {
                    const int selected_entry_system_health =
                        int(selected_entry_spaceship->systems[n].health * 100.0f);

                    selected_entry_systems[n]
                        ->setValue(string(selected_entry_system_health) + "%")
                        ->setVisible(true);

                    // Color damaged systems
                    if (selected_entry_system_health < 0)
                    {
                        selected_entry_systems[n]->setColor(glm::u8vec4(255, 0, 0, 255));
                    }
                    else if (selected_entry_system_health < 100)
                    {
                        LOG(INFO) << "I should be yellow but I'm not";
                        selected_entry_systems[n]->setColor(glm::u8vec4(255, 255, 0, 255));
                    }
                    else
                    {
                        selected_entry_systems[n]->setColor(glm::u8vec4(255, 255, 255, 255));
                    }
                }
                else
                {
                    // If the system's been removed, hide its k/v entry.
                    selected_entry_systems[n]->setVisible(false);
                }
            }

            // - Weapons storage
            for (unsigned int n = 0; n < MW_Count; n++)
            {
                // Show and update only weapons with a storage capacity.
                if (selected_entry_spaceship->weapon_storage_max[n] > 0)
                {
                    selected_entry_weapons[n]
                        ->setValue(
                            string(selected_entry_spaceship->weapon_storage[n])
                            + "/"
                            + string(selected_entry_spaceship->weapon_storage_max[n])
                        )
                        ->setVisible(true);
                }
                else
                {
                    selected_entry_weapons[n]->setVisible(false);
                }

                // Color based on count
                if (selected_entry_spaceship->weapon_storage[n] == 0)
                    selected_entry_weapons[n]->setColor(glm::u8vec4(255, 0, 0, 255));
                else if (selected_entry_spaceship->weapon_storage[n] < selected_entry_spaceship->weapon_storage_max[n])
                    selected_entry_weapons[n]->setColor(glm::u8vec4(255, 255, 0, 255));
                else
                    selected_entry_weapons[n]->setColor(glm::u8vec4(255, 255, 255, 255));
            }

            if (selected_entry_player)
            {
                // - Energy
                selected_entry_energy
                    ->setValue(string(selected_entry_player->energy_level, 0));

                // - Repair crew
                selected_entry_repair_crew
                    ->setValue(string(selected_entry_player->getRepairCrewCount()));

                // - Scan probes
                selected_entry_scan_probes
                    ->setValue(
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
