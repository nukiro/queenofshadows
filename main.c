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

    struct Player player = {"UUID_PLAYER", true};
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

    struct Character hero = {.position = {5.0f, 1.0f, 4.0f}};
    struct Camera camera = create_camera(hero.position);

    while (!WindowShouldClose())
    {

        if (IsKeyDown(KEY_UP))
            zoom_in_camera(&camera);

        if (IsKeyDown(KEY_DOWN))
            zoom_out_camera(&camera);

        if (IsKeyPressed(KEY_LEFT))
            clockwise_rotation_camera(&camera);

        if (IsKeyPressed(KEY_RIGHT))
            counter_clockwise_rotation_camera(&camera);

        calculate_angle_camera(&camera);
        calculate_position_camera(&camera, hero.position);

        BeginDrawing();
        ClearBackground((Color){15, 15, 15, 255});

        BeginMode3D(camera.instance);
        DrawCube(hero.position, 0.5f, 2.0f, 0.5f, RED);
        DrawCubeWires(hero.position, 0.5f, 2.0f, 0.5f, BLUE);
        DrawCube((Vector3){2.0f, 2.0f, 0.0f}, 1.5f, 2.0f, 0.5f, WHITE);
        DrawCubeWires((Vector3){2.0f, 2.0f, 0.0f}, 1.5f, 2.0f, 0.5f, BLUE);
        DrawCube((Vector3){-1.0f, 1.0f, 0.0f}, 0.5f, 2.0f, 0.5f, WHITE);
        DrawCubeWires((Vector3){-1.0f, 1.0f, 0.0f}, 0.5f, 2.0f, 0.5f, BLUE);
        DrawSphere((Vector3){-5.0f, 0.0f, 3.0f}, 0.5f, WHITE);
        DrawSphereWires((Vector3){-5.0f, 0.0f, 3.0f}, 0.5f, 16, 16, BLUE);
        DrawCube((Vector3){.0f, 5.0f, 15.0f}, 20.0f, 10.0f, 10.0f, BEIGE);
        DrawCubeWires((Vector3){.0f, 5.0f, 15.0f}, 20.0f, 10.0f, 10.0f, BLUE);
        DrawCube((Vector3){-10.0f, 7.5f, 15.0f}, 5.0f, 15.0f, 5.0f, BROWN);
        DrawCubeWires((Vector3){-10.0f, 7.5f, 15.0f}, 5.0f, 15.0f, 5.0f, BLUE);
        DrawCube((Vector3){10.0f, 7.5f, 15.0f}, 5.0f, 15.0f, 5.0f, BROWN);
        DrawCubeWires((Vector3){10.0f, 7.5f, 15.0f}, 5.0f, 15.0f, 5.0f, BLUE);
        DrawCube((Vector3){.0f, 9.f, 18.0f}, 5.0f, 20.0f, 5.0f, BROWN); // main tower
        DrawCubeWires((Vector3){.0f, 9.f, 18.0f}, 5.0f, 20.0f, 5.0f, BLUE);
        // DrawPlane((Vector3){.0f, .0f, .0f}, (Vector2){100.f, 100.0f}, DARKGRAY);

        DrawGrid(150, 0.25f);

        EndMode3D();

        if (game.debug) /* game.fps.delta_time != 0 */
        {
            DrawText(TextFormat("%s %s", game.name, game.version), 10, 10, 10, GREEN);
            DrawText(TextFormat("FPS Target: %i", game.fps.target), 10, 25, 10, GREEN);
            DrawText(TextFormat("FPS Current: %i", (int)(1.0f / game.fps.delta_time)), 10, 40, 10, GREEN);
            DrawText(TextFormat("Camara: %i x=%.2f y=%.2f z=%.2f", camera.step, camera.instance.position.x, camera.instance.position.y, camera.instance.position.z), 10, 55, 10, GREEN);
            DrawText(TextFormat("Camara Angle: %f", camera.angle), 10, 70, 10, GREEN);
            DrawText(TextFormat("Hero: x=%.2f y=%.2f z=%.2f", hero.position.x, hero.position.y, hero.position.z), 10, 85, 10, GREEN);
        }
        EndDrawing();

        if (game.debug)
            calculate_fps(&game.fps);
    }

    CloseWindow();

    return 0;
}