from game_types import NUM_TILES, SFX, SpellName
from game import Platform, RunningState, tick, PlayerMoveResult
from map import random_passable_tile
from tile import Tile, MoveResult, direct_move, get_tile, hit, get_adjacent_passable_neighbors

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

spells: dict[SpellName, Spell] = {
    SpellName.WOOP: woop,
    SpellName.QUAKE: quake,
    SpellName.MAELSTROM: maelstrom,
}
