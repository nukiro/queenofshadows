#include <raylib.h>
#include <stdlib.h>
#include <stdio.h>

const Vector2 screen_size = {1920, 1080};
#define NEARBLACK CLITERAL(Color){15, 15, 15, 255}

int main(void)
{
    InitWindow(screen_size.x, screen_size.y, "Queen of Shadows");

    SetTargetFPS(60);

    while (!WindowShouldClose())
    {
        BeginDrawing();
        ClearBackground(NEARBLACK);

        EndDrawing();
    }

    CloseWindow();

    return 0;
}