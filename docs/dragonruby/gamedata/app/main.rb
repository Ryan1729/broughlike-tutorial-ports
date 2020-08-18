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
  s.append_sound ||= -> (file_name){ args.outputs.sounds << file_name }
  initSounds s

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

    s.player.castSpell(s, 0) if key_down.one
    s.player.castSpell(s, 1) if key_down.two
    s.player.castSpell(s, 2) if key_down.three
    s.player.castSpell(s, 3) if key_down.four
    s.player.castSpell(s, 4) if key_down.five
    s.player.castSpell(s, 5) if key_down.six
    s.player.castSpell(s, 6) if key_down.seven
    s.player.castSpell(s, 7) if key_down.eight
    s.player.castSpell(s, 8) if key_down.nine
  else
    throw 'Unknown state ' + s.state
  end
end
