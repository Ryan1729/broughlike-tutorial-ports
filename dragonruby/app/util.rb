def tryTo(description, callback)
    (0..1000).reverse_each{|timeout|
        if callback.call then
            return
        end
    }
    throw 'Timeout while trying to '+description;
end

def randomRange(min, max)
    return (rand*(max-min+1)).floor + min
end

