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

class Bird < Monster
    def initialize tile
        super tile, 4, 3
    end
end

class Snake < Monster
    def initialize tile
        super tile, 5, 1
    end
end

class Tank < Monster
    def initialize tile
        super tile, 6, 2
    end
end

class Eater < Monster
    def initialize tile
        super tile, 7, 1
    end
end

class Jester < Monster
    def initialize tile
        super tile, 8, 2
    end
end
