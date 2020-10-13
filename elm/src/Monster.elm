module Monster exposing (HP(..), Kind(..), Monster, add, draw, isNothing, move, tryMove)

import Game exposing (DeltaX(..), DeltaY(..), Located, SpriteIndex(..), X(..), Y(..))
import Map exposing (Tiles)
import Ports
import Tile exposing (Tile)


type Kind
    = Player
    | Bird
    | Snake
    | Tank
    | Eater
    | Jester


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
        ( sprite, hp ) =
            case monsterSpec.kind of
                Player ->
                    ( SpriteIndex 0, HP 3 )

                Bird ->
                    ( SpriteIndex 4, HP 3 )

                Snake ->
                    ( SpriteIndex 5, HP 1 )

                Tank ->
                    ( SpriteIndex 6, HP 2 )

                Eater ->
                    ( SpriteIndex 7, HP 1 )

                Jester ->
                    ( SpriteIndex 8, HP 2 )

        newMonster =
            { kind = monsterSpec.kind
            , x = monsterSpec.x
            , y = monsterSpec.y
            , sprite = sprite
            , hp = hp
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
            Map.get tiles monsterIn.x monsterIn.y

        newTile =
            Map.get tiles x y

        monster =
            { monsterIn | x = x, y = y }
    in
    ( Map.set { oldTile | monster = Nothing } tiles
        |> Map.set { newTile | monster = Just () }
    , monster
    )
