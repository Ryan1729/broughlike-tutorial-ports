TileSize = 80;
NumTiles = 9;
UIWidth = 4;
PlayAreaMinX = 1.5 * TileSize
PlayAreaMinY = 0
PlayAreaMaxX = (NumTiles + UIWidth) * TileSize
PlayAreaMaxY = NumTiles * TileSize

def draw args
  s = args.state

  args.outputs.background_color = [75, 0, 130]

  # the -1 and +2 business makes the border lie just outside the actual
  # play area
  args.outputs.borders << [
    PlayAreaMinX - 1,
    PlayAreaMinY - 1,
    PlayAreaMaxX + 2,
    PlayAreaMaxY + 2,
    255,
    255,
    255
  ]

  (0...NumTiles).each{|i|
    (0...NumTiles).each{|j|
      (s.tiles.get i, j).draw args
    }
  }

  s.monsters.each{|monster|
    monster.draw args
  }

  s.player.draw args
end

def drawSprite args, sprite, x, y
  args.outputs.sprites << {
    x: PlayAreaMinX + x * TileSize,
    y: PlayAreaMinY + (PlayAreaMaxY - ((y + 1) * TileSize)),
    w: TileSize,
    h: TileSize,
    path: "sprites/spritesheet.png",
    source_x: sprite * 16,
    source_y: 0,
    source_w: 16,
  }
end

def game_tick s
  monsters = s.monsters
  (0...monsters.length).reverse_each{|k|
    if !monsters[k].dead then
      monsters[k].update s
    else
      monsters.delete_at k
    end
  }
end
