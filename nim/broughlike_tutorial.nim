
import raylib
# Put this above everything but the raylib import, since it seems like we get
# SIGSEGV errors if we call (some?) raylib stuff before calling this.
InitWindow 0, 0, "AWESOME BROUGHLIKE"

from math import nil
from times import nil
from options import isSome, get

from assets import nil
from randomness import nil
from monster import draw
from res import ok, err
from game import `-=`, `+=`, no_ex, DeltaX, DeltaY, `$`
from map import generateLevel, randomPassableTile, addMonster, tryMove, getTile
from world import tick


const INDIGO = Color(a: 0xffu8, r: 0x4bu8, g: 0, b: 0x82u8)

type
    floatXY = tuple
        x: float
        y: float

    Size = int32

    sizesObj = object
        playAreaX: Size
        playAreaY: Size
        playAreaW: Size
        playAreaH: Size
        tile: Size

    State = res.ult[world.State, string]

no_ex:
    proc seedState(): res.ult[world.State, string] =
        let
            now = times.getTime()
            seed = times.toUnix(now) * 1_000_000_000 + times.nanosecond(now)
            level = game.LevelNum(1)

        # So we can reproduce weird situtations
        echo seed

        var rng = randomness.initRand(seed)
        var tiles = rng.generateLevel(level)
        case tiles.isOk:
        of true:
            let startingTile = rng.randomPassableTile(tiles.value)

            case startingTile.isOk:
            of true:
                let xy = startingTile.value.xy
                tiles.value.addMonster(monster.newPlayer(xy))

                (
                    xy: xy,
                    tiles: tiles.value,
                    rng: rng,
                    level: level
                ).ok
            of false:
                startingTile.error.err
        of false:
            tiles.error.err

# It seems like it should be provable that `state.value` is accessible
# inside an `if` that checks `state.isOk`, but it doesn't work currently.
# See https://github.com/nim-lang/Nim/issues/7882
{.push warning[ProveField]: off.}
no_ex:
    proc movePlayer(state: var State, dxy: game.DeltaXY) =
        if state.isOk:
            let monster = state.value.tiles.getTile(state.value.xy).monster
            if monster.isSome:
                let moved = state.value.tiles.tryMove(
                    monster.get,
                    dxy
                )

                if moved.isSome:
                    state.value.xy = moved.get.xy
                    state.value.tick

            else:
                state = State.err("Could not find player!")

{.pop.}

var
    state = seedState()
    sizes: sizesObj

var spritesheet: Texture2D = LoadTextureFromImage(assets.spritesheetImage)

no_ex:
    proc drawSpriteFloat(sprite: game.SpriteIndex, xy: floatXY) =
        DrawTexturePro(
            spritesheet,
            Rectangle(x: float(sprite) * 16, y: 0, width: 16, height: 16),
            Rectangle(
                x: float(sizes.playAreaX) + (xy.x * float(sizes.tile)),
                y: float(sizes.playAreaY) + (xy.y * float(sizes.tile)),
                width: float(sizes.tile),
                height: float(sizes.tile)
            ),
            Vector2(x: 0, y: 0),
            0.0,
            WHITE
        )

    proc drawSprite(sprite: game.SpriteIndex, xy: game.TileXY) =
        drawSpriteFloat(
            sprite,
            (
                x: float(xy.x),
                y: float(xy.y)
            )
        )

    proc drawHp(hp: game.HP, xy: game.TileXY) =
        for i in 0..<(int(hp) div 2):
            drawSpriteFloat(
                game.SpriteIndex(9),
                (
                    x: float(xy.x) + float((i mod 3))*(5.0/16.0),
                    y: float(xy.y) - math.floor(float(i div 3))*(5.0/16.0)
                )
            )

const platform = game.Platform(
    sprite: drawSprite,
    hp: drawHp
)

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

            for t in state.value.tiles:
                t.monster.draw(platform)
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
            state.movePlayer((x: DX0, y: DYm1))
        if IsKeyPressed(KEY_S) or IsKeyPressed(KEY_DOWN):
            state.movePlayer((x: DX0, y: DY1))
        if IsKeyPressed(KEY_A) or IsKeyPressed(KEY_LEFT):
            state.movePlayer((x: DXm1, y: DY0))
        if IsKeyPressed(KEY_D) or IsKeyPressed(KEY_RIGHT):
            state.movePlayer((x: DX1, y: DY0))
    of false:
        discard

    BeginDrawing()

    draw()

    EndDrawing()
