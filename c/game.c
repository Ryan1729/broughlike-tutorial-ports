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

typedef enum {
    NONE,
    SOME
} maybe_kind;

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

local u8 abs(i8 x){
    return (u8)(x < 0 ? -x : x);
}

// manhattan distance
local u8 tile_xy_dist(tile_xy a, tile_xy b){
    return abs((i8)a.x-(i8)b.x) + abs((i8)a.y-(i8)b.y);
}

typedef i8 delta_x;
typedef i8 delta_y;

typedef struct {
    delta_x x;
    delta_y y;
} delta_xy;

typedef enum {
    PLAYER,
    BIRD,
    SNAKE,
    TANK,
    EATER,
    JESTER
} monster_kind;

typedef u8 half_hp;

typedef struct {
    monster_kind kind;
    tile_xy xy;
    half_hp half_hp;
    bool attacked_this_turn;
    bool stunned;
    u8 padding[3];
} monster;

local monster make_player(tile_xy xy) {
    monster m = {
        .kind = PLAYER,
        .xy = xy,
        .half_hp = 6,
    };

    return m;
}

local monster make_bird(tile_xy xy) {
    monster m = {
        .kind = BIRD,
        .xy = xy,
        .half_hp = 6,
    };

    return m;
}

local monster make_snake(tile_xy xy) {
    monster m = {
        .kind = SNAKE,
        .xy = xy,
        .half_hp = 2,
    };

    return m;
}

local monster make_tank(tile_xy xy) {
    monster m = {
        .kind = TANK,
        .xy = xy,
        .half_hp = 4,
    };

    return m;
}

local monster make_eater(tile_xy xy) {
    monster m = {
        .kind = EATER,
        .xy = xy,
        .half_hp = 2,
    };

    return m;
}

local monster make_jester(tile_xy xy) {
    monster m = {
        .kind = JESTER,
        .xy = xy,
        .half_hp = 4,
    };

    return m;
}

local bool is_dead(monster monster) {
    return monster.half_hp == 0;
}

local bool is_player(monster monster) {
    return monster.kind == PLAYER;
}

// maybe def {
typedef struct {
    maybe_kind kind;
    monster payload;
} maybe_monster;

local maybe_monster some_monster(monster monster) {
    return (maybe_monster) {.kind = SOME, .payload = monster};
}
// }

// list def {
typedef struct {
    // THe maximum umber of monsters is < TILE_COUNT.
    monster pool[TILE_COUNT];
    u8 length;
    u8 padding[3];
} monster_list;

local void monster_list_push_saturating(monster_list* list, monster monster) {
    if (list->length < TILE_COUNT) {
        list->pool[list->length] = monster;
        list->length += 1;
    }
}
// }

typedef enum {
    WALL,
    FLOOR,
} tile_kind;

typedef struct {
    tile_kind kind;
    tile_xy xy;
    u8 padding[2];
    maybe_monster maybe_monster;
} tile;

