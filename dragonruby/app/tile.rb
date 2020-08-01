# frozen_string_literal: true

# a (possibly inaccessible) location in the dungeon
class Tile
  attr_accessor :x, :y, :sprite, :passable, :monster

  def initialize(x, y, sprite, passable)
    @x = x
    @y = y
    @sprite = sprite
    @passable = passable
  end

  # manhattan distance
  def dist(other)
    (x - other.x).abs + (y - other.y).abs
  end

  def draw(args)
    drawSprite args, sprite, x, y
  end

  def getNeighbor(tiles, dx, dy)
    tiles.get x + dx, y + dy
  end

  def getAdjacentNeighbors(tiles)
    [
      (getNeighbor tiles, 0, -1),
      (getNeighbor tiles, 0, 1),
      (getNeighbor tiles, -1, 0),
      (getNeighbor tiles, 1, 0)
    ].shuffle!
  end

  def getAdjacentPassableNeighbors(tiles)
    (getAdjacentNeighbors tiles).select { |t| t.passable }
  end

  def getConnectedTiles(tiles)
    connectedTiles = [self]
    frontier = [self]
    while frontier.length > 0
      neighbors = (frontier.pop.getAdjacentPassableNeighbors tiles)
                  .select { |t| !connectedTiles.member? t }
      connectedTiles = connectedTiles.concat neighbors
      frontier = frontier.concat neighbors
    end
    connectedTiles
  end

  ## Dragonruby output these instructions to enable serialization on our
  ## class, so we complied.
  # 1. Create a serialize method that returns a hash with all of
  #    the values you care about.
  def serialize
    # this way avoids an infinite recursive loop during printout
    monster_hash = nil
    if monster
      monster_tile = monster.tile
      if monster.tile
        (monster.tile.equal? self ? 'self' : 'other') +
          '(' + monster.tile.x.to_s + ', ' + monster.tile.y.to_s + ')'
      end
      {
        tile: monster_tile,
        sprite: monster.sprite,
        hp: monster.hp
      }
    end

    {
      x: x,
      y: y,
      sprite: sprite,
      passable: passable,
      monster: monster_hash
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

# a walkable tile
class Floor < Tile
  def initialize(x, y)
    super x, y, 2, true
  end
end

# a non-walkable tile
class Wall < Tile
  def initialize(x, y)
    super x, y, 3, false
  end
end
