module GameModel exposing (GameModel(..), Spell, SpellBook, SpellName(..), SpellPage(..), State, addSpellViaTreasureIfApplicable, cast, emptySpells, refreshSpells, removeSpellName, spellNameToString, spellNamesWithOneBasedIndex, startLevel)

import Array exposing (Array)
import Dict exposing (Dict)
import Game exposing (DeltaX(..), DeltaY(..), LevelNum, Positioned, Score(..), Shake, SpriteIndex(..), X(..), Y(..), plainPositioned)
import Map
import Monster exposing (Monster)
import Ports exposing (CommandRecords, noCmds, withNoCmd)
import Random exposing (Seed)
import Randomness
import Tile exposing (Tile)
import Tiles exposing (Tiles)


initialSpawnRate =
    15


type GameModel
    = Error String
    | Title (Maybe State) Seed
    | Running State
    | Dead State


type alias State =
    { player : Positioned {}
    , seed : Seed
    , tiles : Tiles
    , level : LevelNum
    , spawnCounter : Int
    , spawnRate : Int
    , score : Score
    , shake : Shake
    , numSpells : Int
    , spells : SpellBook
    }


startLevel : Score -> Seed -> Monster.HP -> Maybe SpellBook -> Int -> LevelNum -> GameModel
startLevel score seedIn hp previousSpells numSpells levelNum =
    let
        ( levelRes, seed1 ) =
            Random.step (Map.generateLevel levelNum) seedIn

        stateRes : Result String State
        stateRes =
            Result.andThen
                (\tilesIn ->
                    let
                        tileGen =
                            Tiles.randomPassableTile tilesIn

                        ( startingTilesRes, seed ) =
                            Random.step
                                (Random.pair tileGen
                                    tileGen
                                    |> Random.pair
                                        (Random.list 3 tileGen)
                                    |> Random.map
                                        (\pair ->
                                            case pair of
                                                ( listOfResults, ( Ok t1, Ok t2 ) ) ->
                                                    case toResultOfList listOfResults of
                                                        Ok list ->
                                                            Ok ( t1, t2, list )

                                                        _ ->
                                                            Err Tiles.NoPassableTile

                                                _ ->
                                                    Err Tiles.NoPassableTile
                                        )
                                )
                                seed1
                    in
                    Result.mapError Tiles.noPassableTileToString startingTilesRes
                        |> Result.map
                            (\( playerTile, exitTile, treasureTiles ) ->
                                let
                                    player =
                                        { xPos = playerTile.xPos, yPos = playerTile.yPos }

                                    tiles : Tiles
                                    tiles =
                                        Tiles.addMonster tilesIn
                                            { kind = Monster.Player hp
                                            , xPos = player.xPos
                                            , yPos = player.yPos
                                            }
                                            |> (\ts ->
                                                    List.foldl
                                                        (Tiles.transform Tile.addTreasure)
                                                        ts
                                                        treasureTiles
                                               )
                                            -- We do this instead of just using replace in case
                                            -- the player tile is the same as the exit tile
                                            |> Tiles.transform (\t -> { t | kind = Tile.Exit }) exitTile

                                    state =
                                        { player = player
                                        , seed = seed
                                        , tiles = tiles
                                        , level = levelNum
                                        , spawnRate = initialSpawnRate
                                        , spawnCounter = initialSpawnRate
                                        , score = score
                                        , shake =
                                            { amount = 0
                                            , x = X 0
                                            , y = Y 0
                                            }
                                        , numSpells = numSpells
                                        , spells = emptySpells
                                        }
                                in
                                case previousSpells of
                                    Just spells ->
                                        { state | spells = spells }

                                    Nothing ->
                                        refreshSpells state
                            )
                )
                levelRes
    in
    case stateRes of
        Err e ->
            Error e

        Ok s ->
            Running s



-- I think this might reverse the order of the list, but for my current purposes,
-- I don't care whether it does or not.


toResultOfList : List (Result e a) -> Result e (List a)
toResultOfList results =
    toResultOfListHelper results []


toResultOfListHelper results output =
    case results of
        [] ->
            Ok output

        (Ok a) :: rest ->
            a
                :: output
                |> toResultOfListHelper rest

        (Err e) :: _ ->
            Err e



--
--  Spells
--


type SpellPage
    = One
    | Two
    | Three
    | Four
    | Five
    | Six
    | Seven
    | Eight
    | Nine


type SpellBook
    = SpellBook (Dict Int SpellName)


