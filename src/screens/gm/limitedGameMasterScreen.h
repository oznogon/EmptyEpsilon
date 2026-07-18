#pragma once

#include "engine.h"
#include "gui/gui2_scrolltextcontainer.h"
#include "gui/gui2_canvas.h"
#include "gui/gui2_overlay.h"
#include "screenComponents/targetsContainer.h"
#include "Updatable.h"

class GuiRadarView;
class GuiRadarZoomSlider;
class GuiOverlay;
class GuiSelector;
class GuiKeyValueDisplay;
class GuiListbox;
class GuiButton;
class GuiToggleButton;
class GameMasterChatDialog;
class GuiGlobalMessageEntryView;
class GuiHotkeyHelpOverlay;
class GuiPanel;
class LimitedGuiEntityTweak;

class LimitedGameMasterScreen : public GuiCanvas, public Updatable
{
private:
    const float MIN_ZOOM_DISTANCE = 5000.0f;
    const float MAX_ZOOM_DISTANCE = 1000000.0f;
    const float LONG_RANGE_DISTANCE = 50000.0f;
    const float SHORT_RANGE_DISTANCE = 10000.0f;

    TargetsContainer targets;
    sp::ecs::Entity target;
    GuiRadarView* main_radar;
    GuiOverlay* box_selection_overlay;
    GuiSelector* faction_selector;

    GuiElement* chat_layer;
    std::vector<GameMasterChatDialog*> chat_dialog_per_ship;
    GuiGlobalMessageEntryView* global_message_entry;

    GuiElement* info_layout;
    std::vector<GuiKeyValueDisplay*> info_items;
    GuiKeyValueDisplay* info_clock;
    GuiListbox* gm_script_options;
    GuiElement* order_layout;
    GuiButton* player_comms_hail;
    GuiButton* global_message_button;
    GuiToggleButton* pause_button;
    GuiSelector* game_time_scale;
    GuiButton* tweak_button;
    LimitedGuiEntityTweak* tweak_dialog;
    GuiRadarZoomSlider* zoom_slider;
    GuiSelector* player_ship_selector;

    GuiPanel* message_frame;
    GuiScrollFormattedText* message_text;
    GuiButton* message_close_button;

    GuiHotkeyHelpOverlay* keyboard_help;

    enum class ClickAndDragState
    {
        None,
        DragViewOrOrder,
        DragView,
        ClickSelectOrBoxSelect,
        BoxSelect,
        ClickSelectOrDragObjects,
        DragObjects,
    } click_and_drag_state = ClickAndDragState::None;

    glm::vec2 drag_start_position{};
    glm::vec2 drag_previous_position{};
    std::vector<std::pair<sp::ecs::Entity, glm::vec2>> drag_entity_original_positions;
    glm::vec2 drag_total_offset{0.0f, 0.0f};

    enum class GMCursorMode : unsigned
    {
        None = 0,
        SelectArea = 1 << 0,
        SelectShips = 1 << 1,
        SelectFaction = 1 << 2,
        AddToSelection = 1 << 3,
        MoveEntities = 1 << 6,
        SetAITarget = 1 << 7,
        ZoomCamera = 1 << 8,
        PanCamera = 1 << 9,
    } gm_cursor_mode = GMCursorMode::None;

    friend GMCursorMode operator|(GMCursorMode a, GMCursorMode b)
        { return GMCursorMode(unsigned(a) | unsigned(b)); }
    friend GMCursorMode& operator|=(GMCursorMode& a, GMCursorMode b)
        { return a = GMCursorMode(unsigned(a) | unsigned(b)); }
    friend GMCursorMode operator&(GMCursorMode a, GMCursorMode b)
        { return GMCursorMode(unsigned(a) & unsigned(b)); }

    bool has_cpu_ship = false;
    bool has_player_ship = false;

    bool gm_add_waypoint_mode = false;
    bool gm_delete_waypoint_mode = false;
    int  gm_waypoint_set = 1;
    sp::ecs::Entity gm_waypoint_target_ship;
    int gm_drag_waypoint_id = -1;
    int gm_drag_waypoint_set = -1;
    sp::ecs::Entity gm_drag_waypoint_ship;

    GuiElement* gm_player_waypoint_layout;
    GuiSelector* gm_waypoint_set_selector;
    GuiToggleButton* gm_show_waypoints_button;
    GuiToggleButton* gm_add_waypoint_button;
    GuiToggleButton* gm_route_toggle;
    GuiToggleButton* gm_delete_waypoint_button;

    bool show_health_bars = true;
    float last_known_game_speed = -1.0f;

    GameMasterChatDialog* getChatDialog(sp::ecs::Entity entity);

    void runScript(const string& code);
    void runScriptForEntity(const string& entity_str, const string& expression);
    string getEntityStringForLua(sp::ecs::Entity entity);

public:
    LimitedGameMasterScreen(RenderLayer* render_layer);
    virtual ~LimitedGameMasterScreen();

    virtual void update(float delta) override;

    void onMouseDown(sp::io::Pointer::Button button, glm::vec2 position);
    void onMouseDrag(glm::vec2 position);
    void onMouseUp(glm::vec2 position);
    void onMouseWheel(float value, glm::vec2 position);

    std::vector<sp::ecs::Entity> getSelection();
};
