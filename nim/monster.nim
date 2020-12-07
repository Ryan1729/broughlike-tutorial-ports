from options import Option, isNone, get

from game import no_ex

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

no_ex:
    func newPlayer*(xy: game.TileXY): Monster =
        (kind: Kind.Player, xy: xy)
        
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
