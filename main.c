#include <raylib.h>
#include <raymath.h>
#include <stdlib.h>
#include <stdio.h>

struct Player
{
    char id[50];
    bool traceable;
};

struct FPS
{
    int target;
    double previous_time;    // Previous time measure
    double current_time;     // Current time measure
    double update_draw_time; // Update + Draw time
    double wait_time;        // Wait time (if target fps required)
    float delta_time;        // Frame time (Update + Draw + Wait time)
};

struct Game
{
    char version[50];
    char name[50];
    struct
    {
        int width;
        int heigth;
    } window;
    bool debug;
    struct FPS fps;
};

struct Scene
{
    Color background;
};

void calculate_fps(struct FPS *p)
{
    p->current_time = GetTime();
    p->update_draw_time = p->current_time - p->previous_time;

    if (p->target > 0) // We want a fixed frame rate
    {
        p->wait_time = (1.0f / (float)p->target) - p->update_draw_time;
        if (p->wait_time > 0.0)
        {
            WaitTime((float)p->wait_time);
            p->current_time = GetTime();
            p->delta_time = (float)(p->current_time - p->previous_time);
        }
    }
    else
        p->delta_time = (float)p->update_draw_time; // Framerate could be variable

    p->previous_time = p->current_time;
}

struct Character
{
    Vector3 position;
};

#define INITIAL_ANGLE 45.0f
#define INITIAL_RADIUS 30.f
#define DIRECTION_CLOCKWISE -1.0f
#define DIRECTION_COUNTER_CLOCKWISE 1.0f
#define ZOOM 0.5f
#define MAX_ZOOM 50.0f
#define MIN_ZOOM 20.0f
#define ROTATION_FRAME 45.0f

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
            // calculate_position_camera(camera, target);
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

int main(void)
{
    /* Initialization */

    struct Player player = {"UUID_PLAYER", true};
    struct Game game =
        {
            .version = "v0.0.1",
            .name = "Queen of Shadows",
            .window = {1920, 1080},
            .debug = true,
            .fps = {
                .target = 60,
                .previous_time = GetTime(),
                .current_time = 0.0,
                .update_draw_time = 0.0,
                .wait_time = 0.0,
                .delta_time = 0.0f}};

    InitWindow(game.window.width, game.window.heigth, game.name);
    SetTargetFPS(game.fps.target);

    struct Character hero = {.position = {5.0f, 1.0f, 4.0f}};
    struct Camera camera = create_camera(hero.position);

    while (!WindowShouldClose())
    {

        if (IsKeyDown(KEY_UP))
            zoom_in_camera(&camera);

        if (IsKeyDown(KEY_DOWN))
            zoom_out_camera(&camera);

        if (IsKeyPressed(KEY_LEFT))
            clockwise_rotation_camera(&camera);

        if (IsKeyPressed(KEY_RIGHT))
            counter_clockwise_rotation_camera(&camera);

        calculate_angle_camera(&camera);
        calculate_position_camera(&camera, hero.position);

        BeginDrawing();
        ClearBackground((Color){15, 15, 15, 255});

        BeginMode3D(camera.instance);
        DrawCube(hero.position, 0.5f, 2.0f, 0.5f, RED);
        DrawCubeWires(hero.position, 0.5f, 2.0f, 0.5f, BLUE);
        DrawCube((Vector3){2.0f, 2.0f, 0.0f}, 1.5f, 2.0f, 0.5f, WHITE);
        DrawCubeWires((Vector3){2.0f, 2.0f, 0.0f}, 1.5f, 2.0f, 0.5f, BLUE);
        DrawCube((Vector3){-1.0f, 1.0f, 0.0f}, 0.5f, 2.0f, 0.5f, WHITE);
        DrawCubeWires((Vector3){-1.0f, 1.0f, 0.0f}, 0.5f, 2.0f, 0.5f, BLUE);
        DrawSphere((Vector3){-5.0f, 0.0f, 3.0f}, 0.5f, WHITE);
        DrawSphereWires((Vector3){-5.0f, 0.0f, 3.0f}, 0.5f, 16, 16, BLUE);
        DrawCube((Vector3){.0f, 5.0f, 15.0f}, 20.0f, 10.0f, 10.0f, BEIGE);
        DrawCubeWires((Vector3){.0f, 5.0f, 15.0f}, 20.0f, 10.0f, 10.0f, BLUE);
        DrawCube((Vector3){-10.0f, 7.5f, 15.0f}, 5.0f, 15.0f, 5.0f, BROWN);
        DrawCubeWires((Vector3){-10.0f, 7.5f, 15.0f}, 5.0f, 15.0f, 5.0f, BLUE);
        DrawCube((Vector3){10.0f, 7.5f, 15.0f}, 5.0f, 15.0f, 5.0f, BROWN);
        DrawCubeWires((Vector3){10.0f, 7.5f, 15.0f}, 5.0f, 15.0f, 5.0f, BLUE);
        DrawCube((Vector3){.0f, 9.f, 18.0f}, 5.0f, 20.0f, 5.0f, BROWN); // main tower
        DrawCubeWires((Vector3){.0f, 9.f, 18.0f}, 5.0f, 20.0f, 5.0f, BLUE);
        // DrawPlane((Vector3){.0f, .0f, .0f}, (Vector2){100.f, 100.0f}, DARKGRAY);

        DrawGrid(150, 0.25f);

        EndMode3D();

        if (game.debug) /* game.fps.delta_time != 0 */
        {
            DrawText(TextFormat("%s %s", game.name, game.version), 10, 10, 10, GREEN);
            DrawText(TextFormat("FPS Target: %i", game.fps.target), 10, 25, 10, GREEN);
            DrawText(TextFormat("FPS Current: %i", (int)(1.0f / game.fps.delta_time)), 10, 40, 10, GREEN);
            DrawText(TextFormat("Camara: %i x=%.2f y=%.2f z=%.2f", camera.step, camera.instance.position.x, camera.instance.position.y, camera.instance.position.z), 10, 55, 10, GREEN);
            DrawText(TextFormat("Camara Angle: %f", camera.angle), 10, 70, 10, GREEN);
            DrawText(TextFormat("Hero: x=%.2f y=%.2f z=%.2f", hero.position.x, hero.position.y, hero.position.z), 10, 85, 10, GREEN);
        }
        EndDrawing();

        if (game.debug)
            calculate_fps(&game.fps);
    }

    CloseWindow();

    return 0;
}