spellNamesWithOneBasedIndex : SpellBook -> List ( Int, Maybe SpellName )
spellNamesWithOneBasedIndex book =
    case book of
        SpellBook spells ->
            [ getPair 1 spells
            , getPair 2 spells
            , getPair 3 spells
            , getPair 4 spells
            , getPair 5 spells
            , getPair 6 spells
            , getPair 7 spells
            , getPair 8 spells
            , getPair 9 spells
            ]


maxNumSpells : Int
maxNumSpells =
    9


foldSpellKeysr : (Int -> a -> a) -> a -> a
foldSpellKeysr folder acc =
    folder 9 acc
        |> folder 8
        |> folder 7
        |> folder 6
        |> folder 5
        |> folder 4
        |> folder 3
        |> folder 2
        |> folder 1


getPair key spells =
    ( key, Dict.get key spells )


emptySpells =
    SpellBook Dict.empty


refreshSpells : State -> State
refreshSpells state =
    let
        ( spells, seed ) =
            Random.step (spellsGen state.numSpells) state.seed
    in
    { state
        | spells = spells
        , seed = seed
    }


spellsGen : Int -> Random.Generator SpellBook
spellsGen numSpells =
    let
        -- clamp numSpells within 1 to 9
        ns =
            min numSpells 9
                |> max 1
    in
    Random.list ns spellNameGen
        |> Random.map (List.indexedMap (\a b -> ( a + 1, b )))
        |> Random.map Dict.fromList
        |> Random.map SpellBook


addSpellViaTreasureIfApplicable : State -> State
addSpellViaTreasureIfApplicable state =
    if
        (case state.score of
            Score score ->
                remainderBy 3 score == 0
        )
            && state.numSpells
            < maxNumSpells
    then
        let
            ( spells, seed ) =
                addSpell state.spells state.seed
        in
        { state
            | numSpells = state.numSpells + 1
            , spells = spells
            , seed = seed
        }

    else
        state


addSpell : SpellBook -> Seed -> ( SpellBook, Seed )
addSpell book seedIn =
    case book of
        SpellBook spellsIn ->
            let
                ( newSpell, seed ) =
                    Random.step spellNameGen seedIn

                list =
                    Dict.toList spellsIn

                lastIndex =
                    List.length list - 1

                maxKey =
                    List.map (\( i, _ ) -> i) list
                        |> List.sort
                        |> List.drop lastIndex
                        |> List.head
                        |> Maybe.withDefault 0
            in
            if maxKey < maxNumSpells then
                ( Dict.insert (maxKey + 1) newSpell spellsIn |> SpellBook, seed )

            else
                ( book, seedIn )


removeSpellName : State -> SpellPage -> Maybe ( SpellName, State )
removeSpellName state spellPage =
    case state.spells of
        SpellBook spells ->
            let
                key =
                    case spellPage of
                        One ->
                            1

                        Two ->
                            2

                        Three ->
                            3

                        Four ->
                            4

                        Five ->
                            5

                        Six ->
                            6

                        Seven ->
                            7

                        Eight ->
                            8

                        Nine ->
                            9
            in
            case Dict.get key spells of
                Just spellName ->
                    Just ( spellName, { state | spells = Dict.remove key spells |> SpellBook } )

                Nothing ->
                    Nothing


type SpellName
    = WOOP
    | QUAKE
    | MAELSTROM
    | MULLIGAN
    | AURA
    | DASH
    | DIG
    | KINGMAKER
    | ALCHEMY
    | POWER
    | BUBBLE
    | BRAVERY
    | BOLT
    | CROSS
    | EX


spellNameToString : SpellName -> String
spellNameToString name =
    case name of
        WOOP ->
            "WOOP"

        QUAKE ->
            "QUAKE"

        MAELSTROM ->
            "MAELSTROM"

        MULLIGAN ->
            "MULLIGAN"

        AURA ->
            "AURA"

        DASH ->
            "DASH"

        DIG ->
            "DIG"

        KINGMAKER ->
            "KINGMAKER"

        ALCHEMY ->
            "ALCHEMY"

        POWER ->
            "POWER"

        BUBBLE ->
            "BUBBLE"

        BRAVERY ->
            "BRAVERY"

        BOLT ->
            "BOLT"

        CROSS ->
            "CROSS"

        EX ->
            "EX"


