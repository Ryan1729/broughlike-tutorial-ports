module Main exposing (..)

import Array
import Browser
import Browser.Events
import Game exposing (H(..), W(..), X(..), Y(..), decX, decY, incX, incY)
import Html
import Json.Decode as JD
import Map exposing (Tiles)
import Ports
import Random exposing (Seed)
import Tile


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
    { x : X
    , y : Y
    , seed : Seed
    , tiles : Tiles
    }


modelFromSeed : Seed -> Model
modelFromSeed seedIn =
    let
        ( tilesRes, seed1 ) =
            Random.step Map.levelGen seedIn
    in
    Result.andThen
        (\tiles ->
            let
                ( startingTileRes, seed ) =
                    Random.step (Map.randomPassableTile tiles) seed1
            in
            Result.map
                (\startingTile ->
                    { x = startingTile.x
                    , y = startingTile.y
                    , seed = seed
                    , tiles = tiles
                    }
                )
                startingTileRes
        )
        tilesRes


draw : State -> Cmd Msg
draw state =
    Map.map Tile.draw state.tiles
        |> Array.push (Ports.drawSprite (Game.SpriteIndex 0) state.x state.y)
        |> Ports.perform


init : Int -> ( Model, Cmd Msg )
init seed =
    ( Random.initialSeed seed
        |> modelFromSeed
    , Ports.setCanvasDimensions ( Game.pixelWidth, Game.pixelHeight )
        |> Array.repeat 1
        |> Ports.perform
    )


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
                                { state | y = decY state.y }

                            Down ->
                                { state | y = incY state.y }

                            Left ->
                                { state | x = decX state.x }

                            Right ->
                                { state | x = incX state.x }

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
