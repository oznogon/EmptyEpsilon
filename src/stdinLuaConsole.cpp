#include "stdinLuaConsole.h"
#include "gameGlobalInfo.h"
#include <cstdlib>
#include <cctype>
#include <iostream>
#include <algorithm>
#ifdef _WIN32
#include <windows.h>
#include <conio.h>
#include <signal.h>
#elif !defined(ANDROID)
#include <sys/select.h>
#include <unistd.h>
#include <termios.h>
#include <errno.h>
#include <signal.h>
#include <ncurses.h>
#include <SDL_log.h>
#endif

#if !defined(_WIN32) && !defined(ANDROID)
StdinLuaConsole* StdinLuaConsole::instance = nullptr;
#endif

StdinLuaConsole::StdinLuaConsole() : history_index(-1), cursor_pos(0), output_scroll_pos(0), max_output_lines(1000) {
#if !defined(_WIN32) && !defined(ANDROID)
    raw_mode_enabled = false;
    output_win = nullptr;
    input_win = nullptr;
    status_win = nullptr;
    original_log_callback = nullptr;
    original_log_userdata = nullptr;
    instance = this;
    initializeUI();
    setupLogCapture();
#endif
    addOutputLine("=== EmptyEpsilon Lua Console ===");
    addOutputLine("Type Lua commands below. Use Ctrl+C to exit.");
    addOutputLine("Use Page Up/Page Down to scroll output.");
}

StdinLuaConsole::~StdinLuaConsole() {
#if !defined(_WIN32) && !defined(ANDROID)
    restoreLogCapture();
    cleanupUI();
    instance = nullptr;
#endif
}

void StdinLuaConsole::update(float delta) {
#if !defined(_WIN32) && !defined(ANDROID)
    int c = getch();
    if (c != ERR) {
        processKey(c);
    }
    
    int new_height, new_width;
    getmaxyx(stdscr, new_height, new_width);
    if (new_height != terminal_height || new_width != terminal_width) {
        resizeWindows();
        refreshUI();
    }
#endif
}

#if !defined(_WIN32) && !defined(ANDROID)
void StdinLuaConsole::initializeUI() {
    initscr();
    cbreak();
    noecho();
    nodelay(stdscr, TRUE);
    keypad(stdscr, TRUE);
    
    getmaxyx(stdscr, terminal_height, terminal_width);
    
    output_height = terminal_height - 4;
    input_height = 3;
    
    output_win = newwin(output_height, terminal_width, 0, 0);
    status_win = newwin(1, terminal_width, output_height, 0);
    input_win = newwin(input_height, terminal_width, output_height + 1, 0);
    
    scrollok(output_win, TRUE);
    
    wbkgd(status_win, A_REVERSE);
    mvwprintw(status_win, 0, 0, " EmptyEpsilon Lua Console - Ctrl+C to exit, PgUp/PgDn to scroll");
    wclrtoeol(status_win);
    
    box(input_win, 0, 0);
    mvwprintw(input_win, 0, 2, " Input ");
    
    refreshUI();
}

void StdinLuaConsole::cleanupUI() {
    if (output_win) delwin(output_win);
    if (status_win) delwin(status_win);
    if (input_win) delwin(input_win);
    endwin();
}

void StdinLuaConsole::resizeWindows() {
    getmaxyx(stdscr, terminal_height, terminal_width);
    
    output_height = terminal_height - 4;
    input_height = 3;
    
    wresize(output_win, output_height, terminal_width);
    wresize(status_win, 1, terminal_width);
    wresize(input_win, input_height, terminal_width);
    
    mvwin(status_win, output_height, 0);
    mvwin(input_win, output_height + 1, 0);
    
    wclear(status_win);
    wbkgd(status_win, A_REVERSE);
    mvwprintw(status_win, 0, 0, " EmptyEpsilon Lua Console - Ctrl+C to exit, PgUp/PgDn to scroll");
    wclrtoeol(status_win);
    
    wclear(input_win);
    box(input_win, 0, 0);
    mvwprintw(input_win, 0, 2, " Input ");
}

