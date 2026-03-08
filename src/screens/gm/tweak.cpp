#include <i18n.h>
#include <limits>
#include <type_traits>
#include "tweak.h"
#include "playerInfo.h"
#include "engine.h"
#include "ai/ai.h"
#include "ecs/query.h"

#include "components/collision.h"
#include "components/database.h"
#include "components/name.h"
#include "components/ai.h"
#include "components/avoidobject.h"
#include "components/beamweapon.h"
#include "components/comms.h"
#include "components/coolant.h"
#include "components/docking.h"
#include "components/faction.h"
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
#include "components/sfx.h"
#include "components/shields.h"
#include "components/spin.h"
#include "components/target.h"
#include "components/warpdrive.h"
#include "components/zone.h"

#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"
#include "gui/gui2_listbox.h"
#include "gui/gui2_scrollcontainer.h"
#include "gui/gui2_scrolltext.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_rotationdial.h"
#include "gui/gui2_slider.h"
#include "gui/gui2_textentry.h"
#include "gui/gui2_togglebutton.h"

// Convert AI orders to string.
// TODO: These conversions should have a single source of truth.
static string getAIOrderString(AIOrder order)
{
    switch (order)
    {
    case AIOrder::Idle:            return tr("ai_order", "Idle");
    case AIOrder::Roaming:         return tr("ai_order", "Roaming");
    case AIOrder::Retreat:         return tr("ai_order", "Retreat");
    case AIOrder::StandGround:     return tr("ai_order", "Stand Ground");
    case AIOrder::DefendLocation:  return tr("ai_order", "Defend Location");
    case AIOrder::DefendTarget:    return tr("ai_order", "Defend Target");
    case AIOrder::FlyFormation:    return tr("ai_order", "Fly in formation");
    case AIOrder::FlyTowards:      return tr("ai_order", "Fly towards");
    case AIOrder::FlyTowardsBlind: return tr("ai_order", "Fly towards (ignore all)");
    case AIOrder::Dock:            return tr("ai_order", "Dock");
    case AIOrder::Attack:          return tr("ai_order", "Attack");
    }

    return tr("Unknown");
}

// Convert docking port states to string.
static string getDockingStateString(DockingPort::State state)
{
    switch (state)
    {
    case DockingPort::State::NotDocking: return tr("docking_state", "Not docking");
    case DockingPort::State::Docking:    return tr("docking_state", "Docking");
    case DockingPort::State::Docked:     return tr("docking_state", "Docked");
    }

    return tr("Unknown");
}

// Convert damage type to string.
static string damageTypeToString(DamageType t)
{
    switch (t)
    {
    case DamageType::Energy:  return tr("damage_type", "Energy");
    case DamageType::Kinetic: return tr("damage_type", "Kinetic");
    case DamageType::EMP:     return tr("damage_type", "EMP");
    }

    return tr("Unknown");
}

// Convert main screen mode to string.
static string mainScreenSettingToLocaleString(MainScreenSetting setting)
{
    switch (setting)
    {
    case MainScreenSetting::Front:     return tr("main_screen", "Front");
    case MainScreenSetting::Back:      return tr("main_screen", "Back");
    case MainScreenSetting::Left:      return tr("main_screen", "Left");
    case MainScreenSetting::Right:     return tr("main_screen", "Right");
    case MainScreenSetting::Target:    return tr("main_screen", "Target");
    case MainScreenSetting::Tactical:  return tr("main_screen", "Tactical");
    case MainScreenSetting::LongRange: return tr("main_screen", "Long range");
    }

    return tr("Unknown");
}

// Convert main screen overlay mode (comms) to string.
static string mainScreenOverlayToLocaleString(MainScreenOverlay overlay)
{
    switch (overlay)
    {
    case MainScreenOverlay::HideComms: return tr("main_screen", "Hide comms");
    case MainScreenOverlay::ShowComms: return tr("main_screen", "Show comms");
    }

    return tr("Unknown");
}

// END GM screen-specific enum-to-string conversions
// BEGIN GM screen-specific GUI subclasses

/*
    GUI subclasses that implement behaviors specific to GM tweaks.
    Macros further down this file will implement several GUI classes that are
    frequently combined.

    Most have a private last_value initialized with quiet_NaN() because it's
    possible for no entity or component to be selected, so it should be OK for
    these elements to not have a last value.

    TODOs:

    - Use consts for row heights (30.0f) and label (20.0f), input (18.0f), and
      list (16.0f) text sizes.
    - Split these into their own files for inclusion, since tweak.cpp has gotten
      too bloated and scope has crept too much.
*/

// Helper to create a standard label-GuiTextEntry combo in a row.
void createLabeledEntry(GuiContainer* row, const std::string& label_text, GuiTextEntry*& entry)
{
    (new GuiLabel(row, "", label_text, 16.0f))
        ->setSize(20.0f, GuiElement::GuiSizeMax);
    entry = new GuiTextEntry(row, "", "");
    entry
        ->setTextSize(18.0f)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
}

// A single-line GuiTextEntry that tweaks a string property.
class GuiTextTweak : public GuiTextEntry
{
public:
    GuiTextTweak(GuiContainer* owner) : GuiTextEntry(owner, "", "")
    {
        setSize(GuiElement::GuiSizeMax, 30.0f);
        setTextSize(20.0f);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        if (!focus) setText(update_func());
        GuiTextEntry::onDraw(target);
    }

    std::function<string()> update_func;
};

// A GuiElement that tweaks a float value using a slider.
class GuiSliderTweak : public GuiElement
{
public:
    GuiSliderTweak(GuiContainer* owner, const string& label, float min_value, float max_value, float start_value, GuiSlider::func_t user_callback)
    : GuiElement(owner, "")
    {
        setSize(GuiElement::GuiSizeMax, 30.0f);
        setAttribute("layout", "horizontal");

        slider = new GuiSlider(this, "", min_value, max_value, start_value, [this, user_callback](float value)
            {
                value_entry->setText(string(value, 2));
                if (user_callback) user_callback(value);
            }
        );
        slider->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        value_entry = new GuiTextEntry(this, "", "");
        value_entry
            ->setTextSize(18.0f)
            ->callback(
                [min_value, max_value, this, user_callback](string text)
                {
                    float val = std::clamp(text.toFloat(), min_value, max_value);
                    slider->setValue(val);
                    if (user_callback) user_callback(val);
                }
            )
            ->setSize(75.0f, GuiElement::GuiSizeMax);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        if (update_func)
        {
            float val = update_func();
            if (val != last_value)
            {
                last_value = val;
                slider->setValue(val);
                value_entry->setText(string(val, 2));
            }
        }
        GuiElement::onDraw(target);
    }

    GuiSliderTweak* setValue(float value)
    {
        slider->setValue(value);
        value_entry->setText(string(value));
        return this;
    }

    float getValue() { return slider->getValue(); }

    GuiSliderTweak* addOverlay(uint8_t num_ticks, float size)
    {
        slider->addOverlay(num_ticks, size);
        return this;
    }

    GuiSliderTweak* addSnapValue(float value, float snap_distance)
    {
        slider->addSnapValue(value, snap_distance);
        return this;
    }

    std::function<float()> update_func;
    GuiSlider* slider;
    GuiTextEntry* value_entry;
private:
    float last_value = std::numeric_limits<float>::quiet_NaN();
};

// A GuiElement that tweaks a float value between 0-360 using a rotation dial.
// Unlike most tweak elements, this takes up two row heights.
class GuiRotationDialTweak : public GuiElement
{
public:
    GuiRotationDialTweak(GuiContainer* owner)
    : GuiElement(owner, "")
    {
        setSize(GuiElement::GuiSizeMax, 60.0f);
        setAttribute("layout", "horizontal");

        dial = new GuiRotationDial(this, "", 0.0f, 360.0f, 0.0f,
            [this](float value)
            {
                value_entry->setText(string(value, 1));
                if (callback) callback(value);
            }
        );
        dial
            ->setThickness(10.0f)
            ->setSize(60.0f, 60.0f);

        value_entry = new GuiTextEntry(this, "", "");
        value_entry
            ->setTextSize(18.0f)
            ->callback(
                [this](string text)
                {
                    float val = fmodf(text.toFloat() + 360.0f, 360.0f);
                    dial->setValue(val);
                    if (callback) callback(val);
                }
            )
            ->setSize(GuiElement::GuiSizeMax, 30.0f);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        if (update_func)
        {
            float val = fmodf(update_func() + 360.0f, 360.0f);
            if (val != last_value)
            {
                last_value = val;
                dial->setValue(val);
                value_entry->setText(string(val, 1));
            }
        }

        GuiElement::onDraw(target);
    }

    std::function<float()> update_func;
    std::function<void(float)> callback;
    GuiRotationDial* dial;
    GuiTextEntry* value_entry;
private:
    float last_value = std::numeric_limits<float>::quiet_NaN();
};

// A GuiToggleButton that tweaks a Boolean value.
class GuiToggleTweak : public GuiToggleButton
{
public:
    GuiToggleTweak(GuiContainer* owner, const string& label, GuiToggleButton::func_t callback)
    : GuiToggleButton(owner, "", label, callback)
    {
        setSize(GuiElement::GuiSizeMax, 30.0f);
        setTextSize(20.0f);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        if (update_func) setValue(update_func());
        GuiToggleButton::onDraw(target);
    }

    std::function<bool()> update_func;
};

// A GuiSelector that selects a vector member to tweak, for properties that are
// themselves vectors.
class GuiVectorTweak : public GuiSelector
{
public:
    GuiVectorTweak(GuiContainer* owner, string id)
    : GuiSelector(owner, id, [](int index, string value) {})
    {
        setSize(GuiElement::GuiSizeMax, 30.0f);
        setTextSize(20.0f);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        // Update list.
        if (update_func)
        {
            const int count = update_func();
            while (count > entryCount())
                addEntry(string(entryCount() + 1), entryCount());
            while (count < entryCount())
                removeEntry(entryCount() - 1);
        }

        GuiSelector::onDraw(target);
    }

    std::function<size_t()> update_func;
};

// A GuiSelector that tweaks an integer value using the selected entry's index.
// Map values to indices to confine selections to indexed values and associate
// them with string description values.
class GuiSelectorTweak : public GuiSelector
{
public:
    GuiSelectorTweak(GuiContainer* owner, string id, GuiSelector::func_t callback)
    : GuiSelector(owner, id, callback)
    {
        setSize(GuiElement::GuiSizeMax, 30.0f);
        setTextSize(20.0f);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        if (update_func)
        {
            auto new_index = update_func();
            if (new_index != getSelectionIndex())
                setSelectionIndex(new_index);
        }

        GuiSelector::onDraw(target);
    }

    // Update function that returns the integer index used to update the
    // GuiSelector.
    std::function<int()> update_func;
};

// A GuiSelector that selects from a list of entities with the CallSign
// component, for instance to select a property's target entity.
class GuiEntityPicker : public GuiSelector
{
public:
    GuiEntityPicker(GuiContainer* owner, string id, GuiSelector::func_t callback)
    : GuiSelector(owner, id, callback)
    {
        setSize(GuiElement::GuiSizeMax, 30.0f);
        setTextSize(18.0f);
        setButtonHeight(20.0f);
        addEntry(tr("tweak-entity", "(None)"), "");
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        updateEntityList();
        if (update_func)
        {
            auto entity = update_func();
            // No entity returned by the update function, so default to (None).
            if (!entity) setSelectionIndex(0);
            // Find and select the returned entity in the list.
            // TODO: Search field to narrow by string.
            else
            {
                string search_key = getEntityKey(entity);
                for (int i = 0; i < entryCount(); i++)
                {
                    if (getEntryValue(i) == search_key)
                    {
                        if (getSelectionIndex() != i) setSelectionIndex(i);
                        break;
                    }
                }
            }
        }

        GuiSelector::onDraw(target);
    }

    // Update function that returns an entity, which is searched for to update
    // the GuiSelector.
    std::function<sp::ecs::Entity()> update_func;

private:
    float last_update_time = 0.0f;

    // Only update the entity list every second to avoid performance issues.
    void updateEntityList()
    {
        if (engine->getElapsedTime() - last_update_time < 1.0f) return;
        last_update_time = engine->getElapsedTime();

        int current_selection = getSelectionIndex();
        string current_value = current_selection >= 0
            ? getEntryValue(current_selection)
            : "";

        // Clear all except "(None)" entry.
        while (entryCount() > 1) removeEntry(entryCount() - 1);

        // Add all entities with callsigns.
        for (auto [entity, callsign] : sp::ecs::Query<CallSign>())
        {
            string label = callsign.callsign;
            if (auto type_name = entity.getComponent<TypeName>())
            {
                label = tr("{label} ({type})").format({
                    {"label", label},
                    {"type", type_name->type_name}
                });
            }
            addEntry(label, getEntityKey(entity));
        }

        // Restore the selection if the entity still exists.
        if (!current_value.empty())
        {
            for (int i = 0; i < entryCount(); i++)
            {
                if (getEntryValue(i) == current_value)
                {
                    setSelectionIndex(i);
                    return;
                }
            }
        }

        // Default to (None).
        setSelectionIndex(0);
    }

    string getEntityKey(sp::ecs::Entity entity) { return entity.toString(); }
};

// GuiSelector for selecting a Database component entity as a navigational
// parent. The list is filtered to show only Database entities.
// TODO: This mostly duplicates, and could be replaced by, GuiEntityPicker.
class GuiDatabaseParentPicker : public GuiSelector
{
public:
    GuiDatabaseParentPicker(GuiContainer* owner, string id, GuiSelector::func_t callback)
    : GuiSelector(owner, id, callback)
    {
        setSize(GuiElement::GuiSizeMax, 30.0f);
        setTextSize(20.0f);
        addEntry(tr("tweak-entity", "(None)"), "");
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        updateEntityList();
        if (update_func)
        {
            auto entity = update_func();
            // No entity returned by the update function, so default to (None).
            if (!entity) setSelectionIndex(0);
            // Find and select the returned entity in the list.
            // TODO: Search field to narrow by string.
            else
            {
                string search_key = getEntityKey(entity);
                for (int i = 0; i < entryCount(); i++)
                {
                    if (getEntryValue(i) == search_key)
                    {
                        if (getSelectionIndex() != i) setSelectionIndex(i);
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

    // Only update the entity list every second to avoid performance issues.
    void updateEntityList()
    {
        if (engine->getElapsedTime() - last_update_time < 1.0f) return;
        last_update_time = engine->getElapsedTime();

        int current_selection = getSelectionIndex();
        string current_value = current_selection >= 0
            ? getEntryValue(current_selection)
            : "";

        // Clear all except "(None)" entry
        while (entryCount() > 1) removeEntry(entryCount() - 1);

        // Add all entities with the Database component.
        for (auto [entity, db] : sp::ecs::Query<Database>())
        {
            string label = db.name.empty()
                ? tr("(Unnamed)")
                : db.name;
            // Show current parent name, if it has one.
            if (db.parent)
            {
                if (auto parent_db = db.parent.getComponent<Database>())
                    label = parent_db->name + " > " + label;
            }

            addEntry(label, getEntityKey(entity));
        }

        // Restore the selection if the entity still exists.
        if (!current_value.empty())
        {
            for (int i = 0; i < entryCount(); i++)
            {
                if (getEntryValue(i) == current_value)
                {
                    setSelectionIndex(i);
                    return;
                }
            }
        }

        // Default to (None).
        setSelectionIndex(0);
    }

    string getEntityKey(sp::ecs::Entity entity)
    {
        return entity.toString();
    }
};

// GuiElement for tweaking 2D vector coordinate (X, Y) values.
class GuiVec2Tweak : public GuiElement
{
public:
    GuiVec2Tweak(GuiContainer* owner) : GuiElement(owner, "")
    {
        setSize(GuiElement::GuiSizeMax, 30.0f);
        setAttribute("layout", "horizontal");

        (new GuiLabel(this, "", "X:", 20.0f))
            ->setSize(20.0f, GuiElement::GuiSizeMax);

        x_input = new GuiTextEntry(this, "", "");
        x_input
            ->setTextSize(20.0f)
            ->callback(
                [this](string text)
                {
                    if (callback)
                    {
                        glm::vec2 value = update_func
                            ? update_func()
                            : glm::vec2(0.0f, 0.0f);
                        value.x = text.toFloat();
                        callback(value);
                    }
                }
            )
            ->setSize(GuiElement::GuiSizeMax, 30.0f);

        (new GuiLabel(this, "", "Y:", 20.0f))
            ->setSize(20.0f, GuiElement::GuiSizeMax);

        y_input = new GuiTextEntry(this, "", "");
        y_input
            ->setTextSize(20.0f)
            ->callback(
                [this](string text)
                {
                    if (callback)
                    {
                        glm::vec2 value = update_func
                            ? update_func()
                            : glm::vec2(0.0f, 0.0f);
                        value.y = text.toFloat();
                        callback(value);
                    }
                }
            )
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        // Update only if text hasn't been manually changed.
        if (update_func)
        {
            glm::vec2 value = update_func();

            if (x_input->getText().toFloat() != value.x)
                x_input->setText(string(value.x, 1));
            if (y_input->getText().toFloat() != value.y)
                y_input->setText(string(value.y, 1));
        }

        GuiElement::onDraw(target);
    }

    std::function<glm::vec2()> update_func;
    std::function<void(glm::vec2)> callback;
    GuiTextEntry* x_input;
    GuiTextEntry* y_input;
};

// GuiElement for tweaking a float value and its corresponding maximum value on
// a single row, as [value] / [max]. Validates that the value doesn't exceed the
// maximum.
class GuiValueMaxTweak : public GuiElement
{
public:
    GuiValueMaxTweak(GuiContainer* owner) : GuiElement(owner, "")
    {
        setSize(GuiElement::GuiSizeMax, 30.0f);
        setAttribute("layout", "horizontal");

        val_input = new GuiTextEntry(this, "", "");
        val_input
            ->setTextSize(20.0f)
            ->callback(
                [this](string text)
                {
                    if (val_callback) val_callback(text.toFloat());
                }
            )
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        (new GuiLabel(this, "", "/", 20.0f))
            ->setSize(20.0f, GuiElement::GuiSizeMax);

        max_input = new GuiTextEntry(this, "", "");
        max_input
            ->setTextSize(20.0f)
            ->callback(
                [this](string text)
                {
                    if (max_callback) max_callback(text.toFloat());
                }
            )
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        if (val_update_func)
        {
            float val = val_update_func();
            if (val_input->getText().toFloat() != val)
                val_input->setText(string(val, 1));
        }
        if (max_update_func)
        {
            float max = max_update_func();
            if (max_input->getText().toFloat() != max)
                max_input->setText(string(max, 1));
        }
        GuiElement::onDraw(target);
    }

    std::function<float()> val_update_func;
    std::function<float()> max_update_func;
    std::function<void(float)> val_callback;
    std::function<void(float)> max_callback;
    GuiTextEntry* val_input;
    GuiTextEntry* max_input;
};

// Sliders and text entry fields for editing RGBA or RGB color values, with a
// preview bar of the resulting color. Pass with_alpha=false for RGB-only use.
class GuiColorPicker : public GuiElement
{
public:
    GuiColorPicker(GuiContainer* owner, bool with_alpha = true) : GuiElement(owner, "")
    {
        setSize(GuiElement::GuiSizeMax, with_alpha ? 150.0f : 120.0f);
        setAttribute("layout", "vertical");

        // Red slider
        auto row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "", tr("tweak-color-red", "R:"), 20.0f))
            ->setSize(30.0f, GuiElement::GuiSizeMax);

        r_slider = new GuiSliderTweak(row, "", 0.0f, 255.0f, 0.0f,
            [this](float value)
            {
                if (callback && update_func)
                {
                    auto color = update_func();
                    color.r = static_cast<uint8_t>(value);
                    callback(color);
                }
            }
        );
        r_slider->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        // Green slider
        row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "", tr("tweak-color-green", "G:"), 20.0f))
            ->setSize(30.0f, GuiElement::GuiSizeMax);

        g_slider = new GuiSliderTweak(row, "", 0.0f, 255.0f, 0.0f,
            [this](float value)
            {
                if (callback && update_func)
                {
                    auto color = update_func();
                    color.g = static_cast<uint8_t>(value);
                    callback(color);
                }
            }
        );
        g_slider->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        // Blue slider
        row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "", tr("tweak-color-blue", "B:"), 20.0f))
            ->setSize(30.0f, GuiElement::GuiSizeMax);

