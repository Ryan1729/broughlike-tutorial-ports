// NUM_TILES is the width/height.
local const u8 NUM_TILES = 9;
// NUM_TILES * NUM_TILES, but we need it to be a literal
#define TILE_COUNT 81
local const u8 UI_WIDTH = 4;

typedef enum { 
    ERR,
    OK
} result_kind;

typedef enum { 
    ERROR_ZERO,
    ERROR_NO_PASSABLE_TILE,
    ERROR_GENERATE_TILES_NEEDS_TO_BE_PASSED_A_BUFFER,
    ERROR_MAP_GENERATION_TIMEOUT,
} error_kind;

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

local bool is_passable(tile tile) {
    return tile.kind == FLOOR;
}

local bool has_monster(tile tile) {
    (void)tile;
    // TODO once we have monsters
    return false;
}

// result def {
typedef struct { 
    result_kind kind;
    union {
        error_kind error;
        tile result;
    };
} tile_result;

local tile_result tile_err(error_kind error) {
    tile_result result = {
        .kind = ERR,
        .error = error,
    };
    return result;
}

local tile_result tile_ok(tile payload) {
    tile_result result = {
        .kind = OK,
        .result = payload,
    };
    return result;
}
//}

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

local bool in_bounds(tile_xy xy) {
    return xy.x > 0 && xy.y > 0 && xy.x < NUM_TILES-1 && xy.y < NUM_TILES-1;
}

local u8 xy_to_i(tile_xy xy) {
    return xy.y * NUM_TILES + xy.x;
}

local tile get_tile(tiles tiles, tile_xy xy){
    if (in_bounds(xy)) {
        return tiles[xy_to_i(xy)];
    } else {
        return make_wall(xy);
    }
}

// result def {
typedef struct {
    result_kind kind;
    u8 padding[4];
    union {
        error_kind error;
        tiles* result;
    };
} tiles_result;

local tiles_result tiles_err(error_kind error) {
    tiles_result result = {
        .kind = ERR,
        .error = error,
    };
    return result;
}

local tiles_result tiles_ok(tiles* payload) {
    tiles_result result = {
        .kind = OK,
        .result = payload,
    };
    return result;
}
//}

local tile_result random_passable_tile(xs* rng, tiles tiles);

local void generate_tiles(xs* rng, tiles_result* output) {
    if (output->kind == ERR) {
        output->error = ERROR_GENERATE_TILES_NEEDS_TO_BE_PASSED_A_BUFFER;
        return;
    }

    u16 timeout = 1000;

    tiles* tiles = output->result;

    while (timeout--) {
        u8 passable_tiles = 0;

        for (u8 y = 0; y < NUM_TILES; y++) {
            for (u8 x = 0; x < NUM_TILES; x++) {
                tile_xy xy = {x, y};
                u8 i = xy_to_i(xy);

                if (xs_u32(rng, 0, 10) < 3 || !in_bounds(xy)) {
                    (*tiles)[i] = make_wall(xy);
                } else {
                    (*tiles)[i] = make_floor(xy);
                    passable_tiles += 1;
                }
            }
        }

        tile_result t_r = random_passable_tile(rng, *tiles);

        if (t_r.kind == ERR) {
            continue;
        }

        // TODO check if all tiles are reachable from the random tile.
        if (false) {
            return;
        }
    }

    *output = tiles_err(ERROR_MAP_GENERATION_TIMEOUT);
}

struct world {
    tile_xy xy;
    u8 padding[6];
    xs rng;
    tiles tiles;
};

// result def {
typedef struct { 
    result_kind kind;
    u8 padding[4];
    union {
        error_kind error;
        struct world result;
    };
} world_result;

local world_result world_err(error_kind error) {
    world_result result = {
        .kind = ERR,
        .error = error,
    };
    return result;
}

local world_result world_ok(struct world payload) {
    world_result result = {
        .kind = OK,
        .result = payload,
    };
    return result;
}
//}

local tile_result random_passable_tile(xs* rng, tiles tiles){
    u16 timeout = 1000;

    while (timeout--) {
        tile_xy xy = {
            .x = (u8) xs_u32(rng, 0, NUM_TILES),
            .y = (u8) xs_u32(rng, 0, NUM_TILES)
        };

        tile tile = get_tile(tiles, xy);

        if (is_passable(tile) && !has_monster(tile)) {
            return tile_ok(tile);
        }
    }

    return tile_err(ERROR_NO_PASSABLE_TILE);
}

local world_result world_from_rng(xs rng) {
    struct world world = {0};
    world.rng = rng;

    tiles_result tiles_r = tiles_ok(&world.tiles);

    generate_tiles(&world.rng, &tiles_r);

    if (tiles_r.kind == ERR) {
        return world_err(tiles_r.error);
    }

    tile_result t_r = random_passable_tile(&world.rng, world.tiles);

    if (t_r.kind == ERR) {
        return world_err(t_r.error);
    }

    world.xy = t_r.result.xy;

    return world_ok(world);
}
