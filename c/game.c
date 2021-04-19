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

local const half_hp MAX_HALF_HP = 12;

typedef u8 teleport_counter;

typedef i16 offset_x;
typedef i16 offset_y;

local const i16 OFFSET_MULTIPLE = 8;

typedef struct {
    offset_x x;
    offset_y y;
} offset_xy;

typedef struct {
    monster_kind kind;
    offset_xy offset_xy;
    tile_xy xy;
    half_hp half_hp;
    bool attacked_this_turn;
    bool stunned;
    teleport_counter teleport_counter;
    u8 padding[2];
} monster;

local const teleport_counter MAX_TELEPORT_COUNTER = 2;

local monster make_player(tile_xy xy) {
    monster m = {
        .kind = PLAYER,
        .xy = xy,
        .half_hp = 6,
        .teleport_counter = 0,
    };

    return m;
}

local monster make_bird(tile_xy xy) {
    monster m = {
        .kind = BIRD,
        .xy = xy,
        .half_hp = 6,
        .teleport_counter = MAX_TELEPORT_COUNTER,
    };

    return m;
}

local monster make_snake(tile_xy xy) {
    monster m = {
        .kind = SNAKE,
        .xy = xy,
        .half_hp = 2,
        .teleport_counter = MAX_TELEPORT_COUNTER,
    };

    return m;
}

local monster make_tank(tile_xy xy) {
    monster m = {
        .kind = TANK,
        .xy = xy,
        .half_hp = 4,
        .teleport_counter = MAX_TELEPORT_COUNTER,
    };

    return m;
}

local monster make_eater(tile_xy xy) {
    monster m = {
        .kind = EATER,
        .xy = xy,
        .half_hp = 2,
        .teleport_counter = MAX_TELEPORT_COUNTER,
    };

    return m;
}

local monster make_jester(tile_xy xy) {
    monster m = {
        .kind = JESTER,
        .xy = xy,
        .half_hp = 4,
        .teleport_counter = MAX_TELEPORT_COUNTER,
    };

    return m;
}

local bool is_dead(monster monster) {
    return monster.half_hp == 0;
}

local bool is_player(monster monster) {
    return monster.kind == PLAYER;
}

typedef i16 display_x;
typedef i16 display_y;

typedef struct {
    display_x x;
    display_y y;
} display_xy;

local display_xy get_display_xy(monster* m) {
    return (display_xy) {
        (display_x)m->xy.x * OFFSET_MULTIPLE + m->offset_xy.x,
        (display_y)m->xy.y * OFFSET_MULTIPLE + m->offset_xy.y
    };
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
    // The maximum umber of monsters is < TILE_COUNT.
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
    EXIT,
} tile_kind;

typedef u8 effect_counter;

typedef struct {
    tile_kind kind;
    tile_xy xy;
    bool treasure;
    sprite_index effect;
    maybe_monster maybe_monster;
    effect_counter effect_counter;
    u8 padding[3];
} tile;

