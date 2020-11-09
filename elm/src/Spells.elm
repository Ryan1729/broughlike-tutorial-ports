module Spells exposing (Spell, SpellName(..), cast, toString)

import Game exposing (plainPositioned)
import GameModel exposing (GameModel(..), State)
import Ports exposing (CommandRecords, noCmds)
import Tiles exposing (Tiles)


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
