#pragma once

#include "world.h"

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

bool find_path(struct World *world, const Vector3 start, const Vector3 end);

int path_length_number();

Vector3 node(int i);
