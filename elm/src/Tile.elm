module Tile exposing (..)

import Array exposing (Array)
import Game exposing (SpriteIndex(..), X(..), Y(..))
import Monster exposing (Monster)
import Ports


type Kind
    = Floor
    | Wall
    | Exit


type alias Tile =
    { kind : Kind
    , x : X
    , y : Y
    , monster : Maybe Monster
    }


draw : Tile -> Ports.CommandRecord
draw tile =
    sprite tile.kind
        |> Ports.drawSprite tile.x tile.y


sprite : Kind -> SpriteIndex
sprite kind =
    case kind of
        Floor ->
            SpriteIndex 2

        Wall ->
            SpriteIndex 3

        Exit ->
            SpriteIndex 11


floor : X -> Y -> Tile
floor x y =
    { kind = Floor, x = x, y = y, monster = Nothing }


wall : X -> Y -> Tile
wall x y =
    { kind = Wall, x = x, y = y, monster = Nothing }


isPassable tile =
    case tile.kind of
        Floor ->
            True

        Wall ->
            False

        Exit ->
            True


hasMonster { monster } =
    case monster of
        Just _ ->
            True

        Nothing ->
            False
