module Map exposing (Tiles, get, getNeighbor, levelGen, map, randomPassableTile, set)

import Array exposing (Array)
import Game exposing (DeltaX(..), DeltaY(..), Located, X(..), Y(..), moveX, moveY)
import Random exposing (Generator, Seed)
import Tile exposing (Kind(..), Tile)


tileCount =
    Game.numTiles * Game.numTiles


levelGen : Generator (Result String Tiles)
levelGen =
    Random.andThen
        (\( tiles, passableCount ) ->
            randomPassableTile tiles
                |> Random.andThen
                    (\tileResult ->
                        case tileResult of
                            Err e ->
                                Random.constant Nothing

                            Ok tile ->
                                getConnectedTiles tiles tile
                                    |> Random.map
                                        (\connectedTiles ->
                                            if passableCount == List.length connectedTiles then
                                                Just tiles

                                            else
                                                Nothing
                                        )
                    )
        )
        tilesGen
        |> tryTo "generate map"


probability : Generator Float
probability =
    Random.float 0 1


tilesGen : Generator ( Tiles, Int )
tilesGen =
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


set : Tiles -> Tile -> Tiles
set tiles tile =
    case tiles of
        Tiles ts ->
            Tiles
                (case toIndex tile of
                    Just i ->
                        Array.set i tile ts

                    Nothing ->
                        ts
                )


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


getConnectedTiles : Tiles -> Tile -> Generator (List Tile)
getConnectedTiles tiles tile =
    getConnectedTilesHelper tiles [ tile ] [ tile ]


getConnectedTilesHelper : Tiles -> List Tile -> List Tile -> Generator (List Tile)
getConnectedTilesHelper tiles connectedTiles frontier =
    case pop frontier of
        Nothing ->
            Random.constant connectedTiles

        Just ( newFrontier, popped ) ->
            getAdjacentPassableNeighbors tiles popped
                |> Random.andThen
                    (\passableNeighbors ->
                        let
                            uncheckedNeighbors =
                                List.filter (\t -> List.member t connectedTiles |> not) passableNeighbors
                        in
                        getConnectedTilesHelper
                            tiles
                            (connectedTiles ++ uncheckedNeighbors)
                            (newFrontier ++ uncheckedNeighbors)
                    )


pop : List a -> Maybe ( List a, a )
pop list =
    let
        newLength =
            List.length list - 1
    in
    List.drop newLength list
        |> List.head
        |> Maybe.map
            (\popped ->
                ( List.take newLength list, popped )
            )


shuffle : List a -> Generator (List a)
shuffle list =
    shuffleHelper list 0


shuffleHelper : List a -> Int -> Generator (List a)
shuffleHelper list i =
    Random.int 0 i
        |> Random.andThen
            (\randomIndex ->
                let
                    newList =
                        swapAt i randomIndex list

                    newI =
                        i + 1
                in
                if newI < List.length newList then
                    shuffleHelper newList newI

                else
                    Random.constant newList
            )


swapAt : Int -> Int -> List a -> List a
swapAt i j list =
    if i == j || i < 0 then
        list

    else if i > j then
        swapAt j i list

    else
        let
            beforeI =
                List.take i list

            iAndAfter =
                List.drop i list

            jInIAndAfter =
                j - i

            iToBeforeJ =
                List.take jInIAndAfter iAndAfter

            jAndAfter =
                List.drop jInIAndAfter iAndAfter
        in
        case ( iToBeforeJ, jAndAfter ) of
            ( valueAtI :: afterIToJ, valueAtJ :: rest ) ->
                List.concat [ beforeI, valueAtJ :: afterIToJ, valueAtI :: rest ]

            _ ->
                list


getNeighbor : Tiles -> Located a -> DeltaX -> DeltaY -> Tile
getNeighbor tiles { x, y } dx dy =
    get tiles (moveX dx x) (moveY dy y)


getAdjacentNeighbors : Tiles -> Tile -> Generator (List Tile)
getAdjacentNeighbors tiles tile =
    shuffle
        [ getNeighbor tiles tile DX0 DYm1
        , getNeighbor tiles tile DX0 DY1
        , getNeighbor tiles tile DXm1 DY0
        , getNeighbor tiles tile DX1 DY0
        ]


getAdjacentPassableNeighbors : Tiles -> Tile -> Generator (List Tile)
getAdjacentPassableNeighbors tiles tile =
    getAdjacentNeighbors tiles tile
        |> Random.map (List.filter Tile.isPassable)


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
