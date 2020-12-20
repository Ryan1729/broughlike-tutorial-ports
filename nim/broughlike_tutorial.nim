
import raylib
# Put this above everything but the raylib import, since it seems like we get
# SIGSEGV errors if we call (some?) raylib stuff before calling this.
InitWindow 0, 0, "AWESOME BROUGHLIKE"

from math import nil
from times import nil
from options import Option, isSome, get, none, some

from assets import nil
from randomness import nil
from monster import draw
from res import ok, err
from game import `-=`, `+=`, no_ex, DeltaX, DeltaY, `$`
from map import generateLevel, randomPassableTile, addMonster, tryMove, getTile
from world import tick, AfterTick


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

    Screen = enum
        Title
        Running
        Dead
        Error

    State = object
        case screen: Screen
        of Title:
            prevState: Option[world.State]
        of Running, Dead:
            state: world.State
        of Error:
            error: string

no_ex:
    proc errorState(message: string): State =
        State(screen: Screen.Error, error: message)

    proc seedState(): State =
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

                let spawnRate = game.Counter(15)

                State(
                    screen: Screen.Running,
                    state: (
                        xy: xy,
                        tiles: tiles.value,
                        rng: rng,
                        level: level,
                        spawnCounter: spawnRate,
                        spawnRate: spawnRate
                    ),
                )
            of false:
                startingTile.error.errorState
        of false:
            tiles.error.errorState

# It seems like it should be provable that `state.state` is accessible
# inside an `if` that checks `state.screen == Screen.Running`, but it
# doesn't work currently. See https://github.com/nim-lang/Nim/issues/7882
{.push warning[ProveField]: off.}
no_ex:
    proc movePlayer(state: var State, dxy: game.DeltaXY) =
        if state.screen == Screen.Running:
            let monster = state.state.tiles.getTile(state.state.xy).monster
            if monster.isSome:
                let moved = state.state.tiles.tryMove(
                    monster.get,
                    dxy
                )

                if moved.isSome:
                    state.state.xy = moved.get.xy
                    case state.state.tick
                    of AfterTick.NoChange:
                        discard
                    of AfterTick.PlayerDied:
                        state = State(
                            screen: Screen.Dead,
                            state: state.state,
                        )

            else:
                state = errorState("Could not find player!")


    proc showTitle(state: var State) =
        if state.screen == Screen.Dead:
            state = State(
                screen: Screen.Title,
                prevState: some(state.state)
            )
{.pop.}

var
    state = State(screen: Screen.Title, prevState: none(world.State))
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
    proc drawState(state: world.State) =
        map.draw(state.tiles, platform)

        for t in state.tiles:
            t.monster.draw(platform)

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

        case state.screen
        of Screen.Running, Screen.Dead:
            drawState(state.state)
        of Screen.Title:
            if state.prevState.isSome:
                drawState(state.prevState.get)

            DrawRectangle(
                sizes.playAreaX,
                sizes.playAreaY,
                sizes.playAreaW,
                sizes.playAreaH,
                Color(r: 0, g: 0, b: 0, a: 192)
            )
        of Screen.Error:
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

    proc anyGameplayKeysPressed(): bool =
        IsKeyPressed(KEY_W) or
        IsKeyPressed(KEY_UP) or
        IsKeyPressed(KEY_S) or
        IsKeyPressed(KEY_DOWN) or
        IsKeyPressed(KEY_A) or
        IsKeyPressed(KEY_LEFT) or
        IsKeyPressed(KEY_D) or
        IsKeyPressed(KEY_RIGHT)

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

    case state.screen:
    of Screen.Title:
        if anyGameplayKeysPressed():
            state = seedState()
    of Screen.Running:
        if IsKeyPressed(KEY_W) or IsKeyPressed(KEY_UP):
            state.movePlayer((x: DX0, y: DYm1))
        if IsKeyPressed(KEY_S) or IsKeyPressed(KEY_DOWN):
            state.movePlayer((x: DX0, y: DY1))
        if IsKeyPressed(KEY_A) or IsKeyPressed(KEY_LEFT):
            state.movePlayer((x: DXm1, y: DY0))
        if IsKeyPressed(KEY_D) or IsKeyPressed(KEY_RIGHT):
            state.movePlayer((x: DX1, y: DY0))
    of Screen.Dead:
        if anyGameplayKeysPressed():
            showTitle(state)
    of Screen.Error:
        discard

    BeginDrawing()

    draw()

    EndDrawing()
