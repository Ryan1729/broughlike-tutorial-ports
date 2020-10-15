module Main exposing (..)

import Array
import Browser
import Browser.Events
import Game exposing (DeltaX(..), DeltaY(..), H(..), LevelNum(..), SpriteIndex(..), W(..), X(..), Y(..), moveX, moveY)
import Html
import Json.Decode as JD
import Map
import Monster exposing (HP(..), Monster, Monsters)
import Ports
import Random exposing (Seed)
import Tile
import Tiles exposing (Tiles)


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    Result String State


type alias State =
    { player : Monster
    , seed : Seed
    , tiles : Tiles
    , monsters : Monsters
    , level : LevelNum
    }


modelFromSeed : Seed -> Model
modelFromSeed seedIn =
    let
        levelNum =
            LevelNum 1

        ( levelRes, seed1 ) =
            Random.step (Map.generateLevel levelNum) seedIn
    in
    Result.andThen
        (\( tilesIn, monstersIn ) ->
            let
                ( startingTileRes, seed ) =
                    Random.step (Tiles.randomPassableTile tilesIn) seed1
            in
            Result.map
                (\startingTile ->
                    let
                        defaultPlayer =
                            { kind = Monster.Player, x = startingTile.x, y = startingTile.y, hp = HP 0, sprite = SpriteIndex 1 }

                        ( tiles, monstersPlusPlayer ) =
                            Monster.add { tiles = tilesIn, monsters = monstersIn } { kind = Monster.Player, x = startingTile.x, y = startingTile.y }
                                |> (\r -> ( r.tiles, r.monsters ))

                        monsters =
                            Array.filter (\m -> Monster.isPlayer m.kind |> not) monstersPlusPlayer

                        player =
                            Array.filter (\m -> Monster.isPlayer m.kind) monstersPlusPlayer
                                |> Array.get 0
                                |> Maybe.withDefault defaultPlayer
                    in
                    { player = player
                    , seed = seed
                    , tiles = tiles
                    , monsters = monsters
                    , level = levelNum
                    }
                )
                startingTileRes
        )
        levelRes


draw : State -> Cmd Msg
draw state =
    Tiles.map Tile.draw state.tiles
        |> (\prev -> Array.map Monster.draw state.monsters |> Array.append prev)
        |> Array.push (Monster.draw state.player)
        |> Ports.perform


init : Int -> ( Model, Cmd Msg )
init seed =
    ( Random.initialSeed seed
        |> modelFromSeed
    , Ports.setCanvasDimensions ( Game.pixelWidth, Game.pixelHeight )
        |> Array.repeat 1
        |> Ports.perform
    )


movePlayer : State -> DeltaX -> DeltaY -> State
movePlayer state dx dy =
    case Monster.tryMove state state.player dx dy of
        Nothing ->
            state

        Just newState ->
            newState
                |> tick


tick : State -> State
tick state =
    Array.foldr
        (\m acc ->
            -- Deleting monsters here would mess up all the indexes if we keep using arrays
            -- So, our choices are:
            --      update all indexes arfter each monster update (bleh)
            --      use generational indexes
            --          doesn't that still imply we should be fixing the indexes up?
            --      store the (non-player) monsters in the tiles, so we don't need indexes at all
            --           note that since we don't have references here in Elm, we just won't have a Monsters collection,
            --           and we will just iterate over the tiles when drawing and updating monsters
            --      something else I haven't thought of?
            if Monster.isDead m then
                acc

            else
                Monster.update acc
        )
        state
        state.monsters
    


update msg model =
    case model of
        Ok state ->
            case msg of
                Tick ->
                    ( model
                    , draw state
                    )

                Input input ->
                    ( Ok
                        (case input of
                            Up ->
                                movePlayer state DX0 DYm1

                            Down ->
                                movePlayer state DX0 DY1

                            Left ->
                                movePlayer state DXm1 DY0

                            Right ->
                                movePlayer state DX1 DY0

                            Other ->
                                state
                        )
                    , Cmd.none
                    )

        Err _ ->
            ( model
            , Cmd.none
            )


subscriptions _ =
    Sub.batch
        [ Browser.Events.onAnimationFrame (\_ -> Tick)
        , JD.field "key" JD.string
            |> JD.map toInput
            |> Browser.Events.onKeyDown
        ]


type Msg
    = Tick
    | Input Input


type Input
    = Other
    | Up
    | Down
    | Left
    | Right


toInput : String -> Msg
toInput s =
    Input
        (case s of
            "ArrowUp" ->
                Up

            "w" ->
                Up

            "ArrowDown" ->
                Down

            "s" ->
                Down

            "ArrowLeft" ->
                Left

            "a" ->
                Left

            "ArrowRight" ->
                Right

            "d" ->
                Right

            _ ->
                Other
        )


view model =
    case model of
        Ok _ ->
            Html.text ""

        Err e ->
            Html.text e
