module Monster exposing (HP(..), Kind(..), Monster, draw, fromSpec, hit, isPlayer, stun)

import Array exposing (Array)
import Game exposing (Located, SpriteIndex(..), X(..), Y(..))
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
        , dead : Bool
        , attackedThisTurn : Bool
        , stunned : Bool
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
    , dead = False
    , attackedThisTurn = False
    , stunned = False
    }


draw : Monster -> Array Ports.CommandRecord
draw monster =
    let
        commands =
            Array.push (Ports.drawSprite monster.sprite monster.x monster.y) Array.empty
    in
    case monster.hp of
        HP hp ->
            drawHP monster (hp - 1) commands


drawHP : Located a -> Float -> Array Ports.CommandRecord -> Array Ports.CommandRecord
drawHP monster i commands =
    if i < 0 then
        commands

    else
        case ( monster.x, monster.y ) of
            ( X x, Y y ) ->
                let
                    hpX =
                        X (x + toFloat (modBy 3 (floor i)) * (5 / 16))

                    hpY =
                        Y (y - (toFloat (floor (i / 3)) * (5 / 16)))

                    hpCommand =
                        Ports.drawSprite (SpriteIndex 9) hpX hpY
                in
                Array.push hpCommand commands
                    |> drawHP monster (i - 1)


hit : HP -> Monster -> Monster
hit damage target =
    case ( target.hp, damage ) of
        ( HP hp, HP d ) ->
            let
                newHP =
                    hp - d

                newMonster =
                    { target | hp = HP newHP }
            in
            if newHP <= 0 then
                die newMonster

            else
                newMonster


die : Monster -> Monster
die monster =
    { monster | dead = True, sprite = SpriteIndex 1 }


stun : Monster -> Monster
stun monster =
    { monster | stunned = True }
