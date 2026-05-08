#include "targetAnalysisScreen.h"
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "i18n.h"
#include "featureDefs.h"
#include "vectorUtils.h"

#include "components/radar.h"
#include "components/target.h"
#include "components/hull.h"
#include "components/shields.h"
#include "components/faction.h"
#include "components/scanning.h"
#include "components/name.h"
#include "components/beamweapon.h"
#include "components/collision.h"
#include "components/docking.h"

#include "screenComponents/rotatingModelView.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/frequencyCurve.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/globalMessage.h"
#include "screenComponents/signalQualityIndicator.h"

#include "random.h"

#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"
#include "gui/gui2_scrolltext.h"

TargetAnalysisScreen::TargetAnalysisScreen(GuiContainer* owner)
: GuiOverlay(owner, "TARGET_ANALYSIS_SCREEN", GuiTheme::getColor("background"))
{
    (new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255,255,255,255}))
        ->setTextureTiledThemed("background.crosses");

    (new AlertLevelOverlay(this));

    no_target_label = new GuiLabel(this, "NO_TARGET_LABEL", tr("No target linked"), 30.0f);
    no_target_label
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(400.0f, 50.0f)
        ->hide();

    auto columns_container = new GuiElement(this, "");
    columns_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");
    columns_container
        ->setAttribute("padding", "20");

    left_column = new GuiElement(columns_container, "LEFT_COLUMN");
    left_column
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    center_column = new GuiElement(columns_container, "CENTER_COLUMN");
    center_column
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    center_column
        ->setAttribute("margin", "20, 0");

    right_column = new GuiElement(columns_container, "RIGHT_COLUMN");
    right_column
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    basic_info_section = new GuiElement(left_column, "BASIC_INFO_SECTION");
    basic_info_section
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    info_callsign = new GuiKeyValueDisplay(basic_info_section, "INFO_CALLSIGN", 0.4f, tr("analysis", "Callsign"), "-");
    info_callsign->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_distance = new GuiKeyValueDisplay(basic_info_section, "INFO_DISTANCE", 0.4f, tr("analysis", "Distance"), "-");
    info_distance->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_bearing = new GuiKeyValueDisplay(basic_info_section, "INFO_BEARING", 0.4f, tr("analysis", "Bearing"), "-");
    info_bearing->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_relspeed = new GuiKeyValueDisplay(basic_info_section, "INFO_RELSPEED", 0.4f, tr("analysis", "Rel. Speed"), "-");
    info_relspeed->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_faction = new GuiKeyValueDisplay(basic_info_section, "INFO_FACTION", 0.4f, tr("analysis", "Faction"), "-");
    info_faction->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_type = new GuiKeyValueDisplay(basic_info_section, "INFO_TYPE", 0.4f, tr("analysis", "Type"), "-");
    info_type->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_hull = new GuiKeyValueDisplay(basic_info_section, "INFO_HULL", 0.4f, tr("analysis", "Hull"), "-");
    info_hull->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_shields = new GuiKeyValueDisplay(basic_info_section, "INFO_SHIELDS", 0.4f, tr("analysis", "Shields"), "-");
    info_shields->setSize(GuiElement::GuiSizeMax, 30.0f);

    description_section = new GuiElement(left_column, "DESCRIPTION_SECTION");
    description_section
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    info_description = new GuiScrollFormattedText(description_section, "INFO_DESC", "");
    info_description
        ->setTextSize(28.0f)
        ->setMargins(10.0f, 0.0f, 0.0f, 0.0f)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    model_view = new GuiRotatingModelView(center_column, "TARGET_MODEL_VIEW", target_entity);
    model_view
        ->setSize(GuiElement::GuiSizeMax, 300.0f);

    core_info_section = new GuiElement(center_column, "CORE_INFO_SECTION");
    core_info_section
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    info_class = new GuiKeyValueDisplay(core_info_section, "INFO_CLASS", 0.4f, tr("analysis", "Class"), "-");
    info_class->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_subclass = new GuiKeyValueDisplay(core_info_section, "INFO_SUBCLASS", 0.4f, tr("analysis", "Subclass"), "-");
    info_subclass->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_size = new GuiKeyValueDisplay(core_info_section, "INFO_SIZE", 0.4f, tr("analysis", "Size"), "-");
    info_size->setSize(GuiElement::GuiSizeMax, 30.0f);

    systems_section = new GuiElement(center_column, "SYSTEMS_SECTION");
    systems_section
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        info_system[n] = new GuiKeyValueDisplay(systems_section, "INFO_SYSTEM_" + string(n), 0.75f, getLocaleSystemName(ShipSystem::Type(n)), "-");
        info_system[n]->setSize(GuiElement::GuiSizeMax, 25.0f)->hide();
    }

    frequencies_section = new GuiElement(right_column, "FREQUENCIES_SECTION");
    frequencies_section
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    if (gameGlobalInfo->use_beam_shield_frequencies)
    {
        info_shield_frequency = new GuiFrequencyCurve(frequencies_section, "INFO_SHIELD_FREQ", GuiFrequencyCurve::FrequencyType::Other, GuiFrequencyCurve::DamageEffect::Positive);
        info_shield_frequency->setSize(GuiElement::GuiSizeMax, 80.0f);
        info_beam_frequency = new GuiFrequencyCurve(frequencies_section, "INFO_BEAM_FREQ", GuiFrequencyCurve::FrequencyType::Beam, GuiFrequencyCurve::DamageEffect::Negative);
        info_beam_frequency->setSize(GuiElement::GuiSizeMax, 80.0f);
    }
    else
    {
        info_shield_frequency = nullptr;
        info_beam_frequency = nullptr;
    }

    signatures_section = new GuiElement(right_column, "SIGNATURES_SECTION");
    signatures_section
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    info_electrical_signal_band = new GuiSignalQualityIndicator(signatures_section, "ELECTRICAL_SIGNAL");
    info_electrical_signal_band
        ->showGreen(false)
        ->showBlue(false)
        ->setSize(GuiElement::GuiSizeMax, 80.0f);
    info_electrical_signal_label = new GuiLabel(info_electrical_signal_band, "", tr("Electrical"), 30.0f);
    info_electrical_signal_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    info_gravitational_signal_band = new GuiSignalQualityIndicator(signatures_section, "GRAVITY_SIGNAL");
    info_gravitational_signal_band
        ->showRed(false)
        ->showBlue(false)
        ->setSize(GuiElement::GuiSizeMax, 80.0f);
    info_gravitational_signal_label = new GuiLabel(info_gravitational_signal_band, "", tr("Gravitational"), 30.0f);
    info_gravitational_signal_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    info_thermal_signal_band = new GuiSignalQualityIndicator(signatures_section, "THERMAL_SIGNAL");
    info_thermal_signal_band
        ->showRed(false)
        ->showGreen(false)
        ->setSize(GuiElement::GuiSizeMax, 80.0f);
    info_thermal_signal_label = new GuiLabel(info_thermal_signal_band, "", "Thermal", 30.0f);
    info_thermal_signal_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    (new GuiCustomShipFunctions(this, CrewPosition::scienceOfficer, ""))
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, 200.0f);

    (new GuiGlobalMessage(this))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
}

