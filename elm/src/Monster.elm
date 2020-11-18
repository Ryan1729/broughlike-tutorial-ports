module Monster exposing (HP(..), Kind(..), Monster, Spec, draw, fromSpec, getLocated, heal, hit, isPlayer, maxHP, stun)

import Array exposing (Array)
import Game exposing (DeltaX(..), DeltaY(..), Located, Positioned, Shake, SpriteIndex(..), X(..), XPos(..), Y(..), YPos(..))
import Ports exposing (Sound(..))
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
    Positioned
        { kind : Kind
        , sprite : SpriteIndex
        , hp : HP
        , dead : Bool
        , attackedThisTurn : Bool
        , stunned : Bool
        , teleportCounter : Int
        , offsetX : X
        , offsetY : Y
        , lastMove : ( DeltaX, DeltaY )
        }


getLocated : Monster -> Located {}
getLocated { offsetX, offsetY, xPos, yPos } =
    case ( ( offsetX, offsetY ), ( xPos, yPos ) ) of
        ( ( X ox, Y oy ), ( XPos xP, YPos yP ) ) ->
            { x = toFloat xP |> (+) ox |> X
            , y = toFloat yP |> (+) oy |> Y
            }


teleportCounterDefault =
    2


type alias Spec =
    Positioned { kind : Kind }


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
    , xPos = monsterSpec.xPos
    , yPos = monsterSpec.yPos
    , offsetX = X 0
    , offsetY = Y 0
    , sprite = sprite
    , hp = hp
    , dead = False
    , attackedThisTurn = False
    , stunned = False
    , teleportCounter = teleportCounter
    , lastMove = ( DXm1, DY0 )
    }


draw : Shake -> ( Monster, Array Ports.CommandRecord ) -> ( Monster, Array Ports.CommandRecord )
draw shake ( monster, cmdsIn ) =
    let
        located =
            getLocated monster
    in
    ( -- We update the offsets on the copy we don't draw, so that the animation
      -- occurs over the expected number of frames.
      { monster
        | offsetX =
            case monster.offsetX of
                X x ->
                    x
                        - (signum x
                            |> (*) (1.0 / 8.0)
                          )
                        |> X
        , offsetY =
            case monster.offsetY of
                Y y ->
                    y
                        - (signum y
                            |> (*) (1.0 / 8.0)
                          )
                        |> Y
      }
    , if monster.teleportCounter > 0 then
        Array.push
            (SpriteIndex 10
                |> Ports.drawSprite shake located
            )
            cmdsIn

      else
        let
            commands =
                Array.push (Ports.drawSprite shake located monster.sprite) cmdsIn
        in
        case monster.hp of
            HP hp ->
                drawHP shake located hp 0 commands
    )


drawHP : Shake -> Located a -> Float -> Float -> Array Ports.CommandRecord -> Array Ports.CommandRecord
drawHP skake monster hp i commands =
    if i >= hp then
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
                            |> Ports.drawSprite skake { x = hpX, y = hpY }
                in
                Array.push hpCommand commands
                    |> drawHP skake monster hp (i + 1)


hit : HP -> Monster -> ( Monster, Ports.CommandRecords )
hit damage target =
    case ( target.hp, damage ) of
        ( HP hp, HP d ) ->
            let
                newHP =
                    hp - d

                hitMonster =
                    { target | hp = HP newHP }

                newMonster =
                    if newHP <= 0 then
                        die hitMonster

                    else
                        hitMonster
            in
            ( newMonster
            , (case newMonster.kind of
                Player _ ->
                    Ports.playSound Hit1

                _ ->
                    Ports.playSound Hit2
              )
                |> Array.repeat 1
            )


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


signum : Float -> Float
signum x =
    if x > 0 then
        1.0

    else if x < 0 then
        -1.0

    else
        -- NaN ends up here
        0.0
