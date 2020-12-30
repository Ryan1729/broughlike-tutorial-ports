from options import Option, none, isSome

from game import no_ex
from monster import Monster

type
  Kind* = enum
    Wall,
    Floor,
    Exit

  Tile* = tuple
    kind: Kind
    xy: game.TileXY
    monster: Option[Monster]
    treasure: bool

no_ex:
    func newTile(kind: Kind, xy: game.TileXY): Tile =
        (kind: kind, xy: xy, monster: none(Monster), treasure: false)
    
    func newWall*(xy: game.TileXY): Tile =
        newTile(Kind.Wall, xy)

    func newFloor*(xy: game.TileXY): Tile =
        newTile(Kind.Floor, xy)

    func newExit*(xy: game.TileXY): Tile =
        newTile(Kind.Exit, xy)
    
    proc draw*(tile: Tile, platform: game.Platform) =
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
            sprite,
            floatXY
        )

        if tile.treasure:
            (platform.spriteFloat)(
                game.SpriteIndex(12),
                floatXY
            )

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
