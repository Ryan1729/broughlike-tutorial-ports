port module Ports exposing (CommandRecord, draw, perform, setCanvasDimensions)

import Array exposing (Array)
import Game exposing (H(..), Model, W(..), X(..), Y(..))
import Json.Encode as JE


type CommandRecord
    = CommandRecord JE.Value


port platform : Array JE.Value -> Cmd msg


perform : Array CommandRecord -> Cmd msg
perform records =
    Array.map
        (\cr ->
            case cr of
                CommandRecord v ->
                    v
        )
        records
        |> platform


draw : Model -> CommandRecord
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
        |> CommandRecord


setCanvasDimensions : ( W, H ) -> CommandRecord
setCanvasDimensions dimensions =
    case dimensions of
        ( W w, H h ) ->
            JE.object
                [ ( "kind", JE.string "setCanvasDimensions" )
                , ( "w"
                  , JE.float w
                  )
                , ( "h"
                  , JE.float h
                  )
                ]
                |> CommandRecord
