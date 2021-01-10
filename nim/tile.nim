from options import Option, none, isSome

from game import no_ex, Shake, Counter, `<`
from monster import Monster

const EffectCounterMax = 255

type
  Kind* = enum
    Wall,
    Floor,
    Exit

  Effect* = tuple
    sprite: game.SpriteIndex
    counter: Counter

  Tile* = tuple
    kind: Kind
    xy: game.TileXY
    monster: Option[Monster]
    treasure: bool
    effect: Effect

no_ex:
    func newTile(kind: Kind, xy: game.TileXY): Tile =
        (kind: kind, xy: xy, monster: none(Monster), treasure: false, effect: (sprite: game.SpriteIndex(1), counter: Counter(0)))
    
    func newWall*(xy: game.TileXY): Tile =
        newTile(Kind.Wall, xy)

    func newFloor*(xy: game.TileXY): Tile =
        newTile(Kind.Floor, xy)

    func newExit*(xy: game.TileXY): Tile =
        newTile(Kind.Exit, xy)
    
    proc draw*(tile: var Tile, shake: Shake, platform: game.Platform) =
        let sprite = case tile.kind
        of Wall:
            game.SpriteIndex(3)
        of Floor:
            game.SpriteIndex(2)
        of Exit:
            game.SpriteIndex(11)

        let floatXY = (
            x: float(tile.xy.x),
            y: float(tile.xy.y)
        )
    
        (platform.spriteFloat)(
            shake,
            sprite,
            floatXY
        )

        if tile.treasure:
            (platform.spriteFloat)(
                shake,
                game.SpriteIndex(12),
                floatXY
            )

        if tile.effect.counter > 0:
            (platform.spriteFloat)(
                shake,
                tile.effect.sprite,
                floatXY,
                float(tile.effect.counter) / EffectCounterMax
            )
            tile.effect.counter.dec()
            
    proc setEffect*(tile: var Tile, sprite: game.SpriteIndex) =
        tile.effect = (sprite: sprite, counter: Counter(EffectCounterMax))

    func isPassable*(kind: Kind): bool =
        case kind
        of Wall:
            false
        else:
            true
        
    func isPassable*(t: Tile): bool =
        t.kind.isPassable

        
    func hasMonster*(t: Tile): bool =
            t.monster.isSome