        b_slider = new GuiSliderTweak(row, "", 0.0f, 255.0f, 0.0f,
            [this](float value)
            {
                if (callback && update_func)
                {
                    auto color = update_func();
                    color.b = static_cast<uint8_t>(value);
                    callback(color);
                }
            }
        );
        b_slider->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        if (with_alpha)
        {
            // Alpha slider
            row = new GuiElement(this, "");
            row
                ->setSize(GuiElement::GuiSizeMax, 30.0f)
                ->setAttribute("layout", "horizontal");

            (new GuiLabel(row, "", tr("tweak-color-alpha", "A:"), 20.0f))
                ->setSize(30.0f, GuiElement::GuiSizeMax);

            a_slider = new GuiSliderTweak(row, "", 0.0f, 255.0f, 255.0f,
                [this](float value)
                {
                    if (callback && update_func)
                    {
                        auto color = update_func();
                        color.a = static_cast<uint8_t>(value);
                        callback(color);
                    }
                }
            );
            a_slider->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        }

        // Preview row
        row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        glm::u8vec4 color{255, 255, 255, 255};

        if (update_func)
        {
            color = update_func();
            r_slider->setValue(static_cast<float>(color.r));
            g_slider->setValue(static_cast<float>(color.g));
            b_slider->setValue(static_cast<float>(color.b));
            if (a_slider) a_slider->setValue(static_cast<float>(color.a));
        }
        GuiElement::onDraw(target);

        // Draw color preview rect in the space reserved by the preview row.
        float preview_y = rect.position.y + (a_slider ? 120.0f : 90.0f);
        target.drawTriangleStrip({
            {rect.position.x, preview_y},
            {rect.position.x + rect.size.x, preview_y},
            {rect.position.x, preview_y + 30.0f},
            {rect.position.x + rect.size.x, preview_y + 30.0f}
        }, color);
    }

    std::function<glm::u8vec4()> update_func;
    std::function<void(glm::u8vec4)> callback;
    GuiSliderTweak* r_slider;
    GuiSliderTweak* g_slider;
    GuiSliderTweak* b_slider;
    GuiSliderTweak* a_slider = nullptr;
};

// GuiScrollText to display multiline text properties.
// TODO: Make an editable multiline GuiTextEntry to use here.
class GuiMultilineTextTweak : public GuiScrollText
{
public:
    GuiMultilineTextTweak(GuiContainer* owner, int lines = 5)
    : GuiScrollText(owner, "", "")
    {
        setSize(GuiElement::GuiSizeMax, lines * 30.0f);
        setTextSize(18.0f);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        if (update_func) setText(update_func());
        GuiScrollText::onDraw(target);
    }

    std::function<string()> update_func;
};

// GuiSelector for tweaking an assigned Faction entity. On the GM screen, this
// is mostly redundant with the faction_selector.
// TODO: Redundant with entity selector?
class GuiFactionSelectorTweak : public GuiSelector
{
public:
    GuiFactionSelectorTweak(GuiContainer* owner, string id, GuiSelector::func_t callback)
    : GuiSelector(owner, id, callback)
    {
        setSize(GuiElement::GuiSizeMax, 30.0f);
        setTextSize(20.0f);
        addEntry(tr("tweak-faction", "(None)"), "");
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        updateFactionList();
        if (update_func)
        {
            if (auto faction_entity = update_func())
            {
                // Find faction in list.
                // TODO: Search by string
                string search_key = faction_entity.toString();
                for (int i = 0; i < entryCount(); i++)
                {
                    if (getEntryValue(i) == search_key)
                    {
                        if (getSelectionIndex() != i) setSelectionIndex(i);
                        break;
                    }
                }
            }
            else setSelectionIndex(0);
        }

        GuiSelector::onDraw(target);
    }

    std::function<sp::ecs::Entity()> update_func;

private:
    float last_update_time = 0.0f;

    // Only update faction list every 1 second to avoid performance issues.
    void updateFactionList()
    {
        if (engine->getElapsedTime() - last_update_time < 1.0f) return;
        last_update_time = engine->getElapsedTime();

        int current_selection = getSelectionIndex();
        string current_value = current_selection >= 0 ? getEntryValue(current_selection) : "";

        // Clear all except "(None)" entry
        while (entryCount() > 1) removeEntry(entryCount() - 1);

        // Add all factions
        for (auto [entity, faction_info] : sp::ecs::Query<FactionInfo>())
            addEntry(faction_info.name, entity.toString());

        // Restore selection if faction still exists.
        if (!current_value.empty())
        {
            for (int i = 0; i < entryCount(); i++)
            {
                if (getEntryValue(i) == current_value)
                {
                    setSelectionIndex(i);
                    return;
                }
            }
        }

        // Default to (None).
        setSelectionIndex(0);
    }
};

// GuiLabel for displaying the countdown to a jump in progress.
// TODO: This doesn't need its own class unless there's another place to use
// this.
class GuiJumpCountdownDisplay : public GuiLabel
{
public:
    GuiJumpCountdownDisplay(GuiContainer* owner, sp::ecs::Entity& entity_ref)
    : GuiLabel(owner, "", " ---", 20.0f), entity(entity_ref)
    {
        setAlignment(sp::Alignment::CenterLeft);
        setSize(GuiElement::GuiSizeMax, 30.0f);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        auto v = entity.getComponent<JumpDrive>();
        if (v && v->delay > 0.0f)
            setText(" " + string(v->get_seconds_to_jump()));
        else
            setText(" ---");

        GuiLabel::onDraw(target);
    }

private:
    sp::ecs::Entity& entity;
};

