#include "asset_bytes.c"

local Image spritesheet_image() {
    return LoadImageFromMemory("png", SPRITESHEET_BYTES, SPRITESHEET_LENGTH);
}

local Wave hit_1_wave() {
    return LoadWaveFromMemory("wav", HIT_1_BYTES, HIT_1_LENGTH);
}

local Wave hit_2_wave() {
    return LoadWaveFromMemory("wav", HIT_2_BYTES, HIT_2_LENGTH);
}

local Wave new_level_wave() {
    return LoadWaveFromMemory("wav", NEW_LEVEL_BYTES, NEW_LEVEL_LENGTH);
}

local Wave spell_wave() {
    return LoadWaveFromMemory("wav", SPELL_BYTES, SPELL_LENGTH);
}

local Wave treasure_wave() {
    return LoadWaveFromMemory("wav", TREASURE_BYTES, TREASURE_LENGTH);
}
