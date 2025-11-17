from game_types import NUM_TILES, SFX, SpellName, W, H
from game import Platform, RunningState, start_level, tick, PlayerMoveResult
from map import random_passable_tile
from monster import HP
from tile import Tile, MoveResult, direct_move, get_tile, hit, get_adjacent_passable_neighbors, get_adjacent_neighbors, get_neighbor, replace, Floor, in_bounds

from typing import Callable

def cast(platform: Platform, state: RunningState, index: int) -> PlayerMoveResult:
    died = False
    new_tile: Tile | None = None

    if index >= 0 and index < len(state.player.spells):
        spell_name = state.player.spells[index];
        state.player.spells[index] = None
        if spell_name:
            old_x = state.player.x
            old_y = state.player.y

            spells[spell_name](platform, state);
            platform.play_sound(SFX.Spell);
            died = tick(platform, state);

            new_x = state.player.x
            new_y = state.player.y

            if new_x != old_x or new_y != old_y:
                new_tile = get_tile(state.tiles, new_x, new_y)


    return PlayerMoveResult(
        died,
        MoveResult(new_tile, 0, None),
    )

Spell = Callable[[Platform, RunningState], None]

def woop(platform: Platform, state: RunningState):
    direct_move(state.tiles, state.player, random_passable_tile(state))

def quake(platform: Platform, state: RunningState):
    for i in range(NUM_TILES):
        for j in range(NUM_TILES):
            tile = get_tile(state.tiles, i, j);
            if tile.monster:
                numWalls = 4 - len(get_adjacent_passable_neighbors(state.rng, state.tiles, tile));
                hit(state.tiles, tile.monster, numWalls*2);

    state.shake_amount = 20;

def maelstrom(platform: Platform, state: RunningState):
    for i in range(len(state.monsters)):
        direct_move(state.tiles, state.monsters[i], random_passable_tile(state))
        state.monsters[i].teleport_counter = 2;

def mulligan(platform: Platform, state: RunningState):
    state.__dict__.update(
        start_level(state.rng, state.level, 1, state.score, state.num_spells, state.player.spells).state.__dict__
    )

def aura(platform: Platform, state: RunningState):
    for tile in get_adjacent_neighbors(state.rng, state.tiles, state.player):
        tile.set_effect(13)
        if tile.monster:
            tile.monster.heal(1);

    get_tile(state.tiles, state.player.x, state.player.y).set_effect(13)
    state.player.heal(1);

def dash(platform: Platform, state: RunningState):
    new_tile = get_tile(state.tiles, state.player.x, state.player.y);
    while True:
        test_tile: Tile = get_neighbor(state.tiles, new_tile, state.player.last_dx, state.player.last_dy)
        if test_tile.passable and not test_tile.monster:
            new_tile = test_tile;
        else:
            break;
    
    if state.player.x != new_tile.x or state.player.y != new_tile.y:
        direct_move(state.tiles, state.player, new_tile)
        
        for tile in get_adjacent_neighbors(state.rng, state.tiles, new_tile):
            if tile.monster:
                tile.set_effect(14);
                tile.monster.is_stunned = True;
                hit(state.tiles, tile.monster, 1);


def dig(platform: Platform, state: RunningState):
    for i in range(NUM_TILES):
        for j in range(NUM_TILES):
            tile = get_tile(state.tiles, i, j);

            if not tile.passable:
                replace(state.tiles, tile, lambda x, y: Floor(x, y));

    get_tile(state.tiles, state.player.x, state.player.y).set_effect(13)
    state.player.heal(2);

def kingmaker(platform: Platform, state: RunningState):
    for monster in state.monsters:
        monster.heal(1);
        get_tile(state.tiles, monster.x, monster.y).has_treasure = True;

def alchemy(platform: Platform, state: RunningState):
    for tile in get_adjacent_neighbors(state.rng, state.tiles, get_tile(state.tiles, state.player.x, state.player.y)):
        if not tile.passable and in_bounds(tile.x, tile.y):
            replace(state.tiles, tile, lambda x, y: Floor(x, y));
            get_tile(state.tiles, tile.x, tile.y).has_treasure = True;

def power(platform: Platform, state: RunningState):
    state.player.bonus_attack = 5;

def bubble(platform: Platform, state: RunningState):
    for i in range(len(state.player.spells) - 1, -1, -1):
        if not state.player.spells[i]:
            state.player.spells[i] = state.player.spells[i-1];

def bravery(platform: Platform, state: RunningState):
    state.player.shield = 2;
    for monster in state.monsters:
        monster.is_stunned = True;

def bolt(platform: Platform, state: RunningState):
    bolt_travel(state, state.player.last_dx, state.player.last_dy, 15 + abs(state.player.last_dy), 4);

spells: dict[SpellName, Spell] = {
    SpellName.WOOP: woop,
    SpellName.QUAKE: quake,
    SpellName.MAELSTROM: maelstrom,
    SpellName.MULLIGAN: mulligan,
    SpellName.AURA: aura,
    SpellName.DASH: dash,
    SpellName.DIG: dig,
    SpellName.KINGMAKER: kingmaker,
    SpellName.ALCHEMY: alchemy,
    SpellName.POWER: power,
    SpellName.BUBBLE: bubble,
    SpellName.BRAVERY: bravery,
    SpellName.BOLT: bolt,
}

def bolt_travel(state: RunningState, dx: W, dy: H, effect: int, damage: HP):
    new_tile = get_tile(state.tiles, state.player.x, state.player.y);
    while True:
        test_tile = get_neighbor(state.tiles, new_tile, dx, dy);
        if test_tile.passable:
            new_tile = test_tile;
            if new_tile.monster:
                hit(state.tiles, new_tile.monster, damage);
            new_tile.set_effect(effect);
        else:
            break;
