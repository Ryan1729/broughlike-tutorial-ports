module Tiles exposing (NoPassableTile(..), Tiles, addMonster, foldMonsters, foldXY, get, getAdjacentNeighbors, getAdjacentPassableNeighbors, getNeighbor, noPassableTileToString, possiblyDisconnectedTilesGen, randomPassableTile, replace, set, toArray, transform, tryMove, updateMonster)

import Array exposing (Array)
import Game exposing (DeltaX(..), DeltaY(..), Located, Positioned, SpriteIndex(..), X(..), XPos(..), Y(..), YPos(..), moveX, moveY)
import Monster exposing (HP(..), Kind(..), Monster)
import Random exposing (Generator, Seed)
import Randomness exposing (probability, shuffle)
import Tile exposing (Kind(..), Tile)


tileCount =
    Game.numTiles * Game.numTiles


type Tiles
    = Tiles (Array Tile)


toArray : Tiles -> Array Tile
toArray tiles =
    case tiles of
        Tiles ts ->
            ts


foldXY : (Positioned {} -> a -> a) -> a -> a
foldXY folder initial =
    List.foldl folder initial allLocations


allLocations : List (Positioned {})
allLocations =
    List.range 0 (Game.numTiles - 1)
        |> List.foldr
            (\y yAcc ->
                List.range 0 (Game.numTiles - 1)
                    |> List.foldr
                        (\x xAcc ->
                            { xPos = XPos x, yPos = YPos y } :: xAcc
                        )
                        yAcc
            )
            []


get : Tiles -> Positioned a -> Tile
get tiles xy =
    case tiles of
        Tiles ts ->
            let
                m : Maybe Tile
                m =
                    toIndex xy
                        |> Maybe.andThen (\i -> Array.get i ts)
            in
            case m of
                Just t ->
                    t

                Nothing ->
                    Tile.wall xy


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



-- `replace` is distinct from `set` in that it makes it more convenient to
-- create a fresh tile than a transformation of an existing tile


replace : (Positioned {} -> Tile) -> Tile -> Tiles -> Tiles
replace constructor { xPos, yPos } =
    let
        positioned : Positioned {}
        positioned =
            { xPos = xPos, yPos = yPos }
    in
    constructor positioned |> set


transform : (Tile -> Tile) -> Positioned a -> Tiles -> Tiles
transform transformer positioned tiles =
    set
        (get tiles positioned
            |> transformer
        )
        tiles


foldMonsters : (Monster -> a -> a) -> a -> Tiles -> a
foldMonsters folder acc tiles =
    case tiles of
        Tiles ts ->
            ts
                |> Array.map .monster
                |> filterOutNothings
                |> Array.foldl folder acc


filterOutNothings : Array (Maybe a) -> Array a
filterOutNothings =
    Array.foldl
        (\maybe acc ->
            case maybe of
                Just x ->
                    Array.push x acc

                Nothing ->
                    acc
        )
        Array.empty


getNeighbor : Tiles -> Positioned a -> DeltaX -> DeltaY -> Tile
getNeighbor tiles { xPos, yPos } dx dy =
    get tiles { xPos = moveX dx xPos, yPos = moveY dy yPos }


inBounds : Positioned a -> Bool
inBounds xy =
    case ( xy.xPos, xy.yPos ) of
        ( XPos x, YPos y ) ->
            x > 0 && y > 0 && x < Game.numTiles - 1 && y < Game.numTiles - 1


toXYPos : Int -> Positioned {}
toXYPos index =
    { xPos =
        XPos
            (modBy Game.numTiles index)
    , yPos =
        YPos
            (index
                // Game.numTiles
            )
    }


toIndex : Positioned a -> Maybe Int
toIndex xy =
    if inBounds xy then
        Just
            (case ( xy.xPos, xy.yPos ) of
                ( XPos x, YPos y ) ->
                    y
                        * Game.numTiles
                        + x
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
                |> Random.map (Array.indexedMap (\i bool -> bool || not (toXYPos i |> inBounds)))

        toTile index isWall =
            let
                xy =
                    toXYPos index
            in
            if isWall then
                Tile.wall xy

            else
                Tile.floor xy

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


getAdjacentNeighbors : Tiles -> Positioned a -> Generator (List Tile)
getAdjacentNeighbors tiles positioned =
    let
        gn =
            getNeighbor tiles positioned
    in
    shuffle
        [ gn DX0 DYm1
        , gn DX0 DY1
        , gn DXm1 DY0
        , gn DX1 DY0
        ]


getAdjacentPassableNeighbors : Tiles -> Positioned a -> Generator (List Tile)
getAdjacentPassableNeighbors tiles located =
    getAdjacentNeighbors tiles located
        |> Random.map (List.filter Tile.isPassable)


type NoPassableTile
    = NoPassableTile


noPassableTileToString : NoPassableTile -> String
noPassableTileToString _ =
    "get random passable tile"


randomPassableTile : Tiles -> Generator (Result NoPassableTile Tile)
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
                Err NoPassableTile
        )
        xyGen
        |> Randomness.tryToCustom


xyGen : Generator (Positioned {})
xyGen =
    let
        coordIntGen =
            Game.numTiles - 1 |> Random.int 0
    in
    Random.map2
        (\xPos yPos -> { xPos = xPos, yPos = yPos })
        (Random.map XPos coordIntGen)
        (Random.map YPos coordIntGen)


updateMonster :
    Monster
    ->
        { a
            | player : Positioned {}
            , tiles : Tiles
            , seed : Seed
        }
    ->
        { a
            | player : Positioned {}
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
            | player : Positioned {}
            , tiles : Tiles
            , seed : Seed
        }
    ->
        WithMoved
            { state :
                { a
                    | player : Positioned {}
                    , tiles : Tiles
                    , seed : Seed
                }
            }
