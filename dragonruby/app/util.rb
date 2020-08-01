# frozen_string_literal: true

def tryTo(description, callback)
  throw 'Timeout while trying to ' + description unless
  (0..1000).any? do |_timeout|
    callback.call
  end
end

def randomRange(min, max)
  (rand * (max - min + 1)).floor + min
end
