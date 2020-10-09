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
    { x : X
    , y : Y
    , seed : Seed
    , tiles : Tiles
    }


modelFromSeed : Seed -> Model
modelFromSeed seedIn =
    let
        ( tiles, seed ) =
            Random.step Map.levelGen seedIn
    in
    { x = X 0
    , y = Y 0
    , seed = seed
    , tiles = tiles
    }


draw : Model -> Cmd Msg
draw model =
    Map.map Tile.draw model.tiles
        |> Array.push (Ports.drawSprite (Game.SpriteIndex 0) model.x model.y)
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
    case msg of
        Tick ->
            ( model
            , draw model
            )

        Input input ->
            ( case input of
                Up ->
                    { model | y = decY model.y }

                Down ->
                    { model | y = incY model.y }

                Left ->
                    { model | x = decX model.x }

                Right ->
                    { model | x = incX model.x }

                Other ->
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
    Html.text ""
