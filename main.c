#include "camera.h"

#include <raylib.h>
#include <raymath.h>
#include <stdlib.h>
#include <stdio.h>

struct Player
{
    char id[50];
    bool traceable;
};

struct FPS
{
    int target;
    double previous_time;    // Previous time measure
    double current_time;     // Current time measure
    double update_draw_time; // Update + Draw time
    double wait_time;        // Wait time (if target fps required)
    float delta_time;        // Frame time (Update + Draw + Wait time)
};

struct Game
{
    char version[50];
    char name[50];
    struct
    {
        int width;
        int heigth;
    } window;
    bool debug;
    struct FPS fps;
};

struct Scene
{
    Color background;
};

void calculate_fps(struct FPS *p)
{
    p->current_time = GetTime();
    p->update_draw_time = p->current_time - p->previous_time;

    if (p->target > 0) // We want a fixed frame rate
    {
        p->wait_time = (1.0f / (float)p->target) - p->update_draw_time;
        if (p->wait_time > 0.0)
        {
            WaitTime((float)p->wait_time);
            p->current_time = GetTime();
            p->delta_time = (float)(p->current_time - p->previous_time);
        }
    }
    else
        p->delta_time = (float)p->update_draw_time; // Framerate could be variable

    p->previous_time = p->current_time;
}

struct Character
{
    Vector3 position;
};

int main(void)
{
    /* Initialization */

    // struct Player player = {"UUID_PLAYER", true};
    struct Game game =
        {
            .version = "v0.0.1",
            .name = "Queen of Shadows",
            .window = {1920, 1080},
            .debug = true,
            .fps = {
                .target = 60,
                .previous_time = GetTime(),
                .current_time = 0.0,
                .update_draw_time = 0.0,
                .wait_time = 0.0,
                .delta_time = 0.0f}};

    InitWindow(game.window.width, game.window.heigth, game.name);
    SetTargetFPS(game.fps.target);

    struct Character hero = {.position = {.0f, 1.0f, .0f}};
    // initialize camema by hero position
    struct Camera camera = create_camera(hero.position);

    while (!WindowShouldClose())
    {
        // Update
        if (game.debug)
            calculate_fps(&game.fps);

        if (IsKeyDown(KEY_W))
            zoom_in_camera(&camera);

        if (IsKeyDown(KEY_S))
            zoom_out_camera(&camera);

        if (IsKeyPressed(KEY_A))
            clockwise_rotate_camera(&camera);

        if (IsKeyPressed(KEY_D))
            counter_clockwise_rotate_camera(&camera);

        update_camera(&camera, hero.position);

        // Drawing

        BeginDrawing();
        ClearBackground((Color){15, 15, 15, 255});

        BeginMode3D(camera.view);

        DrawCube(hero.position, 0.5f, 2.0f, 0.5f, RED);
        DrawCubeWires(hero.position, 0.5f, 2.0f, 0.5f, BLUE);

        DrawGrid(100, 0.25f);

        EndMode3D();

        if (game.debug)
        {
            DrawText(TextFormat("%s %s", game.name, game.version), 10, 10, 10, GREEN);
            DrawText(TextFormat("FPS Current: %i (target: %i)", (int)(1.0f / game.fps.delta_time), game.fps.target), 10, 30, 10, GREEN);
            DrawText(TextFormat("Camara: %s (%.0f)", position_camera(&camera), camera.angle), 10, 45, 10, GREEN);
            DrawText(TextFormat("Hero: %.2f %.2f", hero.position.x, hero.position.z), 10, 60, 10, GREEN);
        }
        EndDrawing();
    }

    CloseWindow();

    return 0;
}