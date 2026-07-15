#include "limitedGameMasterScreen.h"
#include "i18n.h"
#include "main.h"
#include "vectorUtils.h"
#include "multiplayer_server.h"
#include "gameGlobalInfo.h"
#include "globalMessageEntryView.h"
#include "chatDialog.h"

#include "GMActions.h"
#include "playerInfo.h"
#include "ecs/query.h"
#include "components/ai.h"
#include "components/radar.h"
#include "components/faction.h"
#include "components/collision.h"
#include "components/gravity.h"
#include "components/hull.h"
#include "components/shields.h"
#include "components/comms.h"
#include "components/player.h"
#include "components/name.h"
#include "components/multiplayer.h"
#include "components/docking.h"
#include "components/beamweapon.h"
#include "components/missiletubes.h"
#include "components/reactor.h"
#include "components/impulse.h"
#include "components/maneuveringthrusters.h"
#include "components/warpdrive.h"
#include "components/jumpdrive.h"
#include "components/lifetime.h"
#include "components/scanning.h"
#include "components/selfdestruct.h"
#include "components/spin.h"
#include "components/target.h"
#include "components/rendering.h"
#include "systems/collision.h"

#include "screenComponents/radarView.h"
#include "screenComponents/radarZoomSlider.h"
#include "screenComponents/helpOverlay.h"

#include "gui/mouseRenderer.h"
#include "gui/gui2_togglebutton.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_listbox.h"
#include "gui/gui2_label.h"
#include "gui/gui2_panel.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_textentry.h"
#include "gui/gui2_tooltip.h"
#include "gui/gui2_scrollcontainer.h"

static std::vector<std::pair<string, string>> getGMInfo(sp::ecs::Entity entity)
{
    std::vector<std::pair<string, string>> result;
    if (auto cs = entity.getComponent<CallSign>())
        result.emplace_back(trMark("gm_info", "Callsign"), cs->callsign);
    if (entity.hasComponent<Faction>())
        result.emplace_back(trMark("gm_info", "Faction"), Faction::getInfo(entity).locale_name);
    if (auto tn = entity.getComponent<TypeName>())
        result.emplace_back(trMark("gm_info", "Type"), tn->localized);
    if (auto shields = entity.getComponent<Shields>())
        for (size_t n = 0; n < shields->entries.size(); n++)
            result.emplace_back(trMark("gm_info", "Shield {n}").format({{"n", string(static_cast<int>(n) + 1)}}), string(shields->entries[n].level) + "/" + string(shields->entries[n].max));
    if (auto hull = entity.getComponent<Hull>())
        result.emplace_back(trMark("gm_info", "Hull"), string(hull->current) + "/" + string(hull->max));
    return result;
}

class LimitedGuiEntityTweak : public GuiPanel
{
public:
    LimitedGuiEntityTweak(GuiContainer* owner, std::function<void(sp::ecs::Entity, const string&)> script_runner)
    : GuiPanel(owner, "LIMITED_TWEAK_DIALOG"), script_runner(script_runner)
    {
        setPosition(0.0f, -100.0f, sp::Alignment::BottomCenter);
        setSize(GuiElement::GuiSizeMax, 700.0f);
        setAttribute("padding", "20");
        setAttribute("margin", "50, 0");

        auto content = new GuiElement(this, "");
        content
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
            ->setAttribute("layout", "horizontal");

        auto left_panel = new GuiElement(content, "");
        left_panel
            ->setSize(300.0f, GuiElement::GuiSizeMax)
            ->setAttribute("layout", "vertical");

        component_list = new GuiListbox(left_panel, "", [this](int index, string value)
        {
            for (auto& page : visible_pages) page->page->hide();
            if (index >= 0 && index < static_cast<int>(visible_pages.size()))
            {
                visible_pages[index]->page->show();
                component_description->setText(visible_pages[index]->description);
            }
        });
        component_list->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        middle_container = new GuiElement(content, "");
        middle_container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        component_description = new GuiScrollFormattedText(content, "COMPONENT_DESC", "");
        component_description
            ->setTextSize(26.0f)
            ->setSize(300.0f, GuiElement::GuiSizeMax)
            ->setAttribute("margin", "0, 0, 20, 0");

        createTransformPage();
        createPhysicsPage();
        createCallSignPage();
        createFactionPage();
        createHullPage();
        createShieldsPage();
        createAIPage();
        createBeamWeaponsPage();
        createMissileTubesPage();
        createReactorPage();
        createImpulsePage();
        createManeuveringPage();
        createWarpDrivePage();
        createJumpDrivePage();
        createCommsPage();
        createDockingPage();
        createLifetimePage();
        createSpinPage();
        createSelfDestructPage();
        createMeshRenderPage();

        (new GuiButton(this, "TWEAK_CLOSE", tr("button", "Close"),
            [this]() { hide(); }))
            ->setTextSize(20.0f)
            ->setPosition(10.0f, -20.0f, sp::Alignment::TopRight)
            ->setSize(70.0f, 30.0f);
    }

    void open(sp::ecs::Entity target)
    {
        entity = target;
        visible_pages.clear();
        component_list->setOptions({});
        component_description->setText("");

        for (auto& page : pages)
        {
            if (page.has_component(entity))
            {
                component_list->addEntry(page.label, page.label);
                visible_pages.push_back(&page);
                for (auto& fn : page.update_funcs) fn();
            }
            page.page->hide();
        }

        if (!visible_pages.empty())
        {
            component_list->setSelectionIndex(0);
            visible_pages[0]->page->show();
            component_description->setText(visible_pages[0]->description);
        }
    }

    void setDragActive(bool active) { drag_active = active; }

    virtual void onUpdate() override
    {
        if (entity && !drag_active)
        {
            for (auto& page : visible_pages)
                for (auto& fn : page->update_funcs) fn();
        }
        GuiPanel::onUpdate();
    }
private:
    sp::ecs::Entity entity;
    std::function<void(sp::ecs::Entity, const string&)> script_runner;
    bool drag_active = false;

    GuiListbox* component_list;
    GuiScrollFormattedText* component_description;
    GuiElement* middle_container;

    struct PageInfo
    {
        string label;
        string description;
        std::function<bool(sp::ecs::Entity)> has_component;
        GuiElement* page;
        std::vector<std::function<void()>> update_funcs;
    };
    std::vector<PageInfo> pages;
    std::vector<PageInfo*> visible_pages;

    PageInfo& addPage(const string& label, std::function<bool(sp::ecs::Entity)> has_component)
    {
        auto page = new GuiScrollContainer(middle_container, "");
        page
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
            ->hide()
            ->setAttribute("layout", "vertical");
        pages.push_back({label, "", has_component, page, {}});
        return pages.back();
    }

    void addLabel(GuiElement* page, const string& text)
    {
        auto row = new GuiElement(page, "");
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal");
        (new GuiLabel(row, "", text, 20.0f))->setAlignment(sp::Alignment::Center)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    }

