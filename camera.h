#pragma once

#include <raylib.h>

enum CameraPosition
{
    POSITION_SOUTH = 0,
    POSITION_WEST = 1,
    POSITION_NORTH = 2,
    POSITION_EAST = 3,
};

struct Camera
{
    // raylib Camera3D instance
    Camera3D view;
    // position: South, West, etc.
    enum CameraPosition position;
    // camara initial box (x,y,z)
    float radius;
    // camara initial angle from 0
    float angle;
};

struct Camera create_camera(const Vector3 at);

const char *position_camera(const struct Camera *camera);

void zoom_in_camera(struct Camera *camera);
void zoom_out_camera(struct Camera *camera);
void clockwise_rotate_camera(struct Camera *camera);
void counter_clockwise_rotate_camera(struct Camera *camera);

Vector2 raycast_camera(const struct Camera *camera, const Vector2 position);

void update_camera(struct Camera *camera, const Vector3 target);