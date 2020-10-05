module Main exposing (..)

import Browser
import Html
import Ports
import Time
import Types exposing (Model, Msg(..))


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Types.defaultModel, Cmd.none )


subscriptions _ =
    Time.every 15 (\_ -> Tick)


update msg model =
    case msg of
        Tick ->
            ( model, Ports.draw model )


view model =
    Html.text ""
