from options import Option, isSome, get

from game import no_ex
from randomness import nil
from map import getTile
from monster import Monster
from tile import Tile

type
  State* = tuple
    xy: game.TileXY
    tiles: map.Tiles
    rng: randomness.Rand
    level: game.LevelNum
    
  TileAndMonster = tuple[tile: ref Tile, monster: Monster]

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

                # will getTileRef work with the return a fresh wall thing?
                var t: ref Tile = state.tiles.getTileRef(xy)

                if t.monster.isSome:
                    var pair: TileAndMonster = (tile: t, monster: t.monster.get)
                    add[TileAndMonster](
                        pairs,
                        pair
                    )


        var k = pairs.len - 1
        while k >= 0:
            var tile = pairs[k].tile
            let monster = pairs[k].monster

            if monster.kind == Kind.Player:
                continue

            elif m.dead:
                tile.monster = none(Monster)
                
            else:
                state.tiles.updateMonster(
                    monster: Monster,
                    state.player,
                    state.rng
                )
            
            k -= 1


