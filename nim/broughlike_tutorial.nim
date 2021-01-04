import options

type
    Player = bool
    State = tuple
        playerOption: Option[Player]

    Spell = proc(state: var State)

proc requirePlayer(
    spellMaker: proc(player: Player): Spell,
): Spell =
    return proc(state: var State) =
        if state.playerOption.isSome:
            (spellMaker(state.playerOption.get))(state)

const spell*: Spell =
    requirePlayer(
        proc(player: Player): Spell =
        return proc(state: var State) =
            # somthing that relies on Player here
            discard
    )

var state = (playerOption: some(true))

spell(state)
