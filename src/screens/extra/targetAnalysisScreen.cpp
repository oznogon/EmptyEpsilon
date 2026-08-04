#include "targetAnalysisScreen.h"
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "i18n.h"
#include "featureDefs.h"
#include "vectorUtils.h"

#include "components/beamweapon.h"
#include "components/collision.h"
#include "components/docking.h"
#include "components/faction.h"
#include "components/hull.h"
#include "components/name.h"
#include "components/radar.h"
#include "components/drone.h"
#include "components/analysisTarget.h"
#include "components/scanning.h"
#include "components/shields.h"
#include "components/target.h"

#include "screenComponents/alertOverlay.h"
// #include "screenComponents/customShipFunctions.h"
#include "screenComponents/frequencyCurve.h"
#include "screenComponents/globalMessage.h"
#include "screenComponents/rotatingModelView.h"
#include "screenComponents/signalQualityIndicator.h"

#include "random.h"

#include "gui/theme.h"
#include "gui/gui2_button.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"
#include "gui/gui2_scrolltextcontainer.h"

TargetAnalysisScreen::TargetAnalysisScreen(GuiContainer* owner)
: GuiOverlay(owner, "TARGET_ANALYSIS_SCREEN", GuiTheme::getColor("background"))
{
    // Render the background decorations.
    (new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    // Render the alert level color overlay.
    new AlertLevelOverlay(this);

    // Message if entity lacks a linked target.
    no_target_label = new GuiLabel(this, "NO_TARGET_LABEL", tr("target_analysis_screen", "No target linked"), 50.0f);
    no_target_label
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide();

    columns_container = new GuiElement(this, "");
    columns_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");
    columns_container
        ->setAttribute("padding", "20");

    auto left_column = new GuiElement(columns_container, "LEFT_COLUMN");
    left_column
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    auto center_column = new GuiElement(columns_container, "CENTER_COLUMN");
    center_column
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    center_column
        ->setAttribute("margin", "20, 0");

    auto right_column = new GuiElement(columns_container, "RIGHT_COLUMN");
    right_column
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    right_column
        ->setAttribute("padding", "0, 0, 120, 0");

    // Model view
    auto model_view_panel = new GuiPanel(left_column, "");
    model_view_panel
        ->setSize(GuiElement::GuiSizeMax, 360.0f)
        ->setAttribute("padding", "0, 20");
    model_view_panel
        ->setAttribute("margin", "0, 0, 0, 30");

    model_view = new GuiRotatingModelView(model_view_panel, "TARGET_MODEL_VIEW", target_entity);
    model_view
        ->setFillPercentage(0.75f)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    info_callsign = new GuiLabel(model_view_panel, "INFO_CALLSIGN", "");
    info_callsign
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopCenter)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    // Description
    description_section = new GuiElement(left_column, "DESCRIPTION_SECTION");
    description_section
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    (new GuiLabel(description_section, "DESCRIPTION_LABEL", tr("analysis", "Description")))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    info_description = new GuiScrollFormattedText(description_section, "INFO_DESC", "");
    info_description
        ->setTextSize(28.0f)
        ->setMargins(10.0f, 0.0f, 0.0f, 0.0f)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    /*
    // Custom ship functions
    (new GuiLabel(left_column, "FUNCTIONS_LABEL", tr("analysis", "Functions")))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    (new GuiCustomShipFunctions(left_column, CrewPosition::scienceOfficer, ""))
        ->setSize(GuiElement::GuiSizeMax, 200.0f);
    */

    // Center column

    // Basic information
    basic_info_section = new GuiElement(center_column, "BASIC_INFO_SECTION");
    basic_info_section
        ->setSize(GuiElement::GuiSizeMax, 60.0f + 10.0f * KV_HEIGHT)
        ->setAttribute("layout", "vertical");
    basic_info_section
        ->setAttribute("margin", "0, 0, 0, 30");

    (new GuiLabel(basic_info_section, "BASIC_INFO_LABEL", tr("analysis", "Analysis")))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    info_class = new GuiKeyValueDisplay(basic_info_section, "INFO_CLASS", KV_DIV, tr("analysis", "Class"), "-");
    info_class->setSize(GuiElement::GuiSizeMax, KV_HEIGHT);

    info_subclass = new GuiKeyValueDisplay(basic_info_section, "INFO_SUBCLASS", KV_DIV, tr("analysis", "Subclass"), "-");
    info_subclass->setSize(GuiElement::GuiSizeMax, KV_HEIGHT);

    info_type = new GuiKeyValueDisplay(basic_info_section, "INFO_TYPE", KV_DIV, tr("analysis", "Type"), "-");
    info_type->setSize(GuiElement::GuiSizeMax, KV_HEIGHT);

    info_distance = new GuiKeyValueDisplay(basic_info_section, "INFO_DISTANCE", KV_DIV, tr("analysis", "Distance"), "-");
    info_distance->setSize(GuiElement::GuiSizeMax, KV_HEIGHT);

    info_size = new GuiKeyValueDisplay(basic_info_section, "INFO_SIZE", KV_DIV, tr("analysis", "Size"), "-");
    info_size->setSize(GuiElement::GuiSizeMax, KV_HEIGHT);

    info_bearing = new GuiKeyValueDisplay(basic_info_section, "INFO_BEARING", KV_DIV, tr("analysis", "Bearing"), "-");
    info_bearing->setSize(GuiElement::GuiSizeMax, KV_HEIGHT);

    info_relspeed = new GuiKeyValueDisplay(basic_info_section, "INFO_RELSPEED", KV_DIV, tr("analysis", "Relative speed"), "-");
    info_relspeed->setSize(GuiElement::GuiSizeMax, KV_HEIGHT);

    info_faction = new GuiKeyValueDisplay(basic_info_section, "INFO_FACTION", KV_DIV, tr("analysis", "Faction"), "-");
    info_faction->setSize(GuiElement::GuiSizeMax, KV_HEIGHT);

    info_hull = new GuiKeyValueDisplay(basic_info_section, "INFO_HULL", KV_DIV, tr("analysis", "Hull"), "-");
    info_hull->setSize(GuiElement::GuiSizeMax, KV_HEIGHT);

    info_shields = new GuiKeyValueDisplay(basic_info_section, "INFO_SHIELDS", KV_DIV, tr("analysis", "Shields"), "-");
    info_shields->setSize(GuiElement::GuiSizeMax, KV_HEIGHT);

    // Systems
    systems_section = new GuiElement(center_column, "SYSTEMS_SECTION");
    systems_section
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    (new GuiLabel(systems_section, "SYSTEMS_LABEL", tr("analysis", "Systems status")))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        info_system[n] = new GuiKeyValueDisplay(systems_section, "INFO_SYSTEM_" + string(n), KV_DIV, getLocaleSystemName(ShipSystem::Type(n)), "-");
        info_system[n]
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->hide();
    }

    // Right column

    // Frequencies
    frequencies_section = new GuiElement(right_column, "FREQUENCIES_SECTION");
    frequencies_section
        ->setSize(GuiElement::GuiSizeMax, 60.0f + 2.0f * (KV_HEIGHT * 4.0f))
        ->setAttribute("layout", "vertical");
    frequencies_section
        ->setAttribute("margin", "0, 0, 0, 30");

    (new GuiLabel(frequencies_section, "FREQUENCIES_LABEL", tr("analysis", "Frequencies")))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    if (gameGlobalInfo->use_beam_shield_frequencies)
    {
        info_shield_frequency = new GuiFrequencyCurve(frequencies_section, "INFO_SHIELD_FREQ", GuiFrequencyCurve::FrequencyType::Other, GuiFrequencyCurve::DamageEffect::Positive);
        info_shield_frequency->setSize(GuiElement::GuiSizeMax, KV_HEIGHT * 4.0f);
        info_beam_frequency = new GuiFrequencyCurve(frequencies_section, "INFO_BEAM_FREQ", GuiFrequencyCurve::FrequencyType::Beam, GuiFrequencyCurve::DamageEffect::Negative);
        info_beam_frequency->setSize(GuiElement::GuiSizeMax, KV_HEIGHT * 4.0f);
    }
    else
    {
        info_shield_frequency = nullptr;
        info_beam_frequency = nullptr;
    }

    // Radar signatures
    signatures_section = new GuiElement(right_column, "SIGNATURES_SECTION");
    signatures_section
        ->setSize(GuiElement::GuiSizeMax, 60.0f + 3.0f * (KV_HEIGHT * 3.0f))
        ->setAttribute("layout", "vertical");
    signatures_section
        ->setAttribute("margin", "0, 0, 0, 30");

    (new GuiLabel(signatures_section, "SIGNATURES_LABEL", tr("analysis", "Radar signatures")))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    info_electrical_signal_band = new GuiSignalQualityIndicator(signatures_section, "ELECTRICAL_SIGNAL");
    info_electrical_signal_band
        ->showGreen(false)
        ->showBlue(false)
        ->setSize(GuiElement::GuiSizeMax, KV_HEIGHT * 3.0f);
    info_electrical_signal_label = new GuiLabel(info_electrical_signal_band, "", tr("Electrical"));
    info_electrical_signal_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    info_electrical_signal_band->addModeButton();

    info_gravitational_signal_band = new GuiSignalQualityIndicator(signatures_section, "GRAVITY_SIGNAL");
    info_gravitational_signal_band
        ->showRed(false)
        ->showGreen(false)
        ->setSize(GuiElement::GuiSizeMax, KV_HEIGHT * 3.0f);
    info_gravitational_signal_label = new GuiLabel(info_gravitational_signal_band, "", tr("Gravitational"));
    info_gravitational_signal_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    info_gravitational_signal_band->addModeButton();

    info_thermal_signal_band = new GuiSignalQualityIndicator(signatures_section, "THERMAL_SIGNAL");
    info_thermal_signal_band
        ->showRed(false)
        ->showBlue(false)
        ->setSize(GuiElement::GuiSizeMax, KV_HEIGHT * 3.0f);
    info_thermal_signal_label = new GuiLabel(info_thermal_signal_band, "", tr("Thermal"));
    info_thermal_signal_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    info_thermal_signal_band->addModeButton();

    // Global message
    (new GuiGlobalMessage(this))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
}

