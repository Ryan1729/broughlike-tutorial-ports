pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- broughlike-tutorial
-- ported by ryan1729

--
-- game
--

function draw_sprite(sprite, x, y)
    sspr(
        (sprite % 8) * tilesize,
        flr(sprite / 8) * tilesize,
        tilesize,
        tilesize,
        -- we offset the sprites by 8 so at least
        -- part of all the tiles can be seen
        x * tilesize - 8,
        y * tilesize - 8
    )
end
-->8

--
-- map
--

function generate_level()
    try_to('generate map', function()
        return generate_tiles() == #(random_passable_tile():get_connected_tiles())
    end)

    generate_monsters()
end

function generate_tiles()
    local passable_tiles = 0

    tiles = {}
    for i=0,numTiles do
        tiles[i] = {}
        for j=0,numTiles do
            if (rnd(1) < 0.3 or not in_bounds(i, j)) then
                tiles[i][j] = wall:new(i,j)
            else
                tiles[i][j] = floor:new(i,j);

                passable_tiles += 1
            end
        end
    end

    return passable_tiles
end

function in_bounds(x,y)
    return x>0 and y>0 and x<numTiles-1 and y<numTiles-1
end

function get_tile(x, y)
    if(in_bounds(x,y)) then
        return tiles[x][y]
    else
        return wall:new(x,y)
    end
end

function random_passable_tile()
    local tile;
    try_to('get random passable tile', function()
        local x = flr(rnd(numTiles))
        local y = flr(rnd(numTiles))
        tile = get_tile(x, y);
        return tile.passable and not tile.monster;
    end);
    return tile
end

function generate_monsters()
    monsters = {};
    local num_monsters = level+1
    for i=0,num_monsters do
        spawn_monster()
    end
end

function spawn_monster()
    local monster_type = shuffle({bird, snake, tank, eater, jester})[1]
    local monster = monster_type:new(random_passable_tile())
    add(monsters, monster)
end

-->8

--
-- tile
--

tile = {}

