module GameModel exposing (GameModel(..), Spell, SpellBook, SpellName(..), SpellPage(..), State, addSpellViaTreasureIfApplicable, cast, emptySpells, refreshSpells, removeSpellName, spellNameToString, spellNamesWithOneBasedIndex)

import Array exposing (Array)
import Dict exposing (Dict)
import Game exposing (LevelNum, Positioned, Score(..), Shake, plainPositioned)
import Monster exposing (Monster)
import Ports exposing (CommandRecords, noCmds)
import Random exposing (Seed)
import Randomness
import Tiles exposing (Tiles)


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


spellNameToString : SpellName -> String
spellNameToString name =
    case name of
        WOOP ->
            "WOOP"

        QUAKE ->
            "QUAKE"

        MAELSTROM ->
            "MAELSTROM"


spellNameGen : Random.Generator SpellName
spellNameGen =
    Randomness.genFromNonEmpty
        ( WOOP
        , [ QUAKE
          , MAELSTROM
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


runningWithNoCmds state =
    ( Running state
    , noCmds
    )


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
