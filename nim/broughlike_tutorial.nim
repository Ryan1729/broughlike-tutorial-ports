import raylib

const screenWidth = 1024
const screenHeight = 768

InitWindow screenWidth, screenHeight, "AWESOME BROUGHLIKE"

while not WindowShouldClose():
    BeginDrawing()

    ClearBackground DARKGRAY

    DrawText "Hello World!", 0, 0, 42, RAYWHITE

    EndDrawing()
