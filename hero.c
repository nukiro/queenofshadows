#include "hero.h"

#include <stdio.h>

#include <raylib.h>
#include <raymath.h>

// Walking speed = 1.5 (m/s) / 60 FPS = 0.025 (m/frame)
#define SPEED 0.025f

Vector3 target = {0};

struct Hero create_hero(const Vector3 at)
{
    return (struct Hero){
        .position = (Vector3){.x = at.x, .y = 1.0f, .z = at.z},
        .is_moving = false,
    };
}

void update_hero(struct Hero *hero)
{
    // this check avoids calculation when the player do not click
    if (hero->is_moving)
    {
        // Calculate direction vector (only X and Z, keep Y constant)
        Vector3 direction = Vector3Subtract(target, hero->position);
        direction.y = 0; // Keep player on ground level
        direction = Vector3Normalize(direction);

        // Move player
        hero->position = Vector3Add(hero->position, Vector3Scale(direction, SPEED));

        // If we're close enough to target, stop moving
        if (fabsf(hero->position.x - target.x) < 0.05f && fabsf(hero->position.z - target.z) < 0.05f)
            hero->is_moving = false;
    }
}

void move_hero(struct Hero *hero, const Vector3 to)
{
    hero->is_moving = true;
    target = to;
}
