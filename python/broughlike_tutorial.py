
#
#  This is the entrypoint file
#

import game

import pygame

from dataclasses import dataclass
import os

pygame.init()
pygame.font.init()
screen: pygame.Surface = pygame.display.set_mode((1280, 720), pygame.RESIZABLE)
clock = pygame.time.Clock()

font = pygame.font.SysFont(pygame.font.get_fonts()[0], 30)

asset_path = os.path.join(os.path.dirname(__file__), "assets")
spritesheet = pygame.image.load(os.path.join(asset_path, "spritesheet.png"))
spritesheet = pygame.Surface.convert_alpha(spritesheet)

# Set the window title
pygame.display.set_caption("AWESOME BROUGHLIKE")

running = True
dt = 0

SPRITE_SIZE = 16

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

PLAYER_INDEX = 0

@dataclass
class Sizes:
    play_area: pygame.Rect
    tile: float

def get_sizes():
    w = screen.get_width()
    h = screen.get_height()

    tile = min(
        w/(game.NUM_TILES+game.UI_WIDTH),
        h/game.NUM_TILES,
    )
    play_area_w, play_area_h = tile*(game.NUM_TILES+game.UI_WIDTH), tile*game.NUM_TILES
    play_area_x, play_area_y = (w-play_area_w)/2, (h-play_area_h)/2

    return Sizes(
        pygame.Rect(play_area_x, play_area_y, play_area_w, play_area_h),
        tile,
    )

sizes = get_sizes()

player_x, player_y = 0, 0

while running:
    # poll for events
    # pygame.QUIT event means the user clicked X to close your window
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.KEYDOWN:
            #
            # Update
            #


            if event.key == pygame.K_w or event.key == pygame.K_UP:
                player_y -= 1
            if event.key == pygame.K_s or event.key == pygame.K_DOWN:
                player_y += 1
            if event.key == pygame.K_a or event.key == pygame.K_LEFT:
                player_x -= 1
            if event.key == pygame.K_d or event.key == pygame.K_RIGHT:
                player_x += 1

    #
    # Render
    #

    screen.fill("indigo")

    sizes = get_sizes()

    pygame.draw.rect(screen, "white", sizes.play_area.inflate(2, 2), 1)

    screen.blit(
        pygame.transform.scale(unscaled_sprites[PLAYER_INDEX], (sizes.tile, sizes.tile)),
        pygame.Rect(
            sizes.play_area.x + player_x * sizes.tile,
            sizes.play_area.y + player_y * sizes.tile,
            sizes.tile,
            sizes.tile
        ),
    )

    pygame.display.flip()

    # limits FPS to 60
    # dt is delta time in seconds since last frame
    dt = clock.tick(60) / 1000

pygame.quit()
