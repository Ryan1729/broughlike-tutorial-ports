# frozen_string_literal: true

SCORE_SAVE_PATH = 'score_save.rb'

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

Aqua = [0, 255, 255].freeze
Indigo = [75, 0, 130].freeze
Violet = [238, 130, 238].freeze
White = [255, 255, 255].freeze


def draw(args)
  args.outputs.background_color = Indigo

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

  # skip drawing the text since we can't draw text behind the title overlay
  return if s.state == :title

  drawText(args, 'Level: ' + s.level.to_s, 20, :ui, 50, Violet)
  drawText(args, 'Score: ' + s.score.to_s, 20, :ui, 100, Violet)
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

  drawText(args, 'BROUGH-UN', 70, :centered, CenterY - 190, White)
  drawText(args, 'RUBY', 40, :centered, CenterY - 50, White)
  
  drawScores args
end

ScoreOffset = 30

def drawScores(args)
  scores = getScores args.state
  return unless scores.length.positive?
  
  drawText(
    args,
    rightPad(%w[RUN SCORE TOTAL]),
    4,
    :centered,
    CenterY + 24 + ScoreOffset,
    White
  )

  newestScore = scores.pop
  scores.sort! do |a, b|
      b[:totalScore] - a[:totalScore]
  end
  
  scores.unshift newestScore

  (0...[10, scores.length].min).each do |i|
    score = scores[i]
    scoreText = rightPad([score[:run], score[:score], score[:totalScore]])
    drawText(
        args,
        scoreText,
        4,
        :centered,
        CenterY + 24 + (i + 2) * ScoreOffset,
        i.zero? ? Aqua : Violet
    )
  end
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
    # since we have to parse this ourselves, let's use a number instead
    # of a boolean, so all the values are numbers.
    active: won == :won ? 1 : 0
  }
  lastScore = scores.pop

  if lastScore
    if lastScore[:active].zero?
      scores.push lastScore
    else
      scoreObject[:run] = lastScore[:run] + 1
      scoreObject[:totalScore] += lastScore[:totalScore]
    end
  end
  scores.push scoreObject

  (s.write_file || proc{}).call(
    SCORE_SAVE_PATH,
    serialize_scores(scores)
  )
end

def serialize_scores(scores)
  scores.to_s
end

# we did this ourselves becasue dragonruby does not currently support
# Marshal or JSON
def deserialize_scores(string)
  output = []

  state = :start
  last_hash = nil
  last_key = nil
  last_value = nil

  string.each_char do |c|
    case state
    when :start
      if c == '{'
        state = :key_start
        last_hash = {}
      end
      when :key_start
      if c == ':'
        state = :key
        last_key = ''
      end
    when :key
      if c == ' '
        state = :hash_rocket_start
      elsif c == '='
        state = :hash_rocket_end
      else
        last_key += c
      end
    when :hash_rocket_start
      state = :hash_rocket_end if c == '='
    when :hash_rocket_end
      if c == '>'
        state = :value_start
        last_value = ''
      end
    when :value_start
      if c == ','
        state = :key_start
        last_hash[last_key.to_sym] = last_value.to_i
      elsif c == '}'
        state = :start
        last_hash[last_key.to_sym] = last_value.to_i
        output.push(last_hash)
      else
        last_value += c
      end
    else
      throw 'Unknown state ' + state
    end
  end

  output
end
