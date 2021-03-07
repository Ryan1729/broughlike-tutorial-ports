#include "spritesheet.c"

local Image spritesheet_image() {
    return LoadImageFromMemory("png", SPRITESHEET_BYTES, SPRITESHEET_LENGTH);
}