// Lists and adds edit, add, and delete controls to tweak properties that are
// unordered_set<string>, such as lists of docking classes.
class GuiStringSetTweak : public GuiElement
{
public:
    GuiStringSetTweak(GuiContainer* owner) : GuiElement(owner, "")
    {
        setSize(GuiElement::GuiSizeMax, 150.0f);
        setAttribute("layout", "vertical");

        // List of current items
        item_list = new GuiListbox(this, "",
            [this](int index, string value)
            {
                selected_index = index;
            }
        );
        item_list
            ->setTextSize(18.0f)
            ->setButtonHeight(20.0f)
            ->setSize(GuiElement::GuiSizeMax, 90.0f);

        // Add new item controls.
        auto row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        new_item_entry = new GuiTextEntry(row, "", "");
        new_item_entry
            ->setTextSize(18.0f)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        (new GuiButton(row, "", tr("tweak-button", "Add"),
            [this]()
            {
                string new_item = new_item_entry->getText();
                if (!new_item.empty() && on_add)
                {
                    on_add(new_item);
                    new_item_entry->setText("");
                }
            }
        ))
            ->setTextSize(18.0f)
            ->setSize(60.0f, GuiElement::GuiSizeMax);

        (new GuiButton(row, "", tr("tweak-button", "Del"),
            [this]()
            {
                if (selected_index >= 0
                    && selected_index < item_list->entryCount()
                    && on_remove)
                {
                    string item = item_list->getEntryValue(selected_index);
                    on_remove(item);
                    selected_index = -1;
                }
            }
        ))
            ->setTextSize(18.0f)
            ->setSize(60.0f, GuiElement::GuiSizeMax);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        if (update_func)
        {
            auto current_set = update_func();

            // Rebuild list if set changed.
            if (current_set.size() != static_cast<size_t>(item_list->entryCount()))
            {
                item_list->setOptions({});
                for (const auto& item : current_set) item_list->addEntry(item, item);
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

// Lists and adds edit, add, and delete controls to tweak properties that are
// unordered_map<string, string>.
// TODO: Is this necessary? Only added it because it's GuiStringSetTweak with
// a second field.
class GuiStringMapTweak : public GuiElement
{
public:
    GuiStringMapTweak(GuiContainer* owner) : GuiElement(owner, "")
    {
        setSize(GuiElement::GuiSizeMax, 180.0f);
        setAttribute("layout", "vertical");

        // List of current key-value pairs.
        item_list = new GuiListbox(this, "", [this](int index, string value)
        {
            selected_index = index;
        });
        item_list
            ->setTextSize(18.0f)
            ->setButtonHeight(20.0f)
            ->setSize(GuiElement::GuiSizeMax, 90.0f);

        // Add new item controls.
        auto row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        key_entry = new GuiTextEntry(row, "", "");
        key_entry
            ->setTextSize(18.0f)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        value_entry = new GuiTextEntry(row, "", "");
        value_entry
            ->setTextSize(18.0f)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        (new GuiButton(row, "", tr("tweak-button", "Add"),
            [this]()
            {
                string key = key_entry->getText();
                string value = value_entry->getText();
                if (!key.empty() && on_add)
                {
                    on_add(key, value);
                    key_entry->setText("");
                    value_entry->setText("");
                }
            }
        ))
            ->setTextSize(18.0f)
            ->setSize(60.0f, GuiElement::GuiSizeMax);

        (new GuiButton(row, "", tr("tweak-button", "Del"),
            [this]()
            {
                if (selected_index >= 0
                    && selected_index < item_list->entryCount()
                    && on_remove)
                {
                    string key = item_list->getEntryValue(selected_index);
                    on_remove(key);
                    selected_index = -1;
                }
            }
        ))
            ->setTextSize(18.0f)
            ->setSize(60.0f, GuiElement::GuiSizeMax);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        if (update_func)
        {
            auto current_map = update_func();

            // Rebuild list if map changed.
            if (current_map.size() != static_cast<size_t>(item_list->entryCount()))
            {
                item_list->setOptions({});
                for (const auto& [key, value] : current_map)
                    item_list->addEntry(key + " = " + value, key);
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

// Lists and adds edit, add, and delete controls to tweak properties that are
// std::vector<glm::vec2>, such as Zone outline points.
class GuiVec2VectorTweak : public GuiElement
{
public:
    GuiVec2VectorTweak(GuiContainer* owner) : GuiElement(owner, "")
    {
        setSize(GuiElement::GuiSizeMax, 150.0f);
        setAttribute("layout", "vertical");

        // List of current points
        item_list = new GuiListbox(this, "",
            [this](int index, string value)
            {
                selected_index = index;
            }
        );
        item_list
            ->setTextSize(18.0f)
            ->setButtonHeight(20.0f)
            ->setSize(GuiElement::GuiSizeMax, 90.0f);

        // Add new point controls
        auto row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "", "X:", 16.0f))
            ->setSize(20.0f, GuiElement::GuiSizeMax);

        x_entry = new GuiTextEntry(row, "", "");
        x_entry
            ->setTextSize(18.0f)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        (new GuiLabel(row, "", "Y:", 16.0f))
            ->setSize(20.0f, GuiElement::GuiSizeMax);

        y_entry = new GuiTextEntry(row, "", "");
        y_entry
            ->setTextSize(18.0f)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiButton(row, "", tr("tweak-button", "Add"),
            [this]()
            {
                string x_str = x_entry->getText();
                string y_str = y_entry->getText();
                if (!x_str.empty()
                    && !y_str.empty()
                    && on_add)
                {
                    glm::vec2 point(x_str.toFloat(), y_str.toFloat());
                    on_add(point);
                    x_entry->setText("");
                    y_entry->setText("");
                }
            }
        ))
            ->setTextSize(18.0f)
            ->setSize(60.0f, GuiElement::GuiSizeMax);

        (new GuiButton(row, "", tr("tweak-button", "Del"),
            [this]()
            {
                if (selected_index >= 0
                    && selected_index < item_list->entryCount()
                    && on_remove)
                {
                    on_remove(selected_index);
                    selected_index = -1;
                }
            }
        ))
            ->setTextSize(18.0f)
            ->setSize(60.0f, GuiElement::GuiSizeMax);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        if (update_func)
        {
            auto current_vector = update_func();

            // Rebuild list if vector size changed.
            if (current_vector.size() != static_cast<size_t>(item_list->entryCount()))
            {
                item_list->setOptions({});
                for (size_t i = 0; i < current_vector.size(); i++)
                {
                    const auto& point = current_vector[i];
                    string display = tr("{index}: {x}, {y}").format({
                        {"index", string(static_cast<int>(i))},
                        {"x", string(point.x, 1)},
                        {"y", string(point.y, 1)}
                    });
                    item_list->addEntry(display, string(static_cast<int>(i)));
                }
            }
        }
        GuiElement::onDraw(target);
    }

    std::function<std::vector<glm::vec2>()> update_func;
    std::function<void(const glm::vec2&)> on_add;
    // Remove by index
    std::function<void(int)> on_remove;
    // Called after any modification
    std::function<void()> on_change;

private:
    GuiListbox* item_list;
    GuiTextEntry* x_entry;
    GuiTextEntry* y_entry;
    int selected_index = -1;
};

// Lists and adds edit, add, and delete controls to tweak
// std::vector<Database::KeyValue> Database entries.
class GuiDatabaseKeyValueTweak : public GuiElement
{
public:
    GuiDatabaseKeyValueTweak(GuiContainer* owner)
    : GuiElement(owner, "")
    {
        setSize(GuiElement::GuiSizeMax, 180.0f);
        setAttribute("layout", "vertical");

        // List key-value pairs.
        item_list = new GuiListbox(this, "",
            [this](int index, string value)
            {
                selected_index = index;
            }
        );
        item_list
            ->setTextSize(18.0f)
            ->setButtonHeight(20.0f)
            ->setSize(GuiElement::GuiSizeMax, 120.0f);

        // Add new key-value controls
        auto row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        key_entry = new GuiTextEntry(row, "", "");
        key_entry
            ->setTextSize(18.0f)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        value_entry = new GuiTextEntry(row, "", "");
        value_entry
            ->setTextSize(18.0f)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        (new GuiButton(row, "", tr("tweak-button", "Add"),
            [this]()
            {
                string key = key_entry->getText();
                string value = value_entry->getText();

                if (!key.empty() && on_add)
                {
                    on_add(key, value);
                    key_entry->setText("");
                    value_entry->setText("");
                }
            }
        ))
            ->setTextSize(18.0f)
            ->setSize(60.0f, GuiElement::GuiSizeMax);

        (new GuiButton(row, "", tr("tweak-button", "Del"),
            [this]()
            {
                if (selected_index >= 0
                    && selected_index < item_list->entryCount()
                    && on_remove)
                {
                    on_remove(selected_index);
                    selected_index = -1;
                }
            }
        ))
            ->setTextSize(18.0f)
            ->setSize(60.0f, GuiElement::GuiSizeMax);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        if (update_func)
        {
            auto current_vector = update_func();

            // Rebuild list if vector size changed
            if (current_vector.size() != static_cast<size_t>(item_list->entryCount()))
            {
                item_list->setOptions({});
                for (size_t i = 0; i < current_vector.size(); i++)
                {
                    const auto& kv = current_vector[i];
                    string display = string("{key} = {value}").format({
                        {"key", kv.key},
                        {"value", kv.value}
                    });
                    item_list->addEntry(display, string(static_cast<int>(i)));
                }
            }
        }

        GuiElement::onDraw(target);
    }

    std::function<std::vector<Database::KeyValue>()> update_func;
    std::function<void(const string&, const string&)> on_add;
    // Remove by index
    std::function<void(int)> on_remove;

private:
    GuiListbox* item_list;
    GuiTextEntry* key_entry;
    GuiTextEntry* value_entry;
    int selected_index = -1;
};

// Fields to tweak a vector of InternalRooms::Room entities.
class GuiRoomVectorTweak : public GuiElement
{
public:
    GuiRoomVectorTweak(GuiContainer* owner)
    : GuiElement(owner, "")
    {
        setSize(GuiElement::GuiSizeMax, 210.0f);
        setAttribute("layout", "vertical");

        item_list = new GuiListbox(this, "",
            [this](int index, string value)
            {
                selected_index = index;
            }
        );
        item_list
            ->setTextSize(18.0f)
            ->setButtonHeight(20.0f)
            ->setSize(GuiElement::GuiSizeMax, 90.0f);

        auto row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        createLabeledEntry(row, "X:", pos_x_entry);
        createLabeledEntry(row, "Y:", pos_y_entry);

        row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        createLabeledEntry(row, tr("tweak-width", "W:"), size_x_entry);
        createLabeledEntry(row, tr("tweak-height", "H:"), size_y_entry);

        row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "", tr("tweak-room", "Ship system"), 18.0f))
            ->setSize(90.0f, GuiElement::GuiSizeMax);

        system_selector = new GuiSelector(row, "ROOM_SYSTEM_SEL", nullptr);
        system_selector->addEntry(tr("tweak-room", "None"), "-1");
        for (int i = 0; i < ShipSystem::COUNT; i++)
            system_selector->addEntry(getLocaleSystemName(static_cast<ShipSystem::Type>(i)), string(i));
        system_selector
            ->setTextSize(18.0f)
            ->setSelectionIndex(0)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiButton(row, "", tr("tweak-button", "Add"),
            [this]()
            {
                if (on_add)
                {
                    InternalRooms::Room room;
                    room.position = glm::ivec2(pos_x_entry->getText().toInt(), pos_y_entry->getText().toInt());
                    room.size = glm::ivec2(size_x_entry->getText().toInt(), size_y_entry->getText().toInt());
                    room.system = static_cast<ShipSystem::Type>(system_selector->getSelectionIndex() - 1);
                    on_add(room);
                }
            }
        ))
            ->setTextSize(18.0f)
            ->setSize(60.0f, GuiElement::GuiSizeMax);

        (new GuiButton(row, "", tr("tweak-button", "Del"),
            [this]()
            {
                if (selected_index >= 0
                    && selected_index < item_list->entryCount()
                    && on_remove)
                {
                    on_remove(selected_index);
                    selected_index = -1;
                }
            }
        ))
            ->setTextSize(18.0f)
            ->setSize(60.0f, GuiElement::GuiSizeMax);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        if (update_func)
        {
            auto current_vector = update_func();
            if (current_vector.size() != static_cast<size_t>(item_list->entryCount()))
            {
                item_list->setOptions({});
                for (size_t i = 0; i < current_vector.size(); i++)
                {
                    const auto& room = current_vector[i];
                    const string display = tr("tweak-room", "({position_x},{position_y} {size_w}x{size_h}) {system_name}").format({
                        {"position_x", string(room.position.x)},
                        {"position_y", string(room.position.y)},
                        {"size_w", string(room.size.x)},
                        {"size_h", string(room.size.y)},
                        {"system_name", room.system == ShipSystem::Type::None ? "-" : getLocaleSystemName(room.system)}
                    });
                    item_list->addEntry(display, string(static_cast<int>(i)));
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

// Fields to tweak a vector of InternalRooms::Door entities.
class GuiDoorVectorTweak : public GuiElement
{
public:
    GuiDoorVectorTweak(GuiContainer* owner)
    : GuiElement(owner, "")
    {
        setSize(GuiElement::GuiSizeMax, 210.0f);
        setAttribute("layout", "vertical");

        item_list = new GuiListbox(this, "",
            [this](int index, string value)
            {
                selected_index = index;
            }
        );
        item_list
            ->setTextSize(18.0f)
            ->setButtonHeight(20.0f)
            ->setSize(GuiElement::GuiSizeMax, 90.0f);

        auto row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        createLabeledEntry(row, "X:", pos_x_entry);
        createLabeledEntry(row, "Y:", pos_y_entry);

        row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "", tr("tweak-room", "Ship system"), 18.0f))
            ->setSize(90.0f, GuiElement::GuiSizeMax);

        horizontal_toggle = new GuiToggleButton(row, "DOOR_HORIZ", tr("tweak-door", "Horizontal"), nullptr);
        horizontal_toggle
            ->setTextSize(18.0f)
            ->setSize(80.0f, GuiElement::GuiSizeMax);

        (new GuiButton(row, "", tr("tweak-button", "Add"),
            [this]()
            {
                if (on_add)
                {
                    InternalRooms::Door door;
                    door.position = glm::ivec2(pos_x_entry->getText().toInt(), pos_y_entry->getText().toInt());
                    door.horizontal = horizontal_toggle->getValue();
                    on_add(door);
                }
            }
        ))
            ->setTextSize(18.0f)
            ->setSize(60.0f, GuiElement::GuiSizeMax);

        (new GuiButton(row, "", tr("tweak-button", "Del"),
            [this]()
            {
                if (selected_index >= 0
                    && selected_index < item_list->entryCount()
                    && on_remove)
                {
                    on_remove(selected_index);
                    selected_index = -1;
                }
            }
        ))
            ->setTextSize(18.0f)
            ->setSize(60.0f, GuiElement::GuiSizeMax);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        if (update_func)
        {
            auto current_vector = update_func();
            if (current_vector.size() != static_cast<size_t>(item_list->entryCount()))
            {
                item_list->setOptions({});
                for (size_t i = 0; i < current_vector.size(); i++)
                {
                    const auto& door = current_vector[i];
                    const string display = tr("tweak-door", "({position_x},{position_y}) {orientation}").format({
                        {"position_x", string(door.position.x)},
                        {"position_y", string(door.position.y)},
                        {"orientation", door.horizontal ? tr("tweak-door", "Horizontal") : tr("tweak-door", "Vertical")}
                    });
                    item_list->addEntry(display, string(static_cast<int>(i)));
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

// Fields to tweak a vector of EngineEmitter::Emitter entities.
class GuiEngineEmittersTweak : public GuiElement
{
public:
    GuiEngineEmittersTweak(GuiContainer* owner)
    : GuiElement(owner, "")
    {
        setSize(GuiElement::GuiSizeMax, 270.0f);
        setAttribute("layout", "vertical");

        // List all emitters in a selectable Listbox.
        item_list = new GuiListbox(this, "",
            [this](int index, string value)
            {
                selected_index = index;
                if (update_func)
                {
                    auto emitters = update_func();
                    if (index >= 0 && index < static_cast<int>(emitters.size()))
                    {
                        const auto& e = emitters[index];
                        pos_x_entry->setText(string(e.position.x, 2));
                        pos_y_entry->setText(string(e.position.y, 2));
                        pos_z_entry->setText(string(e.position.z, 2));
                        scale_entry->setText(string(e.scale, 2));
                        edit_color = e.color;
                    }
                }
            }
        );
        item_list
            ->setTextSize(16.0f)
            ->setButtonHeight(20.0f)
            ->setSize(GuiElement::GuiSizeMax, 90.0f);

        // Set the emitter's coordinates of relative to the model's center.
        auto row = new GuiElement(this, "");
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal");

        createLabeledEntry(row, "X:", pos_x_entry);
        createLabeledEntry(row, "Y:", pos_y_entry);
        createLabeledEntry(row, "Z:", pos_z_entry);

        // Set the emitter's color.
        color_picker = new GuiColorPicker(this, false);
        color_picker->update_func = [this]() -> glm::u8vec4 {
            return glm::u8vec4(
                static_cast<uint8_t>(edit_color.r * 255.0f),
                static_cast<uint8_t>(edit_color.g * 255.0f),
                static_cast<uint8_t>(edit_color.b * 255.0f),
                255);
        };
        color_picker->callback = [this](glm::u8vec4 color) {
            edit_color = glm::vec3(color.r / 255.0f, color.g / 255.0f, color.b / 255.0f);
        };

        // Set the emitter's scale.
        row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "", tr("tweak-text", "Scale:"), 20.0f))
            ->setSize(40.0f, GuiElement::GuiSizeMax);

        scale_entry = new GuiTextEntry(row, "", "");
        scale_entry
            ->setTextSize(20.0f)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        // Add, apply changes to, or remove the selected emitter.
        row = new GuiElement(this, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiButton(row, "", tr("tweak-button", "Add"),
            [this]()
            {
                if (on_add)
                {
                    EngineEmitter::Emitter e;
                    e.position = glm::vec3(pos_x_entry->getText().toFloat(), pos_y_entry->getText().toFloat(), pos_z_entry->getText().toFloat());
                    e.color = edit_color;
                    e.scale = scale_entry->getText().toFloat();
                    on_add(e);
                }
            }
        ))
            ->setTextSize(18.0f)
            ->setSize(60.0f, GuiElement::GuiSizeMax);

        (new GuiButton(row, "", tr("tweak-button", "Apply"),
            [this]()
            {
                if (selected_index >= 0 && selected_index < item_list->entryCount() && on_update)
                {
                    EngineEmitter::Emitter e;
                    e.position = glm::vec3(pos_x_entry->getText().toFloat(), pos_y_entry->getText().toFloat(), pos_z_entry->getText().toFloat());
                    e.color = edit_color;
                    e.scale = scale_entry->getText().toFloat();
                    on_update(selected_index, e);
                }
            }
        ))
            ->setTextSize(18.0f)
            ->setSize(60.0f, GuiElement::GuiSizeMax);

        (new GuiButton(row, "", tr("tweak-button", "Del"),
            [this]()
            {
                if (selected_index >= 0
                    && selected_index < item_list->entryCount()
                    && on_remove)
                {
                    on_remove(selected_index);
                    selected_index = -1;
                }
            }
        ))
            ->setTextSize(18.0f)
            ->setSize(60.0f, GuiElement::GuiSizeMax);
    }

    virtual void onDraw(sp::RenderTarget& target) override
    {
        if (update_func)
        {
            auto current_vector = update_func();
            std::vector<string> entries;
            entries.reserve(current_vector.size());

            // Update the emitter list's entries.
            for (size_t i = 0; i < current_vector.size(); i++)
            {
                const auto& e = current_vector[i];
                entries.push_back(string("{index}: x {x}, y {y}, z {z}; scale {scale}").format({
                    {"index", static_cast<int>(i)},
                    {"x", string(e.position.x, 1)},
                    {"y", string(e.position.y, 1)},
                    {"z", string(e.position.z, 1)},
                    {"scale", string(e.scale, 2)}
                }));
            }

            // Resize the emitter list.
            if (entries.size() != static_cast<size_t>(item_list->entryCount())
                || entries != cached_entries)
            {
                cached_entries = entries;
                item_list->setOptions({});
                for (size_t i = 0; i < entries.size(); i++)
                    item_list->addEntry(entries[i], string(static_cast<int>(i)));
                if (selected_index >= 0 && selected_index < item_list->entryCount())
                    item_list->setSelectionIndex(selected_index);
            }
        }

        GuiElement::onDraw(target);
    }

    std::function<std::vector<EngineEmitter::Emitter>()> update_func;
    std::function<void(const EngineEmitter::Emitter&)> on_add;
    std::function<void(int, const EngineEmitter::Emitter&)> on_update;
    std::function<void(int)> on_remove;

private:
    GuiListbox* item_list;
    GuiTextEntry* pos_x_entry;
    GuiTextEntry* pos_y_entry;
    GuiTextEntry* pos_z_entry;
    GuiColorPicker* color_picker;
    glm::vec3 edit_color{1.0f, 1.0f, 1.0f};
    GuiTextEntry* scale_entry;
    int selected_index = -1;
    std::vector<string> cached_entries;
};

// BEGIN macros for GM tweak UI elements

// Add a new tweak page for the given component.
#define ADD_PAGE(LABEL, COMPONENT) \
    new_page = new GuiTweakPage(content); \
    new_page->has_component = [](sp::ecs::Entity e) { return e.hasComponent<COMPONENT>(); }; \
    new_page->add_component = [page_ptr = new_page](sp::ecs::Entity e) { \
        e.addComponent<COMPONENT>(); \
        for (auto& fn : page_ptr->apply_functions) fn(); \
    }; \
    new_page->remove_component = [](sp::ecs::Entity e) { e.removeComponent<COMPONENT>(); }; \
    pages.push_back(new_page); \
    page_labels.push_back(LABEL);
// Add a new label to this tweak page.
#define ADD_LABEL(LABEL) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        row->setAttribute("margin", "0, 0, 10, 0"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->addBackground()->setAlignment(sp::Alignment::Center)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
    } while(0)
// Add a field to tweak a string value for the given component.
#define ADD_TEXT_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiTextTweak(row); \
        ui->update_func = [this, ui]() -> string { if (auto v = entity.getComponent<COMPONENT>()) return v->VALUE; return ui->getText(); }; \
        ui->callback([this](string text) { if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = text; }); \
        new_page->apply_functions.push_back([this, ui]() { \
            string text = ui->getText(); \
            if (!text.empty()) { if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = text; } \
        }); \
    } while(0)
// Add a text field to tweak a float value for the given component.
#define ADD_NUM_TEXT_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiTextTweak(row); \
        ui->update_func = [this, ui]() -> string { if (auto v = entity.getComponent<COMPONENT>()) return string(v->VALUE, 3); return ui->getText(); }; \
        ui->callback([this](string text) { if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = text.toFloat(); }); \
        new_page->apply_functions.push_back([this, ui]() { \
            string text = ui->getText(); \
            if (!text.empty()) { if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = text.toFloat(); } \
        }); \
    } while(0)
// Add a slider and text field to tweak a float value within a range for the
// given component.
#define ADD_NUM_SLIDER_TWEAK(LABEL, COMPONENT, MIN_VALUE, MAX_VALUE, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiSliderTweak(row, "", MIN_VALUE, MAX_VALUE, 0.0f, [this](float number) { \
            if (auto v = entity.getComponent<COMPONENT>()) \
                v->VALUE = number; \
        }); \
        ui->update_func = [this, ui]() -> float { \
            if (auto v = entity.getComponent<COMPONENT>()) \
                return v->VALUE; \
            return ui->value_entry->getText().toFloat(); \
        }; \
        new_page->apply_functions.push_back([this, ui]() { \
            string text = ui->value_entry->getText(); \
            if (!text.empty()) { \
                if (auto v = entity.getComponent<COMPONENT>()) \
                    v->VALUE = text.toFloat(); \
            } \
        }); \
    } while(0)
// Add a slider and text field to tweak an integer value within a range for the
// given component.
#define ADD_INT_SLIDER_TWEAK(LABEL, COMPONENT, MIN_VALUE, MAX_VALUE, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiSliderTweak(row, "", MIN_VALUE, MAX_VALUE, 0u, [this](float number) { if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = number; }); \
        for (float i = MIN_VALUE; i <= MAX_VALUE; i++) \
            ui->addSnapValue(i, 0.5f); \
        ui->addOverlay(0u, 20.0f); \
        ui->update_func = [this, ui]() -> float { \
            if (auto v = entity.getComponent<COMPONENT>()) \
                return v->VALUE; \
            return ui->value_entry->getText().toFloat(); }; \
        new_page->apply_functions.push_back([this, ui]() { \
            string text = ui->value_entry->getText(); \
            if (!text.empty()) { if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = static_cast<int>(text.toFloat()); } \
        }); \
    } while(0)
// Add a toggle button to tweak a Boolean field for the given component.
#define ADD_BOOL_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        auto ui = new GuiToggleTweak(row, LABEL, [this](bool value) { if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = value; }); \
        ui->update_func = [this, ui]() -> bool { \
            if (auto v = entity.getComponent<COMPONENT>()) \
                return v->VALUE; \
            return ui->getValue(); \
        }; \
        new_page->apply_functions.push_back([this, ui]() \
        { \
            if (auto v = entity.getComponent<COMPONENT>()) \
                v->VALUE = ui->getValue(); \
        }); \
    } while(0)
// Add a selector to select, add, and remove vector members of the given component.
#define ADD_VECTOR(LABEL, COMPONENT, VECTOR) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        vector_selector = new GuiVectorTweak(row, "VECTOR_SELECTOR"); \
        vector_selector->update_func = [this]() -> size_t { if (auto v = entity.getComponent<COMPONENT>()) return v->VECTOR.size(); return 0; }; \
        auto add = new GuiButton(row, "", tr("tweak-button", "Add"), [this, vector_selector](){ if (auto v = entity.getComponent<COMPONENT>()) { v->VECTOR.emplace_back(); vector_selector->setSelectionIndex(v->VECTOR.size()); } }); \
        add->setTextSize(20.0f)->setSize(50.0f, GuiElement::GuiSizeMax); \
        auto del = new GuiButton(row, "", tr("tweak-button", "Del"), [this](){ auto v = entity.getComponent<COMPONENT>(); if (v && v->VECTOR.size() > 0) v->VECTOR.pop_back(); }); \
        del->setTextSize(20.0f)->setSize(50.0f, GuiElement::GuiSizeMax); \
    } while(0)
