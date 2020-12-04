from randomness import nil

from game import no_ex
from map import nil


type
  State* = object
    xy*: game.TileXY
    tiles*: map.Tiles
    rng*: randomness.Rand
