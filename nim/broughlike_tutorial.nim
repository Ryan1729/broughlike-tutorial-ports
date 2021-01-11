
import raylib
# Put this above everything but the raylib import, since it seems like we get
# SIGSEGV errors if we call (some?) raylib stuff before calling this.
InitWindow 0, 0, "AWESOME BROUGHLIKE"

InitAudioDevice()

from algorithm import sort
from math import nil
from strutils import replace
from sequtils import map
from json import parseFile, JsonNode, `%`
from times import nil
from options import Option, isSome, get, none, some

from assets import nil
from randomness import rand01, shuffle
from tile import Kind, newExit
from monster import draw, isPlayer, Damage, `+`
from res import ok, err
from game import `-=`, `+=`, `==`, no_ex, DeltaX, DeltaY, `$`, Score, floatXY,
        Counter, `<`, SoundSpec, deltasFrom
from map import generateLevel, randomPassableTile, setMonster, spawnMonster,
        tryMove, getTile, replace, setTreasure
from world import tick, AfterTick, maxNumSpells, SpellCount, addSpell,
        PostSpell, PostSpellKind

const AQUA = Color(a: 0xffu8, r: 0, g: 0xffu8, b: 0xffu8)
const INDIGO = Color(a: 0xffu8, r: 0x4bu8, g: 0, b: 0x82u8)
const VIOLET = Color(a: 0xffu8, r: 0xeeu8, g: 0x82u8, b: 0xeeu8)

