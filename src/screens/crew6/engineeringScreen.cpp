#include "engineeringScreen.h"
#include <i18n.h>
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "engine.h"

#include "components/beamweapon.h"
#include "components/coolant.h"
#include "components/hull.h"
#include "components/impulse.h"
#include "components/jumpdrive.h"
#include "components/maneuveringthrusters.h"
#include "components/probe.h"
#include "components/radar.h"
#include "components/reactor.h"
#include "components/selfdestruct.h"
#include "components/shields.h"
#include "components/utilityBeam.h"

#include "screenComponents/alertOverlay.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/infoDisplay.h"
#include "screenComponents/selfDestructButton.h"
#include "screenComponents/shieldFreqencySelect.h"
#include "screenComponents/shieldsEnableButton.h"
#include "screenComponents/shipInternalView.h"

#include "gui/theme.h"
#include "gui/gui2_arrow.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_panel.h"
#include "gui/gui2_progressbar.h"
#include "gui/gui2_progressslider.h"
#include "gui/gui2_slider.h"
#include "gui/gui2_togglebutton.h"

EngineeringScreen::EngineeringScreen(GuiContainer* owner, CrewPosition crew_position)
: GuiOverlay(owner, "ENGINEERING_SCREEN", GuiTheme::getColor("background"))
{
    bool has_coolant = false;
    bool has_reactor = false;
    float power_max = 3.0f;

    if (my_spaceship)
    {
        has_coolant = my_spaceship.hasComponent<Coolant>();
        has_reactor = my_spaceship.hasComponent<Reactor>();
        if (!has_coolant && !has_reactor) power_max = 1.0f;
    }

    slider_tick_style = theme->getStyle("slider.tick");
    overlay_damaged_style = theme->getStyle("overlay.damaged");
    overlay_overheating_style = theme->getStyle("overlay.overheating");

    // Render the background decorations.
    (new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    // Render the alert level color overlay.
    new AlertLevelOverlay(this);

    // Container
    GuiElement* container = new GuiElement(this, "");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    container
        ->setAttribute("padding", "20");

    // Top row (self-destuct, stats, Eng+ shields, interior view).
    GuiElement* top_row = new GuiElement(container, "");
    top_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");

    // Top-left controls.
    GuiElement* top_left = new GuiElement(top_row, "");
    top_left
        ->setSize(250.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Self-destruct trigger.
    self_destruct_button = new GuiSelfDestructButton(top_left, "SELF_DESTRUCT");
    self_destruct_button
        ->setSize(GuiElement::GuiSizeMax, 100.0f) // Not 50.0f, due to Confirm button
        ->setVisible(my_spaceship && my_spaceship.hasComponent<SelfDestruct>());

    // Ship stats key/values.
    auto stats = new GuiElement(top_left, "ENGINEERING_STATS");
    stats
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    stats
        ->setAttribute("margin", "0, 0, -20, 0");
    stats
        ->getLayout().match_content_y = true;

    auto energy_display = new EnergyInfoDisplay(stats, "ENERGY_DISPLAY", 0.45f, true);
    energy_display
        ->setIcon("gui/icons/energy")
        ->setSize(GuiElement::GuiSizeMax, 40.0f)
        ->setVisible(has_reactor);
    auto hull_display = new HullInfoDisplay(stats, "HULL_DISPLAY", 0.45f);
    hull_display
        ->setSize(GuiElement::GuiSizeMax, 40.0f);
    auto front_shield_display = new ShieldsInfoDisplay(stats, "FRONT_SHIELDS_DISPLAY", 0.45f, 0);
    front_shield_display
        ->setSize(GuiElement::GuiSizeMax, 40.0f);
    auto rear_shield_display = new ShieldsInfoDisplay(stats, "REAR_SHIELDS_DISPLAY", 0.45f, 1);
    rear_shield_display
        ->setSize(GuiElement::GuiSizeMax, 40.0f);
    auto coolant_display = new CoolantInfoDisplay(stats, "COOLANT_DISPLAY", 0.45f);
    coolant_display
        ->setSize(GuiElement::GuiSizeMax, 40.0f)
        ->setVisible(has_coolant);

    // Engineering+ screen features.
    if (crew_position == CrewPosition::engineeringPlus)
    {
        if (gameGlobalInfo->use_beam_shield_frequencies)
            (new GuiShieldFrequencySelect(top_left, "SHIELD_FREQ"))->setSize(GuiElement::GuiSizeMax, 100.0f);
        else
            (new GuiShieldsEnableButton(top_left, "SHIELDS_ENABLE"))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
    }

    // Top-right controls.
    GuiElement* top_right = new GuiElement(top_row, "");
    top_right
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");

    GuiShipInternalView* internal_view = new GuiShipInternalView(top_right, "SHIP_INTERNAL_VIEW", 48.0f);
    internal_view
        ->setShip(my_spaceship)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    GuiElement* top_right_column = new GuiElement(top_row, "");
    top_right_column
        ->setSize(270.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    (new GuiCustomShipFunctions(top_right_column, crew_position, "CSF"))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    system_effects_container = new GuiElement(top_right_column, "");
    system_effects_container
        ->setPosition(0.0f, 0.0f, sp::Alignment::BottomRight)
        ->setSize(GuiElement::GuiSizeMax, 400.0f)
        ->setAttribute("layout", "verticalbottom");

    // Bottom row (ship systems, power/coolant sliders).
    GuiElement* bottom_row = new GuiScrollContainer(container, "");
    bottom_row
        ->setSize(GuiElement::GuiSizeMax, 450.0f)
        ->setAttribute("layout", "horizontal");

    // Ship systems container.
    GuiElement* system_config_container = new GuiElement(bottom_row, "");
    system_config_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");

    GuiElement* system_row_layouts = new GuiElement(system_config_container, "SYSTEM_ROWS");
    system_row_layouts
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "verticalbottom");

    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        string id = "SYSTEM_ROW_" + getSystemName(ShipSystem::Type(n));
        SystemRow info;
        info.row = new GuiElement(system_row_layouts, id);
        info.row
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("layout", "horizontal");

        info.button = new GuiToggleButton(info.row, id + "_SELECT", getLocaleSystemName(ShipSystem::Type(n)),
            [this, n](bool value)
            {
                selectSystem(ShipSystem::Type(n));
            }
        );
        info.button->setSize(300.0f, GuiElement::GuiSizeMax);

        info.damage_bar = new GuiProgressbar(info.row, id + "_DAMAGE", 0.0f, 1.0f, 0.0f);
        info.damage_bar
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
            ->setVisible(gameGlobalInfo->use_system_damage);
        info.damage_icon = new GuiImage(info.damage_bar, "", "gui/icons/system_health");
        info.damage_icon
            ->setColor(overlay_damaged_style->get(getState()).color)
            ->setPosition(0.0f, 0.0f, sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMatchHeight, GuiElement::GuiSizeMax);
        info.damage_label = new GuiLabel(info.damage_bar, id + "_DAMAGE_LABEL", "...", 20.0f);
        info.damage_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        info.heat_bar = new GuiProgressbar(info.row, id + "_HEAT", 0.0f, 1.0f, 0.0f);
        info.heat_bar
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
            ->setVisible(has_coolant);
        info.heat_arrow = new GuiArrow(info.heat_bar, id + "_HEAT_ARROW", 0.0f);
        info.heat_arrow
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        info.heat_icon = new GuiImage(info.heat_bar, "", "gui/icons/status_overheat");
        info.heat_icon
            ->setColor(overlay_overheating_style->get(getState()).color)
            ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
            ->setSize(GuiElement::GuiSizeMatchHeight, GuiElement::GuiSizeMax);

        info.power_bar = new GuiProgressSlider(info.row, id + "_POWER", 0.0f, power_max, 0.0f,
            [n](float value)
            {
                if (my_spaceship)
                    my_player_info->commandSetSystemPowerRequest(ShipSystem::Type(n), value);
            }
        );
        info.power_bar
            ->setColor(glm::u8vec4(192, 192, 32, 128))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        info.coolant_bar = new GuiProgressSlider(info.row, id + "_COOLANT", 0.0f, 10.0f, 0.0f,
            [n](float value)
            {
                if (my_spaceship)
                    my_player_info->commandSetSystemCoolantRequest(ShipSystem::Type(n), value);
            }
        );
        info.coolant_bar
            ->setColor(glm::u8vec4(32, 128, 128, 128))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
            ->setVisible(has_coolant);

        if (!gameGlobalInfo->use_system_damage) info.damage_bar->hide();
        info.coolant_max_indicator = new GuiImage(info.coolant_bar, "", slider_tick_style->get(getState()).texture);
        info.coolant_max_indicator
            ->setAngle(90.0f)
            ->setColor(glm::u8vec4{255, 255, 255, 0})
            ->setSize(40.0f, 40.0f);

        info.row->moveToBack();
        system_rows.push_back(info);
    }

    GuiElement* icon_layout = new GuiElement(system_row_layouts, "");
    icon_layout
        ->setSize(GuiElement::GuiSizeMax, 48.0f)
        ->setAttribute("layout", "horizontal");

    (new GuiElement(icon_layout, "FILLER"))
        ->setSize(300.0f, GuiElement::GuiSizeMax);

    system_health_icon = new GuiImage(icon_layout, "SYSTEM_HEALTH_ICON", "gui/icons/system_health");
    system_health_icon
        ->setSize(150.0f, GuiElement::GuiSizeMax)
        ->setVisible(gameGlobalInfo->use_system_damage);

    heat_icon = new GuiImage(icon_layout, "HEAT_ICON", "gui/icons/status_overheat");
    heat_icon
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setVisible(has_coolant);

    (new GuiImage(icon_layout, "POWER_ICON", "gui/icons/energy"))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    coolant_remaining_bar = new GuiProgressSlider(icon_layout, "", 0, 10.0, 10.0,
        [](float requested_unused_coolant)
        {
            auto coolant = my_spaceship.getComponent<Coolant>();
            if (!coolant) return;

            float total_requested = 0.0f;
            float new_max_total = coolant->max - requested_unused_coolant;

            for (int n = 0; n < ShipSystem::COUNT; n++)
            {
                if (auto sys = ShipSystem::get(my_spaceship, ShipSystem::Type(n)))
                    total_requested += sys->coolant_request;
            }

            // Drain systems
            if (new_max_total < total_requested)
            {
                for (int n = 0; n < ShipSystem::COUNT; n++)
                {
                    if (auto sys = ShipSystem::get(my_spaceship, ShipSystem::Type(n)))
                        my_player_info->commandSetSystemCoolantRequest(ShipSystem::Type(n), sys->coolant_request * new_max_total / total_requested);
                }
            }
            // Put coolant into systems
            else
            {
                int system_count = 0;
                for (int n = 0; n < ShipSystem::COUNT; n++)
                {
                    if (ShipSystem::get(my_spaceship, ShipSystem::Type(n)))
                        system_count++;
                }

                float add = (new_max_total - total_requested) / static_cast<float>(system_count);

                for (int n = 0; n < ShipSystem::COUNT; n++)
                {
                    if (auto sys = ShipSystem::get(my_spaceship, ShipSystem::Type(n)))
                        my_player_info->commandSetSystemCoolantRequest(ShipSystem::Type(n), std::min(sys->coolant_request + add, 10.0f));
                }
            }
        }
    );
    coolant_remaining_bar
        ->setColor(glm::u8vec4(32, 128, 128, 128))
        ->setDrawBackground(false)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setVisible(has_coolant);
    (new GuiImage(coolant_remaining_bar, "COOLANT_ICON", "gui/icons/coolant"))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    system_rows[static_cast<int>(ShipSystem::Type::Reactor)].button->setIcon("gui/icons/system_reactor");
    system_rows[static_cast<int>(ShipSystem::Type::BeamWeapons)].button->setIcon("gui/icons/system_beam");
    system_rows[static_cast<int>(ShipSystem::Type::MissileSystem)].button->setIcon("gui/icons/system_missile");
    system_rows[static_cast<int>(ShipSystem::Type::Maneuver)].button->setIcon("gui/icons/system_maneuver");
    system_rows[static_cast<int>(ShipSystem::Type::Impulse)].button->setIcon("gui/icons/system_impulse");
    system_rows[static_cast<int>(ShipSystem::Type::Warp)].button->setIcon("gui/icons/system_warpdrive");
    system_rows[static_cast<int>(ShipSystem::Type::JumpDrive)].button->setIcon("gui/icons/system_jumpdrive");
    system_rows[static_cast<int>(ShipSystem::Type::FrontShield)].button->setIcon("gui/icons/shields-fore");
    system_rows[static_cast<int>(ShipSystem::Type::RearShield)].button->setIcon("gui/icons/shields-aft");
    system_rows[static_cast<int>(ShipSystem::Type::UtilityBeam)].button->setIcon("gui/icons/system_utilitybeam");
    system_rows[static_cast<int>(ShipSystem::Type::DockingBay)].button->setIcon("gui/icons/docking");
    system_rows[static_cast<int>(ShipSystem::Type::Sensors)].button->setIcon("gui/icons/station-radar");

    GuiPanel* power_coolant_box = new GuiPanel(system_config_container, "POWER_COOLANT_BOX");
    power_coolant_box
        ->setSize(270.0f, GuiElement::GuiSizeMax)
        ->setAttribute("padding", "20");
    power_coolant_box
        ->setAttribute("layout", "horizontal");
    power_coolant_box
        ->getLayout().match_content_x = true;

    power_label = new GuiLabel(power_coolant_box, "POWER_LABEL", tr("slider", "Power"), GuiElement::GuiSizeLabel);
    power_label
        ->setVertical()
        ->setAlignment(sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeLabel, GuiElement::GuiSizeMax);

    GuiElement* control = new GuiElement(power_coolant_box, "");
    control
        ->setSize(60.0f, GuiElement::GuiSizeMax);

    power_bar = new GuiProgressbar(control, "POWER_BAR", 0.0f, power_max, 0.0f);
    power_bar
        ->setDrawBackground(false)
        ->setColor(glm::u8vec4(192, 192, 32, 255))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "5, 30");
    power_slider = new GuiSlider(control, "POWER_SLIDER", power_max, 0.0f, 1.0f,
        [this](float value)
        {
            if (my_spaceship && selected_system != ShipSystem::Type::None)
                my_player_info->commandSetSystemPowerRequest(selected_system, value);
        }
    );
    power_slider
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->disable();
    for (float snap_point = 0.0f; snap_point <= power_max; snap_point += 0.5f)
        power_slider->addSnapValue(snap_point, snap_point == 1.0f ? 0.1f : 0.01f);

    coolant_label = new GuiLabel(power_coolant_box, "COOLANT_LABEL", tr("slider", "Coolant"), GuiElement::GuiSizeLabel);
    coolant_label
        ->setVertical()
        ->setAlignment(sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeLabel, GuiElement::GuiSizeMax)
        ->setVisible(has_coolant);

    control = new GuiElement(power_coolant_box, "");
    control
        ->setSize(60.0f, GuiElement::GuiSizeMax);

    coolant_bar = new GuiProgressbar(control, "COOLANT_BAR", 0.0f, 10.0f, 0.0f);
    coolant_bar
        ->setDrawBackground(false)
        ->setColor(glm::u8vec4(32, 128, 128, 255))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setVisible(has_coolant)
        ->setAttribute("margin", "5, 30");

    coolant_slider = new GuiSlider(control, "COOLANT_SLIDER", 10.0f, 0.0f, 0.0f,
        [this](float value)
        {
            if (my_spaceship && selected_system != ShipSystem::Type::None)
                my_player_info->commandSetSystemCoolantRequest(selected_system, value);
        }
    );
    coolant_slider
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->disable()
        ->setVisible(has_coolant);
    for (float snap_point = 0.0f; snap_point <= 10.0f; snap_point += 2.5f)
        coolant_slider->addSnapValue(snap_point, 0.1f);
}

