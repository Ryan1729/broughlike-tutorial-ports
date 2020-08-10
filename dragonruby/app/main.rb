# frozen_string_literal: true

require 'app/game.rb'
require 'app/map.rb'
require 'app/tile.rb'
require 'app/monster.rb'
require 'app/util.rb'
require 'app/spell.rb'

def tick(args)
  s = args.state

  s.state ||= :title
  s.read_file ||= -> (file_name){ args.gtk.read_file file_name }
  s.write_file ||= -> (file_name, text){ args.gtk.write_file file_name, text }

  draw args

  key_down = args.inputs.keyboard.key_down
  case s.state
  when :title
    drawTitle args
    startGame s if key_down.truthy_keys.length.positive?
  when :dead
    args.state.state = :title if key_down.truthy_keys.length.positive?
  when :running
    s.player.tryMove s, 0, -1 if key_down.w || key_down.up
    s.player.tryMove s, 0, 1 if key_down.s || key_down.down
    s.player.tryMove s, -1, 0 if key_down.a || key_down.left
    s.player.tryMove s, 1, 0 if key_down.d || key_down.right
  else
    throw 'Unknown state ' + s.state
  end
end
