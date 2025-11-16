
#
#  This is the entrypoint file
#

import pygame
import json

pygame.init()
pygame.font.init()
screen: pygame.Surface = pygame.display.set_mode((1280, 720), pygame.RESIZABLE)

from game_types import NUM_TILES, UI_WIDTH, SFX
import game
import spell
from tile import get_tile

import os
import math
import time
import random

clock = pygame.time.Clock()


font_name = pygame.font.get_fonts()[0]

font_cache: dict[int, pygame.font.Font] = {}

def get_font(size: int) -> pygame.font.Font:
    if font := font_cache.get(size):
        return font

    return pygame.font.SysFont(font_name, size)

# Set the window title
pygame.display.set_caption("AWESOME BROUGHLIKE")

running = True
dt = 0

SCORES_FILENAME = "scores.json"

def get_scores() -> list[game.Score]:
    validated_scores: list[game.Score] = []
    try:
        with open(SCORES_FILENAME, "r", encoding="utf-8") as f:
            # If the type is different than this, given it's JSON, the
            # other possibilties  will cause excpetions, which we'll
            # catch anyway.
            unvalidated_scores: list[dict[str, int | bool]] = json.load(f)

            for unvalidated_score in unvalidated_scores:
                score = unvalidated_score.get("score", None)
                run = unvalidated_score.get("run", None)
                total_score = unvalidated_score.get("total_score", None)
                active = unvalidated_score.get("active", None)

                if (
                    type(score) == int
                    and type(run) == int
                    and type(total_score) == int
                    and type(active) == bool
                ):
                    validated_scores.append({
                        "score": score,
                        "run": run,
                        "total_score": total_score,
                        "active": active,
                    })
                else:
                    print("Invalid score:", unvalidated_score)
    except FileNotFoundError as e:
        # Expected to happen the first time the game starts
        pass
    except Exception as e:
        print(type(e), e)
    finally:
        return validated_scores

def save_scores(scores: list[game.Score]):
    try:
        with open(SCORES_FILENAME, "w", encoding="utf-8") as f:
            f.write(json.dumps(scores))
    except FileNotFoundError as e:
        # Expected to happen the first time the game starts
        pass
    except Exception as e:
        print(type(e), e)

def add_score(score: int, won: bool):
    scores = get_scores();

    score_object: game.Score = {"score": score, "run": 1, "total_score": score, "active": won};

    if scores:
        last_score = scores.pop();
        if last_score.get("active", False):
            # If has active true, then it probably has the right structure
            score_object["run"] = last_score["run"] + 1;
            score_object["total_score"] += last_score["total_score"]
        else:
            scores.append(last_score);

    scores.append(score_object);

    save_scores(scores)


def get_sizes() -> game.Sizes:
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

sounds_path = os.path.join(os.path.dirname(__file__), "assets", "sounds")

sounds: dict[SFX | None, pygame.mixer.Sound] = {
    SFX.Hit1: pygame.mixer.Sound(os.path.join(sounds_path, "hit1.wav")),
    SFX.Hit2: pygame.mixer.Sound(os.path.join(sounds_path, "hit2.wav")),
    SFX.Treasure: pygame.mixer.Sound(os.path.join(sounds_path, "treasure.wav")),
    SFX.NewLevel: pygame.mixer.Sound(os.path.join(sounds_path, "newLevel.wav")),
    SFX.Spell: pygame.mixer.Sound(os.path.join(sounds_path, "spell.wav")),
};

def play_sound(sfx: SFX | None):
    sound: pygame.mixer.Sound | None = sounds.get(sfx)
    if not sound: return

    sound.play()

platform = game.Platform(
    screen,
    get_font,
    get_scores,
    add_score,
    play_sound,
    get_sizes(),
    0,
    0,
)

initial_seed = int(time.time())

print(f"seed = {initial_seed}")

state: game.State = game.title_state(initial_seed)

violet = pygame.color.Color("violet")
aqua = pygame.color.Color("aqua")

def render_running(state: game.RunningState):
    screenshake(platform, state)

    for i in range(NUM_TILES):
        for j in range(NUM_TILES):
            game.draw_tile(platform, get_tile(state.tiles, i, j))

    for i in range(len(state.monsters)):
        game.draw_monster(platform, state.monsters[i]);

    game.draw_monster(platform, state.player)

    game.draw_text(platform, f"Level: {state.level}", 30, False, 40, violet);
    game.draw_text(platform, f"Score: {state.score}", 30, False, 90, violet);

    for i in range(len(state.player.spells)):
        spell_name = state.player.spells[i]

        spell_text: str = f"{i+1}) {spell_name.name if spell_name else ''}";
        game.draw_text(platform, spell_text, 20, False, 150+i*40, aqua);


def screenshake(platform: game.Platform, state: game.RunningState):
    if state.shake_amount:
        state.shake_amount -= 1;

    if state.shake_amount <= 0:
        platform.shake_w = 0
        platform.shake_h = 0
        return

    # State bugs are more reproducible if we don't use the state's rng for this.
    shake_angle: float = random.random()*math.tau;

    platform.shake_w = round(math.cos(shake_angle)*state.shake_amount);
    platform.shake_h = round(math.sin(shake_angle)*state.shake_amount);

#
#  Dev hack we should remove later
#
import sys
override_spells: list[spell.SpellName | None] | None = None
if sys.argv[-1] == "newest_spell":
    spellbook: list[spell.SpellName | None] | None = list(spell.spells.keys())
    override_spells = spellbook[-1:]


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
                state = game.running_state(state, override_spells)
            elif isinstance(state, game.Dead):
                state = game.to_title_state(state.state.rng)
            elif isinstance(state, game.Running):
                move_result = None

                if event.key == pygame.K_w or event.key == pygame.K_UP:
                    move_result = game.player_move(platform, state.state, 0, -1)
                if event.key == pygame.K_s or event.key == pygame.K_DOWN:
                    move_result = game.player_move(platform, state.state, 0, 1)
                if event.key == pygame.K_a or event.key == pygame.K_LEFT:
                    move_result = game.player_move(platform, state.state, -1, 0)
                if event.key == pygame.K_d or event.key == pygame.K_RIGHT:
                    move_result = game.player_move(platform, state.state, 1, 0)

                if event.key >= pygame.K_1 and event.key <= pygame.K_9:
                    move_result = spell.cast(platform, state.state, event.key - pygame.K_1)

                if move_result:
                    if move_result.died:
                        state = game.dead_state(state)
                    elif move_result.move_result.new_tile:
                        new_state = game.step_on(
                            platform,
                            state.state,
                            state.state.player,
                            move_result.move_result.new_tile
                        )
                        if new_state:
                            state = new_state
    #
    # Render
    #

    screen.fill("indigo")

    platform.sizes = get_sizes()

    pygame.draw.rect(screen, "white", platform.sizes.play_area.inflate(2, 2), 1)

    if isinstance(state, game.Title):
        white = pygame.color.Color("white")
        game.draw_text(platform, "BROUGHPYKE", 40, True, platform.sizes.play_area.height/2 - 210, white);
        game.draw_text(platform, "TUTORIAL", 70, True, platform.sizes.play_area.height/2 - 150, white);

        game.draw_scores(platform);

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
