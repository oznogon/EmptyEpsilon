#include "mineSweeper.h"
#include "i18n.h"
#include "random.h"
#include "miniGame.h"
#include "hackingDialog.h"

#include "gui/gui2_togglebutton.h"
#include "gui/gui2_label.h"
#include "gui/gui2_progressbar.h"
#include "gui/gui2_panel.h"

MineSweeper::MineSweeper(GuiPanel* owner, GuiHackingDialog* parent, int difficulty)
: MiniGame(owner, parent, difficulty)
{
    field_size = difficulty * 2 + 6;
    bomb_count = difficulty * 2 + 6;

    // Create attempts remaining label.
    attempts_label = new GuiLabel(owner, "MINESWEEPER_ATTEMPTS_COUNT", "", 25.0f);
    attempts_label
        ->setAlignment(sp::Alignment::CenterRight)
        ->setPosition(-185.0f, -25.0f, sp::Alignment::BottomRight)
        ->setSize(150.0f, GuiElement::GuiSizeRow);

    // Create flag mode toggle button for touch/no right click.
    flag_mode_toggle = new GuiToggleButton(owner, "MINESWEEPER_FLAG_MODE", "",
        [this](bool value)
        {
            flag_mode = value;
        }
    );
    flag_mode_toggle
        ->setIcon("waypoint.png", sp::Alignment::Center)
        ->setPosition(185.0f, -25.0f, sp::Alignment::BottomLeft)
        ->setSize(GuiElement::GuiSizeRow, GuiElement::GuiSizeRow);

    for (int x = 0; x < field_size; x++)
    {
        for (int y = 0; y < field_size; y++)
        {
            FieldItem* item = new FieldItem(
                owner, "", "",
                [this, x, y](bool value)
                {
                    if (flag_mode) onFieldRightClick(x, y);
                    else onFieldClick(x, y);
                },
                [this, x, y](bool value)
                {
                    onFieldRightClick(x, y);
                }
            );

            item
                ->setSize(GuiElement::GuiSizeRow, GuiElement::GuiSizeRow)
                ->setPosition(
                    static_cast<float>(x * 50 - field_size * 25),
                    static_cast<float>(25 + y * 50 - field_size * 25),
                    sp::Alignment::Center
                );
            board.emplace_back(item);
        }
    }

    reset();
}

MineSweeper::~MineSweeper()
{
    // Explicitly destroy GUI controls.
    if (attempts_label) attempts_label->destroy();
    if (flag_mode_toggle) flag_mode_toggle->destroy();
}

void MineSweeper::disable()
{
    MiniGame::disable();

    for (int x = 0; x < field_size; x++)
    {
        for (int y = 0; y < field_size; y++)
        {
            FieldItem* item = getFieldItem(x, y);
            item
                ->setValue(false)
                ->setText("")
                ->setIcon("")
                ->disable();
        }
    }

    attempts_label->hide();
    flag_mode_toggle->hide();
}

void MineSweeper::reset()
{
    MiniGame::reset();

    for (int x = 0; x < field_size; x++)
    {
        for (int y = 0; y < field_size; y++)
        {
            FieldItem* item = getFieldItem(x, y);
            item
                ->setValue(false)
                ->setText("")
                ->setIcon("")
                ->enable();
            item->bomb = false;
        }
    }

    for (int n = 0; n < bomb_count; n++)
    {
        int x = irandom(0, field_size - 1);
        int y = irandom(0, field_size - 1);

        if (getFieldItem(x, y)->bomb)
        {
            n--;
            continue;
        }

        getFieldItem(x, y)->bomb = true;
    }

    error_count = 0;
    correct_count = 0;
    flag_mode = false;
    flag_mode_toggle
        ->setValue(false)
        ->show();
    attempts_label->show();

    updateAttemptsLabel();
}

float MineSweeper::getProgress()
{
    return static_cast<float>(correct_count) / static_cast<float>(field_size * field_size - bomb_count);
}

void MineSweeper::gameComplete()
{
    bool success = correct_count == (field_size * field_size) - bomb_count;
    parent->onMiniGameComplete(success);
    game_complete = true;
}

glm::vec2 MineSweeper::getBoardSize()
{
    return glm::vec2(field_size * 50, field_size * 50);
}

