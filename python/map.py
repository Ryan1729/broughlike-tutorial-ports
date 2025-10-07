
from game_types import X, Y, NUM_TILES
from tile import Tile, Wall, Floor, Tiles, in_bounds, get_tile, get_connected_tiles
from util import random_range, try_to, RNG

from typing import Protocol

class StateFields(Protocol):
    rng: RNG
    tiles: Tiles

def generate_level(state: StateFields):
    def cb() -> bool:
        return (
            generate_tiles(state)
                == len(
                    get_connected_tiles(
                        state.rng,
                        state.tiles,
                        random_passable_tile(state)
                    )
                )
        );

    try_to('generate map', cb);

def generate_tiles(state: StateFields) -> int:
    passable_tiles = 0
    state.tiles = []
    for i in range(NUM_TILES):
        state.tiles.append([]);
        for j in range(NUM_TILES):
            if state.rng.random() < 0.3 or not in_bounds(i, j):
                state.tiles[i].append(Wall(i,j))
            else:
                state.tiles[i].append(Floor(i,j))
                passable_tiles += 1
    return passable_tiles

def random_passable_tile(state: StateFields) -> Tile:
    tile = None
    def cb() -> bool:
        nonlocal tile
        x: X = random_range(state.rng, 0, NUM_TILES-1);
        y: Y = random_range(state.rng, 0, NUM_TILES-1);
        tile = get_tile(state.tiles, x, y);
        return tile.passable and not tile.monster;

    try_to('get random passable tile', cb);

    assert tile is not None

    return tile;

