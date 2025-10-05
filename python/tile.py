
from dataclasses import dataclass

from game_types import SpriteIndex, X, Y

@dataclass
class Tile:
    x: X
    y: Y
    sprite_index: SpriteIndex
    passable: bool
    monster: None

class Floor(Tile):
    def __init__(self, x: X, y: Y):
        super().__init__(x, y, 2, True, None)

class Wall(Tile):
    def __init__(self, x: X, y: Y):
        super().__init__(x, y, 3, False, None)