updateMonsterInner monsterIn stateIn =
    let
        monster =
            { monsterIn | teleportCounter = monsterIn.teleportCounter - 1 }
    in
    if monster.stunned || monster.teleportCounter > 0 then
        setMonster { monster | stunned = False } stateIn

    else
        let
            gen =
                case monster.kind of
                    Monster.Player _ ->
                        { state = stateIn, moved = monster }
                            |> Random.constant

                    Monster.Bird ->
                        doStuff stateIn monster

                    Monster.Snake ->
                        doStuff stateIn { monster | attackedThisTurn = False }
                            |> Random.andThen
                                (\{ state, moved } ->
                                    if moved.attackedThisTurn then
                                        { state = state, moved = moved }
                                            |> Random.constant

                                    else
                                        doStuff state moved
                                )

                    Monster.Tank ->
                        doStuff stateIn monster

                    Monster.Eater ->
                        getAdjacentNeighbors stateIn.tiles monster
                            |> Random.map (List.filter (\t -> not (Tile.isPassable t) && inBounds t))
                            |> Random.andThen
                                (\neighbors ->
                                    case neighbors of
                                        [] ->
                                            doStuff stateIn monster

                                        head :: _ ->
                                            { stateIn | tiles = replace Tile.floor head stateIn.tiles }
                                                |> setMonster (Monster.heal (HP 0.5) monster)
                                                |> Random.constant
                                )

                    Monster.Jester ->
                        getAdjacentPassableNeighbors stateIn.tiles monster
                            |> Random.map
                                (\neighbors ->
                                    case neighbors of
                                        [] ->
                                            { state = stateIn, moved = monster }

                                        head :: _ ->
                                            case
                                                Game.deltasFrom { source = monster, target = head }
                                                    |> Maybe.andThen (\( dx, dy ) -> tryMove monster dx dy stateIn.tiles)
                                            of
                                                Nothing ->
                                                    { state = stateIn, moved = monster }

                                                Just { tiles, moved } ->
                                                    { state =
                                                        { stateIn | tiles = tiles }
                                                    , moved = moved
                                                    }
                                )
        in
        Random.step gen stateIn.seed
            |> (\( { state } as output, seed ) -> { output | state = { state | seed = seed } })


doStuff :
    { a
        | player : Positioned {}
        , tiles : Tiles
        , seed : Seed
    }
    -> Monster
    ->
        Generator
            (WithMoved
                { state :
                    { a
                        | player : Positioned {}
                        , tiles : Tiles
                        , seed : Seed
                    }
                }
            )
doStuff state monster =
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
                                            tryMove monster dx dy state.tiles
                                        )
                            )
                of
                    Just { tiles, moved } ->
                        { state = { state | tiles = tiles }, moved = moved }

                    Nothing ->
                        { state = state, moved = monster }
            )


setMonster :
    Monster
    ->
        { a
            | player : Positioned {}
            , tiles : Tiles
            , seed : Seed
        }
    ->
        WithMoved
            { state :
                { a
                    | player : Positioned {}
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
    -> Monster.Spec
    -> Tiles
addMonster tiles monsterSpec =
    let
        monster =
            Monster.fromSpec monsterSpec
    in
    move monster monster tiles
        |> .tiles


isNothing : Maybe a -> Bool
isNothing maybe =
    case maybe of
        Just _ ->
            False

        Nothing ->
            True


tryMove :
    Monster
    -> DeltaX
    -> DeltaY
    -> Tiles
    ->
        Maybe
            (WithMoved { tiles : Tiles })
tryMove monster dx dy tiles =
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

                            bumpMovement =
                                Bump
                                    ( case ( monster.xPos, target.xPos ) of
                                        ( XPos mX, XPos tX ) ->
                                            toFloat (tX - mX) / 2 |> X
                                    , case ( monster.yPos, target.yPos ) of
                                        ( YPos mY, YPos tY ) ->
                                            toFloat (tY - mY) / 2 |> Y
                                    )
                        in
                        { tiles =
                            move newTarget newTarget tiles
                                |> .tiles
                                |> moveInner bumpMovement newMonster newMonster
                                |> .tiles
                        , moved = newMonster
                        }

                    else
                        { tiles = tiles, moved = monster }
            )

    else
        Nothing


type Movement
    = ToTile
    | Bump ( X, Y )


move :
    Monster
    -> Positioned a
    -> Tiles
    -> WithMoved { tiles : Tiles }
move =
    moveInner ToTile


moveInner :
    Movement
    -> Monster
    -> Positioned a
    -> Tiles
    -> WithMoved { tiles : Tiles }
moveInner movement monsterIn { xPos, yPos } tiles =
    let
        oldTile =
            get tiles monsterIn

        newTile =
            get tiles { xPos = xPos, yPos = yPos }

        ( offsetX, offsetY ) =
            case movement of
                ToTile ->
                    ( case ( monsterIn.xPos, xPos ) of
                        ( XPos oldX, XPos newX ) ->
                            oldX - newX |> toFloat |> X
                    , case ( monsterIn.yPos, yPos ) of
                        ( YPos oldY, YPos newY ) ->
                            oldY - newY |> toFloat |> Y
                    )

                Bump ( ox, oy ) ->
                    ( ox, oy )

        monster =
            { monsterIn
                | xPos = xPos
                , yPos = yPos
                , offsetX = offsetX
                , offsetY = offsetY
            }
    in
    { tiles =
        set { oldTile | monster = Nothing } tiles
            |> set { newTile | monster = Just monster }
    , moved = monster
    }
