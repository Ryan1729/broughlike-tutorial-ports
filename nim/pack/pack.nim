import strutils, system

# spritesheet.nim
# {
block:
    let image = readFile("../spritesheet.png")
    let imageLen: int = len(image)

    var output = """
import raylib

var imageArray: array["""
    add(output, $imageLen)
    add(output, ", char] = [")

    let startLen = len(output)

    for c in image:
        addSep(output, startLen = startLen)
        add(output, "'\\x")
        add(output, toHex(uint8(c)))
        add(output, "'")
        

    add(output, "]\n")

    add(output, """

var imageBytes: ptr char = cast[ptr char](addr(imageArray))

var image*: Image = LoadImageFromMemory(
    "png",
    imageBytes,
    """)
    add(output, $imageLen)
    add(output, "\n)\n")

    writeFile("../spritesheet.nim", output)
# }


# font.nim
# {
block:
    let font = readFile("../fonts/Courier Prime Sans.ttf")
    let fontLen: int = len(font)

    var output = """
import raylib

var fontArray: array["""
    add(output, $fontLen)
    add(output, ", char] = [")

    let startLen = len(output)

    for c in font:
        addSep(output, startLen = startLen)
        add(output, "'\\x")
        add(output, toHex(uint8(c)))
        add(output, "'")
        

    add(output, "]\n")

    add(output, """

var fontBytes: ptr char = cast[ptr char](addr(fontArray))

var loadedFont*: Font = LoadFontFromMemory(
    "ttf",
    fontBytes,
    """)
    add(output, $fontLen)
    add(output, """,
    32,
    nil,
    95
)
""")

    add(output, "var license* = \"\"\"\n")
    let license: string = readFile("../fonts/LICENSE.md")
    add(output, license)
    add(output, "\n\"\"\"")

    writeFile("../font.nim", output)
# }
