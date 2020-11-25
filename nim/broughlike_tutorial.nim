import macros, raylib

# no_ex: allow no exceptions
macro no_ex(x: untyped): untyped =
    #echo "x = ", tree_repr(x)

    for child in x:
        let raisesPragma: NimNode = nnkExprColonExpr.newTree(
            newIdentNode("raises"),
            nnkBracket.newTree()
        )

        addPragma(child, raisesPragma)

    result = x


InitWindow 0, 0, "AWESOME BROUGHLIKE"

var screenWidth = GetScreenWidth()
var screenHeight = GetScreenHeight()

var x, y = 0

no_ex:
    proc draw() =
        ClearBackground DARKGRAY
        DrawRectangle(x*20, y*20, 20, 20, BLACK)

while not WindowShouldClose():
    if IsKeyPressed(KEY_F11):
        ToggleFullscreen()
        screenWidth = GetScreenWidth()
        screenHeight = GetScreenHeight()

    if IsKeyPressed(KEY_W) or IsKeyPressed(KEY_UP):
        y -= 1
    if IsKeyPressed(KEY_S) or IsKeyPressed(KEY_DOWN):
        y += 1
    if IsKeyPressed(KEY_A) or IsKeyPressed(KEY_LEFT):
        x -= 1
    if IsKeyPressed(KEY_D) or IsKeyPressed(KEY_RIGHT):
        x += 1

    BeginDrawing()

    draw()

    EndDrawing()
