module Tiles exposing (Tiles, addMonster, foldXY, get, getAdjacentNeighbors, getAdjacentPassableNeighbors, getNeighbor, mapToArray, possiblyDisconnectedTilesGen, randomPassableTile, set, tryMove, updateMonster)

import Array exposing (Array)
import Game exposing (DeltaX(..), DeltaY(..), Located, SpriteIndex(..), X(..), Y(..), moveX, moveY)
import Monster exposing (HP(..), Kind(..), Monster)
import Random exposing (Generator, Seed)
import Randomness exposing (probability, shuffle)
import Tile exposing (Kind(..), Tile)


tileCount =
    Game.numTiles * Game.numTiles


type Tiles
    = Tiles (Array Tile)


mapToArray : (Tile -> a) -> Tiles -> Array a
mapToArray mapper tiles =
    case tiles of
        Tiles ts ->
            Array.map mapper ts


foldXY : (Located {} -> a -> a) -> a -> a
foldXY folder initial =
    List.foldl folder initial allLocations


allLocations : List (Located {})
allLocations =
    List.range 0 (Game.numTiles - 1)
        |> List.foldr
            (\y yAcc ->
                List.range 0 (Game.numTiles - 1)
                    |> List.foldr
                        (\x xAcc ->
                            { x = X (toFloat x), y = Y (toFloat y) } :: xAcc
                        )
                        yAcc
            )
            []


get : Tiles -> Located a -> Tile
get tiles { x, y } =
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
    get tiles { x = moveX dx x, y = moveY dy y }


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


getAdjacentNeighbors : Tiles -> Located a -> Generator (List Tile)
getAdjacentNeighbors tiles located =
    shuffle
        [ getNeighbor tiles located DX0 DYm1
        , getNeighbor tiles located DX0 DY1
        , getNeighbor tiles located DXm1 DY0
        , getNeighbor tiles located DX1 DY0
        ]


getAdjacentPassableNeighbors : Tiles -> Located a -> Generator (List Tile)
getAdjacentPassableNeighbors tiles located =
    getAdjacentNeighbors tiles located
        |> Random.map (List.filter Tile.isPassable)


randomPassableTile : Tiles -> Generator (Result String Tile)
randomPassableTile tiles =
    Random.map
        (\xy ->
            let
                t : Tile
                t =
                    get tiles xy
            in
            if Tile.isPassable t && not (Tile.hasMonster t) then
                Ok t

            else
                Err "get random passable tile"
        )
        xyGen
        |> Randomness.tryTo


xyGen : Generator (Located {})
xyGen =
    let
        coordIntGen =
            Game.numTiles - 1 |> Random.int 0
    in
    Random.map2
        (\x y -> { x = x, y = y })
        (Random.map (toFloat >> X) coordIntGen)
        (Random.map (toFloat >> Y) coordIntGen)


updateMonster :
    Monster
    ->
        { a
            | player : Located {}
            , tiles : Tiles
            , seed : Seed
        }
    ->
        { a
            | player : Located {}
            , tiles : Tiles
            , seed : Seed
        }
updateMonster monster stateIn =
    case monster.kind of
        Monster.Tank ->
            let
                startedStunned =
                    monster.stunned

                { state, moved } =
                    updateMonsterInner monster stateIn
            in
            if startedStunned then
                state

            else
                setMonster (Monster.stun moved) state
                    |> .state

        _ ->
            updateMonsterInner monster stateIn
                |> .state


type alias WithMoved a =
    { a | moved : Monster }


updateMonsterInner :
    Monster
    ->
        { a
            | player : Located {}
            , tiles : Tiles
            , seed : Seed
        }
    ->
        WithMoved
            { state :
                { a
                    | player : Located {}
                    , tiles : Tiles
                    , seed : Seed
                }
            }
