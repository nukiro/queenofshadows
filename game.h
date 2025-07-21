#pragma once

#include "logging.h"

enum Environment {
    DEVELOPMENT,
    PRODUCTION,
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
    enum Environment environment;
    int target_fps;
};

struct Game create_game();

bool setup_game(const struct Logger *logger);