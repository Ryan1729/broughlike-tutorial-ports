module Map exposing (Level, generateLevel, spawnMonster)

import Array exposing (Array)
import Game exposing (DeltaX(..), DeltaY(..), LevelNum(..), Located, Positioned, X(..), Y(..), moveX, moveY)
import Monster exposing (Monster)
import Random exposing (Generator, Seed)
import Randomness
import Tile exposing (Kind(..), Tile)
import Tiles exposing (Tiles)


type alias Level =
    Tiles


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
                        |> Random.map (Result.mapError Tiles.noPassableTileToString)
        )
        tilesGen
        |> Randomness.tryTo


generateMonsters : LevelNum -> Tiles -> Generator (Result Tiles.NoPassableTile Level)
generateMonsters levelNum tiles =
    let
        numMonsters =
            case levelNum of
                LevelNum level ->
                    level + 1
    in
    addMonsters numMonsters tiles


addMonsters : Int -> Level -> Generator (Result Tiles.NoPassableTile Level)
addMonsters count tilesIn =
    if count <= 0 then
        Ok tilesIn
            |> Random.constant

    else
        Random.andThen
            (\kind ->
                Tiles.randomPassableTile tilesIn
                    |> Random.andThen
                        (\tileResult ->
                            case tileResult of
                                Err e ->
                                    Err e
                                        |> Random.constant

                                Ok { xPos, yPos } ->
                                    Tiles.addMonster tilesIn { xPos = xPos, yPos = yPos, kind = kind }
                                        |> addMonsters
                                            (count - 1)
                        )
            )
            nonPlayerMonsterKindGen


spawnMonster : Level -> Generator (Result Tiles.NoPassableTile Level)
spawnMonster tiles =
    addMonsters 1 tiles


nonPlayerMonsterKindGen : Generator Monster.Kind
nonPlayerMonsterKindGen =
    Randomness.shuffleNonEmpty
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
            Tiles.randomPassableTile tiles
                |> Random.andThen
                    (\tileResult ->
                        case tileResult of
                            Err e ->
                                Tiles.noPassableTileToString e
                                    |> Err
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
            Tiles.getAdjacentPassableNeighbors tiles popped
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
