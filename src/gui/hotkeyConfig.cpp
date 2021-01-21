#include <i18n.h>
#include "hotkeyConfig.h"
#include "preferenceManager.h"
#include "shipTemplate.h"

HotkeyConfig hotkeys;

HotkeyConfig::HotkeyConfig()
{  // this list includes all Hotkeys and their standard configuration
    newCategory("BASIC", "basic"); // these Items should all have predefined values
    newKey("PAUSE", std::make_tuple(tr("Pause game"), "P"));
    newKey("HELP", std::make_tuple(tr("Show in-game help"), "F1"));
    newKey("ESCAPE", std::make_tuple(tr("Return to ship options menu"), "Escape"));
    newKey("HOME", std::make_tuple(tr("Return to ship options menu"), "Home"));  // Remove this item as it does the same as Escape?

    newCategory("GENERAL", "General");
    newKey("NEXT_STATION", std::make_tuple(tr("Switch to next crew station"), "Tab"));
    newKey("PREV_STATION", std::make_tuple(tr("Switch to previous crew station"), ""));
    newKey("STATION_HELMS", std::make_tuple(tr("Switch to helms station"), "F2"));
    newKey("STATION_WEAPONS", std::make_tuple(tr("Switch to weapons station"), "F3"));
    newKey("STATION_ENGINEERING", std::make_tuple(tr("Switch to engineering station"), "F4"));
    newKey("STATION_SCIENCE", std::make_tuple(tr("Switch to science station"), "F5"));
    newKey("STATION_RELAY", std::make_tuple(tr("Switch to relay station"), "F6"));

    newCategory("MAIN_SCREEN", "Main Screen");
    newKey("VIEW_FORWARD", std::make_tuple(tr("View forward"), "Up"));
    newKey("VIEW_LEFT", std::make_tuple(tr("View left"), "Left"));
    newKey("VIEW_RIGHT", std::make_tuple(tr("View right"), "Right"));
    newKey("VIEW_BACK", std::make_tuple(tr("View backward"), "Down"));
    newKey("VIEW_TARGET", std::make_tuple(tr("Lock view on weapons target"), "T"));
    newKey("TACTICAL_RADAR", std::make_tuple(tr("View tactical radar"), "Tab"));
    newKey("LONG_RANGE_RADAR", std::make_tuple(tr("View long-range radar"), "Q"));
    newKey("FIRST_PERSON", std::make_tuple(tr("Toggle first-person view"), "F"));

    newCategory("HELMS", "Helms");
    newKey("INC_IMPULSE", std::make_tuple(tr("Increase impulse"), "Up"));
    newKey("DEC_IMPULSE", std::make_tuple(tr("Decrease impulse"), "Down"));
    newKey("ZERO_IMPULSE", std::make_tuple(tr("Zero impulse"), "Space"));
    newKey("MAX_IMPULSE", std::make_tuple(tr("Max impulse"), ""));
    newKey("MIN_IMPULSE", std::make_tuple(tr("Max reverse impulse"), ""));
    newKey("TURN_LEFT", std::make_tuple(tr("Turn left"), "Left"));
    newKey("TURN_RIGHT", std::make_tuple(tr("Turn right"), "Right"));
    newKey("WARP_0", std::make_tuple(tr("Warp off"), ""));
    newKey("WARP_1", std::make_tuple(tr("Warp 1"), ""));
    newKey("WARP_2", std::make_tuple(tr("Warp 2"), ""));
    newKey("WARP_3", std::make_tuple(tr("Warp 3"), ""));
    newKey("WARP_4", std::make_tuple(tr("Warp 4"), ""));
    newKey("DOCK_ACTION", std::make_tuple(tr("Dock request/abort/undock"), "D"));
    newKey("DOCK_REQUEST", std::make_tuple(tr("Initiate docking"), ""));
    newKey("DOCK_ABORT", std::make_tuple(tr("Abort docking"), ""));
    newKey("UNDOCK", std::make_tuple(tr("Undock"), "D"));
    newKey("INC_JUMP", std::make_tuple(tr("Increase jump distance"), ""));
    newKey("DEC_JUMP", std::make_tuple(tr("Decrease jump distance"), ""));
    newKey("JUMP", std::make_tuple(tr("Initiate jump"), ""));
    //newKey("COMBAT_LEFT", "Combat maneuver left");
    //newKey("COMBAT_RIGHT", "Combat maneuver right");
    //newKey("COMBAT_BOOST", "Combat maneuver boost");

    newCategory("WEAPONS", "Weapons");
    newKey("SELECT_MISSILE_TYPE_HOMING", std::make_tuple(tr("Select homing"), "Num1"));
    newKey("SELECT_MISSILE_TYPE_NUKE", std::make_tuple(tr("Select nuke"), "Num2"));
    newKey("SELECT_MISSILE_TYPE_MINE", std::make_tuple(tr("Select mine"), "Num3"));
    newKey("SELECT_MISSILE_TYPE_EMP", std::make_tuple(tr("Select EMP"), "Num4"));
    newKey("SELECT_MISSILE_TYPE_HVLI", std::make_tuple(tr("Select HVLI"), "Num5"));
    for(int n=0; n<max_weapon_tubes; n++)
        newKey(std::string("LOAD_TUBE_") + string(n+1), std::make_tuple(std::string("Load tube ") + string(n+1), ""));
    for(int n=0; n<max_weapon_tubes; n++)
        newKey(std::string("UNLOAD_TUBE_") + string(n+1), std::make_tuple(std::string("Unload tube ") + string(n+1), ""));
    for(int n=0; n<max_weapon_tubes; n++)
        newKey(std::string("FIRE_TUBE_") + string(n+1), std::make_tuple(std::string("Fire tube ") + string(n+1), ""));
    newKey("NEXT_ENEMY_TARGET", std::make_tuple(tr("Select next hostile target"), ""));
    newKey("NEXT_TARGET", std::make_tuple(tr("Select next target (any)"), ""));
    newKey("TOGGLE_SHIELDS", std::make_tuple(tr("Toggle shields"), "S"));
    newKey("ENABLE_SHIELDS", std::make_tuple(tr("Enable shields"), ""));
    newKey("DISABLE_SHIELDS", std::make_tuple(tr("Disable shields"), ""));
    newKey("SHIELD_CAL_INC", std::make_tuple(tr("Increase shield frequency target"), ""));
    newKey("SHIELD_CAL_DEC", std::make_tuple(tr("Decrease shield frequency target"), ""));
    newKey("SHIELD_CAL_START", std::make_tuple(tr("Start shield calibration"), ""));
    newKey("BEAM_SUBSYSTEM_TARGET_NEXT", std::make_tuple(tr("Next beam subsystem target type"), ""));
    newKey("BEAM_SUBSYSTEM_TARGET_PREV", std::make_tuple(tr("Previous beam subsystem target type"), ""));
    newKey("BEAM_FREQUENCY_INCREASE", std::make_tuple(tr("Increase beam frequency"), ""));
    newKey("BEAM_FREQUENCY_DECREASE", std::make_tuple(tr("Decrease beam frequency"), ""));
    newKey("TOGGLE_AIM_LOCK", std::make_tuple(tr("Toggle missile aim lock"), ""));
    newKey("ENABLE_AIM_LOCK", std::make_tuple(tr("Enable missile aim lock"), ""));
    newKey("DISABLE_AIM_LOCK", std::make_tuple(tr("Disable missile aim lock"), ""));
    newKey("AIM_MISSILE_LEFT", std::make_tuple(tr("Turn missile aim to the left"), ""));
    newKey("AIM_MISSILE_RIGHT", std::make_tuple(tr("Turn missile aim to the right"), ""));

    newCategory("SCIENCE", "Science");
    newKey("SCAN_OBJECT", std::make_tuple(tr("Scan object"), "S"));
    newKey("NEXT_SCANNABLE_OBJECT", std::make_tuple(tr("Select next scannable object"), "C"));

    newCategory("ENGINEERING", "Engineering");
    newKey("SELECT_REACTOR", std::make_tuple(tr("Select reactor system"), "Num1"));
    newKey("SELECT_BEAM_WEAPONS", std::make_tuple(tr("Select beam weapon system"), "Num2"));
    newKey("SELECT_MISSILE_SYSTEM", std::make_tuple(tr("Select missile weapon system"), "Num3"));
    newKey("SELECT_MANEUVER", std::make_tuple(tr("Select maneuvering system"), "Num4"));
    newKey("SELECT_IMPULSE", std::make_tuple(tr("Select impulse system"), "Num5"));
    newKey("SELECT_WARP", std::make_tuple(tr("Select warp system"), "Num6"));
    newKey("SELECT_JUMP_DRIVE", std::make_tuple(tr("Select jump drive system"), "Num7"));
    newKey("SELECT_FRONT_SHIELDS", std::make_tuple(tr("Select front shields system"), "Num8"));
    newKey("SELECT_REAR_SHIELDS", std::make_tuple(tr("Select rear shields system"), "Num9"));
    newKey("SET_POWER_000", std::make_tuple(tr("Set system power to 0%"), ""));
    newKey("SET_POWER_030", std::make_tuple(tr("Set system power to 30%"), ""));
    newKey("SET_POWER_050", std::make_tuple(tr("Set system power to 50%"), ""));
    newKey("SET_POWER_100", std::make_tuple(tr("Set system power to 100%"), "Space"));
    newKey("SET_POWER_150", std::make_tuple(tr("Set system power to 150%"), ""));
    newKey("SET_POWER_200", std::make_tuple(tr("Set system power to 200%"), ""));
    newKey("SET_POWER_250", std::make_tuple(tr("Set system power to 250%"), ""));
    newKey("SET_POWER_300", std::make_tuple(tr("Set system power to 300%"), ""));
    newKey("INCREASE_POWER", std::make_tuple(tr("Increase system power"), "Up"));
    newKey("DECREASE_POWER", std::make_tuple(tr("Decrease system power"), "Down"));
    newKey("INCREASE_COOLANT", std::make_tuple(tr("Increase system coolant"), "Right"));
    newKey("DECREASE_COOLANT", std::make_tuple(tr("Decrease system coolant"), "Left"));
    newKey("NEXT_REPAIR_CREW", std::make_tuple(tr("Next repair crew"), ""));
    newKey("REPAIR_CREW_MOVE_UP", std::make_tuple(tr("Crew move up"), ""));
    newKey("REPAIR_CREW_MOVE_DOWN", std::make_tuple(tr("Crew move down"), ""));
    newKey("REPAIR_CREW_MOVE_LEFT", std::make_tuple(tr("Crew move left"), ""));
    newKey("REPAIR_CREW_MOVE_RIGHT", std::make_tuple(tr("Crew move right"), ""));
    newKey("SELF_DESTRUCT_START", std::make_tuple(tr("Start self-destruct"), ""));
    newKey("SELF_DESTRUCT_CONFIRM", std::make_tuple(tr("Confirm self-destruct"), ""));
    newKey("SELF_DESTRUCT_CANCEL", std::make_tuple(tr("Cancel self-destruct"), ""));
}