void EngineeringScreen::onDraw(sp::RenderTarget& renderer)
{
    if (my_spaceship)
    {
        float total_coolant_used = 0.0f;
        auto reactor = my_spaceship.getComponent<Reactor>();
        auto coolant = my_spaceship.getComponent<Coolant>();
        float power_max = (reactor || coolant) ? 3.0f : 1.0f;

        system_health_icon->setVisible(gameGlobalInfo->use_system_damage);
        heat_icon->setVisible(coolant);

        for (int n = 0; n < ShipSystem::COUNT; n++)
        {
            SystemRow info = system_rows[n];
            auto system = ShipSystem::get(my_spaceship, ShipSystem::Type(n));
            info.row->setVisible(system);
            if (!system) continue;

            if (gameGlobalInfo->use_system_damage)
            {
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
                float health_max = system->health_max;
                info.damage_icon->setVisible(health_max < 1.0f);
            }

            info.power_bar
                ->setRange(0.0f, power_max)
                ->setValue(system->power_level);

            info.heat_bar->setVisible(coolant);
            info.coolant_bar->setVisible(coolant);

            if (coolant)
            {
                // Render heat
                const float heat = system->heat_level;
                const float heating_diff = system->getHeatingDelta();

                info.heat_bar
                    ->setValue(heat)
                    ->setColor(glm::u8vec4(128, 32 + static_cast<int>(96.0f * (1.0f - heat)), 32, 192));

                info.heat_arrow
                    ->setAngle((heating_diff > 0) ? 90.0f : -90.0f)
                    ->setColor(glm::u8vec4(255, 255, 255, std::min(255, static_cast<int>(255.0f * fabs(heating_diff)))))
                    ->setVisible(heat > 0.0f);

                info.heat_icon->setVisible(heat > 0.9f && fmod(engine->getElapsedTime(), 0.5f) < 0.25f);

                // Render coolant
                info.coolant_bar
                    ->setValue(system->coolant_level)
                    ->setEnable(!coolant->auto_levels);

                auto slider_tick_color = slider_tick_style->get(getState()).color;
                if (system->coolant_request > 0.0f)
                {
                    info.coolant_max_indicator
                        ->setColor({slider_tick_color.r, slider_tick_color.g, slider_tick_color.b, 255})
                        ->setPosition(-20.0f + info.coolant_bar->getRect().size.x * (system->coolant_request * 0.1f), 5.0f);
                }
                else
                    info.coolant_max_indicator->setColor({slider_tick_color.r, slider_tick_color.g, slider_tick_color.b, 0});

                total_coolant_used += system->coolant_level;
            }
        }

        // Render total remaining coolant
        coolant_remaining_bar->setVisible(coolant);
        if (coolant)
        {
            coolant_remaining_bar
                ->setRange(0.0f, coolant->max)
                ->setValue(coolant->max - total_coolant_used);
        }

        if (selected_system != ShipSystem::Type::None)
        {
            auto system = ShipSystem::get(my_spaceship, selected_system);
            if (system)
            {
                // Render power slider
                power_label->setText(tr("slider", "Power: {current_level}% / {requested}%").format({
                    {"current_level", toNearbyIntString(system->power_level * 100.0f)},
                    {"requested", toNearbyIntString(system->power_request * 100.0f)}
                }));

                // Limit max power to 100% if lacking both Coolant and Reactor.
                // Rotated bar takes the max value first.
                const float effective_power_max = (coolant || reactor) ? 3.0f : 1.0f;
                power_slider
                    ->setRange(effective_power_max, 0.0f)
                    ->setValue(system->power_request);

                power_bar
                    ->setRange(0.0f, effective_power_max)
                    ->setValue(system->power_level);

                // Render coolant slider
                coolant_label->setVisible(coolant);
                coolant_slider->setVisible(coolant);
                coolant_bar->setVisible(coolant);
                if (coolant)
                {
                    coolant_label->setText(tr("slider", "Coolant: {current_level}% / {requested}%").format({
                        {"current_level", toNearbyIntString(system->coolant_level / coolant->max_coolant_per_system * 100.0f)},
                        {"requested", toNearbyIntString(std::min(system->coolant_request, coolant->max) / coolant->max_coolant_per_system * 100.0f)}
                    }));
                    coolant_slider
                        ->setValue(std::min(system->coolant_request, coolant->max))
                        ->setEnable(!coolant->auto_levels);
                    coolant_bar->setValue(std::min(system->coolant_level, coolant->max));
                }

                system_effects_index = 0;
                float effectiveness = system->getSystemEffectiveness();

                float health_max = system->health_max;
                if (health_max < 1.0f)
                    addSystemEffect(tr("Engineer", "Maximal health"), toNearbyIntString(health_max * 100.0f) + "%");
                switch (selected_system)
                {
                case ShipSystem::Type::Reactor:
                    if (effectiveness > 1.0f)
                        effectiveness = (1.0f + effectiveness) * 0.5f;
                    addSystemEffect(tr("Energy production"),  tr("{energy}/min").format({
                        {"energy", string(effectiveness * -system->power_factor * system->power_factor_rate * 60.0f, 1)}
                    }));
                    break;
                case ShipSystem::Type::BeamWeapons:
                    addSystemEffect(tr("Firing rate"), toNearbyIntString(effectiveness * 100.0f) + "%");
                    // If the ship has a turret, also note that the rotation rate
                    // is affected.
                    if (auto beamweapons = my_spaceship.getComponent<BeamWeaponSys>())
                    {
                        for (auto& mount : beamweapons->mounts)
                        {
                            if (mount.turret_arc > 0)
                            {
                                addSystemEffect(tr("Engineer", "Turret rotation rate"), toNearbyIntString(effectiveness * 100) + "%");
                                break;
                            }
                        }
                    }
                    break;
                case ShipSystem::Type::UtilityBeam:
                    addSystemEffect(tr("Force"), toNearbyIntString(effectiveness * 100) + "%");
                    break;
                case ShipSystem::Type::MissileSystem:
                    addSystemEffect(tr("missile", "Reload rate"), toNearbyIntString(effectiveness * 100.0f) + "%");
                    break;
                case ShipSystem::Type::Maneuver:
                    {
                        addSystemEffect(tr("Turning speed"), toNearbyIntString(effectiveness * 100.0f) + "%");
                        if (my_spaceship.hasComponent<CombatManeuveringThrusters>())
                        {
                            auto impulse = my_spaceship.getComponent<ImpulseEngine>();
                            auto thrusters = my_spaceship.getComponent<ManeuveringThrusters>();
                            if (impulse && thrusters)
                                addSystemEffect(tr("Combat recharge rate"), toNearbyIntString(((impulse->getSystemEffectiveness() + thrusters->getSystemEffectiveness()) * 0.5f) * 100.0f) + "%");
                        }
                    }
                    break;
                case ShipSystem::Type::Impulse:
                    {
                        addSystemEffect(tr("Impulse speed"), toNearbyIntString(effectiveness * 100) + "%");
                        if (my_spaceship.hasComponent<CombatManeuveringThrusters>())
                        {
                            auto impulse = my_spaceship.getComponent<ImpulseEngine>();
                            auto thrusters = my_spaceship.getComponent<ManeuveringThrusters>();
                            if (impulse && thrusters)
                                addSystemEffect(tr("Combat recharge rate"), toNearbyIntString(((impulse->getSystemEffectiveness() + thrusters->getSystemEffectiveness()) * 0.5f) * 100.0f) + "%");
                        }
                    }
                    break;
                case ShipSystem::Type::Warp:
                    addSystemEffect(tr("Warp drive speed"), toNearbyIntString(effectiveness * 100.0f) + "%");
                    break;
                case ShipSystem::Type::JumpDrive:
                    {
                        if (auto jump = my_spaceship.getComponent<JumpDrive>())
                        {
                            if (jump->get_seconds_to_jump() == std::numeric_limits<int>::max())
                            {
                                addSystemEffect(tr("Time to jump activation"), tr("jumpcontrol", "{delay} sec.").format({
                                    {"delay", (jump->get_seconds_to_jump() == std::numeric_limits<int>::max()) ? "∞" : string(jump->get_seconds_to_jump())}
                                }));
                            }
                            addSystemEffect(tr("Jump drive recharge rate"), toNearbyIntString(jump->get_recharge_rate() * 100.0f) + "%");
                        }
                    }
                    break;
                case ShipSystem::Type::FrontShield:
                case ShipSystem::Type::RearShield:
                    {
                        if (auto shields = my_spaceship.getComponent<Shields>())
                        {
                            // Determine front or rear shields.
                            const std::size_t shield_index = (selected_system == ShipSystem::Type::FrontShield)
                                ? 0
                                : shields->entries.size() - 1;

                            // Add frequency calibration speed effect, if relevant.
                            if (gameGlobalInfo->use_beam_shield_frequencies)
                                addSystemEffect(tr("shields", "Calibration speed"), toNearbyIntString((shields->front_system.getSystemEffectiveness() + shields->rear_system.getSystemEffectiveness()) * 0.5f * 100.0f) + "%");

                            // Add charge rate effect.
                            addSystemEffect(tr("shields", "Charge rate"), toNearbyIntString(effectiveness * 100.0f) + "%");

                            // Add damage negation/vulnerability rate effect.
                            const float damage_negate = 1.0f - shields->getDamageFactor(shield_index);
                            if (damage_negate < 0.0f)
                                addSystemEffect(tr("Extra damage taken"), toNearbyIntString(-damage_negate * 100.0f) + "%");
                            else
                                addSystemEffect(tr("Damage negated"), toNearbyIntString(damage_negate * 100.0f) + "%");
                        }
                    }
                    break;
                case ShipSystem::Type::DockingBay:
                    addSystemEffect(tr("docking", "Docking bay effectiveness"), toNearbyIntString(effectiveness * 100.0f) + "%");
                    break;
                case ShipSystem::Type::Sensors:
                    {
                        // Show drone control range only if DroneController
                        // component is present.
                        if (auto dc = my_spaceship.getComponent<DroneController>())
                        {
                            const float drone_control_range = dc->control_range;
                            addSystemEffect(tr("sensors", "Drone control range"), string(drone_control_range * effectiveness / 1000.0f, 1) + "U");
                        }

                        if (auto lrr = my_spaceship.getComponent<LongRangeRadar>())
                        {
                            addSystemEffect(tr("sensors", "Short-range radar range"), string(sensorsScaleShortRange(lrr->short_range, effectiveness) / 1000.0f, 1) + "U");
                            addSystemEffect(tr("sensors", "Long-range radar range"), string(sensorsScaleLongRange(lrr->long_range, effectiveness) / 1000.0f, 1) + "U");
                        }

                        if (my_spaceship.hasComponent<ScanProbeLauncher>())
                            addSystemEffect(tr("sensors", "Probe radar range"), string(sensorsScaleShortRange(5000.0f, effectiveness) / 1000.0f, 1) + "U");

                        addSystemEffect(tr("sensors", "Scan lock sensitivity"), toNearbyIntString(effectiveness * 100.0f) + "%");
                        {
                            string delay_str = effectiveness > 0.01f ? string(2.0f / effectiveness, 1) : string("∞");
                            addSystemEffect(tr("sensors", "Scan lock delay"), tr("sensors", "{delay} sec.").format({{"delay", delay_str}}));
                        }
                    }
                    break;
                default:
                    break;
                }

                // Hide all effects to start.
                for (size_t idx = system_effects_index; idx < system_effects.size(); idx++)
                    system_effects[idx]->hide();
            }
        }
    }
    GuiOverlay::onDraw(renderer);
}

