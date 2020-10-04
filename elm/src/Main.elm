module Main exposing (..)

import Browser
import Html


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


type alias Model =
    ()


init : Model -> ( Model, Cmd Msg )
init model =
    ( model, Cmd.none )


type alias Msg =
    ()


update msg model =
    ( model, Cmd.none )


view model =
    Html.text "Hello, World!"