local bool is_passable(tile tile) {
    return tile.kind == FLOOR;
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

local void remove_monster(tiles tiles, tile_xy xy) {
    tiles[xy_to_i(xy)].maybe_monster = (maybe_monster){0};
}

local void set_monster(tiles tiles, monster monster) {
    tiles[xy_to_i(monster.xy)].maybe_monster = some_monster(monster);
}

local void hit(monster* monster, half_hp half_hp) {
    if (monster->half_hp > half_hp) {
        monster->half_hp -= half_hp;
    } else {
        monster->half_hp = 0;
    }
}

typedef u8 level;

struct world {
    tile_xy xy;
    level level;
    u8 padding[5];
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

local monster move(struct world* world, monster monster, tile_xy xy) {
    remove_monster(world->tiles, monster.xy);

    monster.xy = xy;

    set_monster(world->tiles, monster);

    if (is_player(monster)) {
        world->xy = monster.xy;
    }

    return monster;
}

local tile get_neighbor(tiles tiles, tile_xy xy, delta_xy dxy) {
    // If we underflow here the bounds check in `get_tile` should save us.
    tile_xy new_xy = {
        .x = (tile_x)((delta_x)xy.x + dxy.x),
        .y = (tile_y)((delta_y)xy.y + dxy.y)
    };
    return get_tile(tiles, new_xy);
}

local maybe_monster try_move(struct world* world, monster m, delta_xy dxy) {
    tile new_tile = get_neighbor(world->tiles, m.xy, dxy);

    maybe_monster output = {0};

    if (is_passable(new_tile)) {
        if (new_tile.maybe_monster.kind == SOME) {
            monster target = new_tile.maybe_monster.payload;
            //`!=` is an example of why it's important that `true` is a single value.
            if(is_player(m) != is_player(target)){
                m.attacked_this_turn = true;
                set_monster(world->tiles, m);

                hit(&target, 2);
                target.stunned = true;
                set_monster(world->tiles, target);
            }

            output = some_monster(m);
        } else {
            output = some_monster(move(world, m, new_tile.xy));
        }
    }

    return output;
}

// list def {
typedef struct {
    tile pool[TILE_COUNT];
    u8 length;
    u8 padding[3];
} tile_list;

local void push_saturating(tile_list* list, tile tile) {
    if (list->length < TILE_COUNT) {
        list->pool[list->length] = tile;
        list->length += 1;
    }
}
// }

local void concat_saturating(tile_list* dest, tile_list* src) {
    for (u8 i = 0; i < src->length; i += 1) {
        push_saturating(dest, src->pool[i]);
    }
}

local bool contains(tile_list* list, tile_xy xy) {
    for (u8 i = 0; i < list->length; i += 1) {
        tile t = list->pool[i];
        
        if (t.xy.x == xy.x && t.xy.y == xy.y) {
            return true;
        }
    }
    return false;
}

local void shuffle(xs* rng, tile_list* list) {
    for (u8 i = 1; i < list->length; i += 1) {
        u32 r = xs_u32(rng, 0, i + 1);
        tile temp = list->pool[i];
        list->pool[i] = list->pool[r];
        list->pool[r] = temp;
    }
}

local void sort_by_dist(tile_list* list, tile_xy xy) {
    // This is used on lists that have at most TILE_COUNT elements, and in practice 
    // have way fewer. So we don't really care how this scales, so bubble sort will
    // do just fine.
    for (u8 i = 0; i < list->length; i += 1) {
        for (u8 j = i + 1; j < list->length; j += 1) {
            int dist_i = tile_xy_dist(xy, list->pool[i].xy);
            int dist_j = tile_xy_dist(xy, list->pool[j].xy);

            if (dist_j < dist_i) {
                tile temp = list->pool[i];
                list->pool[i] = list->pool[j];
                list->pool[j] = temp;
            }
        }
    }
}

local tile_list get_adjacent_neighbors(xs* rng, tiles tiles, tile_xy xy) {
    tile_list adjacent_neighbors = {0};

    push_saturating(
        &adjacent_neighbors,
        get_neighbor(
            tiles,
            xy,
            (delta_xy){0, -1}
        )
    );

    push_saturating(
        &adjacent_neighbors,
        get_neighbor(
            tiles,
            xy,
            (delta_xy){0, 1}
        )
    );

    push_saturating(
        &adjacent_neighbors,
        get_neighbor(
            tiles,
            xy,
            (delta_xy){-1, 0}
        )
    );

    push_saturating(
        &adjacent_neighbors,
        get_neighbor(
            tiles,
            xy,
            (delta_xy){1, 0}
        )
    );

    shuffle(rng, &adjacent_neighbors);

    return adjacent_neighbors;
}

local tile_list get_connected_tiles(xs* rng, tiles tiles, tile start_tile) {
    tile_list connected_tiles = {0};
    push_saturating(&connected_tiles, start_tile);

    tile_list frontier = {0};
    push_saturating(&frontier, start_tile);

    while (frontier.length) {
        // We currently know frontier.length > 0
        tile popped = frontier.pool[frontier.length - 1];
        frontier.length -= 1;

        tile_list unfiltered_neighbors = get_adjacent_neighbors(
            rng,
            tiles,
            popped.xy
        );

        tile_list neighbors = {0};
        for (u8 i = 0; i < unfiltered_neighbors.length; i += 1) {
            tile t = unfiltered_neighbors.pool[i];
            if (is_passable(t) && !contains(&connected_tiles, t.xy)) {
                push_saturating(&neighbors, t);
            }
        }

        concat_saturating(&connected_tiles, &neighbors);
        concat_saturating(&frontier, &neighbors);
    }

    return connected_tiles;
}

local tile_result random_passable_tile(xs* rng, tiles tiles);

local void spawn_monster(xs* rng, tiles tiles) {
    tile_result t_r = random_passable_tile(rng, tiles);

    if (t_r.kind == ERR) {
        // The player won't mind if a monster doesn't spawn.
        return;
    }

    monster (*maker)(tile_xy) = 0;
    switch (xs_u32(rng, 0, 5)) {
        case 0:
            maker = &make_bird;
        break;
        case 1:
            maker = &make_snake;
        break;
        case 2:
            maker = &make_tank;
        break;
        case 3:
            maker = &make_eater;
        break;
        case 4:
            maker = &make_jester;
        break;
        default:
            // We don't expect this case to be hit.
            return;
    }

    set_monster(tiles, maker(t_r.result.xy));
}

local void generate_monsters(xs* rng, tiles tiles, level level) {
    u8 monster_count = level + 1;
    for (u8 i = 0; i < monster_count; i += 1) {
        spawn_monster(rng, tiles);
    }
}

local void generate_tiles(xs* rng, tiles_result* output, level level) {
    if (output->kind == ERR) {
        output->error = ERROR_GENERATE_TILES_NEEDS_TO_BE_PASSED_A_BUFFER;
        return;
    }

    u16 timeout = 1000;

    tiles* tiles = output->result;

    while (timeout--) {
        u8 passable_tiles = 0;

        for (u8 y = 0; y < NUM_TILES; y += 1) {
            for (u8 x = 0; x < NUM_TILES; x += 1) {
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

        tile_list connected_tiles = get_connected_tiles(rng, *tiles, t_r.result);
        
        if (connected_tiles.length == passable_tiles) {
            generate_monsters(rng, *tiles, level);
            return;
        }
    }

    *output = tiles_err(ERROR_MAP_GENERATION_TIMEOUT);
}

local tile_result random_passable_tile(xs* rng, tiles tiles){
    u16 timeout = 1000;

    while (timeout--) {
        tile_xy xy = {
            .x = (u8) xs_u32(rng, 0, NUM_TILES),
            .y = (u8) xs_u32(rng, 0, NUM_TILES)
        };

        tile tile = get_tile(tiles, xy);

        if (is_passable(tile) && tile.maybe_monster.kind == NONE) {
            return tile_ok(tile);
        }
    }

    return tile_err(ERROR_NO_PASSABLE_TILE);
}

typedef struct {
    level level;
} world_spec;

local world_result world_from_rng(xs rng, world_spec world_spec) {
    struct world world = {0};

    world.rng = rng;
    world.level = world_spec.level ? world_spec.level : 1;

    tiles_result tiles_r = tiles_ok(&world.tiles);

    generate_tiles(&world.rng, &tiles_r, world.level);

    if (tiles_r.kind == ERR) {
        return world_err(tiles_r.error);
    }

    tile_result t_r = random_passable_tile(&world.rng, world.tiles);

    if (t_r.kind == ERR) {
        return world_err(t_r.error);
    }

    world.xy = t_r.result.xy;

    set_monster(world.tiles, make_player(world.xy));

    return world_ok(world);
}

local maybe_monster do_stuff(struct world* world, monster monster) {
    tile_list unfiltered_neighbors = get_adjacent_neighbors(
        &world->rng,
        world->tiles,
        monster.xy
    );

    tile_list neighbors = {0};
    for (u8 i = 0; i < unfiltered_neighbors.length; i += 1) {
        tile t = unfiltered_neighbors.pool[i];
        if (
            is_passable(t)
            && (
                t.maybe_monster.kind == NONE
                || is_player(t.maybe_monster.payload)
            )) {
            push_saturating(&neighbors, t);
        }
    }

    maybe_monster output = {0};

    if (neighbors.length) {
        sort_by_dist(&neighbors, world->xy);
        tile new_tile = neighbors.pool[0];
        output = try_move(
            world,
            monster,
            (delta_xy) {
                (delta_x)new_tile.xy.x - (delta_x)monster.xy.x,
                (delta_y)new_tile.xy.y - (delta_y)monster.xy.y
            }
        );
    }

    return output;
}

local void update_monster(struct world* world, monster m) {
    if (m.stunned) {
        m.stunned = false;
        set_monster(world->tiles, m);

        return;
    }

    switch (m.kind) {
        case SNAKE: {
            m.attacked_this_turn = false;

            set_monster(world->tiles, m);

            maybe_monster maybe_moved = do_stuff(world, m);
            if (maybe_moved.kind == SOME) {
                monster moved = maybe_moved.payload;
                if (!moved.attacked_this_turn) {
                    do_stuff(world, moved);
                }
            }
        } break;
        case TANK: {
            bool started_stunned = m.stunned;

            maybe_monster maybe_moved = do_stuff(world, m);

            if(!started_stunned){
                monster moved = maybe_moved.kind == SOME
                    ? maybe_moved.payload
                    : m;

                moved.stunned = true;
                set_monster(world->tiles, moved);
            }
        } break;
        case EATER:
        case JESTER:
        case BIRD:
        case PLAYER: // Shouldn't happen.
            do_stuff(world, m);
    }
}

local maybe_monster get_player(struct world* world) {
    tile tile = get_tile(world->tiles, world->xy);
    if (tile.maybe_monster.kind == SOME) {
        if (is_player(tile.maybe_monster.payload)) {
            return tile.maybe_monster;
        }
    }
    return (maybe_monster){0};
}

// When iterating monsters, We collect the monsters into a list
// so that we don't hit the same monster twice in the iteration,
// in case it moves
local monster_list get_monsters(tiles tiles) {
    monster_list monsters = {0};

    for (u8 y = 0; y < NUM_TILES; y += 1) {
        for (u8 x = 0; x < NUM_TILES; x += 1) {
            tile_xy xy = {x, y};
            tile t = get_tile(tiles, xy);

            if (
                t.maybe_monster.kind == SOME
                && !is_player(t.maybe_monster.payload)
            ) {
                monster_list_push_saturating(&monsters, t.maybe_monster.payload);
            }
        }
    }

    return monsters;
}

local void tick(struct world* world){
    monster_list monsters = get_monsters(world->tiles);

    for (u8 i = 0; i < monsters.length; i += 1) {
        monster monster = monsters.pool[i];
        if (is_dead(monster)) {
            remove_monster(world->tiles, monster.xy);
        } else {
            update_monster(world, monster);
        }
    }
}

local void move_player(struct world* world, delta_xy dxy) {
    maybe_monster maybe_player = get_player(world);

    if (maybe_player.kind == SOME) {
        maybe_monster maybe_moved = try_move(world, maybe_player.payload, dxy);

        if (maybe_moved.kind == SOME) {
            tick(world);
        }
    }
}

typedef enum {
    INPUT_NONE,
    INPUT_UP,
    INPUT_DOWN,
    INPUT_LEFT,
    INPUT_RIGHT,
} input;

local void update(struct world* world, input input) {
    switch (input) {
        case INPUT_NONE:
            return;
        case INPUT_UP:
            move_player(world, (delta_xy){0, -1});
        break;
        case INPUT_DOWN:
            move_player(world, (delta_xy){0, 1});
        break;
        case INPUT_LEFT:
            move_player(world, (delta_xy){-1, 0});
        break;
        case INPUT_RIGHT:
            move_player(world, (delta_xy){1, 0});
        break;
    }
}
