from typing import Protocol

X = int
Y = int

W = int
H = int

SpriteIndex = int

class TileSprite(Protocol):
    x: X
    y: Y
    sprite_index: SpriteIndex

NUM_TILES = 9
UI_WIDTH = 4
