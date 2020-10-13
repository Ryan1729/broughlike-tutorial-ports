module Tiles exposing (Tiles, get, getNeighbor, map, possiblyDisconnectedTilesGen, set)

import Array exposing (Array)
import Game exposing (DeltaX(..), DeltaY(..), Located, X(..), Y(..), moveX, moveY)
import Random exposing (Generator, Seed)
import Tile exposing (Kind(..), Tile)


tileCount =
    Game.numTiles * Game.numTiles


type Tiles
    = Tiles (Array Tile)


map : (Tile -> a) -> Tiles -> Array a
map mapper tiles =
    case tiles of
        Tiles ts ->
            Array.map mapper ts


get : Tiles -> X -> Y -> Tile
get tiles x y =
    case tiles of
        Tiles ts ->
            let
                m : Maybe Tile
                m =
                    toIndex { x = x, y = y }
                        |> Maybe.andThen (\i -> Array.get i ts)
            in
            case m of
                Just t ->
                    t

                Nothing ->
                    Tile.wall x y


set : Tile -> Tiles -> Tiles
set tile tiles =
    case tiles of
        Tiles ts ->
            Tiles
                (case toIndex tile of
                    Just i ->
                        Array.set i tile ts

                    Nothing ->
                        ts
                )


getNeighbor : Tiles -> Located a -> DeltaX -> DeltaY -> Tile
getNeighbor tiles { x, y } dx dy =
    get tiles (moveX dx x) (moveY dy y)


inBounds : Located a -> Bool
inBounds xy =
    case ( xy.x, xy.y ) of
        ( X x, Y y ) ->
            x > 0 && y > 0 && x < Game.numTiles - 1 && y < Game.numTiles - 1


toXY : Int -> Located {}
toXY index =
    { x =
        X
            (modBy Game.numTiles index
                |> toFloat
            )
    , y =
        Y
            (index
                // Game.numTiles
                |> toFloat
            )
    }


toIndex : Located a -> Maybe Int
toIndex xy =
    if inBounds xy then
        Just
            (case ( xy.x, xy.y ) of
                ( X x, Y y ) ->
                    y
                        * Game.numTiles
                        + x
                        |> round
            )

    else
        Nothing


possiblyDisconnectedTilesGen : Generator ( Tiles, Int )
possiblyDisconnectedTilesGen =
    let
        isWallArrayGen : Generator (Array Bool)
        isWallArrayGen =
            Random.map
                (\x -> x < 0.3)
                probability
                |> Random.list tileCount
                |> Random.map Array.fromList
                |> Random.map (Array.indexedMap (\i bool -> bool || not (toXY i |> inBounds)))

        toTile index isWall =
            let
                { x, y } =
                    toXY index
            in
            if isWall then
                Tile.wall x y

            else
                Tile.floor x y

        toTiles : Array Bool -> Tiles
        toTiles =
            Array.indexedMap toTile
                >> Tiles

        toPassableCount : Array Bool -> Int
        toPassableCount =
            Array.foldl
                (\isWall count ->
                    if isWall then
                        count

                    else
                        count + 1
                )
                0
    in
    Random.map (\bools -> ( toTiles bools, toPassableCount bools )) isWallArrayGen


probability : Generator Float
probability =
    Random.float 0 1
