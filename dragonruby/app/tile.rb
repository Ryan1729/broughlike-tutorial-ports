# frozen_string_literal: true

# a (possibly inaccessible) location in the dungeon
class Tile
  attr_accessor :x, :y, :sprite, :passable, :monster, :treasure

  def initialize(x, y, sprite, passable)
    @x = x
    @y = y
    @sprite = sprite
    @passable = passable
    @treasure = false
  end

  # manhattan distance
  def dist(other)
    (x - other.x).abs + (y - other.y).abs
  end

  def draw(args)
    drawSprite args, sprite, x, y
    
    return unless @treasure
    
    drawSprite args, 12, x, y
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
    (getAdjacentNeighbors tiles).select(&:passable)
  end

  def getConnectedTiles(tiles)
    connectedTiles = [self]
    frontier = [self]
    until frontier.empty?
      neighbors = (frontier.pop.getAdjacentPassableNeighbors tiles)
                  .reject { |t| connectedTiles.member? t }
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

  def stepOn(s, monster)
    # we pass nil as s when placing the player initially
    return unless !s.nil? && monster.isPlayer && @treasure
    
    playSound s, :treasure
    s.score += 1
    @treasure = false
    s.monsters << (spawnMonster s)
  end
end

# a non-walkable tile
class Wall < Tile
  def initialize(x, y)
    super x, y, 3, false
  end
end

# a tile that starts the next level
class Exit < Tile
  def initialize(x, y)
    super x, y, 11, true
  end

  def stepOn(s, monster)
    return unless monster.isPlayer

    playSound s, :newLevel
    if s.level == NumLevels
        s.state = :title
        addScore(s, :won)
    else
        s.level += 1
        startLevel(s, [MaxHp, s.player.hp+1].min)
    end
  end
end
