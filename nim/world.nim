from options import Option, isSome, get

from game import no_ex
from randomness import nil
from map import getTile, removeMonster, updateMonster
from monster import Monster, Kind, dead
from tile import Tile

type
  State* = tuple
    xy: game.TileXY
    tiles: map.Tiles
    rng: randomness.Rand
    level: game.LevelNum
    
  TileAndMonster = tuple[tile: Tile, monster: Monster]

no_ex:
    proc getPairsSeq(): seq[TileAndMonster] =
        newSeqOfCap[TileAndMonster](map.tileLen)


no_ex:
    proc tick*(state: var State) =
        # We collect the tile, monster pairs into a list so that we don't hit
        # the same monster twice in the iteration, in case it moves
        
        var pairs: seq[TileAndMonster] = getPairsSeq()
        
        for y in 0..<game.NumTiles:
            for x in 0..<game.NumTiles:
                let xy = (x: game.TileX(x), y: game.TileY(y))

                var t: Tile = state.tiles.getTile(xy)

                if t.monster.isSome:
                    var pair: TileAndMonster = (tile: t, monster: t.monster.get)
                    add[TileAndMonster](
                        pairs,
                        pair
                    )


        var k = pairs.len - 1
        while k >= 0:
            var tile = pairs[k].tile
            let m = pairs[k].monster

            if m.kind == Kind.Player:
                continue

            elif m.dead:
                state.tiles.removeMonster(m.xy)
            else:
                state.tiles.updateMonster(
                    m,
                    state.xy,
                    state.rng
                )
            
            k -= 1


