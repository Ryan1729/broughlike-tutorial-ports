from random as r import nil 

# I don't want any non-seeded randomness, so let's only use `random` in this
# module and not export the global rng versions of the functions.

# Silence warnings that happen if a module only uses the direct exports from
# the `random` module.

{.used.} 

export r.Rand
export r.initRand

proc rand01*(rng: var r.Rand): float =
    r.rand(rng, 1.0)

