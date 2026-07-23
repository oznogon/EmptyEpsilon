#pragma once

#include "gui2_element.h"
#include "gui2_scrollbar.h"

class GuiEntryList : public GuiElement
{
public:
    typedef std::function<void(int index, string value)> func_t;

protected:
    class GuiEntry
    {
    public:
        string name;
        string value;
        string icon_name = "";
        GuiEntry(string name, string value) : name(name), value(value) {}
        GuiEntry(string name, string value, string icon_name) : name(name), value(value), icon_name(icon_name) {}
    };

    std::vector<GuiEntry> entries;
    int selection_index = -1;
    func_t func;
    bool sort_by_name = false;
public:
    GuiEntryList(GuiContainer* owner, string id, func_t func);

    GuiEntryList* setOptions(const std::vector<string>& options);
    GuiEntryList* setOptions(const std::vector<string>& options, const std::vector<string>& values);

    virtual void setEntryName(int index, string name);
    virtual void setEntryValue(int index, string value);
    virtual void setEntryIcon(int index, string icon_name);
    virtual void setEntry(int index, string name, string value);

    virtual int addEntry(string name, string value);
    int indexByValue(string value) const;
    virtual void removeEntry(int index);
    virtual void clear();
    int entryCount() const;
    string getEntryName(int index) const;
    string getEntryValue(int index) const;
    string getEntryIcon(int index) const;

    int getSelectionIndex() const;
    GuiEntryList* setSelectionIndex(int index);
    string getSelectionValue() const;

    void sortEntries();
    GuiEntryList* setSortByName(bool enable);
    bool getSortByName() const;
protected:
    void callback();
private:
    virtual void entriesChanged();
};
