class Monster
  attr_accessor :tile, :sprite, :hp

  def initialize tile, sprite, hp
    move(tile)
    @sprite = sprite
    @hp = hp
  end

  def draw args
    drawSprite args, sprite, tile.x, tile.y
  end
  
  def tryMove tiles, dx, dy
    newTile = tile.getNeighbor tiles, dx, dy
    if newTile.passable then
      if !newTile.monster then
        move(newTile)
      end
      true
    end
  end

  def move to_tile
    if @tile then
      @tile.monster = nil
    end
    @tile = to_tile
    tile.monster = self
  end
  
  ## Dragonruby output these instructions to enable serialization on our
  ## class, so we complied.
  # 1. Create a serialize method that returns a hash with all of
  #    the values you care about.
  def serialize
    { 
      :tile => tile,
      :sprite => sprite,
      :hp => hp
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

class Player < Monster
  def initialize tile
      super tile, 0, 3
  end
  
  def isPlayer
    true
  end
end
