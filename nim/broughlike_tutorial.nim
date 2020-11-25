import raylib

InitWindow 0, 0, "AWESOME BROUGHLIKE"

var screenWidth = GetScreenWidth()
var screenHeight = GetScreenHeight()

while not WindowShouldClose():
    if IsKeyPressed(KEY_F11):
        ToggleFullscreen()
        screenWidth = GetScreenWidth()
        screenHeight = GetScreenHeight()

    BeginDrawing()

    ClearBackground DARKGRAY

    DrawRectangle(0, 0, 20, 20, BLACK)

    EndDrawing()
