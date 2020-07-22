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
  if key_down.w then s.y += 8 end
  if key_down.s then s.y -= 8 end
  if key_down.a then s.x -= 8 end
  if key_down.d then s.x += 8 end

  draw args
end

TileSize = 80;
NumTiles = 9;
UIWidth = 4;

def draw args
  s = args.state

  # copy the screen size and ake it slighlty bigger to fix the gray 
  # peeking through when fullscreened
  background = args.grid.rect.scale_rect(1.1)
  # add on the colour we want
  background += [75, 0, 130]
  args.outputs.solids << background
  
  # the -1 and +2 business makes the border lie just outside the actual 
  # play area
  args.outputs.borders << [
    (1.5 * TileSize) - 1,
    -1,
    (NumTiles + UIWidth) * TileSize + 2,
    NumTiles * TileSize + 2,
    255,
    255,
    255
  ]

  args.outputs.sprites << {
    x: s.x,
    y: s.y,
    w: TileSize,
    h: TileSize,
    path: "sprites/spritesheet.png",
    source_x: 0,
    source_y: 0,
    source_w: 16,
  }
end
