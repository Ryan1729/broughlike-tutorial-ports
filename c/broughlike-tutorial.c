#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpadded"
#endif

#include "include/raylib.h"

#ifdef __clang__
#pragma clang diagnostic pop
#endif

#define local static
#define i8 char
#define u8 unsigned char
#define i16 short
#define u16 unsigned short
#define u32 unsigned long
#define u64 unsigned long long

#include "assets.c"
#include "game.c"

local const Color AQUA = { 0, 0xff, 0xff, 0xff };
local const Color INDIGO = { 0x4b, 0, 0x82, 0xff };
local const Color VIOLET_ALT = { 0xee, 0x82, 0xee, 0xff };
local const Color OVERLAY = { 0, 0, 0, 0xcc };

typedef int screen_size;

local screen_size min_screen_size(screen_size a, screen_size b) {
    return a < b ? a : b;
}

struct sizes {
    screen_size play_area_x;
    screen_size play_area_y;
    screen_size play_area_w;
    screen_size play_area_h;
    screen_size tile;
};

local struct sizes sizes = {0};

local struct sizes fresh_sizes(void) {
    screen_size w = GetScreenWidth();
    screen_size h = GetScreenHeight();

    screen_size tile = min_screen_size(
        w / (NUM_TILES + UI_WIDTH),
        h / NUM_TILES
    );

    screen_size play_area_w = tile * (NUM_TILES + UI_WIDTH);
    screen_size play_area_h = tile * NUM_TILES;
    screen_size play_area_x = (w - play_area_w) / 2;
    screen_size play_area_y = (h - play_area_h) / 2;

    struct sizes output = {
        .play_area_x = play_area_x,
        .play_area_y = play_area_y,
        .play_area_w = play_area_w,
        .play_area_h = play_area_h,
        .tile = tile,
    };

    return output;
}

local Texture2D spritesheet = {0};

struct sounds {
    Sound hit_1;
    Sound hit_2;
    Sound new_level;
    Sound spell;
    Sound treasure;
};

local struct sounds sounds = {0};

typedef struct {
    float x;
    float y;
} screen_xy;

typedef u8 alpha_byte;

local void draw_sprite_alpha(
    sprite_index sprite,
    screen_xy xy,
    alpha_byte alpha
) {
    Rectangle spritesheet_rect = {
        .x = (float) sprite * 16,
        .y = 0,
        .width = 16,
        .height = 16,
    };

    Rectangle render_rect = {
        .x = (float) (sizes.play_area_x) + xy.x,
        .y = (float) (sizes.play_area_y) + xy.y,
        .width = (float) (sizes.tile),
        .height = (float) (sizes.tile),
    };

    Color tint = WHITE;
    tint.a = alpha;

    DrawTexturePro(
        spritesheet,
        spritesheet_rect,
        render_rect,
        (Vector2){0},
        0.0,
        tint
    );
}

local void draw_sprite(sprite_index sprite, screen_xy xy) {
    draw_sprite_alpha(sprite, xy, 255);
}

#define offset_to_float(o) \
    ((float)o / (float) OFFSET_MULTIPLE) \

local void draw_sprite_tile_alpha(
    sprite_index sprite,
    tile_xy xy,
    offset_xy shake,
    alpha_byte alpha
) {
    draw_sprite_alpha(
        sprite,
        (screen_xy) {
            (float)((screen_size)xy.x * sizes.tile) + offset_to_float(shake.x),
            (float)((screen_size)xy.y * sizes.tile) + offset_to_float(shake.y)
        },
        alpha
    );
}

local void draw_sprite_tile(sprite_index sprite, tile_xy xy, offset_xy shake) {
    draw_sprite_tile_alpha(
        sprite,
        xy,
        shake,
        255
    );
}

local void draw_error_text(const char* error_text) {
    DrawText(
        error_text,
        sizes.play_area_x,
        sizes.play_area_y,
        40,
        RED
    );
}

#define MAX_STACK_STRING_LENGTH 254

typedef struct {
    u8 length;
    char chars[MAX_STACK_STRING_LENGTH];
    char final_terminating_zero;
} stack_string;

local void push_chars_saturating(stack_string* str, const char* chars) {
    while (str->length <= MAX_STACK_STRING_LENGTH && *chars) {
        str->chars[str->length] = *chars;
        str->length += 1;

        chars += 1;
    }
}

