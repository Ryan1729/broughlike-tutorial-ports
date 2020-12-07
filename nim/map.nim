from options import some, none
from sequtils import filter, toSeq, any, concat

from randomness import rand01, tryTo, randomTileXY, shuffle, Rand
from res import ok, err
from game import no_ex, `<`, `<=`, TileXY, DeltaX, DeltaY, DeltaXY, `+`, `==`
from tile import Tile, isPassable, hasMonster
from monster import Monster

const tileLen: int = game.NumTiles * game.NumTiles

type
    Tiles* = array[tileLen, tile.Tile]

no_ex:
    proc draw*(tiles: Tiles, platform: game.Platform) =
        for t in tiles:
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
            tiles[xyToI(xy)]
        else:
            tile.newWall(xy)

    func getNeighbor(tiles: Tiles, txy: TileXY, dxy: DeltaXY): Tile =
        getTile(tiles, txy + dxy)
    

    func getAdjacentNeighbors(txy: TileXY, tiles: Tiles, rng: var Rand): array[4, Tile] =
        result = [
            tiles.getNeighbor(txy, (x: DX0, y: DYm1)),
            tiles.getNeighbor(txy, (x: DX0, y: DY1)),
            tiles.getNeighbor(txy, (x: DXm1, y: DY0)),
            tiles.getNeighbor(txy, (x: DX1, y: DY0))
        ]
        shuffle(rng, result)

    func getAdjacentPassableNeighbors(txy: TileXY, tiles: Tiles, rng: var Rand): seq[Tile] = 
        getAdjacentNeighbors(txy, tiles, rng).toSeq.filter(isPassable)

    func getConnectedTiles(til: Tile, tiles: Tiles, rng: var Rand): seq[Tile] =
        var connectedTiles = @[til]
        var frontier = @[til]
        while frontier.len > 0:
            let neighbors = frontier.pop
                                .xy
                                .getAdjacentPassableNeighbors(tiles, rng)
                                .filter(proc(t: Tile): bool =
                                    not connectedTiles.any(proc(ct: Tile): bool = ct == t))
            connectedTiles = connectedTiles.concat(neighbors)
            frontier = frontier.concat(neighbors)

        connectedTiles

    proc move*(tiles: var Tiles, monster: Monster, xy: TileXy) =
        tiles[xyToI(monster.xy)].monster = none(Monster)
        tiles[xyToI(xy)].monster = some(monster)

    proc tryMove*(tiles: var Tiles, monster: Monster, dxy: DeltaXY): bool =
        let newTile = tiles.getNeighbor(monster.xy, dxy)
        if newTile.isPassable:
            if not newTile.hasMonster:
                tiles.move(monster, newTile.xy)
            
            result = true


    proc generateTiles(rng: var Rand): tuple[tiles: Tiles, passableCount: int] =
        var tiles: Tiles
        var passableCount = 0
        for y in 0..<game.NumTiles:
            for x in 0..<game.NumTiles:
                let
                    xy = (x: game.TileX(x), y: game.TileY(y))
                    i = xyToI(xy)
                
                if (not inBounds(xy)) or rand01(rng) < 0.3:
                    tiles[i] = tile.newWall(xy)
                else:
                    passableCount += 1
                    tiles[i] = tile.newFloor(xy)
                
        (
            tiles,
            passableCount
        )

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
            let (tiles, passableCount) = generateTiles(rng)

            tilesRes = tiles.ok

            let tileRes = randomPassableTile(rng, tiles)
            case tileRes.isOk
            of true:
                passableCount == tileRes.value.getConnectedTiles(tiles, rng).len
            of false:
                false
            

        case r.isOk
        of true:
            tilesRes
        of false:
            err(r.error)
        