    void addTextTweak(GuiElement* page, const string& label, const string& lua_path, std::function<string()> getter, std::vector<std::function<void()>>& update_funcs)
    {
        auto row = new GuiElement(page, "");
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal");
        (new GuiLabel(row, "", label, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(100.0f, GuiElement::GuiSizeMax);

        auto entry = new GuiTextEntry(row, "", "");
        entry->setTextSize(18.0f)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        entry->callback([this, entry, lua_path](string text)
        {
            if (entity && script_runner && text.length() > 0)
            {
                string escaped;
                for (auto c : text) { if (c == '\'') escaped += "\\'"; else escaped += c; }
                script_runner(entity, lua_path + " = '" + escaped + "'");
            }
        });

        update_funcs.push_back([entry, getter]()
        {
            if (!entry->hasFocus()) entry->setText(getter());
        });
    }

    void addFloatTweak(GuiElement* page, const string& label, const string& lua_path, std::function<float()> getter, std::vector<std::function<void()>>& update_funcs)
    {
        auto row = new GuiElement(page, "");
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal");
        (new GuiLabel(row, "", label, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(100.0f, GuiElement::GuiSizeMax);

        auto entry = new GuiTextEntry(row, "", "");
        entry->setTextSize(18.0f)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        entry->callback([this, entry, lua_path](string text)
        {
            if (entity && script_runner && text.length() > 0)
                script_runner(entity, lua_path + " = " + string(text.toFloat(), 3));
        });

        update_funcs.push_back([entry, getter]()
        {
            if (!entry->hasFocus()) entry->setText(string(getter()));
        });
    }

    void addIntTweak(GuiElement* page, const string& label, const string& lua_path, std::function<int()> getter, std::vector<std::function<void()>>& update_funcs)
    {
        auto row = new GuiElement(page, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "", label, 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(100.0f, GuiElement::GuiSizeMax);

        auto entry = new GuiTextEntry(row, "", "");
        entry
            ->setTextSize(18.0f)
            ->callback(
                [this, entry, lua_path](string text)
                {
                    if (entity && script_runner && text.length() > 0)
                        script_runner(entity, lua_path + " = " + string(text.toInt()));
                }
            )
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        update_funcs.push_back([entry, getter]()
        {
            if (!entry->hasFocus()) entry->setText(string(getter(), 2));
        });
    }

    void addBoolTweak(GuiElement* page, const string& label, const string& lua_path, std::function<bool()> getter, std::vector<std::function<void()>>& update_funcs)
    {
        auto btn = new GuiToggleButton(page, "", label, [this, lua_path](bool value)
        {
            if (entity && script_runner)
                script_runner(entity, lua_path + " = " + string(value ? "true" : "false"));
        });
        btn
            ->setTextSize(20.0f)
            ->setSize(GuiElement::GuiSizeMax, 30.0f);

        update_funcs.push_back([btn, getter]()
        {
            btn->setValue(getter());
        });
    }

    void addSelectorTweak(GuiElement* page, const string& label, const string& lua_path, const std::vector<std::pair<string, string>>& options, std::function<int()> getter, std::vector<std::function<void()>>& update_funcs)
    {
        auto row = new GuiElement(page, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "", label, 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(100.0f, GuiElement::GuiSizeMax);

        auto selector = new GuiSelector(row, "",
            [this, lua_path, options](int index, string value)
            {
                if (entity && script_runner && index >= 0 && index < static_cast<int>(options.size()))
                    script_runner(entity, lua_path + " = " + options[index].second);
            }
        );
        for (auto& opt : options) selector->addEntry(opt.first, opt.first);
        selector
            ->setTextSize(18.0f)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        update_funcs.push_back([selector, getter, options]()
        {
            int idx = getter();
            if (idx >= 0 && idx < static_cast<int>(options.size()) && idx != selector->getSelectionIndex())
                selector->setSelectionIndex(idx);
        });
    }

    void addVec2Tweak(GuiElement* page, const string& label, const string& lua_path, std::function<glm::vec2()> getter, std::vector<std::function<void()>>& update_funcs)
    {
        auto row = new GuiElement(page, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "", label, 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(100.0f, GuiElement::GuiSizeMax);

        auto x_entry = new GuiTextEntry(row, "", "");
        x_entry
            ->setTextSize(18.0f)
            ->setSize(80.0f, GuiElement::GuiSizeMax);

        (new GuiLabel(row, "", ",", 20.0f))
            ->setSize(20.0f, GuiElement::GuiSizeMax);

        auto y_entry = new GuiTextEntry(row, "", "");
        y_entry
            ->setTextSize(18.0f)
            ->setSize(80.0f, GuiElement::GuiSizeMax);

        auto sendUpdate = [this, x_entry, y_entry, lua_path]()
        {
            if (entity && script_runner)
            {
                float x = x_entry->getText().toFloat();
                float y = y_entry->getText().toFloat();
                script_runner(entity, lua_path + " = {" + string(x, 1) + ", " + string(y, 1) + "}");
            }
        };
        x_entry->callback([sendUpdate](string) { sendUpdate(); });
        y_entry->callback([sendUpdate](string) { sendUpdate(); });

        update_funcs.push_back([x_entry, y_entry, getter]()
        {
            auto v = getter();
            if (!x_entry->hasFocus()) x_entry->setText(string(v.x, 1));
            if (!y_entry->hasFocus()) y_entry->setText(string(v.y, 1));
        });
    }

    void createTransformPage()
    {
        auto& page = addPage(tr("tweak-tab", "Transform"),
            [](sp::ecs::Entity e) { return e.hasComponent<sp::Transform>(); });

        page.description = tr("tweak-transform", "Sets the entity's position (X, Y) and rotation angle. Position is in game units (1000 = 1U), rotation in degrees (0 = right/east-facing/heading 90).");
        addVec2Tweak(page.page, tr("tweak-text", "Position:"), ".components.transform.position",
            [this]()
            {
                if (auto t = entity.getComponent<sp::Transform>()) return t->getPosition();
                return glm::vec2(0, 0);
            },
            page.update_funcs);
        addFloatTweak(page.page, tr("tweak-text", "Rotation:"), ".components.transform.rotation",
            [this]()
            {
                if (auto t = entity.getComponent<sp::Transform>()) return t->getRotation();
                return 0.0f;
            },
            page.update_funcs);
    }

    void createPhysicsPage()
    {
        auto& page = addPage(tr("tweak-tab", "Physics"),
            [](sp::ecs::Entity e) { return e.hasComponent<sp::Physics>(); });
        page.description = tr("tweak-physics", "If present, this component subjects this entity to physics interactions. Sets the physics body type (Sensor, Dynamic, Static), shape (Circle or Rectangle), size, velocity, and angular velocity.");
        addSelectorTweak(page.page, tr("tweak-text", "Type:"), ".components.physics.type",
            {
                {tr("physics_type", "Sensor"), "\"sensor\""},
                {tr("physics_type", "Dynamic"), "\"dynamic\""},
                {tr("physics_type", "Static"), "\"static\""}
            },
            [this]()
            {
                if (auto v = entity.getComponent<sp::Physics>()) return static_cast<int>(v->getType());
                return 0;
            },
            page.update_funcs
        );
        addVec2Tweak(page.page, tr("tweak-text", "Velocity:"), ".components.physics.velocity",
            [this]()
            {
                if (auto v = entity.getComponent<sp::Physics>()) return v->getVelocity();
                return glm::vec2(0.0f, 0.0f);
            },
            page.update_funcs
        );
        addFloatTweak(page.page, tr("tweak-text", "Angular velocity:"), ".components.physics.angular_velocity",
            [this]()
            {
                if (auto v = entity.getComponent<sp::Physics>()) return v->getAngularVelocity();
                return 0.0f;
            },
            page.update_funcs
        );
    }

    void createCallSignPage()
    {
        auto& page = addPage(tr("tweak-tab", "CallSign"),
            [](sp::ecs::Entity e) { return e.hasComponent<CallSign>(); });
        page.description = tr("tweak-callsign", "The callsign displayed on radar views and in communications.");
        addTextTweak(page.page, tr("tweak-text", "Callsign:"), ".components.callsign.callsign",
            [this]()
            {
                if (auto v = entity.getComponent<CallSign>()) return v->callsign;
                return string("");
            },
            page.update_funcs
        );
    }

    void createFactionPage()
    {
        auto& page = addPage(tr("tweak-tab", "Faction"),
            [](sp::ecs::Entity e) { return e.hasComponent<Faction>(); });
        page.description = tr("tweak-faction", "The faction to which this entity belongs. An entity's faction determines which entities are friendly, neutral, or hostile.");
        auto row = new GuiElement(page.page, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "", tr("tweak-text", "Faction:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(100.0f, GuiElement::GuiSizeMax);

        auto selector = new GuiSelector(row, "",
            [this](int index, string value)
            {
                if (entity && script_runner && !value.empty())
                    script_runner(entity, ".components.faction.entity = findFaction('" + value + "')");
            }
        );

        for (auto [e, info] : sp::ecs::Query<FactionInfo>())
            selector->addEntry(info.locale_name, info.name);
        selector->setTextSize(18.0f)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        page.update_funcs.push_back(
            [this, selector]()
            {
                if (!entity) return;
                string current_faction = Faction::getInfo(entity).name;
                for (int i = 0; i < selector->entryCount(); i++)
                {
                    if (selector->getEntryValue(i) == current_faction)
                    {
                        if (selector->getSelectionIndex() != i) selector->setSelectionIndex(i);
                        return;
                    }
                }
                if (selector->getSelectionIndex() != -1) selector->setSelectionIndex(-1);
            }
        );
    }

    void createHullPage()
    {
        auto& page = addPage(tr("tweak-tab", "Hull"),
            [](sp::ecs::Entity e) { return e.hasComponent<Hull>(); });
        page.description = tr("tweak-hull", "Structural hit points. If hull reaches zero and the entity is destructible, it can be destroyed. Docking to certain entities can restore hull points.");

        addFloatTweak(page.page, tr("tweak-text", "Current:"), ".components.hull.current",
            [this]()
            {
                if (auto v = entity.getComponent<Hull>()) return v->current;
                return 0.0f;
            },
            page.update_funcs
        );
        addFloatTweak(page.page, tr("tweak-text", "Max:"), ".components.hull.max",
            [this]()
            {
                if (auto v = entity.getComponent<Hull>()) return v->max;
                return 0.0f;
            },
            page.update_funcs
        );
        addBoolTweak(page.page, tr("tweak-text", "Allow destruction"), ".components.hull.allow_destruction",
            [this]()
            {
                if (auto v = entity.getComponent<Hull>()) return v->allow_destruction;
                return false;
            },
            page.update_funcs
        );
    }

    void createShieldsPage()
    {
        auto& page = addPage(tr("tweak-tab", "Shields"),
            [](sp::ecs::Entity e) { return e.hasComponent<Shields>(); });
        page.description = tr("tweak-shields", "Shield generators, including active state and per-segment level and maximum capacity. Ships can have multiple shield segments with equal arcs.");

        addBoolTweak(page.page, tr("tweak-text", "Active"), ".components.shields.active",
            [this]()
            {
                if (auto v = entity.getComponent<Shields>()) return v->active;
                return false;
            },
            page.update_funcs
        );
        addFloatTweak(page.page, tr("tweak-text", "Level:"), ".components.shields.entries[1].level",
            [this]()
            {
                if (auto v = entity.getComponent<Shields>())
                    if (v->entries.size() > 0) return v->entries[0].level;
                return 0.0f;
            },
            page.update_funcs
        );
        addFloatTweak(page.page, tr("tweak-text", "Max:"), ".components.shields.entries[1].max",
            [this]()
            {
                if (auto v = entity.getComponent<Shields>())
                    if (v->entries.size() > 0) return v->entries[0].max;
                return 0.0f;
            },
            page.update_funcs
        );
    }

    void createAIPage()
    {
        auto& page = addPage(tr("tweak-tab", "AI"),
            [](sp::ecs::Entity e) { return e.hasComponent<AIController>(); });
        page.description = tr("tweak-ai", "Autonomous ship behavior. Set orders (attack, defend, dock, etc.), target entity, and target location for AI control.");
        addSelectorTweak(page.page, tr("tweak-text", "Orders:"), ".components.ai_controller.orders",
            {
                {tr("ai_order", "Idle"), "\"idle\""},
                {tr("ai_order", "Roaming"), "\"roaming\""},
                {tr("ai_order", "Retreat"), "\"retreat\""},
                {tr("ai_order", "Stand Ground"), "\"stand ground\""},
                {tr("ai_order", "Defend Location"), "\"defend location\""},
                {tr("ai_order", "Defend Target"), "\"defend target\""},
                {tr("ai_order", "Fly in formation"), "\"fly in formation\""},
                {tr("ai_order", "Fly towards"), "\"fly towards\""},
                {tr("ai_order", "Fly towards (ignore all)"), "\"fly towards (ignore all)\""},
                {tr("ai_order", "Dock"), "\"dock\""},
                {tr("ai_order", "Attack"), "\"attack\""}
            },
            [this]()
            {
                if (auto v = entity.getComponent<AIController>()) return static_cast<int>(v->orders);
                return 0;
            },
            page.update_funcs
        );
        addVec2Tweak(page.page, tr("tweak-text", "Order target location:"), ".components.ai_controller.order_target_location",
            [this]()
            {
                if (auto v = entity.getComponent<AIController>()) return v->order_target_location;
                return glm::vec2(0.0f, 0.0f);
            },
            page.update_funcs
        );
    }

    void createBeamWeaponsPage()
    {
        auto& page = addPage(tr("tweak-tab", "Beam weapons"),
            [](sp::ecs::Entity e) { return e.hasComponent<BeamWeaponSys>(); });
        page.description = tr("tweak-beam-system", "Ship system providing beam weapon configuration. Defines arc, range, damage, cycle time, and optional turret tracking.");

        addFloatTweak(page.page, tr("tweak-text", "Health:"), ".components.beam_weapons.health",
            [this]()
            {
                if (auto v = entity.getComponent<BeamWeaponSys>()) return v->health;
                return 0.0f;
            }, page.update_funcs
        );
        addFloatTweak(page.page, tr("tweak-text", "Health max:"), ".components.beam_weapons.health_max",
            [this]()
            {
                if (auto v = entity.getComponent<BeamWeaponSys>()) return v->health_max;
                return 0.0f;
            },
            page.update_funcs
        );
        addFloatTweak(page.page, tr("tweak-text", "Power level:"), ".components.beam_weapons.power_level",
            [this]()
            {
                if (auto v = entity.getComponent<BeamWeaponSys>()) return v->power_level;
                return 0.0f;
            },
            page.update_funcs
        );
        addFloatTweak(page.page, tr("tweak-text", "Heat level:"), ".components.beam_weapons.heat_level",
            [this]()
            {
                if (auto v = entity.getComponent<BeamWeaponSys>()) return v->heat_level;
                return 0.0f;
            },
            page.update_funcs
        );
    }

    void createMissileTubesPage()
    {
        auto& page = addPage(tr("tweak-tab", "Missile tubes"),
            [](sp::ecs::Entity e) { return e.hasComponent<MissileTubes>(); });
        page.description = tr("tweak-missile-system", "Ship system and storage for missiles and mines. Defines current stock and maximum capacity for each type.");
        addIntTweak(page.page, tr("tweak-text", "Homing:"), ".components.missile_tubes.storage_homing",
            [this]()
            {
                if (auto v = entity.getComponent<MissileTubes>()) return v->storage[int(MW_Homing)];
                return 0;
            },
            page.update_funcs
        );
        addIntTweak(page.page, tr("tweak-text", "Nuke:"), ".components.missile_tubes.storage_nuke",
            [this]()
            {
                if (auto v = entity.getComponent<MissileTubes>()) return v->storage[int(MW_Nuke)];
                return 0;
            },
            page.update_funcs
        );
        addIntTweak(page.page, tr("tweak-text", "Mine:"), ".components.missile_tubes.storage_mine",
            [this]()
            {
                if (auto v = entity.getComponent<MissileTubes>()) return v->storage[int(MW_Mine)];
                return 0;
            },
            page.update_funcs
        );
        addIntTweak(page.page, tr("tweak-text", "EMP:"), ".components.missile_tubes.storage_emp",
            [this]()
            {
                if (auto v = entity.getComponent<MissileTubes>()) return v->storage[int(MW_EMP)];
                return 0;
            },
            page.update_funcs
        );
        addIntTweak(page.page, tr("tweak-text", "HVLI:"), ".components.missile_tubes.storage_hvli",
            [this]()
            {
                if (auto v = entity.getComponent<MissileTubes>()) return v->storage[int(MW_HVLI)];
                return 0;
            },
            page.update_funcs
        );
    }

    void createReactorPage()
    {
        auto& page = addPage(tr("tweak-tab", "Reactor"),
            [](sp::ecs::Entity e) { return e.hasComponent<Reactor>(); });
        page.description = tr("tweak-reactor", "Ship system that generates and stores energy. Sets energy capacity and current energy level.");

        addFloatTweak(page.page, tr("tweak-text", "Energy:"), ".components.reactor.energy",
            [this]()
            {
                if (auto v = entity.getComponent<Reactor>()) return v->energy;
                return 0.0f;
            },
            page.update_funcs
        );
        addFloatTweak(page.page, tr("tweak-text", "Max energy:"), ".components.reactor.max_energy",
            [this]()
            {
                if (auto v = entity.getComponent<Reactor>()) return v->max_energy;
                return 0.0f;
            },
            page.update_funcs
        );
    }

    void createImpulsePage()
    {
        auto& page = addPage(tr("tweak-tab", "Impulse"),
            [](sp::ecs::Entity e) { return e.hasComponent<ImpulseEngine>(); });
        page.description = tr("tweak-impulse", "Ship system for impulse propulsion. Controls forward/reverse max speeds and acceleration rates.");
        addFloatTweak(page.page, tr("tweak-text", "Max speed forward:"), ".components.impulse_engine.max_speed_forward",
            [this]()
            {
                if (auto v = entity.getComponent<ImpulseEngine>()) return v->max_speed_forward;
                return 0.0f;
            },
            page.update_funcs
        );
        addFloatTweak(page.page, tr("tweak-text", "Acceleration forward:"), ".components.impulse_engine.acceleration_forward",
            [this]()
            {
                if (auto v = entity.getComponent<ImpulseEngine>()) return v->acceleration_forward;

                return 0.0f;
            },
            page.update_funcs
        );
    }

    void createManeuveringPage()
    {
        auto& page = addPage(tr("tweak-tab", "Maneuvering"),
            [](sp::ecs::Entity e) { return e.hasComponent<ManeuveringThrusters>(); });
        page.description = tr("tweak-maneuvering", "Ship system providing rotational thrusters for the ship.");
        addFloatTweak(page.page, tr("tweak-text", "Speed:"), ".components.maneuvering_thrusters.speed",
            [this]()
            {
                if (auto v = entity.getComponent<ManeuveringThrusters>()) return v->speed;
                return 0.0f;
            },
            page.update_funcs
        );
    }

    void createWarpDrivePage()
    {
        auto& page = addPage(tr("tweak-tab", "Warp drive"),
            [](sp::ecs::Entity e) { return e.hasComponent<WarpDrive>(); });
        page.description = tr("tweak-warp", "Ship system for the warp propulsion drive. Active warp usage consumes energy and generates heat.");
        addIntTweak(page.page, tr("tweak-text", "Request:"), ".components.warp_drive.request",
            [this]()
            {
                if (auto v = entity.getComponent<WarpDrive>()) return v->request;
                return 0;
            },
            page.update_funcs
        );
        addFloatTweak(page.page, tr("tweak-text", "Current:"), ".components.warp_drive.current",
            [this]()
            {
                if (auto v = entity.getComponent<WarpDrive>()) return v->current;
                return 0.0f;
            },
            page.update_funcs
        );
        addIntTweak(page.page, tr("tweak-text", "Max level:"), ".components.warp_drive.max_level",
            [this]()
            {
                if (auto v = entity.getComponent<WarpDrive>()) return v->max_level;
                return 0;
            },
            page.update_funcs
        );
    }

    void createJumpDrivePage()
    {
        auto& page = addPage(tr("tweak-tab", "Jump drive"),
            [](sp::ecs::Entity e) { return e.hasComponent<JumpDrive>(); });
        page.description = tr("tweak-jump", "Ship system for the jump propulsion drive. Minimum and maximum distance values define the available jump range.");
        addFloatTweak(page.page, tr("tweak-text", "Charge:"), ".components.jump_drive.charge",
            [this]()
            {
                if (auto v = entity.getComponent<JumpDrive>()) return v->charge;
                return 0.0f;
            },
            page.update_funcs
        );
        addFloatTweak(page.page, tr("tweak-text", "Distance:"), ".components.jump_drive.distance",
            [this]()
            {
                if (auto v = entity.getComponent<JumpDrive>()) return v->distance;
                return 0.0f;
            },
            page.update_funcs
        );
        addFloatTweak(page.page, tr("tweak-text", "Delay:"), ".components.jump_drive.delay",
            [this]()
            {
                if (auto v = entity.getComponent<JumpDrive>()) return v->delay;
                return 0.0f;
            },
            page.update_funcs
        );
    }

    void createCommsPage()
    {
        auto& page = addPage(tr("tweak-tab", "Comms"),
            [](sp::ecs::Entity e) { return e.hasComponent<CommsTransmitter>(); });
        page.description = tr("tweak-comms-transmitter", "Allows this entity to open communication channels with other ships and stations.");
        addSelectorTweak(page.page, tr("tweak-text", "State:"), ".components.comms_transmitter.state", {
            {tr("comms_state", "Inactive"), "\"inactive\""},
            {tr("comms_state", "Opening channel"), "\"opening\""},
            {tr("comms_state", "Being hailed"), "\"hailed\""},
            {tr("comms_state", "Being hailed by GM"), "\"hailed_gm\""},
            {tr("comms_state", "Channel open"), "\"open\""},
            {tr("comms_state", "Channel open (player)"), "\"open_player\""},
            {tr("comms_state", "Channel open (GM)"), "\"open_gm\""},
            {tr("comms_state", "Channel failed"), "\"failed\""},
            {tr("comms_state", "Channel broken"), "\"broken\""},
            {tr("comms_state", "Channel closed"), "\"closed\""}
        },
            [this]()
            {
                if (auto v = entity.getComponent<CommsTransmitter>()) return static_cast<int>(v->state);

                return 0;
            },
            page.update_funcs
        );
    }

    void createDockingPage()
    {
        auto& page = addPage(tr("tweak-tab", "Docking"),
            [](sp::ecs::Entity e) { return e.hasComponent<DockingPort>(); });
        page.description = tr("tweak-docking-port", "Allows this entity to dock with entities that have a Docking bay component. Tracks docking state and auto-reload configuration.");
        addSelectorTweak(page.page, tr("tweak-text", "State:"), ".components.docking_port.state",
            {
                {tr("docking_state", "Not docking"), "\"not_docking\""},
                {tr("docking_state", "Docking"), "\"docking\""},
                {tr("docking_state", "Docked"), "\"docked\""}
            },
            [this]()
            {
                if (auto v = entity.getComponent<DockingPort>()) return static_cast<int>(v->state);

                return 0;
            },
            page.update_funcs
        );
        addBoolTweak(page.page, tr("tweak-text", "Auto reload missiles"), ".components.docking_port.auto_reload_missiles",
            [this]()
            {
                if (auto v = entity.getComponent<DockingPort>()) return v->auto_reload_missiles;
                return false;
            },
            page.update_funcs
        );
    }

    void createLifetimePage()
    {
        auto& page = addPage(tr("tweak-tab", "Lifetime"),
            [](sp::ecs::Entity e) { return e.hasComponent<LifeTime>(); });
        page.description = tr("tweak-lifetime", "Defines a time-limited existence for this entity. The entity is automatically destroyed when the remaining lifetime expires.");
        addFloatTweak(page.page, tr("tweak-text", "Lifetime:"), ".components.lifetime.lifetime",
            [this]()
            {
                if (auto v = entity.getComponent<LifeTime>()) return v->lifetime;
                return 0.0f;
            },
            page.update_funcs
        );
    }

    void createSpinPage()
    {
        auto& page = addPage(tr("tweak-tab", "Spin"),
            [](sp::ecs::Entity e) { return e.hasComponent<Spin>(); });
        page.description = tr("tweak-spin", "Makes the entity rotate continuously at the given rate in degrees per second. Useful for asteroids, debris, and planetary rotation effects.");
        addFloatTweak(page.page, tr("tweak-text", "Rate:"), ".components.spin.rate",
            [this]()
            {
                if (auto v = entity.getComponent<Spin>()) return v->rate;
                return 0.0f;
            },
            page.update_funcs
        );
    }

    void createSelfDestructPage()
    {
        auto& page = addPage(tr("tweak-tab", "Self destruct"),
            [](sp::ecs::Entity e) { return e.hasComponent<SelfDestruct>(); });
        page.description = tr("tweak-self-destruct", "If present and active, starts a countdown and triggers an explosion with the defined blast damage and radius.");
        addBoolTweak(page.page, tr("tweak-text", "Active"), ".components.self_destruct.active",
            [this]()
            {
                if (auto v = entity.getComponent<SelfDestruct>()) return v->active;
                return false;
            },
            page.update_funcs
        );
        addFloatTweak(page.page, tr("tweak-text", "Countdown:"), ".components.self_destruct.countdown",
            [this]()
            {
                if (auto v = entity.getComponent<SelfDestruct>()) return v->countdown;
                return 0.0f;
            },
            page.update_funcs
        );
    }

    void createMeshRenderPage()
    {
        auto& page = addPage(tr("tweak-tab", "Mesh render"),
            [](sp::ecs::Entity e) { return e.hasComponent<MeshRenderComponent>(); });
        page.description = tr("tweak-mesh-render", "3D mesh rendering. Defines the model file, texture, and scale.");
        addTextTweak(page.page, tr("tweak-text", "Mesh:"), ".components.mesh_render.mesh",
            [this]()
            {
                if (auto v = entity.getComponent<MeshRenderComponent>()) return v->mesh.name;
                return string("");
            },
            page.update_funcs
        );
        addTextTweak(page.page, tr("tweak-text", "Texture:"), ".components.mesh_render.texture",
            [this]()
            {
                if (auto v = entity.getComponent<MeshRenderComponent>()) return v->texture.name;
                return string("");
            },
            page.update_funcs
        );
        addFloatTweak(page.page, tr("tweak-text", "Scale:"), ".components.mesh_render.scale",
            [this]()
            {
                if (auto v = entity.getComponent<MeshRenderComponent>()) return v->scale;
                return 1.0f;
            },
            page.update_funcs
        );
    }
};

LimitedGameMasterScreen::LimitedGameMasterScreen(RenderLayer* render_layer)
: GuiCanvas(render_layer)
{
    main_radar = new GuiRadarView(this, "MAIN_RADAR", LONG_RANGE_DISTANCE, &targets);
    main_radar
        ->setStyle(GuiRadarView::Rectangular)
        ->longRange()
        ->gameMaster()
        ->enableTargetProjections(nullptr)
        ->setAutoCentering(false)
        ->setCallbacks(
            [this](sp::io::Pointer::Button button, glm::vec2 position) { this->onMouseDown(button, position); },
            [this](glm::vec2 position) { this->onMouseDrag(position); },
            [this](glm::vec2 position) { this->onMouseUp(position); },
            [this](float value, glm::vec2 position) { this->onMouseWheel(value, position); }
        )
        ->setOverlayCallback(
            [this](sp::RenderTarget& renderer)
            {
                const bool is_short_range = main_radar->getDistance() <= SHORT_RANGE_DISTANCE;
                float bar_width = is_short_range ? 60.0f : 30.0f;
                float bar_height = is_short_range ? 5.0f : 2.0f;
                float bar_offset = bar_width * 0.5f;

                if (show_health_bars)
                {
                    for (auto [entity, hull, transform, trace] : sp::ecs::Query<Hull, sp::Transform, sp::ecs::optional<RadarTrace>>())
                    {
                        const float hull_norm = hull.current / hull.max;
                        float bar_distance = bar_height * 4.0f;
                        if (trace) bar_distance = std::clamp(trace->radius * main_radar->getScale() * 2.0f, trace->min_size, trace->max_size) * 0.75f;

                        if (hull_norm < 0.9f || is_short_range)
                        {
                            glm::vec2 screen_pos = main_radar->worldToScreen(transform.getPosition());
                            const float health_bar_width = bar_width * hull_norm;
                            uint8_t bar_r, bar_g;
                            if (hull_norm >= 0.5f)
                            {
                                float t = (hull_norm - 0.5f) / 0.5f;
                                bar_r = static_cast<uint8_t>(255.0f * (1.0f - t));
                                bar_g = 255;
                            }
                            else if (hull_norm >= 0.2f)
                            {
                                float t = (hull_norm - 0.2f) / 0.3f;
                                bar_r = 255;
                                bar_g = static_cast<uint8_t>(255.0f * t);
                            }
                            else
                            {
                                bar_r = 255;
                                bar_g = 0;
                            }
                            renderer.fillRect(sp::Rect(screen_pos.x - bar_offset, screen_pos.y + bar_distance, health_bar_width, bar_height), glm::u8vec4(bar_r, bar_g, 0, 192));
                            renderer.drawRectOutline(sp::Rect(screen_pos.x - bar_offset, screen_pos.y + bar_distance, bar_width, bar_height), 1.0f, glm::u8vec4(255, 255, 255, 128));
                        }
                    }
                }
            }
        )
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    box_selection_overlay = new GuiOverlay(main_radar, "BOX_SELECTION", glm::u8vec4(255, 255, 255, 32));
    box_selection_overlay->getLayout().fill_height = false;
    box_selection_overlay->getLayout().fill_width = false;
    box_selection_overlay->hide();

    faction_selector = new GuiSelector(this, "FACTION_SELECTOR", [this](int index, string value) {
        for (auto obj : targets.getTargets())
            runScriptForEntity(getEntityStringForLua(obj), ".components.faction.entity = findFaction('" + value + "')");
    });

    for (auto [entity, info] : sp::ecs::Query<FactionInfo>())
        faction_selector->addEntry(info.locale_name, info.name);

    faction_selector
        ->setSelectionIndex(0)
        ->setPosition(20.0f, 70.0f, sp::Alignment::TopLeft)
        ->setSize(250.0f, GuiElement::GuiSizeRow);

    (new GuiTextTooltip(faction_selector, "FACTION_SELECTOR_TIP", tr("gm_tooltip", "Change the faction of selected objects."), 20.0f))->setWidth(280.0f);

    pause_button = new GuiToggleButton(this, "PAUSE_BUTTON", tr("button", "Pause"),
        [this](bool value)
        {
            if (value)
                runScript("pauseGame()");
            else
                runScript("setGameSpeed(" + string(static_cast<int>(pow(2.0f, game_time_scale->getSelectionIndex()))) + ")");
        }
    );
    pause_button
        ->setValue(false)
        ->setPosition(20.0f, 20.0f, sp::Alignment::TopLeft)
        ->setSize(150.0f, GuiElement::GuiSizeRow);

    (new GuiTextTooltip(pause_button, "PAUSE_BUTTON_TIP", tr("gm_tooltip", "Toggle pausing the game simulation."), 20.0f))
        ->setWidth(280.0f);

    game_time_scale = new GuiSelector(this, "GAME_TIME_SCALE_SELECTOR",
        [this](int index, string value)
        {
            runScript("setGameSpeed(" + string(static_cast<int>(pow(2, index))) + ")");
        }
    );
    game_time_scale
        ->setOptions({"1x", "2x", "4x", "8x"})
        ->setSelectionIndex(0)
        ->setPosition(170.0f, 20.0f, sp::Alignment::TopLeft)
        ->setSize(100.0f, GuiElement::GuiSizeRow);

    tweak_dialog = new LimitedGuiEntityTweak(this,
        [this](sp::ecs::Entity entity, const string& expression)
        {
            runScriptForEntity(getEntityStringForLua(entity), expression);
        }
    );
    tweak_dialog->hide();

    tweak_button = new GuiButton(this, "TWEAK_OBJECT", tr("button", "Tweak"),
        [this]()
        {
            sp::ecs::Entity target = targets.get();
            if (!target) return;
            tweak_dialog->open(target);
            tweak_dialog->show();
            tweak_dialog->moveToFront();
        }
    );
    tweak_button
        ->setPosition(20.0f, -120.0f, sp::Alignment::BottomLeft)
        ->setSize(250.0f, GuiElement::GuiSizeRow)
        ->hide();

    (new GuiTextTooltip(tweak_button, "TWEAK_OBJECT_TIP", tr("gm_tooltip", "Edit properties of the selected entity."), 20.0f))
        ->setWidth(280.0f);

    global_message_button = new GuiButton(this, "GLOBAL_MESSAGE_BUTTON", tr("button", "Global message"),
        [this]() { global_message_entry->show(); }
    );
    global_message_button
        ->setPosition(20.0f, -20.0f, sp::Alignment::BottomLeft)
        ->setSize(250.0f, GuiElement::GuiSizeRow);

    (new GuiTextTooltip(global_message_button, "GLOBAL_MESSAGE_TIP", tr("gm_tooltip", "Broadcast a message to all players."), 20.0f))
        ->setWidth(280.0f);

    player_ship_selector = new GuiSelector(this, "PLAYER_SHIP_SELECTOR",
        [this](int index, string value)
        {
            auto ship = sp::ecs::Entity::fromString(value);
            if (!ship) return;

            target = ship;
            if (auto transform = target.getComponent<sp::Transform>())
                main_radar->setViewPosition(transform->getPosition());
            targets.set(ship);
        }
    );
    player_ship_selector
        ->setPosition(270.0f, -20.0f, sp::Alignment::BottomLeft)
        ->setSize(350.0f, GuiElement::GuiSizeRow);

    (new GuiTextTooltip(player_ship_selector, "PLAYER_SHIP_SELECTOR_TIP", tr("gm_tooltip", "Select a player ship to track on the map."), 20.0f))
        ->setWidth(280.0f);

    zoom_slider = new GuiRadarZoomSlider(this, "ZOOM_SLIDER", MIN_ZOOM_DISTANCE, MAX_ZOOM_DISTANCE, LONG_RANGE_DISTANCE, main_radar);
    zoom_slider
        ->setZoomReference(LONG_RANGE_DISTANCE)
        ->setLabelPrecision(3)
        ->setPosition(-20.0f, -20.0f, sp::Alignment::BottomRight)
        ->setSize(250.0f, GuiElement::GuiSizeRow);

    player_comms_hail = new GuiButton(this, "HAIL_PLAYER", tr("button", "Hail ship"),
        [this]()
        {
            for (auto obj : targets.getTargets())
            {
                if (obj.hasComponent<CommsTransmitter>())
                {
                    auto cd = getChatDialog(obj);
                    if (auto transform = obj.getComponent<sp::Transform>())
                    {
                        cd
                            ->show()
                            ->setPosition(main_radar->worldToScreen(transform->getPosition()))
                            ->setSize(300.0f, 300.0f);
                    }
                }
            }
        }
    );
    player_comms_hail
        ->setPosition(20.0f, -170.0f, sp::Alignment::BottomLeft)
        ->setSize(250.0f, GuiElement::GuiSizeRow)
        ->hide();

    (new GuiTextTooltip(player_comms_hail, "HAIL_PLAYER_TIP", tr("gm_tooltip", "Open a communication channel with the selected player ship."), 20.0f))
        ->setWidth(280.0f);

    info_layout = new GuiElement(this, "INFO_LAYOUT");
    info_layout
        ->setPosition(-20.0f, 20.0f, sp::Alignment::TopRight)
        ->setSize(300.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    info_clock = new GuiKeyValueDisplay(info_layout, "INFO_CLOCK", 0.5f, tr("Clock"), "");
    info_clock->setSize(GuiElement::GuiSizeMax, 30.0f);

    gm_script_options = new GuiListbox(this, "GM_SCRIPT_OPTIONS",
        [this](int index, string value)
        {
            gm_script_options->setSelectionIndex(-1);
            int n = 0;
            for (GMScriptCallback& callback : gameGlobalInfo->gm_callback_functions)
            {
                if (n == index)
                {
                    auto cb = callback.callback;
                    cb.call<void>();
                    return;
                }

                n++;
            }
        }
    );
    gm_script_options
        ->setPosition(20.0f, 130.0f, sp::Alignment::TopLeft)
        ->setSize(250.0f, 500.0f);

    order_layout = new GuiElement(this, "ORDER_LAYOUT");
    order_layout
        ->setPosition(-20.0f, -110.0f, sp::Alignment::BottomRight)
        ->setSize(300.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "verticalbottom");

    (new GuiLabel(order_layout, "ORDERS_HELP", tr("Right click to issue movement/target orders"), 20.0f))
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    GuiButton* order_defend = new GuiButton(order_layout, "ORDER_DEFEND_LOCATION", tr("Defend location"),
        [this]()
        {
            for (auto entity : targets.getTargets())
                if (my_player_info) my_player_info->commandSetAIOrder(entity, AIOrder::DefendLocation);
        }
    );
    order_defend
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    (new GuiTextTooltip(order_defend, "ORDER_DEFEND_TIP", tr("gm_tooltip", "Order selected AI entities to defend their current location."), 20.0f))
        ->setWidth(280.0f);

    GuiButton* order_stand_ground = new GuiButton(order_layout, "ORDER_STAND_GROUND", tr("Stand ground"),
        [this]()
        {
            for (auto entity : targets.getTargets())
                if (my_player_info) my_player_info->commandSetAIOrder(entity, AIOrder::StandGround);
        }
    );
    order_stand_ground
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    (new GuiTextTooltip(order_stand_ground, "ORDER_STAND_GROUND_TIP", tr("gm_tooltip", "Order selected AI entities to hold position and attack nearby enemies."), 20.0f))
        ->setWidth(280.0f);

    GuiButton* order_roaming = new GuiButton(order_layout, "ORDER_ROAMING", tr("Roaming"),
        [this]()
        {
            for (auto entity : targets.getTargets())
                if (my_player_info) my_player_info->commandSetAIOrder(entity, AIOrder::Roaming);
        }
    );
    order_roaming
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    (new GuiTextTooltip(order_roaming, "ORDER_ROAMING_TIP", tr("gm_tooltip", "Order selected AI entities to roam freely and engage enemies."), 20.0f))
        ->setWidth(280.0f);

    GuiButton* order_idle = new GuiButton(order_layout, "ORDER_IDLE", tr("Idle"),
        [this]()
        {
            for (auto entity : targets.getTargets())
                if (my_player_info) my_player_info->commandSetAIOrder(entity, AIOrder::Idle);
        }
    );
    order_idle
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    (new GuiTextTooltip(order_idle, "ORDER_IDLE_TIP", tr("gm_tooltip", "Order selected AI entities to stop all actions."), 20.0f))
        ->setWidth(280.0f);

    (new GuiLabel(order_layout, "ORDERS_LABEL", tr("Orders"), 20.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    gm_player_waypoint_layout = new GuiElement(this, "GM_WP_LAYOUT");
    gm_player_waypoint_layout
        ->setPosition(-20.0f, -240.0f, sp::Alignment::BottomRight)
        ->setSize(300.0f, GuiElement::GuiSizeMax)
        ->hide()
        ->setAttribute("layout", "verticalbottom");

    gm_delete_waypoint_button = new GuiToggleButton(gm_player_waypoint_layout, "GM_WP_DELETE", tr("button", "Delete waypoint"),
        [this](bool value)
        {
            gm_delete_waypoint_mode = value;
            if (value && gm_add_waypoint_mode)
            {
                gm_add_waypoint_mode = false;
                gm_waypoint_target_ship = {};
                gm_add_waypoint_button->setValue(false);
            }
        }
    );
    gm_delete_waypoint_button
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    gm_add_waypoint_button = new GuiToggleButton(gm_player_waypoint_layout, "GM_WP_ADD", tr("button", "Add waypoint"),
        [this](bool value)
        {
            if (value)
            {
                for (auto entity : targets.getTargets())
                {
                    if (entity.hasComponent<PlayerControl>())
                    {
                        gm_waypoint_target_ship = entity;
                        gm_add_waypoint_mode = true;
                        if (gm_delete_waypoint_mode)
                        {
                            gm_delete_waypoint_mode = false;
                            gm_delete_waypoint_button->setValue(false);
                        }
                        return;
                    }
                }
                gm_add_waypoint_button->setValue(false);
            }
            else
            {
                gm_add_waypoint_mode = false;
                gm_waypoint_target_ship = {};
            }
        }
    );
    gm_add_waypoint_button
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    gm_route_toggle = new GuiToggleButton(gm_player_waypoint_layout, "GM_WP_ROUTE", tr("Draw route for this waypoint set"),
        [this](bool value)
        {
            for (auto entity : targets.getTargets())
            {
                if (entity.hasComponent<PlayerControl>())
                {
                    runScript("commandSetWaypointRoute(entityFromString('" + getEntityStringForLua(entity) + "'), " + string(value ? "true" : "false") + ", " + string(gm_waypoint_set) + ")");
                    break;
                }
            }
        }
    );
    gm_route_toggle
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    gm_waypoint_set_selector = new GuiSelector(gm_player_waypoint_layout, "GM_WP_SET",
        [this](int index, string value)
        {
            gm_waypoint_set = index + 1;
            for (auto entity : targets.getTargets())
            {
                if (entity.hasComponent<PlayerControl>())
                {
                    if (auto wp = entity.getComponent<Waypoints>())
                        gm_route_toggle->setValue(wp->is_route[gm_waypoint_set - 1]);
                    break;
                }
            }
        }
    );
    gm_waypoint_set_selector
        ->setTextSize(20.0f)
        ->setOptions({tr("Waypoint set 1"), tr("Waypoint set 2"), tr("Waypoint set 3"), tr("Waypoint set 4")})
        ->setSelectionIndex(0)
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    gm_show_waypoints_button = new GuiToggleButton(gm_player_waypoint_layout, "GM_WP_SHOW", tr("button", "Show waypoints"),
        [this](bool value)
        {
            if (value) main_radar->enableWaypoints();
            else main_radar->disableWaypoints();
        }
    );
    gm_show_waypoints_button
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    (new GuiLabel(gm_player_waypoint_layout, "GM_WP_LABEL", tr("Waypoints"), 20.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    chat_layer = new GuiElement(this, "");
    chat_layer
        ->setPosition(0.0f, 0.0f)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    global_message_entry = new GuiGlobalMessageEntryView(this);
    global_message_entry->hide();

    message_frame = new GuiPanel(this, "");
    message_frame
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopCenter)
        ->setSize(900.0f, 230.0f)
        ->hide();

    message_text = new GuiScrollFormattedText(message_frame, "", "");
    message_text
        ->setTextSize(20.0f)
        ->setPosition(20.0f, 20.0f, sp::Alignment::TopLeft)
        ->setSize(900.0f - 40.0f, 200.0f - 40.0f);
    message_close_button = new GuiButton(message_frame, "", tr("button", "Close"),
        []()
        {
            if (!gameGlobalInfo->gm_messages.empty())
                gameGlobalInfo->gm_messages.pop_front();
        }
    );
    message_close_button
        ->setTextSize(30.0f)
        ->setPosition(-20.0f, -20.0f, sp::Alignment::BottomRight)
        ->setSize(300.0f, 30.0f);

    keyboard_help = new GuiHotkeyHelpOverlay(this, {tr("hotkey_menu", "Console"), tr("hotkey_menu", "Basic"), tr("hotkey_menu", "GM")});
}

LimitedGameMasterScreen::~LimitedGameMasterScreen()
{
    if (P<MouseRenderer> mouse_renderer = engine->getObject("mouseRenderer"))
    {
        mouse_renderer->setPrimary("cursors/mouse.png");
        mouse_renderer->setCursorHotspotTopLeft();
    }
}

void LimitedGameMasterScreen::update(float delta)
{
    if (!drag_entity_original_positions.empty())
    {
        for (auto& [entity, original_pos] : drag_entity_original_positions)
            if (auto transform = entity.getComponent<sp::Transform>())
                transform->setPosition(original_pos + drag_total_offset);
    }

    float mouse_wheel_delta = keys.zoom_in.getContinuousValue() + keys.zoom_in.getAxis0Value() + keys.zoom_in.getAxis1Value()
        - keys.zoom_out.getContinuousValue() - keys.zoom_out.getAxis0Value() - keys.zoom_out.getAxis1Value();
    if (mouse_wheel_delta != 0.0f)
    {
        float view_distance = std::clamp(main_radar->getDistance() * (1.0f - (mouse_wheel_delta * 0.1f)), MIN_ZOOM_DISTANCE, MAX_ZOOM_DISTANCE);
        main_radar->setDistance(view_distance);
        if (view_distance <= SHORT_RANGE_DISTANCE) main_radar->shortRange();
        else main_radar->longRange();
    }
    if (keys.zoom_in.isDiscreteStepDown() || keys.zoom_in.isRepeatReady())
    {
        float view_distance = std::clamp(main_radar->getDistance() * 0.9f, 5000.0f, 1000000.0f);
        main_radar->setDistance(view_distance);
        if (view_distance < 10000) main_radar->shortRange();
        else main_radar->longRange();
    }
    if (keys.zoom_out.isDiscreteStepDown() || keys.zoom_out.isRepeatReady())
    {
        float view_distance = std::clamp(main_radar->getDistance() * 1.1f, 5000.0f, 1000000.0f);
        main_radar->setDistance(view_distance);
        if (view_distance < 10000) main_radar->shortRange();
        else main_radar->longRange();
    }

    if (keys.pause.isDiscreteStepDown())
        runScript("isGamePaused() and unpauseGame() or pauseGame()");

    {
        const float game_speed = engine->getGameSpeed();
        if (game_speed != last_known_game_speed)
        {
            last_known_game_speed = game_speed;
            if (game_speed == 0.0f)
            {
                pause_button->setValue(true);
                game_time_scale->setSelectionIndex(0);
                game_time_scale->disable();
            }
            else
            {
                pause_button->setValue(false);
                game_time_scale->enable();
                switch (static_cast<int>(game_speed))
                {
                    case 1: game_time_scale->setSelectionIndex(0); break;
                    case 2: game_time_scale->setSelectionIndex(1); break;
                    case 4: game_time_scale->setSelectionIndex(2); break;
                    case 8: game_time_scale->setSelectionIndex(3); break;
                    default: break;
                }
            }
        }
    }

    if (keys.gm_delete.isDiscreteStepDown())
    {
        for (auto obj : targets.getTargets())
            runScriptForEntity(getEntityStringForLua(obj), ":destroy()");
    }

    if (keys.help.isDiscreteStepDown())
        keyboard_help->frame->setVisible(!keyboard_help->frame->isVisible());

    if (keys.escape.isDiscreteStepDown())
    {
        if (tweak_dialog->isVisible())
            tweak_dialog->hide();
        else
        {
            destroy();
            returnToShipSelection(getRenderLayer());
        }
    }

    if (keys.gm_show_callsigns.isDiscreteStepDown())
        main_radar->showCallsigns(!main_radar->getCallsigns());

    if (keys.gm_show_waypoints.isDiscreteStepDown())
    {
        if (main_radar->getWaypoints()) main_radar->disableWaypoints();
        else main_radar->enableWaypoints();
    }

    if (keys.gm_show_health_bars.isDiscreteStepDown())
        show_health_bars = !show_health_bars;

    has_cpu_ship = false;
    has_player_ship = false;

    for (auto [entity, pc] : sp::ecs::Query<PlayerControl>())
    {
        string ship_name;
        if (auto tn = entity.getComponent<TypeName>())
            ship_name += " " + tn->type_name;
        if (auto cs = entity.getComponent<CallSign>())
            ship_name += " " + cs->callsign;
        if (player_ship_selector->indexByValue(entity.toString()) == -1)
            player_ship_selector->addEntry(ship_name, entity.toString());
        else
            player_ship_selector->setEntryName(player_ship_selector->indexByValue(entity.toString()), ship_name);

        auto transmitter = entity.getComponent<CommsTransmitter>();
        if (transmitter && (transmitter->state == CommsTransmitter::State::BeingHailedByGM || transmitter->state == CommsTransmitter::State::ChannelOpenGM))
        {
            auto cd = getChatDialog(entity);
            if (!cd->isVisible())
            {
                if (auto transform = entity.getComponent<sp::Transform>())
                    cd->show()->setPosition(main_radar->worldToScreen(transform->getPosition()))->setSize(300, 300);
            }
        }
    }
    for (int n = 0; n < player_ship_selector->entryCount(); n++)
    {
        if (!sp::ecs::Entity::fromString(player_ship_selector->getEntryValue(n)))
            player_ship_selector->removeEntry(n);
    }

    for (auto entity : targets.getTargets())
    {
        if (entity.hasComponent<AIController>()) has_cpu_ship = true;
        if (entity.hasComponent<PlayerControl>()) has_player_ship = true;
    }

    player_ship_selector->setVisible(player_ship_selector->entryCount() > 0);

    order_layout->setVisible(has_cpu_ship);
    player_comms_hail->setVisible(has_player_ship);
    tweak_button->setVisible(targets.getTargets().size() > 0);

    if (!has_player_ship && gm_delete_waypoint_mode)
    {
        gm_delete_waypoint_mode = false;
        gm_delete_waypoint_button->setValue(false);
    }
    gm_player_waypoint_layout->setVisible(has_player_ship);
    gm_add_waypoint_button->setVisible(main_radar->getWaypoints());
    gm_delete_waypoint_button->setVisible(main_radar->getWaypoints());
    gm_route_toggle->setVisible(gameGlobalInfo->enable_waypoint_routes && main_radar->getWaypoints());
    gm_waypoint_set_selector->setVisible(gameGlobalInfo->enable_multiple_waypoint_sets && main_radar->getWaypoints());

    if (!gameGlobalInfo->enable_multiple_waypoint_sets && gm_waypoint_set != 1)
    {
        gm_waypoint_set = 1;
        gm_waypoint_set_selector->setSelectionIndex(0);
    }

    if (has_player_ship)
    {
        for (auto entity : targets.getTargets())
        {
            if (entity.hasComponent<PlayerControl>())
            {
                if (auto wp = entity.getComponent<Waypoints>())
                    gm_route_toggle->setValue(wp->is_route[gm_waypoint_set - 1]);
                break;
            }
        }
    }

    info_clock->setValue(gameGlobalInfo->getMissionTime());

    std::vector<std::pair<string, string>> selection_info;
    std::unordered_map<string, size_t> selection_info_index;

    if (targets.getTargets().size() == 1)
    {
        if (auto t = targets.get().getComponent<sp::Transform>())
        {
            string pos_key = trMark("gm_info", "Position");
            string pos_val = string(t->getPosition().x, 0) + "," + string(t->getPosition().y, 0);
            auto it = selection_info_index.find(pos_key);
            if (it == selection_info_index.end())
            {
                selection_info_index[pos_key] = selection_info.size();
                selection_info.emplace_back(pos_key, pos_val);
            }
            else
                selection_info[it->second].second = pos_val;
        }
    }

    for (auto entity : targets.getTargets())
    {
        for (auto& [key, value] : getGMInfo(entity))
        {
            auto it = selection_info_index.find(key);
            if (it == selection_info_index.end())
            {
                selection_info_index[key] = selection_info.size();
                selection_info.emplace_back(key, value);
            }
            else if (selection_info[it->second].second != value)
                selection_info[it->second].second = tr("*mixed*");
        }
    }

    unsigned int cnt = 0;
    for (auto& [key, value] : selection_info)
    {
        if (cnt == info_items.size())
        {
            info_items.push_back(new GuiKeyValueDisplay(info_layout, "INFO_" + string(cnt), 0.5f, key, value));
            info_items[cnt]->setSize(GuiElement::GuiSizeMax, 30.0f);
        }
        else
        {
            info_items[cnt]
                ->setKey(tr("gm_info", key))->setValue(value)
                ->show();
        }
        cnt++;
    }

    while (cnt < info_items.size())
    {
        info_items[cnt]->hide();
        cnt++;
    }

    bool gm_functions_changed = gm_script_options->entryCount() != int(gameGlobalInfo->gm_callback_functions.size());
    auto it = gameGlobalInfo->gm_callback_functions.begin();
    for (int n = 0; !gm_functions_changed && n<gm_script_options->entryCount(); n++)
    {
        if (gm_script_options->getEntryName(n) != it->name)
            gm_functions_changed = true;
        it++;
    }

    if (gm_functions_changed)
    {
        gm_script_options->setOptions({});
        for (const GMScriptCallback& callback : gameGlobalInfo->gm_callback_functions)
            gm_script_options->addEntry(callback.name, callback.name);
    }

    if (!gameGlobalInfo->gm_messages.empty())
    {
        const auto& message = gameGlobalInfo->gm_messages.front();
        message_text->setText(message);
        message_frame->show();
    }
    else
        message_frame->hide();

    P<MouseRenderer> mouse_renderer = engine->getObject("mouseRenderer");

    auto mods = SDL_GetModState();
    if (click_and_drag_state == ClickAndDragState::None
        || click_and_drag_state == ClickAndDragState::ClickSelectOrBoxSelect)
    {
        gm_cursor_mode = GMCursorMode::None;
        if (mods & KMOD_SHIFT) gm_cursor_mode |= GMCursorMode::AddToSelection;
        if (mods & KMOD_CTRL) gm_cursor_mode |= GMCursorMode::SelectShips;
        if (mods & KMOD_ALT) gm_cursor_mode |= GMCursorMode::SelectFaction;
    }
    else if (click_and_drag_state == ClickAndDragState::BoxSelect)
    {
        gm_cursor_mode = GMCursorMode::SelectArea;
        if (mods & KMOD_SHIFT) gm_cursor_mode |= GMCursorMode::AddToSelection;
        if (mods & KMOD_CTRL) gm_cursor_mode |= GMCursorMode::SelectShips;
        if (mods & KMOD_ALT) gm_cursor_mode |= GMCursorMode::SelectFaction;
    }
    else if (click_and_drag_state == ClickAndDragState::DragViewOrOrder)
        gm_cursor_mode = GMCursorMode::SetAITarget;
    else if (click_and_drag_state == ClickAndDragState::DragView)
        gm_cursor_mode = GMCursorMode::PanCamera;
    else if (click_and_drag_state == ClickAndDragState::ClickSelectOrDragObjects
             || click_and_drag_state == ClickAndDragState::DragObjects)
        gm_cursor_mode = GMCursorMode::MoveEntities;

    if (mouse_renderer)
    {
        mouse_renderer->setCursorHotspotTopLeft();
        mouse_renderer->clearOverlays();

        if ((gm_cursor_mode & GMCursorMode::MoveEntities) != GMCursorMode::None)
        {
            mouse_renderer->setPrimary("cursors/mouse.png");
            mouse_renderer->addOverlay("cursors/mouse_pan.png", {20.0f, 20.0f}, 32.0f, {255, 255, 255, 255});
        }
        else if ((gm_cursor_mode & GMCursorMode::SetAITarget) != GMCursorMode::None)
        {
            mouse_renderer->setPrimary("cursors/mouse_ai_target.png", 32.0f, {255, 64, 64, 255});
            mouse_renderer->setCursorHotspotCenter();
        }
        else if ((gm_cursor_mode & GMCursorMode::ZoomCamera) != GMCursorMode::None)
        {
            mouse_renderer->setPrimary("cursors/mouse_zoom.png");
            mouse_renderer->setCursorHotspotCenter();
        }
        else if ((gm_cursor_mode & GMCursorMode::PanCamera) != GMCursorMode::None)
        {
            mouse_renderer->setPrimary("cursors/mouse_pan.png", 32.0f, {192, 192, 255, 255});
            mouse_renderer->setCursorHotspotCenter();
        }
        else
        {
            mouse_renderer->setPrimary("cursors/mouse.png");

            if ((gm_cursor_mode & GMCursorMode::SelectArea) != GMCursorMode::None)
                mouse_renderer->addOverlay("cursors/mouse_selection.png", {16.0f, 16.0f}, 32.0f, {192, 192, 255, 255});

            glm::u8vec4 overlay_color = {192, 192, 255, 255};
            if ((gm_cursor_mode & GMCursorMode::SelectFaction) != GMCursorMode::None)
                if (auto* info = FactionInfo::find(faction_selector->getSelectionValue()))
                    overlay_color = info->gm_color;

            if ((gm_cursor_mode & GMCursorMode::SelectShips) != GMCursorMode::None)
                mouse_renderer->addOverlay("cursors/mouse_ship.png", {20.0f, 20.0f}, 32.0f, overlay_color);
            else if ((gm_cursor_mode & GMCursorMode::SelectFaction) != GMCursorMode::None)
                mouse_renderer->addOverlay("cursors/mouse_faction.png", {20.0f, 20.0f}, 32.0f, overlay_color);

            if ((gm_cursor_mode & GMCursorMode::AddToSelection) != GMCursorMode::None)
                mouse_renderer->addOverlay("cursors/mouse_create.png", {10.0f, -5.0f}, 32.0f, overlay_color);
        }
    }
}

void LimitedGameMasterScreen::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position)
{
    if (click_and_drag_state != ClickAndDragState::None) return;

    if (button == sp::io::Pointer::Button::Left && main_radar->getWaypoints())
    {
        float min_drag_distance = main_radar->getDistance() / 450.0f * 10.0f;
        glm::vec2 click_screen = main_radar->worldToScreen(position);
        int max_sets = (gameGlobalInfo && gameGlobalInfo->enable_multiple_waypoint_sets) ? Waypoints::MAX_SETS : 1;
        for (auto [entity, waypoints] : sp::ecs::Query<Waypoints>())
        {
            for (auto& wp : waypoints.waypoints)
            {
                if (wp.set_id < 1 || wp.set_id > max_sets) continue;
                if (gm_delete_waypoint_mode)
                {
                    glm::vec2 wp_screen = main_radar->worldToScreen(wp.position);
                    glm::vec2 delta = click_screen - wp_screen;
                    if (delta.x >= -30.0f && delta.x <= 30.0f && delta.y >= -22.0f && delta.y <= 18.0f)
                    {
                        runScript("commandRemoveWaypoint(entityFromString('" + getEntityStringForLua(entity) + "'), " + string(wp.id) + ", " + string(wp.set_id) + ")");
                        return;
                    }
                }
                else if (glm::length(wp.position - position) < min_drag_distance)
                {
                    gm_drag_waypoint_id  = wp.id;
                    gm_drag_waypoint_set = wp.set_id;
                    gm_drag_waypoint_ship = entity;
                    drag_start_position = position;
                    drag_previous_position = position;
                    return;
                }
            }
        }
    }

    if (gm_add_waypoint_mode || gm_delete_waypoint_mode)
        return;

    if (button == sp::io::Pointer::Button::Right)
    {
        if (has_cpu_ship) click_and_drag_state = ClickAndDragState::DragViewOrOrder;
        else click_and_drag_state = ClickAndDragState::DragView;
    }
    else
    {
        click_and_drag_state = ClickAndDragState::ClickSelectOrBoxSelect;
        float min_drag_distance = main_radar->getDistance() / 450.0f * 10.0f;

        for (auto obj : targets.getTargets())
        {
            if (auto transform = obj.getComponent<sp::Transform>())
            {
                if (glm::length(transform->getPosition() - position) < min_drag_distance)
                    click_and_drag_state = ClickAndDragState::ClickSelectOrDragObjects;
            }
        }
    }
    drag_start_position = position;
    drag_previous_position = position;
}

void LimitedGameMasterScreen::onMouseDrag(glm::vec2 position)
{
    if (gm_drag_waypoint_id >= 0)
    {
        if (auto wp = gm_drag_waypoint_ship.getComponent<Waypoints>())
            wp->move(gm_drag_waypoint_id, position, gm_drag_waypoint_set);
        drag_previous_position = position;
        return;
    }

    switch(click_and_drag_state)
    {
    case ClickAndDragState::DragViewOrOrder:
    case ClickAndDragState::DragView:
        click_and_drag_state = ClickAndDragState::DragView;
        main_radar->setViewPosition(main_radar->getViewPosition() - (position - drag_previous_position));
        position -= (position - drag_previous_position);
        break;
    case ClickAndDragState::ClickSelectOrDragObjects:
    case ClickAndDragState::DragObjects:
        if (click_and_drag_state == ClickAndDragState::ClickSelectOrDragObjects)
        {
            drag_entity_original_positions.clear();
            drag_total_offset = {0.0f, 0.0f};
            for (auto entity : targets.getTargets())
                if (auto transform = entity.getComponent<sp::Transform>())
                    drag_entity_original_positions.emplace_back(entity, transform->getPosition());
        }
        click_and_drag_state = ClickAndDragState::DragObjects;
        tweak_dialog->setDragActive(true);
        drag_total_offset += (position - drag_previous_position);
        break;
    case ClickAndDragState::ClickSelectOrBoxSelect:
    case ClickAndDragState::BoxSelect:
        click_and_drag_state = ClickAndDragState::BoxSelect;
        {
            auto p0 = main_radar->worldToScreen(drag_start_position);
            auto p1 = main_radar->worldToScreen(position);
            if (p0.x > p1.x) std::swap(p0.x, p1.x);
            if (p0.y > p1.y) std::swap(p0.y, p1.y);
            box_selection_overlay->show();
            box_selection_overlay->setPosition(p0, sp::Alignment::TopLeft);
            box_selection_overlay->setSize(p1 - p0);
        }
        break;
    default:
        break;
    }
    drag_previous_position = position;
}

void LimitedGameMasterScreen::onMouseUp(glm::vec2 position)
{
    if (gm_drag_waypoint_id >= 0)
    {
        runScript("commandMoveWaypoint(entityFromString('" + getEntityStringForLua(gm_drag_waypoint_ship) + "'), " + string(gm_drag_waypoint_id) + ", " + string(position.x) + ", " + string(position.y) + ", " + string(gm_drag_waypoint_set) + ")");
        gm_drag_waypoint_id  = -1;
        gm_drag_waypoint_set = -1;
        gm_drag_waypoint_ship = {};
        return;
    }

    if (gm_add_waypoint_mode && gm_waypoint_target_ship)
    {
        string entity_str = getEntityStringForLua(gm_waypoint_target_ship);
        runScript("commandAddWaypoint(entityFromString('" + entity_str + "'), " + string(position.x) + ", " + string(position.y) + ", " + string(gm_waypoint_set) + ")");
        gm_add_waypoint_mode = false;
        gm_waypoint_target_ship = {};
        gm_add_waypoint_button->setValue(false);
        return;
    }

    if (click_and_drag_state == ClickAndDragState::DragObjects)
    {
        tweak_dialog->setDragActive(false);
        for (auto& [entity, original_pos] : drag_entity_original_positions)
        {
            auto final_pos = original_pos + drag_total_offset;
            runScriptForEntity(getEntityStringForLua(entity), ".components.transform.position = {" + string(final_pos.x) + ", " + string(final_pos.y) + "}");
        }
        drag_entity_original_positions.clear();
        goto cleanup;
    }

    {
    auto mods = SDL_GetModState();
    const bool shift_down = mods & KMOD_SHIFT;
    const bool ctrl_down = mods & KMOD_CTRL;
    const bool alt_down = mods & KMOD_ALT;

    switch (click_and_drag_state)
    {
    case ClickAndDragState::DragViewOrOrder:
        {
            sp::ecs::Entity target_entity;
            glm::vec2 target_position;

            for (auto entity : sp::TransformQuery::queryArea(position, position))
            {
                auto transform = entity.getComponent<sp::Transform>();
                if (!transform) continue;
                if (!target_entity || glm::length(position - transform->getPosition()) < glm::length(position - target_position))
                {
                    target_entity = entity;
                    target_position = transform->getPosition();
                }
            }

            glm::vec2 upper_bound(-std::numeric_limits<float>::max(), -std::numeric_limits<float>::max());
            glm::vec2 lower_bound(std::numeric_limits<float>::max(), std::numeric_limits<float>::max());

            for (auto entity : targets.getTargets())
            {
                if (!entity.hasComponent<AIController>()) continue;
                auto transform = entity.getComponent<sp::Transform>();
                if (!transform) continue;

                lower_bound.x = std::min(lower_bound.x, transform->getPosition().x);
                lower_bound.y = std::min(lower_bound.y, transform->getPosition().y);
                upper_bound.x = std::max(upper_bound.x, transform->getPosition().x);
                upper_bound.y = std::max(upper_bound.y, transform->getPosition().y);
            }
            glm::vec2 objects_center = (upper_bound + lower_bound) / 2.0f;

            for (auto entity : targets.getTargets())
            {
                if (target_entity && target_entity != entity && target_entity.hasComponent<Hull>())
                {
                    if (Faction::getRelation(entity, target_entity) == FactionRelation::Enemy)
                    {
                        if (my_player_info)
                            my_player_info->commandSetAIOrder(entity, AIOrder::Attack, target_entity);
                    }
                    else
                    {
                        auto port = entity.getComponent<DockingPort>();
                        auto bay = target_entity.getComponent<DockingBay>();
                        if (!shift_down && port && bay && port->canDockOn(*bay) != DockingStyle::None)
                        {
                            if (my_player_info)
                                my_player_info->commandSetAIOrder(entity, AIOrder::Dock, target_entity);
                        }
                        else
                        {
                            if (my_player_info)
                                my_player_info->commandSetAIOrder(entity, AIOrder::DefendTarget, target_entity);
                        }
                    }
                }
                else
                {
                    glm::vec2 target_loc;
                    if (auto transform = entity.getComponent<sp::Transform>())
                        target_loc = position + transform->getPosition() - objects_center;
                    else
                        target_loc = position;

                    string order_str = shift_down ? "Fly towards (ignore all)" : "Fly towards";
                    runScriptForEntity(getEntityStringForLua(entity), ".components.ai_controller.orders = '" + order_str + "'; " + getEntityStringForLua(entity) + ".components.ai_controller.order_target_location = {" + string(target_loc.x) + ", " + string(target_loc.y) + "}");
                }
                if (auto gravity = entity.getComponent<Gravity>())
                {
                    if (gravity->wormhole_target.x || gravity->wormhole_target.y)
                        runScriptForEntity(getEntityStringForLua(entity), ".components.gravity.wormhole_target = {" + string(position.x) + ", " + string(position.y) + "}");
                }
            }
        }
        break;
    case ClickAndDragState::ClickSelectOrBoxSelect:
    case ClickAndDragState::ClickSelectOrDragObjects:
    case ClickAndDragState::BoxSelect:
        {
            std::vector<sp::ecs::Entity> entities;
            auto findTargets = [&](std::function<void(sp::ecs::Entity, sp::Transform&)> found)
            {
                for (auto [entity, transform, physics] : sp::ecs::Query<sp::Transform, sp::ecs::optional<sp::Physics>>())
                {
                    auto size = physics ? std::max(physics->getSize().x, physics->getSize().y) : 0.0f;
                    if (transform.getPosition().x + size < std::min(drag_start_position.x, position.x)) continue;
                    if (transform.getPosition().x - size > std::max(drag_start_position.x, position.x)) continue;
                    if (transform.getPosition().y + size < std::min(drag_start_position.y, position.y)) continue;
                    if (transform.getPosition().y - size > std::max(drag_start_position.y, position.y)) continue;
                    if (ctrl_down
                        && !entity.hasComponent<PlayerControl>()
                        && !entity.hasComponent<AIController>()
                        && !entity.hasComponent<DockingBay>()
                    )
                        continue;
                    if (alt_down
                        && (!entity.hasComponent<Faction>()
                            || (Faction::getInfo(entity).name != faction_selector->getSelectionValue()))
                    )
                        continue;

                    found(entity, transform);
                }
            };

            if (click_and_drag_state == ClickAndDragState::BoxSelect)
                findTargets([&](auto entity, auto) { entities.push_back(entity); });
            else
            {
                sp::ecs::Entity closest_entity;
                float closest_score = std::numeric_limits<float>::max();
                glm::vec2 click_screen = main_radar->worldToScreen(position);

                findTargets([&](sp::ecs::Entity entity, sp::Transform& transform)
                    {
                        const float screen_dist = glm::length(main_radar->worldToScreen(transform.getPosition()) - click_screen);
                        float screen_radius = 0.0f;

                        if (auto physics = entity.getComponent<sp::Physics>())
                            screen_radius = physics->getSize().x * main_radar->getScale();

                        const float score = std::max(0.0f, screen_dist - screen_radius);
                        if (score < closest_score)
                        {
                            closest_score = score;
                            closest_entity = entity;
                        }
                    }
                );

                if (closest_score != std::numeric_limits<float>::max())
                    entities.push_back(closest_entity);
            }

            if (shift_down) for (auto e : entities) targets.add(e);
            else targets.set(entities);

            if (entities.size() > 0)
            {
                for (int n = 0; n < faction_selector->entryCount(); n++)
                {
                    if (faction_selector->getEntryValue(n) == Faction::getInfo(entities[0]).name)
                        faction_selector->setSelectionIndex(n);
                }
            }
        }
        break;
    default:
        break;
    }
    }

cleanup:
    click_and_drag_state = ClickAndDragState::None;
    box_selection_overlay->hide();
}

void LimitedGameMasterScreen::onMouseWheel(float value, glm::vec2 position)
{
    const float view_distance = std::clamp(
        main_radar->getDistance() * (1.0f - value * 0.1f),
        MIN_ZOOM_DISTANCE,
        MAX_ZOOM_DISTANCE
    );

    const glm::vec2 world_position_before_zoom = main_radar->screenToWorld(position);

    main_radar->setDistance(view_distance);
    zoom_slider->setValue(view_distance);
    if (view_distance <= SHORT_RANGE_DISTANCE) main_radar->shortRange();
    else main_radar->longRange();

    main_radar->setViewPosition(main_radar->getViewPosition() + world_position_before_zoom - main_radar->screenToWorld(position));
}

std::vector<sp::ecs::Entity> LimitedGameMasterScreen::getSelection()
{
    return targets.getTargets();
}

GameMasterChatDialog* LimitedGameMasterScreen::getChatDialog(sp::ecs::Entity entity)
{
    for (auto d : chat_dialog_per_ship)
        if (d->player == entity) return d;

    auto dialog = new GameMasterChatDialog(chat_layer, main_radar, entity);
    dialog
        ->setPosition(0.0f, 0.0f)
        ->setSize(300.0f, 300.0f);
    chat_dialog_per_ship.push_back(dialog);
    return dialog;
}

string LimitedGameMasterScreen::getEntityStringForLua(sp::ecs::Entity entity)
{
    if (auto si = entity.getComponent<ServerIndex>())
        return string(si->index) + ":" + string(si->version);
    return entity.toString();
}

void LimitedGameMasterScreen::runScript(const string& code)
{
    if (gameMasterActions)
        gameMasterActions->commandRunScript(code);
}

void LimitedGameMasterScreen::runScriptForEntity(const string& entity_str, const string& expression)
{
    runScript("entityFromString('" + entity_str + "')" + expression);
}
