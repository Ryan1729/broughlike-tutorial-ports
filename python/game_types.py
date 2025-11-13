from typing import Protocol
from enum import Enum

X = int
Y = int

W = int
H = int

SpriteIndex = int


PLAYER_INDEX: SpriteIndex = 0
BIRD_INDEX: SpriteIndex = 4
SNAKE_INDEX: SpriteIndex =  5
TANK_INDEX: SpriteIndex =  6
EATER_INDEX: SpriteIndex =  7
JESTER_INDEX: SpriteIndex =  8

class TileSprite(Protocol):
    x: X
    y: Y
    sprite_index: SpriteIndex

Distance = int

# manhattan distance
def dist(a: TileSprite, b: TileSprite)-> Distance:
    return abs(a.x-b.x)+abs(a.y-b.y);

NUM_TILES = 9
UI_WIDTH = 4

Level = int

class SFX(Enum):
    Hit1 = 1
    Hit2 = 2
    Treasure = 3
    NewLevel = 4
    Spell = 5

class SpellName(Enum):
    WOOP = 1
