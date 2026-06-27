#pragma once

#include "gui/gui2_canvas.h"
#include "Updatable.h"

class GuiButton;
class GuiLabel;
class GuiListbox;
class GuiScrollFormattedText;
class GuiTextEntry;
class GuiToggleButton;

class ServerSetupScreen : public GuiCanvas
{
public:
    ServerSetupScreen();

private:
    const string DEFAULT_REGISTRY = "http://daid.eu/ee/register.php";

    GuiTextEntry* server_name;
    GuiTextEntry* server_password;
    GuiTextEntry* gm_password;
    GuiToggleButton* server_visibility;
    GuiTextEntry* server_port;
};

class ServerSetupMasterServerRegistrationScreen : public GuiCanvas, Updatable
{
public:
    ServerSetupMasterServerRegistrationScreen();

    virtual void update(float delta) override;

private:
    GuiLabel* info_label;
    GuiButton* continue_button;
};

class ServerScenarioSelectionScreen : public GuiCanvas
{
public:
    ServerScenarioSelectionScreen();

private:
    void loadScenarioList(const string& category);
    GuiListbox* category_list;
    GuiListbox* scenario_list;
    GuiScrollFormattedText* description_text;
    GuiButton* start_button;
};

class ServerScenarioOptionsScreen : public GuiCanvas
{
public:
    ServerScenarioOptionsScreen(string filename);

private:
    GuiButton* start_button;
    std::unordered_map<string,string> scenario_settings;
    std::unordered_map<string, GuiScrollFormattedText*> description_per_setting;
};
