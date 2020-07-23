class Tile
  attr_accessor :x, :y, :sprite, :passable
  
  def initialize(x, y, sprite, passable)
    @x = x
    @y = y;
    @sprite = sprite;
    @passable = passable;
  end

  def draw args
    drawSprite args, sprite, x, y
  end
  
  ## Dragonruby output these instructions to enable serialization on our
  ## class, so we complied.
  # 1. Create a serialize method that returns a hash with all of
  #    the values you care about.
  def serialize
    { 
      x => x,
      y => y,
      sprite => sprite,
      passable => passable
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

class Floor < Tile
  def initialize(x, y)
      super x, y, 2, true
  end
end

class Wall < Tile
  def initialize(x, y)
      super x, y, 3, false
  end
end