local bool is_passable(tile tile) {
    return tile.kind == FLOOR || tile.kind == EXIT;
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

local tile make_exit(tile_xy xy) {
    tile t = {
        .xy = xy,
        .kind = EXIT,
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

local void replace(tiles tiles, tile_xy xy, tile (*maker)(tile_xy)) {
    tiles[xy_to_i(xy)] = maker(xy);
}

local void add_treasure(tiles tiles, tile_xy xy) {
    tiles[xy_to_i(xy)].treasure = true;
}

local void remove_treasure(tiles tiles, tile_xy xy) {
    tiles[xy_to_i(xy)].treasure = false;
}

#define EFFECT_MAX 30

local void set_effect(tiles tiles, tile_xy xy, sprite_index effect) {
    tiles[xy_to_i(xy)].effect = effect;
    tiles[xy_to_i(xy)].effect_counter = EFFECT_MAX;
}

local void hit(monster* monster, half_hp half_hp) {
    if (monster->half_hp > half_hp) {
        monster->half_hp -= half_hp;
    } else {
        monster->half_hp = 0;
    }
}

local void heal(monster* monster, half_hp half_hp) {
    if (monster->half_hp + half_hp < MAX_HALF_HP) {
        monster->half_hp += half_hp;
    } else {
        monster->half_hp = MAX_HALF_HP;
    }
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

typedef u16 score;
typedef u8 level;

local const level MAX_LEVEL = 6;

typedef u8 spawn_counter;
typedef u8 spawn_rate;

typedef u8 amount;

typedef struct {
    offset_xy xy;
    amount amount;
    u8 padding[3];
    // We keep a separate shake RNG so that how fast the user inputs things
    // does not affect the world generation
    xs rng;
} shake;

typedef enum {
    NOTHING_INTERESTING,
    PLAYER_DIED,
    COMPLETED_RUN,
    UPDATE_ERROR,
} update_event_kind;

typedef struct {
    update_event_kind kind;
    union {
        score score; // PLAYER_DIED, COMPLETED_RUN
        error_kind error_kind; // UPDATE_ERROR
    };
} update_event;

local update_event update_event_from_error(error_kind error_kind) {
    return (update_event) {
        .kind = UPDATE_ERROR,
        .error_kind = error_kind,
    };
}

typedef enum {
    SOUND_NONE,
    SOUND_HIT_1,
    SOUND_HIT_2,
    SOUND_NEW_LEVEL,
    SOUND_SPELL,
    SOUND_TREASURE,
} sound_spec;

#define WORLD_SOUND_SPEC_COUNT 16

#define MAX_NUM_SPELLS 9

typedef u8 spell_count;

#define ALL_SPELL_NAMES_WITH_COMMAS \
    WOOP,\
    QUAKE,\
    MAELSTROM,\
    MULLIGAN,\
    AURA,\
    DASH,\
    DIG,\
    KINGMAKER,\

#define ALL_SPELL_NAMES_LENGTH 8

typedef enum {
    NO_SPELL,
    ALL_SPELL_NAMES_WITH_COMMAS
} spell_name;

struct world {
    tile_xy xy;
    score score;
    level level;
    spawn_counter spawn_counter;
    spawn_rate spawn_rate;
    spell_count num_spells;
    shake shake;
    xs rng;
    tiles tiles;
    sound_spec sound_specs[WORLD_SOUND_SPEC_COUNT];
    spell_name spells[MAX_NUM_SPELLS];
    delta_xy last_move;
    u8 padding[2];
};

local void tick(struct world* world);

local void clear_sounds(struct world* world) {
    for (u8 i = 0; i < WORLD_SOUND_SPEC_COUNT; i += 1) {
        world->sound_specs[i] = SOUND_NONE;
    }
}

local void push_sound_saturating(struct world* world, sound_spec spec) {
    for (u8 i = 0; i < WORLD_SOUND_SPEC_COUNT; i += 1) {
        if (world->sound_specs[i] == SOUND_NONE) {
            world->sound_specs[i] = spec;
            break;
        }
    }
}

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
    monster.offset_xy.x = ((offset_x)monster.xy.x - (offset_x)xy.x) * OFFSET_MULTIPLE;
    monster.offset_xy.y = ((offset_y)monster.xy.y - (offset_y)xy.y) * OFFSET_MULTIPLE;
    monster.xy = xy;

    set_monster(world->tiles, monster);

    if (is_player(monster)) {
        world->xy = monster.xy;
    }

    return monster;
}

typedef update_event (*spell_proc) (struct world*);

local maybe_monster get_player(struct world*);

local tile_result random_passable_tile(xs* rng, tiles tiles);

local tile_list get_adjacent_neighbors(xs* rng, tiles tiles, tile_xy xy);

local tile get_neighbor(tiles tiles, tile_xy xy, delta_xy dxy);

local monster_list get_monsters(tiles tiles);

local void generate_tiles(xs* rng, tiles_result* output, level level);

local void shuffle_spell_names(xs* rng, spell_name* list);

typedef struct {
    score score;
    level level;
    half_hp half_hp;
    spell_count num_spells;
    bool read_spells;
    u8 padding[2];
    sound_spec sound_specs[WORLD_SOUND_SPEC_COUNT];
    spell_name spells[MAX_NUM_SPELLS];
} world_spec;

local world_result world_from_rng(xs rng, world_spec world_spec) {
    struct world world = {0};
    world.spawn_counter = world.spawn_rate = 15;
    world.last_move = (delta_xy){-1, 0};

    world.rng = rng;
    world.level = world_spec.level ? world_spec.level : 1;
    world.score = world_spec.score;
    world.num_spells = world_spec.num_spells ? world_spec.num_spells : 1;

    tiles_result tiles_r = tiles_ok(&world.tiles);

    generate_tiles(&world.rng, &tiles_r, world.level);

    if (tiles_r.kind == ERR) {
        return world_err(tiles_r.error);
    }

    tile_result exit_t_r = random_passable_tile(&world.rng, world.tiles);

    if (exit_t_r.kind == ERR) {
        return world_err(exit_t_r.error);
    }
    
    // Do the exit first, so we don't replace the player!
    replace(world.tiles, exit_t_r.result.xy, make_exit);

    tile_result player_t_r = random_passable_tile(&world.rng, world.tiles);

    if (player_t_r.kind == ERR) {
        return world_err(player_t_r.error);
    }

    world.xy = player_t_r.result.xy;

    monster player = make_player(world.xy);
    if (world_spec.half_hp) {
        player.half_hp = world_spec.half_hp;
    }

    set_monster(world.tiles, player);

    for (int i = 0; i < 3; i += 1) {
        tile_result t_r = random_passable_tile(&world.rng, world.tiles);

        if (t_r.kind == ERR) {
            return world_err(t_r.error);
        }

        add_treasure(world.tiles, t_r.result.xy);
    }

    if (world_spec.read_spells) {
        for (u8 i = 0; i < world.num_spells; i += 1) {
            world.spells[i] = world_spec.spells[i];
        }
    } else {
        spell_name all_spells[ALL_SPELL_NAMES_LENGTH] = {ALL_SPELL_NAMES_WITH_COMMAS};
        shuffle_spell_names(&world.rng, all_spells);

        for (u8 i = 0; i < world.num_spells; i += 1) {
            world.spells[i] = all_spells[i % ALL_SPELL_NAMES_LENGTH];
        }
    }

    for (u8 i = 0; i < WORLD_SOUND_SPEC_COUNT; i += 1) {
        world.sound_specs[i] = world_spec.sound_specs[i];
    }

    return world_ok(world);
}

local update_event woop(struct world* world) {
    update_event output = {0};

    maybe_monster maybe_player = get_player(world);

    if (maybe_player.kind == SOME) {
        tile_result t_r = random_passable_tile(&world->rng, world->tiles);
        if (t_r.kind == OK) {
            move(world, maybe_player.payload, t_r.result.xy);
        } else {
            // If the player tries to teleport when there is no free space
            // I'm not sure what else they would expect to happen. But I
            // know that they wouldn't want the game to freeze with an error.
        }
    }

    return output;
}

local update_event quake(struct world* world) {
    update_event output = {0};

    for (u8 y = 0; y < NUM_TILES; y += 1) {
        for (u8 x = 0; x < NUM_TILES; x += 1) {
            tile_xy xy = {x, y};
            tile t = get_tile(world->tiles, xy);

            if (t.maybe_monster.kind == SOME) {
                monster target = t.maybe_monster.payload;

                tile_list unfiltered_neighbors = get_adjacent_neighbors(
                    &world->rng,
                    world->tiles,
                    xy
                );
            
                u8 passable_count = 0;
                for (u8 i = 0; i < unfiltered_neighbors.length; i += 1) {
                    if (is_passable(unfiltered_neighbors.pool[i])) {
                        passable_count += 1;
                    }
                }

                u8 num_walls = 4 - passable_count;

                hit(&target, num_walls * 4);

                if (is_player(target)) {
                    push_sound_saturating(world, SOUND_HIT_1);
                } else {
                    push_sound_saturating(world, SOUND_HIT_2);
                }

                set_monster(world->tiles, target);
            }
        }
    }

    world->shake.amount = 20;

    return output;
}

local update_event maelstrom(struct world* world) {
    update_event output = {0};

    monster_list monsters = get_monsters(world->tiles);

    for (u8 i = 0; i < monsters.length; i += 1) {
        monster monster = monsters.pool[i];
        monster.teleport_counter = 2;

        tile_result t_r = random_passable_tile(&world->rng, world->tiles);
        if (t_r.kind == OK) {
            move(world, monster, t_r.result.xy);
        } else {
            // If there is no free space, the player would likely prefer that we
            // just set the teleport counter and move on, instead of causing the
            // game to freeze with an error.
            set_monster(world->tiles, monster);
        }
    }

    return output;
}

local update_event mulligan(struct world* world) {
    update_event output = {0};

    world_spec spec = {0};
    spec.level = world->level;
    spec.half_hp = 2;
    spec.num_spells = world->num_spells;

    spec.read_spells = true;
    for (u8 i = 0; i < spec.num_spells; i += 1) {
        spec.spells[i] = world->spells[i];
    }

    for (u8 i = 0; i < WORLD_SOUND_SPEC_COUNT; i += 1) {
        spec.sound_specs[i] = world->sound_specs[i];
    }

    world_result result = world_from_rng(
        world->rng,
        spec
    );

    if (result.kind == ERR) {
        output = update_event_from_error(result.error);
    } else {
        *world = result.result;
    }

    return output;
}

local update_event aura(struct world* world) {
    update_event output = {0};

    maybe_monster maybe_player = get_player(world);

    if (maybe_player.kind == SOME) {
        tile_list neighbors = get_adjacent_neighbors(
            &world->rng,
            world->tiles,
            maybe_player.payload.xy
        );

        for (u8 i = 0; i < neighbors.length; i += 1) {
            tile t = neighbors.pool[i];

            set_effect(world->tiles, t.xy, 13);

            if (t.maybe_monster.kind == SOME) {
                heal(&t.maybe_monster.payload, 2);
                set_monster(world->tiles, t.maybe_monster.payload);
            }
        }

        set_effect(world->tiles, world->xy, 13);

        heal(&maybe_player.payload, 2);
        set_monster(world->tiles, maybe_player.payload);
    }

    return output;
}

local update_event dash(struct world* world) {
    update_event output = {0};

    maybe_monster maybe_player = get_player(world);

    if (maybe_player.kind == SOME) {
        tile_xy target_xy = world->xy;

        while (true) {
            tile t = get_neighbor(world->tiles, target_xy, world->last_move);
            if (is_passable(t) && t.maybe_monster.kind == NONE) {
                target_xy = t.xy;
            } else {
                break;
            }
        }

        if (target_xy.x != world->xy.x || target_xy.y != world->xy.y) {
            monster moved = move(world, maybe_player.payload, target_xy);

            tile_list neighbors = get_adjacent_neighbors(
                &world->rng,
                world->tiles,
                moved.xy
            );

            for (u8 i = 0; i < neighbors.length; i += 1) {
                tile t = neighbors.pool[i];

                if (t.maybe_monster.kind == SOME) {
                    monster m = t.maybe_monster.payload;
                    set_effect(world->tiles, t.xy, 14);

                    m.stunned = true;
                    hit(&m, 2);
                    set_monster(world->tiles, m);
                }
            }
        }
    }

    return output;
}

local update_event dig(struct world* world) {
    update_event output = {0};

    maybe_monster maybe_player = get_player(world);

    if (maybe_player.kind == SOME) {
        for (u8 x = 1; x < NUM_TILES - 1; x += 1) {
            for (u8 y = 1; y < NUM_TILES - 1; y += 1) {
                tile_xy xy = {x, y};
                tile t = get_tile(world->tiles, xy);

                if (!is_passable(t)) {
                    replace(world->tiles, t.xy, make_floor);
                }
            }
        }

        set_effect(world->tiles, world->xy, 13);

        heal(&maybe_player.payload, 4);
        set_monster(world->tiles, maybe_player.payload);
    }

    return output;
}

local update_event kingmaker(struct world* world) {
    update_event output = {0};

    monster_list monsters = get_monsters(world->tiles);

    for (u8 i = 0; i < monsters.length; i += 1) {
        monster m = monsters.pool[i];
        heal(&m, 2);
        set_monster(world->tiles, m);

        add_treasure(world->tiles, m.xy);
    }

    return output;
}

local update_event cast_spell(struct world* world, u8 index) {
    update_event output = {0};

    spell_name name = world->spells[index];

    spell_proc spell;
    switch (name) {
        case NO_SPELL:
            return output;
        case WOOP: {
            spell = woop;
        } break;
        case QUAKE: {
            spell = quake;
        } break;
        case MAELSTROM: {
            spell = maelstrom;
        } break;
        case MULLIGAN: {
            spell = mulligan;
        } break;
        case AURA: {
            spell = aura;
        } break;
        case DASH: {
            spell = dash;
        } break;
        case DIG: {
            spell = dig;
        } break;
        case KINGMAKER: {
            spell = kingmaker;
        } break;
    }
    
    world->spells[index] = NO_SPELL;

    output = spell(world);

    push_sound_saturating(world, SOUND_SPELL);
    tick(world);

    return output;
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
                m.offset_xy.x = ((offset_x)target.xy.x - (offset_x)m.xy.x) * OFFSET_MULTIPLE / 2;
                m.offset_xy.y = ((offset_y)target.xy.y - (offset_x)m.xy.y) * OFFSET_MULTIPLE / 2;
                set_monster(world->tiles, m);

                world->shake.amount = 5;

                hit(&target, 2);

                if (is_player(target)) {
                    push_sound_saturating(world, SOUND_HIT_1);
                } else {
                    push_sound_saturating(world, SOUND_HIT_2);
                }

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

typedef enum {
    TITLE_FIRST,
    TITLE_RETURN,
    RUNNING,
    DEAD,
    STATE_ERROR
} state_kind ;

typedef struct {
    state_kind kind;
    u8 padding[4];
    union {
        xs rng; // TITLE_FIRST
        struct world world; // TITLE_RETURN, RUNNING, DEAD
        error_kind error_kind; // STATE_ERROR
    };
} state;

local void shuffle(xs* rng, tile_list* list) {
    for (u8 i = 1; i < list->length; i += 1) {
        u32 r = xs_u32(rng, 0, i + 1);
        tile temp = list->pool[i];
        list->pool[i] = list->pool[r];
        list->pool[r] = temp;
    }
}

local void shuffle_spell_names(xs* rng, spell_name* list) {
    for (u8 i = 1; i < ALL_SPELL_NAMES_LENGTH; i += 1) {
        u32 r = xs_u32(rng, 0, i + 1);
        spell_name temp = list[i];
        list[i] = list[r];
        list[r] = temp;
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

local state state_from_error(error_kind error_kind) {
    return (state) {
        .kind = STATE_ERROR,
        .error_kind = error_kind,
    };
}

local state state_from_rng(xs rng) {
    world_result result = world_from_rng(
        rng,
        (world_spec){0}
    );

    if (result.kind == ERR) {
        return state_from_error(result.error);
    } else {
        return (state) {
            .kind = RUNNING,
            .world = result.result,
        };
    }
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
    if (m.teleport_counter) {
        m.teleport_counter -= 1;
    }

    if (m.stunned || m.teleport_counter) {
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
        case EATER: {
            tile_list unfiltered_neighbors = get_adjacent_neighbors(
                &world->rng,
                world->tiles,
                m.xy
            );

            tile_list neighbors = {0};
            for (u8 i = 0; i < unfiltered_neighbors.length; i += 1) {
                tile t = unfiltered_neighbors.pool[i];
                if (
                    !is_passable(t)
                    && in_bounds(t.xy)
                ) {
                    push_saturating(&neighbors, t);
                }
            }

            if(neighbors.length){
                replace(world->tiles, neighbors.pool[0].xy, make_floor);
                heal(&m, 1);
                set_monster(world->tiles, m);
            } else {
                do_stuff(world, m);
            }
        } break;
        case JESTER: {
            tile_list unfiltered_neighbors = get_adjacent_neighbors(
                &world->rng,
                world->tiles,
                m.xy
            );

            tile_list neighbors = {0};
            for (u8 i = 0; i < unfiltered_neighbors.length; i += 1) {
                tile t = unfiltered_neighbors.pool[i];
                if (is_passable(t)) {
                    push_saturating(&neighbors, t);
                }
            }

            if (neighbors.length) {
                tile_xy target_xy = neighbors.pool[0].xy;
                try_move(
                    world,
                    m,
                    (delta_xy) {
                        (delta_x)target_xy.x - (delta_x)m.xy.x,
                        (delta_y)target_xy.y - (delta_y)m.xy.y
                    }
                );
            }
        } break;
        case PLAYER: // Shouldn't happen.
        case BIRD:
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

    if (world->spawn_counter > 0) {
        world->spawn_counter -= 1;
    }
    if (world->spawn_counter == 0) {
        spawn_monster(&world->rng, world->tiles);
        world->spawn_counter = world->spawn_rate;
        if (world->spawn_rate > 0) {
            world->spawn_rate -= 1;
        }
    }

    tile player_tile = get_tile(world->tiles, world->xy);

    if (player_tile.treasure) {
        if (world->score < (score)(-1)) {
            world->score += 1;
        }

        if (world->score % 3 == 0 && world->num_spells < MAX_NUM_SPELLS) {
            world->num_spells += 1;

            // Add spell
            u8 i = world->num_spells - 1;

            spell_name all_spells[ALL_SPELL_NAMES_LENGTH] = {ALL_SPELL_NAMES_WITH_COMMAS};
            shuffle_spell_names(&world->rng, all_spells);

            if (world->spells[i] == NO_SPELL) {
                world->spells[i] = all_spells[0];
            }
        }

        push_sound_saturating(world, SOUND_TREASURE);

        remove_treasure(world->tiles, player_tile.xy);
        spawn_monster(&world->rng, world->tiles);
    }
}

local update_event move_player(struct world* world, delta_xy dxy) {
    update_event event = {0};

    maybe_monster maybe_player = get_player(world);

    if (maybe_player.kind == SOME) {
        maybe_monster maybe_moved = try_move(world, maybe_player.payload, dxy);

        if (maybe_moved.kind == SOME) {
            world->last_move = dxy;

            tick(world);
        }

        // We need the fresh player, with updated health, etc. after `tick`.
        maybe_monster fresh_player = get_player(world);
        
        bool on_exit = get_tile(world->tiles, world->xy).kind == EXIT;

        if (
            fresh_player.kind == NONE
            // let the player through the exit before getting killed
            || (!on_exit && is_dead(fresh_player.payload))
        ) {
            event.kind = PLAYER_DIED;
            event.score = world->score;
        } else {
            if (on_exit) {
                push_sound_saturating(world, SOUND_NEW_LEVEL);

                if (world->level >= MAX_LEVEL) {
                    event.kind = COMPLETED_RUN;
                    event.score = world->score;
                } else {
                    world_spec spec = (world_spec) {
                        .level = world->level + 1,
                        .score = world->score,
                        .half_hp = fresh_player.payload.half_hp + 1 > MAX_HALF_HP
                            ? MAX_HALF_HP
                            : fresh_player.payload.half_hp + 1,
                        .num_spells = world->num_spells,
                    };
                    for (u8 i = 0; i < WORLD_SOUND_SPEC_COUNT; i += 1) {
                        spec.sound_specs[i] = world->sound_specs[i];
                    }

                    world_result result = world_from_rng(
                        world->rng,
                        spec
                    );
    
                    if (result.kind == OK) {
                        *world = result.result;
                    } else {
                        event = update_event_from_error(result.error);
                    }
                }
            }
        }
    }

    return event;
}

local i16 i16_signum(i16 x) {
    if (x == 0) {
        return 0;
    } else if (x > 0) {
        return 1;
    } else {
        return -1;
    }
}

local void begin_game_frame(struct world* world) {
    clear_sounds(world);

    for (u8 i = 0; i < TILE_COUNT; i += 1) {
        tile* t = &world->tiles[i];

        // Monster offsets
        if (t->maybe_monster.kind == SOME) {
            t->maybe_monster.payload.offset_xy.x -= i16_signum(t->maybe_monster.payload.offset_xy.x);
            t->maybe_monster.payload.offset_xy.y -= i16_signum(t->maybe_monster.payload.offset_xy.y);
        }

        // Tile Effects
        if (t->effect_counter) {
            t->effect_counter -= 1;
        }
    }

    // Screenshake offsets
    shake* shake = &world->shake;
    if (shake->amount > 0) {
        shake->amount -= 1;

        // An extremely approximate version of picking a random angle, taking
        // cos/sin of the angle, multiplying that by shake->amount.
        
        // We ask for 2 more random bits to determine the quadrant.
        offset_x max_offset = ((offset_x)shake->amount) * OFFSET_MULTIPLE;
        u32 shake_spec = xs_u32(&shake->rng, 0, ((u32)max_offset + 1) << 2);
        
        // Here we pull those bits out.
        u32 quadrant = shake_spec & ((1 << 2) - 1);
        // Here we slide those bits off to get random number from 0 to max_offset.
        shake->xy.x = (offset_x)(shake_spec >> 2);
        // On a unit square diamond, (our extreme appoximation to a unit circle)
        // |x| + |y| == 1
        // We skip the absolute value part by staying in the positive quadrant for now.
        shake->xy.y = max_offset - shake->xy.x;
    
        // check each quadrant bit in turn to decide whether to flip across each axis.
        if ((quadrant & 1) == 0) {
            shake->xy.x *= -1;
        }
        if ((quadrant & 2) == 0) {
            shake->xy.y *= -1;
        }
    }
}

typedef enum {
    INPUT_NONE,
    INPUT_UP,
    INPUT_DOWN,
    INPUT_LEFT,
    INPUT_RIGHT,
    INPUT_PAGE_1,
    INPUT_PAGE_2,
    INPUT_PAGE_3,
    INPUT_PAGE_4,
    INPUT_PAGE_5,
    INPUT_PAGE_6,
    INPUT_PAGE_7,
    INPUT_PAGE_8,
    INPUT_PAGE_9,
} input;

local update_event update(state* state, input input) {
    update_event event = {0};

    switch(state->kind) {
        case TITLE_FIRST: {
            if (input != INPUT_NONE) {
                *state = state_from_rng(state->rng);
            }
        } break;
        case TITLE_RETURN: {
            if (input != INPUT_NONE) {
                *state = state_from_rng(state->world.rng);
            }
        } break;
        case RUNNING: {
            begin_game_frame(&state->world);

            switch (input) {
                case INPUT_NONE:
                    // do nothing
                break;
                case INPUT_UP:
                    event = move_player(&state->world, (delta_xy){0, -1});
                break;
                case INPUT_DOWN:
                    event = move_player(&state->world, (delta_xy){0, 1});
                break;
                case INPUT_LEFT:
                    event = move_player(&state->world, (delta_xy){-1, 0});
                break;
                case INPUT_RIGHT:
                    event = move_player(&state->world, (delta_xy){1, 0});
                break;
                case INPUT_PAGE_1:
                case INPUT_PAGE_2:
                case INPUT_PAGE_3:
                case INPUT_PAGE_4:
                case INPUT_PAGE_5:
                case INPUT_PAGE_6:
                case INPUT_PAGE_7:
                case INPUT_PAGE_8:
                case INPUT_PAGE_9: {
                    // Apparently enum conversion to int is defined
                    u8 page_index = (u8)((int)input - (int)INPUT_PAGE_1);
                    event = cast_spell(&state->world, page_index);
                } break;
            }

            switch (event.kind) {
                case NOTHING_INTERESTING:
                    return event;
                break;
                case PLAYER_DIED:
                    state->kind = DEAD;
                break;
                case COMPLETED_RUN:
                    state->kind = TITLE_RETURN;
                break;
                case UPDATE_ERROR:
                    *state = state_from_error(event.error_kind);
                break;
            }
        } break;
        case DEAD: {
            begin_game_frame(&state->world);

            if (input != INPUT_NONE) {
                state->kind = TITLE_RETURN;
            }
        } break;
        case STATE_ERROR: {
            // do nothing
        } break;
    }

    return event;
}
