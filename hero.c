#include "hero.h"

#include <raylib.h>
#include <raymath.h>

#define SPEED 0.05f

bool is_moving = false;
Vector3 target = {0};

struct Hero create_hero(const Vector2 at)
{
    return (struct Hero){
        .position = (Vector3){.x = at.x, .y = 1.0f, .z = at.y},
    };
}

void update_hero(struct Hero *hero)
{
    if (is_moving)
    {
        hero->position = Vector3Lerp(hero->position, (Vector3){target.x, 1.0f, target.z}, SPEED);

        if (hero->position.x == target.x && hero->position.z == target.y)
        {
            is_moving = false;
        }
    }
}

void move_hero(struct Hero *hero, const Vector3 to)
{
    is_moving = true;
    target = to;
}
