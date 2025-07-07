#pragma once

#include <raylib.h>

enum CameraStep
{
    STEP_SOUTH = 0,
    STEP_WEST = 1,
    STEP_NORTH = 2,
    STEP_EAST = 3,
};

struct Camera
{
    Camera3D instance;
    enum CameraStep step;
    float dimension;
    float angle;
    bool rotating;
    float direction;
    float current_rotation_frame;
    float rotation_frame;
};

struct Camera create_camera(const Vector3 at);
void clockwise_rotation_camera(struct Camera *camera);
void counter_clockwise_rotation_camera(struct Camera *camera);
void calculate_position_camera(struct Camera *camera, const Vector3 target);
void calculate_angle_camera(struct Camera *camera);
void zoom_in_camera(struct Camera *camera);
void zoom_out_camera(struct Camera *camera);