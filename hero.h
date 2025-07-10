#pragma once

#include <raylib.h>

struct Hero
{
    Vector3 position;
};

struct Hero create_hero(const Vector2 at);

void move_hero(struct Hero *hero, const Vector3 target);

void update_hero(struct Hero *hero);