void StdinLuaConsole::refreshUI() {
    wclear(output_win);
    
    int lines_to_show = std::min((int)output_lines.size(), output_height);
    int start_line = std::max(0, (int)output_lines.size() - output_height - output_scroll_pos);
    
    for (int i = 0; i < lines_to_show; i++) {
        int line_idx = start_line + i;
        if (line_idx >= 0 && line_idx < (int)output_lines.size()) {
            mvwprintw(output_win, i, 0, "%s", output_lines[line_idx].c_str());
        }
    }
    
    mvwprintw(input_win, 1, 2, "> %s", input_buffer.c_str());
    wclrtoeol(input_win);
    
    int cursor_screen_pos = cursor_pos + 4;
    if (cursor_screen_pos >= terminal_width - 2) {
        cursor_screen_pos = terminal_width - 3;
    }
    wmove(input_win, 1, cursor_screen_pos);
    
    wrefresh(output_win);
    wrefresh(status_win);
    wrefresh(input_win);
}
#endif

void StdinLuaConsole::addOutputLine(const string& line) {
#if !defined(_WIN32) && !defined(ANDROID)
    output_lines.push_back(line);
    
    while ((int)output_lines.size() > max_output_lines) {
        output_lines.pop_front();
    }
    
    output_scroll_pos = 0;
    refreshUI();
#endif
}

void StdinLuaConsole::addLuaLogLine(const string& line) {
#if !defined(_WIN32) && !defined(ANDROID)
    if (instance) {
        instance->addOutputLine(line);
    }
#endif
}

void StdinLuaConsole::processKey(int c) {
#if !defined(_WIN32) && !defined(ANDROID)
    if (c == 3) { // Ctrl-C
        cleanupUI();
        exit(0);
        return;
    }
    
    switch (c) {
        case KEY_UP:
            handleArrowKey(-1);
            break;
        case KEY_DOWN:
            handleArrowKey(1);
            break;
        case KEY_LEFT:
            if (cursor_pos > 0) {
                cursor_pos--;
                refreshUI();
            }
            break;
        case KEY_RIGHT:
            if (cursor_pos < (int)input_buffer.length()) {
                cursor_pos++;
                refreshUI();
            }
            break;
        case KEY_PPAGE: // Page Up
            scrollOutput(1);
            break;
        case KEY_NPAGE: // Page Down
            scrollOutput(-1);
            break;
        case 545: // Ctrl+Right
            handleWordMovement(1);
            break;
        case 560: // Ctrl+Left
            handleWordMovement(-1);
            break;
        case '\r':
        case '\n':
        case KEY_ENTER:
            executeLine();
            break;
        case KEY_BACKSPACE:
        case 127:
        case 8:
            if (cursor_pos > 0) {
                input_buffer.erase(cursor_pos - 1, 1);
                cursor_pos--;
                refreshUI();
            }
            break;
        default:
            if (c >= 32 && c < 127) { // Printable characters
                input_buffer.insert(cursor_pos, 1, (char)c);
                cursor_pos++;
                refreshUI();
            }
            break;
    }
#endif
}

void StdinLuaConsole::handleArrowKey(int direction) {
#if !defined(_WIN32) && !defined(ANDROID)
    if (command_history.empty()) return;
    
    int new_index = history_index + direction;
    
    if (direction < 0) { // Up arrow
        if (history_index == -1) {
            new_index = command_history.size() - 1;
        } else if (new_index < 0) {
            return; // At oldest command
        }
    } else { // Down arrow
        if (new_index >= (int)command_history.size()) {
            new_index = -1; // Back to current empty line
        }
    }
    
    history_index = new_index;
    
    if (history_index == -1) {
        input_buffer.clear();
    } else {
        input_buffer = command_history[history_index];
    }
    
    cursor_pos = input_buffer.length();
    refreshUI();
#endif
}

