use state::{State, Input};

const INDIGO: macroquad::Color = macroquad::Color([0x4b, 0, 0x82, 0xff]);

#[macroquad::main("AWESOME BROUGHLIKE")]
async fn main() {
    let state: &mut State = &mut State::default();

    type Size = f32;

    struct Sizes {
        play_area_x: Size,
        play_area_y: Size,
        play_area_w: Size,
        play_area_h: Size,
        tile: Size,
    }

    fn fresh_sizes() -> Sizes {
        let w = macroquad::screen_width();
        let h = macroquad::screen_height();

        let w_in_tiles = (state::NUM_TILES + state::UI_WIDTH) as Size;
        let h_in_tiles = state::NUM_TILES as Size;

        let tile = Size::min(
            w / w_in_tiles,
            h / h_in_tiles,
        );

        let play_area_w = tile * w_in_tiles;
        let play_area_h = tile * h_in_tiles;
        let play_area_x = (w - play_area_w) / 2.;
        let play_area_y = (h - play_area_h) / 2.;

        Sizes {
            play_area_x,
            play_area_y,
            play_area_w,
            play_area_h,
            tile,
        }
    }

    loop {
        let sizes = fresh_sizes();

        macroquad::clear_background(INDIGO);
        let mut input = Input::Empty;
        macro_rules! take_input {
            ($input: ident) => {
                take_input!($input, $input)
            };
            ($input: ident, $key_code: ident) => {
                if macroquad::is_key_pressed(macroquad::KeyCode::$key_code) {
                    input = Input::$input;
                }
            }
        }
        take_input!(Right);
        take_input!(Right, D);
        take_input!(Left);
        take_input!(Left, A);
        take_input!(Down);
        take_input!(Down, S);
        take_input!(Up);
        take_input!(Up, W);

        state::update(state, input);

        // the -1 and +2 business makes the border lie just outside the actual
        // play area
        macroquad::draw_rectangle_lines(
            sizes.play_area_x - 1.,
            sizes.play_area_y - 1.,
            sizes.play_area_w + 2.,
            sizes.play_area_h + 2.,
            1.,
            macroquad::WHITE
        );

        macroquad::draw_rectangle(
            sizes.play_area_x + sizes.tile * (state.xy.x as Size),
            sizes.play_area_y + sizes.tile * (state.xy.y as Size),
            sizes.tile,
            sizes.tile,
            macroquad::WHITE
        );

        macroquad::next_frame().await
    }
}