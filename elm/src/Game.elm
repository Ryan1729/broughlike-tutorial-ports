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


type W
    = W Float


type H
    = H Float
