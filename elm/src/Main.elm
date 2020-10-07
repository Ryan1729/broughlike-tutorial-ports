module Main exposing (..)

import Array
import Browser
import Browser.Events
import Game exposing (H, Model, W, X, Y, decX, decY, incX, incY)
import Html
import Json.Decode as JD
import Ports


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Game.defaultModel
    , Ports.setCanvasDimensions ( Game.pixelWidth, Game.pixelHeight )
        |> Array.repeat 1
        |> Ports.perform
    )


update msg model =
    case msg of
        Tick ->
            ( model
            , Ports.draw (Game.SpriteIndex 0) model.x model.y
                |> Array.repeat 1
                |> Ports.perform
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
