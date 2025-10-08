
#
#  This is the entrypoint file
#

import pygame

pygame.init()
pygame.font.init()
screen: pygame.Surface = pygame.display.set_mode((1280, 720), pygame.RESIZABLE)

from game_types import NUM_TILES, UI_WIDTH
import game
import time
from tile import get_tile, try_move

clock = pygame.time.Clock()

font = pygame.font.SysFont(pygame.font.get_fonts()[0], 30)

# Set the window title
pygame.display.set_caption("AWESOME BROUGHLIKE")

running = True
dt = 0

def get_sizes():
    w = screen.get_width()
    h = screen.get_height()

    tile = min(
        w/(NUM_TILES+UI_WIDTH),
        h/NUM_TILES,
    )
    play_area_w, play_area_h = tile*(NUM_TILES+UI_WIDTH), tile*NUM_TILES
    play_area_x, play_area_y = (w-play_area_w)/2, (h-play_area_h)/2

    return game.Sizes(
        pygame.Rect(play_area_x, play_area_y, play_area_w, play_area_h),
        tile,
    )

platform = game.Platform(screen, get_sizes())

initial_seed = int(time.time())

print(f"seed = {initial_seed}")

state: game.State = game.new_state(initial_seed)

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
                try_move(state.tiles, state.player, 0, -1)
            if event.key == pygame.K_s or event.key == pygame.K_DOWN:
                try_move(state.tiles, state.player, 0, 1)
            if event.key == pygame.K_a or event.key == pygame.K_LEFT:
                try_move(state.tiles, state.player, -1, 0)
            if event.key == pygame.K_d or event.key == pygame.K_RIGHT:
                try_move(state.tiles, state.player, 1, 0)

    #
    # Render
    #

    screen.fill("indigo")

    platform.sizes = get_sizes()

    pygame.draw.rect(screen, "white", platform.sizes.play_area.inflate(2, 2), 1)

    for i in range(NUM_TILES):
        for j in range(NUM_TILES):
            game.draw_tile(platform, get_tile(state.tiles, i, j))

    for i in range(len(state.monsters)):
        game.draw_tile(platform, state.monsters[i]);

    game.draw_tile(platform, state.player)

    pygame.display.flip()

    # limits FPS to 60
    # dt is delta time in seconds since last frame
    dt = clock.tick(60) / 1000

pygame.quit()
