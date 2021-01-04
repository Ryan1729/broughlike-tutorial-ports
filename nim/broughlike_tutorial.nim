type
    Spell = proc(state: var bool)

proc requirePlayer(
    spellMaker: proc(field: bool): Spell,
): Spell =
    return proc(state: var bool) =
        (spellMaker(state))(state)

const spell*: Spell =
    requirePlayer(
        proc(field: bool): Spell =
        return proc(state: var bool) =
            discard
    )

var state = true

spell(state)
