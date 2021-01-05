from options import Option, isSome, isNone, get, some, none

from game import no_ex, Counter, dec, `<=`, Score, Shake, Platform
from randomness import shuffle
from map import getTile, removeMonster, updateMonster, spawnMonster, randomPassableTile, move
from monster import Monster, Kind, dead, isPlayer
from tile import Tile

const maxNumSpellsInt: int = 9

type
    SpellName* = enum
        WOOP

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

    Spell = proc(state: var State, platform: Platform) {. raises: [] .}

    AfterTick* = enum
        NoChange
        PlayerDied

no_ex:
    proc tick*(state: var State, platform: Platform): AfterTick =
        # We collect the monsters into a list so that we don't hit
        # the same monster twice in the iteration, in case it moves

        var monsters: seq[Monster] = newSeqOfCap[Monster](map.tileLen)

        for y in 0..<game.NumTiles:
            for x in 0..<game.NumTiles:
                let xy = (x: game.TileX(x), y: game.TileY(y))

                var t: Tile = state.tiles.getTile(xy)

                if t.monster.isSome:
                    monsters.add(
                        t.monster.get
                    )


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

template requirePlayer(spellName, playerName, stateName, platformName, spellBody: untyped) =
    proc spellName(stateName: var State, platformName: Platform) {. raises: [] .} =
        let tile = stateName.tiles.getTile(stateName.xy)
        let monster = tile.monster
        if monster.isSome:
            let playerName = monster.get

            spellBody
        else:
            # If the player cannot be found now then presumably the
            # next time the player tries to move, the error message
            # will be shown
            discard

requirePlayer(woop, player, state, platform):
        let tileRes = state.rng.randomPassableTile(state.tiles)
        case tileRes.isOk:
        of true:
            let moved = state.tiles.move(player, tileRes.value.xy)
            state.xy = moved.xy
        of false:
            # If the player tries to teleport when there is no free space
            # I'm not sure what else they would expect to happen
            discard

no_ex:
    proc addSpell*(state: var State) =
        var index = -1
        for i in countdown(high(SpellPage), low(SpellPage)):
            if state.spells[int(i)].isNone:
                index = int(i)
                break

        if index == -1:
            return

        var names = allSpellNames()
        state.rng.shuffle(names)

        let newSpell = names[0]

        state.spells[index] = some(newSpell)

    proc castSpell*(state: var State, platform: Platform, page: SpellPage): AfterTick =
        let index = int(page)
        let spellName: Option[SpellName] = state.spells[index]

        if spellName.isSome:
            state.spells[index] = none(SpellName)

            let spell: Spell = case spellName.get
                of WOOP:
                    woop

            spell(state, platform)

            platform.sound(game.SoundSpec.spell)
            tick(state, platform)
        else:
            AfterTick.NoChange
