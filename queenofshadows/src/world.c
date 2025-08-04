#include "world.h"

#include <raylib.h>

// Grid settings
#define GRID_SIZE 5
#define WORLD_SIZE 11
#define TILE_SIZE 1.0f

// Initialize walkable grid with some obstacles
void world_init(struct World *world)
{
    // Make everything walkable first
    for (int x = 0; x < WORLD_SIZE; x++)
    {
        for (int y = 0; y < WORLD_SIZE; y++)
        {
            world->grid[x][y] = 1;
        }
    }

    world->grid[0][0] = 0;
    world->grid[0][1] = 0;
    world->grid[1][0] = 0;

    world->grid[4][3] = 0;
    world->grid[3][4] = 0;

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
    if (x < 0 || x >= WORLD_SIZE || y < 0 || y >= WORLD_SIZE)
        return false;

    return world->grid[x][y] == 1;
}

// Convert world position to grid coordinates
void world_to_grid(Vector3 worldPos, int *gridX, int *gridY)
{
    if (worldPos.x >= 0)
    {
        *gridX = (int)(worldPos.x / TILE_SIZE + 0.5f) + GRID_SIZE;
    }
    if (worldPos.z >= 0)
    {
        *gridY = (int)(worldPos.z / TILE_SIZE + 0.5f) + GRID_SIZE;
    }

    if (worldPos.x < 0)
    {
        *gridX = (int)(worldPos.x / TILE_SIZE - 0.5f) + GRID_SIZE;
    }
    if (worldPos.z < 0)
    {
        *gridY = (int)(worldPos.z / TILE_SIZE - 0.5f) + GRID_SIZE;
    }
}

// Convert grid coordinates to world position
Vector3 grid_to_world(int gridX, int gridY)
{
    return (Vector3){(gridX * TILE_SIZE) - GRID_SIZE, 0, (gridY * TILE_SIZE) - GRID_SIZE};
}

int grid_size()
{
    return GRID_SIZE;
}

int tile_size()
{
    return (int)TILE_SIZE;
}