#include "playerInfo.h"
#include "spaceObjects/playerSpaceship.h"
#include "shipsLogControl.h"

#include "gui/gui2_panel.h"
#include "gui/gui2_advancedscrolltext.h"

ShipsLog::ShipsLog(GuiContainer* owner)
: GuiElement(owner, ""), open(false), log_text(new GuiAdvancedScrollText(this, ""))
{
    setPosition(0, 0, sp::Alignment::BottomCenter);
    setSize(GuiElement::GuiSizeMax, 50);
    setMargins(20, 0);

    log_text
        ->enableAutoScrollDown()
        ->setMargins(15, 4, 15, 0)
        ->setPosition(0, 0)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
}

void ShipsLog::onDraw(sp::RenderTarget& renderer)
{
    renderer.drawStretchedHV(sp::Rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y + 100), 25.0f, "gui/widget/PanelBackground.png");

    if (!my_spaceship)
        return;

    const std::vector<PlayerSpaceship::ShipLogEntry>& logs = my_spaceship->getShipsLog();
    const unsigned int log_entry_count = logs.size();

    if (log_text->getEntryCount() > 0 && log_entry_count == 0) {
        log_text->clearEntries();
}

    if (open)
    {
        // If expanded, display all entries.

        // If the scroll text element has more entries than the ship's log,
        // prune the top entries from the scroll text element until its count
        // is equal to the log's.
        while (log_text->getEntryCount() > log_entry_count) {
            log_text->removeEntry(0);
}

        // If the scroll and log have entries, and the first scroll entry isn't
        // the earliest log entry, update the scroll.
        if (log_text->getEntryCount() > 0
            && log_entry_count > 0
            && log_text->getEntryPrefix(0) != logs[0].prefix
            && log_text->getEntryText(0) != logs[0].text)
        {
            bool updated = false;

            for (unsigned int n = 1; n < log_text->getEntryCount(); n++)
            {
                if (log_text->getEntryPrefix(n) == logs[0].prefix
                    && log_text->getEntryText(n) == logs[0].text)
                {
                    for (unsigned int m = 0; m < n; m++)
                    {
                        log_text->removeEntry(0);
                    }

                    updated = true;
                    break;
                }
            }

            if (!updated)
            {
                log_text->clearEntries();
            }
        }

        while (log_text->getEntryCount() < log_entry_count)
        {
            const unsigned int n = log_text->getEntryCount();
            log_text->addEntry(logs[n].prefix, logs[n].text, logs[n].color);
        }
    }
    else
    {
        // If minimized, display only the first entry.
        if (log_text->getEntryCount() > 0 && log_entry_count > 0)
        {
            if (log_text->getEntryPrefix(0) != logs.back().prefix
                || log_text->getEntryText(0) != logs.back().text)
            {
                log_text->clearEntries();
            }
        }

        if (log_text->getEntryCount() == 0 && log_entry_count > 0)
        {
            log_text->addEntry(logs.back().prefix, logs.back().text, logs.back().color);
        }
    }
}

bool ShipsLog::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    open = !open;

    if (open)
    {
        setSize(getSize().x, 800.0F);
    }
    else
    {
        setSize(getSize().x, 50.0F);
    }

    return true;
}
