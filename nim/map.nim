from random import rand

from game import no_ex
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

    proc generateTiles*(rng: var random.Rand): Tiles =
        var tiles: TilesArray
        for y in 0..<game.NumTiles:
            for x in 0..<game.NumTiles:
                let
                    i = y * game.NumTiles + x
                    xy = game.TileXY(x: game.TileX(x), y: game.TileY(y))

                tiles[i] = tile.newFloor(xy)
                
                if rand(rng, 1.0) < 0.3:
                    tiles[i] = tile.newWall(xy)
                else:
                    tiles[i] = tile.newFloor(xy)
                
        result = Tiles(tiles: tiles)
