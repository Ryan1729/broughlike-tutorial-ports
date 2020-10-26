module Tile exposing (..)

import Array exposing (Array)
import Game exposing (Located, SpriteIndex(..), X(..), Y(..))
import Monster exposing (Monster)
import Ports


type Kind
    = Floor
    | Wall
    | Exit


type alias Tile =
    Located
        { kind : Kind
        , monster : Maybe Monster
        , treasure : Bool
        }


draw : Tile -> Array Ports.CommandRecord
draw tile =
    let
        commands =
            sprite tile.kind
                |> Ports.drawSprite tile.x tile.y
                |> Array.repeat 1
    in
    if tile.treasure then
        Array.push (SpriteIndex 12 |> Ports.drawSprite tile.x tile.y) commands

    else
        commands


sprite : Kind -> SpriteIndex
sprite kind =
    case kind of
        Floor ->
            SpriteIndex 2

        Wall ->
            SpriteIndex 3

        Exit ->
            SpriteIndex 11


floor : Located a -> Tile
floor =
    withKind Floor


wall : Located a -> Tile
wall =
    withKind Wall


exit : Located a -> Tile
exit =
    withKind Exit


withKind : Kind -> (Located a -> Tile)
withKind kind { x, y } =
    { kind = kind, x = x, y = y, monster = Nothing, treasure = False }


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
