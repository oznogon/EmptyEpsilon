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
sp::io::Keybinding open_console_key("CONSOLE_KEY", {"`"});

LuaConsole::LuaConsole()
: GuiCanvas(consoleRenderLayer)
{
    console = this;
    open_console_key.setLabel(tr("hotkey_menu", "General"), tr("hotkey_General", "Open Lua console"));
    open_console_key.setSupportedInteractions(sp::io::Keybinding::Interaction::Discrete);

    top = new GuiOverlay(this, "", {0, 0, 0, 192});
    top->getLayout().fill_height = false;
    top->getLayout().size.y = 450;
    top->getLayout().margin.left = 50;
    top->getLayout().margin.right = 50;
    top->setAttribute("layout", "vertical");

    log_scroll = new GuiScrollContainer(top, "", GuiScrollContainer::ScrollMode::Scroll);
    log_scroll->setAttribute("stretch", "true");
    log_scroll->setScrollbarWidth(25);
    log_scroll->setScrollStart(GuiScrollContainer::ScrollStart::Bottom);
    log_scroll->enableAutoScrollDown();

    log = new GuiTextEntry(log_scroll, "", "");
    log->setAttribute("style", "luaconsole.log");
    log->getLayout().fill_width = true;
    log->setMultiline(true);
    log->setWrap(true);
    log->setTextSize(12);
    log->setAttribute("readonly", "true");
    entry = new GuiTextEntry(top, "", "");
    entry->setAttribute("style", "luaconsole.entry");
    entry->getLayout().fill_width = true;
    entry->setMultiline(true);
    entry->setWrap(true);
    entry->setTextSize(12);
    entry->enterCallback([this](string s) {
        if (gameGlobalInfo) {
            LuaConsole::addLog("> " + s);
            gameGlobalInfo->execScriptCode(s);
            history.append(s);
            entry->setText("");
        }
    });
    entry->upCallback([this](string s) {
        string text = history.movePrevious(s);
        entry->setText(text);
        entry->setCursorPosition(static_cast<int>(text.size()));
    });
    entry->downCallback([this](string s) {
        string text = history.moveNext(s);
        entry->setText(text);
        entry->setCursorPosition(static_cast<int>(text.size()));
    });

    top->hide();
    entry->hide();
}

bool LuaConsole::onPointerDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    if (!top->isVisible())
        return false;
    bool handled = GuiCanvas::onPointerDown(button, position, id);
    if (!log->getRect().contains(position) && !entry->getRect().contains(position))
        focus(nullptr);
    return handled;
}

void LuaConsole::addLog(const string& message)
{
    if (!console) return;
    for(auto msg : message.split("\n"))
        console->log_messages.push_back(msg);
    while(console->log_messages.size() > 50)
        console->log_messages.erase(console->log_messages.begin());
    console->log->setText(string("\n").join(console->log_messages));
    if (!console->is_open && PreferencesManager::get("lua_console_popup", "1") == "1") {
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
    if (open_console_key.getDown()) {
        if (is_open) {
            is_open = false;
            top->hide();
            entry->hide();
        } else {
            is_open = true;
            top->getLayout().size.y = 450;
            message_show_timers.clear();
            top->show();
            top->setEnable(true);
            entry->show();
        }
    }
    while(!message_show_timers.empty() && message_show_timers.front().isExpired()) {
        message_show_timers.erase(message_show_timers.begin());
        if (message_show_timers.empty()) {
            top->hide();
        } else {
            auto linespace = console->log->getLineSpacing();
            auto padding = console->log_scroll->getLayout().padding.top + console->log_scroll->getLayout().padding.bottom;
            top->getLayout().size.y = std::min(450.0f, (0.3f + message_show_timers.size()) * linespace + padding);
            log_scroll->setPendingScrollToBottom();
        }
    }

}

void LuaConsole::onTextInput(sp::TextInputEvent e)
{
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

string ConsoleHistory::movePrevious(string s) {
    if (position == 0)
        // beginning of history, nothing to go up to. keep the line the same.
        return s;

    if (position == entries.size())
        // previous from a line not in history; set it pending so we can go back down to it later
        pending = s;
    else
        entries[position] = s;

    return entries[--position];
}

string ConsoleHistory::moveNext(string s) {
    if (position == entries.size())
        return s;

    if (position + 1 == entries.size())
    {
        // end of history, nothing to do down to.
        // if we had a pending entry, put it back
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
