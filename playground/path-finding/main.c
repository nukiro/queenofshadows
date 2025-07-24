#include "raylib.h"
#include "raymath.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Screen settings
#define SCREEN_WIDTH 1980
#define SCREEN_HEIGHT 1080

// Grid settings
#define GRID_SIZE 20
#define TILE_SIZE 1.0f

// Character structure
typedef struct
{
    Vector3 position;
    Vector3 targetPosition;
    int gridX, gridY;
    int targetGridX, targetGridY;
    bool isMoving;
    float moveSpeed;
} Character;

// Walkable grid (1 = walkable, 0 = blocked)
int walkableGrid[GRID_SIZE][GRID_SIZE];

// Simple pathfinding queue for BFS
typedef struct
{
    int x, y;
    int parent;
} PathNode;

// Initialize walkable grid with some obstacles
void InitWalkableGrid()
{
    // Make everything walkable first
    for (int x = 0; x < GRID_SIZE; x++)
    {
        for (int y = 0; y < GRID_SIZE; y++)
        {
            walkableGrid[x][y] = 1;
        }
    }

    // Add some obstacles
    walkableGrid[5][5] = 0;
    walkableGrid[5][6] = 0;
    walkableGrid[6][5] = 0;
    walkableGrid[6][6] = 0;

    walkableGrid[10][8] = 0;
    walkableGrid[11][8] = 0;
    walkableGrid[12][8] = 0;

    walkableGrid[15][15] = 0;
    walkableGrid[16][15] = 0;
    walkableGrid[15][16] = 0;
}

// Check if grid position is valid and walkable
bool IsWalkable(int x, int y)
{
    if (x < 0 || x >= GRID_SIZE || y < 0 || y >= GRID_SIZE)
        return false;
    return walkableGrid[x][y] == 1;
}

// Convert screen mouse position to world position using raycasting
Vector3 GetMouseWorldPosition(Camera3D camera)
{
    Ray ray = GetMouseRay(GetMousePosition(), camera);

    // Create a plane at Y=0 (ground level)
    Vector3 planePoint = {0, 0, 0};
    Vector3 planeNormal = {0, 1, 0};

    // Calculate intersection with ground plane
    float t = -(Vector3DotProduct(Vector3Subtract(ray.position, planePoint), planeNormal)) /
              Vector3DotProduct(ray.direction, planeNormal);

    if (t >= 0)
    {
        return Vector3Add(ray.position, Vector3Scale(ray.direction, t));
    }

    return (Vector3){-1, -1, -1}; // Invalid position
}

// Convert world position to grid coordinates
void WorldToGrid(Vector3 worldPos, int *gridX, int *gridY)
{
    *gridX = (int)(worldPos.x / TILE_SIZE + 0.5f);
    *gridY = (int)(worldPos.z / TILE_SIZE + 0.5f);
}

// Convert grid coordinates to world position
Vector3 GridToWorld(int gridX, int gridY)
{
    return (Vector3){gridX * TILE_SIZE, 0, gridY * TILE_SIZE};
}

