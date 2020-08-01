def tryTo(description, callback)
  (0..1000).reverse_each do |_timeout|
    return if callback.call
  end
  throw 'Timeout while trying to ' + description
end

def randomRange(min, max)
  (rand * (max - min + 1)).floor + min
end
