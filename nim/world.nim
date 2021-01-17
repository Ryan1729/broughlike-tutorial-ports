from options import Option, isSome, isNone, get, some, none

from game import no_ex, Counter, dec, `<=`, Score, Shake, Platform, DeltaXY
from randomness import shuffle
from map import getTile, removeMonster, updateMonster, spawnMonster, randomPassableTile, move, setMonster, getAdjacentNeighbors, setEffect, getNeighbor, replace, setTreasure
from monster import Monster, Kind, dead, isPlayer, hit, Damage, heal, markStunned
from tile import Tile, isPassable

const maxNumSpellsInt: int = 9

type
    SpellName* = enum
        WOOP
        QUAKE
        MAELSTROM
        MULLIGAN
        AURA
        DASH
        DIG
        KINGMAKER
        ALCHEMY
        POWER
        BUBBLE
        BRAVERY
        BOLT
        CROSS
        EX

no_ex:
    func allSpellNames*(): seq[SpellName] =
        result = newSeqOfCap[SpellName](ord(high(SpellName)) + 1)
        for sn in low(SpellName)..high(SpellName):
            add(result, sn)

type
    SpellBook* = array[maxNumSpellsInt, Option[SpellName]]

    SpellCount* = range[1..maxNumSpellsInt]

    SpellPage* = distinct range[0..maxNumSpellsInt - 1]

proc `<=`*(x, y: SpellPage): bool =
    int(x) == int(y)

const maxNumSpells*: SpellCount = SpellCount(maxNumSpellsInt)

type
    State* = tuple
        xy: game.TileXY
        tiles: map.Tiles
        rng: randomness.Rand
        level: game.LevelNum
        spawnCounter: Counter
        spawnRate: Counter
        score: Score
        shake: Shake
        spells: SpellBook
        numSpells: SpellCount
        lastMove: DeltaXY
        bonusAttack: Option[Damage]
        shield: Counter

type
    PostSpellKind* = enum
        AllEffectsHandled
        PlayerMoved
        StartLevel

    PostSpell* = object
        case kind*: PostSpellKind
        of PostSpellKind.PlayerMoved:
            player*: Monster
        of PostSpellKind.AllEffectsHandled, PostSpellKind.StartLevel:
            discard

no_ex:
    func allEffectsHandled(): PostSpell =
        PostSpell(kind: PostSpellKind.AllEffectsHandled)

    func playerMoved(player: Monster): PostSpell =
        PostSpell(kind: PostSpellKind.PlayerMoved, player: player)

type
    Spell = proc(state: var State, platform: Platform): PostSpell {. raises: [] .}

    AfterTick* = enum
        NoChange
        PlayerDied

# When iterating monsters, We collect the monsters into a list
# so that we don't hit the same monster twice in the iteration,
# in case it moves
template getMonsters(state: State): seq[Monster] =
    var monsters: seq[Monster] = newSeqOfCap[Monster](map.tileLen)

    for y in 0..<game.NumTiles:
        for x in 0..<game.NumTiles:
            let xy = (x: game.TileX(x), y: game.TileY(y))

            var t: Tile = state.tiles.getTile(xy)

            if t.monster.isSome:
                monsters.add(
                    t.monster.get
                )

    monsters


no_ex:
    proc tick*(state: var State, platform: Platform): AfterTick =
        var monsters: seq[Monster] = getMonsters(state)

        var k = monsters.len - 1
        while k >= 0:
            let m = monsters[k]

            if m.isPlayer:
                # We don't check if the player is dead here because the
                # player may only be killed after it is checked here.
                discard

            elif m.dead:
                state.tiles.removeMonster(m.xy)
            else:
                state.tiles.updateMonster(
                    state.shake,
                    platform,
                    m,
                    state.xy,
                    state.rng
                )

            k -= 1

        state.shield.dec

        state.spawnCounter.dec
        if state.spawnCounter <= 0u64:
            state.rng.spawnMonster(state.tiles)
            state.spawnCounter = state.spawnRate
            state.spawnRate.dec

        var t: Tile = state.tiles.getTile(state.xy)

        if t.monster.isSome:
            if t.monster.get.dead:
                return AfterTick.PlayerDied

        AfterTick.NoChange


#
#  Spells
#

#  Spell helpers

template requirePlayer(spellName, playerName, stateName, platformName, spellBody: untyped) =
    proc spellName(stateName: var State, platformName: Platform): PostSpell {. raises: [] .} =
        let tile = stateName.tiles.getTile(stateName.xy)
        let monster = tile.monster
        if monster.isSome:
            let playerName = monster.get

            spellBody
        else:
            # If the player cannot be found now then presumably the
            # next time the player tries to move, the error message
            # will be shown
            allEffectsHandled()

