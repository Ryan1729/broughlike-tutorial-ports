
import pygame

from dataclasses import dataclass
from functools import cmp_to_key
import os
import random

from game_types import SpriteIndex, TileSprite, Level, W, H, dist
from tile import Tiles, Tile, try_move, get_adjacent_passable_neighbors
from map import generate_level, random_passable_tile
from monster import Player, Monster, Bird, Snake, Tank, Eater, Jester

Screen = pygame.Surface
Sprite = pygame.Surface


SPRITE_SIZE = 16

asset_path = os.path.join(os.path.dirname(__file__), "assets")
spritesheet = pygame.image.load(os.path.join(asset_path, "spritesheet.png"))
spritesheet = pygame.Surface.convert_alpha(spritesheet)

unscaled_sprites: list[pygame.Surface] = []

for i in range(17):
    unscaled_sprites.append(
        spritesheet.subsurface(
            pygame.Rect(
                i * SPRITE_SIZE,
                0,
                SPRITE_SIZE,
                SPRITE_SIZE
            )
        )
    )

@dataclass
class Sizes:
    play_area: pygame.Rect
    tile: int

@dataclass
class Platform:
    screen: Screen
    sizes: Sizes

PixelX = int
PixelY = int

def draw_sprite(platform: Platform, sprite_index: SpriteIndex, x: PixelX, y: PixelY):
    platform.screen.blit(
        pygame.transform.scale(unscaled_sprites[sprite_index], (platform.sizes.tile + 0.5, platform.sizes.tile + 0.5)),
        pygame.Rect(
            platform.sizes.play_area.x + x,
            platform.sizes.play_area.y + y,
            platform.sizes.tile,
            platform.sizes.tile
        ),
    )

def draw_tile(platform: Platform, tile: TileSprite):
    draw_sprite(platform, tile.sprite_index, tile.x * platform.sizes.tile, tile.y * platform.sizes.tile)

def draw_hp(platform: Platform, monster: Monster):
    for i in range(monster.hp):
        draw_sprite(
            platform,
            9,
            monster.x*platform.sizes.tile + ((i%3)*platform.sizes.tile*5)//16,
            monster.y*platform.sizes.tile - ((i//3)*platform.sizes.tile*5)//16
        );

@dataclass
class State:
    player: Player
    rng: random.Random
    tiles: Tiles
    level: Level
    monsters: list[Monster]

def new_state(seed: int) -> State:
    @dataclass
    class MiniState:
        rng: random.Random
        tiles: Tiles
        level: Level
        monsters: list[Monster]

    state = MiniState(random.Random(seed), [], 1, [])

    generate_level(state);

    starting_tile: Tile = random_passable_tile(state);

    return State(
        Player(starting_tile),
        state.rng,
        state.tiles,
        state.level,
        state.monsters,
    )


def player_move(state: State, dx: W, dy: H):
    if try_move(state.tiles, state.player, dx, dy):
        tick(state);

def basic_do_stuff(state: State, monster: Monster):
    neighbors = get_adjacent_passable_neighbors(state.rng, state.tiles, monster);
    neighbors = list(filter(lambda t: (not t.monster) or (t.monster.is_player), neighbors));
    if len(neighbors):
       neighbors.sort(key=cmp_to_key(lambda a, b: dist(a, state.player) - dist(b, state.player)));
       new_tile = neighbors[0];
       try_move(state.tiles, monster, new_tile.x - monster.x, new_tile.y - monster.y)

def monster_do_stuff(state: State, monster: Monster):
    if monster.is_stunned:
        monster.is_stunned = False;
        return;

    monster.attacked_this_turn = False;
    # Matching here seems better than forcing monster.py to know about State
    match monster:
        case Bird():
            basic_do_stuff(state, monster)
        case Snake():
            basic_do_stuff(state, monster)
            if not monster.attacked_this_turn:
                basic_do_stuff(state, monster)
        case Tank():
            basic_do_stuff(state, monster)
        case Eater():
            pass # TODO
        case Jester():
            pass # TODO
        case _:
            print("unhandled do stuff case: ", monster)

def tick(state: State):
    # In reverse so we can safely delete monsters
    for i in range(len(state.monsters) - 1, -1, -1):
        if not state.monsters[i].is_dead:
            match state.monsters[i]:
                case Bird():
                    pass
                case Snake():
                    pass
                case Tank():
                    started_stunned = state.monsters[i].is_stunned;
                    monster_do_stuff(state, state.monsters[i]);

                    if not started_stunned:
                        state.monsters[i].is_stunned = True;

                    continue
                case Eater():
                    pass
                case Jester():
                    pass
                case _:
                    print("unhandled tick case: ", state.monsters[i])


            # This seems nicer than maving to have monster.py know about State
            monster_do_stuff(state, state.monsters[i]);
        else:
            state.monsters.pop(i);
