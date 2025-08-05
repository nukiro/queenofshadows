#include "../raykit.h"
#include "raylib.h"

#define RENDER_DEBUG_FONT_SIZE 10
#define RENDER_DEBUG_FONT_COLOR (Color){0, 158, 47, 255}
#define RENDER_DEBUG_TABLE_X 10
#define RENDER_DEBUG_TABLE_Y 36
#define RENDER_DEBUG_TABLE_GAP 5

void render_debug_text(const char *str, const int x, int *y)
{
    DrawText(str, x, *y, RENDER_DEBUG_FONT_SIZE, RENDER_DEBUG_FONT_COLOR);
    *y += (RENDER_DEBUG_FONT_SIZE + RENDER_DEBUG_TABLE_GAP);
}

void render_debug()
{
    int x = RENDER_DEBUG_TABLE_X;
    int y = RENDER_DEBUG_TABLE_Y;

    DrawFPS(x, x);

    // Game
    render_debug_text("--- Game ---", x, &y);
    render_debug_text(TextFormat("Name: %s", CONFIG_TITLE), x, &y);
    render_debug_text(TextFormat("Version: %s", CONFIG_VERSION), x, &y);
}

void render()
{
    ClearBackground(CONFIG_SCREEN_BACKGROUND_COLOR);

#ifdef CONFIG_ENABLE_DEBUG
    render_debug();
#endif
}
