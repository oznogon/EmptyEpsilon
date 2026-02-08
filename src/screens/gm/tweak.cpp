#include <i18n.h>
#include "tweak.h"
#include "playerInfo.h"
#include "components/collision.h"
#include "components/database.h"
#include "components/name.h"
#include "components/ai.h"
#include "ai/ai.h"
#include "components/avoidobject.h"
#include "components/beamweapon.h"
#include "components/comms.h"
#include "components/coolant.h"
#include "components/docking.h"
#include "components/gravity.h"
#include "components/hacking.h"
#include "components/hull.h"
#include "components/impulse.h"
#include "components/internalrooms.h"
#include "components/jumpdrive.h"
#include "components/lifetime.h"
#include "components/maneuveringthrusters.h"
#include "components/missile.h"
#include "components/missiletubes.h"
#include "components/moveto.h"
#include "components/name.h"
#include "components/orbit.h"
#include "components/pickup.h"
#include "components/player.h"
#include "components/probe.h"
#include "components/radar.h"
#include "components/radarblock.h"
#include "components/reactor.h"
#include "components/rendering.h"
#include "components/scanning.h"
#include "components/selfdestruct.h"
#include "components/shields.h"
#include "components/spin.h"
#include "components/warpdrive.h"
#include "components/zone.h"


#include "gui/gui2_listbox.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"
#include "gui/gui2_textentry.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_slider.h"
#include "gui/gui2_togglebutton.h"
#include "gui/gui2_scrolltext.h"
#include "ecs/query.h"
#include "components/faction.h"
#include "engine.h"


// Conversion function for AIOrder enum
static string getAIOrderString(AIOrder order)
{
    switch(order)
    {
    case AIOrder::Idle: return tr("ai_order", "Idle");
    case AIOrder::Roaming: return tr("ai_order", "Roaming");
    case AIOrder::Retreat: return tr("ai_order", "Retreat");
    case AIOrder::StandGround: return tr("ai_order", "Stand Ground");
    case AIOrder::DefendLocation: return tr("ai_order", "Defend Location");
    case AIOrder::DefendTarget: return tr("ai_order", "Defend Target");
    case AIOrder::FlyFormation: return tr("ai_order", "Fly in formation");
    case AIOrder::FlyTowards: return tr("ai_order", "Fly towards");
    case AIOrder::FlyTowardsBlind: return tr("ai_order", "Fly towards (ignore all)");
    case AIOrder::Dock: return tr("ai_order", "Dock");
    case AIOrder::Attack: return tr("ai_order", "Attack");
    }
    return "Unknown";
}

// Conversion function for DockingPort::State enum
static string getDockingStateString(DockingPort::State state)
{
    switch(state)
    {
    case DockingPort::State::NotDocking: return tr("docking_state", "Not docking");
    case DockingPort::State::Docking: return tr("docking_state", "Docking");
    case DockingPort::State::Docked: return tr("docking_state", "Docked");
    }
    return "Unknown";
}


class GuiTextTweak : public GuiTextEntry {
public:
    GuiTextTweak(GuiContainer* owner) : GuiTextEntry(owner, "", "") {
        setSize(GuiElement::GuiSizeMax, 30);
        setTextSize(20);
    }
    virtual void onDraw(sp::RenderTarget& target) override {
        if (!focus) setText(update_func());
        GuiTextEntry::onDraw(target);
    }
    std::function<string()> update_func;
};
class GuiSliderTweak : public GuiSlider {
public:
    GuiSliderTweak(GuiContainer* owner, const string& label, float min_value, float max_value, float start_value, GuiSlider::func_t callback)
    : GuiSlider(owner, "", min_value, max_value, start_value, callback)
    {
        setSize(GuiElement::GuiSizeMax, 30.0f);
    }
    virtual void onDraw(sp::RenderTarget& target) override {
        if (!focus && update_func) setValue(update_func());
        GuiSlider::onDraw(target);
    }
    std::function<float()> update_func;
};
class GuiToggleTweak : public GuiToggleButton {
public:
    GuiToggleTweak(GuiContainer* owner, const string& label, GuiToggleButton::func_t callback) : GuiToggleButton(owner, "", label, callback) {
        setSize(GuiElement::GuiSizeMax, 30);
        setTextSize(20);
    }
    virtual void onDraw(sp::RenderTarget& target) override {
        if (update_func) setValue(update_func());
        GuiToggleButton::onDraw(target);
    }
    std::function<bool()> update_func;
};
class GuiVectorTweak : public GuiSelector {
public:
    GuiVectorTweak(GuiContainer* owner, string id)
    : GuiSelector(owner, id, [](int index, string value) {}) {
        setSize(GuiElement::GuiSizeMax, 30);
        setTextSize(20);
    }
    virtual void onDraw(sp::RenderTarget& target) override {
        if (update_func) {
            int count = update_func();
            while(count > entryCount())
                addEntry(string(entryCount()+1), entryCount());
            while(count < entryCount())
                removeEntry(entryCount()-1);
        }
        GuiSelector::onDraw(target);
    }
    std::function<size_t()> update_func;
};
class GuiSelectorTweak : public GuiSelector {
public:
    GuiSelectorTweak(GuiContainer* owner, string id, GuiSelector::func_t callback)
    : GuiSelector(owner, id, callback) {
        setSize(GuiElement::GuiSizeMax, 30);
        setTextSize(20);
    }
    virtual void onDraw(sp::RenderTarget& target) override {
        if (update_func) {
            auto new_index = update_func();
            if (new_index != getSelectionIndex())
                setSelectionIndex(new_index);
        }
        GuiSelector::onDraw(target);
    }
    std::function<int()> update_func;
};

// Widget for selecting entities from the game world
class GuiEntityPicker : public GuiSelector {
public:
    GuiEntityPicker(GuiContainer* owner, string id, GuiSelector::func_t callback)
    : GuiSelector(owner, id, callback) {
        setSize(GuiElement::GuiSizeMax, 30);
        setTextSize(20);
        addEntry(tr("tweak-entity", "(None)"), "");
    }
    virtual void onDraw(sp::RenderTarget& target) override {
        updateEntityList();
        if (update_func) {
            auto entity = update_func();
            if (!entity) {
                setSelectionIndex(0); // None
            } else {
                // Find entity in list
                string search_key = getEntityKey(entity);
                for(int i = 0; i < entryCount(); i++) {
                    if (getEntryValue(i) == search_key) {
                        if (getSelectionIndex() != i)
                            setSelectionIndex(i);
                        break;
                    }
                }
            }
        }
        GuiSelector::onDraw(target);
    }
    std::function<sp::ecs::Entity()> update_func;

private:
    float last_update_time = 0.0f;

    void updateEntityList() {
        // Update entity list every 1 second to avoid performance issues
        if (engine->getElapsedTime() - last_update_time < 1.0f)
            return;
        last_update_time = engine->getElapsedTime();

        int current_selection = getSelectionIndex();
        string current_value = current_selection >= 0 ? getEntryValue(current_selection) : "";

        // Clear all except "(None)" entry
        while(entryCount() > 1)
            removeEntry(entryCount() - 1);

        // Add all entities with callsigns
        for(auto [entity, callsign] : sp::ecs::Query<CallSign>()) {
            string label = callsign.callsign;
            if (auto type_name = entity.getComponent<TypeName>())
                label = label + " (" + type_name->type_name + ")";
            addEntry(label, getEntityKey(entity));
        }

        // Restore selection if entity still exists
        if (!current_value.empty()) {
            for(int i = 0; i < entryCount(); i++) {
                if (getEntryValue(i) == current_value) {
                    setSelectionIndex(i);
                    return;
                }
            }
        }
        setSelectionIndex(0); // Default to None
    }

    string getEntityKey(sp::ecs::Entity entity) {
        return entity.toString();
    }
};

// Widget for selecting Database entities as parent (filtered to only Database entities)
class GuiDatabaseParentPicker : public GuiSelector {
public:
    GuiDatabaseParentPicker(GuiContainer* owner, string id, GuiSelector::func_t callback)
    : GuiSelector(owner, id, callback) {
        setSize(GuiElement::GuiSizeMax, 30);
        setTextSize(20);
        addEntry(tr("tweak-entity", "(None)"), "");
    }

    virtual void onDraw(sp::RenderTarget& target) override {
        updateEntityList();
        if (update_func) {
            auto entity = update_func();
            if (!entity) {
                setSelectionIndex(0); // None
            } else {
                // Find entity in list
                string search_key = getEntityKey(entity);
                for(int i = 0; i < entryCount(); i++) {
                    if (getEntryValue(i) == search_key) {
                        if (getSelectionIndex() != i)
                            setSelectionIndex(i);
                        break;
                    }
                }
            }
        }
        GuiSelector::onDraw(target);
    }
    std::function<sp::ecs::Entity()> update_func;

private:
    float last_update_time = 0.0f;

    void updateEntityList() {
        // Update entity list every 1 second to avoid performance issues
        if (engine->getElapsedTime() - last_update_time < 1.0f)
            return;
        last_update_time = engine->getElapsedTime();

        int current_selection = getSelectionIndex();
        string current_value = current_selection >= 0 ? getEntryValue(current_selection) : "";

        // Clear all except "(None)" entry
        while(entryCount() > 1)
            removeEntry(entryCount() - 1);

        // Add all Database entities
        for(auto [entity, db] : sp::ecs::Query<Database>()) {
            string label = db.name.empty() ? "(unnamed)" : db.name;
            // Show parent name if available
            if (db.parent) {
                if (auto parent_db = db.parent.getComponent<Database>()) {
                    label = parent_db->name + " > " + label;
                }
            }
            addEntry(label, getEntityKey(entity));
        }

        // Restore selection if entity still exists
        if (!current_value.empty()) {
            for(int i = 0; i < entryCount(); i++) {
                if (getEntryValue(i) == current_value) {
                    setSelectionIndex(i);
                    return;
                }
            }
        }
        setSelectionIndex(0); // Default to None
    }

