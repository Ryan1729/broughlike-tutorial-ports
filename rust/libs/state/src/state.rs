#![no_std]
#![deny(clippy::float_arithmetic)]

#[derive(Debug)]
pub enum Error {
    TimeoutWhileTryingTo(&'static str)
}

pub type Res<A> = Result<A, Error>;

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

/// The number of tiles across and tall that the grid is.
pub const NUM_TILES: TileCount = 9;

pub const UI_WIDTH: TileCount = 4;

pub type TileX = u8;
pub type TileY = u8;

#[derive(Clone, Copy, Default, PartialEq, Eq)]
pub struct TileXY {
    pub x: TileX,
    pub y: TileY,
}

// Should only be in the range [-1, 0, 1]
pub type DeltaX = i8;
// Should only be in the range [-1, 0, 1]
pub type DeltaY = i8;

#[derive(Clone, Copy, Default, PartialEq, Eq)]
pub struct DeltaXY {
    pub x: DeltaX,
    pub y: DeltaY,
}

macro_rules! dxy {
    ($x: literal, $y: literal) => {
        DeltaXY {
            x: $x,
            y: $y,
        }
    };
    ($x: ident, $y: ident) => {
        DeltaXY {
            x: $x,
            y: $y,
        }
    };
}

pub type SpriteIndex = u8;

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum TileKind {
    Wall,
    Floor,
}

impl Default for TileKind {
    fn default() -> Self {
        Self::Wall
    }
}

// TODO
type Monster = ();

#[derive(Clone, Copy, Default, PartialEq, Eq)]
pub struct Tile {
    pub xy: TileXY,
    pub kind: TileKind,
    pub monster: Option<Monster>
}

impl Tile {
    fn is_passable(&self) -> bool {
        matches!(self.kind, TileKind::Floor)
    }
}

const TOTAL_TILE_COUNT: TileCount = NUM_TILES * NUM_TILES;

pub struct Tiles([Tile; TOTAL_TILE_COUNT as _]);

fn make_wall(xy: TileXY) -> Tile {
    Tile {
        xy,
        kind: TileKind::Wall,
        ..<_>::default()
    }
}

fn make_floor(xy: TileXY) -> Tile {
    Tile {
        xy,
        kind: TileKind::Floor,
        ..<_>::default()
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
    pub fn from_seed(mut seed: Seed) -> Res<Self> {
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

        let tiles = generate_level(&mut rng)?;

        random_passable_tile(&mut rng, &tiles).map(|t| {
            Self {
                xy: t.xy,
                rng,
                tiles,
            }   
        })
    }
}

fn generate_level(rng: &mut Xs) -> Res<Tiles> {
    try_to(
        "generate map",
        || {
            let (tiles, passable_count) = generate_tiles(rng);

            let reachable_count = random_passable_tile(rng, &tiles)
                .map(|t| {
                    get_connected_tiles(rng, &tiles, t).length
                }).map_err(|_| ())?;

            if reachable_count == passable_count{
                Ok(tiles)
            } else {
                Err(())
            }
        }
    )    
}

fn generate_tiles(rng: &mut Xs) -> (Tiles, TileCount) {
    let mut tiles = [Tile::default(); TOTAL_TILE_COUNT as _];

    let mut passable_tiles = 0;

    for y in 0..NUM_TILES {
        for x in 0..NUM_TILES {
            let xy = TileXY{ x, y };
            let i = xy_to_i(xy);

            if !in_bounds(xy) || xs_u32(rng, 0, 10) < 3 {
                tiles[i] = make_wall(xy);
            }else{
                tiles[i] = make_floor(xy);

                passable_tiles += 1;
            }
        }
    }

    (Tiles(tiles), passable_tiles)
}

#[derive(Clone)]
struct TileStack {
    pool: [Tile; TOTAL_TILE_COUNT as _],
    length: TileCount,
}

impl TileStack {
    fn push_saturating(&mut self, tile: Tile) {
        if self.length as usize >= self.pool.len() {
            debug_assert!(
                !(self.length as usize >= self.pool.len()),
                "TileStack overflow!"
            );
            return;
        }

        self.pool[self.length as usize] = tile;
        self.length += 1;
    }

    fn iter(&self) -> impl Iterator<Item = &Tile> {
        self.pool.iter().take(self.length as _)
    }
}

fn get_connected_tiles(rng: &mut Xs, tiles: &Tiles, tile: Tile) -> TileStack {
    let mut connected = TileStack{
        pool: [Tile::default(); TOTAL_TILE_COUNT as _],
        length: 0,
    };

    connected.push_saturating(tile);

    let mut frontier = connected.clone();

    while frontier.length > 0 {
        // We currently know frontier.length > 0
        let popped: Tile = frontier.pool[frontier.length as usize - 1];
        frontier.length -= 1;

        let neighbors = get_adjacent_neighbors(rng, tiles, popped.xy);

        let mut filtered = neighbors.iter()
                            .filter(|t| t.is_passable())
                            .filter(|n|
                                !connected.iter().any(|c| c == *n)
                            );
        let filtered = [filtered.next(), filtered.next(), filtered.next(), filtered.next()];

        for tile in filtered.iter() {
            if let Some(&t) = tile {
                connected.push_saturating(t);
                frontier.push_saturating(t);
            }        
        }
    }

    connected
}

fn get_adjacent_neighbors(
    rng: &mut Xs,
    tiles: &Tiles,
    xy: TileXY
) -> [Tile; 4] {
    let mut neighbors = [
        get_neighbor(tiles, xy, dxy!(0, -1)),
        get_neighbor(tiles, xy, dxy!(0, 1)),
        get_neighbor(tiles, xy, dxy!(-1, 0)),
        get_neighbor(tiles, xy, dxy!(1, 0))
    ];

    shuffle(rng, &mut neighbors);

    neighbors
}

fn shuffle<A>(rng: &mut Xs, slice: &mut [A]) {
    for i in 1..slice.len() as u32 {
        // This only shuffles the first u32::MAX_VALUE elements.
        let r = xs_u32(rng, 0, i) as usize;
        let i = i as usize;
        slice.swap(i, r);
    }
}

fn get_neighbor(
    tiles: &Tiles,
    TileXY{x, y}: TileXY,
    dxy!{dx, dy}: DeltaXY,
) -> Tile {
    tiles.get_tile(
        TileXY {
            x: (x as DeltaX + dx) as TileX,
            y: (y as DeltaY + dy) as TileY,
        }
    )
}

fn random_passable_tile(rng: &mut Xs, tiles: &Tiles) -> Res<Tile> {
    try_to(
        "get random passable tile",
        || {
            use core::convert::TryInto;
            let x = xs_u32(rng, 0, (NUM_TILES-1).into()).try_into().map_err(|_| ())?;
            let y = xs_u32(rng, 0, (NUM_TILES-1).into()).try_into().map_err(|_| ())?;
            let tile = Tiles::get_tile(tiles, TileXY{x, y});
            if tile.is_passable() && tile.monster.is_none(){
                Ok(tile)
            } else {
                Err(())
            }
        }
    )
}

fn try_to<Out, F>(description: &'static str, mut callback: F) -> Res<Out>
where 
    F: FnMut() -> Result<Out, ()> {

    for _ in 0..1000 {
        if let Ok(out) = callback() {
            return Ok(out);
        }
    }

    Err(Error::TimeoutWhileTryingTo(description))
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