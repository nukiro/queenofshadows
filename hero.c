#include "hero.h"

#include <stdio.h>

#include <raylib.h>
#include <raymath.h>

// when it is close enough, stop moving
#define WALKING_DISTANCE_TO_TARGET 0.3f
#define STOPPING_DISTANCE_TO_TARGET 0.05f
#define STOP_SPEED 0.0f
// Walking Speed = 1.5 (m/s) / 60 FPS = 0.025 (m/frame)
#define WALKING_SPEED 0.025f
// Running Speed = 4.5 (m/s) / 60 FPS = 0.075 (m/frame)
#define RUNNING_SPEED 0.075f

Vector3 target = {0};

struct Hero create_hero(const Vector3 at)
{
    return (struct Hero){
        .position = (Vector3){.x = at.x, .y = 1.0f, .z = at.z},
        .is_moving = false,
        .speed = STOP_SPEED,
    };
}

bool on_target_hero(const Vector3 position, const Vector3 target, const float distance)
{
    return fabsf(position.x - target.x) < distance && fabsf(position.z - target.z) < distance;
}

bool is_running_hero(const struct Hero *hero)
{
    return hero->speed == RUNNING_SPEED;
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
        hero->position = Vector3Add(hero->position, Vector3Scale(direction, hero->speed));

        // If we're close enough to target and the hero is running, walk to make the stop animation softer
        if (is_running_hero(hero) && on_target_hero(hero->position, target, WALKING_DISTANCE_TO_TARGET))
            hero->speed = WALKING_SPEED;

        // If we're close enough to target, stop moving
        if (on_target_hero(hero->position, target, STOPPING_DISTANCE_TO_TARGET))
        {
            hero->is_moving = false;
            hero->speed = STOP_SPEED;
        }
    }
}

void move_hero(struct Hero *hero, const Vector3 to, const bool running)
{
    hero->is_moving = true;
    hero->speed = running ? RUNNING_SPEED : WALKING_SPEED;
    target = to;
}