    string getEntityKey(sp::ecs::Entity entity) {
        return entity.toString();
    }
};

// Widget for editing 2D vector values
class GuiVec2Tweak : public GuiElement {
public:
    GuiVec2Tweak(GuiContainer* owner) : GuiElement(owner, "") {
        setSize(GuiElement::GuiSizeMax, 30);
        setAttribute("layout", "horizontal");

        auto x_label = new GuiLabel(this, "", "X:", 20);
        x_label->setSize(20, 30);

        x_input = new GuiTextEntry(this, "", "");
        x_input->setSize(GuiElement::GuiSizeMax, 30);
        x_input->setTextSize(20);
        x_input->callback([this](string text) {
            if (callback) {
                glm::vec2 value = update_func ? update_func() : glm::vec2(0, 0);
                value.x = text.toFloat();
                callback(value);
            }
        });

        auto y_label = new GuiLabel(this, "", "Y:", 20);
        y_label->setSize(20, 30);

        y_input = new GuiTextEntry(this, "", "");
        y_input->setSize(GuiElement::GuiSizeMax, 30);
        y_input->setTextSize(20);
        y_input->callback([this](string text) {
            if (callback) {
                glm::vec2 value = update_func ? update_func() : glm::vec2(0, 0);
                value.y = text.toFloat();
                callback(value);
            }
        });
    }

    virtual void onDraw(sp::RenderTarget& target) override {
        if (update_func) {
            glm::vec2 value = update_func();
            // Only update if text hasn't been manually changed
            if (x_input->getText().toFloat() != value.x)
                x_input->setText(string(value.x, 1));
            if (y_input->getText().toFloat() != value.y)
                y_input->setText(string(value.y, 1));
        }
        GuiElement::onDraw(target);
    }

    std::function<glm::vec2()> update_func;
    std::function<void(glm::vec2)> callback;

private:
    GuiTextEntry* x_input;
    GuiTextEntry* y_input;
};

// Widget for editing RGBA color values
class GuiColorPicker : public GuiElement {
public:
    GuiColorPicker(GuiContainer* owner) : GuiElement(owner, "") {
        setSize(GuiElement::GuiSizeMax, 120);
        setAttribute("layout", "vertical");

        // Red slider
        auto r_row = new GuiElement(this, "");
        r_row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");
        auto r_label = new GuiLabel(r_row, "", "R:", 20);
        r_label->setSize(30, 30);
        r_slider = new GuiSlider(r_row, "", 0.0f, 255.0f, 0.0f, [this](float value) {
            if (callback && update_func) {
                auto color = update_func();
                color.r = static_cast<uint8_t>(value);
                callback(color);
            }
        });
        r_slider->setSize(GuiElement::GuiSizeMax, 30);
        r_slider->addSnapValue(0.0f, 1.0f);
        r_slider->addSnapValue(255.0f, 1.0f);
        r_slider->addOverlay(0u, 20.0f);

        // Green slider
        auto g_row = new GuiElement(this, "");
        g_row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");
        auto g_label = new GuiLabel(g_row, "", "G:", 20);
        g_label->setSize(30, 30);
        g_slider = new GuiSlider(g_row, "", 0.0f, 255.0f, 0.0f, [this](float value) {
            if (callback && update_func) {
                auto color = update_func();
                color.g = static_cast<uint8_t>(value);
                callback(color);
            }
        });
        g_slider->setSize(GuiElement::GuiSizeMax, 30);
        g_slider->addSnapValue(0.0f, 1.0f);
        g_slider->addSnapValue(255.0f, 1.0f);
        g_slider->addOverlay(0u, 20.0f);

        // Blue slider
        auto b_row = new GuiElement(this, "");
        b_row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");
        auto b_label = new GuiLabel(b_row, "", "B:", 20);
        b_label->setSize(30, 30);
        b_slider = new GuiSlider(b_row, "", 0.0f, 255.0f, 0.0f, [this](float value) {
            if (callback && update_func) {
                auto color = update_func();
                color.b = static_cast<uint8_t>(value);
                callback(color);
            }
        });
        b_slider->setSize(GuiElement::GuiSizeMax, 30);
        b_slider->addSnapValue(0.0f, 1.0f);
        b_slider->addSnapValue(255.0f, 1.0f);
        b_slider->addOverlay(0u, 20.0f);

        // Alpha slider
        auto a_row = new GuiElement(this, "");
        a_row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");
        auto a_label = new GuiLabel(a_row, "", "A:", 20);
        a_label->setSize(30, 30);
        a_slider = new GuiSlider(a_row, "", 0.0f, 255.0f, 255.0f, [this](float value) {
            if (callback && update_func) {
                auto color = update_func();
                color.a = static_cast<uint8_t>(value);
                callback(color);
            }
        });
        a_slider->setSize(GuiElement::GuiSizeMax, 30);
        a_slider->addSnapValue(0.0f, 1.0f);
        a_slider->addSnapValue(255.0f, 1.0f);
        a_slider->addOverlay(0u, 20.0f);
    }

    virtual void onDraw(sp::RenderTarget& target) override {
        if (update_func) {
            auto color = update_func();
            r_slider->setValue(static_cast<float>(color.r));
            g_slider->setValue(static_cast<float>(color.g));
            b_slider->setValue(static_cast<float>(color.b));
            a_slider->setValue(static_cast<float>(color.a));
        }
        GuiElement::onDraw(target);
    }

    std::function<glm::u8vec4()> update_func;
    std::function<void(glm::u8vec4)> callback;

private:
    GuiSlider* r_slider;
    GuiSlider* g_slider;
    GuiSlider* b_slider;
    GuiSlider* a_slider;
};

// Widget for editing multiline text
class GuiMultilineTextTweak : public GuiScrollText {
public:
    GuiMultilineTextTweak(GuiContainer* owner, int lines = 5)
    : GuiScrollText(owner, "", "") {
        setSize(GuiElement::GuiSizeMax, lines * 30);
        setTextSize(18);
    }

    virtual void onDraw(sp::RenderTarget& target) override {
        if (update_func) {
            setText(update_func());
        }
        GuiScrollText::onDraw(target);
    }

    std::function<string()> update_func;
    // Note: GuiScrollText is read-only; for editable multiline text,
    // would need to create a custom widget or use GuiTextEntry with newlines enabled
};

// Widget for selecting from faction list
class GuiFactionSelectorTweak : public GuiSelector {
public:
    GuiFactionSelectorTweak(GuiContainer* owner, string id, GuiSelector::func_t callback)
    : GuiSelector(owner, id, callback) {
        setSize(GuiElement::GuiSizeMax, 30);
        setTextSize(20);
        addEntry(tr("tweak-faction", "(None)"), "");
    }

    virtual void onDraw(sp::RenderTarget& target) override {
        updateFactionList();
        if (update_func) {
            auto faction_entity = update_func();
            if (!faction_entity) {
                setSelectionIndex(0); // None
            } else {
                // Find faction in list
                string search_key = faction_entity.toString();
                for(int i = 0; i < entryCount(); i++) {
                    if (getEntryValue(i) == search_key) {
                        if (getSelectionIndex() != i)
                            setSelectionIndex(i);
                        break;
                    }
                }
            }
        }
        GuiSelector::onDraw(target);
    }

    std::function<sp::ecs::Entity()> update_func;

private:
    float last_update_time = 0.0f;

    void updateFactionList() {
        // Update faction list every 1 second
        if (engine->getElapsedTime() - last_update_time < 1.0f)
            return;
        last_update_time = engine->getElapsedTime();

        int current_selection = getSelectionIndex();
        string current_value = current_selection >= 0 ? getEntryValue(current_selection) : "";

        // Clear all except "(None)" entry
        while(entryCount() > 1)
            removeEntry(entryCount() - 1);

        // Add all factions
        for(auto [entity, faction_info] : sp::ecs::Query<FactionInfo>()) {
            addEntry(faction_info.name, entity.toString());
        }

        // Restore selection if faction still exists
        if (!current_value.empty()) {
            for(int i = 0; i < entryCount(); i++) {
                if (getEntryValue(i) == current_value) {
                    setSelectionIndex(i);
                    return;
                }
            }
        }
        setSelectionIndex(0); // Default to None
    }
};

// Widget for editing unordered_set<string>
class GuiStringSetTweak : public GuiElement {
public:
    GuiStringSetTweak(GuiContainer* owner) : GuiElement(owner, "") {
        setSize(GuiElement::GuiSizeMax, 150);
        setAttribute("layout", "vertical");

        // List of current items
        item_list = new GuiListbox(this, "", [this](int index, string value) {
            selected_index = index;
        });
        item_list
            ->setTextSize(18.0f)
            ->setButtonHeight(20.0f)
            ->setSize(GuiElement::GuiSizeMax, 90);

        // Add new item controls
        auto add_row = new GuiElement(this, "");
        add_row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");

        new_item_entry = new GuiTextEntry(add_row, "", "");
        new_item_entry->setTextSize(18)->setSize(GuiElement::GuiSizeMax, 30);

        auto add_button = new GuiButton(add_row, "", tr("tweak-button", "Add"), [this]() {
            string new_item = new_item_entry->getText();
            if (!new_item.empty() && on_add) {
                on_add(new_item);
                new_item_entry->setText("");
            }
        });
        add_button->setTextSize(18)->setSize(60, 30);

        auto del_button = new GuiButton(add_row, "", tr("tweak-button", "Delete"), [this]() {
            if (selected_index >= 0 && selected_index < item_list->entryCount() && on_remove) {
                string item = item_list->getEntryValue(selected_index);
                on_remove(item);
                selected_index = -1;
            }
        });
        del_button->setTextSize(18)->setSize(60, 30);
    }

