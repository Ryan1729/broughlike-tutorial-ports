
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

