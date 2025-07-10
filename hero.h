#pragma once

#include <raylib.h>

struct Hero
{
    Vector3 position;
    bool is_moving;
    float speed;
};

struct Hero create_hero(const Vector3 at);

void move_hero(struct Hero *hero, const Vector3 target, const bool running);

void update_hero(struct Hero *hero);