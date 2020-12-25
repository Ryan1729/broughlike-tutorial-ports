
import raylib
# Put this above everything but the raylib import, since it seems like we get
# SIGSEGV errors if we call (some?) raylib stuff before calling this.
InitWindow 0, 0, "AWESOME BROUGHLIKE"

from math import nil
from times import nil
from options import Option, isSome, get, none, some

from assets import nil
from randomness import nil
from tile import Kind, newExit
from monster import draw, isPlayer, Damage, `+`
from res import ok, err
from game import `-=`, `+=`, `==`, no_ex, DeltaX, DeltaY, `$`
from map import generateLevel, randomPassableTile, addMonster, tryMove, getTile, replace
from world import tick, AfterTick


const INDIGO = Color(a: 0xffu8, r: 0x4bu8, g: 0, b: 0x82u8)
const VIOLET = Color(a: 0xffu8, r: 0xeeu8, g: 0x82u8, b: 0xeeu8)

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

    proc startLevel(
        level: game.LevelNum,
        rng: var randomness.Rand,
        playerHP: game.HP
    ): State =
        var tiles = rng.generateLevel(level)
        case tiles.isOk:
        of true:
            let startingTile = rng.randomPassableTile(tiles.value)

            case startingTile.isOk:
            of true:
                let exitTile = rng.randomPassableTile(tiles.value)

                case exitTile.isOk:
                of true:
                    # Do the exit tile first so we don't erase the player!
                    tiles.value.replace(exitTile.value.xy, newExit)

                    let xy = startingTile.value.xy
                    tiles.value.addMonster(monster.newPlayer(xy, playerHP))

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
                    exitTile.error.errorState
            of false:
                startingTile.error.errorState
        of false:
            tiles.error.errorState


    proc seedState(): State =
        let
            now = times.getTime()
            seed = times.toUnix(now) * 1_000_000_000 + times.nanosecond(now)
            level = game.LevelNum(1)

        # So we can reproduce weird situtations
        echo seed

        var rng = randomness.initRand(seed)
        startLevel(level, rng, game.HP(6))


# It seems like it should be provable that `state.state` is accessible
# inside an `if` that checks `state.screen == Screen.Running`, but it
# doesn't work currently. See https://github.com/nim-lang/Nim/issues/7882
{.push warning[ProveField]: off.}
no_ex:
    proc showTitle(state: var State) =
        case state.screen:
        of Screen.Dead, Screen.Running:
            state = State(
                screen: Screen.Title,
                prevState: some(state.state)
            )
        else:
            discard

    proc movePlayer(state: var State, dxy: game.DeltaXY) =
        if state.screen == Screen.Running:
            let tile = state.state.tiles.getTile(state.state.xy)
            let monster = tile.monster
            if monster.isSome:
                let moved = state.state.tiles.tryMove(
                    monster.get,
                    dxy
                )

                if moved.isSome:
                    case state.state.tiles.getTile(moved.get.xy).kind:
                    of Kind.Exit:
                        if monster.get.isPlayer:
                            if state.state.level == high(game.LevelNum):
                                state.showTitle
                            else:
                                state = startLevel(
                                    game.LevelNum(int(state.state.level) + 1),
                                    state.state.rng,
                                    monster.get.hp + Damage(2)
                                )
                            return
                    else:
                        discard

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
                let message = "Could not find player!\n" &
                    "expected the player to be at " & $state.state.xy & "\n" &
                    "but instead got:\n" &
                    $tile
                state = errorState(message)



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

type
    TextX = int32
    TextY = int32
    FontSize = int32

    TextSpec = tuple
        text: string
        size: FontSize
        centered: bool
        y: TextY
        colour: Color

no_ex:
    proc drawText(spec: TextSpec) =
        let cText: cstring = spec.text

        let textX: TextX = sizes.playAreaX + (if spec.centered:
            (sizes.playAreaW - MeasureText(cText, spec.size)) div 2
        else:
            sizes.playAreaW - game.UIWidth*sizes.tile + MeasureText("m", spec.size)
        )

        DrawText(
            cText,
            textX,
            sizes.playAreaY + spec.y,
            spec.size,
            spec.colour
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

        const UIFontSize: FontSize = FontSize(30)
        (
            text: "Level: " & $int(state.level),
            size: UIFontSize,
            centered: false,
            y: TextY(UIFontSize),
            colour: VIOLET
        ).drawText

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

            (
                text: "Awes-nim",
                size: FontSize(40),
                centered: true,
                y: TextY(sizes.playAreaH / 2 - 110),
                colour: WHITE
            ).drawText

            (
                text: "Broughlike",
                size: FontSize(70),
                centered: true,
                y: TextY(sizes.playAreaH / 2 - 50),
                colour: WHITE
            ).drawText

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
