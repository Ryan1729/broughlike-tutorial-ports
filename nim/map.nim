from randomness import rand01

from game import no_ex, `<`, `<=`
from tile import nil

const tileLen: int = game.NumTiles * game.NumTiles

type
    TilesArray = array[tileLen, tile.Tile]
    Tiles* = object
        tiles: TilesArray

no_ex:
    proc draw*(tiles: Tiles, platform: game.Platform) =
        for t in tiles.tiles:
            tile.draw(t, platform)

    func xyToI(xy: game.TileXY): int =
        int(xy.y) * game.NumTiles + int(xy.x)

    func inBounds(xy: game.TileXY): bool =
        let
            x = xy.x
            y = xy.y
        x > 0 and y > 0 and x < game.NumTiles - 1 and y < game.NumTiles - 1

    proc generateTiles*(rng: var randomness.Rand): Tiles =
        var tiles: TilesArray
        for y in 0..<game.NumTiles:
            for x in 0..<game.NumTiles:
                let
                    xy = game.TileXY(x: game.TileX(x), y: game.TileY(y))
                    i = xyToI(xy)

                tiles[i] = tile.newFloor(xy)
                
                if (not inBounds(xy)) or rand01(rng) < 0.3:
                    tiles[i] = tile.newWall(xy)
                else:
                    tiles[i] = tile.newFloor(xy)
                
        Tiles(tiles: tiles)

    func getTile*(tiles: Tiles, xy: game.TileXY): tile.Tile =
        if inBounds xy:
            tiles.tiles[xyToI(xy)]
        else:
            tile.newWall(xy)

