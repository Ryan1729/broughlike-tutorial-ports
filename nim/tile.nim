from game import nil

type
  Kind* = enum
    Wall,
    Floor

  Tile* = object
    kind*: Kind
    x*: game.TileX
    y*: game.TileY
    
proc draw*(tile: Tile, platform: game.Platform) =
    let sprite = case tile.kind
    of Wall:
        game.SpriteIndex(3)
    of Floor:
        game.SpriteIndex(2)

    (platform.sprite)(
        sprite,
        tile.x,
        tile.y
    )
