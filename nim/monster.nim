from options import Option, isNone, get

from game import no_ex, TileXY

type
  HP* = distinct range[0..6]

proc `==`*(x, y: HP): bool =
  int(x) == int(y)

type
  Kind* = enum
    Player,
    Bird,
    Snake,
    Tank,
    Eater,
    Jester

  Monster* = tuple
    kind: Kind
    xy: game.TileXY
    hp: HP

no_ex:
    func newPlayer*(xy: game.TileXY): Monster =
        (kind: Kind.Player, xy: xy, hp: HP(3))

    func newBird*(xy: game.TileXY): Monster =
        (kind: Kind.Bird, xy: xy, hp: HP(3))

    func newSnake*(xy: game.TileXY): Monster =
        (kind: Kind.Snake, xy: xy, hp: HP(1))

    func newTank*(xy: game.TileXY): Monster =
        (kind: Kind.Tank, xy: xy, hp: HP(2))

    func newEater*(xy: game.TileXY): Monster =
        (kind: Kind.Eater, xy: xy, hp: HP(1))

    func newJester*(xy: game.TileXY): Monster =
        (kind: Kind.Jester, xy: xy, hp: HP(2))

    proc draw*(option: Option[Monster], platform: game.Platform) =
        if option.isNone:
            return
        let monster = option.get
        let sprite = case monster.kind
        of Player:
            game.SpriteIndex(0)
        of Bird:
            game.SpriteIndex(4)
        of Snake:
            game.SpriteIndex(5)
        of Tank:
            game.SpriteIndex(6)
        of Eater:
            game.SpriteIndex(7)
        of Jester:
            game.SpriteIndex(8)

        (platform.sprite)(
            sprite,
            monster.xy
        )

const NonPlayerMakers*: array[5, auto] = [
  newBird,
  newSnake,
  newTank,
  newEater,
  newJester
]



