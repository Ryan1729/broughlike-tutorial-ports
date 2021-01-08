from math import nil
from options import Option, isNone, get

from game import no_ex, TileXY, HP, Counter, `<`, floatXY, Shake, Platform, SoundSpec

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
    offsetXY: floatXY
    hp: HP
    attackedThisTurn: bool
    stunned: bool
    teleportCounter: Counter

  Damage* = distinct range[1 .. int(high(HP))]

no_ex:
    func `-=`(hp: var HP, damage: Damage) =
        let newHp = int(hp) - int(damage)
        if newHp < int(low(HP)):
            hp = low(HP)
        else:
            hp = HP(newHp)

    func `+=`(hp: var HP, damage: Damage) =
        let newHp = int(hp) + int(damage)
        if newHp > int(high(HP)):
            hp = high(HP)
        else:
            hp = HP(newHp)
    func `+`*(hpIn: HP, damage: Damage): HP =
        var hp = hpIn
        hp += damage
        hp
    func `+`*(damage: Damage, hpIn: HP): HP =
        var hp = hpIn
        hp += damage
        hp

    func newMonster*(kind: Kind, xy: game.TileXY, hp: HP): Monster =
        (
            kind: kind,
            xy: xy,
            offsetXY: (x: 0.0, y: 0.0),
            hp: hp,
            attackedThisTurn: false,
            stunned: false,
            teleportCounter: Counter(2)
        )
    
    func newPlayer*(xy: game.TileXY, hp: HP): Monster =
        result = newMonster(Kind.Player, xy, hp)
        result.teleportCounter = Counter(0)

    func newBird*(xy: game.TileXY): Monster =
        newMonster(Kind.Bird, xy, HP(6))

    func newSnake*(xy: game.TileXY): Monster =
        newMonster(Kind.Snake, xy, HP(2))

    func newTank*(xy: game.TileXY): Monster =
        newMonster(Kind.Tank, xy, HP(4))

    func newEater*(xy: game.TileXY): Monster =
        newMonster(Kind.Eater, xy, HP(2))

    func newJester*(xy: game.TileXY): Monster =
        newMonster(Kind.Jester, xy, HP(4))

    func isPlayer*(m: Monster): bool =
        m.kind == Kind.Player

    func displayXY(monster: Monster): floatXY =
        (
            x: monster.offsetXY.x + float(monster.xy.x),
            y: monster.offsetXY.y + float(monster.xy.y)
        )

    proc hit*(
        monster: Monster,
        platform: Platform,
        damage: Damage
    ): Monster =
        var m = monster
        m.hp -= damage

        platform.sound(
            if m.isPlayer:
                game.SoundSpec.hit1
            else:
                game.SoundSpec.hit2
        )
        m

    func heal*(monster: Monster, damage: Damage): Monster =
        var m = monster
        m.hp += damage
        m

    func dead*(m: Monster): bool =
        int(m.hp) <= 1

    func markAttacked*(monster: Monster): Monster =
        var m = monster
        m.attackedThisTurn = true
        m

    func markStunned*(monster: Monster): Monster =
        var m = monster
        m.stunned = true
        m    

    func markUnstunned*(monster: Monster): Monster =
        var m = monster
        m.stunned = false
        m

    func withTeleportCounter*(monster: Monster, teleportCounter: Counter): Monster =
        var m = monster
        m.teleportCounter = teleportCounter
        m

    proc drawHp(platform: game.Platform, shake: Shake, hp: game.HP, xy: game.floatXY) =
        for i in 0..<(int(hp) div 2):
            (platform.spriteFloat)(
                shake,
                game.SpriteIndex(9),
                (
                    x: xy.x + float((i mod 3))*(5.0/16.0),
                    y: xy.y - math.floor(float(i div 3))*(5.0/16.0)
                )
            )

    proc draw*(option: var Option[Monster], shake: Shake, platform: game.Platform) =
        if option.isNone:
            return
        let floatXY = option.get.displayXY()
        
        if option.get.teleportCounter > 0:
            (platform.spriteFloat)(
                shake,
                game.SpriteIndex(10),
                floatXY
            )
            return
        
        let sprite = case option.get.kind
        of Player:
            if option.get.dead:
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

        (platform.spriteFloat)(
            shake,
            sprite,
            floatXY
        )

        platform.drawHp(shake, option.get.hp, floatXY)
        if option.get.offsetXY.x != 0.0 or option.get.offsetXY.y != 0.0:
            echo option.get.kind, " draw offsetXY: ", option.get.offsetXY
        option.get.offsetXY.x -= float(math.sgn(option.get.offsetXY.x))*(1.0/64.0)
        option.get.offsetXY.y -= float(math.sgn(option.get.offsetXY.y))*(1.0/64.0)


const NonPlayerMakers*: array[5, auto] = [
  newBird,
  newSnake,
  newTank,
  newEater,
  newJester
]