    virtual void onDraw(sp::RenderTarget& target) override {
        if (update_func) {
            auto current_set = update_func();

            // Rebuild list if set changed
            if (current_set.size() != static_cast<size_t>(item_list->entryCount())) {
                item_list->setOptions({});
                for(const auto& item : current_set) {
                    item_list->addEntry(item, item);
                }
            }
        }
        GuiElement::onDraw(target);
    }

    std::function<std::unordered_set<string>()> update_func;
    std::function<void(const string&)> on_add;
    std::function<void(const string&)> on_remove;

private:
    GuiListbox* item_list;
    GuiTextEntry* new_item_entry;
    int selected_index = -1;
};

// Widget for editing unordered_map<string, string>
class GuiStringMapTweak : public GuiElement {
public:
    GuiStringMapTweak(GuiContainer* owner) : GuiElement(owner, "") {
        setSize(GuiElement::GuiSizeMax, 180);
        setAttribute("layout", "vertical");

        // List of current key-value pairs
        item_list = new GuiListbox(this, "", [this](int index, string value) {
            selected_index = index;
        });
        item_list
            ->setTextSize(18.0f)
            ->setButtonHeight(20.0f)
            ->setSize(GuiElement::GuiSizeMax, 90);

        // Add new item controls
        auto add_row = new GuiElement(this, "");
        add_row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");

        key_entry = new GuiTextEntry(add_row, "", "");
        key_entry->setTextSize(18)->setSize(GuiElement::GuiSizeMax, 30);

        value_entry = new GuiTextEntry(add_row, "", "");
        value_entry->setTextSize(18)->setSize(GuiElement::GuiSizeMax, 30);

        auto add_button = new GuiButton(add_row, "", tr("tweak-button", "Add"), [this]() {
            string key = key_entry->getText();
            string value = value_entry->getText();
            if (!key.empty() && on_add) {
                on_add(key, value);
                key_entry->setText("");
                value_entry->setText("");
            }
        });
        add_button->setTextSize(18)->setSize(60, 30);

        auto del_button = new GuiButton(add_row, "", tr("tweak-button", "Delete"), [this]() {
            if (selected_index >= 0 && selected_index < item_list->entryCount() && on_remove) {
                string key = item_list->getEntryValue(selected_index);
                on_remove(key);
                selected_index = -1;
            }
        });
        del_button->setTextSize(18)->setSize(60, 30);
    }

    virtual void onDraw(sp::RenderTarget& target) override {
        if (update_func) {
            auto current_map = update_func();

            // Rebuild list if map changed
            if (current_map.size() != static_cast<size_t>(item_list->entryCount())) {
                item_list->setOptions({});
                for(const auto& [key, value] : current_map) {
                    item_list->addEntry(key + " = " + value, key);
                }
            }
        }
        GuiElement::onDraw(target);
    }

    std::function<std::unordered_map<string, string>()> update_func;
    std::function<void(const string&, const string&)> on_add;
    std::function<void(const string&)> on_remove;

private:
    GuiListbox* item_list;
    GuiTextEntry* key_entry;
    GuiTextEntry* value_entry;
    int selected_index = -1;
};

// Widget for editing std::vector<glm::vec2> (outline points)
class GuiVec2VectorTweak : public GuiElement {
public:
    GuiVec2VectorTweak(GuiContainer* owner) : GuiElement(owner, "") {
        setSize(GuiElement::GuiSizeMax, 150);
        setAttribute("layout", "vertical");

        // List of current points
        item_list = new GuiListbox(this, "", [this](int index, string value) {
            selected_index = index;
        });
        item_list
            ->setTextSize(18.0f)
            ->setButtonHeight(20.0f)
            ->setSize(GuiElement::GuiSizeMax, 90);

        // Add new point controls
        auto add_row = new GuiElement(this, "");
        add_row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");

        x_entry = new GuiTextEntry(add_row, "", "");
        x_entry->setTextSize(18)->setSize(GuiElement::GuiSizeMax, 30);

        y_entry = new GuiTextEntry(add_row, "", "");
        y_entry->setTextSize(18)->setSize(GuiElement::GuiSizeMax, 30);

        auto add_button = new GuiButton(add_row, "", tr("tweak-button", "Add"), [this]() {
            string x_str = x_entry->getText();
            string y_str = y_entry->getText();
            if (!x_str.empty() && !y_str.empty() && on_add) {
                glm::vec2 point(x_str.toFloat(), y_str.toFloat());
                on_add(point);
                x_entry->setText("");
                y_entry->setText("");
            }
        });
        add_button->setTextSize(18)->setSize(60, 30);

        auto del_button = new GuiButton(add_row, "", tr("tweak-button", "Delete"), [this]() {
            if (selected_index >= 0 && selected_index < item_list->entryCount() && on_remove) {
                on_remove(selected_index);
                selected_index = -1;
            }
        });
        del_button->setTextSize(18)->setSize(60, 30);
    }

    virtual void onDraw(sp::RenderTarget& target) override {
        if (update_func) {
            auto current_vector = update_func();

            // Rebuild list if vector size changed
            if (current_vector.size() != static_cast<size_t>(item_list->entryCount())) {
                item_list->setOptions({});
                for(size_t i = 0; i < current_vector.size(); i++) {
                    const auto& point = current_vector[i];
                    string display = string(int(i)) + ": (" + string(point.x, 1) + ", " + string(point.y, 1) + ")";
                    item_list->addEntry(display, string(int(i)));
                }
            }
        }
        GuiElement::onDraw(target);
    }

    std::function<std::vector<glm::vec2>()> update_func;
    std::function<void(const glm::vec2&)> on_add;
    std::function<void(int)> on_remove;  // Remove by index
    std::function<void()> on_change;     // Called after any modification

private:
    GuiListbox* item_list;
    GuiTextEntry* x_entry;
    GuiTextEntry* y_entry;
    int selected_index = -1;
};

// Widget for editing std::vector<Database::KeyValue>
class GuiDatabaseKeyValueTweak : public GuiElement {
public:
    GuiDatabaseKeyValueTweak(GuiContainer* owner) : GuiElement(owner, "") {
        setSize(GuiElement::GuiSizeMax, 180);
        setAttribute("layout", "vertical");

        // List of current key-value pairs
        item_list = new GuiListbox(this, "", [this](int index, string value) {
            selected_index = index;
        });
        item_list
            ->setTextSize(18.0f)
            ->setButtonHeight(20.0f)
            ->setSize(GuiElement::GuiSizeMax, 120);

        // Add new key-value controls
        auto add_row = new GuiElement(this, "");
        add_row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");

        key_entry = new GuiTextEntry(add_row, "", "");
        key_entry->setTextSize(18)->setSize(GuiElement::GuiSizeMax, 30);

        value_entry = new GuiTextEntry(add_row, "", "");
        value_entry->setTextSize(18)->setSize(GuiElement::GuiSizeMax, 30);

        auto add_button = new GuiButton(add_row, "", tr("tweak-button", "Add"), [this]() {
            string key = key_entry->getText();
            string value = value_entry->getText();
            if (!key.empty() && on_add) {
                on_add(key, value);
                key_entry->setText("");
                value_entry->setText("");
            }
        });
        add_button->setTextSize(18)->setSize(60, 30);

        auto del_button = new GuiButton(add_row, "", tr("tweak-button", "Delete"), [this]() {
            if (selected_index >= 0 && selected_index < item_list->entryCount() && on_remove) {
                on_remove(selected_index);
                selected_index = -1;
            }
        });
        del_button->setTextSize(18)->setSize(60, 30);
    }

    virtual void onDraw(sp::RenderTarget& target) override {
        if (update_func) {
            auto current_vector = update_func();

            // Rebuild list if vector size changed
            if (current_vector.size() != static_cast<size_t>(item_list->entryCount())) {
                item_list->setOptions({});
                for(size_t i = 0; i < current_vector.size(); i++) {
                    const auto& kv = current_vector[i];
                    string display = kv.key + " = " + kv.value;
                    item_list->addEntry(display, string(int(i)));
                }
            }
        }
        GuiElement::onDraw(target);
    }

    std::function<std::vector<Database::KeyValue>()> update_func;
    std::function<void(const string&, const string&)> on_add;
    std::function<void(int)> on_remove;  // Remove by index

private:
    GuiListbox* item_list;
    GuiTextEntry* key_entry;
    GuiTextEntry* value_entry;
    int selected_index = -1;
};

