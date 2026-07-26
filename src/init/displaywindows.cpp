#include "displaywindows.h"
#include "main.h"
#include "menus/luaConsole.h"
#include <preferenceManager.h>
#include "windowManager.h"
#include "gui/mouseRenderer.h"
#include "gui/gui2_canvas.h"
#include "graphics/opengl.h"
#include "menus/shipSelectionScreen.h"
#include "shaderRegistry.h"
#include "gui/debugRenderer.h"
#include "gui/hotkeyConfig.h"
#include "glObjects.h"

class DebugVisibilityToggle : public Renderable
{
public:
    DebugVisibilityToggle(RenderLayer* layer, DebugRenderer* renderer)
    : Renderable(layer), renderer(renderer) {}

    void render(sp::RenderTarget&) override
    {
        if (keys.debug_show.isDiscreteStepDown())
            renderer->setVisible(!renderer->isVisible());
    }

private:
    DebugRenderer* renderer;
};

bool createDisplayWindows()
{
    // Setup the rendering layers.
    defaultRenderLayer = new RenderLayer();
    consoleRenderLayer = new RenderLayer(defaultRenderLayer);
    mouseLayer = new RenderLayer(consoleRenderLayer);
    glitchPostProcessor = new PostProcessor("shaders/glitch", mouseLayer);
    glitchPostProcessor->enabled = false;
    warpPostProcessor = new PostProcessor("shaders/warp", glitchPostProcessor);
    warpPostProcessor->enabled = false;

    new LuaConsole();

    auto debug_canvas = new GuiCanvas(mouseLayer);
    auto debug_renderer = new DebugRenderer(debug_canvas);
    debug_renderer
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
        ->setSize(400.0f, 175.0f);
#ifndef DEBUG
    debug_renderer->hide();
#endif
    new DebugVisibilityToggle(mouseLayer, debug_renderer);

    int width = 1200;
    int height = 900;
    int fsaa = 0;
    Window::Mode fullscreen = (Window::Mode)PreferencesManager::get("fullscreen", "1").toInt();

    if (PreferencesManager::get("fsaa").toInt() > 0)
    {
        fsaa = PreferencesManager::get("fsaa").toInt();
        if (fsaa < 2) fsaa = 2;
    }

#ifndef ANDROID
    if (PreferencesManager::get("touchscreen").toInt() == 0)
    {
        engine->registerObject("mouseRenderer", new MouseRenderer(mouseLayer));
        P<MouseRenderer> mouse_renderer = engine->getObject("mouseRenderer");
    }
#endif

    windows.push_back(new Window({width, height}, fullscreen, warpPostProcessor, fsaa));
    window_render_layers.push_back(defaultRenderLayer);

    auto n = PreferencesManager::get("multimonitor", "0").toInt();
    if (n != 0)
    {
        int num_displays = 0;
        SDL_GetDisplays(&num_displays);
        if (n < 2) n = num_displays;
        SDL_SetHint(SDL_HINT_MOUSE_AUTO_CAPTURE, "0");

        while (static_cast<int>(windows.size()) < n)
        {
            auto wrl = new RenderLayer();
            auto ml = new RenderLayer(wrl);
            new MouseRenderer(ml);
            windows.push_back(new Window({width, height}, fullscreen, ml, fsaa));
            window_render_layers.push_back(wrl);
            new SecondMonitorScreen(static_cast<int>(windows.size() - 1));
        }
    }

#if defined(DEBUG)
    // Synchronous gl debug output always in debug.
    constexpr bool wants_gl_debug = true;
    constexpr bool wants_gl_debug_synchronous = true;
#else
    auto wants_gl_debug = !PreferencesManager::get("gl_debug").empty();
    auto wants_gl_debug_synchronous = !PreferencesManager::get("gl_debug_synchronous").empty();
#endif
    if (wants_gl_debug)
    {
        if (sp::gl::enableDebugOutput(wants_gl_debug_synchronous))
            LOG(Info, "[displaywin] GL Debug output enabled.");
        else
            LOG(Warning, "[displaywin] GL Debug output requested but not available on this system.");
    }

    for (size_t n = 0; n < windows.size(); n++)
    {
        P<Window> window = windows[n];
        string postfix = "";

        if (n > 0) postfix = " - " + string(static_cast<int>(n));

        if (PreferencesManager::get("instance_name") != "")
            window->setTitle("EmptyEpsilon - " + PreferencesManager::get("instance_name") + postfix);
        else
            window->setTitle("EmptyEpsilon" + postfix);

        window->setIcon("logo_icon.png");
    }

    if (gl::isAvailable())
    {
        if (!ShaderRegistry::Shader::initialize())
        {
            LOG(Error, "[displaywin] Failed to initialize shaders, exiting.");
            SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Error", "Failed to initialize shaders (possible cause: cannot find shader files)", nullptr);
            return false;
        }
    }

    return true;
}