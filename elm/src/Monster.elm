module Monster exposing (HP(..), Kind(..), Monster, draw, fromSpec, isDead, isPlayer)

import Array exposing (Array)
import Game exposing (Located, SpriteIndex(..))
import Ports
import Random exposing (Generator, Seed)


type Kind
    = Player
    | Bird
    | Snake
    | Tank
    | Eater
    | Jester


isPlayer : Kind -> Bool
isPlayer kind =
    case kind of
        Player ->
            True

        _ ->
            False


type HP
    = HP Float


type alias Monster =
    Located
        { kind : Kind
        , sprite : SpriteIndex
        , hp : HP
        }


fromSpec : Located { kind : Kind } -> Monster
fromSpec monsterSpec =
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
    in
    { kind = monsterSpec.kind
    , x = monsterSpec.x
    , y = monsterSpec.y
    , sprite = sprite
    , hp = hp
    }


draw : Monster -> Ports.CommandRecord
draw monster =
    Ports.drawSprite monster.sprite monster.x monster.y


isDead : Monster -> Bool
isDead monster =
    -- TODO change when needed
    False
