from game import no_ex

type
  Kind* = enum
    Wall,
    Floor

  Tile* = object
    kind*: Kind
    xy*: game.TileXY

no_ex:
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