void TargetAnalysisScreen::onDraw(sp::RenderTarget& renderer)
{
    if (my_spaceship)
    {
        if (auto tg = my_spaceship.getComponent<Target>())
            targets.set(tg->entity);
        else
            targets.set(sp::ecs::Entity{});
    }

    info_callsign->setValue("-");
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

    auto target = targets.get();
    if (target)
    {
        target_entity = target;
        no_target_label->hide();
        model_view->show();

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
            info_callsign->setValue(cs->callsign);

        auto scanstate_component = target.getComponent<ScanState>();
        auto scanstate = scanstate_component ? scanstate_component->getStateFor(my_spaceship) : ScanState::State::FullScan;

        string description = "";

        if (auto sd = target.getComponent<ScienceDescription>())
        {
            switch (scanstate)
            {
            case ScanState::State::NotScanned: description = sd->not_scanned; break;
            case ScanState::State::FriendOrFoeIdentified: description = sd->friend_or_foe_identified; break;
            case ScanState::State::SimpleScan: description = sd->simple_scan; break;
            case ScanState::State::FullScan: description = sd->full_scan; break;
            }
        }

        if (!description.empty())
            info_description->setText(description);
        else
            info_description->setText(tr("No description available."));

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
                float size = glm::max(physics->getSize().x, physics->getSize().y);
                info_size->setValue(string(static_cast<int>(size)));
            }
        }

        if (scanstate >= ScanState::State::FullScan)
        {
            if (gameGlobalInfo->use_beam_shield_frequencies && info_shield_frequency)
            {
                auto shieldsystem = target.getComponent<Shields>();
                info_shield_frequency->setFrequency(shieldsystem ? shieldsystem->frequency : -1);
                info_shield_frequency->setEnemyHasEquipment(shieldsystem);
                auto beamsystem = target.getComponent<BeamWeaponSys>();
                info_beam_frequency->setFrequency(beamsystem ? beamsystem->frequency : -1);
                info_beam_frequency->setEnemyHasEquipment(beamsystem);
            }

            for (int n = 0; n < ShipSystem::COUNT; n++)
            {
                auto sys = ShipSystem::get(target, ShipSystem::Type(n));
                if (sys)
                {
                    float health = sys->health;
                    info_system[n]
                        ->setValue(string(int(health * 100.0f)) + "%")
                        ->setBackColor(glm::u8vec4(255, uint8_t(127.5f * (health + 1)), uint8_t(127.5f * (health + 1)), 255))
                        ->show();
                }
            }

            float signal = 0.0f;
            float electrical = 0.0f;
            float gravitational = 0.0f;
            float thermal = 0.0f;

            if (auto info = target.getComponent<RawRadarSignatureInfo>())
            {
                float distance_variance = 0.0f;
                auto lrr = my_spaceship.getComponent<LongRangeRadar>();

                if (lrr && distance > lrr->short_range && scanstate < ScanState::State::FullScan)
                    distance_variance = (random(0.01f, (distance - lrr->short_range)) / (lrr->long_range - lrr->short_range)) * 0.1f;

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

            signal = electrical;
            info_electrical_signal_band
                ->setMaxAmp(signal)
                ->setNoiseError(std::max(0.0f, (signal - 1.0f) * 0.1f));
            info_electrical_signal_label->setText(tr("Electrical: {signal} MJ").format({
                {"signal", string(signal)}
            }));

            signal = thermal;
            info_thermal_signal_band
                ->setMaxAmp(signal)
                ->setPhaseError(std::max(0.0f, (signal - 1.0f) * 0.1f));
            info_thermal_signal_label->setText(tr("Thermal: {signal} um").format({
                {"signal", string(signal)}
            }));

            signal = gravitational;
            info_gravitational_signal_band
                ->setMaxAmp(signal)
                ->setPeriodError(std::max(0.0f, (signal - 1.0f) * 0.1f));
            info_gravitational_signal_label->setText(tr("Gravitational: {signal} dN").format({
                {"signal", string(signal)}
            }));
        }
    }
    else
    {
        target_entity = {};
        no_target_label->show();
        model_view->hide();
    }

    GuiOverlay::onDraw(renderer);
}