static std::vector<std::pair<string, sf::Keyboard::Key> > sfml_key_names = {
    {"A", sf::Keyboard::A},
    {"B", sf::Keyboard::B},
    {"C", sf::Keyboard::C},
    {"D", sf::Keyboard::D},
    {"E", sf::Keyboard::E},
    {"F", sf::Keyboard::F},
    {"G", sf::Keyboard::G},
    {"H", sf::Keyboard::H},
    {"I", sf::Keyboard::I},
    {"J", sf::Keyboard::J},
    {"K", sf::Keyboard::K},
    {"L", sf::Keyboard::L},
    {"M", sf::Keyboard::M},
    {"N", sf::Keyboard::N},
    {"O", sf::Keyboard::O},
    {"P", sf::Keyboard::P},
    {"Q", sf::Keyboard::Q},
    {"R", sf::Keyboard::R},
    {"S", sf::Keyboard::S},
    {"T", sf::Keyboard::T},
    {"U", sf::Keyboard::U},
    {"V", sf::Keyboard::V},
    {"W", sf::Keyboard::W},
    {"X", sf::Keyboard::X},
    {"Y", sf::Keyboard::Y},
    {"Z", sf::Keyboard::Z},
    {"Num0", sf::Keyboard::Num0},
    {"Num1", sf::Keyboard::Num1},
    {"Num2", sf::Keyboard::Num2},
    {"Num3", sf::Keyboard::Num3},
    {"Num4", sf::Keyboard::Num4},
    {"Num5", sf::Keyboard::Num5},
    {"Num6", sf::Keyboard::Num6},
    {"Num7", sf::Keyboard::Num7},
    {"Num8", sf::Keyboard::Num8},
    {"Num9", sf::Keyboard::Num9},
    {"Escape", sf::Keyboard::Escape},
    {"LControl", sf::Keyboard::LControl},
    {"LShift", sf::Keyboard::LShift},
    {"LAlt", sf::Keyboard::LAlt},
    {"LSystem", sf::Keyboard::LSystem},
    {"RControl", sf::Keyboard::RControl},
    {"RShift", sf::Keyboard::RShift},
    {"RAlt", sf::Keyboard::RAlt},
    {"RSystem", sf::Keyboard::RSystem},
    {"Menu", sf::Keyboard::Menu},
    {"LBracket", sf::Keyboard::LBracket},
    {"RBracket", sf::Keyboard::RBracket},
    {"SemiColon", sf::Keyboard::SemiColon},
    {"Comma", sf::Keyboard::Comma},
    {"Period", sf::Keyboard::Period},
    {"Quote", sf::Keyboard::Quote},
    {"Slash", sf::Keyboard::Slash},
    {"BackSlash", sf::Keyboard::BackSlash},
    {"Tilde", sf::Keyboard::Tilde},
    {"Equal", sf::Keyboard::Equal},
    {"Dash", sf::Keyboard::Dash},
    {"Space", sf::Keyboard::Space},
    {"Return", sf::Keyboard::Return},
    {"BackSpace", sf::Keyboard::BackSpace},
    {"Tab", sf::Keyboard::Tab},
    {"PageUp", sf::Keyboard::PageUp},
    {"PageDown", sf::Keyboard::PageDown},
    {"End", sf::Keyboard::End},
    {"Home", sf::Keyboard::Home},
    {"Insert", sf::Keyboard::Insert},
    {"Delete", sf::Keyboard::Delete},
    {"Add", sf::Keyboard::Add},
    {"Subtract", sf::Keyboard::Subtract},
    {"Multiply", sf::Keyboard::Multiply},
    {"Divide", sf::Keyboard::Divide},
    {"Left", sf::Keyboard::Left},
    {"Right", sf::Keyboard::Right},
    {"Up", sf::Keyboard::Up},
    {"Down", sf::Keyboard::Down},
    {"Numpad0", sf::Keyboard::Numpad0},
    {"Numpad1", sf::Keyboard::Numpad1},
    {"Numpad2", sf::Keyboard::Numpad2},
    {"Numpad3", sf::Keyboard::Numpad3},
    {"Numpad4", sf::Keyboard::Numpad4},
    {"Numpad5", sf::Keyboard::Numpad5},
    {"Numpad6", sf::Keyboard::Numpad6},
    {"Numpad7", sf::Keyboard::Numpad7},
    {"Numpad8", sf::Keyboard::Numpad8},
    {"Numpad9", sf::Keyboard::Numpad9},
    {"F1", sf::Keyboard::F1},
    {"F2", sf::Keyboard::F2},
    {"F3", sf::Keyboard::F3},
    {"F4", sf::Keyboard::F4},
    {"F5", sf::Keyboard::F5},
    {"F6", sf::Keyboard::F6},
    {"F7", sf::Keyboard::F7},
    {"F8", sf::Keyboard::F8},
    {"F9", sf::Keyboard::F9},
    {"F10", sf::Keyboard::F10},
    {"F11", sf::Keyboard::F11},
    {"F12", sf::Keyboard::F12},
    {"F13", sf::Keyboard::F13},
    {"F14", sf::Keyboard::F14},
    {"F15", sf::Keyboard::F15},
    {"Pause", sf::Keyboard::Pause},
};

