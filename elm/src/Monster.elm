module Monster exposing (HP(..), Kind(..), Monster, Monsters, add, draw, isDead, isNothing, isPlayer, move, tryMove, update)

import Array exposing (Array)
import Game exposing (DeltaX(..), DeltaY(..), Located, SpriteIndex(..), X(..), Y(..))
import Ports
import Random exposing (Generator)
import Tile exposing (MonsterId(..), Tile)
import Tiles exposing (Tiles)


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
    { kind : Kind
    , x : X
    , y : Y
    , sprite : SpriteIndex
    , hp : HP
    }


type alias Monsters =
    Array Monster


get : Monsters -> MonsterId -> Maybe Monster
get monsters monsterId =
    case monsterId of
        MonsterId index ->
            Array.get index monsters


setOrPush : MonsterId -> Monster -> Monsters -> Monsters
setOrPush monsterId monster monsters =
    case monsterId of
        MonsterId index ->
            if index == Array.length monsters then
                Array.push monster monsters

            else
                Array.set index monster monsters


isDead : Monster -> Bool
isDead monster =
    -- TODO change when needed
    False


update :
    { a
        | player : Monster
        , tiles : Tiles
        , monsters : Monsters
    }
    -> MonsterId
    ->
        Generator
            { a
                | player : Monster
                , tiles : Tiles
                , monsters : Monsters
            }
update state monsterId =
    case get state.monsters monsterId of
        Nothing ->
            Random.constant state

        Just monster ->
            Tiles.getAdjacentPassableNeighbors state.tiles monster
                |> Random.map
                    (List.filter
                        (\t ->
                            case Maybe.andThen (get state.monsters) t.monster of
                                Just m ->
                                    isPlayer m.kind

                                Nothing ->
                                    False
                        )
                    )
                |> Random.map
                    (\neighbors ->
                        case
                            List.sortBy (Game.dist state.player) neighbors
                                |> List.head
                                |> Maybe.andThen
                                    (\newTile ->
                                        Game.deltasFrom newTile monster
                                            |> Maybe.andThen
                                                (\( dx, dy ) ->
                                                    tryMove state monsterId dx dy
                                                )
                                    )
                        of
                            Just newState ->
                                newState

                            Nothing ->
                                state
                    )


add :
    { a
        | tiles : Tiles
        , monsters : Monsters
    }
    -> Located { kind : Kind }
    ->
        { a
            | tiles : Tiles
            , monsters : Monsters
        }
add state monsterSpec =
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
    move state (New newMonster) monsterSpec


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


tryMove :
    { a
        | tiles : Tiles
        , monsters : Monsters
    }
    -> MonsterId
    -> DeltaX
    -> DeltaY
    ->
        Maybe
            { a
                | tiles : Tiles
                , monsters : Monsters
            }
tryMove state monsterId dx dy =
    get state.monsters monsterId
        |> Maybe.andThen
            (\monster ->
                let
                    newTile =
                        Tiles.getNeighbor state.tiles monster dx dy
                in
                if Tile.isPassable newTile then
                    Just
                        (if isNothing newTile.monster then
                            move state (Old monsterId) newTile

                         else
                            state
                        )

                else
                    Nothing
            )


type NewOrOldMonster
    = New Monster
    | Old MonsterId


toMonsterAndId : Monsters -> NewOrOldMonster -> Maybe ( MonsterId, Monster )
toMonsterAndId monsters newOrOld =
    case newOrOld of
        New m ->
            Just ( Array.length monsters |> MonsterId, m )

        Old mId ->
            get monsters mId
                |> Maybe.map (\m -> ( mId, m ))


move :
    { a
        | tiles : Tiles
        , monsters : Monsters
    }
    -> NewOrOldMonster
    -> Located b
    ->
        { a
            | tiles : Tiles
            , monsters : Monsters
        }
move state newOrOld { x, y } =
    case toMonsterAndId state.monsters newOrOld of
        Nothing ->
            state

        Just ( monsterId, monsterIn ) ->
            let
                oldTile =
                    Tiles.get state.tiles monsterIn.x monsterIn.y

                newTile =
                    Tiles.get state.tiles x y

                monster =
                    { monsterIn | x = x, y = y }
            in
            { state
                | tiles =
                    Tiles.set { oldTile | monster = Nothing } state.tiles
                        |> Tiles.set { newTile | monster = Just monsterId }
                , monsters = setOrPush monsterId monster state.monsters
            }
