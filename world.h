#pragma once

#include <raylib.h>

struct World
{
    // Walkable grid (1 = walkable, 0 = blocked)
    int grid[11][11];
};

struct World create_world();
void world_init(struct World *world);
void world_to_grid(Vector3 worldPos, int *gridX, int *gridY);
Vector3 grid_to_world(int gridX, int gridY);
bool is_walkable(struct World *world, int x, int y);
int grid_size();
int tile_size();