const tileSize*: int = 64
const NumTiles*: int = 9
const UIWidth*: int = 4

type SpriteIndex* = distinct uint8

template unsignedAdditive(typ, base: typedesc) =
    proc `+` *(x, y: typ): typ {.borrow.}
    proc `+` *(x: typ, y: base): typ {.borrow.}
    proc `+=` *(x: var typ, y: typ) {.borrow.}
    proc `+=` *(x: var typ, y: base) =
        x += typ(y)
    proc `+=` *(x: var base, y: typ) =
        x += base(y)

    proc `-` *(x, y: typ): typ {.borrow.}
    proc `-` *(x: typ, y: base): typ {.borrow.}
    proc `-=` *(x: var typ, y: typ) {.borrow.}
    proc `-=` *(x: var typ, y: base) =
        x -= typ(y)
    proc `-=` *(x: var base, y: typ) =
        x -= base(y)


template comparable(typ, base: typedesc) =
    proc `<`*(x, y: typ): bool {.borrow.}
    proc `<`*(x: typ, y: base): bool {.borrow.}
    proc `<`*(x: base, y: typ): bool {.borrow.}
    proc `<=`*(x, y: typ): bool {.borrow.}
    proc `<=`*(x: typ, y: base): bool {.borrow.}
    proc `<=`*(x: base, y: typ): bool {.borrow.}
    proc `==`*(x, y: typ): bool {.borrow.}
    proc `==`*(x: typ, y: base): bool {.borrow.}
    proc `==`*(x: base, y: typ): bool {.borrow.}

template definePos(typ, base: untyped) =
    type
        typ* = distinct base
    unsignedAdditive(typ, base)
    comparable(typ, base)


definePos(ScreenPos, uint16)
definePos(TilePos, uint8)