void StdinLuaConsole::handleWordMovement(int direction) {
#if !defined(_WIN32) && !defined(ANDROID)
    if (direction > 0) {
        cursor_pos = findNextWordStart(cursor_pos);
    } else {
        cursor_pos = findPrevWordStart(cursor_pos);
    }
    refreshUI();
#endif
}

int StdinLuaConsole::findNextWordStart(int pos) {
    int len = input_buffer.length();
    if (pos >= len) return len;
    
    while (pos < len && (isalnum(input_buffer[pos]) || input_buffer[pos] == '_')) {
        pos++;
    }
    
    while (pos < len && isspace(input_buffer[pos])) {
        pos++;
    }
    
    return pos;
}

int StdinLuaConsole::findPrevWordStart(int pos) {
    if (pos <= 0) return 0;
    
    pos--;
    
    while (pos > 0 && isspace(input_buffer[pos])) {
        pos--;
    }
    
    while (pos > 0 && (isalnum(input_buffer[pos - 1]) || input_buffer[pos - 1] == '_')) {
        pos--;
    }
    
    return pos;
}

void StdinLuaConsole::executeLine() {
#if !defined(_WIN32) && !defined(ANDROID)
    if (!input_buffer.empty()) {
        addOutputLine("> " + input_buffer);
        
        command_history.push_back(input_buffer);
        if (command_history.size() > 100) {
            command_history.erase(command_history.begin());
        }
        
        if (gameGlobalInfo) {
            gameGlobalInfo->execScriptCode(input_buffer);
        }
        
        input_buffer.clear();
        cursor_pos = 0;
        history_index = -1;
        refreshUI();
    }
#endif
}

void StdinLuaConsole::scrollOutput(int direction) {
#if !defined(_WIN32) && !defined(ANDROID)
    int max_scroll = std::max(0, (int)output_lines.size() - output_height);
    
    if (direction > 0) { // Scroll up (show older lines)
        output_scroll_pos = std::min(output_scroll_pos + output_height / 2, max_scroll);
    } else { // Scroll down (show newer lines)
        output_scroll_pos = std::max(output_scroll_pos - output_height / 2, 0);
    }
    
    refreshUI();
#endif
}

#if !defined(_WIN32) && !defined(ANDROID)
void StdinLuaConsole::setupLogCapture() {
    SDL_LogGetOutputFunction(&original_log_callback, &original_log_userdata);
    SDL_LogSetOutputFunction(&StdinLuaConsole::logCallback, this);
}

void StdinLuaConsole::restoreLogCapture() {
    if (original_log_callback) {
        SDL_LogSetOutputFunction(original_log_callback, original_log_userdata);
    }
}

void StdinLuaConsole::logCallback(void* userdata, int category, SDL_LogPriority priority, const char* message) {
    auto* console = static_cast<StdinLuaConsole*>(userdata);
    if (console) {
        const char* level_prefix = "";
        switch (priority) {
            case SDL_LOG_PRIORITY_DEBUG:   level_prefix = "[DEBUG  ] "; break;
            case SDL_LOG_PRIORITY_INFO:    level_prefix = "[INFO   ] "; break;
            case SDL_LOG_PRIORITY_WARN:    level_prefix = "[WARNING] "; break;
            case SDL_LOG_PRIORITY_ERROR:   level_prefix = "[ERROR  ] "; break;
            case SDL_LOG_PRIORITY_CRITICAL:level_prefix = "[CRITICAL]"; break;
            default:                       level_prefix = "[UNKNOWN] "; break;
        }
        
        string log_message = string(level_prefix) + message;
        console->addOutputLine(log_message);
    }
    
    if (console && console->original_log_callback) {
        console->original_log_callback(console->original_log_userdata, category, priority, message);
    }
}
#endif