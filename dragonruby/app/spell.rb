# frozen_string_literal: true

Spells = {
  WOOP: lambda {|s|
    s.player.move s, s.tiles.randomPassable
  },
  QUAKE: lambda {|s|
    (0...NumTiles).each do |i|
      (0...NumTiles).each do |j|
        tile = s.tiles.get i, j
        if tile.monster
          numWalls = 4 - tile.getAdjacentPassableNeighbors(s.tiles).length
          tile.monster.hit(s, numWalls * 2)
        end
      end
    end
    s.shakeAmount = 20
  }
}.freeze