function tile:new(x, y, sprite, passable)
    obj = {
        x = x,
        y = y,
        sprite = sprite,
        passable = passable
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function tile:dist(other)
  return abs(self.x-other.x)+abs(self.y-other.y);
end


function tile:draw()
  draw_sprite(self.sprite, self.x, self.y)
end

function tile:get_neighbor(dx, dy)
    return get_tile(self.x + dx, self.y + dy)
end

function tile:get_adjacent_neighbors()
    return shuffle({
        self:get_neighbor(0, -1),
        self:get_neighbor(0, 1),
        self:get_neighbor(-1, 0),
        self:get_neighbor(1, 0)
    });
end

function tile:get_adjacent_passable_neighbors()
    return filter(self:get_adjacent_neighbors(), function (t) return t.passable end);
end

function tile:get_connected_tiles()
    local connected_tiles = {self}
    local frontier = {self}
    while (#frontier > 0) do
        local neighbors = filter(
            pop(frontier):get_adjacent_passable_neighbors(),
            function (t) return not contains(connected_tiles, t) end
        )
        connected_tiles = concat(connected_tiles, neighbors)
        frontier = concat(frontier, neighbors)
    end
    return connected_tiles
end

floor = tile:new()

function floor:new(x, y)
  return tile.new(self, x, y, 2, true)
end

wall = tile:new()

function wall:new(x, y)
  return tile.new(self, x, y, 3, false)
end

-->8

--
-- monster
--

monster = {}

function monster:new(tile, sprite, hp)
    obj = {
        sprite = sprite,
        hp = hp
    }
    setmetatable(obj, self)
    self.__index = self
    obj:move(tile)
    return obj
end

function monster:update()
  self:do_stuff()
end

function monster:do_stuff()
    local neighbors = self.tile:get_adjacent_passable_neighbors()

    neighbors = filter(neighbors, function(t)
        return (t.monster == nil) or t.monster.is_player
    end)

    if(#neighbors > 0) then
        sort(neighbors, function(a,b)
            return a:dist(player.tile) > b:dist(player.tile)
        end)
        local new_tile = neighbors[1]
        self:try_move(new_tile.x - self.tile.x, new_tile.y - self.tile.y);
    end
end

function monster:draw()
  draw_sprite(self.sprite, self.tile.x, self.tile.y)

  self:draw_hp()
end

function monster:draw_hp()
    for i=0,self.hp - 1 do
        draw_sprite(
            9,
            self.tile.x + (i%3)*(5/16),
            self.tile.y - flr(i/3)*(5/16)
        )
    end
end

function monster:try_move(dx, dy)
    local new_tile = self.tile:get_neighbor(dx, dy)
    if(new_tile.passable) then
        if(new_tile.monster == nil) then
            self:move(new_tile)
        else
            if (self.is_player ~= new_tile.monster.is_player) then
                new_tile.monster:hit(1);
            end
        end
        return true
    end
    return false
end


function monster:hit(damage)
    self.hp -= damage
    if(self.hp <= 0) then
        self:die()
    end
end

function monster:die()
    self.dead = true
    self.tile.monster = nil
    self.sprite = 1
end

function monster:move(tile)
    if(self.tile ~= nil) then
        self.tile.monster = nil
    end
    self.tile = tile
    tile.monster = self
end

player_class = monster:new({})

function player_class:new(tile)
    local player = monster.new(self, tile, 0, 3)

    player.is_player = true

    return player
end

function player_class:try_move(dx, dy)
    if (monster.try_move(self, dx,dy)) then
        tick()
    end
end

bird = monster:new({})

function bird:new(tile)
    return monster.new(self, tile, 4, 3)
end

snake = monster:new({})

function snake:new(tile)
    return monster.new(self, tile, 5, 1)
end

tank = monster:new({})

function tank:new(tile)
    return monster.new(self, tile, 6, 2)
end

eater = monster:new({})

function eater:new(tile)
    return monster.new(self, tile, 7, 1)
end

jester = monster:new({})

function jester:new(tile)
    return monster.new(self, tile, 8, 2)
end

-->8

--
-- util
--

function try_to(description, callback)
    for timeout=1000, 0, -1 do
        if(callback()) then
            return
        end
    end
    assert(false, "timeout while trying to "..description)
end

function filter(tbl, predicate)
    local output = {}

    for i=1,#tbl do
        local v = tbl[i]
        if (predicate(v)) then
            add(output, v)
        end
    end

    return output
end

function pop(tbl)
    local len = #tbl
    local v = tbl[len]
    tbl[len] = nil
    return v
end

function concat(t1, t2)
    local output = {}

    local len1 = #t1
    for i=1,len1 do
        output[i] = t1[i]
    end

    for i=1,#t2 do
        output[len1 + i] = t2[i]
    end

    return output
end

function contains(tbl, elem)
    for e in all(tbl) do
        if (e == elem) return true
    end
    return false
end

function shuffle(arr)
    for i=1, #arr do
        local r = flr(rnd(i)) + 1
        arr[i], arr[r] = arr[r], arr[i]
    end
    return arr;
end

-- https://www.lexaloffle.com/bbs/?pid=43636
-- converts anything to string, even nested tables
-- (max_depth added by ryan1729)
function tostring(any, max_depth)
  max_depth = max_depth or 16
  if (type(any)~="table" or max_depth <= 0) return tostr(any)
  local str = "{"
  for k,v in pairs(any) do
    if (str~="{") str=str..","
    str=str..tostring(k, max_depth - 1).."="..tostring(v, max_depth - 1)
  end
  return str.."}"
end

-- https://www.lexaloffle.com/bbs/?pid=50555#p
-- chosen for brevity
function sort(a,cmp)
  for i=1,#a do
    local j = i
    while j > 1 and cmp(a[j-1],a[j]) do
        a[j],a[j-1] = a[j-1],a[j]
        j = j - 1
    end
  end
end

-->8

--
-- spell
--

-->8

--
-- main
--

numTiles=9
tilesize=16
level=1

function _init()
  palt(0, false)
  palt(15, true)

  generate_level()

  player = player_class:new(random_passable_tile())
end

function _draw()
    cls(13)

    for i=0,numTiles do
        for j=0,numTiles do
            get_tile(i, j):draw()
        end
    end

    for i=1,#monsters do
        monsters[i]:draw()
    end

    player:draw()
end

function tick()
    for k=#monsters,1,-1 do
        if(not monsters[k].dead) then
            monsters[k]:update()
        else
            del(monsters, monsters[k])
        end
    end
end

function _update()
  if (btnp(0)) player:try_move(-1, 0)
  if (btnp(1)) player:try_move(1, 0)
  if (btnp(2)) player:try_move(0, -1)
  if (btnp(3)) player:try_move(0, 1)
end

__gfx__
ffffffffffffffffffffffffffffffff11111111111111111133333333333311fffffffffffffffffffffffffffffffffffffffffffffffffddffddfffffffff
fffffbffbfff4fffffffffffffffffff11111111111111111333333333333331ffffffffffffffffffffddd666ffffffffffffffcccccfffd555555ddfffffff
fffffbbbbbfff4ffffffffffffffffff11111111111111113333333333333333ffffffffffffffffffffddddd6666ffffcccfffcdddddcff55555555dddddfff
fffffbfbfb3ff44fffffffffffffffff11111111111111113333333333333333fffeeeffffffffffff6ddd66fbfb66fffcddcccddc66cdcf55ddd555dd55dddf
fbbffbbbb33fff4fffffffffffffffff11111111111111113333333333333333666ef8efffffffffff66dd66fffffffffcdcdcddc6ddcdcf5d111d555d575ddf
fbbfff33333fff4ffffbb3bbbbbbbb3311111111111111113333333333333333f6688eeffffffffff666ffd6fbfbffffffcd6cdcdddcd6cfff5111dd55555d5f
ff3334433444ff4fffbbbb3bbbbbbbb311111111111111113333333333333333fff8888efffffffe6666fffd66666fffffcdcdddddddccfffff51111d555dd5d
ffffff4444433bbffbb033343333333411111111111111113333333333333333fff8eeeeeffffeef666fffffdd6ffff6ffcdddcddcddcfffffff51111dd5555d
ffffff34443ffbbff83bb83b4333334411111111111111113333333333333333fff88eeeeeeee8ff666ffbffffffff6ffccdddcddcddcfffffff5111111dd555
fffffbb343bfff4f88303833b43bb33311111111111111113333333333333333fff8e8ee8eee8fffd66666fffffff6dffcddddddddddcffffff51111111111d5
fffffbbb3bbfff4f833338883b33bbb411111111111111113333333333333333fff888e8e8e8ffffd66fffffff6bf6fffcdd6ddddd6d6fffff5111111111dd55
fffffbb33bbff4ff883388883b888f4411111111111111113333333333333333ffff8888e88fffffd666ff6bff6ff6ffffcdc6ddd6dcfffff511111111dd555f
fffffb3333bfffff88b888888388fff411111111111111113333333333333333fffff88888ffffffdd66ff6fff6f6dffffcddc66cdd6fffff5111111dd55555f
fffffb3333bbfffffb888ffff33fffff11111111111111113333333333333333fffff6fff6fffffffdd6666fff666ffffffcdddddd6ffffff5d111dd555555ff
ffff4433344bffff3bffff444334444f11111111111111111333333333333331fffff6fff6ffffffffdd66666666dfffffffccc666fffffff55ddd555fffffff
fff444333444ffff33ff44fffffffff411111111111111111133333333333311ffff6fff6ffffffffffdddd666ddffffffffffffffffffffff55555fffffffff
fffffeeeeeddffffffffffffffffffffffffffffff1111ff1111177777711111ffffffffffffffffff33ffff3fff33fff008888000f0f0ffffffffffffffffff
ffeeeee66eeeedfffffffffffffffffffffffffff11bb11f1111700000077771fffffffffffffffff3113ffffff3113f0888998880000f0fffffffffffffffff
fefdee6666dddedfffffffffffffffff111f111111b11b1f117700000a000007ffffffffffffffff31bb13fbff31bb1308999999888800f0ffffffffffffffff
efffd556655dffefffffffffffffffff1b111bbbbbb1111f170000aa00000a07ffffffff5fffffff31bb13ffff31bb13889aaaa99998880fffffffffffffffff
ffffd56ee65dffdfffffffffffffffffb111b111111b111f170a00aa00aa0007fffffff595fffffff3113ff33ff3113f899a77aaaa9998007777ffffffffffff
ffffd56ee65dfdffffffffffffffffffb11b11bbbb11b11f1700000000aa0071ffffff59d95fffffff33ff3113ff33ff899a77777aaa988078877fffffffffff
ffffdd5665ddffffffffffffffffffff1bb11b1111b11b1f1700a00000000771fffff59ddd95ffff3ffff31bb13ffff3889aa777777a998087e8777777777777
fffffdd55dddffffffffffffffffffff11b1b11bb11b1b1f17000000a0000007ffff59dd7dd95ffffff3f31bb13ffbff0899a777777a9980e7788e77e88e7788
fffffdddddddfffffffffffffffffffff1b1b11b11b11b1f700aa00000000a07ffff59d7eed95ffffbffff3113fffffff889a7777aaa98807777788e8788e8e7
fffffddedddffffdfffffffffffffffff1b1b11bbb11b11f700aa00a00000007ffff59dee7d95ffffff33ff33ff33ff30089a7777a99980fffff77e8777e8877
ffdfffdedddfffddf0000ffffffffffff1b11b11111b11117000000000aa0071ffff59dd7dd95fffff3113ffff3113fff089aa77aa988800fffff7777f77777f
fdefffdedddfffdf008200fffffffffff11b11bbbbb11bb1700000a000aa0071fffff59ddd95fffff31bb13ff31bb13f00899a77a998000fffffffffffffffff
deffffeeddefffdf087820ffffffffffff11b1111111b11b1777000000000071ffffff59d95ffffff31bb13ff31bb13ff0889aaaa98800ffffffffffffffffff
eefffeeefdeffedf088820fffffffffff1111bbbbbbb111b111700000a00a071fffffff595ffffffff3113ffff3113ff0f08999999800f0fffffffffffffffff
deeeeeefffdeeddf002200fffffffffff1b11b11111111b11117007700000071ffffffff5fffffff3ff33fffbff33ffff0f888998880f0ffffffffffffffffff
fdddddffffffddfff0000ffffffffffff11bb11ffffff1111111771177777711ffffffffffffffffffffff3ffffffff3ff0f0888800f0fffffffffffffffffff
fffffff7e877ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffff77787ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffff77e87ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffff78877ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffff77877fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff778e7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff7e877ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff78e77ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff778e7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffff7787ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff77887ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff7e8e7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff78e77ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff78877ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff77e87ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffff7787ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