// Widget for editing std::vector<InternalRooms::Room>
class GuiRoomVectorTweak : public GuiElement {
public:
    GuiRoomVectorTweak(GuiContainer* owner) : GuiElement(owner, "") {
        setSize(GuiElement::GuiSizeMax, 150);
        setAttribute("layout", "vertical");

        item_list = new GuiListbox(this, "", [this](int index, string value) {
            selected_index = index;
        });
        item_list
            ->setTextSize(18.0f)
            ->setButtonHeight(20.0f)
            ->setSize(GuiElement::GuiSizeMax, 90);

        auto pos_size_row = new GuiElement(this, "");
        pos_size_row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");

        pos_x_entry = new GuiTextEntry(pos_size_row, "", "");
        pos_x_entry->setTextSize(18)->setSize(GuiElement::GuiSizeMax, 30);
        pos_y_entry = new GuiTextEntry(pos_size_row, "", "");
        pos_y_entry->setTextSize(18)->setSize(GuiElement::GuiSizeMax, 30);
        size_x_entry = new GuiTextEntry(pos_size_row, "", "");
        size_x_entry->setTextSize(18)->setSize(GuiElement::GuiSizeMax, 30);
        size_y_entry = new GuiTextEntry(pos_size_row, "", "");
        size_y_entry->setTextSize(18)->setSize(GuiElement::GuiSizeMax, 30);

        auto sys_row = new GuiElement(this, "");
        sys_row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");

        system_selector = new GuiSelector(sys_row, "ROOM_SYSTEM_SEL", nullptr);
        system_selector->addEntry(tr("tweak-room", "None"), "-1");
        for(int i = 0; i < ShipSystem::COUNT; i++)
            system_selector->addEntry(getLocaleSystemName(static_cast<ShipSystem::Type>(i)), string(i));
        system_selector->setTextSize(18)->setSize(GuiElement::GuiSizeMax, 30);
        system_selector->setSelectionIndex(0);

        auto add_button = new GuiButton(sys_row, "", tr("tweak-button", "Add"), [this]() {
            if (on_add) {
                InternalRooms::Room room;
                room.position = glm::ivec2(pos_x_entry->getText().toInt(), pos_y_entry->getText().toInt());
                room.size = glm::ivec2(size_x_entry->getText().toInt(), size_y_entry->getText().toInt());
                room.system = static_cast<ShipSystem::Type>(system_selector->getSelectionIndex() - 1);
                on_add(room);
            }
        });
        add_button->setTextSize(18)->setSize(60, 30);

        auto del_button = new GuiButton(sys_row, "", tr("tweak-button", "Delete"), [this]() {
            if (selected_index >= 0 && selected_index < item_list->entryCount() && on_remove) {
                on_remove(selected_index);
                selected_index = -1;
            }
        });
        del_button->setTextSize(18)->setSize(60, 30);
    }

    virtual void onDraw(sp::RenderTarget& target) override {
        if (update_func) {
            auto current_vector = update_func();
            if (current_vector.size() != static_cast<size_t>(item_list->entryCount())) {
                item_list->setOptions({});
                for(size_t i = 0; i < current_vector.size(); i++) {
                    const auto& room = current_vector[i];
                    const string display = tr("tweak-room", "({position_x},{position_y} {size_w}x{size_h}) {system_name}").format({
                        {"position_x", string(room.position.x)},
                        {"position_y", string(room.position.y)},
                        {"size_w", string(room.size.x)},
                        {"size_h", string(room.size.y)},
                        {"system_name", room.system == ShipSystem::Type::None ? "-" : getLocaleSystemName(room.system)}
                    });
                    item_list->addEntry(display, string(int(i)));
                }
            }
        }
        GuiElement::onDraw(target);
    }

    std::function<std::vector<InternalRooms::Room>()> update_func;
    std::function<void(const InternalRooms::Room&)> on_add;
    std::function<void(int)> on_remove;

private:
    GuiListbox* item_list;
    GuiTextEntry* pos_x_entry;
    GuiTextEntry* pos_y_entry;
    GuiTextEntry* size_x_entry;
    GuiTextEntry* size_y_entry;
    GuiSelector* system_selector;
    int selected_index = -1;
};

// Widget for editing std::vector<InternalRooms::Door>
class GuiDoorVectorTweak : public GuiElement {
public:
    GuiDoorVectorTweak(GuiContainer* owner) : GuiElement(owner, "") {
        setSize(GuiElement::GuiSizeMax, 120);
        setAttribute("layout", "vertical");

        item_list = new GuiListbox(this, "", [this](int index, string value) {
            selected_index = index;
        });
        item_list
            ->setTextSize(18.0f)
            ->setButtonHeight(20.0f)
            ->setSize(GuiElement::GuiSizeMax, 90);

        auto input_row = new GuiElement(this, "");
        input_row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");

        pos_x_entry = new GuiTextEntry(input_row, "", "");
        pos_x_entry->setTextSize(18)->setSize(GuiElement::GuiSizeMax, 30);
        pos_y_entry = new GuiTextEntry(input_row, "", "");
        pos_y_entry->setTextSize(18)->setSize(GuiElement::GuiSizeMax, 30);

        horizontal_toggle = new GuiToggleButton(input_row, "DOOR_HORIZ", tr("tweak-door", "Horizontal"), nullptr);
        horizontal_toggle->setTextSize(18)->setSize(80, 30);

        auto add_button = new GuiButton(input_row, "", tr("tweak-button", "Add"), [this]() {
            if (on_add) {
                InternalRooms::Door door;
                door.position = glm::ivec2(pos_x_entry->getText().toInt(), pos_y_entry->getText().toInt());
                door.horizontal = horizontal_toggle->getValue();
                on_add(door);
            }
        });
        add_button->setTextSize(18)->setSize(60, 30);

        auto del_button = new GuiButton(input_row, "", tr("tweak-button", "Delete"), [this]() {
            if (selected_index >= 0 && selected_index < item_list->entryCount() && on_remove) {
                on_remove(selected_index);
                selected_index = -1;
            }
        });
        del_button->setTextSize(18)->setSize(60, 30);
    }

    virtual void onDraw(sp::RenderTarget& target) override {
        if (update_func) {
            auto current_vector = update_func();
            if (current_vector.size() != static_cast<size_t>(item_list->entryCount())) {
                item_list->setOptions({});
                for(size_t i = 0; i < current_vector.size(); i++) {
                    const auto& door = current_vector[i];
                    const string display = tr("tweak-door", "({position_x},{position_y}) {orientation}").format({
                        {"position_x", string(door.position.x)},
                        {"position_y", string(door.position.y)},
                        {"orientation", door.horizontal ? tr("tweak-door", "Horizontal") : tr("tweak-door", "Vertical")}
                    });
                    item_list->addEntry(display, string(int(i)));
                }
            }
        }
        GuiElement::onDraw(target);
    }

    std::function<std::vector<InternalRooms::Door>()> update_func;
    std::function<void(const InternalRooms::Door&)> on_add;
    std::function<void(int)> on_remove;

private:
    GuiListbox* item_list;
    GuiTextEntry* pos_x_entry;
    GuiTextEntry* pos_y_entry;
    GuiToggleButton* horizontal_toggle;
    int selected_index = -1;
};


#define ADD_PAGE(LABEL, COMPONENT) \
    new_page = new GuiTweakPage(content); \
    new_page->has_component = [](sp::ecs::Entity e) { return e.hasComponent<COMPONENT>(); }; \
    new_page->add_component = [](sp::ecs::Entity e) { e.addComponent<COMPONENT>(); }; \
    new_page->remove_component = [](sp::ecs::Entity e) { e.removeComponent<COMPONENT>(); }; \
    pages.push_back(new_page); \
    component_list->addEntry(LABEL, "");
#define ADD_LABEL(LABEL) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
    } while(0)
#define ADD_TEXT_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        auto ui = new GuiTextTweak(row); \
        ui->update_func = [this]() -> string { auto v = entity.getComponent<COMPONENT>(); if (v) return v->VALUE; return ""; }; \
        ui->callback([this](string text) { auto v = entity.getComponent<COMPONENT>(); if (v) v->VALUE = text; }); \
    } while(0)
#define ADD_NUM_TEXT_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        auto ui = new GuiTextTweak(row); \
        ui->update_func = [this]() -> string { auto v = entity.getComponent<COMPONENT>(); if (v) return string(v->VALUE, 3); return ""; }; \
        ui->callback([this](string text) { auto v = entity.getComponent<COMPONENT>(); if (v) v->VALUE = text.toFloat(); }); \
    } while(0)
#define ADD_NUM_SLIDER_TWEAK(LABEL, COMPONENT, MIN_VALUE, MAX_VALUE, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        auto ui = new GuiSliderTweak(row, "", MIN_VALUE, MAX_VALUE, 0.0f, [this](float number) { auto v = entity.getComponent<COMPONENT>(); if (v) v->VALUE = number; }); \
        ui->addOverlay(2u, 20.0f); \
        ui->update_func = [this]() -> float { auto v = entity.getComponent<COMPONENT>(); if (v) return v->VALUE; return 0.0f; }; \
    } while(0)
#define ADD_INT_SLIDER_TWEAK(LABEL, COMPONENT, MIN_VALUE, MAX_VALUE, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        auto ui = new GuiSliderTweak(row, "", MIN_VALUE, MAX_VALUE, 0u, [this](float number) { auto v = entity.getComponent<COMPONENT>(); if (v) v->VALUE = number; }); \
        for (float i = MIN_VALUE; i <= MAX_VALUE; i++) \
            ui->addSnapValue(i, 0.5f); \
        ui->addOverlay(0u, 20.0f); \
        ui->update_func = [this]() -> float { auto v = entity.getComponent<COMPONENT>(); if (v) return v->VALUE; return 0u; }; \
    } while(0)
#define ADD_BOOL_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        auto ui = new GuiToggleTweak(row, "", [this](bool value) { auto v = entity.getComponent<COMPONENT>(); if (v) v->VALUE = value; }); \
        ui->update_func = [this]() -> bool { auto v = entity.getComponent<COMPONENT>(); if (v) return v->VALUE; return false; }; \
    } while(0)
