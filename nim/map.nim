from algorithm import sort
from options import Option, some, isSome, none, isNone, get
from sequtils import filter, toSeq, any, concat

from randomness import rand01, tryTo, randomTileXY, shuffle, Rand
from res import ok, err
from game import no_ex, `<`, `<=`, TileXY, DeltaX, DeltaY, DeltaXY, `+`, `==`, LevelNum, dist, dec, `-`, floatXY, `$`, Counter, Shake, Platform
from tile import Tile, isPassable, hasMonster
from monster import Monster, Kind, hit, Damage, markAttacked, markStunned, markUnstunned, heal, withTeleportCounter, isPlayer, draw

const tileLen*: int = game.NumTiles * game.NumTiles

type
    Tiles* = array[tileLen, tile.Tile]

no_ex:
    proc draw*(tiles: var Tiles, shake: Shake, platform: Platform) =
        for i in 0..<tileLen:
            tile.draw(tiles[i], shake, platform)

        for i in 0..<tileLen:
            tiles[i].monster.draw(shake, platform)

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

    func getNeighbor*(tiles: Tiles, txy: TileXY, dxy: DeltaXY): Tile =
        getTile(tiles, txy + dxy)

    func getAdjacentNeighbors*(txy: TileXY, tiles: Tiles, rng: var Rand): array[4, Tile] =
        result = [
            tiles.getNeighbor(txy, (x: DX0, y: DYm1)),
            tiles.getNeighbor(txy, (x: DX0, y: DY1)),
            tiles.getNeighbor(txy, (x: DXm1, y: DY0)),
            tiles.getNeighbor(txy, (x: DX1, y: DY0))
        ]
        shuffle(rng, result)

    func getAdjacentPassableNeighbors*(txy: TileXY, tiles: Tiles, rng: var Rand): seq[Tile] =
        getAdjacentNeighbors(txy, tiles, rng).toSeq.filter(isPassable)

    func getConnectedTiles(til: Tile, tiles: Tiles, rng: var Rand): seq[Tile] =
        var connectedTiles = @[til]
        var frontier = @[til]
        while frontier.len > 0:
            let neighbors = frontier.pop
                                .xy
                                .getAdjacentPassableNeighbors(tiles, rng)
                                .filter(proc(t: Tile): bool =
                                    not connectedTiles.any(proc(ct: Tile): bool = ct.xy == t.xy)
                                )
            connectedTiles = connectedTiles.concat(neighbors)
            frontier = frontier.concat(neighbors)

        connectedTiles

    proc replace*(
        tiles: var Tiles,
        xy: TileXY,
        maker: proc (xy: game.TileXY): Tile
    ) =
        if inBounds(xy):
            tiles[xyToI(xy)] = maker(xy)

    proc removeMonster*(tiles: var Tiles, xy: TileXY) =
        tiles[xyToI(xy)].monster = none(Monster)

    proc setMonster*(tiles: var Tiles, monster: Monster) =
        tiles[xyToI(monster.xy)].monster = some(monster)

    proc setEffect*(tiles: var Tiles, xy: TileXY, sprite: game.SpriteIndex) =
        tile.setEffect(tiles[xyToI(xy)], sprite)

    proc moveWithOffsetXY(tiles: var Tiles, monster: Monster, xy: TileXy, offsetXY: floatXY): Monster =
        tiles.removeMonster(monster.xy)

        var moved = monster
        
        if moved.xy != xy:
            moved.offsetXY = offsetXY
            moved.xy = xy
        
        tiles.setMonster(moved)

        moved

    proc move*(tiles: var Tiles, monster: Monster, xy: TileXy): Monster =
        moveWithOffsetXY(
            tiles,
            monster,
            xy,
            (
                x: float(monster.xy.x) - float(xy.x),
                y: float(monster.xy.y) - float(xy.y)
            )
        )

    proc tryMove*(
        tiles: var Tiles,
        shake: var Shake,
        platform: game.Platform,
        monster: Monster,
        dxy: DeltaXY
    ): Option[Monster] =
        let newTile = tiles.getNeighbor(monster.xy, dxy)
        if newTile.isPassable:
            if not newTile.hasMonster:
                let moved = tiles.move(monster, newTile.xy)
                return some(moved)
            else:
                if (monster.isPlayer) != (newTile.monster.get.isPlayer):
                    shake.amount = Counter(5)

                    var m = monster.markAttacked()

                    let moved = tiles.moveWithOffsetXY(
                        m,
                        m.xy,
                        (
                            x: (float(newTile.xy.x) - float(m.xy.x))/2,
                            y: (float(newTile.xy.y) - float(m.xy.y))/2
                        )
                    )

                    tiles.setMonster(
                        newTile.monster.get.markStunned.hit(platform, Damage(2))
                    )

                    return some(moved)

                return some(monster)

        none(Monster)

    proc plainDoStuff(
        tiles: var Tiles,
        shake: var Shake,
        platform: Platform,
        monster: Monster,
        playerXY: TileXY,
        rng: var Rand
    ): Monster =
        var neighbors: seq[Tile] = getAdjacentPassableNeighbors(
            monster.xy,
            tiles,
            rng
        )

        neighbors = neighbors.filter(
            proc (t: Tile): bool =
                t.monster.isNone or t.monster.get.isPlayer
        )
        if neighbors.len > 0:
            let distCmp = proc (a, b: Tile): int =
              a.xy.dist(playerXY) - b.xy.dist(playerXY)

            sort(neighbors, distCmp)

            let deltas = game.deltasFrom(
                (source: monster.xy, target: neighbors[0].xy)
            )

            if deltas.isNone:
                # The player genrally won't mind if a monster doesn't move.
                return monster

            let option = tiles.tryMove(
                shake,
                platform,
                monster,
                deltas.get
            )

            if option.isSome:
                return option.get

        monster

    proc doStuff(
        tiles: var Tiles,
        shake: var Shake,
        platform: Platform,
        monster: Monster,
        playerXY: TileXY,
        rng: var Rand
    ): Monster =
        var m = monster
        discard monster

        case m.kind
        of Kind.Bird, Kind.Tank:
            plainDoStuff(
                tiles,
                shake,
                platform,
                monster,
                playerXY,
                rng
            )
        of Kind.Snake:
            m.attackedThisTurn = false

            tiles.setMonster(
                m
            )

            m = plainDoStuff(
                tiles,
                shake,
                platform,
                m,
                playerXY,
                rng
            )

            if not m.attackedThisTurn:
                plainDoStuff(
                    tiles,
                    shake,
                    platform,
                    m,
                    playerXY,
                    rng
                )
            else:
                m
        of Kind.Eater:
            let neighbors = monster.xy.getAdjacentNeighbors(tiles, rng)
                .filter(
                    proc (t: Tile): bool =
                        (not t.isPassable) and t.xy.inBounds
                )
            if neighbors.len > 0:
                tiles.replace(neighbors[0].xy, tile.newFloor)
                m = m.heal(Damage(1))

                tiles.setMonster(
                    m
                )
                
                m
            else:
                plainDoStuff(
                    tiles,
                    shake,
                    platform,
                    m,
                    playerXY,
                    rng
                )
        of Kind.Jester:
            let neighbors = monster.xy.getAdjacentPassableNeighbors(tiles, rng)
            if neighbors.len > 0:
                let deltas = game.deltasFrom(
                    (source: monster.xy, target: neighbors[0].xy)
                )

                if deltas.isNone:
                    # The player genrally won't mind if a monster doesn't move.
                    return monster

                let option = tiles.tryMove(
                    shake,
                    platform,
                    monster,
                    deltas.get
                )

                if option.isSome:
                    return option.get
        
            monster

        of Kind.Player:
            # This should not happen
            monster
            

    proc plainUpdateMonster(
        tiles: var Tiles,
        shake: var Shake,
        platform: Platform,
        monsterIn: Monster,
        playerXY: TileXY,
        rng: var Rand
    ): Monster =
        var m = monsterIn
        m.teleportCounter.dec
        tiles.setMonster(
            m
        )
        
        if m.stunned or m.teleportCounter > 0:
            m = m.markUnstunned
            tiles.setMonster(
                m
            )
            
            return m
        
        doStuff(tiles, shake, platform, m, playerXY, rng)

    proc updateMonster*(
        tiles: var Tiles,
        shake: var Shake,
        platform: Platform,
        monster: Monster,
        playerXY: TileXY,
        rng: var Rand
    ) =
        case monster.kind
        of Kind.Tank:        
            let startedStunned = monster.stunned
            let moved = plainUpdateMonster(tiles, shake, platform, monster, playerXY, rng)

            if not startedStunned:
                tiles.setMonster(
                    moved.markStunned
                )

        else:
            discard plainUpdateMonster(tiles, shake, platform, monster, playerXY, rng)

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

    proc spawnMonster*(rng: var randomness.Rand, tiles: var Tiles) =
        var monsterMakers = monster.NonPlayerMakers
        rng.shuffle(monsterMakers)

        let tileRes = rng.randomPassableTile(tiles)
        case tileRes.isOk:
        of true:
            let monster = monsterMakers[0](tileRes.value.xy)
            tiles.setMonster(monster)
        of false:
            # The player won't mind if a monter doesn't spawn because it
            # doesn't fit.
            discard

    proc generateMonsters(rng: var randomness.Rand, tiles: var Tiles, level: LevelNum) =
        for _ in 0..int(level):
            rng.spawnMonster(tiles)

    proc setTreasure*(tiles: var Tiles, xy: game.TileXY, isTreasure: bool) =
        tiles[xyToI(xy)].treasure = isTreasure

    proc generateTreasure(rng: var randomness.Rand, tiles: var Tiles) =
        for _ in 0..<3:
            let tileRes = rng.randomPassableTile(tiles)

            case tileRes.isOk:
            of true:
                tiles.setTreasure(tileRes.value.xy, true)
            of false:
                # The player would presumably prefer being able to play a
                # level missing traeasure, than a crash, etc.
                discard

type TilesResult = res.ult[Tiles, string]

{.push warning[ProveField]: off.}
no_ex:
    proc generateMonstersTreasureTilesResult(rng: var randomness.Rand, tilesRes: var TilesResult, level: LevelNum) =
        case tilesRes.isOk
        of true:
            rng.generateMonsters(tilesRes.value, level)

            rng.generateTreasure(tilesRes.value)
        of false:
            discard
{.pop.}

no_ex:
    proc generateLevel*(rng: var randomness.Rand, level: LevelNum): TilesResult =
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
            rng.generateMonstersTreasureTilesResult(tilesRes, level)
            
            tilesRes
        of false:
            err(r.error)

