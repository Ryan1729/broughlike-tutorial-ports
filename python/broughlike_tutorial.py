# Example file showing a circle moving on screen
import pygame

pygame.init()
pygame.font.init()
screen = pygame.display.set_mode((1280, 720))
clock = pygame.time.Clock()

font = pygame.font.SysFont(pygame.font.get_fonts()[0], 30)

running = True
dt = 0

player = pygame.Rect(0, 0, 20, 20)

while running:
    # poll for events
    # pygame.QUIT event means the user clicked X to close your window
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    #
    # Render
    #
    screen.fill("white")

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
