module Monster exposing (HP(..), Kind(..), Monster, add, draw, isNothing, move, tryMove)

import Game exposing (DeltaX(..), DeltaY(..), Located, SpriteIndex(..), X(..), Y(..))
import Map exposing (Tiles)
import Ports
import Tile exposing (Tile)


type Kind
    = Player


type HP
    = HP Float


type alias Monster =
    { kind : Kind
    , x : X
    , y : Y
    , sprite : SpriteIndex
    , hp : HP
    }


add : Tiles -> Located { kind : Kind } -> ( Tiles, Monster )
add tiles monsterSpec =
    let
        newMonster =
            case monsterSpec.kind of
                Player ->
                    { kind = Player
                    , x = monsterSpec.x
                    , y = monsterSpec.y
                    , sprite = SpriteIndex 0
                    , hp = HP 3
                    }
    in
    move tiles newMonster monsterSpec


draw : Monster -> Ports.CommandRecord
draw monster =
    Ports.drawSprite monster.sprite monster.x monster.y


isNothing : Maybe a -> Bool
isNothing maybe =
    case maybe of
        Just _ ->
            False

        Nothing ->
            True

tryMove : Tiles -> Monster -> DeltaX -> DeltaY -> Maybe ( Tiles, Monster )
tryMove tiles monster dx dy =
    let
        newTile =
            Map.getNeighbor tiles monster dx dy
    in
    if Tile.isPassable newTile then
        Just
            (if isNothing newTile.monster then
                move tiles monster newTile

             else
                ( tiles, monster )
            )

    else
        Nothing


move : Tiles -> Monster -> Located a -> ( Tiles, Monster )
move tiles monsterIn { x, y } =
    let
        oldTile =
            Map.get tiles x y

        monster =
            { monsterIn | x = x, y = y }
    in
    ( Map.set tiles { oldTile | monster = Just () }
    , monster
    )
