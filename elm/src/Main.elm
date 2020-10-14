module Main exposing (..)

import Array
import Browser
import Browser.Events
import Game exposing (DeltaX(..), DeltaY(..), H(..), LevelNum(..), W(..), X(..), Y(..), moveX, moveY)
import Html
import Json.Decode as JD
import Map
import Monster exposing (Monster, Monsters)
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
    { player : Monster
    , seed : Seed
    , tiles : Tiles
    , monsters : Monsters
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
        (\( tilesIn, monstersIn ) ->
            let
                ( startingTileRes, seed ) =
                    Random.step (Tiles.randomPassableTile tilesIn) seed1
            in
            Result.map
                (\startingTile ->
                    let
                        ( tiles, player ) =
                            Monster.add tilesIn { kind = Monster.Player, x = startingTile.x, y = startingTile.y }
                    in
                    { player = player
                    , seed = seed
                    , tiles = tiles
                    , monsters = monstersIn
                    , level = levelNum
                    }
                )
                startingTileRes
        )
        levelRes


draw : State -> Cmd Msg
draw state =
    Tiles.map Tile.draw state.tiles
        |> (\prev -> Array.map Monster.draw state.monsters |> Array.append prev)
        |> Array.push (Monster.draw state.player)
        |> Ports.perform


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
    case Monster.tryMove state.tiles state.player dx dy of
        Nothing ->
            state

        Just ( tiles, player ) ->
            { state | tiles = tiles, player = player }


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
