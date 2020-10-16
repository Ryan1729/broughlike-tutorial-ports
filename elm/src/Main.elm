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


type alias Model =
    Result String State


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
    in
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


draw : State -> Cmd Msg
draw state =
    Tiles.mapToArray Tile.draw state.tiles
        |> (\prev ->
                Tiles.mapToArray .monster state.tiles
                    |> filterOutNothings
                    |> Array.map Monster.draw
                    |> Array.append prev
           )
        |> Ports.perform


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
        |> modelFromSeed
    , Ports.setCanvasDimensions ( Game.pixelWidth, Game.pixelHeight )
        |> Array.repeat 1
        |> Ports.perform
    )


movePlayer : State -> DeltaX -> DeltaY -> State
movePlayer state dx dy =
    let
        m =
            getPlayer state
                |> Maybe.andThen
                    (\player -> Tiles.tryMove state.tiles player dx dy)
    in
    case m of
        Nothing ->
            state

        Just ( tiles, { x, y } ) ->
            { state | tiles = tiles, player = { x = x, y = y } }
                |> tick


getPlayer : State -> Maybe Monster
getPlayer state =
    Tiles.get state.tiles state.player
        |> .monster


tick : State -> State
tick stateIn =
    Tiles.foldXY
        (\xy state ->
            case
                Tiles.get state.tiles xy
                    |> (\t -> Maybe.map (\m -> ( t, m )) t.monster)
            of
                Nothing ->
                    state

                Just ( tile, m ) ->
                    if m.kind == Monster.Player then
                        -- The player updating is handled before we call `tick`
                        state

                    else if Monster.isDead m then
                        { state
                            | tiles = Tiles.set { tile | monster = Nothing } state.tiles
                        }

                    else
                        Tiles.updateMonster state m
        )
        stateIn


update msg model =
    case model of
        Ok state ->
            case msg of
                Tick ->
                    ( model
                    , draw state
                    )

                Input input ->
                    ( Ok
                        (case input of
                            Up ->
                                movePlayer state DX0 DYm1

                            Down ->
                                movePlayer state DX0 DY1

                            Left ->
                                movePlayer state DXm1 DY0

                            Right ->
                                movePlayer state DX1 DY0

                            Other ->
                                state
                        )
                    , Cmd.none
                    )

        Err _ ->
            ( model
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
        Ok _ ->
            Html.text ""

        Err e ->
            Html.text e