local void push_u8_chars_saturating(stack_string* str, u8 n) {
    if (n == 0) {
        str->chars[str->length] = '0';
        str->length += 1;
    } else {
        u8 unit = 100;
        while (unit) {
            if (n >= unit) {
                str->chars[str->length] = '0' + (char)(n / unit);
                str->length += 1;
                n %= unit;
            }
    
            unit /= 10;
        }
    }
}

local void push_u16_chars_saturating(stack_string* str, u16 n) {
    if (n == 0) {
        str->chars[str->length] = '0';
        str->length += 1;
    } else {
        u16 unit = 10000;
        while (unit) {
            if (n >= unit) {
                str->chars[str->length] = '0' + (char)(n / unit);
                str->length += 1;
                n %= unit;
            }
    
            unit /= 10;
        }
    }
}

local void clear_chars(stack_string* str) {
    *str = (stack_string) {0};
}

// Just for fun, let's reduce our reliance on the c stdlib
local int null_terminated_string_len(const char* str) {
    int output = 0;
    while (*str) {
        output += 1;
        str += 1;
    }

    return output;
}

typedef enum {
    TITLE,
    UI,
    SCORE_HEADER,
    SCORE_COL_1,
    SCORE_COL_2,
    SCORE_COL_3,
} text_mode;

typedef struct {
    const stack_string* text;
    text_mode text_mode;
    screen_size y;
    Color colour;
    u8 padding[4];
} text_spec;

local const screen_size UI_FONT_SIZE = 40;
local const screen_size TITLE_FONT_SIZE = 50;

local const char* LONGEST_TILE_LINE = "Broughlike in";

local stack_string right_pad(int size, const char** text_array){
    stack_string output = {0};

    for (int i = 0; i < size; i += 1) {
        const char* text = text_array[i];

        push_chars_saturating(&output, text);

        int length = null_terminated_string_len(text);
        for (int j = length; j < 10; j += 1) {
            push_chars_saturating(&output, " ");
        }
    }

    return output;
}

local const char* SCORE_HEADERS_ARRAY[3] = {"RUN","SCORE","TOTAL"};

local stack_string score_header;
local stack_string score_header_first_column;
local stack_string score_header_first_two_columns;

local void init_score_headers() {
    score_header = right_pad(3, SCORE_HEADERS_ARRAY);
    score_header_first_column = right_pad(1, SCORE_HEADERS_ARRAY);
    score_header_first_two_columns = right_pad(2, SCORE_HEADERS_ARRAY);
}

// This is to account for the fact that the last column has 5 extra spaces 
// after it, so the centering seems off, because it's based on the full text 
// width.
local const screen_size SCORE_NUDGE_IN_EMS = 5.0;

local void draw_text(text_spec spec) {
    screen_size size;
    screen_size x;

    const char* chars = (const char*) &spec.text->chars;

    int em = MeasureText("m", UI_FONT_SIZE);

    switch (spec.text_mode) {
        case TITLE: {
            size = TITLE_FONT_SIZE;
            x = (sizes.play_area_w - MeasureText(LONGEST_TILE_LINE, size))/2;
        } break;
        case UI: {
            size = UI_FONT_SIZE;
            x = ((screen_size) NUM_TILES) * sizes.tile + em;
        } break;
        case SCORE_HEADER: {
            size = UI_FONT_SIZE;
            x = (
                sizes.play_area_w 
                - MeasureText(chars, size)
                + SCORE_NUDGE_IN_EMS * em
            )/2;
        } break;
        case SCORE_COL_1: {
            size = UI_FONT_SIZE;
            x = (
                sizes.play_area_w 
                - MeasureText((const char*) score_header.chars, size)
                + SCORE_NUDGE_IN_EMS * em
            )/2;
        } break;
        case SCORE_COL_2: {
            size = UI_FONT_SIZE;
            x = (
                sizes.play_area_w 
                - MeasureText((const char*) score_header.chars, size)
                + SCORE_NUDGE_IN_EMS * em
            )/2 + MeasureText((const char*) score_header_first_column.chars, size);
        } break;
        case SCORE_COL_3: {
            size = UI_FONT_SIZE;
            x = (
                sizes.play_area_w 
                - MeasureText((const char*) score_header.chars, size)
                + SCORE_NUDGE_IN_EMS * em
            )/2 + MeasureText((const char*) score_header_first_two_columns.chars, size);
        } break;
    }

    DrawText(
        chars,
        sizes.play_area_x + x,
        spec.y,
        40,
        spec.colour
    );
}