void MineSweeper::onFieldClick(int x, int y)
{
    FieldItem* item = getFieldItem(x, y);

    // Unpressing an already pressed button, or flagged tile, or game over.
    if (item->getValue()
        || item->getText() == "X"
        || item->getIcon() == "waypoint.png"
        || error_count > 1
        || correct_count == (field_size * field_size - bomb_count)
    ) return;

    item->setValue(true);

    if (item->bomb)
    {
        item
            ->setValue(false)
            ->setText("X");
        error_count++;
        updateAttemptsLabel();
    }
    else
    {
        correct_count++;
        int proximity = 0;
        // Model directions clockwise from top-left.
        int directions[8][2] = {
            {-1, -1}, {-1,  0}, {-1,  1},
            { 0, -1},           { 0,  1},
            { 1, -1}, { 1,  0}, { 1,  1}
        };

        // Increment proximity for each adjacent bomb.
        for (int i = 0; i < 8; i++)
        {
            const int nx = x + directions[i][0];
            const int ny = y + directions[i][1];
            if (nx >= 0 && nx < field_size
                && ny >= 0 && ny < field_size
                && getFieldItem(nx, ny)->bomb
            ) proximity++;
        }

        // Write the number of adjacent bombs into the cell.
        item->setText(proximity > 0
            ? string(proximity)
            : ""
        );

        // If no bombs found in proximity, auto-click all surrounding tiles.
        if (proximity < 1)
        {
            for (int i = 0; i < 8; i++)
            {
                const int nx = x + directions[i][0];
                const int ny = y + directions[i][1];
                if (nx >= 0 && nx < field_size && ny >= 0 && ny < field_size)
                    onFieldClick(nx, ny);
            }
        }
    }

    if (error_count > 1
        || correct_count == (field_size * field_size - bomb_count)
    ) gameComplete();
}

void MineSweeper::onFieldRightClick(int x, int y)
{
    FieldItem* item = getFieldItem(x, y);

    // Don't allow flagging already revealed tiles or revealed bombs.
    if (item->getValue() || item->getText() == "X") return;

    // Don't allow flagging after game is over.
    if (error_count > 1 || correct_count == (field_size * field_size - bomb_count)) return;

    // Toggle flag.
    if (item->getIcon() == "waypoint.png") item->setIcon("");
    else item->setIcon("waypoint.png", sp::Alignment::Center);
}

void MineSweeper::updateAttemptsLabel()
{
    int attempts_remaining = MAX_ATTEMPTS - error_count;
    string attempts_text = static_cast<string>("{remaining}/{max}").format({
        {"remaining", attempts_remaining},
        {"max", MAX_ATTEMPTS}}
    );

    if (difficulty > 1)
        attempts_text = tr("minesweeper", "Attempts: ") + attempts_text;
    else attempts_text = "X: " + attempts_text;

    attempts_label->setText(attempts_text);
}

MineSweeper::FieldItem* MineSweeper::getFieldItem(int x, int y)
{
    return dynamic_cast<MineSweeper::FieldItem*>(board[x * field_size + y]);
}

MineSweeper::FieldItem::FieldItem(GuiContainer* owner, string id, string text, func_t left_func, func_t right_func)
: GuiToggleButton(owner, id, text, nullptr), left_click_func(left_func), right_click_func(right_func)
{
}

bool MineSweeper::FieldItem::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    last_button = button;

    if (button == sp::io::Pointer::Button::Touch)
    {
        touch_count++;
        if (touch_count > peak_touch_count) peak_touch_count = touch_count;
    }

    return true;
}

void MineSweeper::FieldItem::onMouseUp(glm::vec2 position, sp::io::Pointer::ID id)
{
    if (!rect.contains(position)) return;

    sp::io::Pointer::Button button = last_button;

    // Handle touch-only events.
    // One-finger touch = left click, two or more = right click.
    if (button == sp::io::Pointer::Button::Touch)
    {
        touch_count--;
        if (touch_count > 0) return;

        if (peak_touch_count >= 2) button = sp::io::Pointer::Button::Right;
        else button = sp::io::Pointer::Button::Left;

        peak_touch_count = 0;
    }

    if (button == sp::io::Pointer::Button::Left && left_click_func)
    {
        func_t f = left_click_func;
        f(getValue());
    }
    else if (button == sp::io::Pointer::Button::Right && right_click_func)
    {
        func_t f = right_click_func;
        f(getValue());
    }
}
