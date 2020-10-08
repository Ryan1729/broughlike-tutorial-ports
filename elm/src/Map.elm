module Map exposing (Tiles, levelGen)

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
        boolArrayGen : Generator (Array Bool)
        boolArrayGen =
            Random.map (\x -> x < 0.3) probability
                |> Random.list tileCount
                |> Random.map Array.fromList

        toTile index isWall =
            let
                x =
                    X
                        (modBy Game.numTiles index
                            |> toFloat
                        )

                y =
                    Y
                        (index // Game.numTiles
                            |> toFloat
                        )
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
    Random.map toTiles boolArrayGen


type Tiles
    = Tiles (Array Tile)