#define ADD_VECTOR(LABEL, COMPONENT, VECTOR) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        vector_selector = new GuiVectorTweak(row, "VECTOR_SELECTOR"); \
        vector_selector->update_func = [this]() -> size_t { auto v = entity.getComponent<COMPONENT>(); if (v) return v->VECTOR.size(); return 0; }; \
        auto add = new GuiButton(row, "", "Add", [this, vector_selector](){ auto v = entity.getComponent<COMPONENT>(); if (v) { v->VECTOR.emplace_back(); vector_selector->setSelectionIndex(v->VECTOR.size()); } }); \
        add->setTextSize(20)->setSize(50, 30); \
        auto del = new GuiButton(row, "", "Del", [this](){ auto v = entity.getComponent<COMPONENT>(); if (v && v->VECTOR.size() > 0) v->VECTOR.pop_back(); }); \
        del->setTextSize(20)->setSize(50, 30); \
    } while(0)
#define ADD_VECTOR_NUM_TEXT_TWEAK(LABEL, COMPONENT, VECTOR, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        auto ui = new GuiTextTweak(row); \
        ui->update_func = [this, vector_selector]() -> string { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < int(v->VECTOR.size())) \
                return string(v->VECTOR[vector_selector->getSelectionIndex()].VALUE); \
            return ""; \
        }; \
        ui->callback([this, vector_selector](string text) { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < int(v->VECTOR.size())) \
                v->VECTOR[vector_selector->getSelectionIndex()].VALUE = text.toFloat(); \
        }); \
    } while(0)
#define ADD_VECTOR_BOOL_TWEAK(LABEL, COMPONENT, VECTOR, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        auto ui = new GuiToggleTweak(row, "", [this, vector_selector](bool value) { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < int(v->VECTOR.size())) \
                v->VECTOR[vector_selector->getSelectionIndex()].VALUE = value; }); \
        ui->update_func = [this, vector_selector]() -> bool { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < int(v->VECTOR.size())) \
                return v->VECTOR[vector_selector->getSelectionIndex()]->VALUE; \
            return false; }; \
    } while(0)
#define ADD_VECTOR_TOGGLE_MASK_TWEAK(LABEL, COMPONENT, VECTOR, VALUE, MASK) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        auto ui = new GuiToggleTweak(row, "", [this, vector_selector](bool value) { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < int(v->VECTOR.size())) { \
                if (value) v->VECTOR[vector_selector->getSelectionIndex()].VALUE |= (MASK); else v->VECTOR[vector_selector->getSelectionIndex()].VALUE &=~(MASK); } \
            }); \
        ui->update_func = [this, vector_selector]() -> bool { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < int(v->VECTOR.size())) \
                return v->VECTOR[vector_selector->getSelectionIndex()].VALUE & (MASK); \
            return false; }; \
    } while(0)
#define ADD_VECTOR_NUM_SLIDER_TWEAK(LABEL, COMPONENT, VECTOR, MIN_VALUE, MAX_VALUE, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        auto ui = new GuiSliderTweak(row, "", MIN_VALUE, MAX_VALUE, 0.0f, [this, vector_selector](float number) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < int(v->VECTOR.size())) \
                v->VECTOR[vector_selector->getSelectionIndex()].VALUE = number; \
        }); \
        ui->addOverlay(2u, 20.0f); \
        ui->update_func = [this, vector_selector]() -> float { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < int(v->VECTOR.size())) \
                return v->VECTOR[vector_selector->getSelectionIndex()].VALUE; \
            return 0.0f; \
        }; \
    } while(0)
#define ADD_VECTOR_ENUM_TWEAK(LABEL, COMPONENT, VECTOR, VALUE, MIN_VALUE, MAX_VALUE, STRING_CONVERT_FUNCTION) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        auto ui = new GuiSelectorTweak(row, "", [this, vector_selector](int index, string value) { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < int(v->VECTOR.size())) \
                v->VECTOR[vector_selector->getSelectionIndex()].VALUE = static_cast<decltype(decltype(COMPONENT::VECTOR)::value_type::VALUE)>(index + MIN_VALUE); \
        }); \
        for(int enum_value=MIN_VALUE; enum_value<=MAX_VALUE; enum_value++) \
            ui->addEntry(STRING_CONVERT_FUNCTION(static_cast<decltype(decltype(COMPONENT::VECTOR)::value_type::VALUE)>(enum_value)), string(enum_value)); \
        ui->update_func = [this, vector_selector]() -> float { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < int(v->VECTOR.size())) \
                return int(v->VECTOR[vector_selector->getSelectionIndex()].VALUE) - int(MIN_VALUE); \
            return -1; \
        }; \
    } while(0)
#define ADD_SHIP_SYSTEM_TWEAK(SYSTEM) \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Health:"), SYSTEM, health); \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Health max:"), SYSTEM, health_max); \
      ADD_NUM_SLIDER_TWEAK(tr("tweak-text", "Heat:"), SYSTEM, 0.0f, 1.0f, heat_level); \
      ADD_BOOL_TWEAK(tr("tweak-text", "Can be hacked:"), SYSTEM, can_be_hacked); \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Power factor:"), SYSTEM, power_factor); \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Heat rate:"), SYSTEM, heat_add_rate_per_second); \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Coolant change rate:"), SYSTEM, coolant_change_rate_per_second); \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Power change rate:"), SYSTEM, power_change_rate_per_second); \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Auto repair rate:"), SYSTEM, auto_repair_per_second);

// New widget macros for additional component types

#define ADD_ENTITY_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        auto ui = new GuiEntityPicker(row, "ENTITY_PICKER", [this](int index, string value) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) v->VALUE = value.empty() ? sp::ecs::Entity() : sp::ecs::Entity::fromString(value); \
        }); \
        ui->update_func = [this]() -> sp::ecs::Entity { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) return v->VALUE; \
            return sp::ecs::Entity(); \
        }; \
    } while(0)

#define ADD_DATABASE_PARENT_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        auto ui = new GuiDatabaseParentPicker(row, "DATABASE_PARENT_PICKER", [this](int index, string value) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) v->VALUE = value.empty() ? sp::ecs::Entity() : sp::ecs::Entity::fromString(value); \
        }); \
        ui->update_func = [this]() -> sp::ecs::Entity { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) return v->VALUE; \
            return sp::ecs::Entity(); \
        }; \
    } while(0)

#define ADD_VECTOR2_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        auto ui = new GuiVec2Tweak(row); \
        ui->update_func = [this]() -> glm::vec2 { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) return v->VALUE; \
            return glm::vec2(0, 0); \
        }; \
        ui->callback = [this](glm::vec2 val) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) v->VALUE = val; \
        }; \
    } while(0)

#define ADD_COLOR_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 120)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 120); \
        auto ui = new GuiColorPicker(row); \
        ui->update_func = [this]() -> glm::u8vec4 { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) return v->VALUE; \
            return glm::u8vec4(255, 255, 255, 255); \
        }; \
        ui->callback = [this](glm::u8vec4 val) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) v->VALUE = val; \
        }; \
    } while(0)

#define ADD_TEXT_MULTILINE_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 150)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 150); \
        auto ui = new GuiMultilineTextTweak(row, 5); \
        ui->update_func = [this]() -> string { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) return v->VALUE; \
            return ""; \
        }; \
    } while(0)

#define ADD_FACTION_SELECTOR_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        auto ui = new GuiFactionSelectorTweak(row, "FACTION_SELECTOR", [this](int index, string value) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) v->VALUE = value.empty() ? sp::ecs::Entity() : sp::ecs::Entity::fromString(value); \
        }); \
        ui->update_func = [this]() -> sp::ecs::Entity { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) return v->VALUE; \
            return sp::ecs::Entity(); \
        }; \
    } while(0)

#define ADD_ENUM_TWEAK(LABEL, COMPONENT, VALUE, MIN_VALUE, MAX_VALUE, STRING_CONVERT_FUNCTION) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30); \
        auto ui = new GuiSelectorTweak(row, "ENUM_SELECTOR", [this](int index, string value) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) v->VALUE = static_cast<decltype(v->VALUE)>(index + MIN_VALUE); \
        }); \
        for(int enum_value = MIN_VALUE; enum_value <= MAX_VALUE; enum_value++) \
            ui->addEntry(STRING_CONVERT_FUNCTION(static_cast<decltype(COMPONENT{}.VALUE)>(enum_value)), string(enum_value)); \
        ui->update_func = [this]() -> int { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) return static_cast<int>(v->VALUE) - static_cast<int>(MIN_VALUE); \
            return -1; \
        }; \
    } while(0)

#define ADD_STRING_SET_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 150)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 150); \
        auto ui = new GuiStringSetTweak(row); \
        ui->update_func = [this]() -> std::unordered_set<string> { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) return v->VALUE; \
            return {}; \
        }; \
        ui->on_add = [this](const string& item) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) { \
                v->VALUE.insert(item); \
                v->VALUE##_dirty = true; \
            } \
        }; \
        ui->on_remove = [this](const string& item) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) { \
                v->VALUE.erase(item); \
                v->VALUE##_dirty = true; \
            } \
        }; \
    } while(0)

#define ADD_STRING_MAP_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 180)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 180); \
        auto ui = new GuiStringMapTweak(row); \
        ui->update_func = [this]() -> std::unordered_map<string, string> { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) return v->VALUE; \
            return {}; \
        }; \
        ui->on_add = [this](const string& key, const string& value) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) { \
                v->VALUE[key] = value; \
            } \
        }; \
        ui->on_remove = [this](const string& key) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) { \
                v->VALUE.erase(key); \
            } \
        }; \
    } while(0)

