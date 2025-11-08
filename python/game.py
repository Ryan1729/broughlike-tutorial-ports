
import pygame

from dataclasses import dataclass
from functools import cmp_to_key
from typing import Callable, TypedDict
import os
import random

from game_types import SpriteIndex, TileSprite, Level, W, H, dist, UI_WIDTH
from tile import Tiles, Tile, try_move, get_adjacent_passable_neighbors, get_adjacent_neighbors, in_bounds, replace, Floor, Wall, Exit, MoveResult
from map import generate_level, random_passable_tile, spawn_monster
from monster import Player, Monster, Bird, Snake, Tank, Eater, Jester, HP, MAX_HP

NUM_LEVELS = 6

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

class Score(TypedDict):
    score: int
    run: int
    total_score: int
    active: bool

@dataclass
class Sizes:
    play_area: pygame.Rect
    tile: int

FontSize = int

@dataclass
class Platform:
    screen: Screen
    get_font: Callable[[FontSize], pygame.font.Font]
    get_scores: Callable[[], list[Score]]
    add_score: Callable[[int, bool], None]
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

def draw_tile_sprite(platform: Platform, tile: TileSprite):
    draw_sprite(platform, tile.sprite_index, tile.x * platform.sizes.tile, tile.y * platform.sizes.tile)

def draw_tile(platform: Platform, tile: Tile):
    draw_tile_sprite(platform, tile)

    if tile.has_treasure:
        draw_sprite(platform, 12, tile.x * platform.sizes.tile, tile.y * platform.sizes.tile)

def sign(x: float) -> float:
    if x > 0.0:
        return 1.0
    elif x < 0.0:
        return -1.0
    else:
        return 0.0

def draw_monster(platform: Platform, monster: Monster):
    if monster.teleport_counter > 0:
        draw_sprite(
            platform,
            10,
            int(monster.display_x() * platform.sizes.tile),
            int(monster.display_y() * platform.sizes.tile)
        );
    else:
        draw_sprite(
            platform,
            monster.sprite_index,
            int(monster.display_x() * platform.sizes.tile),
            int(monster.display_y() * platform.sizes.tile)
        );
        draw_hp(platform, monster);

    monster.offset_x -= sign(monster.offset_x)*(1/8);
    monster.offset_y -= sign(monster.offset_y)*(1/8);

