module Tiles exposing (NoPassableTile(..), Tiles, addMonster, foldMonsters, foldXY, get, getAdjacentNeighbors, getAdjacentPassableNeighbors, getNeighbor, move, noPassableTileToString, possiblyDisconnectedTilesGen, randomPassableTile, replace, set, toArray, transform, tryMove, updateMonster)

import Array exposing (Array)
import Game exposing (DeltaX(..), DeltaY(..), Located, Positioned, Shake, SpriteIndex(..), X(..), XPos(..), Y(..), YPos(..), moveX, moveY)
import Monster exposing (HP(..), Kind(..), Monster)
import Ports
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


type alias StateSubset a =
    { a
        | player : Positioned {}
        , tiles : Tiles
        , seed : Seed
        , shake : Shake
    }


updateMonster : Monster -> ( StateSubset a, Array Ports.CommandRecord ) -> ( StateSubset a, Array Ports.CommandRecord )
updateMonster monster ( stateIn, cmdsIn ) =
    case monster.kind of
        Monster.Tank ->
            let
                startedStunned =
                    monster.stunned

                { state, moved, cmds } =
                    updateMonsterInner monster stateIn
            in
            if startedStunned then
                ( state, cmds )

            else
                let
                    newMonster =
                        Monster.stun moved

                    { tiles } =
                        moveDirectly newMonster newMonster state.tiles
                in
                ( { state | tiles = tiles }, cmds )

        _ ->
            let
                record =
                    updateMonsterInner monster stateIn
            in
            ( record.state, Array.append cmdsIn record.cmds )


type alias WithMoved a =
    { a | moved : Monster }


updateMonsterInner : Monster -> StateSubset a -> WithMoved { state : StateSubset a, cmds : Array Ports.CommandRecord }
updateMonsterInner monsterIn stateIn =
    let
        monster =
            { monsterIn | teleportCounter = monsterIn.teleportCounter - 1 }
    in
    if monster.stunned || monster.teleportCounter > 0 then
        setMonster { monster | stunned = False } stateIn

    else
        let
            noChange =
                { state = stateIn, moved = monster, cmds = Array.empty }

            gen =
                case monster.kind of
                    Monster.Player _ ->
                        noChange |> Random.constant

                    Monster.Bird ->
                        doStuff stateIn monster

                    Monster.Snake ->
                        doStuff stateIn { monster | attackedThisTurn = False }
                            |> Random.andThen
                                (\{ state, moved } ->
                                    if moved.attackedThisTurn then
                                        noChange |> Random.constant

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
                                                |> (\{ state, moved } ->
                                                        { state = state
                                                        , moved = moved
                                                        , cmds = Array.empty
                                                        }
                                                   )
                                                |> Random.constant
                                )

                    Monster.Jester ->
                        getAdjacentPassableNeighbors stateIn.tiles monster
                            |> Random.map
                                (\neighbors ->
                                    case neighbors of
                                        [] ->
                                            noChange

                                        head :: _ ->
                                            case
                                                Game.deltasFrom { source = monster, target = head }
                                                    |> Maybe.andThen (\( dx, dy ) -> tryMove stateIn.shake monster dx dy stateIn.tiles)
                                            of
                                                Nothing ->
                                                    noChange

                                                Just { tiles, moved, shake, cmds } ->
                                                    { state =
                                                        { stateIn | tiles = tiles, shake = shake }
                                                    , moved = moved
                                                    , cmds = cmds
                                                    }
                                )
        in
        Random.step gen stateIn.seed
            |> (\( { state } as output, seed ) -> { output | state = { state | seed = seed } })


doStuff : StateSubset a -> Monster -> Generator (WithMoved { state : StateSubset a, cmds : Array Ports.CommandRecord })
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
                                            tryMove state.shake monster dx dy state.tiles
                                        )
                            )
                of
                    Just { tiles, moved, shake, cmds } ->
                        { state = { state | tiles = tiles, shake = shake }, moved = moved, cmds = cmds }

                    Nothing ->
                        { state = state, moved = monster, cmds = Array.empty }
            )


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
    Shake
    -> Monster
    -> DeltaX
    -> DeltaY
    -> Tiles
    ->
        Maybe
            (WithMoved { tiles : Tiles, shake : Shake, cmds : Array Ports.CommandRecord })
tryMove shake monster dx dy tiles =
    let
        newTile =
            getNeighbor tiles monster dx dy
    in
    if Tile.isPassable newTile then
        Just
            (case newTile.monster of
                Nothing ->
                    let
                        tilesWithMoved =
                            move monster newTile tiles
                    in
                    { moved = tilesWithMoved.moved, tiles = tilesWithMoved.tiles, shake = shake, cmds = Array.empty }

                Just target ->
                    if Monster.isPlayer monster.kind /= Monster.isPlayer target.kind then
                        let
                            newMonster =
                                { monster | attackedThisTurn = True }

                            ( newTarget, cmds ) =
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
                        , shake = { shake | amount = 5 }
                        , cmds = cmds
                        }

                    else
                        { tiles = tiles, moved = monster, shake = shake, cmds = Array.empty }
            )

    else
        Nothing


type Movement
    = ToTile
    | Bump ( X, Y )


move : Monster -> Positioned a -> Tiles -> WithMoved { tiles : Tiles }
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
                | offsetX = offsetX
                , offsetY = offsetY
            }
    in
    moveDirectly monster { xPos = xPos, yPos = yPos } tiles


setMonster : Monster -> StateSubset a -> WithMoved { state : StateSubset a, cmds : Array Ports.CommandRecord }
setMonster monster state =
    let
        { tiles, moved } =
            moveDirectly monster monster state.tiles
    in
    { state = { state | tiles = tiles }, moved = moved, cmds = Array.empty }


moveDirectly : Monster -> Positioned a -> Tiles -> WithMoved { tiles : Tiles }
moveDirectly monsterIn { xPos, yPos } tiles =
    let
        oldTile =
            get tiles monsterIn

        newTile =
            get tiles { xPos = xPos, yPos = yPos }

        monster =
            { monsterIn
                | xPos = xPos
                , yPos = yPos
            }
    in
    { tiles =
        set { oldTile | monster = Nothing } tiles
            |> set { newTile | monster = Just monster }
    , moved = monster
    }
