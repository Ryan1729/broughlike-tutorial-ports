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
