#include "logging.h"
#include "camera.h"
#include "world.h"
#include "hero.h"
#include "game.h"

#include <raylib.h>
#include <raymath.h>
#include <stdlib.h>
#include <stdio.h>

#define DOUBLE_CLICK_TIME 0.5f

struct Player
{
    char id[50];
    bool traceable;
};

int trace(const struct Player *player)
{
    return player->traceable ? INFO : ERROR;
}

bool double_click(bool *first_click, float *last_click_time)
{
    float current_time = GetTime();
    bool is_double_click = false;

    // Check for double-click
    if (first_click && (current_time - *last_click_time) <= DOUBLE_CLICK_TIME)
    {
        is_double_click = true;
        *first_click = false;
    }
    else
    {
        *first_click = true;
    }

    *last_click_time = current_time;

    return is_double_click;
}

// Double-click detection variables
static float last_click_time = 0.0f;
static bool first_click = false;

int main(void)
{
    /* Initialization */
    struct Player player = {"UUID_PLAYER", true};
    struct Game game = create_game();
    struct Logger logger = create_logger(game.debug ? DEBUG : trace(&player));

    info(&logger, "Initializating...");

    // if setup fails return error
    if (!setup_game(&game, &logger))
    {
        return 0;
    }

    info(&logger, "Running...");

    InitWindow(game.window.width, game.window.heigth, game.name);

    SetTargetFPS(game.target_fps);

    struct World world = create_world();
    world_init(&world);

    struct Hero hero = create_hero((Vector3){.0f, .0f, 0.f});
    // initialize camera by hero position
    struct Camera camera = create_camera(hero.position);

    while (!WindowShouldClose())
    {
        // float _ = GetFrameTime();
        // printf("%f %f\n", hero.position.x, hero.position.z);

        // Action Input
        if (IsMouseButtonPressed(MOUSE_LEFT_BUTTON))
        {
            // From mouse position, generate a ray
            Vector3 ray = raycast_camera(&camera, GetMousePosition());
            if (find_path(&world, hero.position, ray))
                move_hero(&hero, ray, double_click(&first_click, &last_click_time));
        }

        // Camera Input
        if (IsKeyDown(KEY_W))
            zoom_in_camera(&camera);

        if (IsKeyDown(KEY_S))
            zoom_out_camera(&camera);

        if (IsKeyPressed(KEY_A))
            clockwise_rotate_camera(&camera);

        if (IsKeyPressed(KEY_D))
            counter_clockwise_rotate_camera(&camera);

        update_hero(&hero);
        update_camera(&camera, hero.position);

        // Drawing

        BeginDrawing();
        ClearBackground((Color){15, 15, 15, 255});

        BeginMode3D(camera.view);

        DrawCube(hero.position, 0.5f, 2.0f, 0.5f, RED);
        DrawCubeWires(hero.position, 0.5f, 2.0f, 0.5f, BLUE);

        DrawGrid(22, 0.5f);

        // Draw 3D walkable grid
        for (int x = -1 * grid_size(); x < grid_size() + 1; x++)
        {
            for (int z = -1 * grid_size(); z < grid_size() + 1; z++)
            {
                Vector3 position = {x * tile_size(), 0.0f, z * tile_size()};
                Color tileColor;

                int vx, vy;
                world_to_grid(position, &vx, &vy);

                if (is_walkable(&world, vx, vy) == 1)
                {
                    tileColor = ((x + z) % 2 == 0) ? (Color){100, 100, 100, 200} : (Color){120, 120, 120, 200};
                    DrawCube(position, tile_size() * 0.95f, 0.0f, tile_size() * 0.95f, tileColor);
                    DrawCubeWires(position, tile_size(), 0.0f, tile_size(), LIGHTGRAY);
                }
            }
        }

        // Draw path
        for (int i = 0; i < path_length_number(); i++)
        {
            Vector3 pathPos = node(i);
            pathPos.y = 0.1f;
            // Color pathColor = (i <= currentPathIndex) ? GREEN : YELLOW;
            DrawCube(pathPos, 0.3f, 0.2f, 0.3f, YELLOW);
        }

        EndMode3D();

        if (game.debug)
        {
            DrawText(TextFormat("%s %s", game.name, game.version), 10, 10, 10, GREEN);
            DrawText(TextFormat("%s (%.0f)", position_camera(&camera), camera.angle), 10, 30, 10, GREEN);
            DrawText(TextFormat("Hero: %.2f %.2f", hero.position.x, hero.position.z), 10, 45, 10, GREEN);
        }
        EndDrawing();
    }

    CloseWindow();

    return 0;
}