port module Ports exposing (Colour(..), CommandRecord, TextSpec, drawOverlay, drawSprite, drawText, perform, setCanvasDimensions)

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


drawSprite : X -> Y -> SpriteIndex -> CommandRecord
drawSprite xx yy spriteIndex =
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


type Colour
    = White
    | Violet
    | Aqua


type alias TextSpec =
    { text : String
    , size : Int
    , centered : Bool
    , y : Y
    , colour : Colour
    }


drawText : TextSpec -> CommandRecord
drawText { text, size, centered, y, colour } =
    case y of
        Y textY ->
            JE.object
                [ ( "kind", JE.string "drawText" )
                , ( "text", JE.string text )
                , ( "size", JE.int size )
                , ( "centered", JE.bool centered )
                , ( "textY", JE.float textY )
                , ( "colour"
                  , JE.string
                        (case colour of
                            White ->
                                "white"

                            Violet ->
                                "violet"

                            Aqua ->
                                "aqua"
                        )
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
