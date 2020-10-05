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


incX xx =
    X
        (case xx of
            X x ->
                x + 1
        )


decX xx =
    X
        (case xx of
            X x ->
                x - 1
        )


type Y
    = Y Float


incY yy =
    Y
        (case yy of
            Y y ->
                y + 1
        )


decY yy =
    Y
        (case yy of
            Y y ->
                y - 1
        )
