
import pygame

import random
from dataclasses import dataclass
import os

from game_types import SpriteIndex, X, Y
from tile import Tile
from map import Tiles, generate_level

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
    tile: float

@dataclass
class Platform:
    screen: Screen
    sizes: Sizes

def draw_sprite(platform: Platform, sprite_index: SpriteIndex, x: X, y: Y):
    platform.screen.blit(
        pygame.transform.scale(unscaled_sprites[sprite_index], (platform.sizes.tile + 0.5, platform.sizes.tile + 0.5)),
        pygame.Rect(
            platform.sizes.play_area.x + x * platform.sizes.tile,
            platform.sizes.play_area.y + y * platform.sizes.tile,
            platform.sizes.tile,
            platform.sizes.tile
        ),
    )

def draw_tile(platform: Platform, tile: Tile):
    draw_sprite(platform, tile.sprite_index, tile.x, tile.y)

@dataclass
class Player:
    x: X
    y: Y

@dataclass
class State:
    player: Player
    tiles: Tiles
    rng: random.Random
    
def new_state(seed: int) -> State:
    player = Player(0, 0)

    rng = random.Random(seed)

    state = State(
        player,
        [],
        rng
    )

    generate_level(state)
    
    return state
