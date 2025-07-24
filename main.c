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

// Grid settings
#define GRID_SIZE 5
#define TILE_SIZE 1.0f

// Walkable grid (1 = walkable, 0 = blocked)
int walkableGrid[11][11];

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

// Initialize walkable grid with some obstacles
void InitWalkableGrid()
{
    // Make everything walkable first
    for (int x = 0; x < 11; x++)
    {
        for (int y = 0; y < 11; y++)
        {
            walkableGrid[x][y] = 1;
        }
    }

    walkableGrid[0][0] = 0;
    walkableGrid[0][1] = 0;
    walkableGrid[1][0] = 0;

    walkableGrid[4][3] = 0;

    walkableGrid[7][8] = 0;
    walkableGrid[8][8] = 0;
    walkableGrid[8][9] = 0;
    walkableGrid[8][10] = 0;

    walkableGrid[10][8] = 0;
}

// Convert world position to grid coordinates
void NormalizeWorldToGrid(Vector3 worldPos, int *gridX, int *gridY)
{
    if (worldPos.x >= 0)
    {
        *gridX = (int)(worldPos.x / TILE_SIZE + 0.5f);
    }
    if (worldPos.z >= 0)
    {
        *gridY = (int)(worldPos.z / TILE_SIZE + 0.5f);
    }

    if (worldPos.x < 0)
    {
        *gridX = (int)(worldPos.x / TILE_SIZE - 0.5f);
    }
    if (worldPos.z < 0)
    {
        *gridY = (int)(worldPos.z / TILE_SIZE - 0.5f);
    }
}

void WorldToGrid(int *x, int *y, const int tx, const int ty)
{
    *x = tx + 5;
    *y = ty + 5;
}

// Convert grid coordinates to world position
Vector3 GridToWorld(int gridX, int gridY)
{
    return (Vector3){(gridX * TILE_SIZE) - 5, 0, (gridY * TILE_SIZE) - 5};
    // return (Vector3){gridX * TILE_SIZE, 0, gridY * TILE_SIZE};
}

// Check if grid position is valid and walkable
bool IsWalkable(int x, int y)
{
    if (x < 0 || x > 10 || y < 0 || y > 10)
        return false;
    return walkableGrid[x][y] == 1;
}

// Simple pathfinding queue for BFS
typedef struct
{
    int x, y;
    int parent;
} PathNode;

// Simple pathfinding using BFS
bool FindPath(int startX, int startY, int endX, int endY, int *pathX, int *pathY, int *pathLength)
{
    if (!IsWalkable(endX, endY))
        return false;
    if (startX == endX && startY == endY)
        return false;

    PathNode queue[11 * 11];
    bool visited[11][11] = {false};
    int queueStart = 0, queueEnd = 0;

    // Add starting position
    queue[queueEnd] = (PathNode){startX, startY, -1};
    visited[startX][startY] = true;
    queueEnd++;

    // Directions: up, down, left, right
    int dx[] = {0, 0, -1, 1};
    int dy[] = {-1, 1, 0, 0};

    while (queueStart < queueEnd)
    {
        PathNode current = queue[queueStart];
        queueStart++;

        // Found target
        if (current.x == endX && current.y == endY)
        {
            // Reconstruct path
            int pathIndex = 0;
            int nodeIndex = queueStart - 1;

            // Build path backwards
            int tempPathX[11 * 11];
            int tempPathY[11 * 11];

            while (nodeIndex != -1)
            {
                tempPathX[pathIndex] = queue[nodeIndex].x;
                tempPathY[pathIndex] = queue[nodeIndex].y;
                pathIndex++;
                nodeIndex = queue[nodeIndex].parent;
            }

            // Reverse path (skip start position)
            *pathLength = pathIndex - 1;
            for (int i = 0; i < *pathLength; i++)
            {
                pathX[i] = tempPathX[*pathLength - 1 - i];
                pathY[i] = tempPathY[*pathLength - 1 - i];
            }

            return true;
        }

        // Check all 4 directions
        for (int i = 0; i < 4; i++)
        {
            int newX = current.x + dx[i];
            int newY = current.y + dy[i];

            if (IsWalkable(newX, newY) && !visited[newX][newY])
            {
                visited[newX][newY] = true;
                queue[queueEnd] = (PathNode){newX, newY, queueStart - 1};
                queueEnd++;
            }
        }
    }

    return false; // No path found
}

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

    // Initialize walkable grid
    InitWalkableGrid();

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
            printf("our mouse = x: %f, y: %f, z: %f\n", ray.x, ray.y, ray.z);

            // Vector3 mouseWorldPos = GetMouseWorldPosition(camera.view);
            // printf("vs mouse = x: %f, y: %f, z: %f\n", mouseWorldPos.x, mouseWorldPos.y, mouseWorldPos.z);

            int targetGridX, targetGridY;
            NormalizeWorldToGrid(ray, &targetGridX, &targetGridY);
            printf("normalize grid = x: %d, y = %d\n", targetGridX, targetGridY);

            int vx, vy;
            WorldToGrid(&vx, &vy, targetGridX, targetGridY);
            printf("walkable grid = x: %d, y = %d\n", vx, vy);

            Vector3 pos = GridToWorld(targetGridX, targetGridY);
            printf("to move hero = x: %f, y: %f, z: %f\n", pos.x, pos.y, pos.z);

            if (IsWalkable(vx, vy))
            {
                // Find path to clicked position
                int hx, hy;
                int phx, phy;
                NormalizeWorldToGrid(hero.position, &phx, &phy);
                WorldToGrid(&hx, &hy, phx, phy);
                if (FindPath(hx, hy, vx, vy,
                             pathX, pathY, &pathLength))
                {
                    printf("---\n");
                    printf("path found: %d\n", pathLength);
                    for (int i = 0; i < pathLength; i++)
                    {
                        Vector3 v = GridToWorld(pathX[i], pathY[i]);
                        printf("path = x: %f, y: %f, z: %f\n", v.x, v.y, v.z);
                    }
                    printf("---\n");
                }
            }

            find_path(&world, hero.position, ray);
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
        for (int x = -1 * GRID_SIZE; x < GRID_SIZE + 1; x++)
        {
            for (int z = -1 * GRID_SIZE; z < GRID_SIZE + 1; z++)
            {
                Vector3 position = {x * TILE_SIZE, 0.0f, z * TILE_SIZE};
                Color tileColor;

                int vx, vy;
                WorldToGrid(&vx, &vy, x, z);

                if (walkableGrid[vx][vy] == 0)
                {
                    tileColor = RED; // Blocked tile
                    DrawCube(position, (TILE_SIZE / 2) * 0.95f, 0.0f, (TILE_SIZE / 2) * 0.95f, tileColor);
                    DrawCubeWires(position, (TILE_SIZE / 2), 0.0f, (TILE_SIZE / 2), LIGHTGRAY);
                }
                else
                {
                    tileColor = ((x + z) % 2 == 0) ? (Color){100, 100, 100, 200} : (Color){120, 120, 120, 200};
                    DrawCube(position, TILE_SIZE * 0.95f, 0.0f, TILE_SIZE * 0.95f, tileColor);
                    DrawCubeWires(position, TILE_SIZE, 0.0f, TILE_SIZE, LIGHTGRAY);
                }
            }
        }

        // Draw path
        for (int i = 0; i < pathLength; i++)
        {
            Vector3 pathPos = GridToWorld(pathX[i], pathY[i]);
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