// Add a text field to tweak a float value in a vector of the given component.
#define ADD_VECTOR_NUM_TEXT_TWEAK(LABEL, COMPONENT, VECTOR, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiTextTweak(row); \
        ui->update_func = [this, vector_selector, ui]() -> string { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) \
                return string(v->VECTOR[vector_selector->getSelectionIndex()].VALUE); \
            return ui->getText(); \
        }; \
        ui->callback([this, vector_selector](string text) { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) \
                v->VECTOR[vector_selector->getSelectionIndex()].VALUE = text.toFloat(); \
        }); \
    } while(0)
// Add text fields to tweak a float value and its corresponding maximum value
// in a vector of the given component.
#define ADD_VECTOR_VALUE_MAX_TWEAK(LABEL, COMPONENT, VECTOR, VALUE, MAX_VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiValueMaxTweak(row); \
        ui->val_update_func = [this, vector_selector, ui]() -> float { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) \
                return static_cast<float>(v->VECTOR[vector_selector->getSelectionIndex()].VALUE); \
            return ui->val_input->getText().toFloat(); }; \
        ui->max_update_func = [this, vector_selector, ui]() -> float { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) \
                return static_cast<float>(v->VECTOR[vector_selector->getSelectionIndex()].MAX_VALUE); \
            return ui->max_input->getText().toFloat(); }; \
        ui->val_callback = [this, vector_selector](float val) { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) \
                v->VECTOR[vector_selector->getSelectionIndex()].VALUE = static_cast<std::remove_reference_t<decltype(v->VECTOR[0].VALUE)>>(val); }; \
        ui->max_callback = [this, vector_selector](float val) { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) \
                v->VECTOR[vector_selector->getSelectionIndex()].MAX_VALUE = static_cast<std::remove_reference_t<decltype(v->VECTOR[0].MAX_VALUE)>>(val); }; \
    } while(0)
// Add a toggle button to tweak a Boolean value in a vector of the given
// component.
#define ADD_VECTOR_BOOL_TWEAK(LABEL, COMPONENT, VECTOR, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row \
            ->setSize(GuiElement::GuiSizeMax, 30.0f) \
            ->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiToggleTweak(row, "", [this, vector_selector](bool value) { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) \
                v->VECTOR[vector_selector->getSelectionIndex()].VALUE = value; }); \
        ui->update_func = [this, vector_selector, ui]() -> bool { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) \
                return v->VECTOR[vector_selector->getSelectionIndex()]->VALUE; \
            return ui->getValue(); }; \
    } while(0)
// Add toggle buttons to tweak a bitwise mask in a vector of the given
// component.
#define ADD_VECTOR_TOGGLE_MASK_TWEAK(LABEL, COMPONENT, VECTOR, VALUE, MASK) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        auto ui = new GuiToggleTweak(row, LABEL, [this, vector_selector](bool value) { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) { \
                if (value) v->VECTOR[vector_selector->getSelectionIndex()].VALUE |= (MASK); else v->VECTOR[vector_selector->getSelectionIndex()].VALUE &=~(MASK); } \
            }); \
        ui->update_func = [this, vector_selector, ui]() -> bool { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) \
                return v->VECTOR[vector_selector->getSelectionIndex()].VALUE & (MASK); \
            return ui->getValue(); }; \
    } while(0)
// Add a slider and text field to tweak a float value in a vector within a range
// for the given component.
#define ADD_VECTOR_NUM_SLIDER_TWEAK(LABEL, COMPONENT, VECTOR, MIN_VALUE, MAX_VALUE, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiSliderTweak(row, "", MIN_VALUE, MAX_VALUE, 0.0f, [this, vector_selector](float number) { \
            auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) \
                v->VECTOR[vector_selector->getSelectionIndex()].VALUE = number; \
        }); \
        ui->addOverlay(2u, 20.0f); \
        ui->update_func = [this, vector_selector, ui]() -> float { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) \
                return v->VECTOR[vector_selector->getSelectionIndex()].VALUE; \
            return ui->value_entry->getText().toFloat(); \
        }; \
    } while(0)
// Add a rotation dial to tweak a 0-360 float value for the given component.
#define ADD_ROTATION_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 60.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiRotationDialTweak(row); \
        ui->update_func = [this, ui]() -> float { if (auto v = entity.getComponent<COMPONENT>()) return static_cast<float>(v->VALUE); return ui->value_entry->getText().toFloat(); }; \
        ui->callback = [this](float val) { if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = static_cast<std::remove_reference_t<decltype(v->VALUE)>>(val); }; \
        new_page->apply_functions.push_back([this, ui]() { \
            string text = ui->value_entry->getText(); \
            if (!text.empty()) { if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = static_cast<std::remove_reference_t<decltype(v->VALUE)>>(fmodf(text.toFloat() + 360.0f, 360.0f)); } \
        }); \
    } while(0)
// Add a rotation dial to tweak a 0-360 float value in a vector of the given
// component.
#define ADD_VECTOR_ROTATION_TWEAK(LABEL, COMPONENT, VECTOR, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 60.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiRotationDialTweak(row); \
        ui->update_func = [this, vector_selector, ui]() -> float { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) \
                return static_cast<float>(v->VECTOR[vector_selector->getSelectionIndex()].VALUE); \
            return ui->value_entry->getText().toFloat(); }; \
        ui->callback = [this, vector_selector](float val) { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) \
                v->VECTOR[vector_selector->getSelectionIndex()].VALUE = static_cast<std::remove_reference_t<decltype(v->VECTOR[0].VALUE)>>(val); }; \
    } while(0)
// Add a selector to tweak an enumerated value in a vector of the given
// component.
#define ADD_VECTOR_ENUM_TWEAK(LABEL, COMPONENT, VECTOR, VALUE, MIN_VALUE, MAX_VALUE, STRING_CONVERT_FUNCTION) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiSelectorTweak(row, "", [this, vector_selector](int index, string value) { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) \
                v->VECTOR[vector_selector->getSelectionIndex()].VALUE = static_cast<decltype(decltype(COMPONENT::VECTOR)::value_type::VALUE)>(index + MIN_VALUE); \
        }); \
        for (int enum_value = MIN_VALUE; enum_value <= MAX_VALUE; enum_value++) \
            ui->addEntry(STRING_CONVERT_FUNCTION(static_cast<decltype(decltype(COMPONENT::VECTOR)::value_type::VALUE)>(enum_value)), string(enum_value)); \
        ui->update_func = [this, vector_selector, ui]() -> float { auto v = entity.getComponent<COMPONENT>(); \
            if (v && vector_selector->getSelectionIndex() >= 0 && vector_selector->getSelectionIndex() < static_cast<int>(v->VECTOR.size())) \
                return static_cast<int>(v->VECTOR[vector_selector->getSelectionIndex()].VALUE) - static_cast<int>(MIN_VALUE); \
            return ui->getSelectionIndex(); \
        }; \
    } while(0)
// Tweak the given ship system's properties using a collection of defined
// fields.
#define ADD_SHIP_SYSTEM_TWEAK(SYSTEM) \
      ADD_BOOL_TWEAK(tr("tweak-text", "Hackable"), SYSTEM, can_be_hacked); \
      ADD_VALUE_MAX_TWEAK(tr("tweak-text", "Health current/max:"), SYSTEM, health, health_max); \
      ADD_NUM_SLIDER_TWEAK(tr("tweak-text", "Heat:"), SYSTEM, 0.0f, 1.0f, heat_level); \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Energy rate factor:"), SYSTEM, power_factor); \
      { \
          auto row = new GuiElement(new_page->tweaks, ""); \
          row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
          (new GuiLabel(row, "", tr("tweak-text", "Value x power level x 0.08 = energy drained/sec"), 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
      } \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Heat added/sec:"), SYSTEM, heat_add_rate_per_second); \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Coolant change/sec:"), SYSTEM, coolant_change_rate_per_second); \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Power change/sec:"), SYSTEM, power_change_rate_per_second); \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Auto repair/sec:"), SYSTEM, auto_repair_per_second);
// As ADD_SHIP_SYSTEM_TWEAK, but for a ShipSystem that is a member of another
// component (i.e. front/rear shields as ship systems of the Shields component)
#define ADD_SHIP_SYSTEM_TWEAK_MEMBER(COMPONENT, SUBSYSTEM) \
      ADD_BOOL_TWEAK(tr("tweak-text", "Hackable"), COMPONENT, SUBSYSTEM.can_be_hacked); \
      ADD_VALUE_MAX_TWEAK(tr("tweak-text", "Health current/max:"), COMPONENT, SUBSYSTEM.health, SUBSYSTEM.health_max); \
      ADD_NUM_SLIDER_TWEAK(tr("tweak-text", "Heat:"), COMPONENT, 0.0f, 1.0f, SUBSYSTEM.heat_level); \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Energy rate factor:"), COMPONENT, SUBSYSTEM.power_factor); \
      { \
          auto row = new GuiElement(new_page->tweaks, ""); \
          row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
          (new GuiLabel(row, "", tr("tweak-text", "Value x power level x 0.08 = energy drained/sec"), 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
      } \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Heat added/sec:"), COMPONENT, SUBSYSTEM.heat_add_rate_per_second); \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Coolant change/sec:"), COMPONENT, SUBSYSTEM.coolant_change_rate_per_second); \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Power change/sec:"), COMPONENT, SUBSYSTEM.power_change_rate_per_second); \
      ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Auto repair/sec:"), COMPONENT, SUBSYSTEM.auto_repair_per_second);
// Select an entity from a list of extant entities as the value of a component
// property.
#define ADD_ENTITY_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiEntityPicker(row, "ENTITY_PICKER", [this](int index, string value) { \
            if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = value.empty() ? sp::ecs::Entity() : sp::ecs::Entity::fromString(value); \
        }); \
        ui->update_func = [this, ui]() -> sp::ecs::Entity { \
            if (auto v = entity.getComponent<COMPONENT>()) return v->VALUE; \
            int idx = ui->getSelectionIndex(); \
            if (idx < 0) return sp::ecs::Entity(); \
            string val = ui->getEntryValue(idx); \
            return val.empty() ? sp::ecs::Entity() : sp::ecs::Entity::fromString(val); \
        }; \
        new_page->apply_functions.push_back([this, ui]() { \
            int idx = ui->getSelectionIndex(); \
            if (idx >= 0) { \
                string val = ui->getEntryValue(idx); \
                if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = val.empty() ? sp::ecs::Entity() : sp::ecs::Entity::fromString(val); \
            } \
        }); \
    } while(0)
// Select an entity from a list of extant Database entities as the parent value
// of an entity with the Database component.
#define ADD_DATABASE_PARENT_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiDatabaseParentPicker(row, "DATABASE_PARENT_PICKER", [this](int index, string value) { \
            if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = value.empty() ? sp::ecs::Entity() : sp::ecs::Entity::fromString(value); \
        }); \
        ui->update_func = [this, ui]() -> sp::ecs::Entity { \
            if (auto v = entity.getComponent<COMPONENT>()) return v->VALUE; \
            int idx = ui->getSelectionIndex(); \
            if (idx < 0) return sp::ecs::Entity(); \
            string val = ui->getEntryValue(idx); \
            return val.empty() ? sp::ecs::Entity() : sp::ecs::Entity::fromString(val); \
        }; \
        new_page->apply_functions.push_back([this, ui]() { \
            int idx = ui->getSelectionIndex(); \
            if (idx >= 0) { \
                string val = ui->getEntryValue(idx); \
                if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = val.empty() ? sp::ecs::Entity() : sp::ecs::Entity::fromString(val); \
            } \
        }); \
    } while(0)
// Add fields to tweak a float X/Y-coordinate value for the given component.
#define ADD_VEC2_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiVec2Tweak(row); \
        ui->update_func = [this, ui]() -> glm::vec2 { \
            if (auto v = entity.getComponent<COMPONENT>()) return v->VALUE; \
            return glm::vec2(ui->x_input->getText().toFloat(), ui->y_input->getText().toFloat()); \
        }; \
        ui->callback = [this](glm::vec2 val) { \
            if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = val; \
        }; \
        new_page->apply_functions.push_back([this, ui]() { \
            string x_text = ui->x_input->getText(); \
            string y_text = ui->y_input->getText(); \
            if (!x_text.empty() || !y_text.empty()) { \
                if (auto v = entity.getComponent<COMPONENT>()) { \
                    glm::vec2 val = v->VALUE; \
                    if (!x_text.empty()) val.x = x_text.toFloat(); \
                    if (!y_text.empty()) val.y = y_text.toFloat(); \
                    v->VALUE = val; \
                } \
            } \
        }); \
    } while(0)
// Add fields to tweak a float value and its corresponding maximum value.
#define ADD_VALUE_MAX_TWEAK(LABEL, COMPONENT, VALUE, MAX_VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiValueMaxTweak(row); \
        ui->val_update_func = [this, ui]() -> float { if (auto v = entity.getComponent<COMPONENT>()) return static_cast<float>(v->VALUE); return ui->val_input->getText().toFloat(); }; \
        ui->max_update_func = [this, ui]() -> float { if (auto v = entity.getComponent<COMPONENT>()) return static_cast<float>(v->MAX_VALUE); return ui->max_input->getText().toFloat(); }; \
        ui->val_callback = [this](float val) { if (auto v = entity.getComponent<COMPONENT>()) { val = std::min(val, static_cast<float>(v->MAX_VALUE)); v->VALUE = static_cast<std::remove_reference_t<decltype(v->VALUE)>>(val); } }; \
        ui->max_callback = [this](float val) { if (auto v = entity.getComponent<COMPONENT>()) v->MAX_VALUE = static_cast<std::remove_reference_t<decltype(v->MAX_VALUE)>>(val); }; \
        new_page->apply_functions.push_back([this, ui]() { \
            string val_text = ui->val_input->getText(); \
            string max_text = ui->max_input->getText(); \
            if (auto v = entity.getComponent<COMPONENT>()) { \
                if (!max_text.empty()) v->MAX_VALUE = static_cast<std::remove_reference_t<decltype(v->MAX_VALUE)>>(max_text.toFloat()); \
                if (!val_text.empty()) { float capped = std::min(val_text.toFloat(), static_cast<float>(v->MAX_VALUE)); v->VALUE = static_cast<std::remove_reference_t<decltype(v->VALUE)>>(capped); } \
            } \
        }); \
    } while(0)
// Add field a field to tweak the integer value of the given missile type array
// index for the given component.
#define ADD_MISSILE_ARRAY_TWEAK(LABEL, COMPONENT, ARRAY, INDEX) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiTextTweak(row); \
        ui->update_func = [this]() -> string { if (auto v = entity.getComponent<COMPONENT>()) return string(v->ARRAY[INDEX]); return ""; }; \
        ui->callback([this](string text) { if (auto v = entity.getComponent<COMPONENT>()) v->ARRAY[INDEX] = text.toInt(); }); \
    } while(0)
// Add fields to tweak an integer X/Y-coordinate value for the given component.
#define ADD_IVEC2_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiVec2Tweak(row); \
        ui->update_func = [this, ui]() -> glm::vec2 { \
            if (auto v = entity.getComponent<COMPONENT>()) return glm::vec2(v->VALUE); \
            return glm::vec2(ui->x_input->getText().toFloat(), ui->y_input->getText().toFloat()); \
        }; \
        ui->callback = [this](glm::vec2 val) { \
            if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = glm::ivec2(val); \
        }; \
        new_page->apply_functions.push_back([this, ui]() { \
            string x_text = ui->x_input->getText(); \
            string y_text = ui->y_input->getText(); \
            if (!x_text.empty() || !y_text.empty()) { \
                if (auto v = entity.getComponent<COMPONENT>()) { \
                    glm::ivec2 val = v->VALUE; \
                    if (!x_text.empty()) val.x = static_cast<int>(x_text.toFloat()); \
                    if (!y_text.empty()) val.y = static_cast<int>(y_text.toFloat()); \
                    v->VALUE = val; \
                } \
            } \
        }); \
    } while(0)
// Add sliders and text fields to tweak an RGBA color value for a component.
#define ADD_COLOR_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 150.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiColorPicker(row); \
        ui->update_func = [this, ui]() -> glm::u8vec4 { \
            if (auto v = entity.getComponent<COMPONENT>()) return v->VALUE; \
            return glm::u8vec4( \
                static_cast<uint8_t>(ui->r_slider->getValue()), \
                static_cast<uint8_t>(ui->g_slider->getValue()), \
                static_cast<uint8_t>(ui->b_slider->getValue()), \
                static_cast<uint8_t>(ui->a_slider->getValue())); \
        }; \
        ui->callback = [this](glm::u8vec4 val) { \
            if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = val; \
        }; \
        new_page->apply_functions.push_back([this, ui]() { \
            if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = glm::u8vec4( \
                static_cast<uint8_t>(ui->r_slider->getValue()), \
                static_cast<uint8_t>(ui->g_slider->getValue()), \
                static_cast<uint8_t>(ui->b_slider->getValue()), \
                static_cast<uint8_t>(ui->a_slider->getValue())); \
        }); \
    } while(0)
// Add sliders and text fields to tweak an RGB (no alpha) color value for a
// component.
#define ADD_VEC3_COLOR_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 120.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiColorPicker(row, false); \
        ui->update_func = [this, ui]() -> glm::u8vec4 { \
            auto v = entity.getComponent<COMPONENT>(); \
            glm::vec3 color = v ? v->VALUE : glm::vec3(ui->r_slider->getValue() / 255.0f, ui->g_slider->getValue() / 255.0f, ui->b_slider->getValue() / 255.0f); \
            return glm::u8vec4(static_cast<uint8_t>(color.r * 255.0f), static_cast<uint8_t>(color.g * 255.0f), static_cast<uint8_t>(color.b * 255.0f), 255); \
        }; \
        ui->callback = [this](glm::u8vec4 val) { \
            if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = glm::vec3(val.r / 255.0f, val.g / 255.0f, val.b / 255.0f); \
        }; \
        new_page->apply_functions.push_back([this, ui]() { \
            if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = glm::vec3(ui->r_slider->getValue() / 255.0f, ui->g_slider->getValue() / 255.0f, ui->b_slider->getValue() / 255.0f); \
        }); \
    } while(0)