updateMonsterInner monster stateIn =
    if monster.stunned then
        setMonster { monster | stunned = False } stateIn

    else
        case monster.kind of
            Monster.Bird ->
                doStuff stateIn monster

            Monster.Snake ->
                let
                    { state, moved } =
                        doStuff stateIn { monster | attackedThisTurn = False }
                in
                if moved.attackedThisTurn then
                    { state = state, moved = moved }

                else
                    doStuff state moved

            Monster.Tank ->
                doStuff stateIn monster

            _ ->
                doStuff stateIn monster


doStuff :
    { a
        | player : Located {}
        , tiles : Tiles
        , seed : Seed
    }
    -> Monster
    ->
        WithMoved
            { state :
                { a
                    | player : Located {}
                    , tiles : Tiles
                    , seed : Seed
                }
            }
doStuff state monster =
    let
        gen =
            getAdjacentPassableNeighbors state.tiles monster
                |> Random.map
                    (List.filter
                        (\t ->
                            case get state.tiles t |> .monster of
                                Just m ->
                                    Monster.isPlayer m.kind

                                Nothing ->
                                    True
                        )
                    )
                |> Random.map
                    (\neighbors ->
                        case
                            List.sortBy (Game.dist state.player) neighbors
                                |> List.head
                                |> Maybe.andThen
                                    (\newTile ->
                                        Game.deltasFrom { source = monster, target = newTile }
                                            |> Maybe.andThen
                                                (\( dx, dy ) ->
                                                    tryMove state.tiles monster dx dy
                                                )
                                    )
                        of
                            Just { tiles, moved } ->
                                { state = { state | tiles = tiles }, moved = moved }

                            Nothing ->
                                { state = state, moved = monster }
                    )

        ( generated, seed ) =
            Random.step gen state.seed

        generatedState =
            generated.state
    in
    { generated | state = { generatedState | seed = seed } }


setMonster :
    Monster
    ->
        { a
            | player : Located {}
            , tiles : Tiles
            , seed : Seed
        }
    ->
        WithMoved
            { state :
                { a
                    | player : Located {}
                    , tiles : Tiles
                    , seed : Seed
                }
            }
setMonster monster state =
    let
        { tiles, moved } =
            move monster monster state.tiles
    in
    { state = { state | tiles = tiles }, moved = moved }


addMonster :
    Tiles
    -> Located { kind : Monster.Kind }
    -> Tiles
addMonster tiles monsterSpec =
    move (Monster.fromSpec monsterSpec) monsterSpec tiles
        |> .tiles


isNothing : Maybe a -> Bool
isNothing maybe =
    case maybe of
        Just _ ->
            False

        Nothing ->
            True



-- We return the monster here mostly so we can use this function for the player too,
-- even though we keep it separate from the `Tiles`


tryMove :
    Tiles
    -> Monster
    -> DeltaX
    -> DeltaY
    ->
        Maybe
            (WithMoved { tiles : Tiles })
tryMove tiles monster dx dy =
    let
        newTile =
            getNeighbor tiles monster dx dy
    in
    if Tile.isPassable newTile then
        Just
            (case newTile.monster of
                Nothing ->
                    move monster newTile tiles

                Just target ->
                    if Monster.isPlayer monster.kind /= Monster.isPlayer target.kind then
                        let
                            newMonster =
                                { monster | attackedThisTurn = True }

                            newTarget =
                                Monster.stun target
                                    |> Monster.hit (HP 1)
                        in
                        { tiles =
                            move newTarget newTarget tiles
                                |> .tiles
                                |> move newMonster newMonster
                                |> .tiles
                        , moved = newMonster
                        }

                    else
                        { tiles = tiles, moved = monster }
            )

    else
        Nothing


move :
    Monster
    -> Located b
    -> Tiles
    -> WithMoved { tiles : Tiles }
move monsterIn { x, y } tiles =
    let
        oldTile =
            get tiles monsterIn

        newTile =
            get tiles { x = x, y = y }

        monster =
            { monsterIn | x = x, y = y }
    in
    { tiles =
        set { oldTile | monster = Nothing } tiles
            |> set { newTile | monster = Just monster }
    , moved = monster
    }
