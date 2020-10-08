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


type alias Model =
    { x : X
    , y : Y
    , seed : Seed
    }


modelFromSeed : Seed -> Model
modelFromSeed seed =
    { x = X 0
    , y = Y 0
    , seed = seed
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


type W
    = W Float


type H
    = H Float
