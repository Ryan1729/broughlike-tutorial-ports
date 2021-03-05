#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpadded"
#endif

#include "include/raylib.h"

#ifdef __clang__
#pragma clang diagnostic pop
#endif

#define local static
#define u8 unsigned char

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

typedef u8 tile_x;
typedef u8 tile_y;

local tile_x x = 0;
local tile_y y = 0;

local void draw(void) {
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

    DrawRectangle(
        sizes.play_area_x + x * sizes.tile,
        sizes.play_area_y + y * sizes.tile,
        sizes.tile,
        sizes.tile,
        BLACK
    );
}

int main(void) {
    InitWindow(0, 0, "AWESOME BROUGHLIKE");

    SetTargetFPS(60);

    sizes = fresh_sizes();

    while (!WindowShouldClose()) {
        if (IsKeyPressed(KEY_F11)) {
            ToggleFullscreen();
            sizes = fresh_sizes();
        }

        if (IsKeyPressed(KEY_W) || IsKeyPressed(KEY_UP)) {
            y -= 1;
        }
        if (IsKeyPressed(KEY_S) || IsKeyPressed(KEY_DOWN)) {
            y += 1;
        }
        if (IsKeyPressed(KEY_A) || IsKeyPressed(KEY_LEFT)) {
            x -= 1;
        }
        if (IsKeyPressed(KEY_D) || IsKeyPressed(KEY_RIGHT)) {
            x += 1;
        }

        BeginDrawing();

        draw();

        EndDrawing();
    }

    CloseWindow();

    return 0;
}