// 64k runs ought to be enough for anybody.
typedef u16 runs;

typedef struct {
    score score;
    score total_score;
    runs run;
    bool active;
    u8 padding;
} score_row;

#define SCORE_LIST_COUNT 10

typedef struct {
    score_row pool[SCORE_LIST_COUNT];
    u8 length;
    bool fresh;
    u8 padding[2];
} score_list;

local void score_list_push_saturating(score_list* list, score_row row) {
    if (list->length < SCORE_LIST_COUNT) {
        list->pool[list->length] = row;
        list->length += 1;
    }
}

local void score_list_push_back_saturating(score_list* list, score_row row) {
    if (list->length < SCORE_LIST_COUNT) {
        for (u8 i = list->length; i > 0; i -= 1) {
            list->pool[i] = list->pool[i - 1];
        }
        list->pool[0] = row;
        list->length += 1;
    }
}

// maybe def {
typedef struct {
    maybe_kind kind;
    score_row payload;
} maybe_score_row;

local maybe_score_row some_score_row(score_row score_row) {
    return (maybe_score_row) {.kind = SOME, .payload = score_row};
}
// }

local maybe_score_row score_list_pop(score_list* list) {
    maybe_score_row output = {0};

    if (list->length) {
        output = some_score_row(list->pool[list->length - 1]);
        list->length -= 1;
    }

    return output;
}

local void sort_by_total_score_desc(score_list* list) {
    // This is used on lists that have at most SCORE_LIST_COUNT elements. So we 
    // don't really care how this scales, so bubble sort will do just fine.
    for (u8 i = 0; i < list->length; i += 1) {
        for (u8 j = i + 1; j < list->length; j += 1) {
            score total_score_i = list->pool[i].total_score;
            score total_score_j = list->pool[j].total_score;

            if (total_score_i < total_score_j) {
                score_row temp = list->pool[i];
                list->pool[i] = list->pool[j];
                list->pool[j] = temp;
            }
        }
    }
}

local score_list get_scores(void);
local void sort_by_total_score_desc(score_list* list);

local void draw_scores() {
    score_list scores = get_scores();

    maybe_score_row maybe_newest_score = score_list_pop(&scores);

    if(maybe_newest_score.kind == SOME){
        score_row newest_score = maybe_newest_score.payload;

        draw_text((text_spec) {
            .text = &score_header,
            .text_mode = SCORE_HEADER,
            .y = sizes.play_area_y + (sizes.play_area_h / 2),
            .colour = WHITE,
        });

        sort_by_total_score_desc(&scores);

        score_list_push_back_saturating(&scores, newest_score);

        for (int i = 0; i < scores.length; i++) {
            score_row row = scores.pool[i];

            float row_h = (float)sizes.play_area_h * 1.0f / 24.0f;

            stack_string text = {0};

            text_spec spec = {
                .text = &text,
                .text_mode = SCORE_COL_1,
                .y = (screen_size)((float)sizes.play_area_y + ((float)sizes.play_area_h / 2)
                            + row_h + (float)i * row_h),
                .colour = i == 0 ? AQUA : VIOLET_ALT,
            };

            push_u16_chars_saturating(
                &text,
                row.run
            );

            draw_text(spec);
            
            clear_chars(&text);
            push_u16_chars_saturating(
                &text,
                row.score
            );
            spec.text_mode = SCORE_COL_2;

            draw_text(spec);

            clear_chars(&text);
            push_u16_chars_saturating(
                &text,
                row.total_score
            );
            spec.text_mode = SCORE_COL_3;

            draw_text(spec);
        }

    }
}