// Add a scrolling text area to review the contents of a multiline text field.
// TODO: Implement a multiline text editing GUI subclass to make this editable.
#define ADD_TEXT_MULTILINE_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 150.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiMultilineTextTweak(row, 5); \
        ui->update_func = [this, ui]() -> string { \
            if (auto v = entity.getComponent<COMPONENT>()) return v->VALUE; \
            return ui->getText(); \
        }; \
    } while(0)
// Add a selector to tweak a faction-related value for a component.
#define ADD_FACTION_SELECTOR_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiFactionSelectorTweak(row, "FACTION_SELECTOR", [this](int index, string value) { \
            if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = value.empty() ? sp::ecs::Entity() : sp::ecs::Entity::fromString(value); \
        }); \
        ui->update_func = [this, ui]() -> sp::ecs::Entity { \
            if (auto v = entity.getComponent<COMPONENT>()) return v->VALUE; \
            int idx = ui->getSelectionIndex(); \
            if (idx < 0) return sp::ecs::Entity(); \
            string val = ui->getEntryValue(idx); \
            return val.empty() ? sp::ecs::Entity() : sp::ecs::Entity::fromString(val); \
        }; \
        new_page->apply_functions.push_back([this, ui]() { \
            int idx = ui->getSelectionIndex(); \
            if (idx >= 0) { \
                string val = ui->getEntryValue(idx); \
                if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = val.empty() ? sp::ecs::Entity() : sp::ecs::Entity::fromString(val); \
            } \
        }); \
    } while(0)
// Add a selector to tweak an enumerated value for a component.
#define ADD_ENUM_TWEAK(LABEL, COMPONENT, VALUE, MIN_VALUE, MAX_VALUE, STRING_CONVERT_FUNCTION) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 30.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiSelectorTweak(row, "ENUM_SELECTOR", [this](int index, string value) { \
            if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = static_cast<decltype(v->VALUE)>(index + MIN_VALUE); \
        }); \
        for (int enum_value = MIN_VALUE; enum_value <= MAX_VALUE; enum_value++) \
            ui->addEntry(STRING_CONVERT_FUNCTION(static_cast<decltype(COMPONENT{}.VALUE)>(enum_value)), string(enum_value)); \
        ui->update_func = [this, ui]() -> int { \
            if (auto v = entity.getComponent<COMPONENT>()) return static_cast<int>(v->VALUE) - static_cast<int>(MIN_VALUE); \
            return ui->getSelectionIndex(); \
        }; \
        new_page->apply_functions.push_back([this, ui]() { \
            int idx = ui->getSelectionIndex(); \
            if (idx >= 0) { \
                if (auto v = entity.getComponent<COMPONENT>()) v->VALUE = static_cast<decltype(v->VALUE)>(idx + MIN_VALUE); \
            } \
        }); \
    } while(0)
// Add a selector to add or remove string values from an unordered set in a
// component.
#define ADD_STRING_SET_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 150.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiStringSetTweak(row); \
        ui->update_func = [this]() -> std::unordered_set<string> { \
            if (auto v = entity.getComponent<COMPONENT>()) return v->VALUE; \
            return {}; \
        }; \
        ui->on_add = [this](const string& item) { \
            if (auto v = entity.getComponent<COMPONENT>()) { \
                v->VALUE.insert(item); \
                v->VALUE##_dirty = true; \
            } \
        }; \
        ui->on_remove = [this](const string& item) { \
            if (auto v = entity.getComponent<COMPONENT>()) { \
                v->VALUE.erase(item); \
                v->VALUE##_dirty = true; \
            } \
        }; \
    } while(0)
// Add a selector to add or remove string values from an unordered map in a
// component.
#define ADD_STRING_MAP_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 180.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiStringMapTweak(row); \
        ui->update_func = [this]() -> std::unordered_map<string, string> { \
            if (auto v = entity.getComponent<COMPONENT>()) return v->VALUE; \
            return {}; \
        }; \
        ui->on_add = [this](const string& key, const string& value) { \
            if (auto v = entity.getComponent<COMPONENT>()) { \
                v->VALUE[key] = value; \
            } \
        }; \
        ui->on_remove = [this](const string& key) { \
            if (auto v = entity.getComponent<COMPONENT>()) { \
                v->VALUE.erase(key); \
            } \
        }; \
    } while(0)
