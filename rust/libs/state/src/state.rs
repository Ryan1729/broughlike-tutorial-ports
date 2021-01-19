#![no_std]
#![deny(clippy::float_arithmetic)]

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