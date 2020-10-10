module Tile exposing (..)

import Array exposing (Array)
import Game exposing (SpriteIndex(..), X(..), Y(..))
import Ports


type Kind
    = Floor
    | Wall


type alias Tile =
    { kind : Kind
    , x : X
    , y : Y
    , sprite : SpriteIndex
    }


draw : Tile -> Ports.CommandRecord
draw tile =
    Ports.drawSprite tile.sprite tile.x tile.y


floor : X -> Y -> Tile
floor x y =
    { kind = Floor, x = x, y = y, sprite = SpriteIndex 2 }


wall : X -> Y -> Tile
wall x y =
    { kind = Wall, x = x, y = y, sprite = SpriteIndex 3 }


isPassable tile =
    case tile.kind of
        Floor ->
            True

        Wall ->
            False



-- Fill this in once we can


hasMonster tile =
    False
