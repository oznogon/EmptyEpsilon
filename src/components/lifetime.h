#pragma once

#include "script/callback.h"

class LifeTime
{
public:
    float lifetime = 1.0f;
    sp::script::Callback on_expire;
};