spellNameGen : Random.Generator SpellName
spellNameGen =
    Randomness.genFromNonEmpty
        ( WOOP
        , [ QUAKE
          , MAELSTROM
          , MULLIGAN
          , AURA
          , DASH
          , DIG
          , KINGMAKER
          , ALCHEMY
          , POWER
          , BUBBLE
          , BRAVERY
          , BOLT
          , CROSS
          , EX
          ]
        )


type alias Spell =
    State -> ( GameModel, CommandRecords )


cast : SpellName -> State -> ( GameModel, CommandRecords )
cast name =
    case name of
        WOOP ->
            woop

        QUAKE ->
            quake

        MAELSTROM ->
            maelstrom

        MULLIGAN ->
            mulligan

        AURA ->
            aura

        DASH ->
            dash

        DIG ->
            dig

        KINGMAKER ->
            kingmaker

        ALCHEMY ->
            alchemy

        POWER ->
            power

        BUBBLE ->
            bubble

        BRAVERY ->
            bravery

        BOLT ->
            bolt

        CROSS ->
            cross

        EX ->
            ex


runningWithNoCmds state =
    ( Running state
    , noCmds
    )


runningWithCmds ( state, cmds ) =
    ( Running state
    , cmds
    )



--
--  Spell helpers
--


dashPosHelper : Tiles -> ( DeltaX, DeltaY ) -> Positioned {} -> Positioned {}
dashPosHelper tiles deltas newPos =
    let
        testTile =
            Tiles.getNeighbor tiles newPos deltas
    in
    if Tile.isPassable testTile && testTile.monster == Nothing then
        plainPositioned testTile
            |> dashPosHelper tiles deltas

    else
        newPos


requirePlayer : (Monster -> Spell) -> Spell
requirePlayer spellMaker state =
    case Tiles.get state.tiles state.player |> .monster of
        Nothing ->
            ( Error "Could not find player", noCmds )

        Just player ->
            spellMaker player state


replaceWallWithFloor : Tile -> Tile
replaceWallWithFloor tile =
    if Tile.isPassable tile then
        tile

    else
        Tile.floor tile


changeTiles : Tiles -> Spell
changeTiles tiles state =
    { state | tiles = tiles }
        |> runningWithNoCmds


boltEffect : ( a, DeltaY ) -> Game.SpriteIndex
boltEffect ( _, dy ) =
    (15
        + (case dy of
            DY1 ->
                1

            DYm1 ->
                1

            DY0 ->
                0
          )
    )
        |> SpriteIndex


boltTravel : ( DeltaX, DeltaY ) -> Game.SpriteIndex -> Monster.HP -> State -> ( State, CommandRecords )
boltTravel deltas effect damage stateIn =
    let
        newTile =
            Tiles.get stateIn.tiles stateIn.player

        hit =
            Monster.hit damage

        loop : Tile -> ( State, CommandRecords ) -> ( State, CommandRecords )
        loop prevTile ( state, cmdsIn ) =
            let
                testTile =
                    Tiles.getNeighbor state.tiles prevTile deltas

                ( hitMonster, hitCmds ) =
                    case testTile.monster of
                        Just m ->
                            case hit m of
                                ( a, b ) ->
                                    ( Just a, b )

                        Nothing ->
                            ( Nothing, Ports.noCmds )

                tiles =
                    Tiles.set
                        ({ testTile | monster = hitMonster }
                            |> Tile.setEffect effect
                        )
                        state.tiles
            in
            if Tile.isPassable testTile then
                ( { state | tiles = tiles }, Array.append cmdsIn hitCmds )
                    |> loop testTile

            else
                ( state, cmdsIn )
    in
    loop newTile ( stateIn, Ports.noCmds )



--
--  the Spells themselves
--


woop : Spell
woop state =
    let
        ( result, seed ) =
            Random.step (Tiles.randomPassableTile state.tiles) state.seed
    in
    case result of
        Ok target ->
            case Tiles.get state.tiles state.player |> .monster of
                Nothing ->
                    ( Error "Could not locate player"
                    , noCmds
                    )

                Just player ->
                    let
                        { tiles, moved } =
                            Tiles.move player target state.tiles
                    in
                    { state | tiles = tiles, player = plainPositioned moved }
                        |> runningWithNoCmds

        Err Tiles.NoPassableTile ->
            ( Tiles.noPassableTileToString Tiles.NoPassableTile
                |> Error
            , noCmds
            )


