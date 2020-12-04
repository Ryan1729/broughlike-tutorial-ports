
import raylib
# Put this above everything but the raylib import, since it seems like we get
# SIGSEGV errors if we call (some?) raylib stuff before calling this.
InitWindow 0, 0, "AWESOME BROUGHLIKE"

from randomness import nil
from times import nil

from assets import nil
from res import ok, err
from game import `-=`, `+=`, no_ex
from map import generateTiles, randomPassableTile
from world import nil


const INDIGO = Color(a: 0xffu8, r: 0x4bu8, g: 0, b: 0x82u8)

type
    Size = int32

    sizesObj = object
        playAreaX: Size
        playAreaY: Size
        playAreaW: Size
        playAreaH: Size
        tile: Size

no_ex:
    proc seedState(): res.ult[world.State, string] =
        let
            now = times.getTime()
            seed = times.toUnix(now) * 1_000_000_000 + times.nanosecond(now)

        # So we can reproduce weird situtations
        echo seed

        var rng = randomness.initRand(seed)
        let tiles = rng.generateTiles
        let startingTile = rng.randomPassableTile(tiles)

        case startingTile.isOk:
        of true:
            world.State(
                xy: startingTile.value.xy,
                tiles: tiles,
                rng: rng
            ).ok
        of false:
            startingTile.error.err

var
    state = seedState()
    sizes: sizesObj

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

        case state.isOk
        of true:
            map.draw(state.value.tiles, platform)

            drawSprite(game.SpriteIndex(0), state.value.xy)
        of false:
            DrawTextRec(
                GetFontDefault(),
                state.error,
                Rectangle(
                    x: float(sizes.playAreaX),
                    y: float(sizes.playAreaY),
                    width: float(sizes.playAreaW),
                    height: float(sizes.playAreaH)
                ),
                20.0,
                4.0,
                true,
                RED
            )



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

    case state.isOk:
    of true:
        if IsKeyPressed(KEY_W) or IsKeyPressed(KEY_UP):
            state.value.xy.y -= 1
        if IsKeyPressed(KEY_S) or IsKeyPressed(KEY_DOWN):
            state.value.xy.y += 1
        if IsKeyPressed(KEY_A) or IsKeyPressed(KEY_LEFT):
            state.value.xy.x -= 1
        if IsKeyPressed(KEY_D) or IsKeyPressed(KEY_RIGHT):
            state.value.xy.x += 1
    of false:
        discard

    BeginDrawing()

    draw()

    EndDrawing()
