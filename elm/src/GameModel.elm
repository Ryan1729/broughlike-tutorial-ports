module GameModel exposing (GameModel(..), State)

import Game exposing (LevelNum, Positioned, Score, Shake)
import Random exposing (Seed)
import Tiles exposing (Tiles)


type GameModel
    = Error String
    | Title (Maybe State) Seed
    | Running State
    | Dead State


type alias State =
    { player : Positioned {}
    , seed : Seed
    , tiles : Tiles
    , level : LevelNum
    , spawnCounter : Int
    , spawnRate : Int
    , score : Score
    , shake : Shake
    }
