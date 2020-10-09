module Map exposing (Tiles, get, levelGen, map)

import Array exposing (Array)
import Game exposing (X(..), Y(..))
import Random exposing (Generator)
import Tile exposing (Kind(..), Tile)


tileCount =
    Game.numTiles * Game.numTiles


levelGen =
    tileGen


probability : Generator Float
probability =
    Random.float 0 1


tileGen : Generator Tiles
tileGen =
    let
        isWallArrayGen : Generator (Array Bool)
        isWallArrayGen =
            Random.map (\x -> x < 0.3) probability
                |> Random.list tileCount
                |> Random.map Array.fromList
                |> Random.map (Array.indexedMap (\i bool -> bool || not (toXY i |> inBounds)))

        toTile index isWall =
            let
                ( x, y ) =
                    toXY index
            in
            if isWall then
                Tile.wall x y

            else
                Tile.floor x y

        toTiles : Array Bool -> Tiles
        toTiles bools =
            Array.indexedMap toTile bools
                |> Tiles
    in
    Random.map toTiles isWallArrayGen


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
                    if inBounds ( x, y ) then
                        Array.get (toIndex x y) ts

                    else
                        Nothing
            in
            case m of
                Just t ->
                    t

                Nothing ->
                    Tile.wall x y


inBounds : ( X, Y ) -> Bool
inBounds xy =
    case xy of
        ( X x, Y y ) ->
            x > 0 && y > 0 && x < Game.numTiles - 1 && y < Game.numTiles - 1


toXY : Int -> ( X, Y )
toXY index =
    ( X
        (modBy Game.numTiles index
            |> toFloat
        )
    , Y
        (index
            // Game.numTiles
            |> toFloat
        )
    )


toIndex : X -> Y -> Int
toIndex xx yy =
    case ( xx, yy ) of
        ( X x, Y y ) ->
            y
                * Game.numTiles
                + x
                |> round
