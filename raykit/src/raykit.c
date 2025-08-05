#include "raylib.h"
#include "raykit.h"

#include "window/renderer.h"

int raykit_run(void)
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