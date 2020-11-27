import raylib

# works, but we want to bake the image into the binary

var spritesheetImage*: Image = LoadImage("spritesheet.png")


# "works" in that garbage data is shown
#[
const spritesheetSeq: array[3, char] = ['a', 'b', 'c']

from spritesheet import nil

var spritesheetImage*: Image = Image(
    data: cast[pointer](unsafeAddr(spritesheet.imageArray)),
    width: 512,
    height: 16,
    mipmaps: 1,
    format: UNCOMPRESSED_R8G8B8A8
)
]#

# what we'd like to get to
#var spritesheetImage*: Image = spritesheet.image





