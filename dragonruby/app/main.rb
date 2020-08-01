require 'app/game.rb'
require 'app/map.rb'
require 'app/tile.rb'
require 'app/monster.rb'
require 'app/util.rb'
require 'app/spell.rb'

def tick(args)
  s = args.state
  init s
  key_down = args.inputs.keyboard.key_down
  s.player.tryMove s, 0, -1 if key_down.w || key_down.up
  s.player.tryMove s, 0, 1 if key_down.s || key_down.down
  s.player.tryMove s, -1, 0 if key_down.a || key_down.left
  s.player.tryMove s, 1, 0 if key_down.d || key_down.right

  draw args
end

def init(s)
  s.level ||= 1

  generateLevel s

  s.player ||= Player.new s.tiles.randomPassable
end
