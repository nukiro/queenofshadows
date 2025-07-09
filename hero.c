#include "hero.h"

#include <raymath.h>

#define SPEED 0.05f

struct Hero create_hero(const Vector2 at)
{
    return (struct Hero){
        .position = (Vector3){.x = at.x, .y = 1.0f, .z = at.y},
    };
}

void update_hero(struct Hero *hero, const Vector2 target)
{
    hero->position = Vector3Lerp(hero->position, (Vector3){target.x, 1.0f, target.y}, SPEED);
}
