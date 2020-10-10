module Map exposing (Tiles, get, levelGen, map, randomPassableTile)

import Array exposing (Array)
import Game exposing (X(..), Y(..))
import Random exposing (Generator, Seed)
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
            Random.map
                (\x -> x < 0.3)
                probability
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


xyGen : Generator ( X, Y )
xyGen =
    let
        coordIntGen =
            Game.numTiles - 1 |> Random.int 0
    in
    Random.pair
        (Random.map (toFloat >> X) coordIntGen)
        (Random.map (toFloat >> Y) coordIntGen)


randomPassableTile : Tiles -> Generator (Result String Tile)
randomPassableTile tiles =
    Random.map
        (\( x, y ) ->
            let
                t : Tile
                t =
                    get tiles x y
            in
            if Tile.isPassable t && not (Tile.hasMonster t) then
                Just t

            else
                Nothing
        )
        xyGen
        |> tryTo "get random passable tile"


tryTo : String -> Generator (Maybe a) -> Generator (Result String a)
tryTo description generator =
    tryToHelper description generator 1000


tryToHelper : String -> Generator (Maybe a) -> Int -> Generator (Result String a)
tryToHelper description generator timeout =
    Random.andThen
        (\maybe ->
            case maybe of
                Just a ->
                    Ok a
                        |> Random.constant

                Nothing ->
                    if timeout <= 0 then
                        "Timeout while trying to "
                            ++ description
                            |> Err
                            |> Random.constant

                    else
                        tryToHelper description generator (timeout - 1)
        )
        generator
