# frozen_string_literal: true

TileSize = 80
NumTiles = 9
UIWidth = 4
PlayAreaX = 1.5 * TileSize
PlayAreaY = 0
PlayAreaW = (NumTiles + UIWidth) * TileSize
PlayAreaH = NumTiles * TileSize
StartingHp = 3
NumLevels = 6

def draw(args)
  args.outputs.background_color = [75, 0, 130]

  # the -1 and +2 business makes the border lie just outside the actual
  # play area
  args.outputs.borders << [
    PlayAreaX - 1,
    PlayAreaY - 1,
    PlayAreaW + 2,
    PlayAreaH + 2,
    255,
    255,
    255
  ]

  s = args.state

  return unless s.tiles

  (0...NumTiles).each do |i|
    (0...NumTiles).each  do |j|
      (s.tiles.get i, j).draw args
    end
  end

  s.monsters.each do |monster|
    monster.draw args
  end

  s.player.draw args
end

def drawSprite(args, sprite, x, y)
  args.outputs.sprites << {
    x: PlayAreaX + x * TileSize,
    y: PlayAreaY + (PlayAreaH - ((y + 1) * TileSize)),
    w: TileSize,
    h: TileSize,
    path: 'sprites/spritesheet.png',
    source_x: sprite * 16,
    source_y: 0,
    source_w: 16
  }
end

def game_tick(s)
  monsters = s.monsters
  (0...monsters.length).reverse_each do |k|
    if !monsters[k].dead
      monsters[k].update s
    else
      monsters.delete_at k
    end
  end

  s.state = :dead if s.player.dead

  s.spawnCounter -= 1
  return if s.spawnCounter.positive?

  monsters << (spawnMonster s)
  s.spawnCounter = s.spawnRate
  s.spawnRate -= 1
end

def drawTitle(args)
  # this needs to be a sprite so the z ordering is correct
  args.outputs.sprites << {
    x: PlayAreaX,
    y: PlayAreaY,
    w: PlayAreaW,
    h: PlayAreaH,
    path: 'sprites/spritesheet.png',
    source_x: 17 * 16,
    source_y: 0,
    source_w: 16,
    a: 192
  }
end

def startGame(s)
  s.level = 1
  startLevel s, StartingHp

  s.state = :running
end

def startLevel(s, playerHp)
  s.spawnRate = 15

  s.spawnCounter = s.spawnRate

  generateLevel s

  tiles = s.tiles

  s.player = Player.new tiles.randomPassable
  s.player.hp = playerHp

  tiles.replace tiles.randomPassable, Exit
end
