import system
from macros import newTree
from options import some, none, Option, isSome, get

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
const numLevels: int = 6

type
    SpriteIndex* = distinct range[0..16]

    LevelNum* = distinct range[1..numLevels]

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
    proc `$`*(x: typ): string =
        $base(x)



definePos(ScreenX, uint16)
definePos(ScreenY, uint16)
definePos(TileX, uint8)
definePos(TileY, uint8)

type TileXY* = tuple
    x: TileX
    y: TileY


func dist*(source: TileXY, target: TileXY): int =
    abs(int(source.x)-int(target.x)) + abs(int(source.y)-int(target.y))


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


proc deltaXFrom(sourceX: TileX, targetX: TileX): Option[DeltaX] =
    let delta = int(targetX) - int(sourceX)
    if delta == -1:
        some(DXm1)

    elif delta == 0:
        some(DX0)

    elif delta == 1:
        some(DX1)

    else:
        none(DeltaX)

proc deltaYFrom(sourceY: TileY, targetY: TileY): Option[DeltaY] =
    let delta = int(targetY) - int(sourceY)
    if delta == -1:
        some(DYm1)

    elif delta == 0:
        some(DY0)

    elif delta == 1:
        some(DY1)

    else:
        none(DeltaY)

type ST = tuple[source: TileXY, target: TileXY]

# This returns the deltas from the `source` to the `target`, if both deltas exist.
# That is, if `source` is at 2, 1 and `target` is at 1, 2 then `Just (DXm1, DY1)` will be returned.
# As another example, if `source` is at 1, 2 and `target` is at 1, 1 then `Just (DX0, DYm1)` will be returned.

proc deltasFrom*(st: ST): Option[DeltaXY] =
    let deltaX = deltaXFrom(st.source.x, st.target.x)
    let deltaY = deltaYFrom(st.source.y, st.target.y)

    if deltaX.isSome and deltaY.isSome:
        some((x: deltaX.get, y: deltaY.get))
    else:
        none(DeltaXY)


