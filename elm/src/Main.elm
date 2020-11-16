module Main exposing (..)

import Array exposing (Array)
import Browser
import Browser.Events
import Game exposing (DeltaX(..), DeltaY(..), H(..), LevelNum(..), Located, Positioned, Score(..), ScoreRow, Shake, SpriteIndex(..), W(..), X(..), Y(..), levelNumToString, moveX, moveY, screenShake)
import GameModel exposing (GameModel(..), SpellPage(..), State, cast, removeSpellName, startLevel)
import Html
import Json.Decode as JD
import Map
import Monster exposing (HP(..), Monster)
import Ports exposing (Colour(..), Sound(..), TextSpec, withNoCmd)
import Random exposing (Seed)
import Tile
import Tiles exposing (Tiles)


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { scores : List ScoreRow
    , game : GameModel
    }


incScore score =
    case score of
        Score s ->
            s
                + 1
                |> Score


scoreToString score =
    case score of
        Score s ->
            String.fromInt s


startingHp =
    HP 3


numLevels =
    LevelNum 6


startGame : Seed -> GameModel
startGame seedIn =
    LevelNum 1
        |> startLevel (Score 0) seedIn startingHp Nothing 1


draw : Model -> ( Model, CommandRecords )
draw model =
    let
        { scores, game } =
            model

        gameToModel g =
            { model | game = g }
    in
    case game of
        Title Nothing _ ->
            ( model
            , drawTitle scores Array.empty
            )

        Title (Just state) seed ->
            let
                ( newState, cmds ) =
                    drawState state
            in
            ( newState, drawTitle scores cmds )
                |> withCmdsMap (\s -> Title (Just s) seed |> gameToModel)

        Running state ->
            drawState state
                |> withCmdsMap (Running >> gameToModel)

        Dead state ->
            drawState state
                |> withCmdsMap (Dead >> gameToModel)

        Error _ ->
            ( model
            , Array.push Ports.drawOverlay Array.empty
            )


type alias CommandRecords =
    Array Ports.CommandRecord


drawTitle : List ScoreRow -> CommandRecords -> CommandRecords
drawTitle scores =
    let
        halfHeight =
            case Game.pixelHeight of
                H h ->
                    h / 2
    in
    Array.push Ports.drawOverlay
        >> pushText
            { text = "BROUGHLIKE"
            , size = 70
            , centered = True
            , y = halfHeight - 110 |> Y
            , colour = White
            }
        >> pushText
            { text = "tutori-elm"
            , size = 40
            , centered = True
            , y = halfHeight - 55 |> Y
            , colour = White
            }
        >> drawScores scores


drawScores : List ScoreRow -> CommandRecords -> CommandRecords
drawScores scoresIn commandsIn =
    let
        lastIndex =
            List.length scoresIn - 1
    in
    case ( List.take lastIndex scoresIn, List.drop lastIndex scoresIn ) of
        ( scores, newestScore :: [] ) ->
            let
                scoresTop =
                    case Game.pixelHeight of
                        H h ->
                            h / 2

                commands =
                    pushText
                        { text = rightPad [ "RUN", "SCORE", "TOTAL" ]
                        , size = 18
                        , centered = True
                        , y = Y scoresTop
                        , colour = White
                        }
                        commandsIn

                ( _, cs ) =
                    List.sortWith
                        (\a b ->
                            compare
                                (case b.totalScore of
                                    Score tsA ->
                                        tsA
                                )
                                (case a.totalScore of
                                    Score tsB ->
                                        tsB
                                )
                        )
                        scores
                        |> (::) newestScore
                        |> List.take 10
                        |> List.foldl
                            (\{ run, score, totalScore } ( i, cmds ) ->
                                ( i + 1
                                , pushText
                                    { text =
                                        rightPad
                                            [ String.fromInt run
                                            , scoreToString score
                                            , scoreToString totalScore
                                            ]
                                    , size = 18
                                    , centered = True
                                    , y = scoresTop + 24 + i * 24 |> Y
                                    , colour =
                                        if i == 0 then
                                            Aqua

                                        else
                                            Violet
                                    }
                                    cmds
                                )
                            )
                            ( 0, commands )
            in
            cs

        _ ->
            commandsIn