def draw_hp(platform: Platform, monster: Monster):
    for i in range(int(monster.hp + 0.5)):
        draw_sprite(
            platform,
            9,
            int(monster.display_x() * platform.sizes.tile) + ((i%3)*platform.sizes.tile*5)//16,
            int(monster.display_y() * platform.sizes.tile) - ((i//3)*platform.sizes.tile*5)//16
        );


def draw_text(platform: Platform, text: str, size: int, centered: bool, text_y: float, color: pygame.Color):
    text_surface: pygame.Surface = platform.get_font(size * 2).render(text, True, color)

    if centered:
        text_x = platform.sizes.play_area.x + (platform.sizes.play_area.width - text_surface.get_width())/2;
    else:
        text_x = platform.sizes.play_area.x + platform.sizes.play_area.width - (UI_WIDTH * platform.sizes.tile) + 25;

    platform.screen.blit(
        text_surface,
        (text_x, text_y),
    )

white = pygame.color.Color("white")
aqua = pygame.color.Color("aqua")
violet = pygame.color.Color("violet")

def draw_scores(platform: Platform):
    scores = platform.get_scores();

    if scores:
        draw_text(
            platform,
            right_pad(["RUN","SCORE","TOTAL"]),
            18,
            True,
            platform.sizes.play_area.height/2,
            white
        );

        newest_score = scores.pop();
        scores.sort(key=cmp_to_key(lambda a, b: b["total_score"] - a["total_score"]));

        scores.insert(0, newest_score);

        for i in range(min(10,len(scores))):
            score_text = right_pad([str(scores[i]["run"]), str(scores[i]["score"]), str(scores[i]["total_score"])]);
            draw_text(
                platform,
                score_text,
                18,
                True,
                platform.sizes.play_area.height/2 + 24+i*24,
                aqua if i == 0 else violet
            );

def right_pad(text_array: list[str]):
    output = "";
    for text in text_array:
        for _ in range(len(text), 10):
            text+=" ";
        output += text;

    return output;

@dataclass
class RunningState:
    player: Player
    rng: random.Random
    tiles: Tiles
    level: Level
    monsters: list[Monster]
    spawn_counter: int
    spawn_rate: int
    score: int

@dataclass
class State:
    pass

@dataclass
class Title(State):
    rng: random.Random

@dataclass
class Running(State):
    state: RunningState

@dataclass
class Dead(State):
    state: RunningState

def title_state(seed: int) -> Title:
    return Title(random.Random(seed))

def running_state(title: Title) -> Running:
    return start_level(title.rng, 1, 3, 0)

def start_level(rng: random.Random, level: Level, player_hp: HP, score: int) -> Running:
    @dataclass
    class MiniState:
        rng: random.Random
        tiles: Tiles
        level: Level
        monsters: list[Monster]
        score: int

    state = MiniState(rng, [], level, [], score)

    generate_level(state);

    starting_tile: Tile = random_passable_tile(state);

    spawn_rate = 15

    exit_tile: Tile = random_passable_tile(state);

    replace(state.tiles, exit_tile, lambda x, y: Exit(x, y))

    return Running(RunningState(
        Player(starting_tile, player_hp),
        state.rng,
        state.tiles,
        state.level,
        state.monsters,
        spawn_rate,
        spawn_rate,
        state.score,
    ))

def dead_state(running: Running) -> Dead:
    return Dead(running.state)

def to_title_state(rng: random.Random) -> Title:
    return Title(rng)

@dataclass
class PlayerMoveResult:
    died: bool
    move_result: MoveResult

def player_move(platform: Platform, state: RunningState, dx: W, dy: H) -> PlayerMoveResult:
    died = False

    move_result = try_move(state.tiles, state.player, dx, dy)

    if move_result.did_move:
        died = tick(platform, state);

    return PlayerMoveResult(
        died,
        move_result,
    )

def basic_do_stuff(state: RunningState, monster: Monster):
    neighbors = get_adjacent_passable_neighbors(state.rng, state.tiles, monster);
    neighbors = list(filter(lambda t: (not t.monster) or (t.monster.is_player), neighbors));
    if len(neighbors):
       neighbors.sort(key=cmp_to_key(lambda a, b: dist(a, state.player) - dist(b, state.player)));
       new_tile = neighbors[0];
       try_move(state.tiles, monster, new_tile.x - monster.x, new_tile.y - monster.y)

def monster_do_stuff(state: RunningState, monster: Monster):
    monster.teleport_counter -= 1;
    if monster.is_stunned or monster.teleport_counter > 0:
        monster.is_stunned = False;
        return;

    monster.attacked_this_turn = False;
    # Matching here seems better than forcing monster.py to know about State
    match monster:
        case Bird():
            basic_do_stuff(state, monster)
        case Snake():
            basic_do_stuff(state, monster)
            if not monster.attacked_this_turn:
                basic_do_stuff(state, monster)
        case Tank():
            basic_do_stuff(state, monster)
        case Eater():
            neighbors = list(filter(lambda t: not t.passable and in_bounds(t.x,t.y), get_adjacent_neighbors(state.rng, state.tiles, monster)));
            if len(neighbors):
                replace(state.tiles, neighbors[0], lambda x, y: Floor(x, y));
                monster.heal(0.5);
            else:
                basic_do_stuff(state, monster)
        case Jester():
            neighbors = get_adjacent_passable_neighbors(state.rng, state.tiles, monster);
            if len(neighbors):
                try_move(state.tiles, monster, neighbors[0].x - monster.x, neighbors[0].y - monster.y)
        case _:
            print("unhandled do stuff case: ", monster)

def step_on(platform: Platform, state: RunningState, monster: Monster, tile: Tile) -> State | None:
    match tile:
        case Floor():
            if monster.is_player and tile.has_treasure:
                state.score += 1;
                tile.has_treasure = False;
                spawn_monster(state);
        case Wall():
            pass
        case Exit():
            if monster.is_player:
                if state.level == NUM_LEVELS:
                    platform.add_score(state.score, True);
                    return to_title_state(state.rng);
                else:
                    return start_level(state.rng, state.level + 1, min(MAX_HP, state.player.hp+1), state.score);
        case _:
            print("unhandled step on case: ", tile)

    return None


def tick(platform: Platform, state: RunningState) -> bool:
    died = False

    # In reverse so we can safely delete monsters
    for i in range(len(state.monsters) - 1, -1, -1):
        if not state.monsters[i].is_dead:
            match state.monsters[i]:
                case Bird():
                    pass
                case Snake():
                    pass
                case Tank():
                    started_stunned = state.monsters[i].is_stunned;
                    monster_do_stuff(state, state.monsters[i]);

                    if not started_stunned:
                        state.monsters[i].is_stunned = True;

                    continue
                case Eater():
                    pass
                case Jester():
                    pass
                case _:
                    print("unhandled tick case: ", state.monsters[i])


            # This seems nicer than maving to have monster.py know about State
            monster_do_stuff(state, state.monsters[i]);
        else:
            state.monsters.pop(i);

    if state.player.is_dead:
        platform.add_score(state.score, False);
        died = True

    state.spawn_counter -= 1;

    if state.spawn_counter <= 0:
        spawn_monster(state);
        state.spawn_counter = state.spawn_rate;
        state.spawn_rate -= 1;

    return died



