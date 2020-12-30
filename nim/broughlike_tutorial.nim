
import raylib
# Put this above everything but the raylib import, since it seems like we get
# SIGSEGV errors if we call (some?) raylib stuff before calling this.
InitWindow 0, 0, "AWESOME BROUGHLIKE"

from algorithm import sort
from strutils import replace
from sequtils import map
from math import nil
from json import parseFile, JsonNode, `%`
from times import nil
from options import Option, isSome, get, none, some

from assets import nil
from randomness import nil
from tile import Kind, newExit
from monster import draw, isPlayer, Damage, `+`
from res import ok, err
from game import `-=`, `+=`, `==`, no_ex, DeltaX, DeltaY, `$`, Score
from map import generateLevel, randomPassableTile, addMonster, spawnMonster,
        tryMove, getTile, replace, setTreasure
from world import tick, AfterTick

const AQUA = Color(a: 0xffu8, r: 0, g: 0xffu8, b: 0xffu8)
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
    proc centerY(ss: sizesObj): Size =
        ss.playAreaY + ss.playAreaH div 2

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
                            spawnRate: spawnRate,
                            score: Score(0)
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

type
    RunNum* = uint

    ScoreRow* = tuple
        score: Score
        run: RunNum
        totalScore: Score
        active: bool

    Outcome* = enum
        Loss
        Win

    ScoreRowJson* = object
        score: uint
        run: uint
        totalScore: uint
        active: bool

const SAVE_FILE_NAME = "Awes-nim_Broughlike.sav"

type ScoreRows = seq[ScoreRow]

var scoresCache = none(ScoreRows)

{.push warning[ProveField]: off.}
no_ex:
    proc getScores(): ScoreRows =
        if scoresCache.isSome:
            return scoresCache.get.deepCopy

        try:
            # Apparently (as in according to compile errors) we can
            # unmarshal into tuples containing distinct types but we can't
            # directly convert that to JSON? Odd.
            result = json.to(json.parseFile(SAVE_FILE_NAME), ScoreRows)
        except Exception:
            result = @[]

        scoresCache = some(result)
{.pop.}
no_ex:
    proc scoreRowToJson(row: ScoreRow): ScoreRowJson =
        ScoreRowJson(
            score: uint(row.score),
            run: uint(row.run),
            totalScore: uint(row.totalScore),
            active: row.active
        )

    proc saveScores(scores: ScoreRows) =
        let jsonRows: seq[ScoreRowJson] = scores.map(scoreRowToJson)
        let node: JsonNode = %(jsonRows)
        try:
            writeFile(SAVE_FILE_NAME, json.`$`(node))
            scoresCache = none(ScoreRows)
        except Exception:
            # presumably the player thinks getting to play with no high
            # scores saved is better than not being able to play.
            echo getCurrentExceptionMsg()

    proc addScore(score: Score, outcome: Outcome) =
        var scores = getScores()

        var scoreRow: ScoreRow = (
            score: score,
            run: uint(1),
            totalScore: score,
            active: outcome == Outcome.Win
        )

        if scores.len > 0:
            let lastScore: ScoreRow = scores.pop()

            if lastScore.active:
                scoreRow.run = lastScore.run + 1
                scoreRow.totalScore += lastScore.totalScore
            else:
                scores.add(lastScore)


        scores.add(scoreRow)

        saveScores(scores)


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
                    let targetTile = state.state.tiles.getTile(moved.get.xy)
                    case targetTile.kind:
                    of Kind.Exit:
                        if monster.get.isPlayer:
                            if state.state.level == high(game.LevelNum):
                                addScore(state.state.score, Outcome.Win)
                                state.showTitle
                            else:
                                state = startLevel(
                                    game.LevelNum(int(state.state.level) + 1),
                                    state.state.rng,
                                    monster.get.hp + Damage(2)
                                )
                            return
                    of Kind.Floor:
                        if monster.get.isPlayer:
                            if targetTile.treasure:
                                state.state.score += 1;
                                state.state.tiles.setTreasure(targetTile.xy, false)
                                state.state.rng.spawnMonster(state.state.tiles)
                    else:
                        discard

                    state.state.xy = moved.get.xy
                    case state.state.tick
                    of AfterTick.NoChange:
                        discard
                    of AfterTick.PlayerDied:
                        addScore(state.state.score, Outcome.Loss)

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

    proc rightPad(strings: seq[string]): string =
        result = ""

        for text in strings:
            result &= text
            for i in text.len..<10:
                result &= " "

