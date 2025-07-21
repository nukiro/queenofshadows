#include "game.h"
#include "logging.h"

#include <stdio.h>

#define MIN_SCREEN_WIDTH 1280
#define MIN_SCREEN_HEIGHT 720

#define DEV_SCREEN_WIDTH 1920
#define DEV_SCREEN_HEIGHT 1080

struct Game create_game()
{
    return (struct Game){
        .version = "v0.1.1",
        .name = "Queen of Shadows",
        .window = {MIN_SCREEN_WIDTH, MIN_SCREEN_HEIGHT},
        .debug = true,
        .environment = DEVELOPMENT,
        .target_fps = 60,
    };
}

bool setup_os(struct Game *game, const struct Logger *logger)
{
#if defined(_WIN32)
    debug(logger, "OS: Windows");
    game->os = WINDOWS;
#elif defined(__APPLE__) && defined(__MACH__)
    debug(logger, "OS: MacOS");
    game->os = MACOS;
#elif defined(__linux__)
    debug(logger, "OS: Linux");
    game->os = LINUX;
#elif defined(__inux__)
    debug(logger, "OS: Unix");
    game->os = UNIX;
#endif

    return true;
}

bool setup_screen(struct Game *game, const struct Logger *logger)
{
    // TODO: #46 using raylib or os libs?
    // check if screen has minimum size

    if (game->environment == DEVELOPMENT)
    {
        game->window.width = DEV_SCREEN_WIDTH;
        game->window.heigth = DEV_SCREEN_HEIGHT;
    }
    // debug(logger, )

    return true;
}

bool setup_game(struct Game *game, const struct Logger *logger)
{
    debug(logger, "Setting up Game...");
    // debug(logger, game->environment);

    if (!setup_os(game, logger))
    {
        error(logger, "error setting up game: OS");
        return false;
    }

    if (!setup_screen(game, logger))
    {
        error(logger, "error setting up game: Screen");
        return false;
    }

    // it will return false if something is not set up properly
    // or if some hardware is not compatible
    return true;
}
