# frozen_string_literal: true

Spells = {
  WOOP: lambda {|s|
    s.player.move s, s.tiles.randomPassable
  }
}.freeze
