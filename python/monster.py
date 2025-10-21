
from dataclasses import dataclass

from game_types import SpriteIndex, X, Y, TileSprite, PLAYER_INDEX, BIRD_INDEX, SNAKE_INDEX, TANK_INDEX, EATER_INDEX, JESTER_INDEX

HP = float
STARTING_HP = 3
MAX_HP = 6

@dataclass
class Monster:
    x: X
    y: Y
    sprite_index: SpriteIndex
    hp: HP
    is_player: bool
    is_dead: bool
    attacked_this_turn: bool
    is_stunned: bool
    
    def heal(self, heal_amount: HP):
        self.hp = min(MAX_HP, self.hp+heal_amount);


class Player(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, PLAYER_INDEX, 3, True, False, False, False)

class Bird(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, BIRD_INDEX, 3, False, False, False, False)

class Snake(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, SNAKE_INDEX, 1, False, False, False, False)

class Tank(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, TANK_INDEX, 2, False, False, False, False)

class Eater(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, EATER_INDEX, 1, False, False, False, False)

class Jester(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, JESTER_INDEX, 2, False, False, False, False)
