import strutils, system

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
