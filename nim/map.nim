from sequtils import filter, toSeq, any, concat

from randomness import rand01, tryTo, randomTileXY, shuffle, Rand
from res import ok, err
from game import no_ex, `<`, `<=`, DeltaX, DeltaY, DeltaXY, `+`, `==`
from tile import Tile, isPassable, hasMonster

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

    func getTile*(tiles: Tiles, xy: game.TileXY): Tile =
        if inBounds xy:
            tiles.tiles[xyToI(xy)]
        else:
            tile.newWall(xy)

    func getNeighbor(tiles: Tiles, t: Tile, dxy: DeltaXY): Tile =
        getTile(tiles, t.xy + dxy)
    

    func getAdjacentNeighbors(t: Tile, tiles: Tiles, rng: var Rand): array[4, Tile] =
        result = [
            tiles.getNeighbor(t, DeltaXY(x: DX0, y: DYm1)),
            tiles.getNeighbor(t, DeltaXY(x: DX0, y: DY1)),
            tiles.getNeighbor(t, DeltaXY(x: DXm1, y: DY0)),
            tiles.getNeighbor(t, DeltaXY(x: DX1, y: DY0))
        ]
        shuffle(rng, result)

    func getAdjacentPassableNeighbors(t: Tile, tiles: Tiles, rng: var Rand): seq[Tile] = 
        getAdjacentNeighbors(t, tiles, rng).toSeq.filter(isPassable)

    func getConnectedTiles(til: Tile, tiles: Tiles, rng: var Rand): seq[Tile] =
        var connectedTiles = @[til]
        var frontier = @[til]
        while frontier.len > 0:
            let neighbors = frontier.pop
                                .getAdjacentPassableNeighbors(tiles, rng)
                                .filter(proc(t: Tile): bool =
                                    not connectedTiles.any(proc(ct: Tile): bool = ct == t))
            connectedTiles = connectedTiles.concat(neighbors)
            frontier = frontier.concat(neighbors)

        connectedTiles

    proc generateTiles(rng: var Rand): Tiles =
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

type TileResult = res.ult[tile.Tile, string]

no_ex:
    func randomPassableTile*(rng: var randomness.Rand, tiles: Tiles): TileResult =
        var t = err(TileResult, "t was never written to")

        let r = tryTo("get random passable tile"):
            let tile = tiles.getTile(rng.randomTileXY)
            t = ok(TileResult, tile)
            tile.isPassable and not tile.hasMonster

        case r.isOk
        of true:
            t
        of false:
            err(r.error)

type TilesResult = res.ult[Tiles, string]

no_ex:
    proc generateLevel*(rng: var randomness.Rand): TilesResult =
        var tilesRes = err(TilesResult, "tiles was never written to")
        let r = tryTo("generate map"):
            let tiles = generateTiles(rng)

            tilesRes = tiles.ok

            let tileRes = randomPassableTile(rng, tiles)
            case tileRes.isOk
            of true:
                tiles.tiles.len == tileRes.value.getConnectedTiles(tiles, rng).len
            of false:
                false
            

        case r.isOk
        of true:
            tilesRes
        of false:
            err(r.error)     
        
