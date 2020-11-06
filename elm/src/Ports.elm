port module Ports exposing (Colour(..), CommandRecord, TextSpec, addScore, decodeScoreRows, drawOverlay, drawSprite, drawText, perform, scoreList, setCanvasDimensions)

import Array exposing (Array)
import Game exposing (H(..), Located, Outcome(..), Score(..), ScoreRow, Shake, SpriteIndex(..), W(..), X(..), Y(..))
import Json.Decode as JD
import Json.Encode as JE


type CommandRecord
    = CommandRecord JE.Value


port platform : Array JE.Value -> Cmd msg


port scores : (JD.Value -> msg) -> Sub msg


decodeScoreRows : JD.Decoder (List ScoreRow)
decodeScoreRows =
    JD.list decodeScoreRow


decodeScoreRow : JD.Decoder ScoreRow
decodeScoreRow =
    JD.map4 ScoreRow
        (JD.field "score" decodeScore)
        (JD.field "run" JD.int)
        (JD.field "totalScore" decodeScore)
        (JD.field "active" JD.bool)


decodeScore : JD.Decoder Score
decodeScore =
    JD.map Score JD.int


scoreList : (Result JD.Error (List Game.ScoreRow) -> msg) -> Sub msg
scoreList toMsg =
    scores
        (JD.decodeValue decodeScoreRows
            >> toMsg
        )


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


drawSprite : Shake -> Located a -> SpriteIndex -> CommandRecord
drawSprite shake { x, y } spriteIndex =
    JE.object
        [ ( "kind", JE.string "drawSprite" )
        , ( "sprite"
          , case spriteIndex of
                SpriteIndex sprite ->
                    JE.int sprite
          )
        , ( "x"
          , case ( x, shake.x ) of
                ( X bareX, X sX ) ->
                    JE.float (bareX * Game.tileSize + sX)
          )
        , ( "y"
          , case ( y, shake.y ) of
                ( Y bareY, Y sY ) ->
                    JE.float (bareY * Game.tileSize + sY)
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


addScore : Score -> Outcome -> CommandRecord
addScore score outcome =
    let
        scoreRow =
            { score = score
            , run = 1
            , totalScore = score
            , active =
                case outcome of
                    Loss ->
                        False

                    Win ->
                        True
            }
    in
    JE.object
        [ ( "kind", JE.string "addScore" )
        , ( "scoreObject"
          , JE.object
                [ ( "score"
                  , case scoreRow.score of
                        Score s ->
                            JE.int s
                  )
                , ( "run", JE.int scoreRow.run )
                , ( "totalScore"
                  , case scoreRow.totalScore of
                        Score ts ->
                            JE.int ts
                  )
                , ( "active", JE.bool scoreRow.active )
                ]
          )
        ]
        |> CommandRecord


setCanvasDimensions : ( W, H, W ) -> CommandRecord
setCanvasDimensions dimensions =
    case dimensions of
        ( W w, H h, W uiWidth ) ->
            JE.object
                [ ( "kind", JE.string "setCanvasDimensions" )
                , ( "w"
                  , JE.float w
                  )
                , ( "h"
                  , JE.float h
                  )
                , ( "uiW"
                  , JE.float uiWidth
                  )
                ]
                |> CommandRecord