local void draw_title() {
    DrawRectangle(
        sizes.play_area_x - 1,
        sizes.play_area_y - 1,
        sizes.play_area_w + 2,
        sizes.play_area_h + 2,
        OVERLAY
    );

    screen_size y = TITLE_FONT_SIZE * 2;
    {
        stack_string line1 = {0};

        push_chars_saturating(&line1, "Awesome");

        draw_text((text_spec) {
            .text_mode = TITLE,
            .y = y,
            .colour = WHITE,
            .text = &line1,
        });
    }

    y += TITLE_FONT_SIZE;

    {
        stack_string line2 = {0};

        push_chars_saturating(&line2, LONGEST_TILE_LINE);

        draw_text((text_spec) {
            .text_mode = TITLE,
            .y = y,
            .colour = WHITE,
            .text = &line2,
        });
    }

    y += TITLE_FONT_SIZE;

    {
        stack_string line3 = {0};

        push_chars_saturating(&line3, "C");

        draw_text((text_spec) {
            .text_mode = TITLE,
            .y = y,
            .colour = WHITE,
            .text = &line3,
        });
    }

    draw_scores();
}

// Just for fun, let's reduce our reliance on the c stdlib
local float float_floor(float f) {
    // NaNs/Infs not handled
    long long n = (long long)f;
    return (float)n;
}

local void draw_world(struct world* world) {
    // the -1 and +2 business makes the border lie just outside the actual
    // play area
    DrawRectangleLines(
        sizes.play_area_x - 1,
        sizes.play_area_y - 1,
        sizes.play_area_w + 2,
        sizes.play_area_h + 2,
        WHITE
    );

    // We draw all the stationary sprites first so they don't cover the
    // moving sprites
    for (u8 i = 0; i < TILE_COUNT; i++) {
        tile t = world->tiles[i];

        sprite_index sprite = 0;
        switch (t.kind) {
            case WALL:
                sprite = 3;
            break;
            case FLOOR:
                sprite = 2;
            break;
            case EXIT:
                sprite = 11;
            break;
        }

        draw_sprite_tile(sprite, t.xy, world->shake.xy);

        if (t.treasure) {
            draw_sprite_tile(12, t.xy, world->shake.xy);
        }

        draw_sprite_tile_alpha(
            t.effect,
            t.xy,
            world->shake.xy,
            (alpha_byte)(
                ((float)t.effect_counter / (float)EFFECT_MAX)
                * 255.0f
            )
        );
    }

    for (u8 i = 0; i < TILE_COUNT; i++) {
        tile t = world->tiles[i];

        if (t.maybe_monster.kind == SOME) {
            monster m = t.maybe_monster.payload;

            if (m.teleport_counter) {
                draw_sprite_tile(10, m.xy, world->shake.xy);
                continue;
            }

            sprite_index sprite = 0;

            switch (m.kind) {
                case PLAYER:
                    sprite = is_dead(m) ? 1 : 0;
                break;
                case BIRD:
                    sprite = 4;
                break;
                case SNAKE:
                    sprite = 5;
                break;
                case TANK:
                    sprite = 6;
                break;
                case EATER:
                    sprite = 7;
                break;
                case JESTER:
                    sprite = 8;
                break;
            }

            display_xy disp_xy = get_display_xy(&m);
            float disp_x = offset_to_float(disp_xy.x);
            float disp_y = offset_to_float(disp_xy.y);

            draw_sprite(
                sprite,
                (screen_xy){
                    (float)sizes.tile
                    * (disp_x) + offset_to_float(world->shake.xy.x),
                    (float)sizes.tile
                    * (disp_y) + offset_to_float(world->shake.xy.y)
                }
            );

            // Drawing HP

            // A single half HP should be drawn as a pip.
            int hp = (m.half_hp + 1) / 2;
            for (int j = 0; j < hp; j += 1) {
                draw_sprite(
                    9,
                    (screen_xy){
                        (float)sizes.tile
                        * (disp_x + (j%3) * (5.0f/16.0f)) + offset_to_float(world->shake.xy.x),
                        (float)sizes.tile
                        * (disp_y - float_floor((float)j/3.0f) * (5.0f/16.0f)) + offset_to_float(world->shake.xy.y)
                    }
                );
            }
        }
    }

    stack_string level_text = {0};

    push_chars_saturating(&level_text, "Level: ");
    push_u8_chars_saturating(&level_text, world->level);

    screen_size y = 30;

    draw_text((text_spec) {
        .text_mode = UI,
        .y = y,
        .colour = VIOLET_ALT,
        .text = &level_text,
    });

    y += UI_FONT_SIZE;

    stack_string score_text = {0};

    push_chars_saturating(&score_text, "Score: ");
    push_u16_chars_saturating(&score_text, world->score);

    draw_text((text_spec) {
        .text_mode = UI,
        .y = y,
        .colour = VIOLET_ALT,
        .text = &score_text,
    });

    y += UI_FONT_SIZE;

    for (u8 i = 0; i < MAX_NUM_SPELLS; i += 1) {
        y += UI_FONT_SIZE;

        stack_string spell_text = {0};

        push_u8_chars_saturating(&spell_text, i + 1);
        push_chars_saturating(&spell_text, ") ");

        switch (world->spells[i]) {
            case NO_SPELL: {
                // do nothing
            } break;
            case WOOP: {
                push_chars_saturating(&spell_text, "WOOP");
            } break;
            case QUAKE: {
                push_chars_saturating(&spell_text, "QUAKE");
            } break;
            case MAELSTROM: {
                push_chars_saturating(&spell_text, "MAELSTROM");
            } break;
            case MULLIGAN: {
                push_chars_saturating(&spell_text, "MULLIGAN");
            } break;
            case AURA: {
                push_chars_saturating(&spell_text, "AURA");
            } break;
            case DASH: {
                push_chars_saturating(&spell_text, "DASH");
            } break;
            case DIG: {
                push_chars_saturating(&spell_text, "DIG");
            } break;
            case KINGMAKER: {
                push_chars_saturating(&spell_text, "KINGMAKER");
            } break;
            case ALCHEMY: {
                push_chars_saturating(&spell_text, "ALCHEMY");
            } break;
            case POWER: {
                push_chars_saturating(&spell_text, "POWER");
            } break;
            case BUBBLE: {
                push_chars_saturating(&spell_text, "BUBBLE");
            } break;
            case BRAVERY: {
                push_chars_saturating(&spell_text, "BRAVERY");
            } break;
            case BOLT: {
                push_chars_saturating(&spell_text, "BOLT");
            } break;
            case CROSS: {
                push_chars_saturating(&spell_text, "CROSS");
            } break;
            case EX: {
                push_chars_saturating(&spell_text, "EX");
            } break;
        }

        draw_text((text_spec) {
            .text_mode = UI,
            .y = y,
            .colour = AQUA,
            .text = &spell_text,
        });
    }
}

