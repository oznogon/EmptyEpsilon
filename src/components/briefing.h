#pragma once

#include "stringImproved.h"
#include <vector>

// Define a page in a Briefing to display on the BriefingScreen.
// If any of these members are defined, then when a BriefingPage is viewed on the BriefingScreen, the screen displays the page's caption and image. If the BriefingScreen's playback mode is enabled, it also plays audio (defined as a file path relative to the resources directory tree) and advances to the next slide automatically after the duration (in seconds) elapses.
class BriefingPage
{
public:
    string caption;
    string image;
    string audio;
    float duration = 0.0f;

    bool operator!=(const BriefingPage& other) const {
        return caption != other.caption || image != other.image || audio != other.audio || duration != other.duration;
    }
};

// Define a Briefing to display on the BriefingScreen.
// A Briefing is a basic presentation defined as a set of BriefingPages. These pages are viewed sequentially on the BriefingScreen.
class Briefing
{
public:
    std::vector<BriefingPage> pages;
};
