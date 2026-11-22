#include "luaConsole.h"
#include "i18n.h"
#include "main.h"
#include "gameGlobalInfo.h"
#include "preferenceManager.h"

#include "gui/theme.h"
#include "gui/gui2_overlay.h"
#include "gui/gui2_panel.h"
#include "gui/gui2_textentry.h"
#include "gui/gui2_scrollcontainer.h"

#include "io/keybinding.h"

static LuaConsole* console;

// Define keybind, default backtick (`).
sp::io::Keybinding open_console_key("CONSOLE_KEY", {"`"});

LuaConsole::LuaConsole()
: GuiCanvas(consoleRenderLayer)
{
    console = this;

    // Define keybind details.
    open_console_key.setLabel(tr("hotkey_menu", "General"), tr("hotkey_General", "Open Lua console"));
    open_console_key.setSupportedInteractions(sp::io::Keybinding::Interaction::Discrete);

    // 
    top = new GuiOverlay(this, "", {0, 0, 0, 192});
    top->getLayout().fill_height = false;
    top->getLayout().size.y = 450.0f;
    top->getLayout().margin.left = 50.0f;
    top->getLayout().margin.right = 50.0f;
    top->setAttribute("layout", "vertical");
    top->hide();

    log_scroll = new GuiScrollContainer(top, "", GuiScrollContainer::ScrollMode::Scroll);
    log_scroll->setAttribute("stretch", "true");
    log_scroll
        ->setScrollbarWidth(25.0f)
        ->setScrollStart(GuiScrollContainer::ScrollStart::Bottom)
        ->enableAutoScrollDown();

    log = new GuiTextEntry(log_scroll, "", "");
    log->setAttribute("style", "luaconsole.log");
    log->setAttribute("readonly", "true");
    log->getLayout().fill_width = true;
    log
        ->setMultiline(true)
        ->setWrap(true)
        ->setTextSize(12.0f);

    entry = new GuiTextEntry(top, "", "");
    entry->setAttribute("style", "luaconsole.entry");
    entry->getLayout().fill_width = true;
    entry
        ->setMultiline(true)
        ->setWrap(true)
        ->setTextSize(12.0f)
        ->enterCallback([this](string s) {
            if (gameGlobalInfo)
            {
                LuaConsole::addLog("> " + s);
                gameGlobalInfo->execScriptCode(s);
                history.append(s);
                entry->setText("");
            }
        })
        ->upCallback([this](string s) {
            string text = history.movePrevious(s);
            entry
                ->setText(text)
                ->setCursorPosition(static_cast<int>(text.size()));
        })
        ->downCallback([this](string s) {
            string text = history.moveNext(s);
            entry
                ->setText(text)
                ->setCursorPosition(static_cast<int>(text.size()));
        })
        ->hide();
}

bool LuaConsole::onPointerDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    if (!top->isVisible()) return false;

    bool handled = GuiCanvas::onPointerDown(button, position, id);
    if (!log->getRect().contains(position) && !entry->getRect().contains(position))
        focus(nullptr);

    return handled;
}

void LuaConsole::addLog(const string& message)
{
    if (!console) return;

    for (auto msg : message.split("\n"))
        console->log_messages.push_back(msg);

    while (console->log_messages.size() > 50)
        console->log_messages.erase(console->log_messages.begin());

    console->log->setText(string("\n").join(console->log_messages));
    if (!console->is_open && PreferencesManager::get("lua_console_popup", "1") == "1")
    {
        console->log_scroll->setPendingScrollToBottom();
        console->message_show_timers.emplace_back();
        console->message_show_timers.back().start(5.0f);
        auto linespace = console->log->getLineSpacing();
        auto padding = console->log_scroll->getLayout().padding.top + console->log_scroll->getLayout().padding.bottom;
        console->top->getLayout().size.y = std::min(450.0f, (0.3f + console->message_show_timers.size()) * linespace + padding);
        console->top->show();
        console->top->setEnable(false);
    }
}

void LuaConsole::update(float delta)
{
    // Handle console toggle keybind.
    if (open_console_key.getDown())
    {
        if (is_open)
        {
            is_open = false;
            top->hide();
            entry->hide();
        }
        else
        {
            is_open = true;
            top->getLayout().size.y = 450.0f;
            message_show_timers.clear();
            top
                ->show()
                ->setEnable(true);
            entry->show();
        }
    }

    while (!message_show_timers.empty() && message_show_timers.front().isExpired())
    {
        message_show_timers.erase(message_show_timers.begin());

        if (message_show_timers.empty()) top->hide();
        else
        {
            auto linespace = console->log->getLineSpacing();
            auto padding = console->log_scroll->getLayout().padding.top + console->log_scroll->getLayout().padding.bottom;

            top->getLayout().size.y = std::min(
                450.0f,
                (0.3f + message_show_timers.size()) * linespace + padding
            );
            log_scroll->setPendingScrollToBottom();
        }
    }

}

void LuaConsole::onTextInput(sp::TextInputEvent e)
{
    // Handle arrow key navigation.
    switch(e)
    {
    case sp::TextInputEvent::Up:
    case sp::TextInputEvent::UpWithSelection:
    case sp::TextInputEvent::Down:
    case sp::TextInputEvent::DownWithSelection:
        entry->onTextInput(e);
        break;
    default:
        GuiCanvas::onTextInput(e);
        break;
    }
}

string ConsoleHistory::movePrevious(string s)
{
    // Beginning of history, nothing to go up to. keep the line the same.
    if (position == 0) return s;

    // Previous from a line not in history. Set it pending so we can go back
    // down to it later.
    if (position == entries.size()) pending = s;
    else entries[position] = s;

    return entries[--position];
}

string ConsoleHistory::moveNext(string s)
{
    if (position == entries.size()) return s;

    // End of history, nothing to do down to.
    // If we had a pending entry, put it back.
    if (position + 1 == entries.size())
    {
        position++;
        string wasPending = pending;
        pending = "";

        return wasPending;
    }

    entries[position] = s;

    return entries[++position];
}

void ConsoleHistory::append(string s)
{
    entries.push_back(s);
    position = static_cast<unsigned int>(entries.size());
    pending = "";
}