void EngineeringScreen::onUpdate()
{
    if (!my_spaceship || !isVisible()) return;

    auto reactor = my_spaceship.getComponent<Reactor>();
    auto coolant = my_spaceship.getComponent<Coolant>();

    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        if (keys.engineering_select_system[n].isDiscreteStepDown()) selectSystem(static_cast<ShipSystem::Type>(n));

        float set_value = keys.engineering_set_power_for_system[n].getAxis0Value() * 3.0f;
        auto sys = ShipSystem::get(my_spaceship, static_cast<ShipSystem::Type>(n));

        // Set system power request.
        if (sys && set_value != sys->power_request && (set_value != 0.0f || set_power_active[n]))
        {
            // Cap set_value to 100% if the ship lacks both Reactor and
            // Coolant components. Otherwise, overpowering the system is
            // free. In this situation there's also no benefit to
            // underpowering the system, but some scenarios still use power
            // assignment as a feature.
            if (!reactor && !coolant) set_value = std::clamp(set_value, 0.0f, 1.0f);

            // Set the system power request.
            my_player_info->commandSetSystemPowerRequest(static_cast<ShipSystem::Type>(n), set_value);
            // Make sure the next update is sent, even if it is back to zero.
            set_power_active[n] = set_value != 0.0f;
        }

        float axis1_value = keys.engineering_set_power_for_system[n].getAxis1Value();
        if (sys && (axis1_value != 0.0f || set_power_axis1_active[n]))
        {
            float axis1_set = (axis1_value + 1.0f) / 2.0f * 3.0f;
            if (axis1_set != sys->power_request)
                my_player_info->commandSetSystemPowerRequest(static_cast<ShipSystem::Type>(n), axis1_set);
            set_power_axis1_active[n] = axis1_value != 0.0f;
        }

        if (coolant)
        {
            set_value = keys.engineering_set_coolant_for_system[n].getAxis0Value() * coolant->max_coolant_per_system;
            if (sys && set_value != sys->coolant_request && (set_value != 0.0f || set_coolant_active[n]))
            {
                my_player_info->commandSetSystemCoolantRequest(static_cast<ShipSystem::Type>(n), set_value);
                // Make sure the next update is sent, even if it is back to zero.
                set_coolant_active[n] = set_value != 0.0f;
            }
        }
    }

    int navigate_system = keys.engineering_select_system_next.isDiscreteStepDown() - keys.engineering_select_system_prev.isDiscreteStepDown(); // +1 or -1
    select_system_accum += (keys.engineering_select_system_next.getContinuousValue() - keys.engineering_select_system_prev.getContinuousValue()) * 0.1f;
    if (select_system_accum >= 1.0f) { navigate_system++; select_system_accum -= 1.0f; }
    else if (select_system_accum <= -1.0f) { navigate_system--; select_system_accum += 1.0f; }

    if (navigate_system)
    {
        int n = static_cast<int>(selected_system);
        ShipSystem::Type sys = ShipSystem::Type::None;
        do
        {
            n = (n + navigate_system) % ShipSystem::COUNT;
            if (n < 0) n = ShipSystem::COUNT -1;
            sys = static_cast<ShipSystem::Type>(n);
        } while (ShipSystem::get(my_spaceship, sys) == nullptr); // endless loop if ship does not have any system!
        selectSystem(sys);
    }

    if (selected_system != ShipSystem::Type::None)
    {
        // Note the code duplication with extra/powerManagement
        if (keys.engineering_set_power_000.isDiscreteStepDown())
        {
            power_slider->setValue(0.0f);
            my_player_info->commandSetSystemPowerRequest(selected_system, power_slider->getValue());
        }
        if (keys.engineering_set_power_030.isDiscreteStepDown())
        {
            power_slider->setValue(0.3f);
            my_player_info->commandSetSystemPowerRequest(selected_system, power_slider->getValue());
        }
        if (keys.engineering_set_power_050.isDiscreteStepDown())
        {
            power_slider->setValue(0.5f);
            my_player_info->commandSetSystemPowerRequest(selected_system, power_slider->getValue());
        }
        if (keys.engineering_set_power_100.isDiscreteStepDown())
        {
            power_slider->setValue(1.0f);
            my_player_info->commandSetSystemPowerRequest(selected_system, power_slider->getValue());
        }
        if (keys.engineering_set_power_150.isDiscreteStepDown())
        {
            power_slider->setValue(1.5f);
            my_player_info->commandSetSystemPowerRequest(selected_system, power_slider->getValue());
        }
        if (keys.engineering_set_power_200.isDiscreteStepDown())
        {
            power_slider->setValue(2.0f);
            my_player_info->commandSetSystemPowerRequest(selected_system, power_slider->getValue());
        }
        if (keys.engineering_set_power_250.isDiscreteStepDown())
        {
            power_slider->setValue(2.5f);
            my_player_info->commandSetSystemPowerRequest(selected_system, power_slider->getValue());
        }
        if (keys.engineering_set_power_300.isDiscreteStepDown())
        {
            power_slider->setValue(3.0f);
            my_player_info->commandSetSystemPowerRequest(selected_system, power_slider->getValue());
        }

        auto power_adjust = (keys.engineering_increase_power.getContinuousValue() + keys.engineering_increase_power.getAxis0Value() + keys.engineering_increase_power.getAxis1Value()
            - keys.engineering_decrease_power.getContinuousValue() - keys.engineering_decrease_power.getAxis0Value() - keys.engineering_decrease_power.getAxis1Value()) * 0.1f;
        if (keys.engineering_increase_power.isDiscreteStepDown() || keys.engineering_increase_power.isRepeatReady()) power_adjust += 0.1f;
        if (keys.engineering_decrease_power.isDiscreteStepDown() || keys.engineering_decrease_power.isRepeatReady()) power_adjust -= 0.1f;
        if (power_adjust != 0.0f)
        {
            auto sys = ShipSystem::get(my_spaceship, selected_system);
            if (sys) 
            {
                power_slider->setValue(sys->power_request + power_adjust);
                my_player_info->commandSetSystemPowerRequest(selected_system, power_slider->getValue());
            }
        }

        auto coolant_adjust = (keys.engineering_increase_coolant.getContinuousValue() + keys.engineering_increase_coolant.getAxis0Value()
            - keys.engineering_decrease_coolant.getContinuousValue() - keys.engineering_decrease_coolant.getAxis0Value()) * 0.5f;
        if (keys.engineering_increase_coolant.isDiscreteStepDown() || keys.engineering_increase_coolant.isRepeatReady()) coolant_adjust += 0.5f;
        if (keys.engineering_decrease_coolant.isDiscreteStepDown() || keys.engineering_decrease_coolant.isRepeatReady()) coolant_adjust -= 0.5f;
        if (coolant_adjust != 0.0f)
        {
            auto sys = ShipSystem::get(my_spaceship, selected_system);
            if (sys) 
            {
                coolant_slider->setValue(sys->coolant_request + coolant_adjust);
                my_player_info->commandSetSystemCoolantRequest(selected_system, coolant_slider->getValue());
            }
        }

        float set_value = keys.engineering_set_power.getAxis0Value() * 3.0f;
        auto sys = ShipSystem::get(my_spaceship, selected_system);
        if (sys && set_value != sys->power_request && (set_value != 0.0f || set_power_active[static_cast<int>(selected_system)]))
        {
            my_player_info->commandSetSystemPowerRequest(selected_system, set_value);
            // Ensure the next update is sent, even if it's back to 0.
            set_power_active[static_cast<int>(selected_system)] = set_value != 0.0f;
        }

        float axis1_value = keys.engineering_set_power.getAxis1Value();
        if (sys && (axis1_value != 0.0f || set_power_axis1_active[static_cast<int>(selected_system)]))
        {
            const float axis1_set = (axis1_value + 1.0f) / 2.0f * 3.0f;
            if (axis1_set != sys->power_request)
                my_player_info->commandSetSystemPowerRequest(selected_system, axis1_set);
            set_power_axis1_active[static_cast<int>(selected_system)] = axis1_value != 0.0f;
        }

        if (coolant && sys)
        {
            set_value = keys.engineering_set_coolant.getAxis0Value() * coolant->max_coolant_per_system;
            if (set_value != sys->coolant_request && (set_value != 0.0f || set_coolant_active[static_cast<int>(selected_system)]))
            {
                my_player_info->commandSetSystemCoolantRequest(selected_system, set_value);
                set_coolant_active[static_cast<int>(selected_system)] = set_value != 0.0f; //Make sure the next update is send, even if it is back to zero.
            }
            float axis1_coolant_value = keys.engineering_set_coolant.getAxis1Value();
            if (axis1_coolant_value != 0.0f || set_coolant_axis1_active)
            {
                const float axis1_coolant_set = (axis1_coolant_value + 1.0f) / 2.0f * coolant->max_coolant_per_system;
                if (axis1_coolant_set != sys->coolant_request)
                    my_player_info->commandSetSystemCoolantRequest(selected_system, axis1_coolant_set);
                set_coolant_axis1_active = axis1_coolant_value != 0.0f;
            }
        }
    }
}