pushText : TextSpec -> CommandRecords -> CommandRecords
pushText textSpec =
    Ports.drawText textSpec
        |> Array.push


pushSpellText : State -> CommandRecords -> CommandRecords
pushSpellText { numSpells, spells } cmds =
    let
        step : ( Int, Maybe GameModel.SpellName ) -> CommandRecords -> CommandRecords
        step ( i, maybeSpellName ) =
            let
                spellNameString =
                    case maybeSpellName of
                        Just name ->
                            GameModel.spellNameToString name

                        Nothing ->
                            ""
            in
            pushText
                { text = String.fromInt i ++ ") " ++ spellNameString
                , size = 20
                , centered = False
                , y = (110 + (i - 1) * 40) |> toFloat |> Y
                , colour = Aqua
                }
    in
    GameModel.spellNamesWithOneBasedIndex spells
        |> List.take numSpells
        |> List.foldl step cmds


rightPad : List String -> String
rightPad =
    List.foldl
        (\text finalText ->
            String.repeat
                (10 - String.length text)
                " "
                |> String.append text
                |> String.append finalText
        )
        ""


drawState : State -> ( State, CommandRecords )
drawState stateIn =
    let
        ( shake, seed ) =
            Random.step (screenShake stateIn.shake) stateIn.seed

        state =
            { stateIn | shake = shake, seed = seed }

        prev =
            Tiles.toArray state.tiles
                |> arrayAndThen (Tile.draw shake)
                |> pushText
                    { text = "Level " ++ levelNumToString state.level
                    , size = 30
                    , centered = False
                    , y = Y 40
                    , colour = Violet
                    }
                |> pushText
                    { text = "Score: " ++ scoreToString state.score
                    , size = 30
                    , centered = False
                    , y = Y 70
                    , colour = Violet
                    }
                |> pushSpellText state

        ( newTiles, cmds ) =
            drawMonsters state.shake state.tiles
    in
    ( { state | tiles = newTiles }
    , Array.append prev cmds
    )


drawMonsters : Shake -> Tiles -> ( Tiles, CommandRecords )
drawMonsters shake tiles =
    Tiles.foldMonsters
        (\monster ( ts, oldCmds ) ->
            let
                ( newMonster, newCmds ) =
                    Monster.draw shake monster oldCmds
            in
            ( Tiles.transform (\tile -> { tile | monster = Just newMonster }) newMonster ts, newCmds )
        )
        ( tiles, Array.empty )
        tiles


arrayAndThen : (a -> Array b) -> Array a -> Array b
arrayAndThen callback array =
    Array.foldl
        (\a acc ->
            Array.append acc (callback a)
        )
        Array.empty
        array


type alias Flags =
    { scores : List ScoreRow
    , seed : Int
    }


decodeFlags : JD.Decoder Flags
decodeFlags =
    JD.map2 Flags
        (JD.field "scores" Ports.decodeScoreRows)
        (JD.field "seed" JD.int)


init : JD.Value -> ( Model, Cmd Msg )
init flags =
    ( case JD.decodeValue decodeFlags flags of
        Ok { seed, scores } ->
            { scores = scores
            , game =
                Random.initialSeed seed
                    |> Title Nothing
            }

        Err error ->
            { scores = []
            , game =
                "Error decoding flags: "
                    ++ JD.errorToString error
                    |> Error
            }
    , Ports.setCanvasDimensions ( Game.pixelWidth, Game.pixelHeight, Game.pixelUIWidth )
        |> Array.repeat 1
        |> Ports.perform
    )


