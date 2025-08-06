#include "raylib.h"
#include "raykit.h"

#include "window/renderer.h"

int raykit_run(void)
{
    InitWindow(CONFIG_SCREEN_WIDTH, CONFIG_SCREEN_HEIGHT, CONFIG_TITLE);
    SetTargetFPS(CONFIG_SCREEN_FPS);

    // Define the camera to look into our 3d world
    Camera3D camera = {0};
    camera.position = (Vector3){0.0f, 10.0f, 10.0f}; // Camera position
    camera.target = (Vector3){0.0f, 0.0f, 0.0f};     // Camera looking at point
    camera.up = (Vector3){0.0f, 1.0f, 0.0f};         // Camera up vector (rotation towards target)
    camera.fovy = 45.0f;                             // Camera field-of-view Y
    camera.projection = CAMERA_PERSPECTIVE;          // Camera mode type

    // Vector3 cubePosition = {0.0f, 0.0f, 0.0f};

    // Main game loop
    while (!WindowShouldClose())
    {
        float _ = GetFrameTime();

        // Update

        // Draw
        BeginDrawing();

        render(&camera);

        EndDrawing();
    }

    // Cleanup
    CloseWindow();

    return 0;
}