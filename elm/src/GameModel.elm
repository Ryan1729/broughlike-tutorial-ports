module GameModel exposing (GameModel(..), Spell, SpellName(..), SpellPage(..), State, cast, emptySpells, refreshSpells, removeSpellName, toString)

import Dict exposing (Dict)
import Game exposing (LevelNum, Positioned, Score, Shake, plainPositioned)
import Ports exposing (CommandRecords, noCmds)
import Random exposing (Seed)
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
spellsGen _ =
    --Debug.todo "Generator SpellBook"
    Random.constant emptySpells


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


toString : SpellName -> String
toString name =
    case name of
        WOOP ->
            "WOOP"


type alias Spell =
    State -> ( GameModel, CommandRecords )


cast : SpellName -> State -> ( GameModel, CommandRecords )
cast name =
    case name of
        WOOP ->
            woop


woop : Spell
woop state =
    let
        ( target, seed ) =
            Debug.todo "target, seed"

        player =
            Debug.todo "player"

        { tiles, moved } =
            Tiles.move player target state.tiles
    in
    ( Running { state | tiles = tiles, player = plainPositioned moved }, noCmds )
