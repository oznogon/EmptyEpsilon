#pragma once

#include "Updatable.h"
#include "stringImproved.h"
#include <vector>
#include <deque>
#if !defined(_WIN32) && !defined(ANDROID)
#include <termios.h>
#include <ncurses.h>
#include <SDL_log.h>
#endif


class StdinLuaConsole : public Updatable {
public:
    StdinLuaConsole();
    ~StdinLuaConsole();
    void update(float delta) override;
    void addOutputLine(const string& line);
    static void addLuaLogLine(const string& line);

private:
    void initializeUI();
    void cleanupUI();
    void resizeWindows();
    void refreshUI();
    void processKey(int c);
    void handleArrowKey(int direction);
    void handleWordMovement(int direction);
    int findNextWordStart(int pos);
    int findPrevWordStart(int pos);
    void executeLine();
    void scrollOutput(int direction);
    void setupLogCapture();
    void restoreLogCapture();
    static void logCallback(void* userdata, int category, SDL_LogPriority priority, const char* message);
    
    string input_buffer;
    std::vector<string> command_history;
    std::deque<string> output_lines;
    int history_index;
    int cursor_pos;
    int output_scroll_pos;
    int max_output_lines;
    
#if !defined(_WIN32) && !defined(ANDROID)
    struct termios orig_termios;
    bool raw_mode_enabled;
    WINDOW* output_win;
    WINDOW* input_win;
    WINDOW* status_win;
    int terminal_height;
    int terminal_width;
    int output_height;
    int input_height;
    SDL_LogOutputFunction original_log_callback;
    void* original_log_userdata;
    static StdinLuaConsole* instance;
#endif
};