#include "errno.h"
#include "stdio.h"

local xs rng_from_seed(u64 seed) {
    // 0 doesn't work as a seed, so use this one instead.
    if (seed == 0) {
        seed = 0xBAD5EED;
    }

    printf("%lld\n", seed);

    xs rng = {
        seed & 0xffffffff,
        (seed >> 32) & 0xffffffff,
        seed & 0xffffffff,
        (seed >> 32) & 0xffffffff
    };

    return rng;
}

typedef struct {
    char save_path[FILENAME_MAX];
    score_list score_list;
} scores;

local scores scores_global = {0};

#if defined(_WIN32) || defined(_WIN64)
#include <direct.h>
#define get_current_dir _getcwd
local char path_sep = '\\';
#elif defined(__unix__)
#include <unistd.h>
#define get_current_dir getcwd
local char path_sep = '/';
#else
"Unsupported platform"
#endif

local void init_scores() {
    // We assume that scores_global is zeroed already.
    get_current_dir(scores_global.save_path, FILENAME_MAX);

    int i = null_terminated_string_len(scores_global.save_path);
    scores_global.save_path[i] = path_sep;

    const char* save_name = "broughlike-tutorial.sav";
    int extra_len = null_terminated_string_len(save_name);
    i += 1;

    for (int j = 0; j < extra_len; j += 1) {
        scores_global.save_path[i] = save_name[j];
        i += 1;
    }
}

typedef enum {
    PARSE_NO_ERROR,
    PARSE_EXPECTED_DIGIT_OR_TAB,
    PARSE_DIGIT_OVERFLOW,
    PARSE_NUMERIC_OVERFLOW,
    PARSE_EXPECTED_DIGIT_OR_NEWLINE,
} parse_error_kind;

typedef struct {
    parse_error_kind kind;
    int unexpected_char;
} parse_error;

typedef enum {
    EXPECTING_SCORE_COL,
    EXPECTING_TOTAL_SCORE_COL,
    EXPECTING_RUN_COL,
    EXPECTING_ACTIVE_COL,
} parse_state;

