#include "camera.h"

#include <stdio.h>
#include <raylib.h>
#include <raymath.h>

// initial camara box
#define ROTATION_ANGLE 90.0f
#define INITIAL_ANGLE 45.0f
#define INITIAL_RADIUS 30.0f
#define DIRECTION_CLOCKWISE -1.0f
#define DIRECTION_COUNTER_CLOCKWISE 1.0f
// zoom increments every time the player pressed the button
#define ZOOM 0.5f
#define MAX_ZOOM 50.0f
#define MIN_ZOOM 20.0f
// total time to rotate = 1 s, with a game target of 60 FPS => 60
// total time to rotate = 750 ms, with a game target of 60 FPS => 45
// total time to rotate = 500 ms, with a game target of 60 FPS => 30
// How many frames do I need to complete the rotation in N seconds?
#define ROTATION_FRAME 45.0f

// Variables to hold current camera rotation
// numbers of frame to complete the rotation
float total_rotation_frame = ROTATION_FRAME;
// variables to control rotation when is_rotating boolean is true
// updated each frame
float current_rotation_angle = INITIAL_ANGLE;
float current_rotation_frame = 0.0f;
// indicate rotate direction: clockwise or counter clockwise
float direction = 0.0f;

struct Camera create_camera(const Vector3 at)
{
    // Init camera
    Camera3D view = {0};
    // Camera position based on current hero position
    // and initial parameters
    view.position = (Vector3){
        at.x + INITIAL_RADIUS * sin(INITIAL_ANGLE * DEG2RAD),
        INITIAL_RADIUS,
        at.z + INITIAL_RADIUS * cos(INITIAL_ANGLE * DEG2RAD)};
    // Looking at point = current hero position
    view.target = at;
    // Up vector (rotation towards target)
    view.up = (Vector3){0.0f, 1.0f, 0.0f};
    // Field-Of-View Y
    view.fovy = 45.0f;
    // Mode type
    view.projection = CAMERA_PERSPECTIVE;

    // initialize file camera variables
    total_rotation_frame = ROTATION_FRAME;
    current_rotation_angle = INITIAL_ANGLE;
    current_rotation_frame = 0.0f;

    // variables to hold camara status
    return (struct Camera){
        .view = view,
        .position = POSITION_SOUTH,
        .angle = INITIAL_ANGLE,
        .radius = INITIAL_RADIUS,
        .is_rotating = false,
    };
}

void zoom_in_camera(struct Camera *camera)
{
    if (camera->radius == MIN_ZOOM)
        return;

    camera->radius -= ZOOM;
}

void zoom_out_camera(struct Camera *camera)
{
    if (camera->radius == MAX_ZOOM)
        return;

    camera->radius += ZOOM;
}

void clockwise_rotate_camera(struct Camera *camera)
{
    if (!camera->is_rotating)
    {
        // update camera status
        // update step pointing to the next one
        if (camera->position == POSITION_SOUTH)
        {
            camera->angle = 360.0f - INITIAL_ANGLE;
            camera->position = POSITION_EAST;
        }
        else
        {
            --camera->position;
            camera->angle -= ROTATION_ANGLE;
        }

        // update rotation variables
        camera->is_rotating = true;
        direction = DIRECTION_CLOCKWISE;
    }
}

void counter_clockwise_rotate_camera(struct Camera *camera)
{
    if (!camera->is_rotating)
    {
        // update camera status
        // update step pointing to the next one
        if (camera->position == POSITION_EAST)
        {
            camera->position = POSITION_SOUTH;
            camera->angle = INITIAL_ANGLE;
        }
        else
        {
            ++camera->position;
            camera->angle += ROTATION_ANGLE;
        }

        // update rotation variables
        camera->is_rotating = true;
        direction = DIRECTION_COUNTER_CLOCKWISE;
    }
}

void update_position_camera(struct Camera *camera, const Vector3 target)
{
    camera->view.position.y = camera->radius;
    camera->view.position.x = target.x + camera->radius * sin(current_rotation_angle * DEG2RAD);
    camera->view.position.z = target.z + camera->radius * cos(current_rotation_angle * DEG2RAD);
}

void update_angle_camera(struct Camera *camera)
{
    if (camera->is_rotating)
    {
        if (current_rotation_frame >= total_rotation_frame)
        {
            // when rotation finishes
            current_rotation_frame = 0;
            camera->is_rotating = false;
        }
        else
        {
            // update rotation angle an frame
            current_rotation_angle += direction * 2;
            ++current_rotation_frame;
        }
    }
}

void update_target_camera(struct Camera *camera, const Vector3 target)
{
    // to follow our hero when it moves
    camera->view.target = target;
}

void update_camera(struct Camera *camera, const Vector3 target)
{
    update_target_camera(camera, target);
    update_angle_camera(camera);
    update_position_camera(camera, target);
}

const char *position_camera(const struct Camera *camera)
{
    switch (camera->position)
    {
    case POSITION_SOUTH:
        return "In the south facing north";
    case POSITION_WEST:
        return "In the west facing east";
    case POSITION_NORTH:
        return "In the north facing south";
    case POSITION_EAST:
        return "In the east facing west";
    default:
        return "Unknown";
    }
}

Vector3 raycast_camera(const struct Camera *camera, const Vector2 position)
{
    Vector3 target = {0};
    Ray ray = GetMouseRay(position, camera->view);

    // Check if ray is parallel to ground (no intersection)
    if (fabsf(ray.direction.y) < 0.001f)
        return target;

    // Calculate intersection point, solve for y = 0
    // float t = (groundY - ray.position.y) / ray.direction.y;
    float t = -ray.position.y / ray.direction.y;
    if (t < 0)
        return target;

    target = Vector3Add(ray.position, Vector3Scale(ray.direction, t));
    return target;
}