string HotkeyConfig::getStringForKey(sf::Keyboard::Key key)
{
    for(auto key_name : sfml_key_names)
    {
        if (key_name.second == key)
        {
            return key_name.first;
        }
    }

    return "";
}

void HotkeyConfig::load()
{
    for(HotkeyConfigCategory& cat : categories)
    {
        for(HotkeyConfigItem& item : cat.hotkeys)
        {
            string key_config = PreferencesManager::get(std::string("HOTKEY.") + cat.key + "." + item.key, std::get<1>(item.value));
            item.load(key_config);
            item.value = std::make_tuple(std::get<0>(item.value), key_config);
        }
    }
}

std::vector<HotkeyResult> HotkeyConfig::getHotkey(sf::Event::KeyEvent key)
{
    std::vector<HotkeyResult> results;
    for(HotkeyConfigCategory& cat : categories)
    {
        for(HotkeyConfigItem& item : cat.hotkeys)
        {
            if (item.hotkey.code == key.code && item.hotkey.alt == key.alt && item.hotkey.control == key.control && item.hotkey.shift == key.shift && item.hotkey.system == key.system)
            {
                results.emplace_back(cat.key, item.key);
            }
        }
    }
    return results;
}

void HotkeyConfig::newCategory(string key, string name)
{
    categories.emplace_back();
    categories.back().key = key;
    categories.back().name = name;
}

