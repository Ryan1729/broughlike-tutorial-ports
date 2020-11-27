import strutils, ../raylib, system

let image = LoadImage("../spritesheet.png")
let imageLen: int = image.width * image.height
let pixelPointer: ptr Color = GetImageData(image)
let pixels: ptr UncheckedArray[Color] = cast[ptr UncheckedArray[Color]](pixelPointer)

const BYTES_PER_PIXEL = 4

var output = """
import raylib

const imageArray*: array["""
add(output, $(imageLen * BYTES_PER_PIXEL))
add(output, ", uint8] = [")

let startLen = len(output)

for i in 0 ..< imageLen:
    let color = pixels[i]

    addSep(output, startLen = startLen)
    add(output, $color.r)
    add(output, "u8")
    addSep(output, startLen = startLen)
    add(output, $color.g)
    add(output, "u8")
    addSep(output, startLen = startLen)
    add(output, $color.b)
    add(output, "u8")
    addSep(output, startLen = startLen)
    add(output, $color.a)
    add(output, "u8")

add(output, "]\n")

add(output, """const image*: Image = Image(
    data: cast[pointer](unsafeAddr(imageArray)),
    width: 512,
    height: 16,
    mipmaps: 1,
    format: UNCOMPRESSED_R8G8B8A8
)
""")

writeFile("../spritesheet.nim", output)
