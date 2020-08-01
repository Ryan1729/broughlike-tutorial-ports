# frozen_string_literal: true

def generateLevel(s)
  tryTo 'generate map', lambda {
    pair = generateTiles
    tiles = pair[0]
    passableCount = pair[1]
    connectedTiles = tiles.randomPassable.getConnectedTiles tiles
    areAllConnected = passableCount == connectedTiles.length
    s.tiles ||= tiles if areAllConnected
    areAllConnected
  }

  s.monsters ||= generateMonsters s
end

def generateTiles
  tiles = []
  passableCount = 0
  (0...NumTiles).each do |i|
    tiles[i] = []
    (0...NumTiles).each  do |j|
      if (rand < 0.3) || !inBounds(i, j)
        tiles[i][j] = Wall.new i, j
      else
        tiles[i][j] = Floor.new i, j

        passableCount += 1
      end
    end
  end
  [Tiles.new(tiles), passableCount]
end

def inBounds(x, y)
  x > 0 and y > 0 and x < NumTiles - 1 and y < NumTiles - 1
end

class Tiles
  def initialize(tiles)
    @tiles = tiles
  end

  def get(x, y)
    if inBounds x, y
      @tiles[x][y]
    else
      Wall.new(x, y)
    end
  end

  def randomPassable
    tile = nil
    tryTo 'get random passable tile', lambda {
      x = randomRange 0, NumTiles - 1
      y = randomRange 0, NumTiles - 1
      tile = get x, y
      tile.passable && !tile.monster
    }
    tile
  end

  ## Dragonruby output these instructions to enable serialization on our
  ## class, so we complied.
  # 1. Create a serialize method that returns a hash with all of
  #    the values you care about.
  def serialize
    {
      tiles: @tiles
    }
  end

  # 2. Override the inspect method and return `serialize.to_s`.
  def inspect
    serialize.to_s
  end

  # 3. Override to_s and return `serialize.to_s`.
  def to_s
    serialize.to_s
  end
end

def generateMonsters(s)
  monsters = []
  numMonsters = s.level + 1
  (0...numMonsters).each  do |_i|
    monsters << (spawnMonster s)
  end
  monsters
end

def spawnMonster(s)
  monsterType = [Bird, Snake, Tank, Eater, Jester].shuffle![0]
  monsterType.new s.tiles.randomPassable
end
