
from dataclasses import dataclass
from typing import Callable

from game_types import SpriteIndex, X, Y, W, H, NUM_TILES, TileSprite
from util import shuffle, RNG
from monster import Monster, HP


@dataclass
class Tile:
    x: X
    y: Y
    sprite_index: SpriteIndex
    passable: bool
    has_treasure: bool
    monster: Monster|None

class Floor(Tile):
    def __init__(self, x: X, y: Y):
        super().__init__(x, y, 2, True, False, None)

class Wall(Tile):
    def __init__(self, x: X, y: Y):
        super().__init__(x, y, 3, False, False, None)

class Exit(Tile):
    def __init__(self, x: X, y: Y):
        super().__init__(x, y, 11, True, False, None)

Tiles = list[list[Tile]]

def get_neighbor(tiles: Tiles, tile: TileSprite, dx: W, dy: H) -> Tile:
    return get_tile(tiles, tile.x + dx, tile.y + dy)

def get_adjacent_neighbors(rng: RNG, tiles: Tiles, tile: TileSprite) -> list[Tile]:
    return shuffle(
        rng,
        [
            get_neighbor(tiles, tile, 0, -1),
            get_neighbor(tiles, tile, 0, 1),
            get_neighbor(tiles, tile, -1, 0),
            get_neighbor(tiles, tile, 1, 0)
        ]
    );

def get_adjacent_passable_neighbors(rng: RNG, tiles: Tiles, tile: TileSprite) -> list[Tile]:
    # We don't check for t.monster here because we use this function for monster movement and we want them to move into the player
    return list(filter(lambda t: t.passable, get_adjacent_neighbors(rng, tiles, tile)))

def get_connected_tiles(rng: RNG, tiles: Tiles, tile: Tile) -> list[Tile]:
    connected_tiles: list[Tile] = [tile];
    frontier: list[Tile] = [tile];
    while len(frontier):
        neighbors: list[Tile] = list(
            filter(
                lambda t: t not in connected_tiles,
                get_adjacent_passable_neighbors(rng, tiles, frontier.pop()),
            )
        );
        connected_tiles.extend(neighbors);
        frontier.extend(neighbors);

    return connected_tiles;


def in_bounds(x: X, y: Y):
    return x > 0 and y > 0 and x < NUM_TILES-1 and y < NUM_TILES - 1

def get_tile(tiles: Tiles, x: X, y: Y) -> Tile:
    if in_bounds(x, y):
        return tiles[x][y]
    else:
        return Wall(x,y)

@dataclass
class MoveResult:
    did_move: bool
    new_tile: Tile

def try_move(tiles: Tiles, monster: Monster, dx: W, dy: H) -> MoveResult:
    did_move = False
    new_tile = get_neighbor(tiles, monster, dx, dy)

    if new_tile.passable:
        if not new_tile.monster:
            new_tile.monster = monster;

            old_tile = get_tile(tiles, monster.x, monster.y)
            if dx != 0 or dy != 0:
                old_tile.monster = None

            monster.x = new_tile.x
            monster.y = new_tile.y


        else:
             if monster.is_player != new_tile.monster.is_player:
                 monster.attacked_this_turn = True;
                 new_tile.monster.is_stunned = True;
                 hit(tiles, new_tile.monster, 1)

        did_move = True

    return MoveResult(did_move, new_tile)

def hit(tiles: Tiles, monster: Monster, damage: HP):
    monster.hp -= damage;
    if monster.hp <= 0:
        die(tiles, monster);

def die(tiles: Tiles, monster: Monster):
    monster.is_dead = True;
    tiles[monster.x][monster.y].monster = None;
    monster.sprite_index = 1;

def replace(tiles: Tiles, tile: TileSprite, constructor: Callable[[X, Y], Tile]):
    tiles[tile.x][tile.y] = constructor(tile.x, tile.y);
