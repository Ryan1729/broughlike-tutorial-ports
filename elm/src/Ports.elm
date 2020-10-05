port module Ports exposing (draw)

import Array exposing (Array)
import Json.Encode as JE
import Types exposing (..)


type alias CommandRecord =
    JE.Value


port platform : Array CommandRecord -> Cmd msg


draw : Model -> Cmd msg
draw model =
    JE.object
        [ ( "kind", JE.string "draw" )
        , ( "x"
          , case model.x of
                X x ->
                    JE.float x
          )
        , ( "y"
          , case model.y of
                Y y ->
                    JE.float y
          )
        ]
        |> Array.repeat 1
        |> platform
