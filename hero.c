#include "hero.h"
#include "world.h"

#include <stdio.h>

#include <raylib.h>
#include <raymath.h>

#define WORLD_SIZE 11

// when it is close enough, stop moving
#define WALKING_DISTANCE_TO_TARGET 0.3f
#define STOPPING_DISTANCE_TO_TARGET 0.05f
#define STOP_SPEED 0.0f
// Walking Speed = 1.5 (m/s) / 60 FPS = 0.025 (m/frame)
#define WALKING_SPEED 0.025f
// Running Speed = 4.5 (m/s) / 60 FPS = 0.075 (m/frame)
#define RUNNING_SPEED 0.075f

Vector3 target = {0};
Vector3 nodes[WORLD_SIZE * WORLD_SIZE];
int path_length = 0;

struct Hero create_hero(const Vector3 at)
{
    return (struct Hero){
        .position = (Vector3){.x = at.x, .y = 1.0f, .z = at.z},
        .is_moving = false,
        .speed = STOP_SPEED,
    };
}

bool on_target_hero(const Vector3 position, const Vector3 target, const float distance)
{
    return fabsf(position.x - target.x) < distance && fabsf(position.z - target.z) < distance;
}

bool is_running_hero(const struct Hero *hero)
{
    return hero->speed == RUNNING_SPEED;
}

void update_hero(struct Hero *hero)
{
    // this check avoids calculation when the player do not click
    if (hero->is_moving)
    {
        // Calculate direction vector (only X and Z, keep Y constant)
        Vector3 direction = Vector3Subtract(target, hero->position);
        direction.y = 0; // Keep player on ground level
        direction = Vector3Normalize(direction);

        // Move player
        hero->position = Vector3Add(hero->position, Vector3Scale(direction, hero->speed));

        // If we're close enough to target and the hero is running, walk to make the stop animation softer
        if (is_running_hero(hero) && on_target_hero(hero->position, target, WALKING_DISTANCE_TO_TARGET))
            hero->speed = WALKING_SPEED;

        // If we're close enough to target, stop moving
        if (on_target_hero(hero->position, target, STOPPING_DISTANCE_TO_TARGET))
        {
            hero->is_moving = false;
            hero->speed = STOP_SPEED;
        }
    }
}

void move_hero(struct Hero *hero, const Vector3 to, const bool running)
{
    hero->is_moving = true;
    hero->speed = running ? RUNNING_SPEED : WALKING_SPEED;
    target = to;
}

// Simple pathfinding queue for BFS
typedef struct
{
    int x, y;
    int parent;
} path_node;

struct PathTemp
{
    int pathX[WORLD_SIZE * WORLD_SIZE];
    int pathY[WORLD_SIZE * WORLD_SIZE];
    int pathLength;
};

// Simple pathfinding using BFS
bool find_path(struct World *world, const Vector3 start, const Vector3 end)
{

    struct PathTemp path_temp = {0};

    int startX, startY, endX, endY;

    world_to_grid(start, &startX, &startY);
    world_to_grid(end, &endX, &endY);

    if (!is_walkable(world, endX, endY))
        return false;
    if (startX == endX && startY == endY)
        return false;

    path_node queue[WORLD_SIZE * WORLD_SIZE];
    bool visited[WORLD_SIZE][WORLD_SIZE] = {false};
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
            int tempPathX[WORLD_SIZE * WORLD_SIZE];
            int tempPathY[WORLD_SIZE * WORLD_SIZE];

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

            for (int i = 0; i < path_temp.pathLength; i++)
                nodes[i] = grid_to_world(path_temp.pathX[i], path_temp.pathY[i]);

            path_length = path_temp.pathLength;

            for (int i = 0; i < path_length; i++)
            {
                Vector3 v = nodes[i];
                printf("path = x: %f, y: %f, z: %f\n", v.x, v.y, v.z);
            }
            printf("---\n");

            return true;
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

    return false; // No path found
}

int path_length_number()
{
    return path_length;
}

Vector3 node(int i)
{
    return nodes[i];
}