#define ADD_VEC2_VECTOR_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 150)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 150); \
        auto ui = new GuiVec2VectorTweak(row); \
        ui->update_func = [this]() -> std::vector<glm::vec2> { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) return v->VALUE; \
            return {}; \
        }; \
        ui->on_add = [this](const glm::vec2& point) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) { \
                v->VALUE.push_back(point); \
                v->updateTriangles(); \
            } \
        }; \
        ui->on_remove = [this](int index) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v && index >= 0 && index < static_cast<int>(v->VALUE.size())) { \
                v->VALUE.erase(v->VALUE.begin() + index); \
                v->updateTriangles(); \
            } \
        }; \
    } while(0)

#define ADD_DATABASE_KEYVALUE_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 180)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 180); \
        auto ui = new GuiDatabaseKeyValueTweak(row); \
        ui->update_func = [this]() -> std::vector<Database::KeyValue> { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) return v->VALUE; \
            return {}; \
        }; \
        ui->on_add = [this](const string& key, const string& value) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) { \
                v->VALUE.push_back({key, value}); \
                v->VALUE##_dirty = true; \
            } \
        }; \
        ui->on_remove = [this](int index) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v && index >= 0 && index < static_cast<int>(v->VALUE.size())) { \
                v->VALUE.erase(v->VALUE.begin() + index); \
                v->VALUE##_dirty = true; \
            } \
        }; \
    } while(0)

#define ADD_ROOM_VECTOR_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 150)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 150); \
        auto ui = new GuiRoomVectorTweak(row); \
        ui->update_func = [this]() -> std::vector<InternalRooms::Room> { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) return v->VALUE; \
            return {}; \
        }; \
        ui->on_add = [this](const InternalRooms::Room& room) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) { \
                v->VALUE.push_back(room); \
                v->VALUE##_dirty = true; \
            } \
        }; \
        ui->on_remove = [this](int index) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v && index >= 0 && index < static_cast<int>(v->VALUE.size())) { \
                v->VALUE.erase(v->VALUE.begin() + index); \
                v->VALUE##_dirty = true; \
            } \
        }; \
    } while(0)

#define ADD_DOOR_VECTOR_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 120)->setAttribute("layout", "horizontal"); \
        auto label = new GuiLabel(row, "", LABEL, 20); \
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 120); \
        auto ui = new GuiDoorVectorTweak(row); \
        ui->update_func = [this]() -> std::vector<InternalRooms::Door> { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) return v->VALUE; \
            return {}; \
        }; \
        ui->on_add = [this](const InternalRooms::Door& door) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v) { \
                v->VALUE.push_back(door); \
                v->VALUE##_dirty = true; \
            } \
        }; \
        ui->on_remove = [this](int index) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v && index >= 0 && index < static_cast<int>(v->VALUE.size())) { \
                v->VALUE.erase(v->VALUE.begin() + index); \
                v->VALUE##_dirty = true; \
            } \
        }; \
    } while(0)

