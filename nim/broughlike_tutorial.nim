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

    const fontSize = 42
    const text = "Hello World!"
    DrawText text,
        (screenWidth - MeasureText(text, fontSize)) div 2,
        (screenHeight - fontSize) div 2,
        fontSize,
        RAYWHITE

    EndDrawing()
