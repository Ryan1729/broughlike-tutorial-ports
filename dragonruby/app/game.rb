# frozen_string_literal: true

SCORE_SAVE_PATH = './app/score_save.rb'

TileSize = 80
NumTiles = 9
UIWidth = 4
PlayAreaX = 1.5 * TileSize
PlayAreaY = 0
# includes the UI section
PlayAreaW = (NumTiles + UIWidth) * TileSize
PlayAreaH = NumTiles * TileSize
# center of the screen, which is currently also the center of the play area
CenterX = 1280 / 2
CenterY = 768 / 2
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

  drawText(args, 'Level: ' + s.level.to_s, 20, :ui, 50, [238, 130, 238])
  drawText(args, 'Score: ' + s.score.to_s, 20, :ui, 100, [238, 130, 238])
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

def drawText(args, text, size, centered, textY, color)
  textX = CenterX
  align = 1 # centered
  if centered != :centered
    textX = PlayAreaX + PlayAreaW - UIWidth*TileSize + 25
    align = 0
  end

  args.outputs.labels << [
    textX,
    768 - textY,
    text,
    size,
    align,
    color[0],
    color[1],
    color[2],
    if color[3].nil?
      255
    else
      color[3]
    end
  ]
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


  if s.player.dead
    addScore(s, :lost)
    s.state = :dead
  end

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

  drawText(args, 'BROUGH-UN', 70, :centered, CenterY - 190, [255, 255, 255])
  drawText(args, 'RUBY', 40, :centered, CenterY - 50, [255, 255, 255])
end

def startGame(s)
  s.level = 1
  s.score = 0

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

def getScores(s)
  current_text = (s.read_file || proc{}).call(SCORE_SAVE_PATH) || ''
  if current_text.length.positive?
    deserialize_scores current_text
  else
    []
  end
end

def addScore(s, won)
  scores = getScores s
  scoreObject = {
    score: s.score,
    run: 1,
    totalScore: s.score,
    active: won == :won
  }
  lastScore = scores.pop

  if lastScore
    if lastScore.active
      scoreObject.run = lastScore.run + 1
      scoreObject.totalScore += lastScore.totalScore
    else
      scores.push lastScore
    end
  end
  scores.push scoreObject

  (s.write_file || proc{}).call(
    SCORE_SAVE_PATH,
    serialize_scores(scores)
  )
end

def serialize_scores(scores)
  # TODO
  ''
end

def deserialize_scores(string)
  # TODO
  []
end
