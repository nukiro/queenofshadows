#include "world.h"

#include <raylib.h>
#include <stdio.h>

// Grid settings
#define GRID_SIZE 5
#define TILE_SIZE 1.0f

// Initialize walkable grid with some obstacles
void world_init(struct World *world)
{
    // Make everything walkable first
    for (int x = 0; x < 11; x++)
    {
        for (int y = 0; y < 11; y++)
        {
            world->grid[x][y] = 1;
        }
    }

    world->grid[0][0] = 0;
    world->grid[0][1] = 0;
    world->grid[1][0] = 0;

    world->grid[4][3] = 0;

    world->grid[7][8] = 0;
    world->grid[8][8] = 0;
    world->grid[8][9] = 0;
    world->grid[8][10] = 0;

    world->grid[10][8] = 0;
}

struct World create_world()
{
    return (struct World){};
}

// Check if grid position is valid and walkable
bool is_walkable(struct World *world, int x, int y)
{
    if (x < 0 || x > 10 || y < 0 || y > 10)
        return false;
    return world->grid[x][y] == 1;
}

// Simple pathfinding queue for BFS
typedef struct
{
    int x, y;
    int parent;
} path_node;

// Convert world position to grid coordinates
void world_to_grid(Vector3 worldPos, int *gridX, int *gridY)
{
    if (worldPos.x >= 0)
    {
        *gridX = (int)(worldPos.x / TILE_SIZE + 0.5f) + 5;
    }
    if (worldPos.z >= 0)
    {
        *gridY = (int)(worldPos.z / TILE_SIZE + 0.5f) + 5;
    }

    if (worldPos.x < 0)
    {
        *gridX = (int)(worldPos.x / TILE_SIZE - 0.5f) + 5;
    }
    if (worldPos.z < 0)
    {
        *gridY = (int)(worldPos.z / TILE_SIZE - 0.5f) + 5;
    }
}

// Convert grid coordinates to world position
Vector3 grid_to_world(int gridX, int gridY)
{
    return (Vector3){(gridX * TILE_SIZE) - 5, 0, (gridY * TILE_SIZE) - 5};
}

struct PathTemp
{
    int pathX[11 * 11];
    int pathY[11 * 11];
    int pathLength;
};

// Simple pathfinding using BFS
struct Path find_path(struct World *world, const Vector3 start, const Vector3 end)
{

    struct PathTemp path_temp = {0};

    int startX, startY, endX, endY;

    world_to_grid(start, &startX, &startY);
    world_to_grid(end, &endX, &endY);

    if (!is_walkable(world, endX, endY))
        return (struct Path){0};
    if (startX == endX && startY == endY)
        return (struct Path){0};

    path_node queue[11 * 11];
    bool visited[11][11] = {false};
    int queueStart = 0, queueEnd = 0;

    // Add starting position
    queue[queueEnd] = (path_node){startX, startY, -1};
    visited[startX][startY] = true;
    queueEnd++;

    // Directions: up, down, left, right
    int dx[] = {0, 0, -1, 1};
    int dy[] = {-1, 1, 0, 0};

    while (queueStart < queueEnd)
    {
        path_node current = queue[queueStart];
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
            path_temp.pathLength = pathIndex - 1;
            for (int i = 0; i < path_temp.pathLength; i++)
            {
                path_temp.pathX[i] = tempPathX[path_temp.pathLength - 1 - i];
                path_temp.pathY[i] = tempPathY[path_temp.pathLength - 1 - i];
            }

            // Vector3 nodes[11 * 11];

            for (int i = 0; i < path_temp.pathLength; i++)
            {
                Vector3 v = grid_to_world(path_temp.pathX[i], path_temp.pathY[i]);
                printf("path = x: %f, y: %f, z: %f\n", v.x, v.y, v.z);
            }

            return (struct Path){
                .length = path_temp.pathLength,
                .index = 0,
            };
        }

        // Check all 4 directions
        for (int i = 0; i < 4; i++)
        {
            int newX = current.x + dx[i];
            int newY = current.y + dy[i];

            if (is_walkable(world, newX, newY) && !visited[newX][newY])
            {
                visited[newX][newY] = true;
                queue[queueEnd] = (path_node){newX, newY, queueStart - 1};
                queueEnd++;
            }
        }
    }

    return (struct Path){0}; // No path found
}
