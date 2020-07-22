require 'app/game.rb'
require 'app/map.rb'
require 'app/tile.rb'
require 'app/monster.rb'
require 'app/util.rb'
require 'app/spell.rb'

def tick args
  s = args.state
  s.x ||= 0
  s.y ||= 0
  key_down = args.inputs.keyboard.key_down
  if key_down.w then s.y -= 1 end
  if key_down.s then s.y += 1 end
  if key_down.a then s.x -= 1 end
  if key_down.d then s.x += 1 end

  draw args
end

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

  drawSprite args, 0, s.x, s.y
end

def drawSprite args, sprite, x, y
  args.outputs.sprites << {
    x: PlayAreaMinX + x * TileSize,
    y: PlayAreaMinY + (PlayAreaMaxY - (y * TileSize)),
    w: TileSize,
    h: TileSize,
    path: "sprites/spritesheet.png",
    source_x: sprite * 16,
    source_y: 0,
    source_w: 16,
  }
end
