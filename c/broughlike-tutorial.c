#include "include/raylib.h"

int main(void)
{
    const int screenWidth = 1024;
    const int screenHeight = 768;

    InitWindow(screenWidth, screenHeight, "AWESOME BROUGHLIKE");

    SetTargetFPS(60);

    while (!WindowShouldClose())
    {
        BeginDrawing();

        ClearBackground(DARKGRAY);

        DrawText("Hello World!", 0, 0, 42, RAYWHITE);

        EndDrawing();
    }

    CloseWindow();

    return 0;
}
