# Example file showing a circle moving on screen
import pygame

pygame.init()
pygame.font.init()
screen = pygame.display.set_mode((1280, 720))
clock = pygame.time.Clock()

font = pygame.font.SysFont(pygame.font.get_fonts()[0], 30)

# Set the window title
pygame.display.set_caption("AWESOME BROUGHLIKE")

running = True
dt = 0

def get_play_area():
    w = screen.get_width()
    h = screen.get_height()

    short_side = min(w, h)

    return pygame.Rect((w - short_side) / 2, (h - short_side) / 2, short_side, short_side)

play_area = get_play_area()

player = pygame.Rect(play_area.x, play_area.y, 20, 20)

while running:
    # poll for events
    # pygame.QUIT event means the user clicked X to close your window
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    #
    # Render
    #

    screen.fill("indigo")

    play_area = get_play_area()

    pygame.draw.rect(screen, "white", play_area.inflate(2, 2), 1)

    pygame.draw.rect(screen, "black", player)

    #
    # Update
    #
    keys = pygame.key.get_pressed()
    if keys[pygame.K_w] or keys[pygame.K_UP]:
        player.y -= 1
    if keys[pygame.K_s] or keys[pygame.K_DOWN]:
        player.y += 1
    if keys[pygame.K_a] or keys[pygame.K_LEFT]:
        player.x -= 1
    if keys[pygame.K_d] or keys[pygame.K_RIGHT]:
        player.x += 1

    pygame.display.flip()

    # limits FPS to 60
    # dt is delta time in seconds since last frame
    dt = clock.tick(60) / 1000

pygame.quit()
