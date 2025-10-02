
import pygame

from dataclasses import dataclass
import os

NUM_TILES = 9
UI_WIDTH = 4

X = int
Y = int

Screen = pygame.Surface
Sprite = pygame.Surface
SpriteIndex = int

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
        pygame.transform.scale(unscaled_sprites[sprite_index], (platform.sizes.tile, platform.sizes.tile)),
        pygame.Rect(
            platform.sizes.play_area.x + x * platform.sizes.tile,
            platform.sizes.play_area.y + y * platform.sizes.tile,
            platform.sizes.tile,
            platform.sizes.tile
        ),
    )
