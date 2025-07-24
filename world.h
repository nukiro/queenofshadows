#pragma once

#include <raylib.h>

struct World {
    // Walkable grid (1 = walkable, 0 = blocked)
    int grid[11][11];
};

struct Path {
    Vector3 nodes[11*11];
    int length;
    int index;
};

struct World create_world();
void world_init(struct World *world);
struct Path find_path(struct World *world, const Vector3 start, const Vector3 end);