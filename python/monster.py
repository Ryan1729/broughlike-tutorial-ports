
from dataclasses import dataclass

from game_types import SpriteIndex, X, Y, TileSprite

HP = int

@dataclass
class Monster:
    x: X
    y: Y
    sprite_index: SpriteIndex
    hp: HP
    is_player: bool


class Player(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, 0, 3, True)


class Bird(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, 4, 3, False)

class Snake(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, 5, 1, False)

class Tank(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, 6, 2, False)

class Eater(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, 7, 1, False)

class Jester(Monster):
    def __init__(self, tile: TileSprite):
        super().__init__(tile.x, tile.y, 8, 2, False)
