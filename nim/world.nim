from options import Option, isSome, isNone, get, some, none

from game import no_ex, Counter, dec, `<=`, Score, Shake, Platform, DeltaXY
from randomness import shuffle
from map import getTile, removeMonster, updateMonster, spawnMonster, randomPassableTile, move, setMonster, getAdjacentNeighbors, setEffect, getNeighbor, replace
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
    proc quake(state: var State, platform: Platform): PostSpell {. raises: [] .} =
        for i in 0..<state.tiles.len:
            if state.tiles[i].monster.isSome:
                let monster = state.tiles[i].monster.get
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

    proc maelstrom(state: var State, platform: Platform): PostSpell {. raises: [] .} =
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

    proc mulligan(state: var State, platform: Platform): PostSpell {. raises: [] .} =
        PostSpell(kind: PostSpellKind.StartLevel)

requirePlayer(aura, player, state, platform):
        for t in state.xy.getAdjacentNeighbors(state.tiles, state.rng):
            state.tiles.setEffect(t.xy, game.SpriteIndex(13))

            if t.monster.isSome:
                state.tiles.setMonster(t.monster.get.heal(Damage(2)))

        state.tiles.setEffect(state.xy, game.SpriteIndex(13))
        state.tiles.setMonster(player.heal(Damage(2)))

        allEffectsHandled()

requirePlayer(dash, player, state, platform):
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
        for i in 0..<state.tiles.len:
            let t = state.tiles[i]
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


# Public spell procs

no_ex:
    proc addSpell*(state: var State) =
        var index = -1
        var i = int(high(SpellPage))
        while i >= int(low(SpellPage)):
            echo $int(i)
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
                of WOOP:
                    woop


            platform.sound(game.SoundSpec.spell)

            spell(state, platform)
        else:
            allEffectsHandled()
