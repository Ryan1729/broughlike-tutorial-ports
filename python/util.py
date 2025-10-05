
import random
import types

RNG = random.Random

def try_to(description: str, callback: types.FunctionType):
    for _ in range(1000):
        if (callback()):
            return
    raise RuntimeError("Timeout while trying to " + description)

def random_range(rng: RNG, min: int, max: int) -> int :
    return rng.randrange(min, max + 1)