void HotkeyConfig::newKey(string key, std::tuple<string, string> value)
{
    categories.back().hotkeys.emplace_back(key, value);
}

std::vector<string> HotkeyConfig::getCategories()
{
    // Initialize return value.
    std::vector<string> ret;

    // Add each category to the return value.
    for(HotkeyConfigCategory& cat : categories)
    {
        ret.push_back(cat.name);
    }

    return ret;
}

std::vector<std::pair<string, string>> HotkeyConfig::listHotkeysByCategory(string hotkey_category)
{
    std::vector<std::pair<string, string>> ret;

    for(HotkeyConfigCategory& cat : categories)
    {
        if (cat.name == hotkey_category)
        {
            for(HotkeyConfigItem& item : cat.hotkeys)
            {
                for(auto key_name : sfml_key_names)
                {
                    if (key_name.second == item.hotkey.code)
                    {
                        string keyModifier = "";
                        if (item.hotkey.shift) {
                            keyModifier = "Shift+";
                        } else if (item.hotkey.control) {
                            keyModifier = "Ctrl+";
                        } else if (item.hotkey.alt){
                            keyModifier = "Alt+";
                        }
                        ret.push_back({std::get<0>(item.value), keyModifier + key_name.first});
                    }
                }
            }
        }
    }

    return ret;
}

