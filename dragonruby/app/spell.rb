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
  },
  MAELSTROM: lambda {|s|
    s.monsters.each do |m|
        m.move(s, s.tiles.randomPassable)
        m.teleportCounter = 2
    end
  },
  MULLIGAN: lambda {|s|
    startLevel(s, 1, s.player.spells)
  },
  AURA: lambda {|s|
    s.player.tile.getAdjacentNeighbors(s.tiles).each do |t|
      t.setEffect(13)
      t.monster.heal(1) unless t.monster.nil?
    end
    s.player.tile.setEffect(13)
    s.player.heal(1)
  },
  DASH: lambda {|s|
    player  = s.player
    newTile = player.tile
    loop do
      lastMove = s.player.lastMove
      testTile = newTile.getNeighbor s.tiles, lastMove[0], lastMove[1]

      break unless testTile.passable && !testTile.monster

      newTile = testTile
    end

    return if player.tile == newTile

    player.move s, newTile
    newTile.getAdjacentNeighbors(s.tiles).each do |t|
      next if t.monster.nil?

      t.setEffect(14)
      t.monster.stunned = true
      t.monster.hit s, 1
    end
  },
  DIG: lambda {|s|
    (0...NumTiles).each do |i|
      (0...NumTiles).each do |j|
        tile = s.tiles.get i, j
        next if tile.passable

        s.tiles.replace tile, Floor
      end
    end
    s.player.tile.setEffect(13)
    s.player.heal(2)
  },
  KINGMAKER: lambda {|s|
    s.monsters.each do |m|
      m.heal(1)
      m.tile.treasure = true
    end
  }
}.freeze
