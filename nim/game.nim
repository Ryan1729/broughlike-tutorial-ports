import system
from macros import newTree

# no_ex: allow no exceptions
macro no_ex*(x: untyped): untyped =
    #echo "x = ", macros.tree_repr(x)

    for child in macros.items(x):
        let raisesPragma: system.NimNode = macros.nnkExprColonExpr.newTree(
            macros.newIdentNode("raises"),
            macros.nnkBracket.newTree()
        )

        macros.addPragma(child, raisesPragma)

    result = x

const tileSize*: int = 64
const NumTiles*: int = 9
const UIWidth*: int = 4

type SpriteIndex* = distinct range[0..16]

template unsignedAdditive(typ, base: typedesc) =
    no_ex:
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
    no_ex:
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


definePos(ScreenX, uint16)
definePos(ScreenY, uint16)
definePos(TileX, uint8)
definePos(TileY, uint8)

type TileXY* = tuple
    x: TileX
    y: TileY

type Platform* = object
    sprite*: proc(sprite: SpriteIndex, xy: TileXY) {.raises: [].}

type DeltaX* = enum DX0, DX1, DXm1
type DeltaY* = enum DY0, DY1, DYm1

proc `+` *(x: TileX, dx: DeltaX): TileX =
    case dx:
    of DX0:
        x
    of DX1:
        x + 1
    of DXm1:
        x - 1

proc `+` *(y: TileY, dy: DeltaY): TileY =
    case dy:
    of DY0:
        y
    of DY1:
        y + 1
    of DYm1:
        y - 1

type DeltaXY* = tuple
    x: DeltaX
    y: DeltaY


proc `+` *(txy: TileXY, dxy: DeltaXY): TileXY =
    (x: txy.x + dxy.x, y: txy.y + dxy.y)
