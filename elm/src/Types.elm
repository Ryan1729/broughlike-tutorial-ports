module Types exposing (..)


type alias Model =
    { x : X
    , y : Y
    }


defaultModel : Model
defaultModel =
    { x = X 0
    , y = Y 0
    }


type X
    = X Float


type Y
    = Y Float


type Msg
    = Tick
