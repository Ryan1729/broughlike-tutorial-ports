
from game_types import X, Y, NUM_TILES
from tile import Tile, Wall, Floor
from util import random_range, try_to, RNG

from typing import Protocol

Tiles = list[list[Tile]]

class StateFields(Protocol):
    tiles: Tiles
    rng: RNG

def generate_level(state: StateFields):
    generate_tiles(state)

def generate_tiles(state: StateFields):
    state.tiles = []
    for i in range(NUM_TILES):
        state.tiles.append([]);
        for j in range(NUM_TILES):
            if state.rng.random() < 0.3 or not in_bounds(i, j):
                state.tiles[i].append(Wall(i,j))
            else:
                state.tiles[i].append(Floor(i,j))

def in_bounds(x: X, y: Y):
    return x > 0 and y > 0 and x < NUM_TILES-1 and y < NUM_TILES - 1

def get_tile(state: StateFields, x: X, y: Y):
    if in_bounds(x, y):
        return state.tiles[x][y]
    else:
        return Wall(x,y)

def random_passable_tile(state: StateFields) -> Tile:
    tile = None
    def cb():
        nonlocal tile
        x: X = random_range(state.rng, 0, NUM_TILES-1);
        y: Y = random_range(state.rng, 0, NUM_TILES-1);
        tile = get_tile(state, x, y);
        return tile.passable and not tile.monster;

    try_to('get random passable tile', cb);

    assert tile is not None

    return tile;