void EngineeringScreen::selectSystem(ShipSystem::Type system)
{
    if (!my_spaceship || !ShipSystem::get(my_spaceship, system))
        return;

    for(int idx=0; idx<ShipSystem::COUNT; idx++)
    {
        system_rows[idx].button->setValue(ShipSystem::Type(idx) == system);
    }
    selected_system = system;
    power_slider->enable();
    if (my_spaceship)
    {
        auto sys = ShipSystem::get(my_spaceship, system);
        if (sys) {
            power_slider->setValue(sys->power_request);
            coolant_slider->setValue(sys->coolant_request);
        }
    }
}

void EngineeringScreen::addSystemEffect(string key, string value)
{
    if (system_effects_index == system_effects.size())
    {
        GuiKeyValueDisplay* item = new GuiKeyValueDisplay(system_effects_container, "", 0.7f, key, value);
        item
            ->setTextSize(20.0f)
            ->setSize(GuiElement::GuiSizeMax, 40.0f);
        system_effects.push_back(item);
    }
    else
    {
        system_effects[system_effects_index]->setKey(key);
        system_effects[system_effects_index]->setValue(value);
        system_effects[system_effects_index]->show();
    }

    system_effects_index++;
}

string EngineeringScreen::toNearbyIntString(float value)
{
    return string(int(nearbyint(value)));
}
