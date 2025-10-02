
#
#  This is the entrypoint file
#

import pygame

pygame.init()
pygame.font.init()
screen: pygame.Surface = pygame.display.set_mode((1280, 720), pygame.RESIZABLE)

import game

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
        w/(game.NUM_TILES+game.UI_WIDTH),
        h/game.NUM_TILES,
    )
    play_area_w, play_area_h = tile*(game.NUM_TILES+game.UI_WIDTH), tile*game.NUM_TILES
    play_area_x, play_area_y = (w-play_area_w)/2, (h-play_area_h)/2

    return game.Sizes(
        pygame.Rect(play_area_x, play_area_y, play_area_w, play_area_h),
        tile,
    )

platform = game.Platform(screen, get_sizes())

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

    platform.sizes = get_sizes()

    pygame.draw.rect(screen, "white", platform.sizes.play_area.inflate(2, 2), 1)

    game.draw_sprite(platform, game.PLAYER_INDEX, player_x, player_y)

    pygame.display.flip()

    # limits FPS to 60
    # dt is delta time in seconds since last frame
    dt = clock.tick(60) / 1000

pygame.quit()
