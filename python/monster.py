
from dataclasses import dataclass

from game_types import SpriteIndex, X, Y, TileSprite, PLAYER_INDEX, BIRD_INDEX, SNAKE_INDEX, TANK_INDEX, EATER_INDEX, JESTER_INDEX, SpellName, W, H
from util import shuffle, RNG

HP = float
STARTING_HP = 3
MAX_HP = 6
OffsetX = float
OffsetY = float

@dataclass
class Monster:
    x: X
    y: Y
    offset_x: OffsetX
    offset_y: OffsetY
    sprite_index: SpriteIndex
    hp: HP
    is_player: bool
    is_dead: bool
    attacked_this_turn: bool
    is_stunned: bool
    teleport_counter: int
    last_dx: W
    last_dy: H
    bonus_attack: int

    def heal(self, heal_amount: HP):
        self.hp = min(MAX_HP, self.hp+heal_amount);

    def display_x(self) -> OffsetX:
        return self.x + self.offset_x;

    def display_y(self) -> OffsetY:
        return self.y + self.offset_y;


class Player(Monster):
    spells: list[SpellName | None]

    def __init__(self, tile: TileSprite, hp: HP, rng: RNG, num_spells: int):
        super().__init__(tile.x, tile.y, 0, 0, PLAYER_INDEX, hp, True, False, False, False, 0, -1, 0, 0)

        all_spells: list[SpellName | None] = [s for s in SpellName]
        spells: list[SpellName | None] = shuffle(rng, all_spells)[:num_spells]
        self.spells = spells

    def add_spell(self, rng: RNG):
        self.spells.append(shuffle(rng, [s for s in SpellName])[0])

class Bird(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, 0, 0, BIRD_INDEX, 3, False, False, False, False, 2, -1, 0, 0)

class Snake(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, 0, 0, SNAKE_INDEX, 1, False, False, False, False, 2, -1, 0, 0)

class Tank(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, 0, 0, TANK_INDEX, 2, False, False, False, False, 2, -1, 0, 0)

class Eater(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, 0, 0, EATER_INDEX, 1, False, False, False, False, 2, -1, 0, 0)

class Jester(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, 0, 0, JESTER_INDEX, 2, False, False, False, False, 2, -1, 0, 0)
