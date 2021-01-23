#![no_std]
#![deny(clippy::float_arithmetic)]

type Xs = [core::num::Wrapping<u32>; 4];

fn xorshift(xs: &mut Xs) -> u32 {
    let mut t = xs[3];

    xs[3] = xs[2];
    xs[2] = xs[1];
    xs[1] = xs[0];

    t ^= t << 11;
    t ^= t >> 8;
    xs[0] = t ^ xs[0] ^ (xs[0] >> 19);

    xs[0].0
}

fn xs_u32(xs: &mut Xs, min: u32, max: u32) -> u32 {
    (xorshift(xs) % (max - min)) + min
}

pub type TileCount = u8;

pub const NUM_TILES: TileCount = 9;
pub const UI_WIDTH: TileCount = 4;

pub type TileX = u8;
pub type TileY = u8;

#[derive(Clone, Copy, Default)]
pub struct TileXY {
    pub x: TileX,
    pub y: TileY,
}

pub type SpriteIndex = u8;

#[derive(Clone, Copy)]
pub enum TileKind {
    Wall,
    Floor,
}

impl Default for TileKind {
    fn default() -> Self {
        Self::Wall
    }
}

#[derive(Clone, Copy, Default)]
pub struct Tile {
    pub xy: TileXY,
    pub kind: TileKind,
}

pub struct Tiles([Tile; NUM_TILES as usize * NUM_TILES as usize]);

fn make_wall(xy: TileXY) -> Tile {
    Tile {
        xy,
        kind: TileKind::Wall,
    }
}

fn make_floor(xy: TileXY) -> Tile {
    Tile {
        xy,
        kind: TileKind::Floor,
    }
}

impl Tiles {
    pub fn iter(&self) -> impl Iterator<Item = &Tile> {
        self.0.iter()
    }

    pub fn get_tile(&self, xy: TileXY) -> Tile {
        if in_bounds(xy) {
            self.0[xy_to_i(xy)]
        } else {
            make_wall(xy)
        }
    }
}

fn in_bounds(TileXY{x, y}: TileXY) -> bool {
    x > 0 && y > 0 && x < NUM_TILES-1 && y < NUM_TILES-1
}

fn xy_to_i(TileXY{x, y}: TileXY) -> usize {
    (y * NUM_TILES + x) as _
}


pub struct State {
    pub xy: TileXY,
    rng: Xs,
    pub tiles: Tiles,
}

pub type Seed = [u8; 16];

impl State {
    pub fn from_seed(mut seed: Seed) -> Self {
        // 0 doesn't work as a seed, so use this one instead.
        if seed == [0; 16] {
            seed = 0xBAD_5EED_u128.to_le_bytes();
        }

        macro_rules! wrap {
            ($i0: literal, $i1: literal, $i2: literal, $i3: literal) => {
                core::num::Wrapping(
                    u32::from_le_bytes([
                        seed[$i0],
                        seed[$i1],
                        seed[$i2],
                        seed[$i3],
                    ])
                )
            }
        }

        let mut rng: Xs = [
            wrap!( 0,  1,  2,  3),
            wrap!( 4,  5,  6,  7),
            wrap!( 8,  9, 10, 11),
            wrap!(12, 13, 14, 15),
        ];

        let tiles = generate_tiles(&mut rng);

        Self {
            xy: TileXY::default(),
            rng,
            tiles,
        }
    }
}

fn generate_tiles(rng: &mut Xs) -> Tiles {
    let mut tiles = [Tile::default(); NUM_TILES as usize * NUM_TILES as usize];

    for y in 0..NUM_TILES {
        for x in 0..NUM_TILES {
            let xy = TileXY{ x, y };
            let i = xy_to_i(xy);

            if xs_u32(rng, 0, 10) < 3 {
                tiles[i] = make_wall(xy);
            }else{
                tiles[i] = make_floor(xy);
            }
        }
    }

    Tiles(tiles)
}

#[derive(Copy, Clone)]
pub enum Input {
    Empty,
    Up,
    Down,
    Left,
    Right,
}

pub fn update(state: &mut State, input: Input) {
    use Input::*;

    match input {
        Empty => {},
        Up => {
            state.xy.y = state.xy.y.saturating_sub(1);
        },
        Down => {
            state.xy.y = state.xy.y.saturating_add(1);
        },
        Left => {
            state.xy.x = state.xy.x.saturating_sub(1);
        },
        Right => {
            state.xy.x = state.xy.x.saturating_add(1);
        },
    }
}