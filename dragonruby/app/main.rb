require 'app/game.rb'
require 'app/map.rb'
require 'app/tile.rb'
require 'app/monster.rb'
require 'app/util.rb'
require 'app/spell.rb'

def tick args
  s = args.state
  init s
  key_down = args.inputs.keyboard.key_down
  if key_down.w or key_down.up then s.player.tryMove s, 0, -1 end
  if key_down.s or key_down.down then s.player.tryMove s, 0, 1 end
  if key_down.a or key_down.left then s.player.tryMove s, -1, 0 end
  if key_down.d or key_down.right then s.player.tryMove s, 1, 0 end

  draw args
end

def init s
  s.level ||= 1

  generateLevel s
  
  s.player ||= Player.new s.tiles.randomPassable
end
