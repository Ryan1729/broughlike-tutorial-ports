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

no_ex:
    proc tick*(state: var State) =
        # We collect the monsters into a list so that we don't hit
        # the same monster twice in the iteration, in case it moves
        
        var monsters: seq[Monster] = newSeqOfCap[Monster](map.tileLen)
        
        for y in 0..<game.NumTiles:
            for x in 0..<game.NumTiles:
                let xy = (x: game.TileX(x), y: game.TileY(y))

                var t: Tile = state.tiles.getTile(xy)

                if t.monster.isSome:
                    monsters.add(
                        t.monster.get
                    )


        var k = monsters.len - 1
        while k >= 0:
            let m = monsters[k]

            if m.kind == Kind.Player:
                discard

            elif m.dead:
                state.tiles.removeMonster(m.xy)
            else:
                state.tiles.updateMonster(
                    m,
                    state.xy,
                    state.rng
                )

            k -= 1
