module Tile exposing (..)

import Array exposing (Array)
import Game exposing (SpriteIndex(..), X(..), Y(..))
import Ports


type Kind
    = Floor
    | Wall


type alias MonsterId =
    -- This will probably be an index into a monsters array later
    ()


type alias Tile =
    { kind : Kind
    , x : X
    , y : Y
    , sprite : SpriteIndex
    , monster : Maybe MonsterId
    }


draw : Tile -> Ports.CommandRecord
draw tile =
    Ports.drawSprite tile.sprite tile.x tile.y


floor : X -> Y -> Tile
floor x y =
    { kind = Floor, x = x, y = y, sprite = SpriteIndex 2, monster = Nothing }


wall : X -> Y -> Tile
wall x y =
    { kind = Wall, x = x, y = y, sprite = SpriteIndex 3, monster = Nothing }


isPassable tile =
    case tile.kind of
        Floor ->
            True

        Wall ->
            False


hasMonster { monster } =
    case monster of
        Just _ ->
            True

        Nothing ->
            False
