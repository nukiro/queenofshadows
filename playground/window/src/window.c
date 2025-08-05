#include "config.h"
#include "renderer.h"
#include "raylib.h"

int run(void)
{
    InitWindow(CONFIG_SCREEN_WIDTH, CONFIG_SCREEN_HEIGHT, CONFIG_TITLE);
    SetTargetFPS(CONFIG_SCREEN_FPS);

    while (!WindowShouldClose())
    {
        BeginDrawing();

        render();

        EndDrawing();
    }

    CloseWindow();

    return 0;
}