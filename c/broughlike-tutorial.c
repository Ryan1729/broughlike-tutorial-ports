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

local void draw_sprite(sprite_index sprite, tile_xy xy) {
    Rectangle spritesheet_rect = {
        .x = (float) sprite * 16,
        .y = 0,
        .width = 16,
        .height = 16,
    };

    Rectangle render_rect = {
        .x = (float) (sizes.play_area_x + (screen_size)xy.x * sizes.tile),
        .y = (float) (sizes.play_area_y + (screen_size)xy.y * sizes.tile),
        .width = (float) (sizes.tile),
        .height = (float) (sizes.tile),
    };

    Vector2 vec2 = {
        .x = (float)xy.x,
        .y = (float)xy.y,
    };

    DrawTexturePro(
        spritesheet,
        spritesheet_rect,
        render_rect,
        vec2,
        0.0,
        WHITE
    );
}

local void draw_world(struct world* world) {
    ClearBackground(INDIGO);

    // the -1 and +2 business makes the border lie just outside the actual
    // play area
    DrawRectangleLines(
        sizes.play_area_x - 1,
        sizes.play_area_y - 1,
        sizes.play_area_w + 2,
        sizes.play_area_h + 2,
        WHITE
    );

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

        draw_sprite(sprite, t.xy);
    }

    draw_sprite(0, world->xy);
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

    world_result result = world_from_rng(rng);

    if (result.kind == ERR) {
        switch (result.error) {
            case ERROR_ZERO:
                printf("Incorrectly initialized result type!?\n");
                // We don't want to return 0 in this case.
                // I guess we might as well not collide with sysexits.h,
                // since we won't need that many error types.
            return 63;
            case ERROR_NO_PASSABLE_TILE:
                printf("No passable tile could be found.\n");
            break;
            case ERROR_GENERATE_TILES_NEEDS_TO_BE_PASSED_A_BUFFER:
                printf("Internal error: GENERATE_TILES_NEEDS_TO_BE_PASSED_A_BUFFER\n");
            break;
            case ERROR_MAP_GENERATION_TIMEOUT:
                printf("Map generation timed out.\n");
            break;
        }

        return (int) result.error;
    }

    struct world world = result.result;

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

        update(&world, input);

        BeginDrawing();

        draw_world(&world);

        EndDrawing();
    }

    CloseWindow();
    UnloadTexture(spritesheet);
    UnloadImage(spritesheet_img);

    return 0;
}
