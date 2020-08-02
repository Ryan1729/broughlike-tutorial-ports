# frozen_string_literal: true

MaxHp = 6

# An entitiy that can move about the dungeon
class Monster
  attr_accessor :tile, :sprite, :hp, :dead, :stunned

  def initialize(tile, sprite, hp)
    move(tile)
    @sprite = sprite
    @hp = hp
    @dead = false
    @attackedThisTurn = false
    @stunned = false
  end

  def heal(damage)
    @hp = [MaxHp, hp + damage].min
  end

  def update(s)
    if @stunned
      @stunned = false
      return
    end

    doStuff s
  end

  def doStuff(s)
    neighbors = tile.getAdjacentPassableNeighbors s.tiles

    neighbors = neighbors.select { |t| !t.monster || t.monster.isPlayer }

    return if neighbors.empty?

    playerTile = s.player.tile
    neighbors.sort! do |a, b|
      a.dist(playerTile) - b.dist(playerTile)
    end
    newTile = neighbors[0]
    tryMove s, newTile.x - tile.x, newTile.y - tile.y
  end

  def draw(args)
    drawSprite args, sprite, tile.x, tile.y

    drawHP args
  end

  def drawHP(args)
    (0...hp).each do |i|
      drawSprite(
        args,
        9,
        tile.x + (i % 3) * (5 / 16),
        tile.y - (i / 3).floor * (5 / 16)
      )
    end
  end

  def tryMove(s, dx, dy)
    tiles = s.tiles
    newTile = tile.getNeighbor tiles, dx, dy
    return false unless newTile.passable

    if !newTile.monster
      move(newTile)
    elsif isPlayer != newTile.monster.isPlayer
      @attackedThisTurn = true
      newTile.monster.stunned = true
      newTile.monster.hit 1
    end
    true
  end

  def hit(damage)
    @hp -= damage
    die if @hp <= 0
  end

  def die
    @dead = true
    @tile.monster = nil
    @sprite = 1
  end

  def move(to_tile)
    @tile.monster = nil if @tile
    @tile = to_tile
    @tile.monster = self
  end

  def isPlayer
    false
  end

  ## Dragonruby output these instructions to enable serialization on our
  ## class, so we complied.
  # 1. Create a serialize method that returns a hash with all of
  #    the values you care about.
  def serialize
    {
      tile: tile,
      sprite: sprite,
      hp: hp
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

# the monster the player controls
class Player < Monster
  def initialize(tile)
    super tile, 0, 3
  end

  def isPlayer
    true
  end

  def tryMove(s, dx, dy)
    game_tick s if super s, dx, dy
  end
end

# a basic monster with lots of health
class Bird < Monster
  def initialize(tile)
    super tile, 4, 3
  end
end

# a fast monster
class Snake < Monster
  def initialize(tile)
    super tile, 5, 1
  end

  def doStuff(s)
    @attackedThisTurn = false
    super s

    super s unless @attackedThisTurn
  end
end

# a slow-moving monster
class Tank < Monster
  def initialize(tile)
    super tile, 6, 2
  end

  def update(s)
    started_stunned = @stunned
    super s
    @stunned = true unless started_stunned
  end
end

# a monster that eats walls
class Eater < Monster
  def initialize(tile)
    super tile, 7, 1
  end

  def doStuff(s)
    neighbors = tile
      .getAdjacentNeighbors(s.tiles)
      .select{ |t| !t.passable && inBounds(t.x,t.y)}
    if neighbors.length.positive?
      s.tiles.replace neighbors[0], Floor
      heal(0.5)
    else
      super s
    end
  end
end

# a monster that moves randomly
class Jester < Monster
  def initialize(tile)
    super tile, 8, 2
  end
end
