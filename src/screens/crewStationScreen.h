#pragma once

#include <memory>
#include "engine.h"
#include "threatLevelEstimate.h"
#include "playerInfo.h"

#include "gui/gui2_canvas.h"

#include "ecs/entity.h"
#include "screenComponents/helpOverlay.h"
#include "screenComponents/viewport3d.h"
#include "screenComponents/viewportMainScreen.h"

class GuiButton;
class GuiHotkeyHelpOverlay;
class GuiPanel;
class GuiScrollContainer;
class GuiScrollFormattedText;
class GuiToggleButton;
class GuiViewport3D;
class GuiViewportMainScreen;
class ImpulseSound;
class UtilityBeamSound;

class CrewStationScreen : public GuiCanvas, public Updatable
{
    P<ThreatLevelEstimate> threat_estimate;
public:
    explicit CrewStationScreen(RenderLayer* render_layer, bool with_main_screen);
    virtual void destroy() override;

    GuiContainer* getTabContainer();
    void addStationTab(GuiElement* element, CrewPosition position, string name, string icon);
    void finishCreation();

    void setDroneViewport(sp::ecs::Entity drone);
    void clearDroneViewport();

    virtual void update(float delta) override;

private:
    GuiElement* main_panel;
    GuiViewportMainScreen* viewport{nullptr};
    GuiButton* select_crew_screen_button;
    GuiScrollContainer* select_crew_screen_list;
    GuiPanel* button_strip;
    GuiHotkeyHelpOverlay* keyboard_help;
    GuiPanel* message_frame;
    GuiScrollFormattedText* message_text;
    GuiButton* message_close_button;
    std::unique_ptr<ImpulseSound> impulse_sound;
    std::unique_ptr<UtilityBeamSound> utility_beam_sound;

    struct CrewTabInfo {
        GuiToggleButton* button;
        GuiElement* element;
        CrewPosition position;
    };

    CrewPosition current_position = CrewPosition::helmsOfficer;
    std::vector<CrewTabInfo> tabs;
    void showNextTab(int offset = 1);
    void showTab(GuiElement* element);
    std::vector<string> hotkey_categories = {tr("hotkey_menu", "General"), tr("hotkey_menu", "Crew screens")};

    GuiElement* findTab(string name);

    void tileViewport();
};
