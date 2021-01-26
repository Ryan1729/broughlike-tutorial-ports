#[deny(unused)]
use state::{State, Input};

const INDIGO: macroquad::Color = macroquad::Color([0x4b, 0, 0x82, 0xff]);

const SPRITESHEET_BYTES: &[u8] = include_bytes!("../assets/spritesheet.png");

#[macroquad::main("AWESOME BROUGHLIKE")]
async fn main() {
    let spritesheet = {
        let ctx = &mut miniquad::graphics::Context::new();
        let texture = macroquad::Texture2D::from_file_with_format(
            ctx,
            SPRITESHEET_BYTES,
            None,
        );

        texture.set_filter(ctx, macroquad::FilterMode::Nearest);

        texture
    };

    let seed: u128 = {
        use std::time::SystemTime;

        let duration = match 
            SystemTime::now()
                .duration_since(SystemTime::UNIX_EPOCH)
        {
            Ok(d) => d,
            Err(err) => err.duration(),
        };

        duration.as_nanos()
    };

    println!("{}", seed);

    let state: &mut State = &mut State::from_seed(seed.to_le_bytes())
        .expect("state to be generated");

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

        if let Err(err) = state::update(state, input) {
            println!("{:?}", err);
            panic!("post state::update {:#?}", state);
        }

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

        let draw_sprite = |sprite: state::SpriteIndex, xy: state::TileXY| {
            macroquad::draw_texture_ex(
                spritesheet,
                sizes.play_area_x + sizes.tile * (xy.x as Size),
                sizes.play_area_y + sizes.tile * (xy.y as Size),
                macroquad::WHITE,
                macroquad::DrawTextureParams {
                    dest_size: Some(macroquad::Vec2::new(sizes.tile, sizes.tile)),
                    source: Some(macroquad::Rect {
                        x: 16. * sprite as f32,
                        y: 0.,
                        w: 16.,
                        h: 16.,
                    }),
                    rotation: 0.,
                }
            );
        };

        for t in state.tiles.iter() {
            draw_sprite(match t.kind {
                state::TileKind::Floor => 2,
                state::TileKind::Wall => 3,
            }, t.xy);
        }

        draw_sprite(0, state.xy);

        macroquad::next_frame().await
    }
}