quake : Spell
quake state =
    let
        folder : Positioned {} -> ( Tiles, Seed, CommandRecords ) -> ( Tiles, Seed, CommandRecords )
        folder xy ( ts, seedIn, cmds ) =
            let
                tile =
                    Tiles.get ts xy
            in
            case tile.monster of
                Just monsterIn ->
                    let
                        ( passableCount, seedOut ) =
                            Random.step
                                (Tiles.getAdjacentPassableNeighbors ts tile
                                    |> Random.map List.length
                                )
                                seedIn

                        numWalls =
                            4 - passableCount

                        ( monster, hitCmds ) =
                            Monster.hit (numWalls * 2 |> toFloat |> Monster.HP) monsterIn
                    in
                    ( Tiles.set
                        { tile
                            | monster = Just monster
                        }
                        ts
                    , seedOut
                    , Array.append cmds hitCmds
                    )

                Nothing ->
                    ( ts, seedIn, cmds )

        ( tiles, seed, cmdsOut ) =
            Tiles.foldXY
                folder
                ( state.tiles, state.seed, noCmds )

        shakeIn =
            state.shake
    in
    ( Running
        { state
            | tiles = tiles
            , shake = { shakeIn | amount = 20 }
            , seed = seed
        }
    , cmdsOut
    )


maelstrom : Spell
maelstrom state =
    let
        folder : Monster -> ( Tiles, Seed ) -> ( Tiles, Seed )
        folder monster ( ts, seedIn ) =
            if Monster.isPlayer monster.kind then
                ( ts, seedIn )

            else
                let
                    ( passableTile, seedOut ) =
                        Random.step
                            (Tiles.randomPassableTile ts)
                            seedIn

                    target : Positioned {}
                    target =
                        case passableTile of
                            Ok t ->
                                plainPositioned t

                            Err _ ->
                                plainPositioned monster
                in
                ( Tiles.move
                    { monster
                        | teleportCounter = 2
                    }
                    target
                    ts
                    |> .tiles
                , seedOut
                )

        ( tiles, seed ) =
            Tiles.foldMonsters
                folder
                ( state.tiles, state.seed )
                state.tiles
    in
    { state
        | tiles = tiles
        , seed = seed
    }
        |> runningWithNoCmds


mulligan : Spell
mulligan state =
    startLevel state.score state.seed (Monster.HP 1) (Just state.spells) state.numSpells state.level
        |> withNoCmd


aura : Spell
aura state =
    let
        healPositions =
            Tiles.getAdjacentNeighborsUnshuffled state.tiles state.player
                |> List.map plainPositioned
                |> (::) state.player
    in
    { state
        | tiles =
            List.foldr
                (Tiles.transform
                    (\tile ->
                        { tile
                            | monster = Maybe.map (Monster.heal (Monster.HP 1)) tile.monster
                        }
                            |> Tile.setEffect (Game.SpriteIndex 13)
                    )
                )
                state.tiles
                healPositions
    }
        |> runningWithNoCmds


dash : Spell
dash =
    requirePlayer
        (\player state ->
            let
                newPos =
                    dashPosHelper state.tiles player.lastMove state.player
            in
            if plainPositioned player /= newPos then
                let
                    { tiles, moved } =
                        Tiles.move player newPos state.tiles

                    ( adjacentNeighbors, seed ) =
                        Random.step (Tiles.getAdjacentNeighbors tiles newPos) state.seed

                    folder : Tile -> ( Tiles, CommandRecords ) -> ( Tiles, CommandRecords )
                    folder tile ( tilesIn, commandsIn ) =
                        case tile.monster of
                            Just monster ->
                                let
                                    ( hitMonster, newCmds ) =
                                        Monster.hit (Monster.HP 1) monster
                                in
                                ( Tiles.transform
                                    (\t ->
                                        { t
                                            | monster = Monster.stun hitMonster |> Just
                                        }
                                            |> Tile.setEffect (Game.SpriteIndex 14)
                                    )
                                    tile
                                    tilesIn
                                , Array.append commandsIn newCmds
                                )

                            Nothing ->
                                ( tilesIn, commandsIn )

                    ( tilesOut, commands ) =
                        List.foldr
                            folder
                            ( tiles, noCmds )
                            adjacentNeighbors
                in
                ( Running
                    { state
                        | tiles = tilesOut
                        , player = plainPositioned moved
                        , seed = seed
                    }
                , commands
                )

            else
                runningWithNoCmds state
        )


