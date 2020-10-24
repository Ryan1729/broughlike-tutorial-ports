module Monster exposing (HP(..), Kind(..), Monster, Spec, draw, fromSpec, heal, hit, isPlayer, stun)

import Array exposing (Array)
import Game exposing (Located, SpriteIndex(..), X(..), Y(..))
import Ports
import Random exposing (Generator, Seed)


type Kind
    = Player HP
    | Bird
    | Snake
    | Tank
    | Eater
    | Jester


isPlayer : Kind -> Bool
isPlayer kind =
    case kind of
        Player _ ->
            True

        _ ->
            False


type HP
    = HP Float


maxHP =
    6


type alias Monster =
    Located
        { kind : Kind
        , sprite : SpriteIndex
        , hp : HP
        , dead : Bool
        , attackedThisTurn : Bool
        , stunned : Bool
        , teleportCounter : Int
        }


teleportCounterDefault =
    2


type alias Spec =
    Located { kind : Kind }


fromSpec : Spec -> Monster
fromSpec monsterSpec =
    let
        ( sprite, hp, teleportCounter ) =
            case monsterSpec.kind of
                Player startingHp ->
                    ( SpriteIndex 0, startingHp, 0 )

                Bird ->
                    ( SpriteIndex 4, HP 3, teleportCounterDefault )

                Snake ->
                    ( SpriteIndex 5, HP 1, teleportCounterDefault )

                Tank ->
                    ( SpriteIndex 6, HP 2, teleportCounterDefault )

                Eater ->
                    ( SpriteIndex 7, HP 1, teleportCounterDefault )

                Jester ->
                    ( SpriteIndex 8, HP 2, teleportCounterDefault )
    in
    { kind = monsterSpec.kind
    , x = monsterSpec.x
    , y = monsterSpec.y
    , sprite = sprite
    , hp = hp
    , dead = False
    , attackedThisTurn = False
    , stunned = False
    , teleportCounter = teleportCounter
    }


draw : Monster -> Array Ports.CommandRecord
draw monster =
    if monster.teleportCounter > 0 then
        Array.push
            (SpriteIndex 10
                |> Ports.drawSprite monster.x monster.y
            )
            Array.empty

    else
        let
            commands =
                Array.push (Ports.drawSprite monster.x monster.y monster.sprite) Array.empty
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
                        SpriteIndex 9
                            |> Ports.drawSprite hpX hpY
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


heal : HP -> Monster -> Monster
heal damage target =
    case ( target.hp, damage ) of
        ( HP hp, HP d ) ->
            let
                newHP =
                    hp
                        + d
                        |> min maxHP

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
