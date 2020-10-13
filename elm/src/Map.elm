module Map exposing (Level, Monsters, generateLevel, randomPassableTile)

import Array exposing (Array)
import Game exposing (DeltaX(..), DeltaY(..), LevelNum(..), Located, X(..), Y(..), moveX, moveY)
import Monster exposing (Monster)
import Random exposing (Generator, Seed)
import Tile exposing (Kind(..), Tile)
import Tiles exposing (Tiles)


type alias Level =
    ( Tiles, Monsters )


generateLevel : LevelNum -> Generator (Result String Level)
generateLevel level =
    Random.andThen
        (\tilesResult ->
            case tilesResult of
                Err e ->
                    Err e
                        |> Random.constant

                Ok tiles ->
                    generateMonsters level tiles
        )
        tilesGen
        |> tryTo


type alias Monsters =
    Array Monster


generateMonsters : LevelNum -> Tiles -> Generator (Result String Level)
generateMonsters levelNum tiles =
    let
        numMonsters =
            case levelNum of
                LevelNum level ->
                    level + 1
    in
    addMonsters numMonsters ( tiles, Array.empty )


addMonsters : Int -> Level -> Generator (Result String Level)
addMonsters count ( tilesIn, monstersIn ) =
    if count <= 0 then
        ( tilesIn, monstersIn )
            |> Ok
            |> Random.constant

    else
        nonPlayerMonsterKindGen
            |> Random.andThen
                (\kind ->
                    randomPassableTile tilesIn
                        |> Random.andThen
                            (\tileResult ->
                                case tileResult of
                                    Err e ->
                                        Err e
                                            |> Random.constant

                                    Ok { x, y } ->
                                        Monster.add tilesIn { x = x, y = y, kind = kind }
                                            |> (\( tiles, monster ) -> ( tiles, Array.push monster monstersIn ))
                                            |> addMonsters
                                                (count - 1)
                            )
                )


nonPlayerMonsterKindGen : Generator Monster.Kind
nonPlayerMonsterKindGen =
    shuffleNonEmpty
        ( Monster.Bird
        , [ Monster.Snake
          , Monster.Tank
          , Monster.Eater
          , Monster.Jester
          ]
        )
        |> Random.map (\( head, _ ) -> head)


tilesGen : Generator (Result String Tiles)
tilesGen =
    Random.andThen
        (\( tiles, passableCount ) ->
            randomPassableTile tiles
                |> Random.andThen
                    (\tileResult ->
                        case tileResult of
                            Err e ->
                                Err e
                                    |> Random.constant

                            Ok tile ->
                                getConnectedTiles tiles tile
                                    |> Random.map
                                        (\connectedTiles ->
                                            if passableCount == List.length connectedTiles then
                                                Ok tiles

                                            else
                                                Err "generate connected tiles"
                                        )
                    )
        )
        Tiles.possiblyDisconnectedTilesGen


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


shuffleNonEmpty : ( a, List a ) -> Generator ( a, List a )
shuffleNonEmpty list =
    shuffleNonEmptyHelper list 0


shuffleNonEmptyHelper : ( a, List a ) -> Int -> Generator ( a, List a )
shuffleNonEmptyHelper list i =
    Random.int 0 i
        |> Random.andThen
            (\randomIndex ->
                let
                    newList =
                        swapAtNonEmpty i randomIndex list

                    newI =
                        i + 1
                in
                if newI < lengthNonEmpty newList then
                    shuffleNonEmptyHelper newList newI

                else
                    Random.constant newList
            )


lengthNonEmpty : ( a, List a ) -> Int
lengthNonEmpty ( _, rest ) =
    1 + List.length rest


swapAtNonEmpty : Int -> Int -> ( a, List a ) -> ( a, List a )
swapAtNonEmpty i j list =
    if i == j || i < 0 then
        list

    else if i > j then
        swapAtNonEmpty j i list

    else
        let
            ( head, rest ) =
                list
        in
        if i == 0 then
            let
                beforeJ =
                    List.take (j + 1) rest

                jAndAfter =
                    List.drop (j + 1) rest
            in
            case jAndAfter of
                valueAtJ :: restOfRest ->
                    ( valueAtJ, List.concat [ beforeJ, head :: restOfRest ] )

                _ ->
                    list

        else
            ( head
            , swapAt (i + 1) (j + 1) rest
            )


xyGen : Generator ( X, Y )
xyGen =
    let
        coordIntGen =
            Game.numTiles - 1 |> Random.int 0
    in
    Random.pair
        (Random.map (toFloat >> X) coordIntGen)
        (Random.map (toFloat >> Y) coordIntGen)


getAdjacentNeighbors : Tiles -> Tile -> Generator (List Tile)
getAdjacentNeighbors tiles tile =
    shuffle
        [ Tiles.getNeighbor tiles tile DX0 DYm1
        , Tiles.getNeighbor tiles tile DX0 DY1
        , Tiles.getNeighbor tiles tile DXm1 DY0
        , Tiles.getNeighbor tiles tile DX1 DY0
        ]


getAdjacentPassableNeighbors : Tiles -> Tile -> Generator (List Tile)
getAdjacentPassableNeighbors tiles tile =
    getAdjacentNeighbors tiles tile
        |> Random.map (List.filter Tile.isPassable)


randomPassableTile : Tiles -> Generator (Result String Tile)
randomPassableTile tiles =
    Random.map
        (\( x, y ) ->
            let
                t : Tile
                t =
                    Tiles.get tiles x y
            in
            if Tile.isPassable t && not (Tile.hasMonster t) then
                Ok t

            else
                Err "get random passable tile"
        )
        xyGen
        |> tryTo


tryTo : Generator (Result String a) -> Generator (Result String a)
tryTo generator =
    tryToHelper generator 1000


tryToHelper : Generator (Result String a) -> Int -> Generator (Result String a)
tryToHelper generator timeout =
    Random.andThen
        (\result ->
            case result of
                Ok a ->
                    Ok a
                        |> Random.constant

                Err description ->
                    if timeout <= 0 then
                        "Timeout while trying to "
                            ++ description
                            |> Err
                            |> Random.constant

                    else
                        tryToHelper generator (timeout - 1)
        )
        generator