movePlayer : DeltaX -> DeltaY -> State -> ( GameModel, CommandRecords )
movePlayer dx dy stateIn =
    let
        m =
            getPlayer stateIn
                |> Maybe.andThen
                    (\p ->
                        Tiles.tryMove stateIn.shake p dx dy stateIn.tiles
                            |> Maybe.map
                                (\record ->
                                    ( record, p )
                                )
                    )
    in
    case m of
        Nothing ->
            Running stateIn
                |> withNoCmd

        Just ( record, player ) ->
            let
                movedTiles =
                    record.tiles

                moved =
                    record.moved

                movedState =
                    { stateIn | shake = record.shake, tiles = movedTiles, player = { xPos = moved.xPos, yPos = moved.yPos } }

                tile =
                    Tiles.get movedTiles moved

                ( preTickModel, preTickCmds ) =
                    case tile.kind of
                        Tile.Exit ->
                            if movedState.level == numLevels then
                                movedState
                                    |> (\s ->
                                            ( Title (Just s) s.seed
                                            , Ports.addScore s.score Game.Win
                                                |> Array.repeat 1
                                            )
                                       )

                            else
                                let
                                    hp =
                                        case player.hp of
                                            HP h ->
                                                (h + 1)
                                                    |> min Monster.maxHP
                                                    |> HP
                                in
                                ( Game.incLevel movedState.level
                                    |> startLevel movedState.score movedState.seed hp Nothing movedState.numSpells
                                , Ports.playSound NewLevel
                                    |> Array.repeat 1
                                )

                        Tile.Floor ->
                            if tile.treasure then
                                let
                                    collectedTiles =
                                        Tiles.set { tile | treasure = False } movedState.tiles

                                    ( tilesRes, seed ) =
                                        Random.step (Map.spawnMonster collectedTiles) movedState.seed

                                    tiles =
                                        case tilesRes of
                                            -- The player won't mind if we don't spawn a monster if there is no room.
                                            Err _ ->
                                                collectedTiles

                                            Ok ts ->
                                                ts
                                in
                                ( { movedState
                                    | score = incScore movedState.score
                                    , tiles = tiles
                                    , seed = seed
                                  }
                                    |> GameModel.addSpellViaTreasureIfApplicable
                                    |> Running
                                , Ports.playSound Treasure
                                    |> Array.repeat 1
                                )

                            else
                                Running movedState
                                    |> withNoCmd

                        _ ->
                            Running movedState
                                |> withNoCmd

                ( postTickModel, postTickCmds ) =
                    case preTickModel of
                        Running s ->
                            tick s

                        Dead s ->
                            tick s

                        Title (Just s) _ ->
                            tick s

                        _ ->
                            withNoCmd preTickModel
            in
            ( postTickModel, Array.append (Array.append record.cmds preTickCmds) postTickCmds )


getPlayer : State -> Maybe Monster
getPlayer state =
    Tiles.get state.tiles state.player
        |> .monster


tick : State -> ( GameModel, CommandRecords )
tick stateIn =
    Tiles.foldXY
        (\xy list ->
            case
                Tiles.get stateIn.tiles xy
                    |> (\t -> Maybe.map (\m -> ( t, m )) t.monster)
            of
                Nothing ->
                    list

                Just pair ->
                    pair :: list
        )
        []
        -- We collect the tile, monster pairs into a list so that we don't hit
        -- the same monster twice in the iteration
        |> List.foldr
            (\( tile, m ) ( state, cmds ) ->
                if Monster.isPlayer m.kind then
                    -- The player updating is handled before we call `tick`
                    ( state, cmds )

                else if m.dead then
                    ( { state
                        | tiles = Tiles.set { tile | monster = Nothing } state.tiles
                      }
                    , cmds
                    )

                else
                    Tiles.updateMonster m ( state, cmds )
            )
            ( stateIn, Array.empty )
        |> (\( state, cmds ) ->
                let
                    s =
                        { state | spawnCounter = state.spawnCounter - 1 }
                in
                ( if s.spawnCounter <= 0 then
                    Map.spawnMonster s.tiles
                        |> (\tilesGen -> Random.step tilesGen s.seed)
                        |> (\( tilesRes, seed ) ->
                                { s
                                    | seed = seed
                                    , tiles =
                                        case tilesRes of
                                            Ok tiles ->
                                                tiles

                                            Err Tiles.NoPassableTile ->
                                                -- the player won't mind us not spawning a monster if we run out of room
                                                s.tiles
                                    , spawnCounter = s.spawnRate
                                    , spawnRate = s.spawnRate - 1
                                }
                           )

                  else
                    s
                , cmds
                )
           )
        |> (\( s, cmds ) ->
                case getPlayer s of
                    Nothing ->
                        ( Running s, cmds )

                    Just player ->
                        if player.dead then
                            ( Dead s, Array.push (Ports.addScore s.score Game.Loss) cmds )

                        else
                            ( Running s
                            , cmds
                            )
           )


