#pragma once

#include "logging.h"

enum Environment {
    DEVELOPMENT,
    PRODUCTION,
};

enum OS {
    WINDOWS,
    MACOS,
    LINUX,
    UNIX,
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
    enum OS os;
    int target_fps;
};

struct Game create_game();

bool setup_game(struct Game *game, const struct Logger *logger);