void TargetAnalysisScreen::onDraw(sp::RenderTarget& renderer)
{
    if (my_spaceship)
    {
        if (auto at = my_spaceship.getComponent<AnalysisTarget>())
            targets.set(at->entity);
        else
            targets.set(sp::ecs::Entity{});
    }
    else return;

    info_callsign->setText("");
    info_distance->setValue("-");
    info_bearing->setValue("-");
    info_relspeed->setValue("-");
    info_faction->setValue("-");
    info_type->setValue("-");
    info_hull->setValue("-");
    info_shields->setValue("-");
    info_class->setValue("-");
    info_subclass->setValue("-");
    info_size->setValue("-");
    for (int n = 0; n < ShipSystem::COUNT; n++)
        info_system[n]->hide();

    auto lrr = my_spaceship.getComponent<LongRangeRadar>();

    float effective_short_range = 5000.0f;
    float effective_long_range = 30000.0f;
    if (lrr)
    {
        effective_short_range = lrr->short_range;
        effective_long_range = lrr->long_range;
        if (auto sensors = my_spaceship.getComponent<SensorsSystem>())
        {
            float eff = sensors->getSystemEffectiveness();
            effective_short_range = sensorsScaleShortRange(effective_short_range, eff);
            effective_long_range = sensorsScaleLongRange(effective_long_range, eff);
        }
    }

    auto target = targets.get();
    if (target != target_entity)
    {
        info_electrical_signal_band->clearHistory();
        info_gravitational_signal_band->clearHistory();
        info_thermal_signal_band->clearHistory();
    }

    if (target)
    {
        target_entity = target;
        no_target_label->hide();
        columns_container->show();

        auto my_transform = my_spaceship.getComponent<sp::Transform>();
        auto target_transform = target.getComponent<sp::Transform>();
        float distance = 0.0f;

        if (my_transform && target_transform)
        {
            auto diff = target_transform->getPosition() - my_transform->getPosition();
            distance = glm::length(diff);

            float heading = vec2ToAngle(diff) - 270.0f;
            while (heading < 0.0f) heading += 360.0f;

            info_distance->setValue(string(distance / 1000.0f, 1) + DISTANCE_UNIT_1K);
            info_bearing->setValue(string(static_cast<int>(heading)));

            auto my_physics = my_spaceship.getComponent<sp::Physics>();
            auto target_physics = target.getComponent<sp::Physics>();
            if (my_physics && target_physics && distance > 0.0f)
            {
                float rel_velocity = glm::dot(target_physics->getVelocity(), diff / distance) - glm::dot(my_physics->getVelocity(), diff / distance);
                if (std::abs(rel_velocity) < 0.01f)
                    rel_velocity = 0.0f;
                info_relspeed->setValue(string(rel_velocity / 1000.0f * 60.0f, 1) + DISTANCE_UNIT_1K + "/min");
            }
        }

        if (auto cs = target.getComponent<CallSign>())
            info_callsign->setText(cs->callsign);

        auto scanstate_component = target.getComponent<ScanState>();
        auto scanstate = scanstate_component ? scanstate_component->getStateFor(my_spaceship) : ScanState::State::FullScan;

        string description = "";
        bool has_description_component = false;

        if (auto sd = target.getComponent<ScienceDescription>())
        {
            has_description_component = true;
            switch (scanstate)
            {
            case ScanState::State::NotScanned: description = sd->not_scanned; break;
            case ScanState::State::FriendOrFoeIdentified: description = sd->friend_or_foe_identified; break;
            case ScanState::State::SimpleScan: description = sd->simple_scan; break;
            case ScanState::State::FullScan: description = sd->full_scan; break;
            }
        }

        if (description.empty())
        {
            if (scanstate < ScanState::State::FullScan && has_description_component)
                description = tr("analysis", "Description requires full scan.");
            else
                description = tr("No description available.");
        }
        info_description->setText(description);

        // Hide 3D model if type isn't identified and entity is > 5U away.
        model_view->setVisible((lrr && distance < effective_short_range) || scanstate > ScanState::State::SimpleScan);

        float electrical = 0.0f;
        float gravitational = 0.0f;
        float thermal = 0.0f;

        if (auto info = target.getComponent<RawRadarSignatureInfo>())
        {
            float distance_variance = 0.0f;

            if (lrr && distance > effective_short_range && scanstate < ScanState::State::FullScan)
                distance_variance = (random(0.01f, (distance - effective_short_range)) / (effective_long_range - effective_short_range)) * 0.1f;

            electrical = std::max(0.0f, info->electrical - distance_variance);
            gravitational = std::max(0.0f, info->gravitational - distance_variance);
            thermal = std::max(0.0f, info->thermal - distance_variance);

            if (auto dynamic_info = target.getComponent<DynamicRadarSignatureInfo>())
            {
                electrical = std::max(0.0f, electrical + dynamic_info->electrical);
                gravitational = std::max(0.0f, gravitational + dynamic_info->gravitational);
                thermal = std::max(0.0f, thermal + dynamic_info->thermal);
            }
        }

        info_electrical_signal_band
            ->setMaxAmp(electrical)
            ->setNoiseError(std::max(0.0f, (electrical - 1.0f) * 0.1f));
        info_electrical_signal_label->setText(tr("Electrical: {signal} MJ").format({
            {"signal", string(electrical)}
        }));

        info_thermal_signal_band
            ->setMaxAmp(thermal)
            ->setPhaseError(std::max(0.0f, (thermal - 1.0f) * 0.1f));
        info_thermal_signal_label->setText(tr("Thermal: {signal} um").format({
            {"signal", string(thermal)}
        }));

        info_gravitational_signal_band
            ->setMaxAmp(gravitational)
            ->setPeriodError(std::max(0.0f, (gravitational - 1.0f) * 0.1f));
        info_gravitational_signal_label->setText(tr("Gravitational: {signal} dN").format({
            {"signal", string(gravitational)}
        }));

        if (scanstate >= ScanState::State::SimpleScan)
        {
            auto faction = Faction::getInfo(target);
            info_faction->setValue(faction.locale_name);

            if (auto tn = target.getComponent<TypeName>())
                info_type->setValue(tn->localized);

            if (auto hull = target.getComponent<Hull>())
                info_hull->setValue(string(static_cast<int>(ceil(hull->current))) + "/" + string(static_cast<int>(ceil(hull->max))));

            if (auto shields = target.getComponent<Shields>())
            {
                string str = "";
                for (size_t i = 0; i < shields->entries.size(); i++)
                {
                    if (i > 0) str += "/";
                    str += string(static_cast<int>(shields->entries[i].level));
                }
                info_shields->setValue(str);
            }

            if (auto docking_port = target.getComponent<DockingPort>())
            {
                if (!docking_port->dock_class.empty())
                    info_class->setValue(docking_port->dock_class);
                if (!docking_port->dock_subclass.empty())
                    info_subclass->setValue(docking_port->dock_subclass);
            }

            if (auto physics = target.getComponent<sp::Physics>())
            {
                info_size->setValue(string(static_cast<int>(glm::max(physics->getSize().x, physics->getSize().y))));
            }
        }

        if (gameGlobalInfo->use_beam_shield_frequencies && info_shield_frequency)
        {
            bool fully_scanned = scanstate >= ScanState::State::FullScan;
            info_shield_frequency->setScanned(fully_scanned);
            info_beam_frequency->setScanned(fully_scanned);
            if (fully_scanned)
            {
                auto shields_system = target.getComponent<Shields>();
                info_shield_frequency
                    ->setFrequency(shields_system ? shields_system->frequency : -1)
                    ->setEnemyHasEquipment(!!shields_system);
                auto beam_system = target.getComponent<BeamWeaponSys>();
                info_beam_frequency
                    ->setFrequency(beam_system ? beam_system->frequency : -1)
                    ->setEnemyHasEquipment(!!beam_system);
            }
            else
            {
                info_shield_frequency
                    ->setFrequency(-1)
                    ->setEnemyHasEquipment(false);
                info_beam_frequency
                    ->setFrequency(-1)
                    ->setEnemyHasEquipment(false);
            }
        }

        for (int n = 0; n < ShipSystem::COUNT; n++)
        {
            auto sys = ShipSystem::get(target, ShipSystem::Type(n));
            if (scanstate < ScanState::State::FullScan)
            {
                info_system[n]
                    ->setValue(tr("analysis", "?"))
                    ->setBackColor(glm::u8vec4{128, 128, 128, 255})
                    ->disable()
                    ->show();
            }
            else if (sys)
            {
                float health = sys->health;
                info_system[n]
                    ->setValue(string(static_cast<int>(health * 100.0f)) + "%")
                    ->setBackColor(glm::u8vec4(255, static_cast<uint8_t>(127.5f * (health + 1.0f)), static_cast<uint8_t>(127.5f * (health + 1.0f)), 255))
                    ->enable()
                    ->show();
            }
            else
            {
                info_system[n]
                    ->setValue(tr("analysis", "-"))
                    ->setBackColor(glm::u8vec4{64, 64, 64, 255})
                    ->disable()
                    ->show();
            }
        }
    }
    else
    {
        target_entity = {};
        no_target_label->show();
        columns_container->hide();
    }

    GuiOverlay::onDraw(renderer);
}
