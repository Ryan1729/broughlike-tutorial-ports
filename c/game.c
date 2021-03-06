local const u8 NUM_TILES = 9;
local const u8 UI_WIDTH = 4;

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