type
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

    proc startLevel*(
        level: game.LevelNum,
        rng: var randomness.Rand,
        playerHP: game.HP,
        score: Score,
        numSpells: world.SpellCount,
        retainedSpells: Option[world.SpellBook] = none(world.SpellBook)
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
                    tiles.value.setMonster(monster.newPlayer(xy, playerHP))

                    let spawnRate = game.Counter(15)

                    let shake: game.Shake = (
                        amount: Counter(0),
                        x: 0.0,
                        y: 0.0
                    )

                    var spells: world.SpellBook

                    if retainedSpells.isSome:
                        spells = retainedSpells.get
                    else:
                        var spellSeq = world.allSpellNames()
                        rng.shuffle(spellSeq)

                        var spellsToUse = spellSeq.len
                        if numSpells < spellsToUse:
                            spellsToUse = numSpells

                        for i in 0..<spellsToUse:
                            spells[i] = some(spellSeq[i])

                    State(
                        screen: Screen.Running,
                        state: (
                            xy: xy,
                            tiles: tiles.value,
                            rng: rng,
                            level: level,
                            spawnCounter: spawnRate,
                            spawnRate: spawnRate,
                            score: score,
                            shake: shake,
                            spells: spells,
                            numSpells: numSpells,
                            lastMove: (x: game.DXm1, y: game.DY0)
                        )
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
            numSpells = world.SpellCount(9)                     #1)

        # So we can reproduce weird situtations
        echo seed

        var rng = randomness.initRand(seed)
        startLevel(level, rng, game.HP(6), Score(0), numSpells)

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

var
    state = State(screen: Screen.Title, prevState: none(world.State))
    sizes: sizesObj

var spritesheet: Texture2D = LoadTextureFromImage(assets.spritesheetImage)

no_ex:
    proc drawSpriteFloat(shake: game.Shake, sprite: game.SpriteIndex,
            xy: floatXY, alpha: float = 1.0) =
        var tint = WHITE
        tint.a = uint8(alpha * float(255))
        DrawTexturePro(
            spritesheet,
            Rectangle(x: float(sprite) * 16, y: 0, width: 16, height: 16),
            Rectangle(
                x: float(sizes.playAreaX) + (xy.x * float(sizes.tile)) +
                        shake.x,
                y: float(sizes.playAreaY) + (xy.y * float(sizes.tile)) +
                        shake.y,
                width: float(sizes.tile),
                height: float(sizes.tile)
            ),
            Vector2(x: 0, y: 0),
            0.0,
            tint
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
        SpellListNumber
        SpellListName

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

        const widestNumber = "8) "

        let em = MeasureText("m", spec.size)
        let textX: TextX = sizes.playAreaX + (case spec.mode
        of TextMode.UI:
            sizes.playAreaW - game.UIWidth*sizes.tile + em
        of TextMode.SpellListNumber:
            let base = sizes.playAreaW - game.UIWidth*sizes.tile + em

            base + MeasureText(widestNumber, spec.size) - MeasureText(spec.text, spec.size)
        of TextMode.SpellListName:
            let base = sizes.playAreaW - game.UIWidth*sizes.tile + em
            base + MeasureText(widestNumber, spec.size)
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

let sounds = (
    hit1: LoadSoundFromWave(assets.hit1),
    hit2: LoadSoundFromWave(assets.hit2),
    treasure: LoadSoundFromWave(assets.treasure),
    newLevel: LoadSoundFromWave(assets.newLevel),
    spell: LoadSoundFromWave(assets.spell)
)

no_ex:
    proc playSpecifiedSound(spec: SoundSpec) =
        PlaySoundMulti(
            case spec
            of hit1:
                sounds.hit1
            of hit2:
                sounds.hit2
            of treasure:
                sounds.treasure
            of newLevel:
                sounds.newLevel
            of spell:
                sounds.spell
        )

const platform = game.Platform(
    spriteFloat: drawSpriteFloat,
    sound: playSpecifiedSound
)

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

    proc doTick(state: var State) =
        let afterTick = tick(state.state, platform)

        case afterTick
        of AfterTick.NoChange:
            discard
        of AfterTick.PlayerDied:
            addScore(state.state.score, Outcome.Loss)

            state = State(
                screen: Screen.Dead,
                state: state.state,
            )

    proc processPlayerMovement(
        state: var State,
        platform: game.Platform,
        player: monster.Monster
    ) =
        if not player.isPlayer:
            return

        let targetTile = state.state.tiles.getTile(player.xy)
        case targetTile.kind:
        of Kind.Exit:
            platform.sound(game.SoundSpec.newLevel)

            if state.state.level == high(game.LevelNum):
                addScore(state.state.score, Outcome.Win)
                state.showTitle
            else:
                state = startLevel(
                    game.LevelNum(int(state.state.level) + 1),
                    state.state.rng,
                    player.hp + Damage(2),
                    state.state.score,
                    state.state.numSpells
                )
            return
        of Kind.Floor:
            if targetTile.treasure:
                state.state.score += 1

                if int(state.state.score) mod 3 == 0 and
                        state.state.numSpells < maxNumSpells:
                    state.state.numSpells += 1
                    state.state.addSpell()

                platform.sound(game.SoundSpec.treasure)

                state.state.tiles.setTreasure(targetTile.xy, false)
                state.state.rng.spawnMonster(state.state.tiles)
        else:
            discard

        let deltas = (source: state.state.xy, target: player.xy).deltasFrom
        if deltas.isSome:
            state.state.lastMove = deltas.get

        state.state.xy = player.xy

        doTick(state)


    proc movePlayer(state: var State, dxy: game.DeltaXY) =
        if state.screen == Screen.Running:
            let tile = state.state.tiles.getTile(state.state.xy)
            let monster = tile.monster
            if monster.isSome:
                let moved = state.state.tiles.tryMove(
                    state.state.shake,
                    platform,
                    monster.get,
                    dxy
                )

                if moved.isSome:
                    processPlayerMovement(state, platform, moved.get)
            else:
                let message = "Could not find player!\n" &
                    "expected the player to be at " & $state.state.xy & "\n" &
                    "but instead got:\n" &
                    $tile
                state = errorState(message)

    proc castSpell(state: var State, page: world.SpellPage) =
        if state.screen == Screen.Running:
            let postSpell = world.castSpell(
                state.state,
                platform,
                page
            )

            case postSpell.kind
            of PlayerMoved:
                processPlayerMovement(state, platform, postSpell.player)
                return # we already did the tick
            of StartLevel:
                state = startLevel(
                    state.state.level,
                    state.state.rng,
                    game.HP(2),
                    state.state.score,
                    state.state.numSpells,
                    some(state.state.spells)
                )
            of AllEffectsHandled:
                discard

            doTick(state)

{.pop.}

no_ex:
    proc drawState(state: var world.State) =
        map.draw(state.tiles, state.shake, platform)

        for i in 0..<state.tiles.len:
            state.tiles[i].monster.draw(state.shake, platform)

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

        for i in 0..<state.spells.len:
            let spellNumber = $(i+1) & ") "

            let spellName: string = if state.spells[i].isSome:
                $state.spells[i].get
            else:
                ""

            let y = TextY(UIFontSize * 4 + i * 40)

            (
                text: spellNumber,
                size: UIFontSize,
                mode: TextMode.SpellListNumber,
                y: y,
                colour: AQUA
            ).drawText

            (
                text: spellName,
                size: UIFontSize,
                mode: TextMode.SpellListName,
                y: y,
                colour: AQUA
            ).drawText


        #screenshake
        if state.shake.amount > 0:
            state.shake.amount.dec()

        let shakeAmount = float(state.shake.amount)
        let shakeAngle = state.rng.rand01()*math.PI*2.0
        state.shake.x = math.round(math.cos(shakeAngle)*shakeAmount)
        state.shake.y = math.round(math.sin(shakeAngle)*shakeAmount)

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

const GameplayKeys = [
    KEY_W,
    KEY_UP,
    KEY_S,
    KEY_DOWN,
    KEY_A,
    KEY_LEFT,
    KEY_D,
    KEY_RIGHT,
    KEY_ONE,
    KEY_TWO,
    KEY_THREE,
    KEY_FOUR,
    KEY_FIVE,
    KEY_SIX,
    KEY_SEVEN,
    KEY_EIGHT,
    KEY_NINE,
]

no_ex:
    proc anyGameplayKeysPressed(): bool =
        for key in GameplayKeys:
            if IsKeyPressed(key):
                return true
        return false

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

        if IsKeyPressed(KEY_ONE):
            castSpell(state, world.SpellPage(0))
        if IsKeyPressed(KEY_TWO):
            castSpell(state, world.SpellPage(1))
        if IsKeyPressed(KEY_THREE):
            castSpell(state, world.SpellPage(2))
        if IsKeyPressed(KEY_FOUR):
            castSpell(state, world.SpellPage(3))
        if IsKeyPressed(KEY_FIVE):
            castSpell(state, world.SpellPage(4))
        if IsKeyPressed(KEY_SIX):
            castSpell(state, world.SpellPage(5))
        if IsKeyPressed(KEY_SEVEN):
            castSpell(state, world.SpellPage(6))
        if IsKeyPressed(KEY_EIGHT):
            castSpell(state, world.SpellPage(7))
        if IsKeyPressed(KEY_NINE):
            castSpell(state, world.SpellPage(8))
    of Screen.Dead:
        if anyGameplayKeysPressed():
            showTitle(state)
    of Screen.Error:
        discard

    BeginDrawing()

    draw()

    EndDrawing()
