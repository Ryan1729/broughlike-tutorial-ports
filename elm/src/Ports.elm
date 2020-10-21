port module Ports exposing (CommandRecord, drawOverlay, drawSprite, perform, setCanvasDimensions)

import Array exposing (Array)
import Game exposing (H(..), SpriteIndex(..), W(..), X(..), Y(..))
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


drawSprite : SpriteIndex -> X -> Y -> CommandRecord
drawSprite spriteIndex xx yy =
    JE.object
        [ ( "kind", JE.string "drawSprite" )
        , ( "sprite"
          , case spriteIndex of
                SpriteIndex sprite ->
                    JE.int sprite
          )
        , ( "x"
          , case xx of
                X x ->
                    JE.float x
          )
        , ( "y"
          , case yy of
                Y y ->
                    JE.float y
          )
        , ( "tileSize"
          , JE.float Game.tileSize
          )
        ]
        |> CommandRecord


drawOverlay : CommandRecord
drawOverlay =
    JE.object
        [ ( "kind", JE.string "drawOverlay" ) ]
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
