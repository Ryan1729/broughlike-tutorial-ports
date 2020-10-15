module Game exposing (..)

import Random exposing (Seed)


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


type DeltaX
    = DX0
    | DX1
    | DXm1


type DeltaY
    = DY0
    | DY1
    | DYm1



-- This returns the deltas from the first param (`source`) to the second param (`target`)
-- if both deltas exist.
-- That is, if `source` is at 2, 1 and `target` is at 1, 2 then `Just (DXm1, DY1)` will be returned.


deltasFrom : Located a -> Located b -> Maybe ( DeltaX, DeltaY )
deltasFrom source target =
    case ( delatXFrom source.x target.x, delatYFrom source.y target.y ) of
        ( Just dx, Just dy ) ->
            Just ( dx, dy )

        _ ->
            Nothing


delatXFrom : X -> X -> Maybe DeltaX
delatXFrom sourceX targetX =
    case ( sourceX, targetX ) of
        ( X sX, X tX ) ->
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


delatYFrom : Y -> Y -> Maybe DeltaY
delatYFrom sourceY targetY =
    case ( sourceY, targetY ) of
        ( Y sY, Y tY ) ->
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


moveX dx xx =
    case xx of
        X x ->
            case dx of
                DX0 ->
                    X x

                DX1 ->
                    x + 1 |> X

                DXm1 ->
                    x - 1 |> X


type Y
    = Y Float


moveY dy yy =
    case yy of
        Y y ->
            case dy of
                DY0 ->
                    Y y

                DY1 ->
                    y + 1 |> Y

                DYm1 ->
                    y - 1 |> Y


type alias Located a =
    { a | x : X, y : Y }


dist : Located a -> Located b -> Float
dist tile other =
    case ( tile.x, tile.y ) of
        ( X tX, Y tY ) ->
            case ( other.x, other.y ) of
                ( X oX, Y oY ) ->
                    abs (tX - oX)
                        + abs (tY - oY)


type W
    = W Float


type H
    = H Float


type LevelNum
    = LevelNum Int