type
    TextX = int32
    TextY = int32
    FontSize = int32

    TextMode = enum
        UI
        TitleScreen
        ScoreCol1
        ScoreCol2
        ScoreCol3

    TextSpec = tuple
        text: string
        size: FontSize
        mode: TextMode
        y: TextY
        colour: Color

let scoreHeader = rightPad(@["RUN", "SCORE", "TOTAL"])
let scoreHeaderFirst = rightPad(@["RUN"])
let scoreHeaderFirst2 = rightPad(@["RUN", "SCORE"])

no_ex:
    proc drawText(spec: TextSpec) =
        var cText: cstring = spec.text

        let em = MeasureText("m", spec.size)
        let textX: TextX = sizes.playAreaX + (case spec.mode
        of TextMode.UI:
            sizes.playAreaW - game.UIWidth*sizes.tile + em
        of TextMode.TitleScreen:
            (
                sizes.playAreaW - MeasureText(spec.text, spec.size)
            ) div 2
        of TextMode.ScoreCol1:
            (
                sizes.playAreaW - MeasureText(scoreHeader, spec.size) + em
            ) div 2
        of TextMode.ScoreCol2:
            (
                sizes.playAreaW - MeasureText(scoreHeader, spec.size) + em
            ) div 2 + MeasureText(scoreHeaderFirst, spec.size)
        of TextMode.ScoreCol3:
            (
                sizes.playAreaW - MeasureText(scoreHeader, spec.size) + em
            ) div 2 + MeasureText(scoreHeaderFirst2, spec.size)
        )

        DrawText(
            cText,
            textX,
            sizes.playAreaY + spec.y,
            spec.size,
            spec.colour
        )


const platform = game.Platform(
    spriteFloat: drawSpriteFloat
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
            mode: TextMode.UI,
            y: TextY(UIFontSize),
            colour: VIOLET
        ).drawText

        (
            text: "Score: " & $int(state.score),
            size: UIFontSize,
            mode: TextMode.UI,
            y: TextY(UIFontSize * 2),
            colour: VIOLET
        ).drawText

    proc drawScores() =
        const ScoresFontSize = FontSize(18)

        var scores = getScores()
        if scores.len > 0:
            let baseY = TextY(sizes.centerY + 48)

            (
                text: scoreHeader,
                size: ScoresFontSize,
                mode: TextMode.TitleScreen,
                y: baseY,
                colour: WHITE
            ).drawText

            let newestScore = scores.pop()

            let byTotalScore = proc(a: ScoreRow, b: ScoreRow): int =
                int(b.totalScore) - int(a.totalScore)

            scores.sort(byTotalScore)
            scores.insert(newestScore)

            var rowCount = scores.len
            if rowCount > 10:
                rowCount = 10

            for i in 0..<rowCount:
                let colour = if i == 0:
                        AQUA
                    else:
                        VIOLET
                let y = TextY(baseY + 24+i*24)

                (
                    text: $uint(scores[i].run),
                    size: ScoresFontSize,
                    mode: TextMode.ScoreCol1,
                    y: y,
                    colour: colour
                ).drawText

                (
                    text: $uint(scores[i].score),
                    size: ScoresFontSize,
                    mode: TextMode.ScoreCol2,
                    y: y,
                    colour: colour
                ).drawText

                (
                    text: $uint(scores[i].totalScore),
                    size: ScoresFontSize,
                    mode: TextMode.ScoreCol3,
                    y: y,
                    colour: colour
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
                mode: TextMode.TitleScreen,
                y: TextY(sizes.centerY - 110),
                colour: WHITE
            ).drawText

            (
                text: "Broughlike",
                size: FontSize(70),
                mode: TextMode.TitleScreen,
                y: TextY(sizes.centerY - 50),
                colour: WHITE
            ).drawText

            drawScores()

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
