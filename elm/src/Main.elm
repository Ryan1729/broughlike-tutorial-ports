module Main exposing (..)

import Array exposing (Array)
import Browser
import Browser.Events
import Game exposing (DeltaX(..), DeltaY(..), H(..), LevelNum(..), Located, SpriteIndex(..), W(..), X(..), Y(..), moveX, moveY)
import Html
import Json.Decode as JD
import Map
import Monster exposing (HP(..), Monster)
import Ports
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


type Model
    = Error String
    | Title (Maybe State) Seed
    | Running State
    | Dead State


type alias State =
    { player : Located {}
    , seed : Seed
    , tiles : Tiles
    , level : LevelNum
    }


modelFromSeed : Seed -> Model
modelFromSeed seedIn =
    let
        levelNum =
            LevelNum 1

        ( levelRes, seed1 ) =
            Random.step (Map.generateLevel levelNum) seedIn

        stateRes =
            Result.andThen
                (\tilesIn ->
                    let
                        ( startingTileRes, seed ) =
                            Random.step (Tiles.randomPassableTile tilesIn) seed1
                    in
                    Result.map
                        (\{ x, y } ->
                            let
                                player =
                                    { x = x, y = y }

                                tiles =
                                    Tiles.addMonster tilesIn { kind = Monster.Player, x = player.x, y = player.y }
                            in
                            { player = player
                            , seed = seed
                            , tiles = tiles
                            , level = levelNum
                            }
                        )
                        startingTileRes
                )
                levelRes
    in
    case stateRes of
        Err e ->
            Error e

        Ok s ->
            Running s


draw : Model -> Cmd Msg
draw model =
    Ports.perform
        (case model of
            Title Nothing _ ->
                Array.push Ports.drawOverlay Array.empty

            Title (Just state) _ ->
                drawState state
                    |> Array.push Ports.drawOverlay

            Running state ->
                drawState state

            Dead state ->
                drawState state

            Error _ ->
                Array.push Ports.drawOverlay Array.empty
        )


drawState : State -> Array Ports.CommandRecord
drawState state =
    Tiles.mapToArray Tile.draw state.tiles
        |> (\prev ->
                Tiles.mapToArray .monster state.tiles
                    |> filterOutNothings
                    |> arrayAndThen Monster.draw
                    |> Array.append prev
           )


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


init : Int -> ( Model, Cmd Msg )
init seed =
    ( Random.initialSeed seed
        |> Title Nothing
    , Ports.setCanvasDimensions ( Game.pixelWidth, Game.pixelHeight )
        |> Array.repeat 1
        |> Ports.perform
    )


movePlayer : DeltaX -> DeltaY -> State -> Model
movePlayer dx dy state =
    let
        m =
            getPlayer state
                |> Maybe.andThen
                    (\player -> Tiles.tryMove state.tiles player dx dy)
    in
    case m of
        Nothing ->
            Running state

        Just { tiles, moved } ->
            { state | tiles = tiles, player = { x = moved.x, y = moved.y } }
                |> tick


getPlayer : State -> Maybe Monster
getPlayer state =
    Tiles.get state.tiles state.player
        |> .monster


tick : State -> Model
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
                if m.kind == Monster.Player then
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
        |> (\s ->
                case getPlayer s of
                    Nothing ->
                        Running s

                    Just player ->
                        if player.dead then
                            Dead s

                        else
                            Running s
           )


update msg model =
    case msg of
        Tick ->
            ( model
            , draw model
            )

        Input input ->
            ( case model of
                Title _ seed ->
                    modelFromSeed seed

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
                            Running state

                Dead state ->
                    Title (Just state) state.seed

                Error _ ->
                    model
            , Cmd.none
            )


subscriptions _ =
    Sub.batch
        [ Browser.Events.onAnimationFrame (\_ -> Tick)
        , JD.field "key" JD.string
            |> JD.map toInput
            |> Browser.Events.onKeyDown
        ]


type Msg
    = Tick
    | Input Input


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
    case model of
        Error e ->
            Html.text e

        _ ->
            Html.text ""
