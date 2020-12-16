from options import Option, isNone, get

from game import no_ex, TileXY, HP

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
    attackedThisTurn: bool
    stunned: bool

  Damage* = distinct range[1 .. int(high(HP))]

no_ex:
    func `-=`(hp: var HP, damage: Damage) {.borrow.}

    func newMonster*(kind: Kind, xy: game.TileXY, hp: HP): Monster =
        (kind: kind, xy: xy, hp: hp, attackedThisTurn: false, stunned: false)
    
    func newPlayer*(xy: game.TileXY): Monster =
        newMonster(Kind.Player, xy, HP(3))

    func newBird*(xy: game.TileXY): Monster =
        newMonster(Kind.Bird, xy, HP(3))

    func newSnake*(xy: game.TileXY): Monster =
        newMonster(Kind.Snake, xy, HP(1))

    func newTank*(xy: game.TileXY): Monster =
        newMonster(Kind.Tank, xy, HP(2))

    func newEater*(xy: game.TileXY): Monster =
        newMonster(Kind.Eater, xy, HP(1))

    func newJester*(xy: game.TileXY): Monster =
        newMonster(Kind.Jester, xy, HP(2))

    func hit*(monster: Monster, damage: Damage): Monster =
        var m = monster
        m.hp -= damage
        m

    func dead*(m: Monster): bool =
        int(m.hp) <= 0

    proc draw*(option: Option[Monster], platform: game.Platform) =
        if option.isNone:
            return
        let monster = option.get
        let sprite = case monster.kind
        of Player:
            if monster.dead:
                game.SpriteIndex(1)
            else:
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

        (platform.hp)(monster.hp, monster.xy)

const NonPlayerMakers*: array[5, auto] = [
  newBird,
  newSnake,
  newTank,
  newEater,
  newJester
]



