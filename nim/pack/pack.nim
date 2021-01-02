import strutils, system

type
    VarSpec = tuple
        data: TaintedString # Yes we shouldn't technically require a tainted string. but this works for now.
        namePrefix: string
        fromMemoryFuncName: string
        fromMemoryFileType: string
        fromMemoryReturnType: string

proc appendVar(output: var string, spec: VarSpec) =
    let arrayName = spec.namePrefix & "Array"
    add(output, """

var """ & arrayName & """: array[""")

    let dataLen = len(spec.data)

    add(output, $dataLen)
    add(output, ", char] = [")

    let startLen = len(output)

    for c in spec.data:
        addSep(output, startLen = startLen)
        add(output, "'\\x")
        add(output, toHex(uint8(c)))
        add(output, "'")


    add(output, "]\n")

    let bytesName = spec.namePrefix & "Bytes"

    add(output, """

var """ & bytesName & """: ptr char = cast[ptr char](addr(""" & arrayName & """))

var """ & spec.namePrefix & """*: """ & spec.fromMemoryReturnType & """ = """ & spec.fromMemoryFuncName & """(
    """" & spec.fromMemoryFileType & """",
    """ & bytesName & """,
    """)
    add(output, $dataLen)
    add(output, "\n)\n")


let image: string = readFile("../spritesheet.png")

var spritesheetOutput = """
import raylib
"""

appendVar(spritesheetOutput, (
    data: image,
    namePrefix: "image",
    fromMemoryFuncName: "LoadImageFromMemory",
    fromMemoryFileType: "png",
    fromMemoryReturnType: "Image"
))

writeFile("../spritesheet.nim", spritesheetOutput)

var soundOutput = """
import raylib
"""

appendVar(soundOutput, (
    data: readFile("../sounds/hit1.wav"),
    namePrefix: "hit1",
    fromMemoryFuncName: "LoadWaveFromMemory",
    fromMemoryFileType: "wav",
    fromMemoryReturnType: "Wave"
))

appendVar(soundOutput, (
    data: readFile("../sounds/hit2.wav"),
    namePrefix: "hit2",
    fromMemoryFuncName: "LoadWaveFromMemory",
    fromMemoryFileType: "wav",
    fromMemoryReturnType: "Wave"
))

appendVar(soundOutput, (
    data: readFile("../sounds/treasure.wav"),
    namePrefix: "treasure",
    fromMemoryFuncName: "LoadWaveFromMemory",
    fromMemoryFileType: "wav",
    fromMemoryReturnType: "Wave"
))

appendVar(soundOutput, (
    data: readFile("../sounds/newLevel.wav"),
    namePrefix: "newLevel",
    fromMemoryFuncName: "LoadWaveFromMemory",
    fromMemoryFileType: "wav",
    fromMemoryReturnType: "Wave"
))

appendVar(soundOutput, (
    data: readFile("../sounds/spell.wav"),
    namePrefix: "spell",
    fromMemoryFuncName: "LoadWaveFromMemory",
    fromMemoryFileType: "wav",
    fromMemoryReturnType: "Wave"
))

writeFile("../sound.nim", soundOutput)