// Add fields to tweak a float X/Y-coordinate value of a vector for the given
// component.
#define ADD_VEC2_VECTOR_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 150.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiVec2VectorTweak(row); \
        ui->update_func = [this]() -> std::vector<glm::vec2> { \
            if (auto v = entity.getComponent<COMPONENT>()) return v->VALUE; \
            return {}; \
        }; \
        ui->on_add = [this](const glm::vec2& point) { \
            if (auto v = entity.getComponent<COMPONENT>()) { \
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
// Add fields to add, remove, and tweak key/value fields in a Database entity.
#define ADD_DATABASE_KEYVALUE_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 180.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiDatabaseKeyValueTweak(row); \
        ui->update_func = [this]() -> std::vector<Database::KeyValue> { \
            if (auto v = entity.getComponent<COMPONENT>()) return v->VALUE; \
            return {}; \
        }; \
        ui->on_add = [this](const string& key, const string& value) { \
            if (auto v = entity.getComponent<COMPONENT>()) { \
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
// Add fields to add, remove, and tweak rooms in an InternalRooms entity.
#define ADD_ROOM_VECTOR_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 150.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiRoomVectorTweak(row); \
        ui->update_func = [this]() -> std::vector<InternalRooms::Room> { \
            if (auto v = entity.getComponent<COMPONENT>()) return v->VALUE; \
            return {}; \
        }; \
        ui->on_add = [this](const InternalRooms::Room& room) { \
            if (auto v = entity.getComponent<COMPONENT>()) { \
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

// Add fields to add, remove, and tweak doors in an InternalRooms entity.
#define ADD_DOOR_VECTOR_TWEAK(LABEL, COMPONENT, VALUE) do { \
        auto row = new GuiElement(new_page->tweaks, ""); \
        row->setSize(GuiElement::GuiSizeMax, 120.0f)->setAttribute("layout", "horizontal"); \
        (new GuiLabel(row, "", LABEL, 20.0f))->setAlignment(sp::Alignment::CenterRight)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax); \
        auto ui = new GuiDoorVectorTweak(row); \
        ui->update_func = [this]() -> std::vector<InternalRooms::Door> { \
            if (auto v = entity.getComponent<COMPONENT>()) return v->VALUE; \
            return {}; \
        }; \
        ui->on_add = [this](const InternalRooms::Door& door) { \
            if (auto v = entity.getComponent<COMPONENT>()) { \
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

// END macros for GM tweak UI elements

GuiEntityTweak::GuiEntityTweak(GuiContainer* owner)
: GuiPanel(owner, "GM_TWEAK_DIALOG")
{
    setPosition(0.0f, -100.0f, sp::Alignment::BottomCenter);
    setSize(GuiElement::GuiSizeMax, 700.0f);
    setAttribute("padding", "20");
    setAttribute("margin", "50, 0");

    content = new GuiElement(this, "GM_TWEAK_DIALOG_CONTENT");
    content
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");

    auto left_panel = new GuiElement(content, "");
    left_panel
        ->setSize(300.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    search_filter = new GuiTextEntry(left_panel, "COMPONENT_SEARCH", "");
    search_filter
        ->callback(
            [this](string value)
            {
                if (value.empty())
                {
                    in_search_view = false;
                    showGroups();
                }
                else showSearchResults(value);
            }
        )
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    component_list = new GuiListbox(left_panel, "", [this](int index, string value)
    {
        if (in_search_view)
        {
            if (index >= 0 && index < static_cast<int>(search_result_indices.size()))
            {
                int pi = search_result_indices[index];
                for (auto page : pages) page->hide();
                pages[pi]->show();
                showPageDescription(pi);
            }
        }
        else if (in_group_view)
            showGroupComponents(index);
        else if (index == 0)
            showGroups();
        else
        {
            int pi = component_groups[current_group_index].page_indices[index - 1];
            for (auto page : pages)
                page->hide();
            pages[pi]->show();
            showPageDescription(pi);
        }
    });

    component_list->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    GuiTweakPage* new_page;
    GuiVectorTweak* vector_selector;

    // Transform component, custom implementation since it uses functions
    // instead of direct access to members.
    ADD_PAGE(tr("tweak-tab", "Transform"), sp::Transform);
    new_page->description = tr("tweak-transform", "Sets the entity's position (X, Y) and rotation angle. Position is in game units (1000 = 1U), rotation in degrees (0 = right/east-facing/heading 90).");
    {
        // Position as vec2 widget
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        (new GuiLabel(row, "", tr("tweak-text", "Position:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        auto ui = new GuiVec2Tweak(row);
        ui->update_func = [this, ui]() -> glm::vec2 {
            if (auto t = entity.getComponent<sp::Transform>())
                return t->getPosition();
            // Component doesn't exist - return current widget values to preserve user input
            return glm::vec2(
                ui->x_input->getText().toFloat(),
                ui->y_input->getText().toFloat()
            );
        };
        ui->callback = [this](glm::vec2 value) {
            if (auto t = entity.getComponent<sp::Transform>())
                t->setPosition(value);
        };
        // Register apply function to initialize from UI when component is created
        new_page->apply_functions.push_back([this, ui]() {
            string x_text = ui->x_input->getText();
            string y_text = ui->y_input->getText();
            if (!x_text.empty() || !y_text.empty()) {
                if (auto t = entity.getComponent<sp::Transform>()) {
                    glm::vec2 pos = t->getPosition();
                    if (!x_text.empty()) pos.x = x_text.toFloat();
                    if (!y_text.empty()) pos.y = y_text.toFloat();
                    t->setPosition(pos);
                }
            }
        });
    }
    {
        // Rotation dial
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 60.0f)
            ->setAttribute("layout", "horizontal");
        (new GuiLabel(row, "", tr("tweak-text", "Rotation:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        auto ui = new GuiRotationDialTweak(row);
        ui->update_func = [this, ui]() -> float {
            if (auto t = entity.getComponent<sp::Transform>())
                return t->getRotation();
            return ui->value_entry->getText().toFloat();
        };
        ui->callback = [this](float value) {
            if (auto t = entity.getComponent<sp::Transform>())
                t->setRotation(value);
        };
        new_page->apply_functions.push_back([this, ui]() {
            string rot_text = ui->value_entry->getText();
            if (!rot_text.empty())
            {
                if (auto t = entity.getComponent<sp::Transform>())
                    t->setRotation(rot_text.toFloat());
            }
        });
    }

    // Physics component
    ADD_PAGE(tr("tweak-tab", "Physics"), sp::Physics);
    new_page->description = tr("tweak-physics", "If present, this component subjects this entity to physics interactions. This tweaks panel is incomplete; set properties in Lua scripting.");
    // TODO: Figure out how to set Physics values

    ADD_PAGE(tr("tweak-tab", "Callsign"), CallSign);
    new_page->description = tr("tweak-callsign", "The callsign displayed on radar views and in communications.");
    ADD_TEXT_TWEAK(tr("tweak-text", "Callsign:"), CallSign, callsign);

    ADD_PAGE(tr("tweak-tab", "Type name"), TypeName);
    new_page->description = tr("tweak-typename", "The ship type name used internally by EmptyEpsilon, such as 'Atlantis', and its localized display string for the current locale, which appears in the science database.");
    ADD_TEXT_TWEAK(tr("tweak-text", "Type name:"), TypeName, type_name);
    ADD_TEXT_TWEAK(tr("tweak-text", "Localized:"), TypeName, localized);

    ADD_PAGE(tr("tweak-tab", "Coolant"), Coolant);
    new_page->description = tr("tweak-coolant", "Adds heat accumulation to ship systems possessed by this entity, and a coolant resource to manage it. If this component is absent, this entity's ship systems don't generate heat.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Max:"), Coolant, max);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Max per system:"), Coolant, max_coolant_per_system);
    ADD_BOOL_TWEAK(tr("tweak-text", "Auto levels"), Coolant, auto_levels);

    ADD_PAGE(tr("tweak-tab", "Hull"), Hull);
    new_page->description = tr("tweak-hull", "Structural hit points. If an entity with a hull has zero hull points, its Allow destruction property is enabled, and it takes damage, the entity can be destroyed. Docking to certain entities can restore hull points.");
    ADD_VALUE_MAX_TWEAK(tr("tweak-text", "Hull:"), Hull, current, max);
    ADD_BOOL_TWEAK(tr("tweak-text", "Allow destruction"), Hull, allow_destruction);

    // Custom impulse command control.
    ADD_PAGE(tr("tweak-tab", "Impulse engine"), ImpulseEngine);
    new_page->description = tr("tweak-impulse", "Ship system for impulse propulsion. Controls forward/reverse max speeds and acceleration rates.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Speed forward:"), ImpulseEngine, max_speed_forward);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Speed reverse:"), ImpulseEngine, max_speed_reverse);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Acceleration forward:"), ImpulseEngine, acceleration_forward);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Acceleration reverse:"), ImpulseEngine, acceleration_reverse);
    ADD_LABEL(tr("tweak-text", "Impulse engine system"));
    ADD_SHIP_SYSTEM_TWEAK(ImpulseEngine);
    ADD_LABEL(tr("tweak-text", "Impulse command"));
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        (new GuiLabel(row, "", tr("tweak-text", "Impulse speed:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        auto ui = new GuiSliderTweak(row, "", -1.0f, 1.0f, 0.0f,
            [this](float value)
            {
                if (auto v = entity.getComponent<ImpulseEngine>())
                    v->request = value;
            }
        );
        ui
            ->addSnapValue(-1.0f, 0.1f)
            ->addSnapValue(-0.5f, 0.1f)
            ->addSnapValue(0.0f, 0.1f)
            ->addSnapValue(0.5f, 0.1f)
            ->addSnapValue(1.0f, 0.1f);
        ui->update_func = [this, ui]() -> float {
            if (auto v = entity.getComponent<ImpulseEngine>())
                return v->request;
            return ui->value_entry->getText().toFloat();
        };
    }

    // Custom heading command control, which is distinct from Transform rotation
    // setting.
    ADD_PAGE(tr("tweak-tab", "Maneuvering thrusters"), ManeuveringThrusters);
    new_page->description =  tr("tweak-maneuvering", "Ship system providing rotational thrusters for the ship. Speed is in degrees per second.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Rotational speed:"), ManeuveringThrusters, speed);
    ADD_LABEL(tr("tweak-text", "Maneuvering thrusters system"));
    ADD_SHIP_SYSTEM_TWEAK(ManeuveringThrusters);
    ADD_LABEL(tr("tweak-text", "Heading command"));
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row->setSize(GuiElement::GuiSizeMax, 60.0f)->setAttribute("layout", "horizontal");
        (new GuiLabel(row, "", tr("tweak-text", "Target heading:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        auto ui = new GuiRotationDialTweak(row);
        // Convert player heading (0 = north) to/from internal rotation
        // (0 = east).
        ui->callback = [this](float player_heading) {
            if (auto v = entity.getComponent<ManeuveringThrusters>())
                v->target = fmodf(player_heading - 90.0f + 360.0f, 360.0f);
        };
        ui->update_func = [this, ui]() -> float {
            auto v = entity.getComponent<ManeuveringThrusters>();
            if (v && v->target != std::numeric_limits<float>::min())
                return fmodf(v->target + 90.0f, 360.0f);
            return ui->value_entry->getText().toFloat();
        };
    }

    ADD_PAGE(tr("tweak-tab", "Combat thrusters"), CombatManeuveringThrusters);
    new_page->description =  tr("tweak-combatmaneuvering", "Boost and strafe capability. Charge is consumed on use and recharges over time (charge_time seconds to full). If this entity has the Coolant component, this generates heat in the Maneuvering thrusters system.");
    ADD_NUM_SLIDER_TWEAK(tr("tweak-text", "Charge available:"), CombatManeuveringThrusters, 0.0f, 1.0f, charge);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Seconds to full recharge from 0:"), CombatManeuveringThrusters, charge_time);

    ADD_PAGE(tr("tweak-tab", "Beam system"), BeamWeaponSys);
    new_page->description =  tr("tweak-beam-system", "Ship system providing beam weapon configuration. Beam frequency affects damage against shields.\n\nEach beam weapon has a mount that defines its firing arc, the direction the arc points in, and its range, damage, and cycle time. It also optionally supports functioning as a rotating turret with a defined speed in tracking targets. If a turret arc is defined, the beam direction rotates the beam arc within the larger turret arc and direction. Beam and turret performance are affected by the Beam weapon system, and firing generates additional heat into the system.");
    ADD_INT_SLIDER_TWEAK(tr("tweak-text", "Frequency:"), BeamWeaponSys, 0u, 20u, frequency);
    ADD_LABEL(tr("tweak-text", "Beam weapons system"));
    ADD_SHIP_SYSTEM_TWEAK(BeamWeaponSys);

    ADD_LABEL(tr("tweak-text", "Beam mounts"));
    ADD_VECTOR(tr("tweak-vector", "Mount"), BeamWeaponSys, mounts);
    ADD_VECTOR_NUM_SLIDER_TWEAK(tr("tweak-text", "Beam arc:"), BeamWeaponSys, mounts, 0.0f, 360.0f, arc);
    ADD_VECTOR_ROTATION_TWEAK(tr("tweak-text", "Beam direction:"), BeamWeaponSys, mounts, direction);
    ADD_VECTOR_NUM_TEXT_TWEAK(tr("tweak-text", "Range:"), BeamWeaponSys, mounts, range);
    ADD_VECTOR_NUM_TEXT_TWEAK(tr("tweak-text", "Cycle time:"), BeamWeaponSys, mounts, cycle_time);
    ADD_VECTOR_NUM_TEXT_TWEAK(tr("tweak-text", "Damage:"), BeamWeaponSys, mounts, damage);
    ADD_VECTOR_NUM_SLIDER_TWEAK(tr("tweak-text", "Turret arc:"), BeamWeaponSys, mounts, 0.0f, 360.0f, turret_arc);
    ADD_VECTOR_ROTATION_TWEAK(tr("tweak-text", "Turret direction:"), BeamWeaponSys, mounts, turret_direction);
    ADD_VECTOR_NUM_TEXT_TWEAK(tr("tweak-text", "Turret rotation rate:"), BeamWeaponSys, mounts, turret_rotation_rate);

    ADD_PAGE(tr("tweak-tab", "Missile system"), MissileTubes);
    new_page->description =  tr("tweak-missile-system", "Ship system and storage for missiles and mines. Defines current stock and maximum capacity for each type.\n\nEach missile launch tube has a mount that defines its fire direction, load time, size class, and allowed ammunition types. Performance is affected by, and firing generates heat into, the Missile weapon system.");
    ADD_LABEL(tr("tweak-text", "Weapon stocks"));
    ADD_VALUE_MAX_TWEAK(tr("tweak-text", "Homing:"), MissileTubes, storage[MW_Homing], storage_max[MW_Homing]);
    ADD_VALUE_MAX_TWEAK(tr("tweak-text", "Nuke:"), MissileTubes, storage[MW_Nuke], storage_max[MW_Nuke]);
    ADD_VALUE_MAX_TWEAK(tr("tweak-text", "EMP:"), MissileTubes, storage[MW_EMP], storage_max[MW_EMP]);
    ADD_VALUE_MAX_TWEAK(tr("tweak-text", "HVLI:"), MissileTubes, storage[MW_HVLI], storage_max[MW_HVLI]);
    ADD_VALUE_MAX_TWEAK(tr("tweak-text", "Mines:"), MissileTubes, storage[MW_Mine], storage_max[MW_Mine]);
    ADD_LABEL(tr("tweak-text", "Missile weapons system"));
    ADD_SHIP_SYSTEM_TWEAK(MissileTubes);

    ADD_LABEL(tr("tweak-text", "Weapon tube mounts"));
    ADD_VECTOR(tr("tweak-vector", "Mount"), MissileTubes, mounts);
    ADD_VECTOR_ROTATION_TWEAK(tr("tweak-text", "Direction:"), MissileTubes, mounts, direction);
    ADD_VECTOR_NUM_TEXT_TWEAK(tr("tweak-text", "Load time:"), MissileTubes, mounts, load_time);
    ADD_VECTOR_ENUM_TWEAK(tr("tweak-text", "Size:"), MissileTubes, mounts, size, MS_Small, MS_Large, getMissileSizeString);
    ADD_VECTOR_TOGGLE_MASK_TWEAK(tr("tweak-text", "Allow homing"), MissileTubes, mounts, type_allowed_mask, 1 << MW_Homing);
    ADD_VECTOR_TOGGLE_MASK_TWEAK(tr("tweak-text", "Allow nuke"), MissileTubes, mounts, type_allowed_mask, 1 << MW_Nuke);
    ADD_VECTOR_TOGGLE_MASK_TWEAK(tr("tweak-text", "Allow mine"), MissileTubes, mounts, type_allowed_mask, 1 << MW_Mine);
    ADD_VECTOR_TOGGLE_MASK_TWEAK(tr("tweak-text", "Allow EMP"), MissileTubes, mounts, type_allowed_mask, 1 << MW_EMP);
    ADD_VECTOR_TOGGLE_MASK_TWEAK(tr("tweak-text", "Allow HVLI"), MissileTubes, mounts, type_allowed_mask, 1 << MW_HVLI);

    ADD_PAGE(tr("tweak-tab", "Shields"), Shields);
    new_page->description = tr("tweak-shields", "Shield generators, including active state, frequency, calibration time, and additional energy cost beyond ship system usage while activated. Ships can have a variable number of segments with equal arcs, and ships with 2 or more segments have separate front and rear shield ship systems.");
    ADD_LABEL(tr("tweak-text", "Front shield system"));
    ADD_SHIP_SYSTEM_TWEAK_MEMBER(Shields, front_system);
    ADD_LABEL(tr("tweak-text", "Rear shield system (2+ segments only)"));
    ADD_SHIP_SYSTEM_TWEAK_MEMBER(Shields, rear_system);
    ADD_BOOL_TWEAK(tr("tweak-text", "Active"), Shields, active);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Seconds to recalibrate:"), Shields, calibration_time);
    ADD_INT_SLIDER_TWEAK(tr("tweak-text", "Frequency:"), Shields, 0u, 20u, frequency);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Energy use/sec:"), Shields, energy_use_per_second);
    ADD_VECTOR(tr("tweak-vector", "Shield segments"), Shields, entries);
    ADD_VECTOR_VALUE_MAX_TWEAK(tr("tweak-text", "Level current/max:"), Shields, entries, level, max);

    // Custom controls for warp drive tweaks.
    ADD_PAGE(tr("tweak-tab", "Warp drive"), WarpDrive);
    new_page->description = tr("tweak-warp", "Ship system for the warp propulsion drive. Maximum level sets the highest available warp factor, with 0-max selectable as integer factors. Energy consumption while active is in addition to ship system energy consumption. Warp usage also generates heat while active.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Maximum level:"), WarpDrive, max_level);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Speed/level:"), WarpDrive, speed_per_level);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Energy consumed per level/sec:"), WarpDrive, energy_warp_per_second);
    ADD_LABEL(tr("tweak-text", "Warp drive system"));
    ADD_SHIP_SYSTEM_TWEAK(WarpDrive);
    ADD_LABEL(tr("tweak-text", "Warp commands"));
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "", tr("tweak-text", "Warp factor:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        auto ui = new GuiSliderTweak(row, "", 0, 4, 0,
            [this](float value)
            {
                if (auto v = entity.getComponent<WarpDrive>())
                    v->request = static_cast<int>(value);
            }
        );

        for (int i = 0; i <= 4; i++)
            ui->addSnapValue(static_cast<float>(i), 0.5f);

        ui->addOverlay(0u, 20.0f);
        ui->update_func = [this, ui]() -> float {
            if (auto v = entity.getComponent<WarpDrive>())
                return static_cast<float>(v->request);
            return ui->value_entry->getText().toFloat();
        };
    }

    // Custom controls for jump drive tweaks.
    ADD_PAGE(tr("tweak-tab", "Jump drive"), JumpDrive);
    new_page->description = tr("tweak-jump", "Ship system for the jump propulsion drive. Minimum and maximum distance values define the available range in the jump drive controls.");
    ADD_VALUE_MAX_TWEAK(tr("tweak-text", "Distance min/max:"), JumpDrive, min_distance, max_distance);
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        (new GuiLabel(row, "", tr("tweak-text", "Charge:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        auto ui = new GuiSliderTweak(row, "", 5000.0f, 50000.0f, 0.0f,
            [this](float value)
            {
                if (auto v = entity.getComponent<JumpDrive>())
                    v->charge = value;
            }
        );
        ui->addOverlay(0u, 20.0f);
        ui->update_func = [this, ui]() -> float {
            // Update slider range based on component's min/max distance
            if (auto v = entity.getComponent<JumpDrive>())
            {
                ui->slider->setRange(0.0f, v->max_distance);
                return v->charge;
            }

            return ui->value_entry->getText().toFloat();
        };
        new_page->apply_functions.push_back(
            [this, ui]()
            {
                string text = ui->value_entry->getText();
                if (!text.empty())
                {
                    if (auto v = entity.getComponent<JumpDrive>())
                        v->charge = text.toFloat();
                }
            }
        );
    }
    ADD_LABEL(tr("tweak-text", "Jump drive system"));
    ADD_SHIP_SYSTEM_TWEAK(JumpDrive);
    ADD_LABEL(tr("tweak-text", "Jump commands"));
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "", tr("tweak-text", "Jump distance:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        auto ui = new GuiSliderTweak(row, "", 5000.0f, 50000.0f, 0.0f, [this](float value)
        {
            if (auto v = entity.getComponent<JumpDrive>())
                v->distance = value;
        });
        ui->addOverlay(0u, 20.0f);
        ui->update_func = [this, ui]() -> float {
            // Update slider range based on component's min/max distance
            if (auto v = entity.getComponent<JumpDrive>())
            {
                ui->slider->setRange(v->min_distance, v->max_distance);
                return v->distance;
            }

            return ui->value_entry->getText().toFloat();
        };
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "", tr("tweak-text", "Seconds to jump:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        new GuiJumpCountdownDisplay(row, entity);
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiButton(row, "", tr("tweak-button", "Initiate jump"), [this]()
        {
            if (auto v = entity.getComponent<JumpDrive>())
                v->delay = v->activation_delay;
        }))
            ->setTextSize(20.0f)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        (new GuiButton(row, "", tr("tweak-button", "Abort jump"), [this]()
        {
            if (auto v = entity.getComponent<JumpDrive>())
                v->delay = 0.0f;
        }))
            ->setTextSize(20.0f)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    }

    // AI Controller component removal is disabled due to unique_ptr<ShipAI>
    // destruction issues that cause compilation issues due to incomplete type.
    // Use scripts to remove AI component.
    // TODO: Surface this better in the UI.
    new_page = new GuiTweakPage(content);
    new_page->has_component = [](sp::ecs::Entity e) { return e.hasComponent<AIController>(); };
    new_page->add_component = [](sp::ecs::Entity e) { e.addComponent<AIController>(); };
    new_page->remove_component = [](sp::ecs::Entity e) {
        LOG(Warning, "AIController component removal not supported via Tweaks dialog");
    };
    pages.push_back(new_page);
    page_labels.push_back(tr("tweak-tab", "AI controller"));
    new_page->description = tr("tweak-ai", "Autonomous ship behavior. Set orders (attack, defend, dock, etc.), target entity, and target location for AI control. This component cannot be removed from an entity using the tweaks menu.");

    ADD_ENUM_TWEAK(tr("tweak-text", "Orders:"), AIController, orders,
        static_cast<int>(AIOrder::Idle), static_cast<int>(AIOrder::Attack), getAIOrderString);
    ADD_VEC2_TWEAK(tr("tweak-text", "Order target location:"), AIController, order_target_location);
    ADD_ENTITY_TWEAK(tr("tweak-text", "Order target:"), AIController, order_target);
    // ADD_TEXT_TWEAK(tr("tweak-text", "AI name:"), AIController, new_name);

    // Orbit component overrides position/propulsion controls.
    ADD_PAGE(tr("tweak-tab", "Orbit"), Orbit);
    new_page->description = tr("tweak-orbit", "Defines simple orbital movement by this entity around another entity (orbit target) or specified coordinates (orbit coordinates) at a defined distance and period.");
    ADD_ENTITY_TWEAK(tr("tweak-text", "Orbit center target:"), Orbit, target);
    ADD_VEC2_TWEAK(tr("tweak-text", "Orbit center coordinates:"), Orbit, center);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Orbit distance:"), Orbit, distance);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Orbit period (seconds):"), Orbit, time);

    // Redundant with GM screen faction selector, but this allows addition/removal
    // of the component itself.
    ADD_PAGE(tr("tweak-tab", "Faction"), Faction);
    new_page->description = tr("tweak-faction", "The faction to which this entity belongs. Determines which entities are friendly, neutral, or hostile in combat and interactions. This can also be set using the faction selector at the top left of the GM screen.");
    ADD_FACTION_SELECTOR_TWEAK(tr("tweak-text", "Faction:"), Faction, entity);

    // Spin component overrides other rotation controls.
    ADD_PAGE(tr("tweak-tab", "Spin"), Spin);
    new_page->description = tr("tweak-spin", "Makes the entity rotate continuously at the given rate in degrees per second. Useful for terrain and decorative objects, such as asteroids and debris. Ships should use the Manuvering thrusters component instead.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Rotation rate (degrees/second):"), Spin, rate);

    ADD_PAGE(tr("tweak-tab", "Life time"), LifeTime);
    new_page->description = tr("tweak-lifetime", "Defines a time-limited existence for this entity, and automatically destroys it when the remaining lifetime in seconds expires.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Remaining lifetime (seconds):"), LifeTime, lifetime);

    ADD_PAGE(tr("tweak-tab", "Warp jammer"), WarpJammer);
    new_page->description = tr("tweak-warp-jammer", "Creates an area in which where warp and jump drives cannot be activated. Useful for trapping or containing ships.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Jamming range:"), WarpJammer, range);

    // TODO: Add a custom interface to draw zones on the map.
    ADD_PAGE(tr("tweak-tab", "Zone"), Zone);
    new_page->description = tr("tweak-zone", "A named region, typically visible on radars as a colored region with a label. Can optionally change the skybox while within the zone, with an optional transition border. Scripts can determine whether an entity is within a Zone. Used for mission areas, hazard zones, map regions, and special effects.");
    ADD_COLOR_TWEAK(tr("tweak-text", "Zone color:"), Zone, color);
    ADD_TEXT_TWEAK(tr("tweak-text", "Label:"), Zone, label);
    ADD_VEC2_TWEAK(tr("tweak-text", "Label offset:"), Zone, label_offset);
    ADD_TEXT_TWEAK(tr("tweak-text", "Skybox:"), Zone, skybox);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Skybox fade distance:"), Zone, skybox_fade_distance);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Radius:"), Zone, radius);
    ADD_VEC2_VECTOR_TWEAK(tr("tweak-text", "Outline points:"), Zone, outline);

    // Database component adds entries to the science database. Designed for
    // entities that aren't selectable on the map, but can be applied to them.
    // See GuiDatabaseParentPicker for an interface to select these entities.
    ADD_PAGE(tr("tweak-tab", "Database"), Database);
    new_page->description = tr("tweak-database", "Science database entry for this entity. Defines the name, description, key-value data pairs, and image shown on the Science, Operations, and Database screens. To modify the main Science database entries, which aren't selectable on the map, use the Databse button on the GM screen.");
    ADD_DATABASE_PARENT_TWEAK(tr("tweak-text", "Parent entry:"), Database, parent);
    ADD_TEXT_TWEAK(tr("tweak-text", "Name:"), Database, name);
    ADD_DATABASE_KEYVALUE_TWEAK(tr("tweak-text", "Key-value pairs:"), Database, key_values);
    // TODO: Replace with multiline text editor widget - single-line field can't handle linebreaks properly
    ADD_TEXT_TWEAK(tr("tweak-text", "Description:"), Database, description);
    ADD_TEXT_TWEAK(tr("tweak-text", "Image:"), Database, image);

    ADD_PAGE(tr("tweak-tab", "Move to"), MoveTo);
    new_page->description = tr("tweak-moveto", "Moves the entity to the target location in a straight line at a fixed rate of speed. Used by default for probes instead of propulsion. Ships should use the Impulse engine component instead.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Speed:"), MoveTo, speed);
    ADD_VEC2_TWEAK(tr("tweak-text", "Target position:"), MoveTo, target);

    ADD_PAGE(tr("tweak-tab", "Avoid object"), AvoidObject);
    new_page->description = tr("tweak-avoid-object", "Marks this entity as an obstacle for AI pathfinding. Ships with AI will route around entities with this component using the given range.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Avoidance range:"), AvoidObject, range);

    ADD_PAGE(tr("tweak-tab", "Delayed avoid object"), DelayedAvoidObject);
    new_page->description = tr("tweak-delayed-avoid-object", "Pathfinding obstacle with an activation delay period. Ships pass through this area until the activation delay countdown expires, then avoid it using the given range.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Activation delay (seconds):"), DelayedAvoidObject, delay);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Avoidance range:"), DelayedAvoidObject, range);

    ADD_PAGE(tr("tweak-tab", "Target"), Target);
    new_page->description = tr("tweak-target", "The entity targeted by this entity's weapons (beam/missile) or AI orders.");
    ADD_ENTITY_TWEAK(tr("tweak-text", "Target entity:"), Target, entity);

    /* Sfx component, plays a sound effect once
       Unclear how to get this to work, since the sound plays immediately after
       being added and toggling the played property doesn't seem to replay it.
    ADD_PAGE(tr("tweak-tab", "Sound effect"), Sfx);
    ADD_TEXT_TWEAK(tr("tweak-text", "Sound file:"), Sfx, sound);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Volume:"), Sfx, volume);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Pitch:"), Sfx, pitch);
    ADD_BOOL_TWEAK(tr("tweak-text", "Played"), Sfx, played);
    */

    ADD_PAGE(tr("tweak-tab", "Internal rooms"), InternalRooms);
    new_page->description = tr("tweak-missile-internalrooms", "Defines the ship's interior room layout, assigned ship systems for repair, and door positions. Coordinates are from the top-left, and rooms are sized from the top-left point of the room, where 1 unit = the size of 1 repair crew.");
    ADD_BOOL_TWEAK(tr("tweak-text", "Auto repair"), InternalRooms, auto_repair_enabled);
    ADD_ROOM_VECTOR_TWEAK(tr("tweak-text", "Rooms:"), InternalRooms, rooms);
    ADD_DOOR_VECTOR_TWEAK(tr("tweak-text", "Doors:"), InternalRooms, doors);

    ADD_PAGE(tr("tweak-tab", "Internal repair crew"), InternalRepairCrew);
    new_page->description = tr("tweak-internalrepaircrew", "Sets the repair and unhack rates for interior repair crew. Affects how quickly damage is repaired per second when a repair crew is in an Internal room for that system.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Repair per second:"), InternalRepairCrew, repair_per_second);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Unhack per second:"), InternalRepairCrew, unhack_per_second);

    /* TODO: InternalCrew component disabled. Adding it via GM Tweaks destroys the entity.
       Needs a different approach before re-enabling.

    ADD_PAGE(tr("tweak-tab", "Internal crew"), InternalCrew);
    ADD_ENTITY_TWEAK(tr("tweak-text", "Ship:"), InternalCrew, ship);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Move speed:"), InternalCrew, move_speed);
    ADD_VEC2_TWEAK(tr("tweak-text", "Position:"), InternalCrew, position);
    ADD_IVEC2_TWEAK(tr("tweak-text", "Target position:"), InternalCrew, target_position);
    */
    
    ADD_PAGE(tr("tweak-tab", "Pickup"), PickupCallback);
    new_page->description = tr("tweak-pickup", "If present, this component makes this entity collectible by other entities. Can grant energy, missiles, or other resources to an entity that touches it, then immediately destroys itself. Can be set to be picked up only by player ships.");
    ADD_BOOL_TWEAK(tr("tweak-text", "Only players can pickup"), PickupCallback, player);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Give energy:"), PickupCallback, give_energy);
    ADD_MISSILE_ARRAY_TWEAK(tr("tweak-text", "Give homing:"), PickupCallback, give_missile, MW_Homing);
    ADD_MISSILE_ARRAY_TWEAK(tr("tweak-text", "Give nuke:"), PickupCallback, give_missile, MW_Nuke);
    ADD_MISSILE_ARRAY_TWEAK(tr("tweak-text", "Give mine:"), PickupCallback, give_missile, MW_Mine);
    ADD_MISSILE_ARRAY_TWEAK(tr("tweak-text", "Give EMP:"), PickupCallback, give_missile, MW_EMP);
    ADD_MISSILE_ARRAY_TWEAK(tr("tweak-text", "Give HVLI:"), PickupCallback, give_missile, MW_HVLI);

    ADD_PAGE(tr("tweak-tab", "Collision callback"), CollisionCallback);
    new_page->description = tr("tweak-collision-callback", "Triggers a Lua script callback when another entity touches this one. Callback must be set through Lua scripting. Optionally restricted to player-ship collisions only.");
    ADD_BOOL_TWEAK(tr("tweak-text", "Execute only if players collide"), CollisionCallback, player);

    ADD_PAGE(tr("tweak-tab", "Docking bay"), DockingBay);
    new_page->description = tr("tweak-docking-bay", "Allows ships to dock at this entity. Configures ship classes and services (energy transfer, repair, shields, probe restocking, AI ship missile restocking).");
    ADD_STRING_SET_TWEAK(tr("tweak-text", "External dock classes:"), DockingBay, external_dock_classes);
    ADD_STRING_SET_TWEAK(tr("tweak-text", "Internal dock classes:"), DockingBay, internal_dock_classes);
    ADD_LABEL(tr("tweak-text", "Docking bay services"));
    // DockingBay flags, custom toggle tweaks for bitfield
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        auto ui = new GuiToggleTweak(row, tr("tweak-text", "Share energy"),
            [this](bool value)
            {
                if (auto v = entity.getComponent<DockingBay>())
                {
                    if (value) v->flags |= DockingBay::ShareEnergy;
                    else v->flags &= ~DockingBay::ShareEnergy;
                }
            }
        );
        ui->update_func = [this]() -> bool {
            auto v = entity.getComponent<DockingBay>();
            return v && (v->flags & DockingBay::ShareEnergy);
        };
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        auto ui = new GuiToggleTweak(row, tr("tweak-text", "Repair hull"),
            [this](bool value)
            {
                if (auto v = entity.getComponent<DockingBay>())
                {
                    if (value) v->flags |= DockingBay::Repair;
                    else v->flags &= ~DockingBay::Repair;
                }
            }
        );
        ui->update_func = [this]() -> bool {
            auto v = entity.getComponent<DockingBay>();
            return v && (v->flags & DockingBay::Repair);
        };
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        auto ui = new GuiToggleTweak(row, tr("tweak-text", "Charge shields"),
            [this](bool value)
            {
                if (auto v = entity.getComponent<DockingBay>())
                {
                    if (value) v->flags |= DockingBay::ChargeShield;
                    else v->flags &= ~DockingBay::ChargeShield;
                }
            }
        );
        ui->update_func = [this]() -> bool {
            auto v = entity.getComponent<DockingBay>();
            return v && (v->flags & DockingBay::ChargeShield);
        };
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        auto ui = new GuiToggleTweak(row, tr("tweak-text", "Restock probes"),
            [this](bool value)
            {
                if (auto v = entity.getComponent<DockingBay>())
                {
                    if (value) v->flags |= DockingBay::RestockProbes;
                    else v->flags &= ~DockingBay::RestockProbes;
                }
            }
        );
        ui->update_func = [this]() -> bool {
            auto v = entity.getComponent<DockingBay>();
            return v && (v->flags & DockingBay::RestockProbes);
        };
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        auto ui = new GuiToggleTweak(row, tr("tweak-text", "Restock missiles (AI only)"),
            [this](bool value)
            {
                if (auto v = entity.getComponent<DockingBay>())
                {
                    if (value) v->flags |= DockingBay::RestockMissiles;
                    else v->flags &= ~DockingBay::RestockMissiles;
                }
            }
        );
        ui->update_func = [this]() -> bool {
            auto v = entity.getComponent<DockingBay>();
            return v && (v->flags & DockingBay::RestockMissiles);
        };
    }

    ADD_PAGE(tr("tweak-tab", "Docking port"), DockingPort);
    new_page->description = tr("tweak-docking-port", "Allows this entity to dock with an entity possessing a Docking bay component. Tracks current docking state, target, and optional missile auto-reload.");
    ADD_TEXT_TWEAK(tr("tweak-text", "Dock class:"), DockingPort, dock_class);
    ADD_TEXT_TWEAK(tr("tweak-text", "Dock subclass:"), DockingPort, dock_subclass);
    ADD_ENUM_TWEAK(tr("tweak-text", "Docking state:"), DockingPort, state,
        static_cast<int>(DockingPort::State::NotDocking),
        static_cast<int>(DockingPort::State::Docked), getDockingStateString);
    ADD_ENTITY_TWEAK(tr("tweak-text", "Dock target:"), DockingPort, target);
    ADD_VEC2_TWEAK(tr("tweak-text", "Docked offset:"), DockingPort, docked_offset);
    ADD_BOOL_TWEAK(tr("tweak-text", "Auto reload missiles"), DockingPort, auto_reload_missiles);
    ADD_VALUE_MAX_TWEAK(tr("tweak-text", "Reload timer:"), DockingPort, auto_reload_missile_delay, auto_reload_missile_time);

    ADD_PAGE(tr("tweak-tab", "Player controller"), PlayerControl);
    new_page->description = tr("tweak-player-controller", "If present, this component enables player control of this entity. Entities with this component appear as selectable ships on the ship selection screen. Sets available crew positions, control code, main screen display, and alert level.");
    ADD_TEXT_TWEAK(tr("tweak-text", "Control code:"), PlayerControl, control_code);
    ADD_ENUM_TWEAK(tr("tweak-text", "Main screen:"), PlayerControl, main_screen_setting, 0, 6, mainScreenSettingToLocaleString);
    ADD_ENUM_TWEAK(tr("tweak-text", "Main screen overlay:"), PlayerControl, main_screen_overlay, 0, 1, mainScreenOverlayToLocaleString);
    ADD_ENUM_TWEAK(tr("tweak-text", "Alert level:"), PlayerControl, alert_level, 0, 2, alertLevelToLocaleString);
    ADD_LABEL(tr("tweak-text", "Allowed crew positions"));
    for (int i = 0; i < static_cast<int>(CrewPosition::MAX); i++)
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        auto ui = new GuiToggleTweak(row, crewPositionToString(CrewPosition(i)),
            [this, i](bool value)
            {
                if (auto v = entity.getComponent<PlayerControl>())
                {
                    if (value) v->allowed_positions.add(CrewPosition(i));
                    else v->allowed_positions.remove(CrewPosition(i));
                }
            }
        );
        ui->update_func = [this, i]() -> bool {
            auto v = entity.getComponent<PlayerControl>();
            return v && v->allowed_positions.has(CrewPosition(i));
        };
    }

    ADD_PAGE(tr("tweak-tab", "Reactor"), Reactor);
    new_page->description = tr("tweak-reactor", "Ship system that generates and stores energy. Sets energy capacity and current energy level. Reactor system health affects power output, and sufficiently negative health destroys the ship if Explode on overload is set. If this component is absent, ship systems on this ship don't require energy.");
    ADD_VALUE_MAX_TWEAK(tr("tweak-text", "Energy:"), Reactor, energy, max_energy);
    ADD_BOOL_TWEAK(tr("tweak-text", "Explode on overload"), Reactor, overload_explode);
    ADD_LABEL(tr("tweak-text", "Reactor system"));
    ADD_SHIP_SYSTEM_TWEAK(Reactor);

    ADD_PAGE(tr("tweak-tab", "Radar range"), LongRangeRadar);
    new_page->description = tr("tweak-radar", "Sensor detection ranges. Short-range radar for nearby contacts, long-range radar for distant threats on tactical display. If this entity has the Allow radar link or Share short-range radar components, the short-range radar range determines what it shares. If this entity has the AI controller component, the long-range radar range determines the range at which it detects other entities.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Short-range radar range:"), LongRangeRadar, short_range);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Long-range radar range:"), LongRangeRadar, long_range);

    ADD_PAGE(tr("tweak-tab", "Scanner"), ScienceScanner);
    new_page->description = tr("tweak-scanner", "Science scanner for detailed entity analysis. Sets the delay and max delay required for a player to complete a scan when not using the scanning minigame.");
    ADD_VALUE_MAX_TWEAK(tr("tweak-text", "Scan delay:"), ScienceScanner, delay, max_scanning_delay);

    ADD_PAGE(tr("tweak-tab", "Comms receiver"), CommsReceiver);
    new_page->description = tr("tweak-comms-receiver", "Allows this entity to communicate with other ships and stations.");
    ADD_PAGE(tr("tweak-tab", "Comms transmitter"), CommsTransmitter);
    new_page->description = tr("tweak-comms-transmitter", "Allows this entity to communicate with other ships and stations.");

    ADD_PAGE(tr("tweak-tab", "Scan probe launcher"), ScanProbeLauncher);
    new_page->description = tr("tweak-scan-probe-launcher", "If present, this component allows this ship lto launch sensor probes. Sets current and max probe stocks, and recharge and charge time control restocking speed when docked.");
    ADD_VALUE_MAX_TWEAK(tr("tweak-text", "Probes:"), ScanProbeLauncher, stock, max);
    ADD_VALUE_MAX_TWEAK(tr("tweak-text", "Recharge:"), ScanProbeLauncher, recharge, charge_time);

    ADD_PAGE(tr("tweak-tab", "Allow radar link"), AllowRadarLink);
    new_page->description = tr("tweak-radar-link", "Marks this entity as a radar-linked probe. The defined owner entity receives the probe's sensor data, which can be viewed in Probe View on the Science or Operations player screens.");
    ADD_ENTITY_TWEAK(tr("tweak-text", "Owner:"), AllowRadarLink, owner);

    ADD_PAGE(tr("tweak-tab", "Share short-range radar"), ShareShortRangeRadar);
    new_page->description = tr("tweak-share-radar", "Causes this entity to share its short-range radar sensor data with allied entities in sensor range.");

    ADD_PAGE(tr("tweak-tab", "Hacking"), HackingDevice);
    new_page->description = tr("tweak-hacking", "If present, this component enables hacking minigames on the Relay player screen. Defines how effective a successful hacking attempt is at disabling the target ship system.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Effectiveness:"), HackingDevice, effectiveness);

    ADD_PAGE(tr("tweak-tab", "Self-destruct"), SelfDestruct);
    new_page->description = tr("tweak-self-destruct", "If present, this component enables the self-destruct function on player screens. When active, counts down in seconds and then triggers an explosion with configurable blast damage and radius.");
    ADD_BOOL_TWEAK(tr("tweak-text", "Active"), SelfDestruct, active);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Countdown:"), SelfDestruct, countdown);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Blast damage:"), SelfDestruct, damage);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Blast radius:"), SelfDestruct, size);

    ADD_PAGE(tr("tweak-tab", "Radar obstruction"), RadarBlock);
    new_page->description = tr("tweak-radar-block", "If present, this component causes this entity to block radar sensor signals around and behind it over the given radius.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Radius:"), RadarBlock, range);
    ADD_BOOL_TWEAK(tr("tweak-text", "Obstructs radar behind"), RadarBlock, behind);

    ADD_PAGE(tr("tweak-tab", "Gravity"), Gravity);
    new_page->description = tr("tweak-gravity", "Defines this entity's gravitational attraction, which pulls nearby entities toward this one. Can optionally deal damage like a black hole.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Radius:"), Gravity, range);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Attraction force:"), Gravity, force);
    ADD_BOOL_TWEAK(tr("tweak-text", "Proximity damage"), Gravity, damage);

    ADD_PAGE(tr("tweak-tab", "Radar trace"), RadarTrace);
    new_page->description = tr("tweak-radar-trace", "Controls how this entity appears on radar. Defines its icon, display size, color (if not set by faction), and visibility flags.");
    ADD_TEXT_TWEAK(tr("tweak-text", "Icon:"), RadarTrace, icon);
    ADD_VALUE_MAX_TWEAK(tr("tweak-text", "Size (min/max):"), RadarTrace, min_size, max_size);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Radius:"), RadarTrace, radius);
    ADD_COLOR_TWEAK(tr("tweak-text", "Color:"), RadarTrace, color);
    ADD_LABEL(tr("tweak-text", "Flags:"));
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        auto ui = new GuiToggleTweak(row, tr("tweak-text", "Rotate"),
            [this](bool value)
            {
                if (auto v = entity.getComponent<RadarTrace>())
                {
                    if (value) v->flags |= RadarTrace::Rotate;
                    else v->flags &= ~RadarTrace::Rotate;
                }
            }
        );
        ui->update_func = [this]() -> bool {
            auto v = entity.getComponent<RadarTrace>();
            return v && (v->flags & RadarTrace::Rotate);
        };
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        auto ui = new GuiToggleTweak(row, tr("tweak-text", "Color by faction"), 
            [this](bool value)
            {
                if (auto v = entity.getComponent<RadarTrace>())
                {
                    if (value) v->flags |= RadarTrace::ColorByFaction;
                    else v->flags &= ~RadarTrace::ColorByFaction;
                }
            }
        );
        ui->update_func = [this]() -> bool {
            auto v = entity.getComponent<RadarTrace>();
            return v && (v->flags & RadarTrace::ColorByFaction);
        };
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        auto ui = new GuiToggleTweak(row, tr("tweak-text", "Arrow if not scanned"),
            [this](bool value)
            {
                if (auto v = entity.getComponent<RadarTrace>())
                {
                    if (value) v->flags |= RadarTrace::ArrowIfNotScanned;
                    else v->flags &= ~RadarTrace::ArrowIfNotScanned;
                }
            }
        );
        ui->update_func = [this]() -> bool {
            auto v = entity.getComponent<RadarTrace>();
            return v && (v->flags & RadarTrace::ArrowIfNotScanned);
        };
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        auto ui = new GuiToggleTweak(row, tr("tweak-text", "Blend add"),
            [this](bool value)
            {
                if (auto v = entity.getComponent<RadarTrace>())
                {
                    if (value) v->flags |= RadarTrace::BlendAdd;
                    else v->flags &= ~RadarTrace::BlendAdd;
                }
            }
        );
        ui->update_func = [this]() -> bool {
            auto v = entity.getComponent<RadarTrace>();
            return v && (v->flags & RadarTrace::BlendAdd);
        };
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        auto ui = new GuiToggleTweak(row, tr("tweak-text", "Long range"),
            [this](bool value)
            {
                if (auto v = entity.getComponent<RadarTrace>())
                {
                    if (value) v->flags |= RadarTrace::LongRange;
                    else v->flags &= ~RadarTrace::LongRange;
                }
            }
        );
        ui->update_func = [this]() -> bool {
            auto v = entity.getComponent<RadarTrace>();
            return v && (v->flags & RadarTrace::LongRange);
        };
    }

    ADD_PAGE(tr("tweak-tab", "Raw radar signature"), RawRadarSignatureInfo);
    new_page->description = tr("tweak-raw-radar-signature", "Permanent radar signature values (gravity, electrical, biological) that modify the sensor bands on Science and Operations radars. WIP; might not function.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Gravity:"), RawRadarSignatureInfo, gravity);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Electrical:"), RawRadarSignatureInfo, electrical);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Biological:"), RawRadarSignatureInfo, biological);

    ADD_PAGE(tr("tweak-tab", "Dynamic radar signature"), DynamicRadarSignatureInfo);
    new_page->description = tr("tweak-dynamic-radar-signature", "Live radar signature values updated by the game engine during play, reflecting current ship state. For modifiable base values, see the Raw radar signature component. WIP; might not function.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Gravity:"), DynamicRadarSignatureInfo, gravity);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Electrical:"), DynamicRadarSignatureInfo, electrical);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Biological:"), DynamicRadarSignatureInfo, biological);

    ADD_PAGE(tr("tweak-tab", "Radar link"), RadarLink);
    new_page->description = tr("tweak-radar-link", "Determines whether this entity is capable of receiving a radar link from another entity, such as a probe.");
    ADD_ENTITY_TWEAK(tr("tweak-text", "Linked entity:"), RadarLink, linked_entity);

    ADD_PAGE(tr("tweak-tab", "Missile flight"), MissileFlight);
    new_page->description = tr("tweak-missile-flight", "Parameters relevant if this entity is a missile in flight. Defines maximum travel speed and flight timeout before self-destruction.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Speed:"), MissileFlight, speed);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Timeout:"), MissileFlight, timeout);

    ADD_PAGE(tr("tweak-tab", "Missile homing"), MissileHoming);
    new_page->description = tr("tweak-missile-homing", "Defines this entity's homing guidance system, turn rate for tracking, acquisition range, and the current tracked target entity. Most relevant if this entity is a missile.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Turn rate:"), MissileHoming, turn_rate);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Range:"), MissileHoming, range);
    ADD_ENTITY_TWEAK(tr("tweak-text", "Target:"), MissileHoming, target);

    ADD_PAGE(tr("tweak-tab", "Explode on touch"), ExplodeOnTouch);
    new_page->description = tr("tweak-explode-on-touch", "Explodes upon collision with another entity. Defines center/edge damage falloff, blast radius, owner, damage type, and explosion sound.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Damage at center:"), ExplodeOnTouch, damage_at_center);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Damage at edge:"), ExplodeOnTouch, damage_at_edge);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Blast range:"), ExplodeOnTouch, blast_range);
    ADD_ENTITY_TWEAK(tr("tweak-text", "Owner:"), ExplodeOnTouch, owner);
    ADD_ENUM_TWEAK(tr("tweak-text", "Damage type:"), ExplodeOnTouch, damage_type,
        static_cast<int>(DamageType::Energy), static_cast<int>(DamageType::EMP), damageTypeToString);
    ADD_TEXT_TWEAK(tr("tweak-text", "Explosion SFX:"), ExplodeOnTouch, explosion_sfx);

    ADD_PAGE(tr("tweak-tab", "Explode on timeout"), ExplodeOnTimeout);
    new_page->description = tr("tweak-explode-on-timeout", "Marker component for missiles or other weapons that detonate when their Missile flight component flight timer expires.");

    ADD_PAGE(tr("tweak-tab", "Delayed explode on touch"), DelayedExplodeOnTouch);
    new_page->description = tr("tweak-delayed-explode-on-touch", "Contact detonation with an arming period. Doesn't trigger until the trigger holdoff delay expires after first contact.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Damage at center:"), DelayedExplodeOnTouch, damage_at_center);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Damage at edge:"), DelayedExplodeOnTouch, damage_at_edge);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Blast range:"), DelayedExplodeOnTouch, blast_range);
    ADD_ENTITY_TWEAK(tr("tweak-text", "Owner:"), DelayedExplodeOnTouch, owner);
    ADD_ENUM_TWEAK(tr("tweak-text", "Damage type:"), DelayedExplodeOnTouch, damage_type,
        static_cast<int>(DamageType::Energy), static_cast<int>(DamageType::EMP), damageTypeToString);
    ADD_TEXT_TWEAK(tr("tweak-text", "Explosion SFX:"), DelayedExplodeOnTouch, explosion_sfx);
    ADD_VALUE_MAX_TWEAK(tr("tweak-text", "Holdoff/delay:"), DelayedExplodeOnTouch, trigger_holdoff_delay, delay);
    ADD_BOOL_TWEAK(tr("tweak-text", "Triggered"), DelayedExplodeOnTouch, triggered);

    ADD_PAGE(tr("tweak-tab", "Particle emitter"), ConstantParticleEmitter);
    new_page->description = tr("tweak-constant-particle", "Defines a continuous particle effect that this entity emits. The color shifts from start to end colors linearly across each particle's lifetime.");
    ADD_VALUE_MAX_TWEAK(tr("tweak-text", "Delay/Interval:"), ConstantParticleEmitter, delay, interval);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Travel random range:"), ConstantParticleEmitter, travel_random_range);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Start size:"), ConstantParticleEmitter, start_size);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "End size:"), ConstantParticleEmitter, end_size);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Lifetime:"), ConstantParticleEmitter, life_time);
    ADD_VEC3_COLOR_TWEAK(tr("tweak-text", "Start color:"), ConstantParticleEmitter, start_color);
    ADD_VEC3_COLOR_TWEAK(tr("tweak-text", "End color:"), ConstantParticleEmitter, end_color);

    ADD_PAGE(tr("tweak-tab", "Mesh render"), MeshRenderComponent);
    new_page->description = tr("tweak-mesh-render", "3D mesh rendering. Defines the model file, its scale, and its offset, and also its texture and texture maps. Mesh and texture paths are relative to the resources directory.");
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        (new GuiLabel(row, "", tr("tweak-text", "Mesh:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        auto ui = new GuiTextTweak(row);
        ui->update_func = [this]() -> string {
            if (auto v = entity.getComponent<MeshRenderComponent>())
                return v->mesh.name;

            return "";
        };
        ui->callback(
            [this](string text)
            {
                if (auto v = entity.getComponent<MeshRenderComponent>())
                    v->mesh.name = text;
            }
        );
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        (new GuiLabel(row, "", tr("tweak-text", "Texture:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        auto ui = new GuiTextTweak(row);
        ui->update_func = [this]() -> string {
            if (auto v = entity.getComponent<MeshRenderComponent>())
                return v->texture.name;

            return "";
        };
        ui->callback(
            [this](string text)
            {
                if (auto v = entity.getComponent<MeshRenderComponent>())
                    v->texture.name = text;
            }
        );
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        (new GuiLabel(row, "", tr("tweak-text", "Specular texture:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        auto ui = new GuiTextTweak(row);
        ui->update_func = [this]() -> string {
            if (auto v = entity.getComponent<MeshRenderComponent>())
                return v->specular_texture.name;

            return "";
        };
        ui->callback(
            [this](string text)
            {
                if (auto v = entity.getComponent<MeshRenderComponent>())
                    v->specular_texture.name = text;
            }
        );
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        (new GuiLabel(row, "", tr("tweak-text", "Illumination texture:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        auto ui = new GuiTextTweak(row);
        ui->update_func = [this]() -> string {
            if (auto v = entity.getComponent<MeshRenderComponent>())
                return v->illumination_texture.name;

            return "";
        };
        ui->callback(
            [this](string text)
            {
                if (auto v = entity.getComponent<MeshRenderComponent>())
                    v->illumination_texture.name = text;
            }
        );
    }
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");
        (new GuiLabel(row, "", tr("tweak-text", "Normal texture:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        auto ui = new GuiTextTweak(row);
        ui->update_func = [this]() -> string {
            if (auto v = entity.getComponent<MeshRenderComponent>())
                return v->normal_texture.name;

            return "";
        };
        ui->callback(
            [this](string text)
            {
                if (auto v = entity.getComponent<MeshRenderComponent>())
                    v->normal_texture.name = text;
            }
        );
    }
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Scale:"), MeshRenderComponent, scale);
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 30.0f)
            ->setAttribute("layout", "horizontal");

        (new GuiLabel(row, "", tr("tweak-text", "Mesh offset:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        auto x_ui = new GuiTextTweak(row);
        x_ui->update_func = [this]() -> string {
            if (auto v = entity.getComponent<MeshRenderComponent>())
                return string(v->mesh_offset.x, 3);
            return "";
        };
        x_ui->callback([this](string t) {
            if (auto v = entity.getComponent<MeshRenderComponent>())
                v->mesh_offset.x = t.toFloat();
        });

        auto y_ui = new GuiTextTweak(row);
        y_ui->update_func = [this]() -> string { if (auto v = entity.getComponent<MeshRenderComponent>()) return string(v->mesh_offset.y, 3); return ""; };
        y_ui->callback([this](string t) { if (auto v = entity.getComponent<MeshRenderComponent>()) v->mesh_offset.y = t.toFloat(); });
        auto z_ui = new GuiTextTweak(row);
        z_ui->update_func = [this]() -> string { if (auto v = entity.getComponent<MeshRenderComponent>()) return string(v->mesh_offset.z, 3); return ""; };
        z_ui->callback([this](string t) { if (auto v = entity.getComponent<MeshRenderComponent>()) v->mesh_offset.z = t.toFloat(); });
    }

    ADD_PAGE(tr("tweak-tab", "Engine emitter"), EngineEmitter);
    new_page->description = tr("tweak-energy-emitter", "Engine exhaust particle effects for ships. Each emitter has a position on the hull, a velocity direction, and a color.");
    {
        auto row = new GuiElement(new_page->tweaks, "");
        row
            ->setSize(GuiElement::GuiSizeMax, 210.0f)
            ->setAttribute("layout", "horizontal");
        (new GuiLabel(row, "", tr("tweak-text", "Emitters:"), 20.0f))
            ->setAlignment(sp::Alignment::CenterRight)
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
        auto ui = new GuiEngineEmittersTweak(row);
        ui->update_func = [this]() -> std::vector<EngineEmitter::Emitter> {
            if (auto v = entity.getComponent<EngineEmitter>()) return v->emitters;
            return {};
        };
        ui->on_add = [this](const EngineEmitter::Emitter& e) {
            if (auto v = entity.getComponent<EngineEmitter>())
            {
                v->emitters.push_back(e);
                v->emitters_dirty = true;
            }
        };
        ui->on_update = [this](int index, const EngineEmitter::Emitter& e) {
            auto v = entity.getComponent<EngineEmitter>();
            if (v && index >= 0 && index < static_cast<int>(v->emitters.size()))
            {
                v->emitters[index] = e;
                v->emitters_dirty = true;
            }
        };
        ui->on_remove = [this](int index) {
            auto v = entity.getComponent<EngineEmitter>();
            if (v && index >= 0 && index < static_cast<int>(v->emitters.size()))
            {
                v->emitters.erase(v->emitters.begin() + index);
                v->emitters_dirty = true;
            }
        };
    }

    ADD_PAGE(tr("tweak-tab", "Billboard renderer"), BillboardRenderer);
    new_page->description = tr("tweak-billboard-renderer", "Flat sprite billboard. Renders a 2D texture facing the camera at a configurable size.");
    ADD_TEXT_TWEAK(tr("tweak-text", "Texture:"), BillboardRenderer, texture);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Size:"), BillboardRenderer, size);

    ADD_PAGE(tr("tweak-tab", "Nebula renderer"), NebulaRenderer);
    new_page->description = tr("tweak-nebula-renderer", "Nebula cloud rendering. Defines how far from the nebula it should be visible in 3D views.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Render range:"), NebulaRenderer, render_range);

    ADD_PAGE(tr("tweak-tab", "Planet renderer"), PlanetRender);
    new_page->description = tr("tweak-planet-renderer", "Spherical planet rendering with surface texture, cloud layer, atmosphere glow, and size properties.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Size:"), PlanetRender, size);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Cloud size:"), PlanetRender, cloud_size);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Atmosphere size:"), PlanetRender, atmosphere_size);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Distance from movement plane:"), PlanetRender, distance_from_movement_plane);
    ADD_TEXT_TWEAK(tr("tweak-text", "Texture:"), PlanetRender, texture);
    ADD_TEXT_TWEAK(tr("tweak-text", "Cloud texture:"), PlanetRender, cloud_texture);
    ADD_TEXT_TWEAK(tr("tweak-text", "Atmosphere texture:"), PlanetRender, atmosphere_texture);
    ADD_VEC3_COLOR_TWEAK(tr("tweak-text", "Atmosphere color:"), PlanetRender, atmosphere_color);

    ADD_PAGE(tr("tweak-tab", "Explosion effect"), ExplosionEffect);
    new_page->description = tr("tweak-explosion-effect", "Defines and initates a visual effect for an explosion. Controls the explosion's size and remaining lifetime.");
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Lifetime:"), ExplosionEffect, lifetime);
    ADD_NUM_TEXT_TWEAK(tr("tweak-text", "Size:"), ExplosionEffect, size);
    ADD_BOOL_TWEAK(tr("tweak-text", "Radar"), ExplosionEffect, radar);
    ADD_BOOL_TWEAK(tr("tweak-text", "Electrical"), ExplosionEffect, electrical);

    for (GuiTweakPage* page : pages)
    {
        page
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
            ->hide();
    }

    component_description = new GuiScrollText(content, "COMPONENT_DESC", "");
    component_description
        ->setTextSize(26.0f)
        ->setSize(300.0f, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "0, -50, 20, 0");

    // Define navigation groups by tweak page indices.
    // TODO: Enum for tweak pages instead of brittle ints.
    component_groups = {
        {tr("tweak-group", "Core"), {0, 1}},
        {tr("tweak-group", "Identity"), {2, 3, 18, 47}},
        {tr("tweak-group", "Movement"), {6, 7, 8, 14, 15, 19, 24}},
        {tr("tweak-group", "AI & Pathfinding"), {16, 25, 26}},
        {tr("tweak-group", "Combat"), {5, 13, 9, 10, 11, 12, 44, 43, 27}},
        {tr("tweak-group", "Projectiles"), {51, 52, 53, 54, 55}},
        {tr("tweak-group", "Ship systems"), {35, 4}},
        {tr("tweak-group", "Player"), {34, 28, 29, 23}},
        {tr("tweak-group", "Sensors"), {36, 37, 48, 49, 40, 41, 50, 42}},
        {tr("tweak-group", "Comms & Docking"), {38, 39, 32, 33}},
        {tr("tweak-group", "Countermeasures"), {45, 21}},
        {tr("tweak-group", "World"), {22, 46, 17}},
        {tr("tweak-group", "Rendering"), {57, 58, 59, 60, 61, 62, 56}},
        {tr("tweak-group", "Scripting"), {30, 31, 20}},
    };
    showGroups();

    (new GuiButton(this, "CLOSE_BUTTON", tr("button", "Close"), [this]() {
        hide();
    }))
        ->setTextSize(20.0f)
        ->setPosition(10.0f, -20.0f, sp::Alignment::TopRight)
        ->setSize(70.0f, 30.0f);
}

void GuiEntityTweak::open(sp::ecs::Entity e, string select_component)
{
    // Open and hide all tweak pages for this entity. If a component is
    // selected, reveal its page.
    entity = e;
    for (auto page : pages) page->open(e);

    if (!select_component.empty())
    {
        for (size_t group = 0; group < component_groups.size(); group++)
        {
            for (size_t component_index = 0; component_index < component_groups[group].page_indices.size(); component_index++)
            {
                int page_index = component_groups[group].page_indices[component_index];
                if (page_labels[page_index].find(select_component) != -1)
                {
                    showGroupComponents(group);
                    component_list->setSelectionIndex(component_index + 1);
                    for (auto page : pages) page->hide();
                    pages[page_index]->show();
                    show();
                    return;
                }
            }
        }
    }

    showGroups();
    show();
}

void GuiEntityTweak::showGroups()
{
    in_group_view = true;
    in_search_view = false;
    current_group_index = -1;
    for (auto page : pages) page->hide();
    component_list->clear();
    for (auto& group : component_groups)
        component_list->addEntry(group.name, "");
    component_list->setSelectionIndex(0);
    component_description->setText("");
}

void GuiEntityTweak::showGroupComponents(int group_index)
{
    in_group_view = false;
    in_search_view = false;
    current_group_index = group_index;
    for (auto page : pages) page->hide();

    component_list->clear();
    component_list->addEntry(tr("tweak-nav", "Back"), "");
    auto& group = component_groups[group_index];

    for (int pi : group.page_indices)
        component_list->addEntry(page_labels[pi], "");

    if (!group.page_indices.empty())
    {
        component_list->setSelectionIndex(1);
        pages[group.page_indices[0]]->show();
        showPageDescription(group.page_indices[0]);
    }
    else component_description->setText("");
}

void GuiEntityTweak::showSearchResults(const string& query)
{
    in_group_view = false;
    in_search_view = true;
    current_group_index = -1;
    for (auto page : pages) page->hide();
    search_result_indices.clear();
    component_list->clear();
    string lower_query = query.lower();
    for (int i = 0; i < static_cast<int>(page_labels.size()); i++)
    {
        if (page_labels[i].lower().find(lower_query) != -1)
        {
            search_result_indices.push_back(i);
            component_list->addEntry(page_labels[i], "");
        }
    }
    if (!search_result_indices.empty())
    {
        component_list->setSelectionIndex(0);
        pages[search_result_indices[0]]->show();
        showPageDescription(search_result_indices[0]);
    }
    else
    {
        component_description->setText("");
    }
}

void GuiEntityTweak::showPageDescription(int page_index)
{
    if (page_index >= 0 && page_index < static_cast<int>(pages.size()))
        component_description->setText(pages[page_index]->description);
    else
        component_description->setText("");
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
    add_remove_button
        ->setSize(300.0f, 50.0f)
        ->setAttribute("alignment", "topcenter");

    tweaks = new GuiScrollContainer(this, "TWEAKS");
    tweaks
        ->setPosition(0.0f, 75.0f, sp::Alignment::TopLeft)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(30.0f, 0.0f)
        ->setAttribute("layout", "vertical");
}

void GuiTweakPage::open(sp::ecs::Entity e)
{
    entity = e;
}

void GuiTweakPage::onDraw(sp::RenderTarget& target)
{
    if (has_component(entity))
    {
        add_remove_button->setText(tr("tweak-button", "Remove component"));
        add_remove_button->setStyle("button.toggle.on");
    }
    else
    {
        add_remove_button->setText(tr("tweak-button", "Create component"));
        add_remove_button->setStyle("button.toggle.off");
    }

    tweaks->show();
}
