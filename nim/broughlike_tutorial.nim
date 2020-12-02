
import raylib
# Put this above everything but the raylib import, since it seems like we get
# SIGSEGV errors if we call (some?) raylib stuff before calling this.
InitWindow 0, 0, "AWESOME BROUGHLIKE"

from assets import nil
from game import `-=`, `+=`, no_ex
from map import nil
from tile import nil
from world import nil

const INDIGO = Color(a: 0xffu8, r: 0x4bu8, g: 0, b: 0x82u8)

type Size = int32

type sizesObj = object
    playAreaX: Size
    playAreaY: Size
    playAreaW: Size
    playAreaH: Size
    tile: Size

var sizes: sizesObj

var
    state = world.State(
        xy: game.TileXY(x: game.TileX(0), y: game.TileY(0)),
        tiles: map.generateTiles()
    )
    exampleTile = tile.Tile(
        kind: tile.Kind.Floor,
        xy: game.TileXY(x: game.TileX(1), y: game.TileY(1))
    )

var spritesheet: Texture2D = LoadTextureFromImage(assets.spritesheetImage)

no_ex:
    proc drawSprite(sprite: game.SpriteIndex, xy: game.TileXY) =
        DrawTexturePro(
            spritesheet,
            Rectangle(x: float(sprite) * 16, y: 0, width: 16, height: 16),
            Rectangle(
                x: float(sizes.playAreaX + (Size(xy.x) * sizes.tile)),
                y: float(sizes.playAreaY + (Size(xy.y) * sizes.tile)),
                width: float(sizes.tile),
                height: float(sizes.tile)
            ),
            Vector2(x: 0, y: 0),
            0.0,
            WHITE
        )

const platform = game.Platform(sprite: drawSprite)

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

        map.draw(state.tiles, platform)

        drawSprite(game.SpriteIndex(0), state.xy)

    proc freshSizes(): sizesObj =
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

        return sizesObj(
            playAreaX: playAreaX,
            playAreaY: playAreaY,
            playAreaW: playAreaW,
            playAreaH: playAreaH,
            tile: tile,
        )

sizes = freshSizes()

while not WindowShouldClose():
    if IsKeyPressed(KEY_F11):
        ToggleFullscreen()
        sizes = freshSizes()

    if IsKeyPressed(KEY_W) or IsKeyPressed(KEY_UP):
        state.xy.y -= 1
    if IsKeyPressed(KEY_S) or IsKeyPressed(KEY_DOWN):
        state.xy.y += 1
    if IsKeyPressed(KEY_A) or IsKeyPressed(KEY_LEFT):
        state.xy.x -= 1
    if IsKeyPressed(KEY_D) or IsKeyPressed(KEY_RIGHT):
        state.xy.x += 1

    BeginDrawing()

    draw()

    EndDrawing()
