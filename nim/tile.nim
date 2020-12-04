from game import no_ex

type
  Kind* = enum
    Wall,
    Floor

  Tile* = object
    kind*: Kind
    xy*: game.TileXY

no_ex:
    func newWall*(xy: game.TileXY): Tile =
        Tile(kind: Kind.Wall, xy: xy)

    func newFloor*(xy: game.TileXY): Tile =
        Tile(kind: Kind.Floor, xy: xy)
    
    proc draw*(tile: Tile, platform: game.Platform) =
        let sprite = case tile.kind
        of Wall:
            game.SpriteIndex(3)
        of Floor:
            game.SpriteIndex(2)

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
        # TODO once we store monsters
        false
        