std::vector<std::pair<string, string>> HotkeyConfig::listAllHotkeysByCategory(string hotkey_category)
{
    std::vector<std::pair<string, string>> ret;

    for(HotkeyConfigCategory& cat : categories)
    {
        if (cat.name == hotkey_category)
        {
            for(HotkeyConfigItem& item : cat.hotkeys)
            {
                ret.push_back({std::get<0>(item.value), std::get<1>(item.value)});
            }
        }
    }

    return ret;
}

sf::Keyboard::Key HotkeyConfig::getKeyByHotkey(string hotkey_category, string hotkey_name)
{
    for(HotkeyConfigCategory& cat : categories)
    {
        if (cat.key == hotkey_category)
        {
            for(HotkeyConfigItem& item : cat.hotkeys)
            {
                if (item.key == hotkey_name)
                {
                    return item.hotkey.code;
                }
            }
        }
    }

    LOG(WARNING) << "Requested an SFML Key from hotkey " << hotkey_category << ", " << hotkey_name << ", but none was found.";
    return sf::Keyboard::KeyCount;
}

HotkeyConfigItem::HotkeyConfigItem(string key, std::tuple<string, string> value)
{
    this->key = key;
    this->value = value;
    hotkey.code = sf::Keyboard::KeyCount;
    hotkey.alt = false;
    hotkey.control = false;
    hotkey.shift = false;
    hotkey.system = false;
}

void HotkeyConfigItem::load(string key_config)
{
    for(const string& config : key_config.split(";"))
    {
        if (config == "[alt]")
            hotkey.alt = true;
        else if (config == "[control]")
            hotkey.control = true;
        else if (config == "[shift]")
            hotkey.shift = true;
        else if (config == "[system]")
            hotkey.system = true;
        else
        {
            for(auto key_name : sfml_key_names)
            {
                if (key_name.first.lower() == config.lower())
                {
                    hotkey.code = key_name.second;
                    break;
                }
            }
        }
    }
}

bool HotkeyConfig::setHotkey(std::string work_cat, std::pair<string,string> key, string new_value)
{
    // test if new_value is part of the sfml_list
    for (std::pair<string, sf::Keyboard::Key> sfml_key : sfml_key_names)
    {
        if ((sfml_key.first.lower() == new_value.lower()) || new_value == "")
        {
            for (HotkeyConfigCategory &cat : categories)
            {
                if (cat.name == work_cat)
                {
                    for (HotkeyConfigItem &item : cat.hotkeys)
                    {
                        if (key.first == std::get<0>(item.value))
                        {
                            item.load(new_value);
                            item.value = std::make_tuple(std::get<0>(item.value), new_value);

                            PreferencesManager::set(std::string("HOTKEY.") + cat.key + "." + item.key, std::get<1>(item.value));

                            return true;
                        }
                    }
                }
            }
        }
    }

    return false;
}
