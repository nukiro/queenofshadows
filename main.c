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

enum CamaraPosition
{
    SOUTH = 0,
    WEST = 1,
    NORTH = 2,
    EAST = 3,
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

    // Define the camera to look into our 3d world
    int camara_current_position = SOUTH;

    Vector3 cubePosition = {0.0f, 1.0f, 0.0f};
    Vector3 cubePosition2 = {0.0f, 1.0f, 2.0f};

    bool is_rotating = false;
    int total_frames_rotate = 45;
    int frames_rotate = 0;
    float angle = 0.0f;
    float way = 0.0f;

    Camera3D camera = {0};
    camera.position = (Vector3){15.0f * sin(angle * DEG2RAD), 10.0f, 15.0f * cos(angle * DEG2RAD)}; // Camera position
    camera.target = (Vector3){0.0f, 0.0f, 0.0f};                                                    // Camera looking at point
    camera.up = (Vector3){0.0f, 1.0f, 0.0f};                                                        // Camera up vector (rotation towards target)
    camera.fovy = 45.0f;                                                                            // Camera field-of-view Y
    camera.projection = CAMERA_PERSPECTIVE;                                                         // Camera mode type

    while (!WindowShouldClose())
    {

        if (IsKeyDown(KEY_RIGHT))
        {
            if (!is_rotating)
            {
                if (camara_current_position == EAST)
                {
                    camara_current_position = SOUTH;
                }
                else
                {
                    ++camara_current_position;
                }
                // angle = camara_positions[camara_current_position];
                is_rotating = !is_rotating;
                way = 1.0f;
            }
        }

        if (IsKeyDown(KEY_LEFT))
        {
            if (!is_rotating)
            {
                if (camara_current_position == SOUTH)
                {
                    camara_current_position = EAST;
                }
                else
                {
                    --camara_current_position;
                }
                // angle = camara_positions[camara_current_position];
                is_rotating = !is_rotating;
                way = -1.0f;
            }
        }

        if (is_rotating)
        {
            if (frames_rotate >= total_frames_rotate)
            {
                frames_rotate = 0;
                is_rotating = false;
                if (camara_current_position == SOUTH)
                    angle = 0;
            }
            else
            {
                angle += way * 2;
                camera.position.x = 15.0f * sin(angle * DEG2RAD);
                camera.position.z = 15.0f * cos(angle * DEG2RAD);
                ++frames_rotate;
            }
        }

        BeginDrawing();
        ClearBackground((Color){15, 15, 15, 255});

        if (game.debug) /* game.fps.delta_time != 0 */
        {
            DrawText(TextFormat("%s %s", game.name, game.version), 10, 10, 10, GREEN);
            DrawText(TextFormat("FPS Target: %i", game.fps.target), 10, 25, 10, GREEN);
            DrawText(TextFormat("FPS Current: %i", (int)(1.0f / game.fps.delta_time)), 10, 40, 10, GREEN);
            DrawText(TextFormat("Camara: %i x=%.2f y=%.2f z=%.2f", camara_current_position, camera.position.x, camera.position.y, camera.position.z), 10, 55, 10, GREEN);
            DrawText(TextFormat("Camara Angle: %f", angle), 10, 70, 10, GREEN);
        }

        BeginMode3D(camera);
        DrawCube((Vector3){0.0f, 1.0f, 0.0f}, 0.5f, 2.0f, 0.5f, RED);
        DrawCubeWires((Vector3){0.0f, 1.0f, 0.0f}, 0.5f, 2.0f, 0.5f, BLUE);
        DrawCube((Vector3){2.0f, 2.0f, 0.0f}, 1.5f, 2.0f, 0.5f, WHITE);
        DrawCubeWires((Vector3){2.0f, 2.0f, 0.0f}, 1.5f, 2.0f, 0.5f, BLUE);
        DrawCube((Vector3){-1.0f, 1.0f, 0.0f}, 0.5f, 2.0f, 0.5f, WHITE);
        DrawCubeWires((Vector3){-1.0f, 1.0f, 0.0f}, 0.5f, 2.0f, 0.5f, BLUE);
        DrawSphere((Vector3){-5.0f, 0.0f, 3.0f}, 0.5f, WHITE);
        DrawSphereWires((Vector3){-5.0f, 0.0f, 3.0f}, 0.5f, 8, 8, BLUE);
        DrawGrid(50, 0.25f);

        EndMode3D();

        EndDrawing();

        if (game.debug)
            calculate_fps(&game.fps);
    }

    CloseWindow();

    return 0;
}