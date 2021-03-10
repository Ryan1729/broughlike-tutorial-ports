// NUM_TILES is the width/height.
local const u8 NUM_TILES = 9;
// NUM_TILES * NUM_TILES, but we need it to be a literal
#define TILE_COUNT 81
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

typedef enum {
    WALL,
    FLOOR,
} tile_kind;

typedef struct {
    tile_kind kind;
    tile_xy xy;
    u8 padding[2];
} tile;

typedef tile tiles[TILE_COUNT];

local tile make_wall(tile_xy xy) {
    tile t = {
        .xy = xy,
        .kind = WALL,
    };

    return t;
}

local tile make_floor(tile_xy xy) {
    tile t = {
        .xy = xy,
        .kind = FLOOR,
    };

    return t;
}

local u8 xy_to_i(tile_xy xy) {
    return xy.y * NUM_TILES + xy.x;
}

local void generate_tiles(xs* rng, tiles* tiles) {
    for (u8 y = 0; y < NUM_TILES; y++) {
        for (u8 x = 0; x < NUM_TILES; x++) {
            tile_xy xy = {x, y};
            u8 i = xy_to_i(xy);

            if (xs_u32(rng, 0, 10) < 3) {
                (*tiles)[i] = make_wall(xy);
            } else {
                (*tiles)[i] = make_floor(xy);
            }
        }
    }
}

struct world {
    tile_xy xy;
    u8 padding[6];
    xs rng;
    tiles tiles;
};

local struct world world_from_rng(xs rng) {
    struct world world = {0};
    world.rng = rng;

    generate_tiles(&world.rng, &world.tiles);

    return world;
}
