#pragma once

#include <raylib.h>

struct Hero
{
    Vector3 position;
    bool is_moving;
};

struct Hero create_hero(const Vector3 at);

void move_hero(struct Hero *hero, const Vector3 target);

void update_hero(struct Hero *hero);