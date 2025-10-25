
#
#  This is the entrypoint file
#

import pygame

pygame.init()
pygame.font.init()
screen: pygame.Surface = pygame.display.set_mode((1280, 720), pygame.RESIZABLE)

from game_types import NUM_TILES, UI_WIDTH
import game
from tile import get_tile

import time

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
        int(tile),
    )

platform = game.Platform(screen, get_sizes())

initial_seed = int(time.time())

print(f"seed = {initial_seed}")

state: game.State = game.title_state(initial_seed)

def render_running(state: game.RunningState):
    for i in range(NUM_TILES):
        for j in range(NUM_TILES):
            game.draw_tile(platform, get_tile(state.tiles, i, j))

    for i in range(len(state.monsters)):
        game.draw_monster(platform, state.monsters[i]);

    game.draw_monster(platform, state.player)

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

            if isinstance(state, game.Title):
                state = game.running_state(state)
            elif isinstance(state, game.Dead):
                state = game.to_title_state(state.state.rng)
            elif isinstance(state, game.Running):
                move_result = None

                if event.key == pygame.K_w or event.key == pygame.K_UP:
                    move_result = game.player_move(state.state, 0, -1)
                if event.key == pygame.K_s or event.key == pygame.K_DOWN:
                    move_result = game.player_move(state.state, 0, 1)
                if event.key == pygame.K_a or event.key == pygame.K_LEFT:
                    move_result = game.player_move(state.state, -1, 0)
                if event.key == pygame.K_d or event.key == pygame.K_RIGHT:
                    move_result = game.player_move(state.state, 1, 0)

                if move_result:
                    if move_result.died:
                        state = game.dead_state(state)
                    elif move_result.move_result.did_move:
                        new_state = game.step_on(state.state, state.state.player, move_result.move_result.new_tile)
                        if new_state:
                            state = new_state
    #
    # Render
    #

    screen.fill("indigo")

    platform.sizes = get_sizes()

    pygame.draw.rect(screen, "white", platform.sizes.play_area.inflate(2, 2), 1)

    if isinstance(state, game.Running):
        render_running(state.state)

    if isinstance(state, game.Dead):
        render_running(state.state)
        s = pygame.Surface((platform.sizes.play_area.w, platform.sizes.play_area.h))
        s.set_alpha(192)
        s.fill((0,0,0))
        screen.blit(s, (platform.sizes.play_area.x,platform.sizes.play_area.y))

    pygame.display.flip()

    # limits FPS to 60
    # dt is delta time in seconds since last frame
    dt = clock.tick(60) / 1000

pygame.quit()