GuiEntityTweak::GuiEntityTweak(GuiContainer* owner)
: GuiPanel(owner, "GM_TWEAK_DIALOG")
{
    setPosition(0, -100, sp::Alignment::BottomCenter);
    setSize(1000, 700);
    setAttribute("padding", "20");

    content = new GuiElement(this, "GM_TWEAK_DIALOG_CONTENT");
    content->setSize(GuiElement::GuiSizeMax,GuiElement::GuiSizeMax)->setAttribute("layout", "horizontal");

    component_list = new GuiListbox(content, "", [this](int index, string value)
    {
        for(GuiTweakPage* page : pages)
            page->hide();
        pages[index]->show();
    });

    component_list->setSize(300, GuiElement::GuiSizeMax);
    component_list->setPosition(0, 0, sp::Alignment::TopLeft);

    GuiTweakPage* new_page;
    GuiVectorTweak* vector_selector;

    // Transform component, custom implementation since it uses functions
    // instead of direct access to members
    ADD_PAGE(tr("tweak-tab", "Transform"), sp::Transform);
    {
        // Position X text field
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        auto label = new GuiLabel(row, "", tr("tweak-text", "Position X:"), 20.0f);
        label
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, 30.0f);
        auto ui = new GuiTextTweak(row);
        ui->update_func = [this]() -> string {
            if (auto t = entity.getComponent<sp::Transform>())
                return string(t->getPosition().x, 1);

            return "";
        };
        ui->callback([this](string text) {
            if (auto t = entity.getComponent<sp::Transform>())
                t->setPosition(glm::vec2(text.toFloat(), t->getPosition().y));
        });
    }
    {
        // Position Y text field
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        auto label = new GuiLabel(row, "", tr("tweak-text", "Position Y:"), 20.0f);
        label
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, 30.0f);
        auto ui = new GuiTextTweak(row);
        ui->update_func = [this]() -> string {
            if (auto t = entity.getComponent<sp::Transform>())
                return string(t->getPosition().y, 1);

            return "";
        };
        ui->callback([this](string text) {
            if (auto t = entity.getComponent<sp::Transform>())
                t->setPosition(glm::vec2(t->getPosition().x, text.toFloat()));
        });
    }
    {
        // Rotation slider
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        auto label = new GuiLabel(row, "", tr("tweak-text", "Rotation:"), 20.0f);
        label
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, 30.0f);
        auto ui = new GuiSliderTweak(row, "", -180.0f, 180.0f, 0.0f,
            [this](float value)
            {
                if (auto t = entity.getComponent<sp::Transform>())
                    t->setRotation(value);
            }
        );
        ui->addOverlay(1u, 20.0f);
        ui->update_func = [this]() -> float {
            if (auto t = entity.getComponent<sp::Transform>())
                return t->getRotation();

            return 0.0f;
        };
    }

    // Physics component
    ADD_PAGE(tr("tweak-tab", "Physics"), sp::Physics);
    // TODO: Figure out how to set Physics values

    ADD_PAGE(tr("tweak-tab", "Callsign"), CallSign);
    ADD_TEXT_TWEAK(tr("tweak-text", "Callsign:"), CallSign, callsign);

    ADD_PAGE(tr("tweak-tab", "Type name"), TypeName);
    ADD_TEXT_TWEAK(tr("tweak-text", "Type name:"), TypeName, type_name);
    ADD_TEXT_TWEAK(tr("tweak-text", "Localized:"), TypeName, localized);

    ADD_PAGE(tr("tweak-tab", "Coolant"), Coolant);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Max:"), Coolant, max);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Max per system:"), Coolant, max_coolant_per_system);
    ADD_BOOL_TWEAK(tr("tweak-text", "Auto levels:"), Coolant, auto_levels);

    ADD_PAGE(tr("tweak-tab", "Hull"), Hull);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Current:"), Hull, current);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Max:"), Hull, max);
    ADD_BOOL_TWEAK(tr("tweak-text", "Allow destruction:"), Hull, allow_destruction);

    ADD_PAGE(tr("tweak-tab", "Impulse engine"), ImpulseEngine);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Speed forward:"), ImpulseEngine, max_speed_forward);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Speed reverse:"), ImpulseEngine, max_speed_reverse);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Acceleration forward:"), ImpulseEngine, acceleration_forward);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Acceleration reverse:"), ImpulseEngine, acceleration_reverse);
    ADD_LABEL(tr("tweak-text", "Impulse engine system"));
    ADD_SHIP_SYSTEM_TWEAK(ImpulseEngine);

    ADD_PAGE(tr("tweak-tab", "Maneuvering thrusters"), ManeuveringThrusters);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Rotational speed:"), ManeuveringThrusters, speed);
    ADD_LABEL(tr("tweak-text", "Maneuvering thrusters system"));
    ADD_SHIP_SYSTEM_TWEAK(ManeuveringThrusters);

    ADD_PAGE(tr("tweak-tab", "Combat thrusters"), CombatManeuveringThrusters);
    ADD_NUM_SLIDER_TWEAK(tr("tweak-text", "Charge available:"), CombatManeuveringThrusters, 0.0f, 1.0f, charge);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Seconds to full recharge from 0:"), CombatManeuveringThrusters, charge_time);

    ADD_PAGE(tr("tweak-tab", "Beam system"), BeamWeaponSys);
    ADD_INT_SLIDER_TWEAK(tr("tweak-text", "Frequency:"), BeamWeaponSys, 0u, 20u, frequency);
    ADD_LABEL(tr("tweak-text", "Beam weapons system"));
    ADD_SHIP_SYSTEM_TWEAK(BeamWeaponSys);

    ADD_PAGE(tr("tweak-tab", "Beam mounts"), BeamWeaponSys);
    ADD_VECTOR(tr("tweak-vector", "Mounts"), BeamWeaponSys, mounts);
    ADD_VECTOR_NUM_SLIDER_TWEAK(tr("tweak-text", "Arc:"), BeamWeaponSys, mounts, 0.0f, 360.0f, arc);
    ADD_VECTOR_NUM_SLIDER_TWEAK(tr("tweak-text", "Direction:"), BeamWeaponSys, mounts, 0.0f, 360.0f, direction);
    ADD_VECTOR_NUM_TEXT_TWEAK(tr("tweak-text", "Range:"), BeamWeaponSys, mounts, range);
    ADD_VECTOR_NUM_TEXT_TWEAK(tr("tweak-text", "Cycle time:"), BeamWeaponSys, mounts, cycle_time);
    ADD_VECTOR_NUM_TEXT_TWEAK(tr("tweak-text", "Damage:"), BeamWeaponSys, mounts, damage);
    ADD_VECTOR_NUM_SLIDER_TWEAK(tr("tweak-text", "Turret arc:"), BeamWeaponSys, mounts, 0.0f, 360.0f, turret_arc);
    ADD_VECTOR_NUM_SLIDER_TWEAK(tr("tweak-text", "Turret direction:"), BeamWeaponSys, mounts, 0.0f, 360.0f, turret_direction);
    ADD_VECTOR_NUM_TEXT_TWEAK(tr("tweak-text", "Turret rotation rate:"), BeamWeaponSys, mounts, turret_rotation_rate);

    ADD_PAGE(tr("tweak-tab", "Missile system"), MissileTubes);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Homing missiles:"), MissileTubes, storage[MW_Homing]);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Homing capacity:"), MissileTubes, storage_max[MW_Homing]);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Nuke missiles:"), MissileTubes, storage[MW_Nuke]);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Nuke capacity:"), MissileTubes, storage_max[MW_Nuke]);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "EMP missiles:"), MissileTubes, storage[MW_EMP]);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "EMP capacity:"), MissileTubes, storage_max[MW_EMP]);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "HVLI missiles:"), MissileTubes, storage[MW_HVLI]);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "HVLI capacity:"), MissileTubes, storage_max[MW_HVLI]);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Mines:"), MissileTubes, storage[MW_Mine]);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Mines capacity:"), MissileTubes, storage_max[MW_Mine]);
    ADD_LABEL(tr("tweak-text", "Missile weapons system"));
    ADD_SHIP_SYSTEM_TWEAK(MissileTubes);

    ADD_PAGE(tr("tweak-tab", "Missile mounts"), MissileTubes);
    ADD_VECTOR(tr("tweak-vector", "Mounts"), MissileTubes, mounts);
    ADD_VECTOR_NUM_SLIDER_TWEAK(tr("tweak-text", "Direction:"), MissileTubes, mounts, 0.0f, 360.0f, direction);
    ADD_VECTOR_NUM_TEXT_TWEAK(tr("tweak-text", "Load time:"), MissileTubes, mounts, load_time);
    ADD_VECTOR_ENUM_TWEAK(tr("tweak-text", "Size:"), MissileTubes, mounts, size, MS_Small, MS_Large, getMissileSizeString);
    ADD_VECTOR_TOGGLE_MASK_TWEAK(tr("tweak-text", "Allow homing:"), MissileTubes, mounts, type_allowed_mask, 1 << MW_Homing);
    ADD_VECTOR_TOGGLE_MASK_TWEAK(tr("tweak-text", "Allow nuke:"), MissileTubes, mounts, type_allowed_mask, 1 << MW_Nuke);
    ADD_VECTOR_TOGGLE_MASK_TWEAK(tr("tweak-text", "Allow mine:"), MissileTubes, mounts, type_allowed_mask, 1 << MW_Mine);
    ADD_VECTOR_TOGGLE_MASK_TWEAK(tr("tweak-text", "Allow EMP:"), MissileTubes, mounts, type_allowed_mask, 1 << MW_EMP);
    ADD_VECTOR_TOGGLE_MASK_TWEAK(tr("tweak-text", "Allow HVLI:"), MissileTubes, mounts, type_allowed_mask, 1 << MW_HVLI);

    ADD_PAGE(tr("tweak-tab", "Shields"), Shields);
    // Unsure how to access the shield component's front/rear systems
    // ADD_LABEL(tr("tweak-text", "Shields systems"));
    // ADD_SHIP_SYSTEM_TWEAK(Shields, front_system);
    // ADD_SHIP_SYSTEM_TWEAK(Shields, rear_system);
    ADD_BOOL_TWEAK(tr("tweak-text", "Active:"), Shields, active);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Seconds to recalibrate:"), Shields, calibration_time);
    ADD_INT_SLIDER_TWEAK(tr("tweak-text", "Frequency:"), Shields, 0u, 20u, frequency);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Energy use per second:"), Shields, energy_use_per_second);
    ADD_VECTOR(tr("tweak-vector", "Shields"), Shields, entries);
    ADD_VECTOR_NUM_TEXT_TWEAK(tr("tweak-text", "Level:"), Shields, entries, level);
    ADD_VECTOR_NUM_TEXT_TWEAK(tr("tweak-text", "Max:"), Shields, entries, max);

    ADD_PAGE(tr("tweak-tab", "Warp drive"), WarpDrive);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Max level:"), WarpDrive, max_level);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Speed per level:"), WarpDrive, speed_per_level);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Energy per second:"), WarpDrive, energy_warp_per_second);
    ADD_LABEL(tr("tweak-text", "Warp drive system"));
    ADD_SHIP_SYSTEM_TWEAK(WarpDrive);

    ADD_PAGE(tr("tweak-tab", "Jump drive"), JumpDrive);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Min distance:"), JumpDrive, min_distance);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Max distance:"), JumpDrive, max_distance);
    ADD_LABEL(tr("tweak-text", "Jump drive system"));
    ADD_SHIP_SYSTEM_TWEAK(JumpDrive);

    // AI Controller component
    // Special handling: Component removal is disabled due to unique_ptr<ShipAI> destruction issues
    new_page = new GuiTweakPage(content);
    new_page->has_component = [](sp::ecs::Entity e) { return e.hasComponent<AIController>(); };
    new_page->add_component = [](sp::ecs::Entity e) { e.addComponent<AIController>(); };
    new_page->remove_component = [](sp::ecs::Entity e) {
        // Removal disabled: AIController contains unique_ptr<ShipAI> which causes
        // compilation issues with incomplete type. Use scripts to remove AI component.
        LOG(Warning, "AIController component removal not supported via Tweaks dialog");
    };
    pages.push_back(new_page);
    component_list->addEntry(tr("tweak-tab", "AI controller"), "");

    ADD_ENUM_TWEAK(tr("tweak-text", "Orders:"), AIController, orders,
        static_cast<int>(AIOrder::Idle), static_cast<int>(AIOrder::Attack), getAIOrderString);
    ADD_VECTOR2_TWEAK(tr("tweak-text", "Order target location:"), AIController, order_target_location);
    ADD_ENTITY_TWEAK(tr("tweak-text", "Order target:"), AIController, order_target);
    // ADD_TEXT_TWEAK(tr("tweak-text", "AI name:"), AIController, new_name);

    // Orbit component - allows entities to orbit around a target or fixed point
    ADD_PAGE(tr("tweak-tab", "Orbit"), Orbit);
    ADD_ENTITY_TWEAK(tr("tweak-text", "Orbit target:"), Orbit, target);
    ADD_VECTOR2_TWEAK(tr("tweak-text", "Orbit center:"), Orbit, center);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Orbit distance:"), Orbit, distance);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Orbit period (seconds):"), Orbit, time);

    // Faction component - assigns entity to a faction
    // Redundant with GM screen faction selector, but this allows addition/removal
    // of the component itself
    ADD_PAGE(tr("tweak-tab", "Faction"), Faction);
    ADD_FACTION_SELECTOR_TWEAK(tr("tweak-text", "Faction:"), Faction, entity);

    // Spin component - makes entity rotate continuously
    ADD_PAGE(tr("tweak-tab", "Spin"), Spin);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Rotation rate (degrees/second):"), Spin, rate);

    // LifeTime component - entity expires after lifetime seconds
    ADD_PAGE(tr("tweak-tab", "Life time"), LifeTime);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Remaining lifetime (seconds):"), LifeTime, lifetime);

    // WarpJammer component - prevents ships from warping within range
    ADD_PAGE(tr("tweak-tab", "Warp jammer"), WarpJammer);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Jamming range:"), WarpJammer, range);

    // Zone component - defines areas with visual effects and properties
    ADD_PAGE(tr("tweak-tab", "Zone"), Zone);
    ADD_COLOR_TWEAK(tr("tweak-text", "Zone color:"), Zone, color);
    ADD_TEXT_TWEAK(tr("tweak-text", "Label:"), Zone, label);
    ADD_VECTOR2_TWEAK(tr("tweak-text", "Label offset:"), Zone, label_offset);
    ADD_TEXT_TWEAK(tr("tweak-text", "Skybox:"), Zone, skybox);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Skybox fade distance:"), Zone, skybox_fade_distance);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Radius:"), Zone, radius);
    ADD_VEC2_VECTOR_TWEAK(tr("tweak-text", "Outline points:"), Zone, outline);

    // Database component - science database entries
    ADD_PAGE(tr("tweak-tab", "Database"), Database);
    ADD_DATABASE_PARENT_TWEAK(tr("tweak-text", "Parent entry:"), Database, parent);
    ADD_TEXT_TWEAK(tr("tweak-text", "Name:"), Database, name);
    ADD_DATABASE_KEYVALUE_TWEAK(tr("tweak-text", "Key-value pairs:"), Database, key_values);
    // TODO: Replace with multiline text editor widget - single-line field can't handle linebreaks properly
    ADD_TEXT_TWEAK(tr("tweak-text", "Description:"), Database, description);
    ADD_TEXT_TWEAK(tr("tweak-text", "Image:"), Database, image);

    // MoveTo component - move entity to target location at fixed speed
    ADD_PAGE(tr("tweak-tab", "Move to"), MoveTo);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Speed:"), MoveTo, speed);
    ADD_VECTOR2_TWEAK(tr("tweak-text", "Target position:"), MoveTo, target);

    // InternalRooms component - ship interior layout with rooms and doors
    ADD_PAGE(tr("tweak-tab", "Internal rooms"), InternalRooms);
    ADD_BOOL_TWEAK(tr("tweak-text", "Auto repair:"), InternalRooms, auto_repair_enabled);
    ADD_ROOM_VECTOR_TWEAK(tr("tweak-text", "Rooms:"), InternalRooms, rooms);
    ADD_DOOR_VECTOR_TWEAK(tr("tweak-text", "Doors:"), InternalRooms, doors);

    // DockingBay component - allows other entities to dock with this entity
    ADD_PAGE(tr("tweak-tab", "Docking bay"), DockingBay);
    ADD_STRING_SET_TWEAK(tr("tweak-text", "External dock classes:"), DockingBay, external_dock_classes);
    ADD_STRING_SET_TWEAK(tr("tweak-text", "Internal dock classes:"), DockingBay, internal_dock_classes);
    ADD_LABEL(tr("tweak-text", "Docking bay services:"));
    // DockingBay flags - custom toggle tweaks for bitfield
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");
        auto label = new GuiLabel(row, "", tr("tweak-text", "Share energy"), 20);
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30);
        auto ui = new GuiToggleTweak(row, "", [this](bool value) {
            auto v = entity.getComponent<DockingBay>();
            if (v) {
                if (value) v->flags |= DockingBay::ShareEnergy;
                else v->flags &= ~DockingBay::ShareEnergy;
            }
        });
        ui->update_func = [this]() -> bool {
            auto v = entity.getComponent<DockingBay>();
            return v && (v->flags & DockingBay::ShareEnergy);
        };
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");
        auto label = new GuiLabel(row, "", tr("tweak-text", "Repair hull"), 20);
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30);
        auto ui = new GuiToggleTweak(row, "", [this](bool value) {
            auto v = entity.getComponent<DockingBay>();
            if (v) {
                if (value) v->flags |= DockingBay::Repair;
                else v->flags &= ~DockingBay::Repair;
            }
        });
        ui->update_func = [this]() -> bool {
            auto v = entity.getComponent<DockingBay>();
            return v && (v->flags & DockingBay::Repair);
        };
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");
        auto label = new GuiLabel(row, "", tr("tweak-text", "Charge shields"), 20);
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30);
        auto ui = new GuiToggleTweak(row, "", [this](bool value) {
            auto v = entity.getComponent<DockingBay>();
            if (v) {
                if (value) v->flags |= DockingBay::ChargeShield;
                else v->flags &= ~DockingBay::ChargeShield;
            }
        });
        ui->update_func = [this]() -> bool {
            auto v = entity.getComponent<DockingBay>();
            return v && (v->flags & DockingBay::ChargeShield);
        };
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");
        auto label = new GuiLabel(row, "", tr("tweak-text", "Restock probes"), 20);
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30);
        auto ui = new GuiToggleTweak(row, "", [this](bool value) {
            auto v = entity.getComponent<DockingBay>();
            if (v) {
                if (value) v->flags |= DockingBay::RestockProbes;
                else v->flags &= ~DockingBay::RestockProbes;
            }
        });
        ui->update_func = [this]() -> bool {
            auto v = entity.getComponent<DockingBay>();
            return v && (v->flags & DockingBay::RestockProbes);
        };
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row->setSize(GuiElement::GuiSizeMax, 30)->setAttribute("layout", "horizontal");
        auto label = new GuiLabel(row, "", tr("tweak-text", "Restock missiles"), 20);
        label->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, 30);
        auto ui = new GuiToggleTweak(row, "", [this](bool value) {
            auto v = entity.getComponent<DockingBay>();
            if (v) {
                if (value) v->flags |= DockingBay::RestockMissiles;
                else v->flags &= ~DockingBay::RestockMissiles;
            }
        });
        ui->update_func = [this]() -> bool {
            auto v = entity.getComponent<DockingBay>();
            return v && (v->flags & DockingBay::RestockMissiles);
        };
    }

    // DockingPort component - allows this entity to dock with others
    ADD_PAGE(tr("tweak-tab", "Docking port"), DockingPort);
    ADD_TEXT_TWEAK(tr("tweak-text", "Dock class:"), DockingPort, dock_class);
    ADD_TEXT_TWEAK(tr("tweak-text", "Dock subclass:"), DockingPort, dock_subclass);
    ADD_ENUM_TWEAK(tr("tweak-text", "Docking state:"), DockingPort, state,
        static_cast<int>(DockingPort::State::NotDocking),
        static_cast<int>(DockingPort::State::Docked), getDockingStateString);
    ADD_ENTITY_TWEAK(tr("tweak-text", "Dock target:"), DockingPort, target);
    ADD_VECTOR2_TWEAK(tr("tweak-text", "Docked offset:"), DockingPort, docked_offset);
    ADD_BOOL_TWEAK(tr("tweak-text", "Auto reload missiles:"), DockingPort, auto_reload_missiles);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Reload delay (seconds):"), DockingPort, auto_reload_missile_delay);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Reload time (seconds):"), DockingPort, auto_reload_missile_time);

    ADD_PAGE(tr("tweak-tab", "Player ship"), PlayerControl);
    ADD_TEXT_TWEAK(tr("tweak-text", "Control code:"), PlayerControl, control_code);

    ADD_PAGE(tr("tweak-tab", "Reactor"), Reactor);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Energy:"), Reactor, energy);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Max energy:"), Reactor, max_energy);
    ADD_BOOL_TWEAK(tr("tweak-text", "Explode on overload:"), Reactor, overload_explode);
    ADD_LABEL(tr("tweak-text", "Reactor system"));
    ADD_SHIP_SYSTEM_TWEAK(Reactor);

    ADD_PAGE(tr("tweak-tab", "Radar"), LongRangeRadar);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Short-range radar range:"), LongRangeRadar, short_range);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Long-range radar range:"), LongRangeRadar, long_range);

    ADD_PAGE(tr("tweak-tab", "Scanner"), ScienceScanner);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Countdown delay:"), ScienceScanner, delay);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Max delay:"), ScienceScanner, max_scanning_delay);

    ADD_PAGE(tr("tweak-tab", "Comms receiver"), CommsReceiver);
    ADD_PAGE(tr("tweak-tab", "Comms transmitter"), CommsTransmitter);

    ADD_PAGE(tr("tweak-tab", "Scan probe launcher"), ScanProbeLauncher);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Stored probes:"), ScanProbeLauncher, stock);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Max probe storage:"), ScanProbeLauncher, max);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Probe restocking delay:"), ScanProbeLauncher, charge_time);

    ADD_PAGE(tr("tweak-tab", "Hacking"), HackingDevice);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Effectiveness:"), HackingDevice, effectiveness);

    ADD_PAGE(tr("tweak-tab", "Self-destruct"), SelfDestruct);
    ADD_BOOL_TWEAK(tr("tweak-text", "Active:"), SelfDestruct, active);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Countdown:"), SelfDestruct, countdown);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Blast damage:"), SelfDestruct, damage);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Blast radius:"), SelfDestruct, size);

    ADD_PAGE(tr("tweak-tab", "Radar obstruction"), RadarBlock);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Radius:"), RadarBlock, range);
    ADD_BOOL_TWEAK(tr("tweak-text", "Obstructs radar behind:"), RadarBlock, behind);

    ADD_PAGE(tr("tweak-tab", "Gravity"), Gravity);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Radius:"), Gravity, range);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Force:"), Gravity, force);
    ADD_BOOL_TWEAK(tr("tweak-text", "Black hole damage:"), Gravity, damage);

    for(GuiTweakPage* page : pages)
    {
        page->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->hide();
    }

    pages[0]->show();
    component_list->setSelectionIndex(0);

    (new GuiButton(this, "CLOSE_BUTTON", tr("button", "Close"), [this]() {
        hide();
    }))->setTextSize(20)->setPosition(10, -20, sp::Alignment::TopRight)->setSize(70, 30);
}