local parse_error parse_non_null_file_into(
    FILE* save_file,
    score_list* output
) {
    parse_state state = EXPECTING_SCORE_COL;

    score_row row = {0};

// We expect score to be a u16, and 65535 has 5 digits
#define PARSE_NUMBER_BUFFER_LEN 5    
    u8 number_buffer[PARSE_NUMBER_BUFFER_LEN] = {0};
    u8 number_buffer_index = 0;

#define PARSE_CLEAR_NUMBER_BUFFER \
    number_buffer[0] = 0;\
    number_buffer[1] = 0;\
    number_buffer[2] = 0;\
    number_buffer[3] = 0;\
    number_buffer[4] = 0;\
    number_buffer_index = 0;\

#define PARSE_PUSH_DIGIT_OR_SET(transition_char, row_field, target_state) \
    if (c >= '0' && c <= '9') {\
        if (number_buffer_index < PARSE_NUMBER_BUFFER_LEN) {\
            number_buffer[number_buffer_index] = (u8)(c - '0');\
            number_buffer_index += 1;\
        } else {\
            return (parse_error) {\
                .kind = PARSE_DIGIT_OVERFLOW,\
                .unexpected_char = c,\
            };\
        }\
    } else if (c == transition_char) {\
        score unit = 1;\
        for (u8 i = 0; i < number_buffer_index; i += 1) {\
            score prev_score = row_field;\
\
            row_field += number_buffer[i] * unit;\
            unit *= 10;\
\
            if (prev_score > row_field) {\
                return (parse_error) {\
                    .kind = PARSE_NUMERIC_OVERFLOW,\
                    .unexpected_char = c,\
                };\
            }\
        }\
\
        PARSE_CLEAR_NUMBER_BUFFER\
        state = target_state;\
    } else {\
        parse_error_kind err_kind = transition_char == '\t'\
            ? PARSE_EXPECTED_DIGIT_OR_TAB\
            : PARSE_EXPECTED_DIGIT_OR_NEWLINE;\
        return (parse_error) {\
            .kind = err_kind,\
            .unexpected_char = c,\
        };\
    }\

    int c; // note: int, not char, required to handle EOF
    while ((c = fgetc(save_file)) != EOF) {
        switch (state) {
            case EXPECTING_SCORE_COL: {
                PARSE_PUSH_DIGIT_OR_SET(
                    '\t',
                    row.score,
                    EXPECTING_TOTAL_SCORE_COL
                )
            } break;
            case EXPECTING_TOTAL_SCORE_COL: {
                PARSE_PUSH_DIGIT_OR_SET(
                    '\t',
                    row.total_score,
                    EXPECTING_RUN_COL
                )
            } break;
            case EXPECTING_RUN_COL: {
                // This relies on the fact that `runs` is the same size as `score`.
                PARSE_PUSH_DIGIT_OR_SET(
                    '\t',
                    row.run,
                    EXPECTING_ACTIVE_COL
                )
            } break;
            case EXPECTING_ACTIVE_COL: {
                score active_score = 0;

                PARSE_PUSH_DIGIT_OR_SET(
                    '\n',
                    active_score,
                    EXPECTING_SCORE_COL
                )

                if (state == EXPECTING_SCORE_COL) {
                    row.active = active_score != 0;

                    score_list_push_saturating(output, row);
                    row = (score_row) {0};

                    PARSE_CLEAR_NUMBER_BUFFER
                }
            } break;
        }
    }

    return (parse_error) {0};
}

