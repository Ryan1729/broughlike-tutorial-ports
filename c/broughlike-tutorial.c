

#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpadded"
#endif

#include "include/raylib.h"

#ifdef __clang__
#pragma clang diagnostic pop
#endif

#define local static
#define u8 unsigned char

typedef u8 tile_x;
typedef u8 tile_y;

local tile_x x = 0;
local tile_y y = 0;

local void draw(void) {
    ClearBackground(DARKGRAY);

    DrawRectangle(x * 20, y * 20, 20, 20, BLACK);
}

int main(void) {
    InitWindow(0, 0, "AWESOME BROUGHLIKE");

    int screen_width = GetScreenWidth();
    int screen_height = GetScreenHeight();

    SetTargetFPS(60);

    while (!WindowShouldClose()) {
        if (IsKeyPressed(KEY_F11)) {
            ToggleFullscreen();
            screen_width = GetScreenWidth();
            screen_height = GetScreenHeight();
        }

        if (IsKeyPressed(KEY_W) || IsKeyPressed(KEY_UP)) {
            y -= 1;
        }
        if (IsKeyPressed(KEY_S) || IsKeyPressed(KEY_DOWN)) {
            y += 1;
        }
        if (IsKeyPressed(KEY_A) || IsKeyPressed(KEY_LEFT)) {
            x -= 1;
        }
        if (IsKeyPressed(KEY_D) || IsKeyPressed(KEY_RIGHT)) {
            x += 1;
        }

        BeginDrawing();

        draw();

        EndDrawing();
    }

    CloseWindow();

    return 0;
}