// Simple pathfinding using BFS
bool FindPath(int startX, int startY, int endX, int endY, int *pathX, int *pathY, int *pathLength)
{
    if (!IsWalkable(endX, endY))
        return false;
    if (startX == endX && startY == endY)
        return false;

    PathNode queue[GRID_SIZE * GRID_SIZE];
    bool visited[GRID_SIZE][GRID_SIZE] = {false};
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
            int tempPathX[GRID_SIZE * GRID_SIZE];
            int tempPathY[GRID_SIZE * GRID_SIZE];

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
    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Isometric Grid (3D Camera)");

    // Initialize walkable grid
    InitWalkableGrid();

    // Create 3D camera
    // Isometric view
    Camera3D camera = {0};
    camera.position = (Vector3){50.0f, 50.0f, 50.0f};
    camera.target = (Vector3){0.0f, 0.0f, 0.0f};
    camera.up = (Vector3){0.0f, 1.0f, 0.0f};
    camera.fovy = 45.0f;
    camera.projection = CAMERA_PERSPECTIVE;

    // Initialize character
    Character character = {0};
    character.position = GridToWorld(1, 1);
    character.targetPosition = character.position;
    character.gridX = 1;
    character.gridY = 1;
    character.targetGridX = 1;
    character.targetGridY = 1;
    character.isMoving = false;
    character.moveSpeed = 3.0f;

    // Path variables
    int pathX[GRID_SIZE * GRID_SIZE];
    int pathY[GRID_SIZE * GRID_SIZE];
    int pathLength = 0;
    int currentPathIndex = 0;

    SetTargetFPS(60);

    while (!WindowShouldClose())
    {
        float deltaTime = GetFrameTime();

        // Handle mouse click for movement
        if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT))
        {
            Vector3 mouseWorldPos = GetMouseWorldPosition(camera);
            printf("mouse = x: %f, y: %f, z: %f\n", mouseWorldPos.x, mouseWorldPos.y, mouseWorldPos.z);

            if (mouseWorldPos.x >= 0)
            { // Valid world position
                int targetGridX, targetGridY;
                WorldToGrid(mouseWorldPos, &targetGridX, &targetGridY);
                printf("grid = x: %d, y = %d\n", targetGridX, targetGridY);

                // Find path to clicked position
                if (FindPath(character.gridX, character.gridY, targetGridX, targetGridY,
                             pathX, pathY, &pathLength))
                {
                    currentPathIndex = 0;
                    character.isMoving = true;
                    character.targetGridX = pathX[0];
                    character.targetGridY = pathY[0];
                    character.targetPosition = GridToWorld(character.targetGridX, character.targetGridY);
                    printf("target = x: %f, y: %f, z: %f\n", character.targetPosition.x, character.targetPosition.y, character.targetPosition.z);
                }
            }
        }

        // Update character movement
        if (character.isMoving)
        {
            Vector3 direction = Vector3Subtract(character.targetPosition, character.position);
            float distance = Vector3Length(direction);

            if (distance < 0.1f)
            {
                // Reached current target
                character.position = character.targetPosition;
                character.gridX = character.targetGridX;
                character.gridY = character.targetGridY;

                // Move to next path point
                currentPathIndex++;
                if (currentPathIndex < pathLength)
                {
                    character.targetGridX = pathX[currentPathIndex];
                    character.targetGridY = pathY[currentPathIndex];
                    character.targetPosition = GridToWorld(character.targetGridX, character.targetGridY);
                }
                else
                {
                    character.isMoving = false;
                }
            }
            else
            {
                // Move towards target
                Vector3 moveVector = Vector3Scale(Vector3Normalize(direction),
                                                  character.moveSpeed * deltaTime);
                character.position = Vector3Add(character.position, moveVector);
            }
        }

        BeginDrawing();
        ClearBackground(DARKGRAY);

        BeginMode3D(camera);

        // Draw 3D grid
        for (int x = 0; x < GRID_SIZE; x++)
        {
            for (int z = 0; z < GRID_SIZE; z++)
            {
                Vector3 position = {x * TILE_SIZE, 0.0f, z * TILE_SIZE};

                Color tileColor;
                if (walkableGrid[x][z] == 0)
                {
                    tileColor = RED; // Blocked tile
                }
                else
                {
                    tileColor = ((x + z) % 2 == 0) ? (Color){100, 100, 100, 200} : (Color){120, 120, 120, 200};
                }

                DrawCube(position, TILE_SIZE * 0.95f, 0.05f, TILE_SIZE * 0.95f, tileColor);
                DrawCubeWires(position, TILE_SIZE, 0.05f, TILE_SIZE, LIGHTGRAY);
            }
        }

        // Draw path
        for (int i = 0; i < pathLength; i++)
        {
            Vector3 pathPos = GridToWorld(pathX[i], pathY[i]);
            pathPos.y = 0.1f;
            Color pathColor = (i <= currentPathIndex) ? GREEN : YELLOW;
            DrawCube(pathPos, 0.3f, 0.2f, 0.3f, pathColor);
        }

        // Draw character
        Vector3 charPos = character.position;
        charPos.y = 0.5f;
        DrawCube(charPos, 0.8f, 1.0f, 0.8f, BLUE);
        DrawCubeWires(charPos, 0.8f, 1.0f, 0.8f, DARKBLUE);

        // Draw mouse hover position
        Vector3 mouseWorldPos = GetMouseWorldPosition(camera);
        if (mouseWorldPos.x >= 0)
        {
            int hoverGridX, hoverGridY;
            WorldToGrid(mouseWorldPos, &hoverGridX, &hoverGridY);

            if (IsWalkable(hoverGridX, hoverGridY))
            {
                Vector3 hoverPos = GridToWorld(hoverGridX, hoverGridY);
                hoverPos.y = 0.2f;
                DrawCube(hoverPos, 0.9f, 0.1f, 0.9f, (Color){255, 255, 0, 100});
            }
        }

        EndMode3D();

        // Draw UI
        DrawText("Left Click: Move character", 10, 10, 20, WHITE);
        DrawText("WASD/Arrows: Camera controls", 10, 35, 20, WHITE);
        DrawText("Mouse Wheel: Zoom", 10, 60, 20, WHITE);
        DrawText(TextFormat("Character: Grid(%d,%d)", character.gridX, character.gridY), 10, 85, 20, WHITE);
        DrawText(character.isMoving ? "Moving..." : "Idle", 10, 110, 20,
                 character.isMoving ? GREEN : WHITE);

        EndDrawing();
    }

    CloseWindow();
    return 0;
}