local score_list get_scores() {
    score_list output = {0};

    if (scores_global.score_list.fresh) {
        for (u8 i = 0; i < scores_global.score_list.length; i += 1) {
            score_list_push_saturating(
                &output,
                scores_global.score_list.pool[i]
            );
        }
    } else {
        if (null_terminated_string_len(scores_global.save_path)) {
            FILE* save_file = fopen(scores_global.save_path, "rb");
    
            if (save_file == 0) {
                if (errno == ENOENT) {
                    // If there wasn't a file there yet, we'll write one when we
                    // complete a round.
                    scores_global.score_list.fresh = true;
                } else {
                    perror("Error opening file for reading");
                }
    
                // Presumably, the player thinks getting to play with no high
                // scores saved is better than not being able to play.
            } else {
                parse_error error = parse_non_null_file_into(
                    save_file,
                    &output
                );

                if (error.kind == PARSE_NO_ERROR) {
                    for (u8 i = 0; i < output.length; i += 1) {
                        score_list_push_saturating(
                            &scores_global.score_list,
                            output.pool[i]
                        );
                    }
                
                    scores_global.score_list.fresh = true;
                } else {
                    char* error_str;
                    switch (error.kind) {
                        case PARSE_NO_ERROR: {
                            // We already checked this, but for completeness sake.
                            error_str = "PARSE_NO_ERROR";
                        } break;
                        case PARSE_EXPECTED_DIGIT_OR_TAB: {
                            error_str = "PARSE_EXPECTED_DIGIT_OR_TAB";
                        } break;
                        case PARSE_DIGIT_OVERFLOW: {
                            error_str = "PARSE_DIGIT_OVERFLOW";
                        } break;
                        case PARSE_NUMERIC_OVERFLOW: {
                            error_str = "PARSE_NUMERIC_OVERFLOW";
                        } break;
                        case PARSE_EXPECTED_DIGIT_OR_NEWLINE: {
                            error_str = "PARSE_EXPECTED_DIGIT_OR_NEWLINE";
                        } break;
                    }

                    fprintf(
                        stderr,
                        "Error parsing save file: found '%c' %s\n",
                        error.unexpected_char,
                        error_str
                    );

                    output = (score_list) {0};
                }

                fclose(save_file);
            }
   
        }
    }

    return output;
}

local void add_score(update_event event) {
    score new_score;
    bool won;
    switch (event.kind) {
        case NOTHING_INTERESTING:
        case UPDATE_ERROR:
            return;
        case PLAYER_DIED: {
            new_score = event.score;
            won = false;
        } break;
        case COMPLETED_RUN: {
            new_score = event.score;
            won = true;
        } break;
    }
    
    score_list list = get_scores();
    score_row row = {
        .score = new_score,
        .run = 1,
        .total_score = new_score,
        .active = won,
    };

    maybe_score_row m_s_r = score_list_pop(&list);
    if (m_s_r.kind == SOME) {
        score_row last_score = m_s_r.payload;
        if (last_score.active) {
            row.run = last_score.run + 1;
            row.total_score += last_score.total_score;
        } else {
            score_list_push_saturating(&list, last_score);
        }
    }

    score_list_push_saturating(&list, row);

    if (null_terminated_string_len(scores_global.save_path)) {
        FILE* save_file = fopen(scores_global.save_path, "wb");

        if (save_file == 0) {
            perror("Error opening file for writing");

            // Presumably, the player thinks getting to play with no high
            // scores saved is better than not being able to play.
            return;
        }

        for (u8 i = 0; i < list.length; i += 1) {
            score_row r = list.pool[i];
            
            fprintf(
                save_file,
                "%u\t%u\t%u\t%u\n",
                r.score,
                r.total_score,
                r.run,
                r.active ? 1 : 0
            );
        }

        scores_global.score_list.fresh = false;

        fclose(save_file);
    }
}

#include "time.h"

