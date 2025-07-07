#include "camera.h"

#include <raylib.h>
#include <raymath.h>

#define INITIAL_ANGLE 45.0f
#define INITIAL_RADIUS 30.f
#define DIRECTION_CLOCKWISE -1.0f
#define DIRECTION_COUNTER_CLOCKWISE 1.0f
#define ZOOM 0.5f
#define MAX_ZOOM 50.0f
#define MIN_ZOOM 20.0f
#define ROTATION_FRAME 45.0f

struct Camera create_camera(const Vector3 at)
{
    // Init camera
    Camera3D camera = {0};
    // Camera position
    camera.position = (Vector3){
        at.x + INITIAL_RADIUS * sin(INITIAL_ANGLE * DEG2RAD),
        INITIAL_RADIUS,
        at.z + INITIAL_RADIUS * cos(INITIAL_ANGLE * DEG2RAD)};
    // Camera looking at point
    camera.target = at;
    // Camera up vector (rotation towards target)
    camera.up = (Vector3){0.0f, 1.0f, 0.0f};
    // Camera field-of-view Y
    camera.fovy = 45.0f;
    // Camera mode type
    camera.projection = CAMERA_PERSPECTIVE;

    return (struct Camera){
        .instance = camera,
        .step = STEP_SOUTH,
        .angle = INITIAL_ANGLE,
        .dimension = INITIAL_RADIUS,
        .rotating = false,
        .current_rotation_frame = 0.0f,
        .rotation_frame = ROTATION_FRAME,
    };
}

void clockwise_rotation_camera(struct Camera *camera)
{
    if (!camera->rotating)
    {
        // update step pointing to the next one
        if (camera->step == STEP_SOUTH)
            camera->step = STEP_EAST;
        else
            --camera->step;

        camera->rotating = !camera->rotating;
        camera->direction = DIRECTION_CLOCKWISE;
    }
}

void counter_clockwise_rotation_camera(struct Camera *camera)
{
    if (!camera->rotating)
    {
        // update step pointing to the next one
        if (camera->step == STEP_EAST)
            camera->step = STEP_SOUTH;
        else
            ++camera->step;

        camera->rotating = !camera->rotating;
        camera->direction = DIRECTION_COUNTER_CLOCKWISE;
    }
}

void calculate_position_camera(struct Camera *camera, const Vector3 target)
{
    camera->instance.position.y = camera->dimension;
    camera->instance.position.x = target.x + camera->dimension * sin(camera->angle * DEG2RAD);
    camera->instance.position.z = target.z + camera->dimension * cos(camera->angle * DEG2RAD);
}

void calculate_angle_camera(struct Camera *camera)
{
    if (camera->rotating)
    {
        if (camera->current_rotation_frame >= camera->rotation_frame)
        {
            camera->current_rotation_frame = 0;
            camera->rotating = false;
            if (camera->step == STEP_SOUTH)
                camera->angle = INITIAL_ANGLE;
        }
        else
        {
            camera->angle += camera->direction * 2;
            ++camera->current_rotation_frame;
        }
    }
}

void zoom_in_camera(struct Camera *camera)
{
    if (camera->dimension == MIN_ZOOM)
        return;

    camera->dimension -= ZOOM;
}

void zoom_out_camera(struct Camera *camera)
{
    if (camera->dimension == MAX_ZOOM)
        return;

    camera->dimension += ZOOM;
}