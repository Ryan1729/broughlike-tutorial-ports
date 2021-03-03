#include "include/raylib.h"

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

        ClearBackground(DARKGRAY);

        const int font_size = 42;
        const char* text = "Hello World!";
        DrawText(
            text,
            (screen_width - MeasureText(text, font_size)) / 2,
            (screen_height - font_size) / 2,
            font_size,
            RAYWHITE
        );

        EndDrawing();
    }

    CloseWindow();

    return 0;
}
