
import random
import types
from typing import TypeVar

T = TypeVar('T')

RNG = random.Random

def try_to(description: str, callback: types.FunctionType):
    for _ in range(1000):
        if (callback()):
            return
    raise RuntimeError("Timeout while trying to " + description)

def random_range(rng: RNG, min: int, max: int) -> int :
    return rng.randrange(min, max + 1)
    
def shuffle(rng: RNG, arr: list[T]) -> list[T]:
    temp = None
    r = 0

    for i in range(1, len(arr)):
        r = random_range(rng, 0, i);
        temp = arr[i];
        arr[i] = arr[r];
        arr[r] = temp;

    return arr;
