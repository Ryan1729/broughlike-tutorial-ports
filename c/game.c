local const u8 NUM_TILES = 9;
local const u8 UI_WIDTH = 4;

#define XS_COUNT 4
// Making this a struct causes some extra copying, but simplifies interfaces.
typedef struct {
    u32 xs[XS_COUNT];
} xs;

local u32 xorshift(xs* xs) {
    u32 t = xs->xs[3];

    xs->xs[3] = xs->xs[2];
    xs->xs[2] = xs->xs[1];
    xs->xs[1] = xs->xs[0];

    t ^= t << 11;
    t ^= t >> 8;
    xs->xs[0] = t ^ xs->xs[0] ^ (xs->xs[0] >> 19);

    return xs->xs[0];
}

local u32 xs_u32(xs* xs, u32 min, u32 one_past_max) {
    return (xorshift(xs) % (one_past_max - min)) + min;
}

typedef u8 sprite_index;

typedef u8 tile_x;
typedef u8 tile_y;

typedef struct {
    tile_x x;
    tile_y y;
} tile_xy;


struct world {
    tile_xy xy;
    u8 padding[6];
    xs rng;
};

local struct world world_from_rng(xs rng) {
    struct world world = {0};
    world.rng = rng;

    return world;
}
