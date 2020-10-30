module Main exposing (..)

import Array exposing (Array)
import Browser
import Browser.Events
import Game exposing (DeltaX(..), DeltaY(..), H(..), LevelNum(..), Located, Score(..), ScoreRow, SpriteIndex(..), W(..), X(..), Y(..), levelNumToString, moveX, moveY)
import Html
import Json.Decode as JD
import Map
import Monster exposing (HP(..), Monster)
import Ports exposing (Colour(..), TextSpec)
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


type GameModel
    = Error String
    | Title (Maybe State) Seed
    | Running State
    | Dead State


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


type alias State =
    { player : Located {}
    , seed : Seed
    , tiles : Tiles
    , level : LevelNum
    , spawnCounter : Int
    , spawnRate : Int
    , score : Score
    }


initialSpawnRate =
    15


startingHp =
    HP 3


numLevels =
    LevelNum 6


startGame : Seed -> GameModel
startGame seedIn =
    LevelNum 1
        |> startLevel seedIn startingHp


startLevel : Seed -> HP -> LevelNum -> GameModel
startLevel seedIn hp levelNum =
    let
        ( levelRes, seed1 ) =
            Random.step (Map.generateLevel levelNum) seedIn

        stateRes : Result String State
        stateRes =
            Result.andThen
                (\tilesIn ->
                    let
                        tileGen =
                            Tiles.randomPassableTile tilesIn

                        ( startingTilesRes, seed ) =
                            Random.step
                                (Random.pair tileGen
                                    tileGen
                                    |> Random.pair
                                        (Random.list 3 tileGen)
                                    |> Random.map
                                        (\pair ->
                                            case pair of
                                                ( listOfResults, ( Ok t1, Ok t2 ) ) ->
                                                    case toResultOfList listOfResults of
                                                        Ok list ->
                                                            Ok ( t1, t2, list )

                                                        _ ->
                                                            Err Tiles.NoPassableTile

                                                _ ->
                                                    Err Tiles.NoPassableTile
                                        )
                                )
                                seed1
                    in
                    Result.mapError Tiles.noPassableTileToString startingTilesRes
                        |> Result.map
                            (\( playerTile, exitTile, treasureTiles ) ->
                                let
                                    player =
                                        { x = playerTile.x, y = playerTile.y }

                                    tiles : Tiles
                                    tiles =
                                        Tiles.addMonster tilesIn
                                            { kind = Monster.Player hp
                                            , x = player.x
                                            , y = player.y
                                            }
                                            |> (\ts ->
                                                    List.foldl
                                                        (\tt ->
                                                            Tiles.set { tt | treasure = True }
                                                        )
                                                        ts
                                                        treasureTiles
                                               )
                                            |> Tiles.replace Tile.exit exitTile
                                in
                                { player = player
                                , seed = seed
                                , tiles = tiles
                                , level = levelNum
                                , spawnRate = initialSpawnRate
                                , spawnCounter = initialSpawnRate
                                , score = Score 0
                                }
                            )
                )
                levelRes
    in
    case stateRes of
        Err e ->
            Error e

        Ok s ->
            Running s



-- I think this might reverse the order of the list, but for my current purposes,
-- I don't care whether it does or not.


toResultOfList : List (Result e a) -> Result e (List a)
toResultOfList results =
    toResultOfListHelper results []


toResultOfListHelper results output =
    case results of
        [] ->
            Ok output

        (Ok a) :: rest ->
            a
                :: output
                |> toResultOfListHelper rest

        (Err e) :: _ ->
            Err e


draw : Model -> Cmd Msg
draw { scores, game } =
    Ports.perform
        (case game of
            Title Nothing _ ->
                drawTitle scores Array.empty

            Title (Just state) _ ->
                drawState state
                    |> drawTitle scores

            Running state ->
                drawState state

            Dead state ->
                drawState state

            Error _ ->
                Array.push Ports.drawOverlay Array.empty
        )


drawTitle : List ScoreRow -> Array Ports.CommandRecord -> Array Ports.CommandRecord
drawTitle scores =
    let
        halfWidth =
            case Game.pixelWidth of
                W w ->
                    w / 2
    in
    Array.push Ports.drawOverlay
        >> pushText
            { text = "BROUGHLIKE"
            , size = 70
            , centered = True
            , y = halfWidth - 110 |> Y
            , colour = White
            }
        >> pushText
            { text = "tutori-elm"
            , size = 40
            , centered = True
            , y = halfWidth - 55 |> Y
            , colour = White
            }
        >> drawScores scores


pushText : TextSpec -> Array Ports.CommandRecord -> Array Ports.CommandRecord
pushText textSpec =
    Ports.drawText textSpec
        |> Array.push


