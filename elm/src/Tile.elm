module Tile exposing (..)

import Array exposing (Array)
import Game exposing (Located, Positioned, Shake, SpriteIndex(..), X(..), XPos(..), Y(..), YPos(..))
import Monster exposing (Monster)
import Ports


type Kind
    = Floor
    | Wall
    | Exit


type alias Tile =
    Positioned
        { kind : Kind
        , monster : Maybe Monster
        , treasure : Bool
        }


getLocated : Tile -> Located {}
getLocated { xPos, yPos } =
    case ( xPos, yPos ) of
        ( XPos xP, YPos yP ) ->
            { x = toFloat xP |> X, y = toFloat yP |> Y }


draw : Shake -> Tile -> Array Ports.CommandRecord
draw shake tile =
    let
        located =
            getLocated tile

        commands =
            sprite tile.kind
                |> Ports.drawSprite shake located
                |> Array.repeat 1
    in
    if tile.treasure then
        Array.push (SpriteIndex 12 |> Ports.drawSprite shake located) commands

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


floor : Positioned a -> Tile
floor =
    withKind Floor


wall : Positioned a -> Tile
wall =
    withKind Wall


exit : Positioned a -> Tile
exit =
    withKind Exit


withKind : Kind -> (Positioned a -> Tile)
withKind kind { xPos, yPos } =
    { kind = kind, xPos = xPos, yPos = yPos, monster = Nothing, treasure = False }


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
