from options import Option, isSome, get

from game import no_ex, Counter, dec, `<=`, Score
from randomness import nil
from map import getTile, removeMonster, updateMonster, spawnMonster
from monster import Monster, Kind, dead, isPlayer
from tile import Tile

type
  State* = tuple
    xy: game.TileXY
    tiles: map.Tiles
    rng: randomness.Rand
    level: game.LevelNum
    spawnCounter: Counter
    spawnRate: Counter
    score: Score

  AfterTick* = enum
    NoChange
    PlayerDied
no_ex:
    proc tick*(state: var State): AfterTick =
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

            if m.isPlayer:
                # We don't check if the player is dead here because the
                # player may only be killed after it is checked here.
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

        state.spawnCounter.dec
        if state.spawnCounter <= 0u64:
            state.rng.spawnMonster(state.tiles)
            state.spawnCounter = state.spawnRate
            state.spawnRate.dec
        

        var t: Tile = state.tiles.getTile(state.xy)

        if t.monster.isSome:
            if t.monster.get.dead:
                return AfterTick.PlayerDied

        AfterTick.NoChange