drawScores : List ScoreRow -> Array Ports.CommandRecord -> Array Ports.CommandRecord
drawScores scoresIn commandsIn =
    let
        lastIndex =
            List.length scoresIn - 1
    in
    case ( List.take lastIndex scoresIn, List.drop lastIndex scoresIn ) of
        ( scores, newestScore :: [] ) ->
            let
                halfWidth =
                    case Game.pixelWidth of
                        W w ->
                            w / 2

                commands =
                    pushText
                        { text = rightPad [ "RUN", "SCORE", "TOTAL" ]
                        , size = 18
                        , centered = True
                        , y = Y halfWidth
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
                                    , y = halfWidth + 24 + i * 24 |> Y
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


rightPad : List String -> String
rightPad =
    List.foldr
        (\text finalText ->
            String.repeat
                (10 - String.length text)
                " "
                |> String.append text
                |> String.append finalText
        )
        ""


drawState : State -> Array Ports.CommandRecord
drawState state =
    Tiles.toArray state.tiles
        |> arrayAndThen Tile.draw
        |> (\prev ->
                Tiles.toArray state.tiles
                    |> Array.map .monster
                    |> filterOutNothings
                    |> arrayAndThen Monster.draw
                    |> Array.append prev
           )
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


arrayAndThen : (a -> Array b) -> Array a -> Array b
arrayAndThen callback array =
    Array.foldl
        (\a acc ->
            Array.append acc (callback a)
        )
        Array.empty
        array


filterOutNothings : Array (Maybe a) -> Array a
filterOutNothings =
    Array.foldl
        (\maybe acc ->
            case maybe of
                Just x ->
                    Array.push x acc

                Nothing ->
                    acc
        )
        Array.empty


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


movePlayer : DeltaX -> DeltaY -> State -> ( GameModel, Cmd Msg )
movePlayer dx dy stateIn =
    let
        m =
            getPlayer stateIn
                |> Maybe.andThen
                    (\p ->
                        Tiles.tryMove p dx dy stateIn.tiles
                            |> Maybe.map (\record -> ( record, p ))
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
                    { stateIn | tiles = movedTiles, player = { x = moved.x, y = moved.y } }

                tile =
                    Tiles.get movedTiles moved

                ( preTickModel, preTickCmd ) =
                    case tile.kind of
                        Tile.Exit ->
                            if movedState.level == numLevels then
                                movedState
                                    |> (\s ->
                                            ( Title (Just s) s.seed
                                            , Ports.addScore s.score Game.Win
                                                |> Array.repeat 1
                                                |> Ports.perform
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
                                Game.incLevel movedState.level
                                    |> startLevel movedState.seed hp
                                    |> withNoCmd

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
                                Running
                                    { movedState
                                        | score = incScore movedState.score
                                        , tiles = tiles
                                        , seed = seed
                                    }
                                    |> withNoCmd

                            else
                                Running movedState
                                    |> withNoCmd

                        _ ->
                            Running movedState
                                |> withNoCmd

                ( postTickModel, postTickCmd ) =
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
            ( postTickModel, Cmd.batch [ preTickCmd, postTickCmd ] )


getPlayer : State -> Maybe Monster
getPlayer state =
    Tiles.get state.tiles state.player
        |> .monster


tick : State -> ( GameModel, Cmd Msg )
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
            (\( tile, m ) state ->
                if Monster.isPlayer m.kind then
                    -- The player updating is handled before we call `tick`
                    state

                else if m.dead then
                    { state
                        | tiles = Tiles.set { tile | monster = Nothing } state.tiles
                    }

                else
                    Tiles.updateMonster m state
            )
            stateIn
        |> (\state ->
                let
                    s =
                        { state | spawnCounter = state.spawnCounter - 1 }
                in
                if s.spawnCounter <= 0 then
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
           )
        |> (\s ->
                case getPlayer s of
                    Nothing ->
                        Running s
                            |> withNoCmd

                    Just player ->
                        if player.dead then
                            ( Dead s, Ports.addScore s.score Game.Loss |> Array.repeat 1 |> Ports.perform )

                        else
                            Running s
                                |> withNoCmd
           )


update msg model =
    case msg of
        Tick ->
            ( model
            , draw model
            )

        Input input ->
            let
                ( game, cmd ) =
                    updateGame input model.game
            in
            ( { model | game = game }
            , cmd
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


withNoCmd : a -> ( a, Cmd msg )
withNoCmd a =
    ( a, Cmd.none )


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

                Other ->
                    Running state |> withNoCmd

        Dead state ->
            Title (Just state) state.seed
                |> withNoCmd

        Error _ ->
            withNoCmd model


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

            _ ->
                Other
        )


view model =
    case model.game of
        Error e ->
            Html.text e

        _ ->
            Html.text ""
