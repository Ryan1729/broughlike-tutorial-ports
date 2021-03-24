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
#define u16 unsigned short
#define u32 unsigned long
#define u64 unsigned long long

#include "assets.c"
#include "game.c"

local const Color INDIGO = { 0x4b, 0, 0x82, 0xff };
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

typedef struct {
    float x;
    float y;
} screen_xy;

local void draw_sprite(sprite_index sprite, screen_xy xy) {
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

    DrawTexturePro(
        spritesheet,
        spritesheet_rect,
        render_rect,
        (Vector2){0},
        0.0,
        WHITE
    );
}

local void draw_sprite_tile(sprite_index sprite, tile_xy xy) {
    draw_sprite(
        sprite,
        (screen_xy) {
            (float)((screen_size)xy.x * sizes.tile),
            (float)((screen_size)xy.y * sizes.tile)
        }
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

local void draw_title() {
    DrawRectangle(
        sizes.play_area_x - 1,
        sizes.play_area_y - 1,
        sizes.play_area_w + 2,
        sizes.play_area_h + 2,
        OVERLAY
    );
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
        }

        draw_sprite_tile(sprite, t.xy);
    }

    for (u8 i = 0; i < TILE_COUNT; i++) {
        tile t = world->tiles[i];

        if (t.maybe_monster.kind == SOME) {
            monster m = t.maybe_monster.payload;

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

            draw_sprite_tile(sprite, m.xy);

            // Drawing HP

            // A single half HP should be drawn as a pip.
            int hp = (m.half_hp + 1) / 2;
            for (int j = 0; j < hp; j += 1) {
                draw_sprite(
                    9,
                    (screen_xy){
                        (float)sizes.tile
                        * ((float)m.xy.x + (j%3) * (5.0f/16.0f)),
                        (float)sizes.tile
                        * ((float)m.xy.y - float_floor((float)j/3.0f) * (5.0f/16.0f))
                    }
                );
            }
        }
    }
}

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

#include "time.h"

int main(void) {
    InitWindow(0, 0, "AWESOME BROUGHLIKE");

    SetTargetFPS(60);

    Image spritesheet_img = spritesheet_image();
    spritesheet = LoadTextureFromImage(spritesheet_img);

    sizes = fresh_sizes();

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

        update(&state, input);

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

    return 0;
}
