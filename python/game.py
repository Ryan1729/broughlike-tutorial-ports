
import pygame

import random
from dataclasses import dataclass
import os

from game_types import SpriteIndex, TileSprite, Level
from tile import Tiles, Tile
from map import generate_level, random_passable_tile
from monster import Player, Monster

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

PLAYER_INDEX: SpriteIndex = 0

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
