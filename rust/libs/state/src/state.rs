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

#[derive(Default)]
pub struct TileXY {
    pub x: TileX,
    pub y: TileY,
}

#[derive(Default)]
pub struct State {
    pub xy: TileXY
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