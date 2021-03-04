



#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpadded"
#endif

#include "include/raylib.h"

#ifdef __clang__
#pragma clang diagnostic pop
#endif

#define local static

local void draw(void) {
    ClearBackground(DARKGRAY);

    DrawRectangle(0, 0, 20, 20, BLACK);
}

int main(void)
{
    InitWindow(0, 0, "AWESOME BROUGHLIKE");

    int screen_width = GetScreenWidth();
    int screen_height = GetScreenHeight();

    SetTargetFPS(60);

    while (!WindowShouldClose())
    {
        if (IsKeyPressed(KEY_F11)) {
            ToggleFullscreen();
            screen_width = GetScreenWidth();
            screen_height = GetScreenHeight();
        }

        BeginDrawing();

        draw();

        EndDrawing();
    }

    CloseWindow();

    return 0;
}
