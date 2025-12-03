#include "dockingBayScreen.h"
#include "i18n.h"

#include "gui/gui2_arrow.h"
#include "gui/gui2_arrowbutton.h"
#include "gui/gui2_button.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"
#include "gui/gui2_progressbar.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_slider.h"
#include "gui/gui2_togglebutton.h"

#include "screenComponents/alertOverlay.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/entityInfoPanel.h"

#include "components/coolant.h"
#include "components/docking.h"
#include "components/hull.h"
#include "components/missiletubes.h"
#include "components/name.h"
#include "components/probe.h"
#include "components/reactor.h"

#include "systems/docking.h"

static string toNearbyIntString(float value)
{
    return static_cast<string>(static_cast<int>(nearbyint(value)));
}

DockingBayScreen::DockingBayScreen(GuiContainer* owner)
: GuiOverlay(owner, "DOCKING_BAY_SCREEN", colorConfig.background),
  selected_entity(sp::ecs::Entity())
{
    // Render the background decorations.
    (new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255,255,255,255}))->setTextureTiled("gui/background/crosses.png");

    // Render the alert level color overlay.
    (new AlertLevelOverlay(this));

    // Exit if we don't have a docking bay.
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
    GuiElement* top_row = new GuiElement(right_column, "");
    top_row
        ->setSize(GuiElement::GuiSizeMax, 260.0f)
        ->setAttribute("layout", "horizontal");
    top_row
        ->setAttribute("margin", "0, 10, 0, 10");

    GuiElement* docking_bay_info_layout = new GuiElement(top_row, "DOCKING_BAY_INFO_LAYOUT");
    docking_bay_info_layout
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    (new GuiElement(top_row, "SPACER"))->setSize(250.0f, GuiElement::GuiSizeMax);

    (new GuiLabel(docking_bay_info_layout, "DOCKING_BAY_INFO_LABEL", tr("Selected berth"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    docking_bay_info = new GuiElement(docking_bay_info_layout, "DOCKING_BAY_INFO_PANEL");
    docking_bay_info
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");

    selected_entity_info = new GuiEntityInfoPanel(docking_bay_info, "", sp::ecs::Entity(), [](sp::ecs::Entity entity) {});
    selected_entity_info
        ->setSize(GuiEntityInfoPanel::default_panel_size, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "0, 10, 0, 0");

    GuiElement* selected_entity_kvs_1 = new GuiElement(docking_bay_info, "");
    selected_entity_kvs_1
        ->setSize(200.0f, 200.0f)
        ->setAttribute("layout", "vertical");
    selected_entity_kvs_1
        ->setAttribute("margin", "0, 10, 0, 0");

    for (int i = MW_Homing; i < MW_Count; i++)
    {
        entity_missiles[i] = new GuiKeyValueDisplay(selected_entity_kvs_1, "", kv_split, getLocaleMissileWeaponName(static_cast<EMissileWeapons>(i)), "");
        entity_missiles[i]->setSize(GuiElement::GuiSizeMax, kv_size);
    }

    entity_missiles[MW_Homing]->setIcon("gui/icons/weapon-homing");
    entity_missiles[MW_Nuke]->setIcon("gui/icons/weapon-nuke");
    entity_missiles[MW_EMP]->setIcon("gui/icons/weapon-emp");
    entity_missiles[MW_HVLI]->setIcon("gui/icons/weapon-hvli");
    entity_missiles[MW_Mine]->setIcon("gui/icons/weapon-mine");

    GuiElement* selected_entity_kvs_2 = new GuiElement(docking_bay_info, "");
    selected_entity_kvs_2
        ->setSize(200.0f, 200.0f)
        ->setAttribute("layout", "vertical");

    entity_energy = new GuiKeyValueDisplay(selected_entity_kvs_2, "", kv_split, tr("dockingbay", "Energy"), "");
    entity_energy
        ->setIcon("gui/icons/energy")
        ->setSize(GuiElement::GuiSizeMax, kv_size);
    entity_hull = new GuiKeyValueDisplay(selected_entity_kvs_2, "", kv_split, tr("dockingbay", "Hull"), "");
    entity_hull
        ->setIcon("gui/icons/hull")
        ->setSize(GuiElement::GuiSizeMax, kv_size);

    // Right column, bottom row
    (new GuiLabel(right_column, "DOCKING_BAY_BERTH_LABEL", tr("Berth operations"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    // Controls to move ships between berths.
    GuiElement* move_controls_row = new GuiElement(right_column, "DOCKING_BAY_MOVE_CONTROLS");
    move_controls_row
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("layout", "horizontal");
    move_controls_row
        ->setAttribute("margin", "0, 0, 0, 10");

    (new GuiButton(move_controls_row, "", tr("dockingbay", "Move to:"),
        [this]()
        {
            if (selected_entity && selected_entity != sp::ecs::Entity() && my_player_info)
                my_player_info->commandMoveInternalToBerth(selected_entity, target_berth->getSelectionValue().toInt());
        }
    ))->setSize(150.0f, 50.0f);

    target_berth = new GuiSelector(move_controls_row, "", [](int index, string value) {} );
    target_berth
        ->setSize(250.0f, GuiElement::GuiSizeMax);

    (new GuiElement(move_controls_row, "SPACER"))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    energy_carrier = new GuiKeyValueDisplay(move_controls_row, "", kv_split, tr("dockingbay", "Carrier"), "");
    energy_carrier
        ->setIcon("gui/icons/energy")
        ->setSize(200.0f, kv_size)
        ->setAttribute("alignment", "center");

    (new GuiElement(move_controls_row, "SPACER"))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Scramble button launches all ships in all hangar berths.
    // As an emergency control, it should always be visible.
    scramble = new GuiToggleButton(move_controls_row, "DOCKING_BAY_SCRAMBLE", tr("dockingbay", "Scramble hangars"),
        [this](bool value)
        {
            if (!value)
            {
                scramble->setText(tr("dockingbay", "Scramble hangars"));
                if (!my_spaceship || !my_player_info) return;

                if (auto bay = my_spaceship.getComponent<DockingBay>())
                {
                    // Undock all entities from hangar berths
                    for (auto& berth : bay->berths)
                    {
                        if (berth.docked_entity && berth.docked_entity != sp::ecs::Entity() && berth.type == DockingBay::Berth::Type::Hangar)
                            my_player_info->commandLaunchInternal(berth.docked_entity);
                    }
                }
            }
            else
                scramble->setText(tr("dockingbay", "Confirm scramble"));
        }
    );
    scramble
        ->setStyle("button.dockingbay_scramble")
        ->setSize(220.0f, 50.0f);

    // Hangar-specific berth controls.
    hangar_controls = new GuiElement(right_column, "DOCKING_BAY_HANGAR_CONTROLS");
    hangar_controls
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    (new GuiLabel(hangar_controls, "DOCKING_BAY_HANGAR_LABEL", tr("dockingbay", "Hangar operations"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    GuiElement* undock_controls_row = new GuiElement(hangar_controls, "DOCKING_BAY_UNDOCK_CONTROLS");
    undock_controls_row
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("layout", "horizontal");

    (new GuiButton(undock_controls_row, "", tr("dockingbay", "Launch"),
        [this]()
        {
            if (selected_entity && selected_entity != sp::ecs::Entity() && my_player_info)
                my_player_info->commandLaunchInternal(selected_entity);
        }
    ))->setIcon("gui/icons/docking")
        ->setSize(150.0f, 50.0f);

    // TODO: "Approve docking" to detect internally dockable ships within 1U, select from them, and compel docking

    // Energy-specific berth controls.
    energy_controls = new GuiElement(right_column, "DOCKING_BAY_ENERGY_CONTROLS");
    energy_controls
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    (new GuiLabel(energy_controls, "DOCKING_BAY_ENERGY_OPERATIONS_LABEL", tr("dockingbay", "Energy operations"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    GuiElement* energy_transfer_row = new GuiElement(energy_controls, "DOCKING_BAY_ENERGY_TRANSFER_CONTROLS");
    energy_transfer_row
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("layout", "horizontal");

    (new GuiLabel(energy_transfer_row, "DOCKING_BAY_ENERGY_TRANSFER_LABEL", tr("dockingbay", "Transfer energy:"), 30.0f))
        ->setAlignment(sp::Alignment::CenterRight)
        ->setSize(GuiElement::GuiSizeMax, 50.0f);

    energy_transfer_direction = new GuiSlider(energy_transfer_row, "DOCKING_BAY_ENERGY_SLIDER",
        static_cast<float>(DockingBay::Berth::TransferDirection::ToCarrier),
        static_cast<float>(DockingBay::Berth::TransferDirection::ToDocked),
        static_cast<float>(DockingBay::Berth::TransferDirection::None),
        [this](float value)
        {
            LOG(Debug, "Energy transferring ", value > 0 ? "to docked entity" : value < 0 ? "to carrier entity" : "inactive");
            if (!my_spaceship || !my_player_info) return;

            if (auto bay = my_spaceship.getComponent<DockingBay>())
            {
                if (selected_berth_index >= 0 && selected_berth_index < static_cast<int>(bay->berths.size()))
                    my_player_info->commandSetBerthTransferDirection(selected_berth_index, static_cast<int>(value));
            }
        }
    );
    energy_transfer_direction
        ->addSnapValue(static_cast<float>(DockingBay::Berth::TransferDirection::ToCarrier), 0.75f)
        ->addSnapValue(static_cast<float>(DockingBay::Berth::TransferDirection::None), 0.5f)
        ->addSnapValue(static_cast<float>(DockingBay::Berth::TransferDirection::ToDocked), 0.75f)
        ->setSize(400.0f, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "10, 0");

    (new GuiElement(energy_transfer_row, "SPACER"))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    GuiElement* energy_transfer_labels_row = new GuiElement(energy_controls, "DOCKING_BAY_ENERGY_TRANSFER_LABELS");
    energy_transfer_labels_row
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("layout", "horizontal");

    (new GuiElement(energy_transfer_labels_row, "SPACER"))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    (new GuiLabel(energy_transfer_labels_row, "", tr("dockingbay", "to carrier"), 20.0f))
        ->setAlignment(sp::Alignment::CenterLeft)
        ->setSize(150.0f, GuiElement::GuiSizeMax);

    (new GuiLabel(energy_transfer_labels_row, "", tr("dockingbay", "none"), 20.0f))
        ->setAlignment(sp::Alignment::Center)
        ->setSize(100.0f, GuiElement::GuiSizeMax);

    (new GuiLabel(energy_transfer_labels_row, "", tr("dockingbay", "to berth"), 20.0f))
        ->setAlignment(sp::Alignment::CenterRight)
        ->setSize(150.0f, GuiElement::GuiSizeMax);

    (new GuiElement(energy_transfer_labels_row, "SPACER"))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Thermal-specific berth controls.
    thermal_controls = new GuiElement(right_column, "DOCKING_BAY_THERMAL_CONTROLS");
    thermal_controls
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    (new GuiLabel(thermal_controls, "DOCKING_BAY_THERMAL_LABEL", tr("dockingbay", "Thermal operations"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    GuiElement* vent_controls_row = new GuiElement(thermal_controls, "DOCKING_BAY_VENT_CONTROLS");
    vent_controls_row
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("layout", "horizontal");

    (new GuiLabel(vent_controls_row, "DOCKING_BAY_VENT_LABEL", tr("dockingbay", "Vent heat:"), 30.0f))
        ->setAlignment(sp::Alignment::CenterRight)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    thermal_venting_direction = new GuiSlider(vent_controls_row, "DOCKING_BAY_VENT_SLIDER",
        static_cast<float>(DockingBay::Berth::TransferDirection::ToCarrier),
        static_cast<float>(DockingBay::Berth::TransferDirection::ToDocked),
        static_cast<float>(DockingBay::Berth::TransferDirection::None),
        [this](float value)
        {
            if (!my_spaceship || !my_player_info) return;

            if (auto bay = my_spaceship.getComponent<DockingBay>())
            {
                if (selected_berth_index >= 0 && selected_berth_index < static_cast<int>(bay->berths.size()))
                    my_player_info->commandSetBerthTransferDirection(selected_berth_index, static_cast<int>(value));
            }
        }
    );
    thermal_venting_direction
        ->addSnapValue(static_cast<float>(DockingBay::Berth::TransferDirection::ToCarrier), 0.75f)
        ->addSnapValue(static_cast<float>(DockingBay::Berth::TransferDirection::None), 0.5f)
        ->addSnapValue(static_cast<float>(DockingBay::Berth::TransferDirection::ToDocked), 0.75f)
        ->setSize(400.0f, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "10, 0");

    (new GuiElement(vent_controls_row, "SPACER"))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    GuiElement* thermal_venting_labels_row = new GuiElement(thermal_controls, "DOCKING_BAY_HEAT_TRANSFER_LABELS");
    thermal_venting_labels_row
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("layout", "horizontal");

    (new GuiElement(thermal_venting_labels_row, "SPACER"))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    (new GuiLabel(thermal_venting_labels_row, "", tr("dockingbay", "to carrier"), 20.0f))
        ->setAlignment(sp::Alignment::CenterLeft)
        ->setSize(150.0f, GuiElement::GuiSizeMax);

    (new GuiLabel(thermal_venting_labels_row, "", tr("dockingbay", "none"), 20.0f))
        ->setAlignment(sp::Alignment::Center)
        ->setSize(100.0f, GuiElement::GuiSizeMax);

    (new GuiLabel(thermal_venting_labels_row, "", tr("dockingbay", "to berth"), 20.0f))
        ->setAlignment(sp::Alignment::CenterRight)
        ->setSize(150.0f, GuiElement::GuiSizeMax);

    (new GuiElement(thermal_venting_labels_row, "SPACER"))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    heat_gauges_row = new GuiElement(thermal_controls, "THERMAL_HEAT_GAUGES");
    heat_gauges_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");

    GuiElement* heat_gauges_left = new GuiElement(heat_gauges_row, "THERMAL_HEAT_GAUGES_LEFT");
    heat_gauges_left
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "0, 10, 0, 0");
    heat_gauges_left
        ->setAttribute("layout", "vertical");

    GuiElement* heat_gauges_right = new GuiElement(heat_gauges_row, "THERMAL_HEAT_GAUGES_RIGHT");
    heat_gauges_right
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "10, 0, 0, 0");
    heat_gauges_right
        ->setAttribute("layout", "vertical");

    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        // TODO: DRY with repair
        string id = "THERMAL_SYSTEM_ROW_" + getSystemName(ShipSystem::Type(n));
        SystemRow info;

        info.row = new GuiElement(n < ShipSystem::COUNT / 2 ? heat_gauges_left : heat_gauges_right, id);
        info.row
            ->setSize(GuiElement::GuiSizeMax, kv_size)
            ->hide()
            ->setAttribute("layout", "horizontal");

        info.label = new GuiKeyValueDisplay(info.row, id + "_LABEL", 0.175f, "", getLocaleSystemName(ShipSystem::Type(n)));
        info.label
            ->setSize(250.0f, GuiElement::GuiSizeMax);

        info.heat_bar = new GuiProgressbar(info.row, id + "_HEAT", 0.0f, 1.0f, 0.0f);
        info.heat_bar->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        info.heat_arrow = new GuiArrow(info.heat_bar, id + "_HEAT_ARROW", 0.0f);
        info.heat_arrow->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        info.heat_icon = new GuiImage(info.heat_bar, "", "gui/icons/status_overheat");
        info.heat_icon
            ->setColor(colorConfig.overlay_overheating)
            ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
            ->setSize(GuiElement::GuiSizeMatchHeight, GuiElement::GuiSizeMax);

        thermal_rows.push_back(info);
    }

    auto setSystemRowIcons = [](std::vector<SystemRow>& system_rows)
    {
        system_rows[int(ShipSystem::Type::Reactor)].label->setIcon("gui/icons/system_reactor");
        system_rows[int(ShipSystem::Type::BeamWeapons)].label->setIcon("gui/icons/system_beam");
        system_rows[int(ShipSystem::Type::MissileSystem)].label->setIcon("gui/icons/system_missile");
        system_rows[int(ShipSystem::Type::Maneuver)].label->setIcon("gui/icons/system_maneuver");
        system_rows[int(ShipSystem::Type::Impulse)].label->setIcon("gui/icons/system_impulse");
        system_rows[int(ShipSystem::Type::Warp)].label->setIcon("gui/icons/system_warpdrive");
        system_rows[int(ShipSystem::Type::JumpDrive)].label->setIcon("gui/icons/system_jumpdrive");
        system_rows[int(ShipSystem::Type::FrontShield)].label->setIcon("gui/icons/shields-fore");
        system_rows[int(ShipSystem::Type::RearShield)].label->setIcon("gui/icons/shields-aft");
    };
    setSystemRowIcons(thermal_rows);

    // TODO: More functionality if there's a docking bay system to vent into.

    // Repair-specific berth controls.
    repair_controls = new GuiElement(right_column, "DOCKING_BAY_REPAIR_CONTROLS");
    repair_controls
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    (new GuiLabel(repair_controls, "DOCKING_BAY_REPAIR_LABEL", tr("dockingbay", "Repair operations"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    GuiElement* repair_controls_row = new GuiElement(repair_controls, "DOCKING_BAY_REPAIR_CONTROLS_ROW");
    repair_controls_row
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("layout", "horizontal");

    (new GuiLabel(repair_controls_row, "DOCKING_BAY_VENT_LABEL", tr("dockingbay", "Prioritize repairs:"), 30.0f))
        ->setAlignment(sp::Alignment::CenterRight)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    repair_prioritization_direction = new GuiSlider(repair_controls_row, "DOCKING_BAY_REPAIR_SLIDER",
        static_cast<float>(DockingBay::Berth::TransferDirection::ToCarrier),
        static_cast<float>(DockingBay::Berth::TransferDirection::ToDocked),
        static_cast<float>(DockingBay::Berth::TransferDirection::None),
        [this](float value)
        {
            if (!my_spaceship || !my_player_info) return;

            if (auto bay = my_spaceship.getComponent<DockingBay>())
            {
                if (selected_berth_index >= 0 && selected_berth_index < static_cast<int>(bay->berths.size()))
                    my_player_info->commandSetBerthTransferDirection(selected_berth_index, static_cast<int>(value));
            }
        }
    );
    repair_prioritization_direction
        ->addSnapValue(static_cast<float>(DockingBay::Berth::TransferDirection::ToCarrier), 0.75f)
        ->addSnapValue(static_cast<float>(DockingBay::Berth::TransferDirection::None), 0.5f)
        ->addSnapValue(static_cast<float>(DockingBay::Berth::TransferDirection::ToDocked), 0.75f)
        ->setSize(400.0f, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "10, 0");

    (new GuiElement(repair_controls_row, "SPACER"))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    GuiElement* repair_prioritization_labels_row = new GuiElement(repair_controls, "DOCKING_BAY_ENERGY_TRANSFER_LABELS");
    repair_prioritization_labels_row
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("layout", "horizontal");

    (new GuiElement(repair_prioritization_labels_row, "SPACER"))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    (new GuiLabel(repair_prioritization_labels_row, "", tr("dockingbay", "prioritize systems"), 20.0f))
        ->setAlignment(sp::Alignment::CenterLeft)
        ->setSize(150.0f, GuiElement::GuiSizeMax);

    (new GuiLabel(repair_prioritization_labels_row, "", tr("dockingbay", "none"), 20.0f))
        ->setAlignment(sp::Alignment::Center)
        ->setSize(100.0f, GuiElement::GuiSizeMax);

    (new GuiLabel(repair_prioritization_labels_row, "", tr("dockingbay", "prioritize hull"), 20.0f))
        ->setAlignment(sp::Alignment::CenterRight)
        ->setSize(150.0f, GuiElement::GuiSizeMax);

    (new GuiElement(repair_prioritization_labels_row, "SPACER"))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    damage_gauges_row = new GuiElement(repair_controls, "REPAIR_DAMAGE_GAUGES");
    damage_gauges_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");

    GuiElement* damage_gauges_left = new GuiElement(damage_gauges_row, "REPAIR_DAMAGE_GAUGES_LEFT");
    damage_gauges_left
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "0, 10, 0, 0");
    damage_gauges_left
        ->setAttribute("layout", "vertical");

    GuiElement* damage_gauges_right = new GuiElement(damage_gauges_row, "REPAIR_DAMAGE_GAUGES_RIGHT");
    damage_gauges_right
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "10, 0, 0, 0");
    damage_gauges_right
        ->setAttribute("layout", "vertical");

    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        string id = "REPAIR_SYSTEM_ROW_" + getSystemName(ShipSystem::Type(n));
        SystemRow info;

        info.row = new GuiElement(n < ShipSystem::COUNT / 2 ? damage_gauges_left : damage_gauges_right, id);
        info.row
            ->setSize(GuiElement::GuiSizeMax, kv_size)
            ->hide()
            ->setAttribute("layout", "horizontal");

        info.label = new GuiKeyValueDisplay(info.row, id + "_LABEL", 0.175f, "", getLocaleSystemName(ShipSystem::Type(n)));
        info.label
            ->setSize(250.0f, GuiElement::GuiSizeMax);

        info.damage_bar = new GuiProgressbar(info.row, id + "_DAMAGE", 0.0f, 1.0f, 0.0f);
        info.damage_bar->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        info.damage_icon = new GuiImage(info.damage_bar, "", "gui/icons/system_health");
        info.damage_icon
            ->setColor(colorConfig.overlay_damaged)
            ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
            ->setSize(GuiElement::GuiSizeMatchHeight, GuiElement::GuiSizeMax);
        info.damage_label = new GuiLabel(info.damage_bar, id + "_DAMAGE_LABEL", "...", 20.0f);
        info.damage_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        // info.row->moveToBack();
        repair_rows.push_back(info);
    }
    setSystemRowIcons(repair_rows);

    // Restocking-specific berth controls.
    supply_controls = new GuiElement(right_column, "DOCKING_BAY_SUPPLY_CONTROLS");
    supply_controls
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    (new GuiLabel(supply_controls, "DOCKING_BAY_SUPPLY_LABEL", tr("dockingbay", "Supply operations"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    GuiElement* supply_controls_row = new GuiElement(supply_controls, "DOCKING_BAY_SUPPLY_CONTROLS_ROW");
    supply_controls_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");

    (new GuiElement(supply_controls_row, "SPACER"))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    GuiElement* supply_controls_left = new GuiElement(supply_controls_row, "DOCKING_BAY_SUPPLY_CONTROLS_LEFT");
    supply_controls_left
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    GuiElement* supply_controls_center = new GuiElement(supply_controls_row, "DOCKING_BAY_SUPPLY_CONTROLS_CENTER");
    supply_controls_center
        ->setSize(kv_size * 2.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    supply_controls_center
        ->setAttribute("margin", "10, 0");

    GuiElement* supply_controls_right = new GuiElement(supply_controls_row, "DOCKING_BAY_SUPPLY_CONTROLS_RIGHT");
    supply_controls_right
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    (new GuiElement(supply_controls_row, "SPACER"))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    auto populateMissiles = [](GuiKeyValueDisplay* supply_missiles[MW_Count], GuiElement* column) {
        for (int i = MW_Homing; i < MW_Count; i++)
        {
            supply_missiles[i] = new GuiKeyValueDisplay(column, "", kv_split, getLocaleMissileWeaponName(static_cast<EMissileWeapons>(i)), "");
            supply_missiles[i]->setSize(200.0f, kv_size);
        }

        supply_missiles[MW_Homing]->setIcon("gui/icons/weapon-homing");
        supply_missiles[MW_Nuke]->setIcon("gui/icons/weapon-nuke");
        supply_missiles[MW_EMP]->setIcon("gui/icons/weapon-emp");
        supply_missiles[MW_HVLI]->setIcon("gui/icons/weapon-hvli");
        supply_missiles[MW_Mine]->setIcon("gui/icons/weapon-mine");

        return supply_missiles;
    };

    // Populate missile key/value displays
    populateMissiles(berth_missiles, supply_controls_left);
    populateMissiles(carrier_missiles, supply_controls_right);

    // Populate missile transfer buttons
    GuiButton* to_berth[MW_Count];
    GuiButton* to_carrier[MW_Count];
    GuiElement* supply_controls_center_row;

    for (int i = MW_Homing; i < MW_Count; i++)
    {
        supply_controls_center_row = new GuiElement(supply_controls_center, "");
        supply_controls_center_row
            ->setSize(GuiElement::GuiSizeMax, kv_size)
            ->setAttribute("layout", "horizontal");

        to_berth[i] = new GuiButton(supply_controls_center_row, "", "<",
            [this, supply_controls_center_row, i]()
            {
                LOG(Info, "Send MW ", i, " to berthed ship");

                if (!my_spaceship || !my_player_info) return;
                auto bay = my_spaceship.getComponent<DockingBay>();
                if (!bay) return;
                if (selected_berth_index < 0 || selected_berth_index >= static_cast<int>(bay->berths.size())) return;

                auto selected_entity = bay->berths[selected_berth_index].docked_entity;
                auto berth_tubes = selected_entity.getComponent<MissileTubes>();
                if (!berth_tubes) return;
                if (berth_tubes->storage[i] >= berth_tubes->storage_max[i]) return;
                auto carrier_tubes = my_spaceship.getComponent<MissileTubes>();
                if (!carrier_tubes) return;
                if (carrier_tubes->storage[i] <= 0) return;

                carrier_tubes->storage[i] -= 1;
                berth_tubes->storage[i] += 1;
            }
        );
        to_berth[i]->setSize(kv_size, kv_size);
        to_carrier[i] = new GuiButton(supply_controls_center_row, "", ">",
            [this, supply_controls_center_row, i]()
            {
                if (!my_spaceship || !my_player_info) return;
                auto bay = my_spaceship.getComponent<DockingBay>();
                if (!bay) return;
                if (selected_berth_index < 0 || selected_berth_index >= static_cast<int>(bay->berths.size())) return;

                auto selected_entity = bay->berths[selected_berth_index].docked_entity;
                auto berth_tubes = selected_entity.getComponent<MissileTubes>();
                if (!berth_tubes) return;
                if (berth_tubes->storage[i] <= 0) return;
                auto carrier_tubes = my_spaceship.getComponent<MissileTubes>();
                if (!carrier_tubes) return;
                if (carrier_tubes->storage[i] >= carrier_tubes->storage_max[i]) return;

                carrier_tubes->storage[i] += 1;
                berth_tubes->storage[i] -= 1;
            }
        );
        to_carrier[i]->setSize(kv_size, kv_size);
    }

    // Populate scan probe key/value displays
    berth_scan_probes = new GuiKeyValueDisplay(supply_controls_left, "", kv_split, tr("dockingbay", "Probes"), "-");
    berth_scan_probes
        ->setIcon("/radar/probe.png")
        ->setSize(200.0f, kv_size);
    carrier_scan_probes = new GuiKeyValueDisplay(supply_controls_right, "", kv_split, tr("dockingbay", "Probes"), "-");
    carrier_scan_probes
        ->setIcon("/radar/probe.png")
        ->setSize(200.0f, kv_size);

    supply_controls_center_row = new GuiElement(supply_controls_center, "");
        supply_controls_center_row
            ->setSize(GuiElement::GuiSizeMax, kv_size)
            ->setAttribute("layout", "horizontal");

    // Populate scan probe transfer buttons
    (new GuiButton(supply_controls_center_row, "", "<",
        [this]()
        {
            if (!my_spaceship || !my_player_info) return;
            auto bay = my_spaceship.getComponent<DockingBay>();
            if (!bay) return;
            if (selected_berth_index < 0 || selected_berth_index >= static_cast<int>(bay->berths.size())) return;

            auto selected_entity = bay->berths[selected_berth_index].docked_entity;
            auto berth_probes = selected_entity.getComponent<ScanProbeLauncher>();
            if (!berth_probes) return;
            if (berth_probes->stock >= berth_probes->max) return;
            auto carrier_probes = my_spaceship.getComponent<ScanProbeLauncher>();
            if (!carrier_probes) return;
            if (carrier_probes->stock <= 0) return;

            carrier_probes->stock -= 1;
            berth_probes->stock += 1;
        }
    ))->setSize(kv_size, kv_size);

    (new GuiButton(supply_controls_center_row, "", ">",
        [this]()
        {
            if (!my_spaceship || !my_player_info) return;
            auto bay = my_spaceship.getComponent<DockingBay>();
            if (!bay) return;
            if (selected_berth_index < 0 || selected_berth_index >= static_cast<int>(bay->berths.size())) return;

            auto selected_entity = bay->berths[selected_berth_index].docked_entity;
            auto berth_probes = selected_entity.getComponent<ScanProbeLauncher>();
            if (!berth_probes) return;
            if (berth_probes->stock <= 0) return;
            auto carrier_probes = my_spaceship.getComponent<ScanProbeLauncher>();
            if (!carrier_probes) return;
            if (carrier_probes->stock >= carrier_probes->max) return;

            carrier_probes->stock += 1;
            berth_probes->stock -= 1;
        }
    ))->setSize(kv_size, kv_size);

    // TODO: Fill berth with supply drop

    // Storage-specific berth controls.
    storage_controls = new GuiElement(right_column, "DOCKING_BAY_STORAGE_CONTROLS");
    storage_controls
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "vertical");

    (new GuiLabel(storage_controls, "DOCKING_BAY_STORAGE_LABEL", tr("Storage operations"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setAttribute("margin", "0, 0, 0, 10");

    // TODO: Are controls necessary for this berth type?

    // Custom ship functions
    /*
    (new GuiCustomShipFunctions(this, CrewPosition::dockingBay, "DOCKING_BAY_CSF"))
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax);
    */
}

void DockingBayScreen::onDraw(sp::RenderTarget& renderer)
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
            selectBerth(-1);
    }

    // Update berth labels every frame to ensure they're set after panels are created.
    updateBerthsLabels();

    // Update the display if a berth is selected.
    if (selected_berth_index >= 0) updateSelectedEntityDisplay();

    // Update the carrier's energy level.
    if (auto carrier_reactor = my_spaceship.getComponent<Reactor>())
    {
        energy_carrier
            ->setColor(glm::u8vec4(255, 255, 255, 255))
            ->setValue(static_cast<string>("{energy}/{max_energy}").format({
                {"energy", toNearbyIntString(carrier_reactor->energy)},
                {"max_energy", toNearbyIntString(carrier_reactor->max_energy)}
            }));
    }
    else
    {
        energy_carrier
            ->setColor(glm::u8vec4(128, 128, 128, 255))
            ->setValue(tr("dockingbay", "No reactor"));
    }
    GuiOverlay::onDraw(renderer);
}

void DockingBayScreen::onUpdate()
{
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
        case DockingBay::Berth::Type::Hangar:
            hangar_controls->show();
            energy_controls->hide();
            thermal_controls->hide();
            supply_controls->hide();
            repair_controls->hide();
            storage_controls->hide();
            break;
        case DockingBay::Berth::Type::Energy:
            hangar_controls->hide();
            energy_controls->show();
            thermal_controls->hide();
            supply_controls->hide();
            repair_controls->hide();
            storage_controls->hide();
            break;
        case DockingBay::Berth::Type::Thermal:
            hangar_controls->hide();
            energy_controls->hide();
            thermal_controls->show();
            supply_controls->hide();
            repair_controls->hide();
            storage_controls->hide();
            break;
        case DockingBay::Berth::Type::Supply:
            hangar_controls->hide();
            energy_controls->hide();
            thermal_controls->hide();
            supply_controls->show();
            repair_controls->hide();
            storage_controls->hide();
            break;
        case DockingBay::Berth::Type::Repair:
            hangar_controls->hide();
            energy_controls->hide();
            thermal_controls->hide();
            supply_controls->hide();
            repair_controls->show();
            storage_controls->hide();
            break;
        case DockingBay::Berth::Type::Storage:
            hangar_controls->hide();
            energy_controls->hide();
            thermal_controls->hide();
            supply_controls->hide();
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
    if (!my_spaceship) return;

    auto bay = my_spaceship.getComponent<DockingBay>();
    if (!bay) return;

    // Select the panel by index.
    docking_bay_berths->selectPanelByIndex(selected_berth_index);

    // Validate berth index.
    if (selected_berth_index < 0 || selected_berth_index >= static_cast<int>(bay->berths.size()))
    {
        selected_entity = sp::ecs::Entity();
        selected_entity_info
            ->setEntity(selected_entity)
            ->setCustomLabel(0, "")
            ->setCustomIcon(1, "")
            ->setCustomLabel(2, "");
        entity_energy->setValue("");
        entity_hull->setValue("");
        for (auto kv : entity_missiles) kv->setValue("");
        return;
    }

    // Update selected_entity from the berth.
    selected_entity = bay->berths[selected_berth_index].docked_entity;

    const string type_icon = bay->getTypeIcon(bay->berths[selected_berth_index].type);
    const string type_name = bay->getTypeName(bay->berths[selected_berth_index].type);
    selected_entity_info
        ->setEntity(selected_entity)
        ->setCustomLabel(0, tr("Berth {i}").format({{"i", selected_berth_index + 1}}))
        ->setCustomIcon(1, type_icon)
        ->setCustomLabel(2, type_name);

    // Update reactor/energy displays.
    auto carrier_reactor = my_spaceship.getComponent<Reactor>();
    auto docked_reactor = selected_entity.getComponent<Reactor>();
    energy_transfer_direction->setEnable(docked_reactor && carrier_reactor);

    if (docked_reactor)
    {
        entity_energy
            ->setColor(glm::u8vec4(255, 255, 255, 255))
            ->setValue(static_cast<string>("{energy}/{max_energy}").format({
                {"energy", toNearbyIntString(docked_reactor->energy)},
                {"max_energy", toNearbyIntString(docked_reactor->max_energy)}
            }));
    }
    else
    {
        entity_energy
            ->setColor(glm::u8vec4(128, 128, 128, 255))
            ->setValue(tr("dockingbay", "No reactor"));
        energy_transfer_direction
            ->setValue(static_cast<float>(DockingBay::Berth::TransferDirection::None));
    }

    // Update hull display.
    if (auto hull = selected_entity.getComponent<Hull>())
    {
        if (hull->max > 0.0f)
        {
            const string hull_value = static_cast<string>("{hull}%").format({
                {"hull", static_cast<int>((hull->current / hull->max) * 100.0f)}
            });

            entity_hull->setValue(hull_value);
        }
        else entity_hull->setValue("");
    }
    else entity_hull->setValue(tr("dockingbay", "N/A"));

    // Update missile displays.
    if (auto tubes = selected_entity.getComponent<MissileTubes>())
    {
        for (int i = MW_Homing; i < MW_Count; i++)
        {
            updateMissileDisplay(entity_missiles[i], tubes, static_cast<EMissileWeapons>(i));
            updateMissileDisplay(berth_missiles[i], tubes, static_cast<EMissileWeapons>(i));
        }
    }
    else
    {
        for (auto kv : entity_missiles) kv->setValue("-");
        for (auto kv : berth_missiles) kv->setValue("-");
    }

    if (auto tubes = my_spaceship.getComponent<MissileTubes>())
    {
        for (int i = MW_Homing; i < MW_Count; i++)
            updateMissileDisplay(carrier_missiles[i], tubes, static_cast<EMissileWeapons>(i));
    }

    // Update scan probe displays.
    if (auto scan_probes = selected_entity.getComponent<ScanProbeLauncher>())
        berth_scan_probes->setValue(scan_probes->stock);
    else
        berth_scan_probes->setValue("-");

    if (auto scan_probes = my_spaceship.getComponent<ScanProbeLauncher>())
        carrier_scan_probes->setValue(scan_probes->stock);
    else
        carrier_scan_probes->setValue("-");

    // Update repair and thermal systems displays.
    if (repair_controls->isVisible())
    {
        if (!selected_entity)
        {
            repair_prioritization_direction
                ->setValue(0.0f)
                ->disable();
            damage_gauges_row->hide();
        }
        else
        {
            damage_gauges_row->show();
            repair_prioritization_direction->enable();

            for (int n = 0; n < ShipSystem::COUNT; n++)
            {
                SystemRow info = repair_rows[n];
                auto system = ShipSystem::get(selected_entity, ShipSystem::Type(n));
                info.row->setVisible(system);
                if (!system) continue;

                float health = system->health;
                if (health < 0.0f)
                {
                    info.damage_bar
                        ->setValue(-health)
                        ->setColor(glm::u8vec4(128, 32, 32, 192));
                }
                else
                {
                    info.damage_bar
                        ->setValue(health)
                        ->setColor(glm::u8vec4(64, static_cast<int>(128.0f * health), static_cast<int>(64.0f * health), 192));
                }

                info.damage_label->setText(toNearbyIntString(health * 100.0f) + "%");
                info.damage_icon->setVisible(system->health_max < 1.0f);
            }

            if (!selected_entity.hasComponent<Hull>() && repair_prioritization_direction->getValue() < 0.0f)
                repair_prioritization_direction->setValue(0.0f);
        }
    }

    if (thermal_controls->isVisible())
    {
        if (!selected_entity)
        {
            thermal_venting_direction
                ->setValue(0.0f)
                ->disable();
            heat_gauges_row->hide();
        }
        else
        {
            heat_gauges_row->show();

            for (int n = 0; n < ShipSystem::COUNT; n++)
            {
                SystemRow info = thermal_rows[n];
                auto system = ShipSystem::get(selected_entity, ShipSystem::Type(n));
                info.row->setVisible(system);
                if (!system) continue;

                float heat = system->heat_level;
                info.heat_bar
                    ->setValue(heat)
                    ->setColor(glm::u8vec4(128, 32 + static_cast<int>(96.0f * 1.0f - heat), 32, 192));

                float heating_diff = system->getHeatingDelta();
                info.heat_arrow
                    ->setAngle(heating_diff > 0.0f ? 90.0f : -90.0f)
                    ->setColor(glm::u8vec4(255, 255, 255, std::min(255, int(255.0f * fabs(heating_diff)))))
                    ->setVisible(heat > 0.0f);

                info.heat_icon->setVisible(heat > 0.9f);
            }

            thermal_venting_direction->setEnable(selected_entity.hasComponent<Coolant>() && my_spaceship.hasComponent<Coolant>());
        }
    }
}

void DockingBayScreen::updateMissileDisplay(GuiKeyValueDisplay* display, MissileTubes* tubes, EMissileWeapons type)
{
    if (tubes->storage_max[type] > 0)
    {
        display
            ->setValue(static_cast<string>(tubes->storage[type]) + "/" +
                      static_cast<string>(tubes->storage_max[type]));
    }
    else display->setValue("-");
}