no_ex:
    proc boltTravel(
        state: var State,
        platform: Platform,
        deltas: DeltaXY,
        effect: game.SpriteIndex,
        damage: Damage
    ) =
        var xy = state.xy;

        while true:
            let testTile = state.tiles.getNeighbor(xy, deltas)
            if testTile.isPassable:
                if xy == testTile.xy:
                    break

                xy = testTile.xy
                if testTile.monster.isSome:
                    state.tiles.setMonster(
                        testTile.monster.get.hit(platform, damage)
                    )

                state.tiles.setEffect(xy, effect)
            else:
                break


# The spells themselves

requirePlayer(woop, player, state, platform):
        let tileRes = state.rng.randomPassableTile(state.tiles)
        case tileRes.isOk:
        of true:
            playerMoved(state.tiles.move(player, tileRes.value.xy))
        of false:
            # If the player tries to teleport when there is no free space
            # I'm not sure what else they would expect to happen
            allEffectsHandled()
no_ex:
    proc quake(state: var State, platform: Platform): PostSpell =
        var monsters: seq[Monster] = getMonsters(state)
        for i in 0..<monsters.len:
            let monster = monsters[i]
            let numWalls = 4 - map.getAdjacentPassableNeighbors(
                monster.xy,
                state.tiles,
                state.rng
            ).len;

            let damage = numWalls*4
            if damage > 0:
                state.tiles.setMonster(
                    monster.hit(platform, Damage(damage))
                )

        state.shake.amount = Counter(20)

    proc maelstrom(state: var State, platform: Platform): PostSpell =
        var monsters: seq[Monster] = getMonsters(state)
        for i in 0..<monsters.len:
            var monster = monsters[i]
            if monster.isPlayer:
                continue

            let tileRes = state.rng.randomPassableTile(state.tiles)
            case tileRes.isOk:
            of true:
                monster.teleportCounter = Counter(2)
                discard state.tiles.move(monster, tileRes.value.xy)
            of false:
                discard

        allEffectsHandled()

    proc mulligan(state: var State, platform: Platform): PostSpell =
        PostSpell(kind: PostSpellKind.StartLevel)

requirePlayer(aura, player, state, platform):
        for t in state.xy.getAdjacentNeighbors(state.tiles, state.rng):
            state.tiles.setEffect(t.xy, game.SpriteIndex(13))

            if t.monster.isSome:
                state.tiles.setMonster(t.monster.get.heal(Damage(2)))

        state.tiles.setEffect(state.xy, game.SpriteIndex(13))
        state.tiles.setMonster(player.heal(Damage(2)))

        allEffectsHandled()

no_ex:
    proc dash(state: var State, platform: Platform): PostSpell =
        var newTile = state.tiles.getTile(state.xy)
        let monster = newTile.monster
        if monster.isSome:
            let player = monster.get

            while true:
                let testTile = state.tiles.getNeighbor(
                    newTile.xy,
                    state.lastMove
                )

                if testTile.isPassable and not testTile.monster.isSome:
                    newTile = testTile
                else:
                    break

            if player.xy != newTile.xy:
                let moved = state.tiles.move(player, newTile.xy)

                for t in newTile.xy.getAdjacentNeighbors(state.tiles, state.rng):
                    if t.monster.isSome:
                        state.tiles.setEffect(
                            t.xy,
                            game.SpriteIndex(14)
                        )

                        state.tiles.setMonster(
                            t.monster.get.markStunned().hit(platform, Damage(2))
                        )

                return playerMoved(moved)


        # If the player cannot be found now then presumably the
        # next time the player tries to move, the error message
        # will be shown
        allEffectsHandled()

requirePlayer(dig, player, state, platform):
        for y in 0..<game.NumTiles:
            for x in 0..<game.NumTiles:
                let xy: game.TileXY = (x: game.TileX(x), y: game.TileY(y))
                let t = state.tiles.getTile(xy)
                if not t.isPassable:
                    state.tiles.replace(t.xy, tile.newFloor)

        state.tiles.setEffect(
            player.xy,
            game.SpriteIndex(13)
        )
        state.tiles.setMonster(
            player.heal(Damage(4))
        )

        allEffectsHandled()