void GuiEntityTweak::open(sp::ecs::Entity e, string select_component)
{
    entity = e;
    for(auto page : pages)
        page->open(e);

    // If a specific component was requested, select it
    if (!select_component.empty()) {
        for(int i = 0; i < component_list->entryCount(); i++) {
            if (component_list->getEntryName(i).find(select_component) != std::string::npos) {
                component_list->setSelectionIndex(i);
                for(auto page : pages)
                    page->hide();
                pages[i]->show();
                break;
            }
        }
    }

    show();
}

GuiTweakPage::GuiTweakPage(GuiContainer* owner)
: GuiElement(owner, "")
{
    add_remove_button = new GuiButton(this, "ADD_REMOVE", "", [this](){
        if (has_component(entity))
            remove_component(entity);
        else
            add_component(entity);
    });
    add_remove_button->setSize(300, 50)->setAttribute("alignment", "topcenter");

    tweaks = new GuiElement(this, "TWEAKS");
    tweaks->setPosition(0, 75, sp::Alignment::TopLeft)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->setAttribute("layout", "vertical");
    tweaks->setMargins(30, 0);
}

void GuiTweakPage::open(sp::ecs::Entity e)
{
    entity = e;
}

void GuiTweakPage::onDraw(sp::RenderTarget& target)
{
    if (has_component(entity)) {
        add_remove_button->setText(tr("tweak-button", "Remove component"));
        tweaks->show();
    } else {
        add_remove_button->setText(tr("tweak-button", "Create component"));
        tweaks->hide();
    }
}
