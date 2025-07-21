#include "game.h"
#include "logging.h"

#include <X11/Xlib.h>
#include <stdio.h>

#define SCREEN_WIDTH 1920
#define SCREEN_HEIGHT 1080

struct Game create_game()
{
    return (struct Game){
        .version = "v0.1.1",
        .name = "Queen of Shadows",
        .window = {SCREEN_WIDTH, SCREEN_HEIGHT},
        .debug = true,
        .environment = DEVELOPMENT,
        .target_fps = 60,
    };
}

bool setup_os(const struct Logger *logger)
{
#if defined(_WIN32)
    info(logger, "OS: Windows");
#elif defined(__APPLE__) && defined(__MACH__)
    info(logger, "OS: MacOS");
#elif defined(__linux__)
    info(logger, "OS: Linux");
#elif defined(__inux__)
    info(logger, "OS: Unix");
#endif

    return true;
}

bool setup_game(const struct Logger *logger)
{
    info(logger, "Setting up Game...");
    if (!setup_os(logger))
    {
        error(logger, "error setting up game: OS");
        return false;
    }

    // it will return false if something is not set up properly
    // or if some hardware is not compatible
    return true;
}
