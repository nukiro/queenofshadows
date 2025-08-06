#pragma once

#define CONFIG_TITLE "Playground - Window"
#define CONFIG_VERSION "0.1.0"

#define CONFIG_ENABLE_DEBUG 1
#define CONFIG_ENABLE_PROFILING 1

#define CONFIG_SCREEN_WIDTH 1920
#define CONFIG_SCREEN_HEIGHT 1080
#define CONFIG_SCREEN_BACKGROUND_COLOR (Color){15, 15, 15, 255}
#define CONFIG_SCREEN_FPS 60

int raykit_run();