dig : Spell
dig state =
    let
        folder : Positioned {} -> Tiles -> Tiles
        folder xy =
            Tiles.transform
                (\tile ->
                    case
                        tile.monster
                            |> Maybe.andThen
                                (\m ->
                                    if Monster.isPlayer m.kind then
                                        Just m

                                    else
                                        Nothing
                                )
                    of
                        Just monsterIn ->
                            { tile
                                | monster = Monster.heal (Monster.HP 2) monsterIn |> Just
                            }
                                |> Tile.setEffect (Game.SpriteIndex 13)
                                |> replaceWallWithFloor

                        Nothing ->
                            replaceWallWithFloor tile
                )
                xy

        tiles =
            Tiles.foldXY
                folder
                state.tiles
    in
    changeTiles tiles state


kingmaker : Spell
kingmaker state =
    let
        folder : Positioned {} -> Tiles -> Tiles
        folder xy =
            Tiles.transform
                (\tile ->
                    case
                        tile.monster
                            |> Maybe.andThen
                                (\m ->
                                    if Monster.isPlayer m.kind then
                                        Nothing

                                    else
                                        Just m
                                )
                    of
                        Just monsterIn ->
                            { tile
                                | monster = Monster.heal (Monster.HP 1) monsterIn |> Just
                            }
                                |> Tile.addTreasure

                        Nothing ->
                            tile
                )
                xy

        tiles =
            Tiles.foldXY
                folder
                state.tiles
    in
    changeTiles tiles state


alchemy : Spell
alchemy state =
    let
        tiles =
            Tiles.getAdjacentNeighborsUnshuffled state.tiles state.player
                |> List.foldr
                    (Tiles.transform
                        (\tile ->
                            if not (Tile.isPassable tile) && Tiles.inBounds tile then
                                replaceWallWithFloor tile
                                    |> Tile.addTreasure

                            else
                                tile
                        )
                    )
                    state.tiles
    in
    changeTiles tiles state


power : Spell
power =
    requirePlayer
        (\player state ->
            let
                newPlayer =
                    { player | bonusAttack = 5 }

                tiles =
                    Tiles.move newPlayer newPlayer state.tiles |> .tiles
            in
            changeTiles tiles state
        )


bubble : Spell
bubble state =
    { state
        | spells =
            case state.spells of
                SpellBook spellbook ->
                    foldSpellKeysr
                        (\key spellsIn ->
                            case Dict.get key spellsIn of
                                Just _ ->
                                    spellsIn

                                Nothing ->
                                    case Dict.get (key - 1) spellsIn of
                                        Nothing ->
                                            spellsIn

                                        Just name ->
                                            Dict.insert key name spellsIn
                        )
                        spellbook
                        |> SpellBook
    }
        |> runningWithNoCmds


bravery : Spell
bravery state =
    changeTiles
        (Tiles.foldMonsters
            (\monster ts ->
                Tiles.transform
                    (\tile ->
                        { tile
                            | monster =
                                Just
                                    (if Monster.isPlayer monster.kind then
                                        { monster | shield = 2 }

                                     else
                                        Monster.stun monster
                                    )
                        }
                    )
                    monster
                    ts
            )
            state.tiles
            state.tiles
        )
        state


bolt : Spell
bolt =
    requirePlayer
        (\player ->
            boltTravel player.lastMove (boltEffect player.lastMove) (Monster.HP 4)
                >> runningWithCmds
        )


cross : Spell
cross stateIn =
    let
        damage =
            Monster.HP 2
    in
    List.foldr
        (\deltas ( state, cmds ) ->
            let
                ( s, newCmds ) =
                    boltTravel deltas (boltEffect deltas) damage state
            in
            ( s, Array.append cmds newCmds )
        )
        ( stateIn, Ports.noCmds )
        [ ( DX0, DYm1 )
        , ( DX0, DY1 )
        , ( DXm1, DY0 )
        , ( DX1, DY0 )
        ]
        |> runningWithCmds


ex : Spell
ex stateIn =
    let
        damage =
            Monster.HP 3

        effect =
            SpriteIndex 14
    in
    List.foldr
        (\deltas ( state, cmds ) ->
            let
                ( s, newCmds ) =
                    boltTravel deltas effect damage state
            in
            ( s, Array.append cmds newCmds )
        )
        ( stateIn, Ports.noCmds )
        [ ( DXm1, DYm1 )
        , ( DXm1, DY1 )
        , ( DX1, DYm1 )
        , ( DX1, DY1 )
        ]
        |> runningWithCmds