no_ex:
    proc kingmaker(state: var State, platform: Platform): PostSpell =
        var monsters: seq[Monster] = getMonsters(state)
        for i in 0..<monsters.len:
            let monster = monsters[i]
            if monster.isPlayer:
                continue

            state.tiles.setMonster(
                monster.heal(Damage(2))
            )
            state.tiles.setTreasure(
                monster.xy,
                true
            )

        allEffectsHandled()

no_ex:
    proc alchemy(state: var State, platform: Platform): PostSpell =
        for neighbor in state.xy.getAdjacentNeighbors(state.tiles, state.rng):
            if not neighbor.isPassable:
                state.tiles.replace(neighbor.xy, tile.newFloor)
                let floorTile = state.tiles.getTile(neighbor.xy)
                # If replacement didn't happen (say because it's an outer wall
                # tile then don't embed the treasure in the outer wall, possibly
                # making the player think there's a way to get it.
                if floorTile.isPassable:
                    state.tiles.setTreasure(
                        floorTile.xy,
                        true
                    )

        allEffectsHandled()

    proc power(state: var State, platform: Platform): PostSpell =
        state.bonusAttack = some(Damage(10))

        allEffectsHandled()

    proc bubble(state: var State, platform: Platform): PostSpell =
        var i = state.spells.len-1
        while i > 0:
            if state.spells[i].isNone:
                state.spells[i] = state.spells[i-1]

            i -= 1

    proc bravery(state: var State, platform: Platform): PostSpell =
        state.shield = Counter(2)

        var monsters: seq[Monster] = getMonsters(state)
        for i in 0..<monsters.len:
            let monster = monsters[i]
            if monster.isPlayer:
                continue

            state.tiles.setMonster(
                monster.markStunned()
            )

    proc bolt(state: var State, platform: Platform): PostSpell =
        boltTravel(
            state,
            platform,
            state.lastMove,
            game.SpriteIndex(
                if state.lastMove.y == game.DeltaY.DY0:
                    15
                else:
                    16
            ),
            Damage(8)
        )

    proc cross(state: var State, platform: Platform): PostSpell =
        let directions = [
            (x: game.DeltaX.DX0, y: game.DeltaY.DYm1),
            (x: game.DeltaX.DX0, y: game.DeltaY.DY1),
            (x: game.DeltaX.DXm1, y: game.DeltaY.DY0),
            (x: game.DeltaX.DX1, y: game.DeltaY.DY0)
        ];

        for direction in directions:
            boltTravel(
                state,
                platform,
                direction,
                game.SpriteIndex(
                    if direction.y == game.DeltaY.DY0:
                        15
                    else:
                        16
                ),
                Damage(4)
            )

    proc ex(state: var State, platform: Platform): PostSpell =
        let directions = [
            (x: game.DeltaX.DXm1, y: game.DeltaY.DYm1),
            (x: game.DeltaX.DXm1, y: game.DeltaY.DY1),
            (x: game.DeltaX.DX1, y: game.DeltaY.DYm1),
            (x: game.DeltaX.DX1, y: game.DeltaY.DY1)
        ];

        for direction in directions:
            boltTravel(
                state,
                platform,
                direction,
                game.SpriteIndex(14),
                Damage(6)
            )
        


# Public spell procs

no_ex:
    proc addSpell*(state: var State) =
        var index = -1
        var i = int(high(SpellPage))
        while i >= int(low(SpellPage)):
            if state.spells[int(i)].isNone:
                index = int(i)

            i -= 1

        if index == -1:
            return

        var names = allSpellNames()
        state.rng.shuffle(names)

        let newSpell = names[0]

        state.spells[index] = some(newSpell)

    proc castSpell*(state: var State, platform: Platform, page: SpellPage): PostSpell =
        let index = int(page)
        let spellName: Option[SpellName] = state.spells[index]

        if spellName.isSome:
            state.spells[index] = none(SpellName)

            let spell: Spell = case spellName.get
                of QUAKE:
                    quake
                of MAELSTROM:
                    maelstrom
                of MULLIGAN:
                    mulligan
                of AURA:
                    aura
                of DASH:
                    dash
                of DIG:
                    dig
                of KINGMAKER:
                    kingmaker
                of ALCHEMY:
                    alchemy
                of POWER:
                    power
                of BUBBLE:
                    bubble
                of BRAVERY:
                    bravery
                of BOLT:
                    bolt
                of CROSS:
                    cross
                of EX:
                    ex
                of WOOP:
                    woop


            platform.sound(game.SoundSpec.spell)

            spell(state, platform)
        else:
            allEffectsHandled()
