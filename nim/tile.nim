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

no_ex:
    func newWall*(xy: game.TileXY): Tile =
        (kind: Kind.Wall, xy: xy, monster: none(Monster))

    func newFloor*(xy: game.TileXY): Tile =
        (kind: Kind.Floor, xy: xy, monster: none(Monster))

    func newExit*(xy: game.TileXY): Tile =
        (kind: Kind.Exit, xy: xy, monster: none(Monster))
    
    proc draw*(tile: Tile, platform: game.Platform) =
        let sprite = case tile.kind
        of Wall:
            game.SpriteIndex(3)
        of Floor:
            game.SpriteIndex(2)
        of Exit:
            game.SpriteIndex(11)

        (platform.sprite)(
            sprite,
            tile.xy
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
