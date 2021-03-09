local const u8 NUM_TILES = 9;
local const u8 UI_WIDTH = 4;

typedef u32 xs[4];

local u32 xorshift(xs xs) {
    u32 t = xs[3];

    xs[3] = xs[2];
    xs[2] = xs[1];
    xs[1] = xs[0];

    t ^= t << 11;
    t ^= t >> 8;
    xs[0] = t ^ xs[0] ^ (xs[0] >> 19);

    return xs[0];
}

local u32 xs_u32(xs xs, u32 min, u32 one_past_max) {
    return (xorshift(xs) % (one_past_max - min)) + min;
}

typedef u8 tile_x;
typedef u8 tile_y;

typedef struct {
    tile_x x;
    tile_y y;
} tile_xy;

typedef u8 sprite_index;

struct world {
    tile_xy xy;
};