int main(void) {
    InitWindow(0, 0, "AWESOME BROUGHLIKE");

    SetTargetFPS(60);

    InitAudioDevice();

    Image spritesheet_img = spritesheet_image();
    spritesheet = LoadTextureFromImage(spritesheet_img);

    Wave hit_1_wav = hit_1_wave();
    sounds.hit_1 = LoadSoundFromWave(hit_1_wav);

    Wave hit_2_wav = hit_2_wave();
    sounds.hit_2 = LoadSoundFromWave(hit_2_wav);

    Wave new_level_wav = new_level_wave();
    sounds.new_level = LoadSoundFromWave(new_level_wav);

    Wave spell_wav = spell_wave();
    sounds.spell = LoadSoundFromWave(spell_wav);

    Wave treasure_wav = treasure_wave();
    sounds.treasure = LoadSoundFromWave(treasure_wav);

    sizes = fresh_sizes();

    init_score_headers();
    init_scores();
    printf("Will save to: %s\n", scores_global.save_path);

    u64 seed = (u64) time(0);

    xs rng = rng_from_seed(seed);

    state state = {
        .kind = TITLE_FIRST,
        .rng = rng,
    };

    while (!WindowShouldClose()) {
        if (IsKeyPressed(KEY_F11)) {
            ToggleFullscreen();
            sizes = fresh_sizes();
        }

        input input = INPUT_NONE;

        if (IsKeyPressed(KEY_W) || IsKeyPressed(KEY_UP)) {
            input = INPUT_UP;
        }
        if (IsKeyPressed(KEY_S) || IsKeyPressed(KEY_DOWN)) {
            input = INPUT_DOWN;
        }
        if (IsKeyPressed(KEY_A) || IsKeyPressed(KEY_LEFT)) {
            input = INPUT_LEFT;
        }
        if (IsKeyPressed(KEY_D) || IsKeyPressed(KEY_RIGHT)) {
            input = INPUT_RIGHT;
        }

        if (IsKeyPressed(KEY_ONE)) {
            input = INPUT_PAGE_1;
        }
        if (IsKeyPressed(KEY_TWO)) {
            input = INPUT_PAGE_2;
        }
        if (IsKeyPressed(KEY_THREE)) {
            input = INPUT_PAGE_3;
        }
        if (IsKeyPressed(KEY_FOUR)) {
            input = INPUT_PAGE_4;
        }
        if (IsKeyPressed(KEY_FIVE)) {
            input = INPUT_PAGE_5;
        }
        if (IsKeyPressed(KEY_SIX)) {
            input = INPUT_PAGE_6;
        }
        if (IsKeyPressed(KEY_SEVEN)) {
            input = INPUT_PAGE_7;
        }
        if (IsKeyPressed(KEY_EIGHT)) {
            input = INPUT_PAGE_8;
        }
        if (IsKeyPressed(KEY_NINE)) {
            input = INPUT_PAGE_9;
        }

        update_event event = update(&state, input);

        add_score(event);

        BeginDrawing();

        ClearBackground(INDIGO);

        switch(state.kind) {
            case TITLE_FIRST: {
                draw_title();
            } break;
            case TITLE_RETURN: {
                draw_world(&state.world);
                draw_title();
            } break;
            case RUNNING:
            case DEAD: {
                draw_world(&state.world);

                for (int i = 0; i < WORLD_SOUND_SPEC_COUNT; i += 1) {
                    Sound sound;
                    switch (state.world.sound_specs[i]) {
                        case SOUND_NONE:
                            continue;
                        case SOUND_HIT_1: {
                            sound = sounds.hit_1;
                        } break;
                        case SOUND_HIT_2: {
                            sound = sounds.hit_2;
                        } break;
                        case SOUND_NEW_LEVEL: {
                            sound = sounds.new_level;
                        } break;
                        case SOUND_SPELL: {
                            sound = sounds.spell;
                        } break;
                        case SOUND_TREASURE: {
                            sound = sounds.treasure;
                        } break;
                    }

                    PlaySoundMulti(sound);
                }
            } break;
            case STATE_ERROR: {
                switch (state.error_kind) {
                    case ERROR_ZERO:
                        draw_error_text("Incorrectly initialized result type!?\n");
                    break;
                    case ERROR_NO_PASSABLE_TILE:
                        draw_error_text("No passable tile could be found.\n");
                    break;
                    case ERROR_GENERATE_TILES_NEEDS_TO_BE_PASSED_A_BUFFER:
                        draw_error_text("Internal error: GENERATE_TILES_NEEDS_TO_BE_PASSED_A_BUFFER\n");
                    break;
                    case ERROR_MAP_GENERATION_TIMEOUT:
                        draw_error_text("Map generation timed out.\n");
                    break;
                }
            } break;
        }

        EndDrawing();
    }

    CloseWindow();

    UnloadTexture(spritesheet);
    UnloadImage(spritesheet_img);

    StopSoundMulti();

    CloseAudioDevice();

    UnloadSound(sounds.hit_1);
    UnloadSound(sounds.hit_2);
    UnloadSound(sounds.new_level);
    UnloadSound(sounds.spell);
    UnloadSound(sounds.treasure);

    UnloadWave(hit_1_wav);
    UnloadWave(hit_2_wav);
    UnloadWave(new_level_wav);
    UnloadWave(spell_wav);
    UnloadWave(treasure_wav);

    return 0;
}
