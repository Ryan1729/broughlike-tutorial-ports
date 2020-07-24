def generateLevel s
  s.tiles ||= generateTiles
end

def generateTiles
  tiles = []
  (0...NumTiles).each{|i|
    tiles[i] = []
    (0...NumTiles).each{|j|
      if rand < 0.3 or !inBounds(i,j) then
        tiles[i][j] = Wall.new i, j
      else
        tiles[i][j] = Floor.new i, j
      end
    }
  }
  tiles
end

def inBounds x, y
    x>0 and y>0 and x<NumTiles-1 and y<NumTiles-1
end

def getTile s, x, y
    if inBounds(x,y) then
        s.tiles[x][y]
    else
        Wall.new(x,y)
    end
end

def randomPassableTile s
    tile = nil
    tryTo 'get random passable tile', -> {
        x = randomRange 0, NumTiles-1
        y = randomRange 0, NumTiles-1
        tile = getTile s, x, y
        tile.passable && !tile.monster
    }
    tile
end
