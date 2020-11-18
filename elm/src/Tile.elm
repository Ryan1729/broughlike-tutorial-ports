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
        , effect : Maybe Effect
        }


type alias Effect =
    { index : SpriteIndex
    , counter : Int
    }


maxEffectCount =
    30


setEffect : SpriteIndex -> Tile -> Tile
setEffect index tile =
    { tile
        | effect = Effect index maxEffectCount |> Just
    }


getLocated : Tile -> Located {}
getLocated { xPos, yPos } =
    case ( xPos, yPos ) of
        ( XPos xP, YPos yP ) ->
            { x = toFloat xP |> X, y = toFloat yP |> Y }


draw : Shake -> ( Tile, Ports.CommandRecords ) -> ( Tile, Ports.CommandRecords )
draw shake ( tile, commandsIn ) =
    let
        located =
            getLocated tile

        drawTreasure cmds =
            if tile.treasure then
                Array.push (SpriteIndex 12 |> Ports.drawSprite shake located) cmds

            else
                cmds

        commands =
            Array.push
                (sprite tile.kind
                    |> Ports.drawSprite shake located
                )
                commandsIn
                |> drawTreasure
    in
    case tile.effect of
        Just { index, counter } ->
            if counter <= 0 then
                ( { tile | effect = Nothing }, commands )

            else
                let
                    alpha =
                        toFloat counter / maxEffectCount
                in
                ( { tile
                    | effect = Just (Effect index (counter - 1))
                  }
                , Array.push (Ports.drawSpriteAlpha alpha shake located index) commands
                )

        Nothing ->
            ( tile, commands )


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
    { kind = kind, xPos = xPos, yPos = yPos, monster = Nothing, treasure = False, effect = Nothing }


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
