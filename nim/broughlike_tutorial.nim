import macros, raylib

from game import nil

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

const INDIGO = Color(a: 0xffu8, r: 0x4bu8, g: 0, b: 0x82u8)

type sizest = object
    playAreaX: int32
    playAreaY: int32
    playAreaW: int32
    playAreaH: int32
    tile: int32

var sizes: sizest

var x, y = 0

no_ex:
    proc draw() =
        ClearBackground INDIGO

        # the -1 and +2 business makes the border lie just outside the actual
        # play area
        DrawRectangleLines(
            sizes.playAreaX - 1,
            sizes.playAreaY - 1,
            sizes.playAreaW + 2,
            sizes.playAreaH + 2,
            WHITE
        )

        DrawRectangle(
            sizes.playAreaX + x*sizes.tile,
            sizes.playAreaY + y*sizes.tile,
            sizes.tile,
            sizes.tile,
            BLACK
        )

    proc freshSizes(): sizest =
        let w = GetScreenWidth()
        let h = GetScreenHeight()
        let tile = min(
            w div (game.NumTiles+game.UIWidth),
            h div game.NumTiles,
        )
        let
            playAreaW = tile*(game.NumTiles+game.UIWidth)
            playAreaH = tile*game.NumTiles
            playAreaX = (w-playAreaW) div 2
            playAreaY = (h-playAreaH) div 2

        return sizest(
            playAreaX: playAreaX,
            playAreaY: playAreaY,
            playAreaW: playAreaW,
            playAreaH: playAreaH,
            tile: tile,
        )


InitWindow 0, 0, "AWESOME BROUGHLIKE"


sizes = freshSizes()

while not WindowShouldClose():
    if IsKeyPressed(KEY_F11):
        ToggleFullscreen()
        sizes = freshSizes()

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
