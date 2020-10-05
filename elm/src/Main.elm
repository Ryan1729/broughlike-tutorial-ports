module Main exposing (..)

import Browser
import Html
import Time
import Types exposing (Model, Msg(..))


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : Model -> ( Model, Cmd Msg )
init model =
    ( model, Cmd.none )


subscriptions _ =
    Time.every 15 (\_ -> Tick)


update msg model =
    case msg of
        Tick ->
            ( model, Cmd.none )


view model =
    Html.text ""
