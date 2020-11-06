module Game exposing (..)

import Random exposing (Generator, Seed)


type SpriteIndex
    = SpriteIndex Int


tileSize =
    64


numTiles =
    9


uiWidth =
    4


pixelWidth =
    W (tileSize * (numTiles + uiWidth))


pixelHeight =
    H (tileSize * numTiles)


pixelUIWidth =
    W (tileSize * uiWidth)



-- Position is the one-dimensional tile position of something on the map
-- The type should only ever hold values inside [0, Numtiles - 1].


type alias Position =
    Int


type XPos
    = XPos Position


moveX dx xx =
    case xx of
        XPos x ->
            case dx of
                DX0 ->
                    XPos x

                DX1 ->
                    x + 1 |> XPos

                DXm1 ->
                    x - 1 |> XPos


type YPos
    = YPos Position


moveY dy yy =
    case yy of
        YPos y ->
            case dy of
                DY0 ->
                    YPos y

                DY1 ->
                    y + 1 |> YPos

                DYm1 ->
                    y - 1 |> YPos


type alias Positioned a =
    { a | xPos : XPos, yPos : YPos }


dist : Positioned a -> Positioned b -> Int
dist tile other =
    case ( tile.xPos, tile.yPos ) of
        ( XPos tX, YPos tY ) ->
            case ( other.xPos, other.yPos ) of
                ( XPos oX, YPos oY ) ->
                    abs (tX - oX)
                        + abs (tY - oY)


type DeltaX
    = DX0
    | DX1
    | DXm1


type DeltaY
    = DY0
    | DY1
    | DYm1



-- This returns the deltas from the `source` to the `target`, if both deltas exist.
-- That is, if `source` is at 2, 1 and `target` is at 1, 2 then `Just (DXm1, DY1)` will be returned.
-- As another example, if `source` is at 1, 2 and `target` is at 1, 1 then `Just (DX0, DYm1)` will be returned.


deltasFrom : { source : Positioned a, target : Positioned b } -> Maybe ( DeltaX, DeltaY )
deltasFrom { source, target } =
    case ( delatXFrom source.xPos target.xPos, delatYFrom source.yPos target.yPos ) of
        ( Just dx, Just dy ) ->
            Just ( dx, dy )

        _ ->
            Nothing


delatXFrom : XPos -> XPos -> Maybe DeltaX
delatXFrom sourceX targetX =
    case ( sourceX, targetX ) of
        ( XPos sX, XPos tX ) ->
            let
                delta =
                    tX - sX
            in
            if delta == -1 then
                Just DXm1

            else if delta == 0 then
                Just DX0

            else if delta == 1 then
                Just DX1

            else
                Nothing


delatYFrom : YPos -> YPos -> Maybe DeltaY
delatYFrom sourceY targetY =
    case ( sourceY, targetY ) of
        ( YPos sY, YPos tY ) ->
            let
                delta =
                    tY - sY
            in
            if delta == -1 then
                Just DYm1

            else if delta == 0 then
                Just DY0

            else if delta == 1 then
                Just DY1

            else
                Nothing


type X
    = X Float


type Y
    = Y Float


type alias Located a =
    { a | x : X, y : Y }


type W
    = W Float


type H
    = H Float


type LevelNum
    = LevelNum Int


incLevel : LevelNum -> LevelNum
incLevel levelNum =
    case levelNum of
        LevelNum l ->
            LevelNum (l + 1)


levelNumToString : LevelNum -> String
levelNumToString levelNum =
    case levelNum of
        LevelNum l ->
            String.fromInt l


type alias ScoreRow =
    { score : Score
    , run : Int
    , totalScore : Score
    , active : Bool
    }


type Score
    = Score Int


type Outcome
    = Loss
    | Win


type alias Shake =
    { amount : Int
    , x : X
    , y : Y
    }


screenShake : Shake -> Generator Shake
screenShake { amount, x, y } =
    case ( x, y ) of
        ( X bareX, Y bareY ) ->
            Random.float 0 (2 * pi)
                |> Random.map
                    (\shakeAngle ->
                        let
                            newAmount =
                                if amount > 0 then
                                    amount - 1

                                else
                                    0
                        in
                        { amount = newAmount
                        , x = round (cos shakeAngle * toFloat newAmount) |> toFloat |> X
                        , y = round (sin shakeAngle * toFloat newAmount) |> toFloat |> Y
                        }
                    )
