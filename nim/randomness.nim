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

    proc shuffle* [T](rng: var r.Rand, arr: var openArray[T]) =
        r.shuffle(rng, arr)


template tryTo*(description: string, callback: untyped): TryToResult =
    var output = res.err(TryToResult, "Timeout while trying to " & description)

    for i in 0..1000 :
        if callback:
            output = res.ok(TryToResult)
            break

    output