performWithModel : ( Model, CommandRecords ) -> ( Model, Cmd msg )
performWithModel ( model, cmds ) =
    ( model, Ports.perform cmds )


update msg model =
    case msg of
        Tick ->
            draw model
                |> performWithModel

        Input input ->
            let
                ( game, updateCmds ) =
                    updateGame input model.game

                newModel =
                    { model | game = game }

                ( finalModel, drawCmds ) =
                    draw newModel
            in
            ( finalModel
            , drawCmds
                |> Array.append updateCmds
                |> Ports.perform
            )

        ScoreRows (Ok scores) ->
            ( { model | scores = scores }
            , Cmd.none
            )

        ScoreRows (Err _) ->
            -- If there is a decoding problem, (indicating a saving problem?
            -- maybe the disk is full?) the current score would be worth
            -- preserving in memory, since they could be saved later.
            ( model
            , Cmd.none
            )


withCmdsMap : (a -> b) -> ( a, CommandRecords ) -> ( b, CommandRecords )
withCmdsMap mapper ( a, cmds ) =
    ( mapper a, cmds )


updateGame input model =
    case model of
        Title _ seed ->
            startGame seed
                |> withNoCmd

        Running state ->
            case input of
                Up ->
                    movePlayer DX0 DYm1 state

                Down ->
                    movePlayer DX0 DY1 state

                Left ->
                    movePlayer DXm1 DY0 state

                Right ->
                    movePlayer DX1 DY0 state

                CastSpell spellIndex ->
                    castSpell state spellIndex

                Other ->
                    Running state |> withNoCmd

        Dead state ->
            Title (Just state) state.seed
                |> withNoCmd

        Error _ ->
            withNoCmd model


castSpell state spellPage =
    case removeSpellName state spellPage of
        Nothing ->
            Running state |> withNoCmd

        Just ( spellName, spellRemovedState ) ->
            case cast spellName spellRemovedState of
                ( Running runningState, cmds ) ->
                    let
                        ( runningTickState, tickCmds ) =
                            tick runningState
                    in
                    ( runningTickState, Array.append tickCmds cmds |> Array.push (Ports.playSound Spell) )

                ( Dead deadState, cmds ) ->
                    let
                        ( deadTickState, tickCmds ) =
                            tick deadState
                    in
                    ( deadTickState, Array.append tickCmds cmds |> Array.push (Ports.playSound Spell) )

                otherwise ->
                    otherwise


subscriptions _ =
    Sub.batch
        [ Browser.Events.onAnimationFrame (\_ -> Tick)

        --Browser.Events.onClick (JD.succeed Tick)
        , JD.field "key" JD.string
            |> JD.map toInput
            |> Browser.Events.onKeyDown
        , Ports.scoreList ScoreRows
        ]


type Msg
    = Tick
    | Input Input
    | ScoreRows (Result JD.Error (List ScoreRow))


type Input
    = Other
    | Up
    | Down
    | Left
    | Right
    | CastSpell SpellPage


toInput : String -> Msg
toInput s =
    Input
        (case s of
            "ArrowUp" ->
                Up

            "w" ->
                Up

            "ArrowDown" ->
                Down

            "s" ->
                Down

            "ArrowLeft" ->
                Left

            "a" ->
                Left

            "ArrowRight" ->
                Right

            "d" ->
                Right

            "1" ->
                CastSpell One

            "2" ->
                CastSpell Two

            "3" ->
                CastSpell Three

            "4" ->
                CastSpell Four

            "5" ->
                CastSpell Five

            "6" ->
                CastSpell Six

            "7" ->
                CastSpell Seven

            "8" ->
                CastSpell Eight

            "9" ->
                CastSpell Nine

            _ ->
                Other
        )


view model =
    case model.game of
        Error e ->
            Html.text e

        _ ->
            Html.text ""
