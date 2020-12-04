from game import no_ex, TileXY, TileX, TileY
from res import nil
from random as r import nil

export TileXY, TileX, TileY

# I don't want any non-seeded randomness, so let's only use `random` in this
# module and not export the global rng versions of the functions.

# Silence warnings that happen if a module only uses the direct exports from
# the `random` module.

{.used.} 

export r.Rand
export r.initRand

type TryToResult* = res.ult[void, string]

no_ex:
    proc rand01*(rng: var r.Rand): float =
        r.rand(rng, 1.0)

    proc randomRange*(rng: var r.Rand, min: Natural, max: Natural): int =
        r.rand(rng, max) + min

    proc randomTileXY*(rng: var r.Rand): TileXY =
        TileXY(
            x: TileX(randomRange(rng, 0, game.NumTiles - 1)),
            y: TileY(randomRange(rng, 0, game.NumTiles - 1)),
        )

    func tryTo*(description: string, callback: proc(): bool): TryToResult =
        for _ in 0..1000 :
            if callback():
                return res.ok(TryToResult)

        res.err(TryToResult, "Timeout while trying to " & description)




